-- ============================================================
-- RDE OXMEDIA — CLIENT  v1.0.3
--
-- ARCHITECTURE — three entity classes:
--
--   NETWORKED props  (player-placed, vehicle props, etc.)
--     • Have a real NetId  → key = 'net:<netId>'
--     • State synced via Entity StateBag  'oxmedia'
--     • Server controls play/stop/pause/volume (authoritative)
--     • ALL clients in proximity see/hear the same content
--
--   NON-NETWORKED props  (static world / map props like world TVs)
--     • No NetId  → key = 'ent:<entityHandle>'
--     • Each client manages its own local state
--     • Menu triggers LOCAL play/stop — no server round-trip
--     • Clearly labelled "Local playback only" in the menu
--
--   RDE_PROPS entities  (client-spawned, non-networked props from rde_props)
--     • Identified via rde_props export getPropIdByEntity
--     • key = 'prop:<propId>'
--     • State synced via GlobalState['oxmedia_prop_<propId>']
--     • Server is authoritative — all clients react to GlobalState changes
--     • Seamlessly integrated — same menu, same DUI, same audio
--
-- Both DUI/audio code paths are shared across all three classes.
-- ============================================================

-- ============================================================
-- LOCALE
-- ============================================================
local loc = lib.load('locales.' .. Config.Locale)

-- ============================================================
-- LOGGING
-- ============================================================

local function Log(msg, level)
    if not Config.Debug and level ~= 'ERROR' then return end
    local prefix = level == 'ERROR' and '^1' or level == 'WARN' and '^3' or '^2'
    print(('%s[RDE_OXMEDIA CLIENT]^7 %s'):format(prefix, msg))
end

-- ============================================================
-- LOCALS
-- ============================================================
local activeDevices = {}   -- [key] = device table   (key = 'net:X', 'ent:X', or 'prop:X')
local nearbyDevices = {}   -- sorted list of nearby device info tables
local playerPed     = 0
local playerCoords  = vector3(0, 0, 0)

-- ============================================================
-- RDE_PROPS INTEGRATION HELPERS
-- ============================================================

--- Returns the rde_props propId for a given entity, or nil if not an rde_props entity.
local function getRdePropId(entity)
    if GetResourceState('rde_props') ~= 'started' then return nil end
    local ok, propId = pcall(function()
        return exports['rde_props']:getPropIdByEntity(entity)
    end)
    return (ok and propId) or nil
end

-- ============================================================
-- ENTITY KEY HELPERS
-- ============================================================

--- Returns: key (string), netId (number|nil), isNetworked (bool), propId (string|nil)
local function entityKey(entity)
    if not DoesEntityExist(entity) then return nil, nil, false, nil end

    -- Check rde_props first — these are client-spawned so NetworkGetEntityIsNetworked
    -- returns false, but we want them treated as server-synced via GlobalState.
    local propId = getRdePropId(entity)
    if propId then
        return 'prop:' .. propId, nil, false, propId
    end

    if NetworkGetEntityIsNetworked(entity) then
        local n = NetworkGetNetworkIdFromEntity(entity)
        if n and n ~= 0 then
            return 'net:' .. n, n, true, nil
        end
    end

    return 'ent:' .. entity, nil, false, nil
end

--- Try to get a NetId; returns nil for world props and rde_props entities.
local function safeNetId(entity)
    if not DoesEntityExist(entity) then return nil end
    if getRdePropId(entity) then return nil end
    if not NetworkGetEntityIsNetworked(entity) then return nil end
    local n = NetworkGetNetworkIdFromEntity(entity)
    return (n and n ~= 0) and n or nil
end

-- ============================================================
-- CONFIG LOOKUP
-- ============================================================

local function getDeviceConfig(entity)
    if not DoesEntityExist(entity) then return nil end
    return Config.DeviceLookup[GetEntityModel(entity)]
end

-- ============================================================
-- DUI
-- ============================================================

local function createDui()
    local url = Config.DuiUrl
    if not url or url == '' then
        Log('Config.DuiUrl is not set! Cannot create DUI.', 'ERROR')
        return nil
    end

    local dui = CreateDui(url, Config.DuiScreenWidth, Config.DuiScreenHeight)
    if not dui then
        Log('CreateDui failed for: ' .. url, 'ERROR')
        return nil
    end

    local handle  = GetDuiHandle(dui)
    local txdName = 'rde_oxm_' .. handle
    local txd     = CreateRuntimeTxd(txdName)
    CreateRuntimeTextureFromDuiHandle(txd, 'dui_tex', handle)

    Log('DUI created from: ' .. url)

    return { dui = dui, handle = handle, txd = txd, txdName = txdName }
end

local function destroyDui(d)
    if not d then return end
    if d.dui then DestroyDui(d.dui) end
    d.dui = nil; d.handle = nil; d.txd = nil
end

local function duiSend(d, msg)
    if not d or not d.dui then return end
    SendDuiMessage(d.dui, json.encode(msg))
end

-- ============================================================
-- MEDIA TYPE DETECTION
-- ============================================================

local function detectMediaType(url)
    if not url or url == '' then return 'direct' end
    if url:match('youtube%.com') or url:match('youtu%.be') then return 'youtube' end
    if url:match('twitch%.tv') then return 'twitch' end
    return 'direct'
end

-- ============================================================
-- DEVICE LIFECYCLE
-- ============================================================
local startDevice, stopDevice, stopByKey

startDevice = function(entity, data)
    if not DoesEntityExist(entity) or not data or not data.url then return end

    local url = tostring(data.url):match('^%s*(.-)%s*$')
    if not url:match('^https?://') then
        Log('Rejected invalid URL: ' .. url:sub(1, 80), 'WARN')
        return
    end
    data.url = url

    local devConfig = getDeviceConfig(entity)
    if not devConfig then return end

    local key, netId, isNetworked, propId = entityKey(entity)
    if not key then return end

    if activeDevices[key] then stopByKey(key) end

    local mediaType = detectMediaType(data.url)
    local duiObj    = nil

    if devConfig.type == 'tv' then
        duiObj = createDui()
        if duiObj then
            local cap = { dui = duiObj, data = data, mt = mediaType }
            SetTimeout(600, function()
                if not cap.dui.dui then return end
                duiSend(cap.dui, {
                    action = 'loadUrl',
                    url    = cap.data.url,
                    type   = cap.mt,
                    volume = cap.data.volume or Config.DefaultVolume,
                    time   = cap.data.currentTime or 0,
                    paused = cap.data.paused or false,
                })
            end)
        end
    end

    activeDevices[key] = {
        key         = key,
        entity      = entity,
        netId       = netId,
        propId      = propId,
        isNetworked = isNetworked,
        isProp      = propId ~= nil,
        coords      = GetEntityCoords(entity),
        config      = devConfig,
        data        = data,
        mediaType   = mediaType,
        dui         = duiObj,
        startTime   = GetGameTimer(),
    }

    local tag = isNetworked and ('netId=' .. tostring(netId))
                or propId and ('prop=' .. propId)
                or ('ent=' .. tostring(entity))
    Log(('started [%s] url=%s'):format(tag, data.url))
end

stopByKey = function(key)
    local dev = activeDevices[key]
    if not dev then return end
    if dev.dui then
        duiSend(dev.dui, { action = 'stop' })
        destroyDui(dev.dui)
    end
    if dev.config and dev.config.screenTxd then
        RemoveReplaceTexture(dev.config.screenTxd, dev.config.screenTex)
    end
    if dev.config and dev.config.renderTarget then
        local rt = dev.config.renderTarget
        -- FIX: ReleaseNamedRendertarget only decrements the ref-count but the GPU
        -- retains the last drawn frame. Spawn a 2-frame thread that draws black
        -- to the RT before releasing, so the frozen image disappears on stop.
        CreateThread(function()
            for _ = 1, 2 do
                Wait(0)
                if IsNamedRendertargetRegistered(rt) then
                    local rid = GetNamedRendertargetRenderId(rt)
                    if rid and rid ~= 0 then
                        SetTextRenderId(rid)
                        Set_2dLayer(4)
                        SetScriptGfxDrawBehindPausemenu(true)
                        DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, 255)
                        SetTextRenderId(GetDefaultScriptRendertargetRenderId())
                    end
                end
            end
            if IsNamedRendertargetRegistered(rt) then
                ReleaseNamedRendertarget(rt)
            end
        end)
    end
    activeDevices[key] = nil
    Log(('stopped [%s]'):format(key))
end

stopDevice = function(entity)
    if not DoesEntityExist(entity) then
        for k, dev in pairs(activeDevices) do
            if dev.entity == entity then stopByKey(k) end
        end
        return
    end
    local key = entityKey(entity)
    if key then stopByKey(key) end
end

-- ============================================================
-- RENDER TARGETS  (every frame)
-- ============================================================

local function updateRenderTargets()
    for key, dev in pairs(activeDevices) do
        if not DoesEntityExist(dev.entity) then
            stopByKey(key); goto continue
        end
        if dev.config.type ~= 'tv' or not dev.dui then goto continue end

        local dist = #(GetEntityCoords(dev.entity) - playerCoords)
        if dist > Config.MaxRenderDistance then goto continue end

        if dev.config.renderTarget then
            local rt        = dev.config.renderTarget
            local modelHash = GetEntityModel(dev.entity)
            if not IsNamedRendertargetRegistered(rt) then
                RegisterNamedRendertarget(rt, false)
            end
            if not IsNamedRendertargetLinked(modelHash) then
                LinkNamedRendertarget(modelHash)
            end
            local rid = GetNamedRendertargetRenderId(rt)
            if rid and rid ~= 0 then
                SetTextRenderId(rid)
                Set_2dLayer(4)
                SetScriptGfxDrawBehindPausemenu(true)
                DrawSprite(dev.dui.txdName, 'dui_tex',
                    0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
                SetTextRenderId(GetDefaultScriptRendertargetRenderId())
            end
        elseif dev.config.screenTxd then
            AddReplaceTexture(dev.config.screenTxd, dev.config.screenTex,
                              dev.dui.txdName, 'dui_tex')
        end

        ::continue::
    end
end

-- ============================================================
-- AUDIO  (every 100 ms)
-- ============================================================

local function updateAudio()
    playerPed    = PlayerPedId()
    playerCoords = GetEntityCoords(playerPed)
    local playerRoom = GetRoomKeyFromEntity(playerPed)

    for key, dev in pairs(activeDevices) do
        if not DoesEntityExist(dev.entity) then
            stopByKey(key); goto continue
        end

        dev.coords = GetEntityCoords(dev.entity)

        if dev.data.paused then
            if dev.dui then duiSend(dev.dui, { action = 'setVolume', volume = 0 }) end
            goto continue
        end

        local dist     = #(playerCoords - dev.coords)
        local maxRange = dev.config.audioRange or 30.0

        if dist > maxRange then
            if dev.dui then duiSend(dev.dui, { action = 'setVolume', volume = 0 }) end
            goto continue
        end

        local vol = dev.data.volume or Config.DefaultVolume

        if Config.EnableAttenuation then
            vol = vol * (1.0 - dist / maxRange)
        end

        if Config.EnableRoomAttenuation then
            local devRoom = GetRoomKeyFromEntity(dev.entity)
            if playerRoom ~= devRoom then
                vol = vol * (1.0 - Config.DiffRoomVolume)
            end
        end

        vol = math.max(0, math.min(100, math.floor(vol)))
        if dev.dui then duiSend(dev.dui, { action = 'setVolume', volume = vol }) end

        ::continue::
    end
end

-- ============================================================
-- NEARBY DETECTION
-- ============================================================

local function updateNearbyDevices()
    playerPed    = PlayerPedId()
    playerCoords = GetEntityCoords(playerPed)
    nearbyDevices = {}

    for _, ent in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(ent) then
            local cfg = getDeviceConfig(ent)
            if cfg then
                local coords = GetEntityCoords(ent)
                local dist   = #(playerCoords - coords)
                if dist <= Config.InteractionDistance then
                    table.insert(nearbyDevices, {
                        entity = ent,
                        coords = coords,
                        dist   = dist,
                        config = cfg,
                    })
                end
            end
        end
    end

    table.sort(nearbyDevices, function(a, b) return a.dist < b.dist end)
end

-- ============================================================
-- STATE BAG  (networked props — server-authoritative sync)
-- ============================================================

local function entityFromBagName(bagName)
    local handle = tonumber(bagName:match('entity:(%d+)'))
    if not handle then return nil, nil end
    local entity = handle
    if not DoesEntityExist(entity) then return nil, nil end
    local netId = safeNetId(entity)
    return entity, netId
end

AddStateBagChangeHandler('oxmedia', nil, function(bagName, _, value)
    local entity, _ = entityFromBagName(bagName)
    if not entity then return end

    local entCoords = GetEntityCoords(entity)
    local myCoords  = GetEntityCoords(PlayerPedId())
    local dist      = #(entCoords - myCoords)

    if value and value.active then
        if dist <= Config.MaxRenderDistance then
            startDevice(entity, value)
        end
    else
        stopDevice(entity)
    end
end)

-- ============================================================
-- RDE_PROPS GLOBALSTATE SYNC
-- Watches GlobalState['oxmedia_prop_<propId>'] for changes.
-- The server writes this key; all clients react here.
-- ============================================================

local function syncRdePropState(entity, propId)
    local gsKey = 'oxmedia_prop_' .. propId
    local data  = GlobalState[gsKey]
    local devKey = 'prop:' .. propId

    -- Treat { _deleted = true } tombstone same as nil
    if data and data.active then
        if not activeDevices[devKey] then
            local dist = #(GetEntityCoords(entity) - GetEntityCoords(PlayerPedId()))
            if dist <= Config.MaxRenderDistance then
                startDevice(entity, data)
            end
        end
    else
        if activeDevices[devKey] then
            stopByKey(devKey)
        end
    end
end

-- GlobalState change handler for rde_props media keys.
-- FiveM doesn't support wildcard AddStateBagChangeHandler on GlobalState,
-- so we poll in the proximity thread below — this handler covers server-push
-- updates for props that are already tracked locally.
AddStateBagChangeHandler('', 'global', function(_, key, value)
    local propId = key:match('^oxmedia_prop_(.+)$')
    if not propId then return end

    -- Find the entity for this propId
    if GetResourceState('rde_props') ~= 'started' then return end
    local ok, entities = pcall(function()
        return exports['rde_props']:getAllEntities()
    end)
    if not ok or not entities then return end

    local entity = entities[propId]
    if not entity or not DoesEntityExist(entity) then return end

    local devKey = 'prop:' .. propId
    -- value == nil OR value._deleted == true → stop
    if value and value.active then
        local dist = #(GetEntityCoords(entity) - GetEntityCoords(PlayerPedId()))
        if dist <= Config.MaxRenderDistance then
            startDevice(entity, value)
        end
    else
        if activeDevices[devKey] then stopByKey(devKey) end
    end
end)

-- ============================================================
-- LATE-JOIN PROXIMITY SYNC
-- Handles both networked (net:) and rde_props (prop:) entities.
-- ============================================================

local pendingSync = {}

CreateThread(function()
    while true do
        Wait(2000)
        playerPed    = PlayerPedId()
        playerCoords = GetEntityCoords(playerPed)

        -- ── Networked entity sync (original logic) ──────────────
        for _, ent in ipairs(GetGamePool('CObject')) do
            if DoesEntityExist(ent) and NetworkGetEntityIsNetworked(ent) then
                -- Skip rde_props entities (they have no real NetId path)
                if not getRdePropId(ent) then
                    local netId = safeNetId(ent)
                    if netId then
                        local key  = 'net:' .. netId
                        local dist = #(GetEntityCoords(ent) - playerCoords)

                        if dist <= Config.MaxRenderDistance and not activeDevices[key] and not pendingSync[netId] then
                            pendingSync[netId] = true
                            local data = lib.callback.await('rde_oxmedia:getDeviceState', false, netId)
                            pendingSync[netId] = nil

                            if data and data.active then
                                startDevice(ent, data)
                            end
                        elseif dist > Config.MaxRenderDistance and activeDevices[key] then
                            stopByKey(key)
                        end
                    end
                end
            end
        end

        -- ── RDE_PROPS entity sync ────────────────────────────────
        if GetResourceState('rde_props') == 'started' then
            local ok, entities = pcall(function()
                return exports['rde_props']:getAllEntities()
            end)
            if ok and entities then
                for propId, entity in pairs(entities) do
                    if DoesEntityExist(entity) then
                        syncRdePropState(entity, propId)
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- MENU
-- ============================================================

local function openMenu(entity)
    if not DoesEntityExist(entity) then
        lib.notify({ type = 'error', description = loc.device_not_found })
        return
    end

    local devConfig = getDeviceConfig(entity)
    if not devConfig then
        lib.notify({ type = 'error', description = loc.not_a_device })
        return
    end

    local key, netId, isNetworked, propId = entityKey(entity)
    local isProp   = propId ~= nil
    local isActive = activeDevices[key] ~= nil
    local devData  = activeDevices[key]
    local options  = {}

    local function doPlay(url, volume)
        if isNetworked then
            TriggerServerEvent('rde_oxmedia:server:start', netId, { url = url, volume = volume })
        elseif isProp then
            TriggerServerEvent('rde_oxmedia:server:propStart', propId, { url = url, volume = volume })
        else
            startDevice(entity, { url = url, volume = volume })
        end
    end

    local function doStop()
        if isNetworked then
            TriggerServerEvent('rde_oxmedia:server:stop', netId)
        elseif isProp then
            TriggerServerEvent('rde_oxmedia:server:propStop', propId)
        else
            stopDevice(entity)
        end
    end

    local function doTogglePause()
        if isNetworked then
            TriggerServerEvent('rde_oxmedia:server:togglePause', netId)
        elseif isProp then
            TriggerServerEvent('rde_oxmedia:server:propTogglePause', propId)
        else
            if devData and devData.data then
                devData.data.paused = not devData.data.paused
                if devData.dui then
                    duiSend(devData.dui, { action = devData.data.paused and 'pause' or 'resume' })
                end
            end
        end
    end

    local function doSetVolume(vol)
        if isNetworked then
            TriggerServerEvent('rde_oxmedia:server:setVolume', netId, vol)
        elseif isProp then
            TriggerServerEvent('rde_oxmedia:server:propSetVolume', propId, vol)
        else
            if devData and devData.data then devData.data.volume = vol end
        end
    end

    if isActive and devData then
        table.insert(options, {
            title    = loc.btn_pause_resume,
            icon     = 'pause',
            onSelect = doTogglePause,
        })
        table.insert(options, {
            title       = loc.btn_stop,
            icon        = 'stop',
            colorScheme = 'red',
            onSelect    = doStop,
        })
        table.insert(options, {
            title       = loc.btn_volume,
            icon        = 'volume-high',
            colorScheme = 'blue',
            onSelect    = function()
                local input = lib.inputDialog(loc.dlg_volume_title, {
                    { type    = 'slider',
                      label   = loc.dlg_volume_label:format(Config.MaxVolume),
                      min     = 0,
                      max     = Config.MaxVolume,
                      default = devData.data.volume or Config.DefaultVolume },
                })
                if input and input[1] then doSetVolume(input[1]) end
            end,
        })
        table.insert(options, {
            title    = loc.btn_change_url,
            icon     = 'link',
            onSelect = function()
                local input = lib.inputDialog(loc.dlg_change_title, {
                    { type        = 'input',
                      label       = loc.dlg_play_url_label,
                      description = loc.dlg_change_url_desc,
                      required    = true },
                })
                if input and input[1] and input[1] ~= '' then
                    doPlay(input[1], devData.data.volume or Config.DefaultVolume)
                end
            end,
        })
        local displayUrl = tostring(devData.data.url or 'Unknown')
        displayUrl = displayUrl:gsub('<[^>]+>', ''):gsub('%s+', ' '):match('^%s*(.-)%s*$')
        if #displayUrl > 80 then displayUrl = displayUrl:sub(1, 77) .. '...' end
        table.insert(options, {
            title       = loc.btn_now_playing,
            icon        = 'circle-info',
            colorScheme = 'purple',
            description = displayUrl,
            readOnly    = true,
        })
    else
        table.insert(options, {
            title       = loc.btn_play,
            icon        = 'play',
            colorScheme = 'green',
            onSelect    = function()
                local input = lib.inputDialog(loc.dlg_play_title, {
                    { type        = 'input',
                      label       = loc.dlg_play_url_label,
                      description = loc.dlg_play_url_desc,
                      required    = true },
                    { type    = 'slider',
                      label   = loc.dlg_volume_label:format(Config.MaxVolume),
                      min     = 0,
                      max     = Config.MaxVolume,
                      default = Config.DefaultVolume },
                })
                if input and input[1] and input[1] ~= '' then
                    doPlay(input[1], input[2] or Config.DefaultVolume)
                end
            end,
        })
    end

    -- Info badge
    if not isNetworked and not isProp then
        table.insert(options, {
            title       = loc.lbl_local_only,
            icon        = 'circle-info',
            description = loc.desc_local_only,
            readOnly    = true,
        })
    elseif isProp then
        table.insert(options, {
            title       = '🐉 RDE Prop',
            icon        = 'circle-info',
            description = 'GlobalState sync — all players hear the same content',
            readOnly    = true,
        })
    end

    lib.registerContext({
        id      = 'rde_oxmedia_menu',
        title   = devConfig.type == 'tv' and loc.menu_title_tv or loc.menu_title_radio,
        options = options,
    })
    lib.showContext('rde_oxmedia_menu')
end

-- Event wrappers
RegisterNetEvent('rde_oxmedia:client:openMenu', function(netId)
    openMenu(NetworkGetEntityFromNetworkId(netId))
end)

RegisterNetEvent('rde_oxmedia:client:findNearest', function()
    if #nearbyDevices > 0 then
        openMenu(nearbyDevices[1].entity)
    else
        lib.notify({ type = 'error', description = loc.device_not_found })
    end
end)

RegisterNetEvent('rde_oxmedia:client:stopNearest', function()
    if #nearbyDevices > 0 then
        local ent    = nearbyDevices[1].entity
        local n      = safeNetId(ent)
        local propId = getRdePropId(ent)
        if n then
            TriggerServerEvent('rde_oxmedia:server:stop', n)
        elseif propId then
            TriggerServerEvent('rde_oxmedia:server:propStop', propId)
        else
            stopDevice(ent)
        end
    else
        lib.notify({ type = 'error', description = loc.device_not_found })
    end
end)

-- ============================================================
-- OX_TARGET
-- ============================================================

if Config.UseTarget then
    local models = {}
    for _, d in ipairs(Config.Devices) do table.insert(models, d.model) end
    exports.ox_target:addModel(models, {
        {
            name     = 'rde_oxmedia_control',
            icon     = Config.TargetIcon,
            label    = 'Media Player',
            distance = Config.TargetDistance,
            debug    = Config.Debug,
            onSelect = function(data) openMenu(data.entity) end,
        },
    })
end

-- ============================================================
-- E-KEY / TEXT-UI
-- ============================================================

if not Config.UseTarget then
    local shown = false
    CreateThread(function()
        while true do
            updateNearbyDevices()
            if #nearbyDevices > 0 then
                if not shown then
                    lib.showTextUI('[E] Media Player', { position = 'bottom-center', icon = 'tv' })
                    shown = true
                end
            else
                if shown then lib.hideTextUI(); shown = false end
            end
            Wait(500)
        end
    end)

    lib.addKeybind({
        name        = 'rde_oxmedia_interact',
        description = 'Interact with media player',
        defaultKey  = 'E',
        onPressed   = function()
            if #nearbyDevices > 0 then openMenu(nearbyDevices[1].entity) end
        end,
    })
end

-- ============================================================
-- MAIN THREADS
-- ============================================================

-- [EXCEPTION] Wait(0) is required here — render targets must be drawn
-- every frame or the DUI texture disappears between frames.
CreateThread(function()
    while true do updateRenderTargets(); Wait(0) end
end)

CreateThread(function()  -- audio attenuation: every 100 ms
    while true do updateAudio(); Wait(100) end
end)

-- Time reporter for networked props (net: keys only)
CreateThread(function()
    while true do
        Wait(5000)
        for key, dev in pairs(activeDevices) do
            if dev.isNetworked and dev.netId and dev.data and dev.dui then
                if dev.data.startedBy == GetPlayerServerId(PlayerId()) then
                    if dev.startTime then  -- BUG-01 fix: startTime lives at dev level, not dev.data
                        local elapsed = (GetGameTimer() - dev.startTime) / 1000
                        local ct = (dev.data.currentTime or 0) + elapsed
                        TriggerServerEvent('rde_oxmedia:server:reportTime', dev.netId, ct)
                    end
                end
            end
        end
    end
end)

if Config.UseTarget then
    CreateThread(function()  -- nearby scan for target interaction
        while true do updateNearbyDevices(); Wait(1000) end
    end)
end

-- ============================================================
-- EXPORTS
-- ============================================================

exports('startDevice',      startDevice)
exports('stopDevice',       stopDevice)
exports('getActiveDevices', function() return activeDevices end)

print('^2[RDE_OXMEDIA] Client v1.0.3 initialized — locale: ' .. Config.Locale .. ' | rde_props sync enabled^7')
