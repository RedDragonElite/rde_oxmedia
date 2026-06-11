-- ============================================================
-- RDE OXMEDIA — SERVER  v1.0.3
--
-- All play/pause/stop/volume actions are server-authoritative.
--
-- NETWORKED PROPS:  State broadcast via Entity StateBags.
-- RDE_PROPS:        State broadcast via GlobalState['oxmedia_prop_<propId>'].
--                   No NetId required — works with client-spawned props.
-- ============================================================

local activeDevices     = {}   -- [netId]  = { netId, entity, data, startedBy, startedAt }
local activePropDevices = {}   -- [propId] = { propId, data, startedBy, startedAt }

-- ============================================================
-- LOGGING
-- ============================================================

local function Log(msg, level)
    if not Config.Debug and level ~= 'ERROR' then return end
    local prefix = level == 'ERROR' and '^1' or level == 'WARN' and '^3' or '^2'
    print(('%s[RDE_OXMEDIA SERVER]^7 %s'):format(prefix, msg))
end

-- ============================================================
-- CURRENT TIME TRACKING  (networked props)
-- ============================================================

RegisterNetEvent('rde_oxmedia:server:reportTime', function(netId, currentTime)
    local src = source
    netId       = tonumber(netId)
    currentTime = tonumber(currentTime)
    if not netId or not currentTime then return end

    local dev = activeDevices[netId]
    if not dev or dev.startedBy ~= src then return end

    dev.data.currentTime  = math.max(0, currentTime)
    dev.data.lastTimeSync = os.time()
end)

lib.callback.register('rde_oxmedia:getDeviceState', function(source, netId)
    netId = tonumber(netId)
    if not netId then return nil end

    local dev = activeDevices[netId]
    if not dev or not dev.data or not dev.data.active then return nil end

    local data = {}
    for k, v in pairs(dev.data) do data[k] = v end

    if not data.paused and data.currentTime and data.lastTimeSync then
        local elapsed = os.time() - data.lastTimeSync
        data.currentTime = data.currentTime + elapsed
    end

    return data
end)

-- ============================================================
-- PERMISSION HELPERS
-- ============================================================

local function hasPermission(source, level)
    if not Config.UsePermissions then return true end
    level = level or 'user'
    if level == 'user' then return true end
    if not source or source == 0 then return true end

    for _, method in ipairs(Config.AdminSystem.checkOrder) do
        if method == 'ace' then
            if IsPlayerAceAllowed(source, Config.AdminSystem.acePermission) then
                return true
            end

        elseif method == 'oxcore' then
            if GetResourceState('ox_core') == 'started' then
                local player = exports.ox_core:GetPlayer(source)
                if player then
                    local groups = player.getGroups()
                    for group in pairs(groups) do
                        if Config.AdminSystem.oxGroups[group] then
                            return true
                        end
                    end
                end
            end

        elseif method == 'steam' then
            local steamId = GetPlayerIdentifierByType(source, 'steam')
            if steamId then
                for _, id in ipairs(Config.AdminSystem.steamIds) do
                    if id == steamId then return true end
                end
            end
        end
    end

    return false
end

-- ============================================================
-- URL VALIDATION
-- ============================================================

local function validateUrl(url)
    if not url or url == '' then
        return false, 'URL is required'
    end

    url = url:match('^%s*(.-)%s*$')

    if not url:match('^https?://') then
        return false, 'URL must start with http:// or https://'
    end

    local isYouTube = url:match('youtube%.com') or url:match('youtu%.be')
    local isTwitch  = url:match('twitch%.tv')

    if isYouTube and not Config.AllowYouTube then
        return false, 'YouTube links are disabled on this server'
    end

    if isTwitch and not Config.AllowTwitch then
        return false, 'Twitch links are disabled on this server'
    end

    if not isYouTube and not isTwitch then
        if not Config.AllowDirectLinks then
            return false, 'Only YouTube and Twitch links are allowed'
        end
    end

    return true, url
end

-- ============================================================
-- NETWORKED DEVICE STATE  (Entity StateBag)
-- ============================================================

local function setDeviceState(netId, data)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then
        return false
    end

    if data then
        data.active      = true
        data.currentTime = data.currentTime or 0
        data.paused      = data.paused      or false
        data.volume      = data.volume      or Config.DefaultVolume

        activeDevices[netId] = {
            netId     = netId,
            entity    = entity,
            data      = data,
            startedBy = data.startedBy,
            startedAt = os.time(),
        }
        data.lastTimeSync = os.time()
    else
        activeDevices[netId] = nil
    end

    Entity(entity).state:set('oxmedia', data, true)
    return true
end

local function getDeviceState(netId)
    return activeDevices[netId]
end

-- ============================================================
-- RDE_PROPS DEVICE STATE  (GlobalState)
-- Key: GlobalState['oxmedia_prop_<propId>']
--
-- FIX BUG-01: Tombstone pattern on deletion — prevents clients
-- from missing the stop event due to nil race condition.
-- Standards Anti-Pattern #4 fix.
-- ============================================================

local function setPropDeviceState(propId, data, immediate)
    if not propId or propId == '' then return false end

    if data then
        data.active      = true
        data.currentTime = data.currentTime or 0
        data.paused      = data.paused      or false
        data.volume      = data.volume      or Config.DefaultVolume

        activePropDevices[propId] = {
            propId    = propId,
            data      = data,
            startedBy = data.startedBy,
            startedAt = os.time(),
        }
        data.lastTimeSync = os.time()
        GlobalState['oxmedia_prop_' .. propId] = data
    else
        activePropDevices[propId] = nil
        if immediate then
            -- Immediate nil (used during resource/rde_props shutdown only)
            GlobalState['oxmedia_prop_' .. propId] = nil
        else
            -- Tombstone: give clients 1 s to react before the key disappears
            GlobalState['oxmedia_prop_' .. propId] = { _deleted = true }
            SetTimeout(1000, function()
                GlobalState['oxmedia_prop_' .. propId] = nil
            end)
        end
    end

    return true
end

local function getPropDeviceState(propId)
    return activePropDevices[propId]
end

-- ============================================================
-- NOSTR LOG
-- ============================================================

local function logAction(source, action, id, details)
    if not Config.UseNostrLog then return end
    if GetResourceState(Config.NostrLogResource) ~= 'started' then return end
    if not Config.NostrLog[action] then return end

    local msg = ('[OXMEDIA] %s | player=%s | device=%s'):format(
        action,
        GetPlayerName(source) or tostring(source),
        tostring(id)
    )
    if details then
        msg = msg .. ' | ' .. json.encode(details)
    end

    TriggerEvent('rde_nostr_log:server:log', {
        type    = 'oxmedia',
        message = msg,
        source  = source,
        data    = { action = action, id = id, details = details },
    })
end

-- ============================================================
-- NOTIFICATION SHORTHAND
-- ============================================================

local function notify(src, ntype, desc)
    TriggerClientEvent('ox_lib:notify', src, { type = ntype, description = desc })
end

-- ============================================================
-- NETWORKED PROP EVENTS
-- ============================================================

RegisterNetEvent('rde_oxmedia:server:start', function(netId, data)
    local source = source
    netId = tonumber(netId)
    if not netId then return end

    if not hasPermission(source, 'user') then
        notify(source, 'error', "You don't have permission to use this")
        return
    end

    local ok, result = validateUrl(data and data.url or '')
    if not ok then notify(source, 'error', result); return end
    data.url = result

    local current = getDeviceState(netId)
    if current and current.data.locked and not hasPermission(source, 'admin') then
        notify(source, 'error', 'This device is locked')
        return
    end

    data.startedBy     = source
    data.startedByName = GetPlayerName(source) or tostring(source)

    if setDeviceState(netId, data) then
        notify(source, 'success', 'Media started')
        logAction(source, 'onMediaStart', netId, { url = data.url })
        Log(('start | netId=%d | url=%s | src=%d'):format(netId, data.url:sub(1,60), source))
    else
        notify(source, 'error', 'Failed to start — device entity not found')
    end
end)

RegisterNetEvent('rde_oxmedia:server:stop', function(netId)
    local source = source
    netId = tonumber(netId)
    if not netId then return end

    local current = getDeviceState(netId)
    if not current then notify(source, 'error', 'Device is not active'); return end

    if current.data.locked and not hasPermission(source, 'admin') then
        notify(source, 'error', 'This device is locked')
        return
    end

    if setDeviceState(netId, nil) then
        notify(source, 'success', 'Media stopped')
        logAction(source, 'onMediaStop', netId, nil)
        Log(('stop | netId=%d | src=%d'):format(netId, source))
    end
end)

RegisterNetEvent('rde_oxmedia:server:togglePause', function(netId)
    local source = source
    netId = tonumber(netId)
    if not netId then return end

    local current = getDeviceState(netId)
    if not current then return end

    if current.data.locked and not hasPermission(source, 'admin') then
        notify(source, 'error', 'This device is locked')
        return
    end

    current.data.paused = not current.data.paused
    setDeviceState(netId, current.data)

    notify(source, 'info', current.data.paused and 'Media paused' or 'Media resumed')
    if Config.NostrLog.onPauseToggle then
        logAction(source, 'onPauseToggle', netId, { paused = current.data.paused })
    end
end)

RegisterNetEvent('rde_oxmedia:server:setVolume', function(netId, volume)
    local source = source
    netId  = tonumber(netId)
    volume = tonumber(volume)
    if not netId or volume == nil then return end  -- BUG-04 fix: `not 0` is false in Lua, explicit nil check

    local current = getDeviceState(netId)
    if not current then return end

    if current.data.locked and not hasPermission(source, 'admin') then
        notify(source, 'error', 'This device is locked')
        return
    end

    volume = math.max(0, math.min(Config.MaxVolume, math.floor(volume)))
    current.data.volume = volume
    setDeviceState(netId, current.data)

    notify(source, 'success', ('Volume set to %d'):format(volume))
    if Config.NostrLog.onVolumeChange then
        logAction(source, 'onVolumeChange', netId, { volume = volume })
    end
end)

RegisterNetEvent('rde_oxmedia:server:lock', function(netId)
    local source = source
    netId = tonumber(netId)
    if not netId then return end

    if not hasPermission(source, 'admin') then
        notify(source, 'error', "You don't have permission to lock devices")
        return
    end

    local current = getDeviceState(netId)
    if not current then return end

    current.data.locked = not current.data.locked
    setDeviceState(netId, current.data)

    notify(source, 'success', current.data.locked and 'Device locked' or 'Device unlocked')
    logAction(source, 'onLock', netId, { locked = current.data.locked })
end)

-- ============================================================
-- RDE_PROPS EVENTS  (GlobalState path)
-- ============================================================

RegisterNetEvent('rde_oxmedia:server:propStart', function(propId, data)
    local source = source
    if not propId or propId == '' then return end

    if not hasPermission(source, 'user') then
        notify(source, 'error', "You don't have permission to use this")
        return
    end

    local ok, result = validateUrl(data and data.url or '')
    if not ok then notify(source, 'error', result); return end
    data.url = result

    local current = getPropDeviceState(propId)
    if current and current.data.locked and not hasPermission(source, 'admin') then
        notify(source, 'error', 'This device is locked')
        return
    end

    data.startedBy     = source
    data.startedByName = GetPlayerName(source) or tostring(source)

    if setPropDeviceState(propId, data) then
        notify(source, 'success', 'Media started')
        logAction(source, 'onMediaStart', propId, { url = data.url })
        Log(('propStart | propId=%s | url=%s | src=%d'):format(propId, data.url:sub(1,60), source))
    else
        notify(source, 'error', 'Failed to start media on prop')
    end
end)

RegisterNetEvent('rde_oxmedia:server:propStop', function(propId)
    local source = source
    if not propId or propId == '' then return end

    local current = getPropDeviceState(propId)
    if not current then notify(source, 'error', 'Device is not active'); return end

    if current.data.locked and not hasPermission(source, 'admin') then
        notify(source, 'error', 'This device is locked')
        return
    end

    if setPropDeviceState(propId, nil) then
        notify(source, 'success', 'Media stopped')
        logAction(source, 'onMediaStop', propId, nil)
        Log(('propStop | propId=%s | src=%d'):format(propId, source))
    end
end)

RegisterNetEvent('rde_oxmedia:server:propTogglePause', function(propId)
    local source = source
    if not propId or propId == '' then return end

    local current = getPropDeviceState(propId)
    if not current then return end

    if current.data.locked and not hasPermission(source, 'admin') then
        notify(source, 'error', 'This device is locked')
        return
    end

    current.data.paused = not current.data.paused
    setPropDeviceState(propId, current.data)

    notify(source, 'info', current.data.paused and 'Media paused' or 'Media resumed')
    if Config.NostrLog.onPauseToggle then
        logAction(source, 'onPauseToggle', propId, { paused = current.data.paused })
    end
end)

RegisterNetEvent('rde_oxmedia:server:propSetVolume', function(propId, volume)
    local source = source
    volume = tonumber(volume)
    if not propId or propId == '' or volume == nil then return end  -- BUG-04 fix: explicit nil check

    local current = getPropDeviceState(propId)
    if not current then return end

    if current.data.locked and not hasPermission(source, 'admin') then
        notify(source, 'error', 'This device is locked')
        return
    end

    volume = math.max(0, math.min(Config.MaxVolume, math.floor(volume)))
    current.data.volume = volume
    setPropDeviceState(propId, current.data)

    notify(source, 'success', ('Volume set to %d'):format(volume))
    if Config.NostrLog.onVolumeChange then
        logAction(source, 'onVolumeChange', propId, { volume = volume })
    end
end)

-- ============================================================
-- ADMIN CLEAR ALL  (includes prop devices)
-- ============================================================

RegisterNetEvent('rde_oxmedia:server:clearAll', function()
    local source = source

    if not hasPermission(source, 'admin') then
        notify(source, 'error', "You don't have permission to clear all devices")
        return
    end

    local count = 0
    for netId in pairs(activeDevices) do
        setDeviceState(netId, nil)
        count = count + 1
    end
    for propId in pairs(activePropDevices) do
        setPropDeviceState(propId, nil)  -- tombstone path (not immediate)
        count = count + 1
    end

    notify(source, 'success', ('Cleared %d active device(s)'):format(count))
    logAction(source, 'onClearAll', nil, { count = count })
    Log(('clearAll | count=%d | src=%d'):format(count, source))
end)

-- ============================================================
-- COMMANDS
-- ============================================================

lib.addCommand('oxmedia', {
    help       = 'Open media player for nearest device',
    restricted = false,
}, function(source)
    TriggerClientEvent('rde_oxmedia:client:findNearest', source)
end)

lib.addCommand('oxmedia_stop', {
    help       = 'Stop media on nearest device',
    restricted = false,
}, function(source)
    TriggerClientEvent('rde_oxmedia:client:stopNearest', source)
end)

lib.addCommand('oxmedia_clear', {
    help       = 'Clear all active media devices (admin only)',
    restricted = 'group.admin',
}, function(source)
    -- BUG-03 fix: inlined logic — TriggerEvent gave source=0, permission check
    -- bypassed and notify(0,...) was a no-op. Command is already restricted to admins.
    local count = 0
    for netId in pairs(activeDevices) do
        setDeviceState(netId, nil)
        count = count + 1
    end
    for propId in pairs(activePropDevices) do
        setPropDeviceState(propId, nil)
        count = count + 1
    end
    notify(source, 'success', ('Cleared %d active device(s)'):format(count))
    logAction(source, 'onClearAll', nil, { count = count })
    Log(('clearAll | count=%d | src=%d'):format(count, source))
end)

-- ============================================================
-- CLEANUP ON RESOURCE STOP
-- ============================================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Immediate nil on resource stop (tombstone not needed — resource is gone)
    for netId in pairs(activeDevices) do
        setDeviceState(netId, nil)
    end
    for propId in pairs(activePropDevices) do
        setPropDeviceState(propId, nil, true)  -- immediate = true
    end

    Log('Resource stopped — cleared all active devices', 'WARN')
end)

-- Clean up GlobalState prop keys when rde_props stops
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= 'rde_props' then return end
    for propId in pairs(activePropDevices) do
        GlobalState['oxmedia_prop_' .. propId] = nil  -- immediate on dependency stop
    end
    activePropDevices = {}
    Log('rde_props stopped — cleared all prop media states', 'WARN')
end)

-- ============================================================
-- EXPORTS
-- ============================================================

exports('getActiveDevices',     function() return activeDevices end)
exports('getActivePropDevices', function() return activePropDevices end)
exports('setDeviceState',       setDeviceState)
exports('setPropDeviceState',   setPropDeviceState)
exports('getDeviceState',       getDeviceState)
exports('getPropDeviceState',   getPropDeviceState)
exports('hasPermission',        hasPermission)

print('^2[RDE_OXMEDIA] Server v1.0.3 initialized | rde_props GlobalState sync ready^7')
