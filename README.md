<div align="center">

```
██████╗ ██████╗ ███████╗     ██████╗ ██╗  ██╗███╗   ███╗███████╗██████╗ ██╗ █████╗
██╔══██╗██╔══██╗██╔════╝    ██╔═══██╗╚██╗██╔╝████╗ ████║██╔════╝██╔══██╗██║██╔══██╗
██████╔╝██║  ██║█████╗      ██║   ██║ ╚███╔╝ ██╔████╔██║█████╗  ██║  ██║██║███████║
██╔══██╗██║  ██║██╔══╝      ██║   ██║ ██╔██╗ ██║╚██╔╝██║██╔══╝  ██║  ██║██║██╔══██║
██║  ██║██████╔╝███████╗    ╚██████╔╝██╔╝ ██╗██║ ╚═╝ ██║███████╗██████╔╝██║██║  ██║
╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝
```

**Next-generation media streaming for FiveM ox_core servers.**  
_YouTube · Twitch · Direct links — on any TV, radio, monitor, or speaker in the world._

[![Version](https://img.shields.io/badge/version-v1.0.0--alpha-red?style=flat-square)](https://github.com/RedDragonElite/rde_oxmedia/releases)
[![License](https://img.shields.io/badge/license-Black%20Flag%20v6.66-black?style=flat-square)](LICENSE)
[![ox_core](https://img.shields.io/badge/stack-ox__core-purple?style=flat-square)](https://github.com/overextended/ox_core)
[![Free](https://img.shields.io/badge/Tebex-never-green?style=flat-square)](https://github.com/RedDragonElite)

> 🐍 **Free code. Free minds.**  
> Built by **Red Dragon Elite** — the anti-paywall FiveM ecosystem.  
> No Tebex. No escrow. No bullshit.

</div>

---

## ⚡ What is rde_oxmedia?

The go-to PMMS replacement for ox_core servers. Stream YouTube videos, Twitch channels, and direct media files on any TV, monitor, laptop, cinema screen, radio, speaker, or boombox in GTA V — with **full server-authoritative multiplayer sync**, **rde_props integration**, and **proximity 3D audio**. Zero database, zero SQL imports, zero overhead.

---

## ✨ Features

- **Full StateBag multiplayer sync** — play/pause/stop/volume is authoritative on the server and broadcast to all clients in proximity instantly
- **rde_props native integration** — client-spawned TV/radio props sync via `GlobalState` — no NetId required, same menu, same DUI, same audio
- **3D proximity audio** — distance-based volume attenuation, room attenuation (different interiors), per-device configurable audio range
- **DUI rendering on 40+ GTA prop models** — flat-screen TVs, CRT TVs, monitors, laptops, cinema screens, arena displays, DLC props
- **YouTube, Twitch, direct MP4/MP3/WebM/HLS** support
- **Late-join sync** — players joining mid-stream receive the correct playback position automatically
- **Dual interaction modes** — `ox_target` third-eye menu OR E-key + TextUI (configurable)
- **Per-device lock** — admins can lock any device so only admins can change it
- **World prop support** — static map TVs work in local mode (clearly labelled in menu)
- **Triple-layer permission system** — ACE permissions → ox_core groups → Steam ID whitelist
- **Optional `rde_nostr_log` integration** — audit trail for all media actions
- **Multilingual** — English & German included, trivially extensible
- **Zero database** — no SQL, no table imports, pure StateBag/GlobalState architecture

---

## 📦 Dependencies

```
# Required — load in this exact order in server.cfg
ensure ox_lib
ensure ox_core

# Optional — needed only if Config.UseTarget = true
ensure ox_target

# Optional — needed only if you want rde_props media sync
ensure rde_props

ensure rde_oxmedia
```

> `oxmysql` is **not required** — this resource has no database.

---

## 🚀 Installation

1. Drop the `rde_oxmedia` folder into your `resources/` directory
2. Add `ensure rde_oxmedia` to your `server.cfg`
3. Set `Config.DuiUrl` in `config.lua` (see below — **required for YouTube**)
4. Restart the server — done. No SQL, no imports, no setup

---

## ⚙️ Configuration

All settings live in `config.lua`. Open it — everything is documented inline.

### DUI URL — Required for YouTube

YouTube's IFrame API blocks `nui://` origins (Error 163). The DUI page must be served over **HTTPS**.

```lua
-- config.lua

-- Default: use RDE's hosted copy (recommended for most servers)
Config.DuiUrl = 'https://rd-elite.com/Files/oxmedia-dui/'

-- Or host web/index.html yourself:
-- Config.DuiUrl = 'https://your-domain.com/oxmedia-dui/'
-- Config.DuiUrl = 'https://your-name.github.io/oxmedia-dui/'
```

> Direct MP4/MP3/WebM links do **not** require HTTPS for the DUI — only YouTube (and Twitch to a lesser extent).

### Language

```lua
Config.Locale = GetConvar('ox:locale', 'en')  -- 'en' or 'de'

-- Or set server-wide in server.cfg:
--   set ox:locale "de"
```

### Interaction Mode

```lua
Config.UseTarget = true   -- true = ox_target (third-eye) | false = E-key + TextUI
```

### Permissions

```lua
Config.UsePermissions = true

Config.AdminSystem = {
    checkOrder    = { 'ace', 'oxcore', 'steam' },   -- first match wins
    acePermission = 'rde_oxmedia.admin',
    oxGroups      = { admin = true, superadmin = true },
    steamIds      = {},   -- 'steam:110000XXXXXXXXX'
}
```

Add ACE in `server.cfg`:
```
add_ace group.admin rde_oxmedia.admin allow
```

### Supported Platforms

```lua
Config.AllowYouTube     = true   -- YouTube videos & livestreams
Config.AllowTwitch      = true   -- Twitch livestreams & VODs
Config.AllowDirectLinks = true   -- MP4, MP3, WebM, HLS streams
```

### Audio

```lua
Config.EnableAttenuation     = true   -- distance-based volume fade
Config.EnableRoomAttenuation = true   -- quieter through walls / different rooms
Config.DiffRoomVolume        = 0.3    -- volume multiplier for different rooms (0–1)
```

### Render Distance

```lua
Config.MaxRenderDistance   = 50.0   -- metres — DUI culled beyond this (VRAM saver)
Config.InteractionDistance = 2.5    -- metres — E-key / TextUI / ox_target activation
```

---

## 🏗️ Architecture — Three Entity Classes

rde_oxmedia handles three distinct entity types transparently. Players see the same menu regardless of which class the device is.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ENTITY CLASS ROUTING                         │
├─────────────────┬───────────────────────┬───────────────────────────┤
│  NETWORKED      │  NON-NETWORKED        │  RDE_PROPS                │
│  net:<netId>    │  ent:<handle>         │  prop:<propId>            │
├─────────────────┼───────────────────────┼───────────────────────────┤
│ Player-placed   │ Static world map      │ Props spawned via         │
│ props, vehicle  │ props (world TVs,     │ rde_props — client-       │
│ props with NetId│ map decorations)      │ spawned, no NetId         │
├─────────────────┼───────────────────────┼───────────────────────────┤
│ Sync via        │ Local only — each     │ Sync via                  │
│ Entity StateBag │ client manages state  │ GlobalState[              │
│ 'oxmedia'       │ independently         │ 'oxmedia_prop_<propId>']  │
├─────────────────┼───────────────────────┼───────────────────────────┤
│ All players     │ Only you see/hear     │ All players see/hear      │
│ see/hear same   │ what you play         │ same content              │
└─────────────────┴───────────────────────┴───────────────────────────┘
```

---

## 🐉 rde_props Integration

rde_oxmedia natively supports props placed via **[rde_props](https://github.com/RedDragonElite/rde_props)**. Because rde_props entities are client-spawned, they have no NetId — rde_oxmedia uses a dedicated `GlobalState` path instead of Entity StateBags.

### Sync Flow

```
Player approaches a placed TV prop
        ↓
entityKey() detects: exports.rde_props:getPropIdByEntity(entity)
        ↓
propId found → key = 'prop:<propId>'
        ↓
Player opens menu → TriggerServerEvent('rde_oxmedia:server:propStart', propId, data)
        ↓
Server: validates URL + permissions
        ↓
Server: GlobalState['oxmedia_prop_<propId>'] = data
        ↓
ALL clients: AddStateBagChangeHandler('', 'global') fires
        ↓
Clients with this prop entity spawned → startDevice(entity, data)
        ↓
DUI renders + audio plays in 3D for all players in range
```

### Required rde_props Version

rde_props **v1.0.1+** is required. The following exports must be present (they are in v1.0.1+):

```lua
exports('getPropIdByEntity', function(entity) ... end)
exports('getAllEntities',    function() return State.entities end)
```

### No Setup Needed

If `rde_props` is running when `rde_oxmedia` starts, prop sync is automatic. The ox_lib menu shows a `🐉 RDE Prop` badge for these entities.

---

## 🎮 Usage

### Playing Media

1. Walk up to any TV, radio, monitor, speaker, etc. in the world
2. Either: **third-eye the device** (ox_target mode) **or** press **E** (TextUI mode)
3. Select **▶️ Play Media**
4. Paste a URL:
   - YouTube: `https://www.youtube.com/watch?v=VIDEO_ID`
   - Twitch: `https://www.twitch.tv/CHANNEL`
   - Direct: `https://example.com/video.mp4` / `https://example.com/stream.m3u8`
5. Set volume (0–100)
6. Everyone nearby sees and hears the same content

### Controls While Playing

| Button | Action |
|--------|--------|
| ⏸️ Pause / Resume | Toggle playback — synced to all players |
| ⏹️ Stop | Stop media — synced to all players |
| 🔊 Volume | Change volume — synced to all players |
| 🔗 Change URL | Replace currently playing media |
| ℹ️ Now Playing | Shows current URL |

---

## 🛡️ Admin Commands

| Command | Permission | Description |
|---------|-----------|-------------|
| `/oxmedia` | Everyone | Open media player for nearest device |
| `/oxmedia_stop` | Everyone | Stop media on nearest device |
| `/oxmedia_clear` | `group.admin` | Stop all active devices server-wide |

---

## 📡 How Multiplayer Sync Works

### Networked Props (standard, player-placed)
```
TriggerServerEvent → Server validates → Entity(ent).state:set('oxmedia', data, true)
        → AddStateBagChangeHandler('oxmedia') fires on ALL clients → startDevice()
```

### rde_props Entities (client-spawned)
```
TriggerServerEvent → Server validates → GlobalState['oxmedia_prop_<propId>'] = data
        → AddStateBagChangeHandler('', 'global') fires on ALL clients → startDevice()
```

### World Props (static map — local only)
```
Direct local startDevice() call → No server round-trip
        → Only your client plays — labelled "🌐 Local playback only" in menu
```

### Late-Join Sync
The late-join thread runs every 2 seconds. When a player enters render distance of an active networked prop, it calls the `rde_oxmedia:getDeviceState` callback which returns the current URL, volume, paused state, and corrected `currentTime` (server adjusts for elapsed seconds since last time report).

---

## 🖥️ Adding Custom Device Models

In `config.lua`, add entries to `Config.Devices`:

```lua
-- TV with named render target (preferred — most GTA props support this):
{ model = 'your_prop_model', type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },

-- TV with texture replacement fallback (for props without a named render target):
{ model = 'your_prop_model', type = 'tv', audioRange = 20.0,
  screenTxd = 'your_prop_model', screenTex = 'your_prop_model_emissive_d' },

-- Radio / speaker (audio only — no screen rendering):
{ model = 'your_speaker_model', type = 'radio', audioRange = 25.0 },
```

The `Config.DeviceLookup` table is built automatically on resource start — no other changes needed.

> **Finding render targets:** Use [Pleb Masters Forge](https://forge.plebmasters.de/objects) or the FiveM native `GetNamedRendertargetRenderId` to check if a model has a named render target.

---

## 🌍 Adding a Language

1. Copy `locales/en.lua` → `locales/xx.lua`
2. Translate all string values
3. Set `Config.Locale = 'xx'` or add `set ox:locale "xx"` to `server.cfg`

---

## 🔧 Troubleshooting

**Black screen / no video on TV**
- Verify `Config.DuiUrl` points to a reachable HTTPS URL
- Open the URL in a browser — if it 404s, the DUI page isn't hosted correctly
- Check browser console for `Error 163` → your DUI URL is on a blocked origin

**No audio**
- Player must be within the device's `audioRange` (configured per-model in `Config.Devices`)
- Check `Config.DefaultVolume` and `Config.EnableAttenuation` — attenuation at close range is still calculated
- Verify `Config.Enable3DAudio = true`

**ox_target not showing**
- `ox_target` must start before `rde_oxmedia` in `server.cfg`
- Set `Config.UseTarget = true` in `config.lua`
- Check `Config.TargetDistance` — default is 2.5m

**World TV plays only for me**
- By design. Static map props are non-networked GTA entities — each client is independent.
- The menu labels these with **"🌐 Local playback only"**.
- For shared playback on static props, spawn them via `rde_props` instead.

**rde_props TV not syncing**
- Ensure rde_props **v1.0.1+** is running — check for `getPropIdByEntity` and `getAllEntities` exports
- Run `GetResourceState('rde_props')` in F8 console — must return `'started'`
- The 2s late-join sync thread will catch props that spawned before media started

**Late joiner has wrong playback position**
- The time reporter thread runs every 5 seconds — maximum drift is ~5s for video on demand
- For live streams (Twitch, HLS) this is irrelevant
- For pre-recorded content, the position self-corrects on the next sync tick

---

## 🔁 Migrating from PMMS

1. Comment out `ensure pmms` and `ensure pmms-dui` in `server.cfg`
2. Add `ensure rde_oxmedia`
3. Set `Config.DuiUrl` and restart — no data migration (StateBags are session-only)

**Advantages over PMMS:**
- StateBag/GlobalState sync vs legacy event flooding → faster, more reliable
- Native rde_props integration out of the box
- No separate DUI resource required
- ox_core native — no ESX shims
- Late-join sync with corrected playback position
- Per-device admin lock
- Configurable platform whitelist (disable YouTube-only, direct-only, etc.)

---

## 🧩 Exports

### Client
```lua
-- Start media on an entity locally
exports.rde_oxmedia:startDevice(entity, { url='https://...', volume=80 })

-- Stop media on an entity
exports.rde_oxmedia:stopDevice(entity)

-- Get all currently active devices
local devices = exports.rde_oxmedia:getActiveDevices()
```

### Server
```lua
-- Get/set device state for networked props
exports.rde_oxmedia:setDeviceState(netId, data)
exports.rde_oxmedia:getDeviceState(netId)

-- Get/set device state for rde_props entities
exports.rde_oxmedia:setPropDeviceState(propId, data)
exports.rde_oxmedia:getPropDeviceState(propId)

-- Get all active devices (both tables)
local nets  = exports.rde_oxmedia:getActiveDevices()
local props = exports.rde_oxmedia:getActivePropDevices()

-- Check admin permission for a player source
local isAdmin = exports.rde_oxmedia:hasPermission(source, 'admin')
```

---

## 📝 Changelog

### v1.0.0-alpha — Initial Public Release
- ✨ Full StateBag multiplayer sync for networked props (Entity StateBag `oxmedia`)
- ✨ rde_props integration — GlobalState sync path for client-spawned entities
- ✨ Three-tier entity key system: `net:<netId>` · `ent:<handle>` · `prop:<propId>`
- ✨ Server events for networked: `start` · `stop` · `togglePause` · `setVolume` · `lock`
- ✨ Server events for props: `propStart` · `propStop` · `propTogglePause` · `propSetVolume`
- ✨ Admin `clearAll` — clears both networked and prop devices
- ✨ Late-join proximity sync thread (2 s cadence) with server-corrected playback position
- ✨ Time reporter (5 s cadence) for accurate late-join position on pre-recorded content
- ✨ 3D proximity audio with configurable distance attenuation + room attenuation
- ✨ DUI rendering — named render targets + AddReplaceTexture fallback
- ✨ 40+ supported GTA prop models out of the box
- ✨ ox_target and E-key/TextUI dual interaction mode
- ✨ Per-device admin lock
- ✨ ACE + ox_core group + Steam ID permission system
- ✨ Optional rde_nostr_log integration
- ✨ English + German locales
- 🐛 **FIX:** GlobalState tombstone pattern on prop deletion prevents clients from missing stop events (Standards Anti-Pattern #4)
- 🐛 **FIX:** `Log()` helper added — debug output via consistent `[RDE_OXMEDIA]` prefix
- 🔧 `immediate` flag on `setPropDeviceState` for clean resource-stop cleanup

---

## 📜 License

**Black Flag Source License v6.66**

Free forever. No paywalls. No Tebex. No escrow. See `LICENSE` for full terms.

---

## ❤️ Credits

Inspired by PMMS. Rewritten from scratch for the ox_core ecosystem.  
No PMMS code was copied — this is a clean, purpose-built implementation.

**Integrates with [rde_props](https://github.com/RedDragonElite/rde_props) v1.0.1+**

---

<div align="center">

**Made with ❤️ for the ox_core community**

🐉 [Red Dragon Elite](https://rd-elite.com) · [GitHub](https://github.com/RedDragonElite) · [rde_props](https://github.com/RedDragonElite/rde_props)

_Free code. Free minds._

</div>
