# 📺 RDE OxMedia — Next-Gen Media Streaming for FiveM

[![Version](https://img.shields.io/badge/version-1.0.1--alpha-red?style=for-the-badge&logo=github)](https://github.com/RedDragonElite/rde_oxmedia/releases)
[![Status](https://img.shields.io/badge/status-EARLY%20ALPHA-orange?style=for-the-badge)](https://github.com/RedDragonElite/rde_oxmedia)
[![License](https://img.shields.io/badge/license-RDE%20Black%20Flag%20v6.66-black?style=for-the-badge)](LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-orange?style=for-the-badge)](https://fivem.net)
[![ox_core](https://img.shields.io/badge/ox__core-Required-blue?style=for-the-badge)](https://github.com/communityox/ox_core)
[![Free](https://img.shields.io/badge/price-FREE%20FOREVER-brightgreen?style=for-the-badge)](https://github.com/RedDragonElite)

**The PMMS replacement the ox_core community actually deserves.**  
Stream YouTube videos and direct media on any TV, monitor, laptop, cinema screen, radio, speaker, or boombox in GTA V — full server-authoritative multiplayer sync, native rde_props integration, 3D proximity audio. Zero database. Zero SQL. Zero Tebex.

Built on ox_core · ox_lib · ox_target · rde_props

*Built by [Red Dragon Elite](https://rd-elite.com) | SerpentsByte · v1.0.0-alpha*

> **⚠️ EARLY ALPHA — ACTIVE DEVELOPMENT**
>
> Core functionality is fully working. YouTube + direct media playback, full StateBag sync, rde_props integration and 3D audio are all production-ready.
> API surface may change between alpha releases.

---

## 📖 Table of Contents

- [Why RDE OxMedia?](#-why-rde-oxmedia)
- [Features](#-features)
- [Dependencies](#-dependencies)
- [Installation](#-installation)
- [Configuration](#️-configuration)
- [Architecture](#️-architecture--three-entity-classes)
- [rde_props Integration](#-rde_props-integration)
- [Usage](#-usage)
- [Admin Commands](#️-admin-commands)
- [How Multiplayer Sync Works](#-how-multiplayer-sync-works)
- [Adding Custom Devices](#️-adding-custom-device-models)
- [Adding a Language](#-adding-a-language)
- [Exports & Developer API](#-exports--developer-api)
- [Troubleshooting](#-troubleshooting)
- [Migrating from PMMS](#-migrating-from-pmms)
- [Changelog](#-changelog)
- [License](#-license)

---

## 🔥 Why RDE OxMedia?

Most media scripts are either abandoned, bloated, or locked behind Tebex. RDE OxMedia is different:

| Feature | PMMS / Generic Scripts | RDE OxMedia |
|---|---|---|
| Multiplayer sync method | Legacy network events | ✅ Entity StateBags |
| rde_props integration | ❌ | ✅ GlobalState path |
| 3D proximity audio | ❌ Flat volume | ✅ Distance + room attenuation |
| Late-join sync | ❌ | ✅ Corrected playback position |
| World prop support | ❌ | ✅ Local mode, clearly labelled |
| Per-device lock | ❌ | ✅ Admin lock system |
| Permission system | ❌ | ✅ ACE + ox_core + Steam ID |
| Separate DUI resource | ✅ Required | ❌ Not needed |
| Database required | ✅ | ❌ Pure StateBag / GlobalState |
| Nostr logging | ❌ | ✅ Optional rde_nostr_log |
| Multi-language | ❌ | ✅ EN + DE built-in |
| Price | €20–€40 on Tebex | ✅ Free forever |

---

## ✨ Features

### 🎮 Gameplay
- **StateBag multiplayer sync** — play/pause/stop/volume is server-authoritative, broadcast to all clients in proximity instantly
- **YouTube + direct MP4/MP3/WebM/HLS** support
- **3D proximity audio** — distance-based volume attenuation, room attenuation across interiors, per-device audio range
- **Late-join sync** — players joining mid-stream get the correct playback position automatically
- **Dual interaction modes** — `ox_target` third-eye or E-key + TextUI (configurable)
- **Per-device admin lock** — admins can lock any device so only admins can change it
- **World prop support** — static map TVs work in local mode, clearly labelled

### 🚀 Technical
- **rde_props native integration** — client-spawned TV/radio props sync via `GlobalState` — no NetId required
- **DUI rendering on 40+ GTA prop models** — flat-screen TVs, CRT TVs, monitors, laptops, cinema screens, arena displays, DLC props
- **Three-tier entity key system** — `net:<netId>` · `ent:<handle>` · `prop:<propId>`
- **Named render targets + AddReplaceTexture fallback** — full prop model coverage
- **Zero database** — no SQL, no table imports, pure StateBag/GlobalState architecture

### 🌍 Quality of Life
- **Multi-language** — English + German built-in, trivially extensible
- **Triple-layer permission system** — ACE permissions → ox_core groups → Steam ID whitelist
- **Optional rde_nostr_log integration** — decentralized audit trail
- **Admin `clearAll`** — wipe all active devices server-wide with one command

---

## 📦 Dependencies

| Resource | Required | Notes |
|---|---|---|
| [ox_lib](https://github.com/communityox/ox_lib) | ✅ Required | UI, callbacks, commands |
| [ox_core](https://github.com/communityox/ox_core) | ✅ Required | Player/character framework |
| [ox_target](https://github.com/communityox/ox_target) | ⚠️ Optional | Only if `Config.UseTarget = true` |
| [rde_props](https://github.com/RedDragonElite/rde_props) | ⚠️ Optional | Only if you want prop media sync |
| [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) | ⚠️ Optional | Decentralized logging — recommended |

> `oxmysql` is **not required** — this resource has zero database footprint.

---

## 🚀 Installation

### 1. Clone or download

```
cd resources
git clone https://github.com/RedDragonElite/rde_oxmedia.git
```

### 2. Add to `server.cfg`

```
ensure ox_lib
ensure ox_core
ensure ox_target      # optional — only if Config.UseTarget = true
ensure rde_props      # optional — only if you want prop media sync
ensure rde_nostr_log  # optional
ensure rde_oxmedia
```

> **Order matters.** `rde_oxmedia` must start **after** all its dependencies.

### 3. Set Config.DuiUrl and restart

```
start rde_oxmedia
```

No SQL. No imports. Done.

---

## ⚙️ Configuration

Edit `config.lua` — everything is documented inline.

### DUI URL — Required for YouTube

YouTube's IFrame API blocks `nui://` origins (Error 163). The DUI must be served over **HTTPS**.

```lua
-- Use RDE's hosted copy — works out of the box:
Config.DuiUrl = 'https://rd-elite.com/Files/oxmedia-dui/'

-- Or self-host web/index.html anywhere over HTTPS:
-- Config.DuiUrl = 'https://your-domain.com/oxmedia-dui/'
```

### Language

```lua
Config.Locale = GetConvar('ox:locale', 'en')   -- 'en' or 'de'
-- Or in server.cfg:  set ox:locale "de"
```

### Interaction Mode

```lua
Config.UseTarget = true   -- true = ox_target | false = E-key + TextUI
```

### Permissions

```lua
Config.UsePermissions = true

Config.AdminSystem = {
    checkOrder    = { 'ace', 'oxcore', 'steam' },
    acePermission = 'rde_oxmedia.admin',
    oxGroups      = { admin = true, superadmin = true },
    steamIds      = {},   -- 'steam:110000XXXXXXXXX'
}
```

```
# server.cfg
add_ace group.admin rde_oxmedia.admin allow
```

### Audio

```lua
Config.EnableAttenuation     = true   -- distance-based volume fade
Config.EnableRoomAttenuation = true   -- quieter through walls / different rooms
Config.DiffRoomVolume        = 0.3    -- volume multiplier for different rooms (0–1)
```

### Render Distance

```lua
Config.MaxRenderDistance   = 50.0   -- DUI culled beyond this (saves VRAM)
Config.InteractionDistance = 2.5    -- E-key / TextUI / ox_target range
```

---

## 🏗️ Architecture — Three Entity Classes

rde_oxmedia routes three distinct entity types through a single unified menu. Players never see the difference.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ENTITY CLASS ROUTING                         │
├─────────────────┬───────────────────────┬───────────────────────────┤
│  NETWORKED      │  NON-NETWORKED        │  RDE_PROPS                │
│  net:<netId>    │  ent:<handle>         │  prop:<propId>            │
├─────────────────┼───────────────────────┼───────────────────────────┤
│ Player-placed   │ Static world map      │ Props spawned via         │
│ props, vehicle  │ props — world TVs,    │ rde_props — client-       │
│ props w/ NetId  │ map decorations       │ spawned, no NetId         │
├─────────────────┼───────────────────────┼───────────────────────────┤
│ Entity StateBag │ Local only — each     │ GlobalState[              │
│   'oxmedia'     │ client independent    │ 'oxmedia_prop_<propId>']  │
├─────────────────┼───────────────────────┼───────────────────────────┤
│ All players     │ You only              │ All players               │
│ hear the same   │                       │ hear the same             │
└─────────────────┴───────────────────────┴───────────────────────────┘
```

---

## 🐉 rde_props Integration

rde_oxmedia natively supports props placed via **[rde_props](https://github.com/RedDragonElite/rde_props)**. Because rde_props entities are client-spawned and have no NetId, a dedicated `GlobalState` sync path handles them — fully transparent to the player.

### Sync Flow

```
Player opens menu on a placed TV prop
        ↓
entityKey() → exports.rde_props:getPropIdByEntity(entity)
        ↓
propId found → key = 'prop:<propId>'
        ↓
TriggerServerEvent('rde_oxmedia:server:propStart', propId, data)
        ↓
Server validates URL + permissions
        ↓
GlobalState['oxmedia_prop_<propId>'] = data
        ↓
AddStateBagChangeHandler('', 'global') fires on ALL clients
        ↓
Clients with this prop entity loaded → startDevice(entity, data)
        ↓
DUI renders + 3D audio plays for everyone in range
```

### Requirements

rde_props **v1.0.1+** — needs these exports (already present):

```lua
exports('getPropIdByEntity', function(entity) ... end)
exports('getAllEntities',    function() return State.entities end)
```

If `rde_props` is running when `rde_oxmedia` starts, everything is automatic. The menu shows a `🐉 RDE Prop` badge for prop entities. No config changes needed.

---

## 🎮 Usage

### Playing Media

1. Walk up to any TV, radio, monitor, speaker in the world
2. **Third-eye** it (ox_target) **or** press **E** (TextUI mode)
3. Select **▶️ Play Media**
4. Drop a URL:
   - YouTube: `https://www.youtube.com/watch?v=VIDEO_ID`
   - Direct: `https://example.com/video.mp4` · `.webm` · `.mp3` · `.m3u8`
5. Set volume (0–100)
6. Everyone nearby sees and hears the same content

### Controls While Playing

| Button | Action |
|--------|--------|
| ⏸️ Pause / Resume | Toggle playback — synced to all |
| ⏹️ Stop | Stop media — synced to all |
| 🔊 Volume | Change volume — synced to all |
| 🔗 Change URL | Swap to a different source |
| ℹ️ Now Playing | Shows current URL |

---

## 🛡️ Admin Commands

| Command | Who | Description |
|---------|-----|-------------|
| `/oxmedia` | Everyone | Open media player for nearest device |
| `/oxmedia_stop` | Everyone | Stop media on nearest device |
| `/oxmedia_clear` | `group.admin` | Stop all active devices server-wide |

---

## 📡 How Multiplayer Sync Works

### Networked Props (standard, player-placed)
```
TriggerServerEvent → validate → Entity(ent).state:set('oxmedia', data, true)
  → AddStateBagChangeHandler('oxmedia') fires on ALL clients → startDevice()
```

### rde_props Entities (client-spawned)
```
TriggerServerEvent → validate → GlobalState['oxmedia_prop_<propId>'] = data
  → AddStateBagChangeHandler('', 'global') fires on ALL clients → startDevice()
```

### World Props (static map — local only)
```
startDevice() locally — no server round-trip
  → only your client plays — labelled "🌐 Local playback only" in menu
```

### Late-Join
Proximity thread runs every 2 seconds. On entering render distance of an active networked device, a server callback returns the current URL, volume, pause state, and corrected `currentTime`. Drift is max ~5s — negligible for streams, self-correcting for VOD.

---

## 🖥️ Adding Custom Device Models

In `config.lua`, add to `Config.Devices`:

```lua
-- TV — named render target (preferred):
{ model = 'your_prop_model', type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },

-- TV — texture replacement fallback (no render target):
{ model = 'your_prop_model', type = 'tv', audioRange = 20.0,
  screenTxd = 'your_prop_model', screenTex = 'your_prop_model_emissive_d' },

-- Radio / speaker (audio only — no screen):
{ model = 'your_speaker_model', type = 'radio', audioRange = 25.0 },
```

`Config.DeviceLookup` is built automatically on resource start — no other changes needed.

---

## 🌍 Adding a Language

1. Copy `locales/en.lua` → `locales/xx.lua`
2. Translate all values
3. `Config.Locale = 'xx'` or `set ox:locale "xx"` in `server.cfg`

---

## 🔧 Exports & Developer API

### Client

```lua
-- Start media on an entity locally
exports.rde_oxmedia:startDevice(entity, { url = 'https://...', volume = 80 })

-- Stop media on an entity
exports.rde_oxmedia:stopDevice(entity)

-- Get all currently active devices
local devices = exports.rde_oxmedia:getActiveDevices()
```

### Server

```lua
-- Networked prop state
exports.rde_oxmedia:setDeviceState(netId, data)
exports.rde_oxmedia:getDeviceState(netId)

-- rde_props entity state
exports.rde_oxmedia:setPropDeviceState(propId, data)
exports.rde_oxmedia:getPropDeviceState(propId)

-- Get all active devices (both tables)
local nets  = exports.rde_oxmedia:getActiveDevices()
local props = exports.rde_oxmedia:getActivePropDevices()

-- Permission check
local ok = exports.rde_oxmedia:hasPermission(source, 'admin')
```

---

## 🐛 Troubleshooting

**Black screen / no video on TV**  
→ `Config.DuiUrl` must point to a live HTTPS URL. Open it in a browser first. If it 404s the DUI page is missing.

**No audio**  
→ Player must be within the device's `audioRange`. At close range `EnableAttenuation` still reduces volume proportionally — this is correct.

**ox_target not appearing**  
→ `ox_target` must `ensure` before `rde_oxmedia` in `server.cfg`. Set `Config.UseTarget = true`.

**World TV only plays for me**  
→ Working as intended. Static map props are non-networked GTA entities. The menu says "🌐 Local playback only". Use `rde_props` to spawn the prop for shared playback.

**rde_props TV not syncing**  
→ Requires rde_props v1.0.1+. Check `GetResourceState('rde_props')` in F8 — must be `'started'`. The 2s sync thread catches props that spawned before media started.

**Late joiner has wrong playback position**  
→ The time reporter runs every 5s — max drift is ~5s on VOD. For live streams this is irrelevant.

---

## 🔁 Migrating from PMMS

```
1. Comment out:  ensure pmms
                 ensure pmms-dui
2. Add:          ensure rde_oxmedia
3. Set Config.DuiUrl and restart.
```

No data migration. StateBags are session-only. Done in 60 seconds.

**Advantages over PMMS:**
- StateBag/GlobalState sync vs legacy event flooding → faster, more reliable
- rde_props integration out of the box, no hacks
- No separate DUI resource needed
- Native ox_core — zero ESX shims
- Late-join sync with corrected position
- Per-device lock + full permission system

---

## 📝 Changelog

### v1.0.2-alpha — Hotfix
- 🔴 **HOTFIX** `fxmanifest.lua` — `locales/*.lua` re-added to `shared_scripts`; `lib.load()` uses `LoadResourceFile` which requires files registered in the manifest — caused `file 'locales.en' not found` crash on resource start

### v1.0.1-alpha — Bug Fix Release
- 🔴 **BUG-01** `client.lua` — time reporter: `dev.data.startTime` → `dev.startTime` (wrong table level — reporter never fired since release)
- 🟡 **BUG-02** `client.lua` — `ReleaseNamedRendertarget()` missing in `stopByKey` (VRAM leak on stop/start cycles)
- 🔴 **BUG-03** `server.lua` — `/oxmedia_clear` used `TriggerEvent` → `source=0`, permission check bypassed, `notify` was a no-op; logic inlined directly into command handler
- 🟡 **BUG-04** `server.lua` — `volume=0` rejected by `not volume` check (`0` is truthy in Lua, use `volume == nil`); players couldn't mute devices
- 📄 **LICENSE** — Black Flag Source License v6.66 added as standalone file

### v1.0.0-alpha — Initial Public Release
- ✨ Full StateBag sync for networked props (Entity StateBag `oxmedia`)
- ✨ rde_props GlobalState sync path — `net:` · `ent:` · `prop:` key system
- ✨ Server events: `start` · `stop` · `togglePause` · `setVolume` · `lock`
- ✨ Prop events: `propStart` · `propStop` · `propTogglePause` · `propSetVolume`
- ✨ Admin `clearAll` — wipes both networked and prop devices
- ✨ Late-join proximity sync (2s) with server-corrected playback position
- ✨ Time reporter (5s) for accurate position on VOD
- ✨ 3D proximity audio — distance + room attenuation
- ✨ DUI rendering — named render targets + `AddReplaceTexture` fallback
- ✨ 40+ supported GTA prop models out of the box
- ✨ ox_target + E-key/TextUI dual interaction mode
- ✨ Per-device admin lock
- ✨ Triple-layer permission system (ACE / ox_core groups / Steam ID)
- ✨ Optional rde_nostr_log integration
- ✨ EN + DE locales
- 🐛 **FIX:** GlobalState tombstone on prop deletion — clients no longer miss stop events (Anti-Pattern #4)
- 🐛 **FIX:** `Log()` helper — consistent `[RDE_OXMEDIA]` debug output, no raw prints
- 🔧 `immediate` flag on `setPropDeviceState` for clean resource-stop sequence

---

## 📜 License

```
###################################################################################
#                                                                                 #
#      .:: RED DRAGON ELITE (RDE)  -  BLACK FLAG SOURCE LICENSE v6.66 ::.         #
#                                                                                 #
#   PROJECT:    RDE_OXMEDIA v1.0.0-ALPHA (NEXT-GEN MEDIA STREAMING FOR FIVEM)     #
#   ARCHITECT:  .:: RDE ⧌ Shin [△ ᛋᛅᚱᛒᛅᚾᛏᛋ ᛒᛁᛏᛅ ▽] ::. | https://rd-elite.com     #
#   ORIGIN:     https://github.com/RedDragonElite                                 #
#                                                                                 #
#   WARNING: THIS CODE IS PROTECTED BY DIGITAL VOODOO AND PURE HATRED FOR LEAKERS #
#                                                                                 #
#   [ THE RULES OF THE GAME ]                                                     #
#                                                                                 #
#   1. // THE "FUCK GREED" PROTOCOL (FREE USE)                                    #
#      You are free to use, edit, and abuse this code on your server.             #
#      Learn from it. Break it. Fix it. That is the hacker way.                   #
#      Cost: 0.00€. If you paid for this, you got scammed by a rat.               #
#                                                                                 #
#   2. // THE TEBEX KILL SWITCH (COMMERCIAL SUICIDE)                              #
#      Listen closely, you parasites:                                             #
#      If I find this script on Tebex, Patreon, or in a paid "Premium Pack":      #
#      > I will DMCA your store into oblivion.                                    #
#      > I will publicly shame your community.                                    #
#      > I hope your server lag spikes to 9999ms every time you blink.            #
#      SELLING FREE WORK IS THEFT. AND I AM THE JUDGE.                            #
#                                                                                 #
#   3. // THE CREDIT OATH                                                         #
#      Keep this header. If you remove my name, you admit you have no skill.      #
#      You can add "Edited by [YourName]", but never erase the original creator.  #
#      Don't be a skid. Respect the architecture.                                 #
#                                                                                 #
#   4. // THE CURSE OF THE COPY-PASTE                                             #
#      This code uses StateBags, GlobalState sync, and DUI rendering.             #
#      If you just copy-paste without reading, it WILL break.                     #
#      Don't come crying to my DMs. RTFM or learn to code.                        #
#                                                                                 #
#   --------------------------------------------------------------------------    #
#   "We build the future on the graves of paid resources."                        #
#   "REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY."                          #
#   --------------------------------------------------------------------------    #
###################################################################################
```

**TL;DR:**
- ✅ Free forever — use it, edit it, learn from it
- ✅ Keep the header — credit where it's due
- ❌ Don't sell it — commercial use = instant DMCA
- ❌ Don't be a skid — copy-paste without reading won't work anyway

---

## 🌐 Community & Support

| | |
|---|---|
| 🐙 GitHub | [RedDragonElite](https://github.com/RedDragonElite) |
| 🌍 Website | [rd-elite.com](https://rd-elite.com) |
| 🔵 Nostr (RDE) | [RedDragonElite](https://primal.net/p/nprofile1qqsv8km2w8yr0sp7mtk3t44qfw7wmvh8caqpnrd7z6ll6mn9ts03teg9ha4rl) |
| 🔵 Nostr (Shin) | [SerpentsByte](https://primal.net/p/nprofile1qqs8p6u423fappfqrrmxful5kt95hs7d04yr25x88apv7k4vszf4gcqynchct) |
| 📺 RDE OxMedia | [rde_oxmedia](https://github.com/RedDragonElite/rde_oxmedia) |
| 🎯 RDE Props | [rde_props](https://github.com/RedDragonElite/rde_props) |
| 🚪 RDE Doors | [rde_doors](https://github.com/RedDragonElite/rde_doors) |
| 😴 RDE Sleep | [rde_sleep](https://github.com/RedDragonElite/rde_sleep) |
| 📡 RDE Nostr Log | [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) |

**When asking for help, always include:**
- Full error from server console or txAdmin
- Your `server.cfg` resource start order
- ox_core / ox_lib versions in use

**Please DON'T:**
- ❌ DM for basic setup questions — read the docs first
- ❌ Open issues without error logs
- ❌ Ask for paid support — this is free software

**Please DO:**
- ✅ Star the repo if it helped you
- ✅ Open issues with proper reproduction steps
- ✅ Share your setup — community feedback makes this better

---

*"We build the future on the graves of paid resources."*

**REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY.**

🐉 Made with 🔥 by [Red Dragon Elite](https://rd-elite.com)

[⬆ Back to Top](#-rde-oxmedia--next-gen-media-streaming-for-fivem)
