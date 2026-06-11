Config = {}

-- ============================================================
-- LOCALE
-- ============================================================
-- Set the server language here, or via convar: set ox:locale "de"
-- Normalises "de-DE" / "en-US" etc. → "de" / "en"
Config.Locale = GetConvar('ox:locale', 'en'):match('^(%a+)')

-- ============================================================
-- DUI URL — EXTERNAL HTTPS REQUIRED FOR YOUTUBE
-- ============================================================
-- YouTube's IFrame API blocks nui:// origins (Error 163).
-- Point this to your own HTTPS-hosted copy of web/index.html,
-- OR use the RDE GitHub Pages default below.
-- ============================================================
Config.DuiUrl = 'https://rd-elite.com/Files/oxmedia-dui/'
-- Config.DuiUrl = 'https://YOUR-NAME.github.io/oxmedia-dui/'

-- ============================================================
-- GENERAL
-- ============================================================
Config.MaxRenderDistance   = 50.0   -- metres: beyond this DUI is culled (saves VRAM)
Config.InteractionDistance = 2.5    -- metres: E-key / TextUI detection radius
Config.DefaultVolume       = 100    -- 0–100
Config.MaxVolume           = 100
Config.VolumeStep          = 5

-- ============================================================
-- INTERACTION SYSTEM
-- ============================================================
Config.UseTarget      = true           -- true = ox_target  |  false = E key + TextUI
Config.TargetIcon     = 'fas fa-tv'
Config.TargetDistance = 2.5

-- ============================================================
-- PERMISSIONS
-- ============================================================
Config.UsePermissions = true

Config.AdminSystem = {
    -- Order in which admin checks are performed (first match wins)
    checkOrder    = { 'ace', 'oxcore', 'steam' },

    -- ACE permission node (server.cfg: add_ace group.admin rde_oxmedia.admin allow)
    acePermission = 'rde_oxmedia.admin',

    -- ox_core groups that count as admin
    oxGroups      = { admin = true, superadmin = true },

    -- Steam ID whitelist fallback (format: 'steam:110000XXXXXXXXX')
    steamIds      = {},
}

-- ============================================================
-- SUPPORTED PLATFORMS
-- ============================================================
Config.AllowYouTube     = true   -- YouTube videos & livestreams
Config.AllowTwitch      = true   -- Twitch livestreams & VODs
Config.AllowDirectLinks = true   -- Direct MP4, MP3, WebM, HLS

-- ============================================================
-- AUDIO
-- ============================================================
Config.EnableAttenuation     = true   -- distance-based volume fade
Config.Enable3DAudio         = true   -- 3D positional audio
Config.EnableRoomAttenuation = true   -- quieter when in a different interior room
Config.DiffRoomVolume        = 0.3    -- volume reduction factor for different rooms (0–1)

-- ============================================================
-- DUI RESOLUTION
-- ============================================================
Config.DuiScreenWidth  = 1280
Config.DuiScreenHeight = 720

-- ============================================================
-- LOGGING (requires rde_nostr_log resource)
-- ============================================================
Config.UseNostrLog      = false          -- set true if rde_nostr_log is present
Config.NostrLogResource = 'rde_nostr_log'
Config.NostrLog = {
    onMediaStart   = true,
    onMediaStop    = true,
    onPauseToggle  = false,
    onVolumeChange = false,
    onLock         = true,
    onClearAll     = true,
}

-- ============================================================
-- DEBUG
-- ============================================================
Config.Debug = false   -- true = ox_target zone outlines visible

-- ============================================================
-- MEDIA DEVICES
-- ============================================================
-- Each entry:
--   model       (string)  — GTA prop model name
--   type        (string)  — 'tv' (has screen) | 'radio' (audio only)
--   audioRange  (number)  — maximum hearing distance in metres
--   renderTarget (string|nil) — named render target for this model (nil = use screenTxd fallback)
--   screenTxd   (string|nil) — txd dict for AddReplaceTexture fallback
--   screenTex   (string|nil) — texture name inside that txd
-- ============================================================
Config.Devices = {

    -- ── Flat-screen TVs ──────────────────────────────────────
    { model = 'prop_tv_flat_01',      type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },
    { model = 'prop_tv_flat_01b',     type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },
    { model = 'prop_tv_flat_02',      type = 'tv', audioRange = 25.0, renderTarget = 'tvscreen' },
    { model = 'prop_tv_flat_02b',     type = 'tv', audioRange = 25.0, renderTarget = 'tvscreen' },
    { model = 'prop_tv_flat_03',      type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },
    { model = 'prop_tv_flat_03b',     type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },
    { model = 'prop_tv_flat_michael', type = 'tv', audioRange = 35.0, renderTarget = 'tvscreen' },
    { model = 'p_tv_flat_01_s',       type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },
    { model = 'prop_tv_flat_01_screen',  type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },
    { model = 'prop_flatscreen_overlay', type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },

    -- ── CRT / Old TVs ────────────────────────────────────────
    { model = 'prop_trev_tv_01', type = 'tv', audioRange = 20.0, renderTarget = 'tvscreen' },
    { model = 'prop_tv_02',      type = 'tv', audioRange = 12.0, renderTarget = 'tvscreen' },
    { model = 'prop_tv_03',      type = 'tv', audioRange = 15.0, renderTarget = 'tvscreen' },
    { model = 'prop_tv_03_overlay', type = 'tv', audioRange = 15.0, renderTarget = 'tvscreen' },

    -- AddReplaceTexture fallback (no named render target)
    { model = 'prop_tv_01', type = 'tv', audioRange = 15.0,
      screenTxd = 'prop_tv_01', screenTex = 'prop_tv_01_emissive_d' },
    { model = 'prop_tv_04', type = 'tv', audioRange = 10.0,
      screenTxd = 'prop_tv_04', screenTex = 'prop_tv_04_emissive_d' },
    { model = 'prop_tv_05', type = 'tv', audioRange = 15.0,
      screenTxd = 'prop_tv_05', screenTex = 'prop_tv_05_emissive_d' },
    { model = 'prop_tv_06', type = 'tv', audioRange = 18.0,
      screenTxd = 'prop_tv_06', screenTex = 'prop_tv_06_emissive_d' },
    { model = 'prop_tv_07', type = 'tv', audioRange = 15.0,
      screenTxd = 'prop_tv_07', screenTex = 'prop_tv_07_emissive_d' },

    -- ── Monitors ─────────────────────────────────────────────
    { model = 'prop_monitor_02',      type = 'tv', audioRange = 12.0, renderTarget = 'tvscreen' },
    { model = 'prop_monitor_w_large', type = 'tv', audioRange = 15.0, renderTarget = 'tvscreen' },
    { model = 'prop_monitor_01a', type = 'tv', audioRange = 10.0,
      screenTxd = 'prop_monitor_01a', screenTex = 'prop_monitor_01a_emissive_d' },
    { model = 'prop_monitor_01b', type = 'tv', audioRange = 10.0,
      screenTxd = 'prop_monitor_01b', screenTex = 'prop_monitor_01b_emissive_d' },
    { model = 'prop_monitor_03b', type = 'tv', audioRange = 8.0,
      screenTxd = 'prop_monitor_03b', screenTex = 'prop_monitor_03b_emissive_d' },

    -- ── Laptops ──────────────────────────────────────────────
    { model = 'prop_laptop_lester2', type = 'tv', audioRange = 5.0, renderTarget = 'tvscreen' },
    { model = 'prop_laptop_lester',  type = 'tv', audioRange = 5.0, renderTarget = 'tvscreen' },
    { model = 'hei_prop_hst_laptop', type = 'tv', audioRange = 5.0, renderTarget = 'tvscreen' },
    { model = 'prop_laptop_01a', type = 'tv', audioRange = 5.0,
      screenTxd = 'prop_laptop_01a', screenTex = 'prop_laptop_01a_emissive_d' },
    { model = 'prop_laptop_02_closed', type = 'tv', audioRange = 5.0,
      screenTxd = 'prop_laptop_02_closed', screenTex = 'prop_laptop_02_closed_emissive_d' },

    -- ── Large / Cinema Screens ───────────────────────────────
    { model = 'prop_big_cin_screen',   type = 'tv', audioRange = 100.0, renderTarget = 'cinscreen' },
    { model = 'v_ilev_cin_screen',     type = 'tv', audioRange = 80.0,  renderTarget = 'cinscreen' },
    { model = 'v_ilev_lest_bigscreen', type = 'tv', audioRange = 60.0,  renderTarget = 'tvscreen'  },
    { model = 'prop_huge_display_01',  type = 'tv', audioRange = 80.0,  renderTarget = 'big_disp'  },
    { model = 'prop_huge_display_02',  type = 'tv', audioRange = 80.0,  renderTarget = 'big_disp'  },
    { model = 'v_ilev_mm_screen',      type = 'tv', audioRange = 60.0,  renderTarget = 'big_disp'  },
    { model = 'v_ilev_mm_screen2',     type = 'tv', audioRange = 60.0,  renderTarget = 'tvscreen'  },

    -- ── DLC / Special Props ──────────────────────────────────
    { model = 'ex_prop_ex_tv_flat_01',           type = 'tv', audioRange = 30.0, renderTarget = 'ex_tvscreen' },
    { model = 'hei_prop_dlc_tablet',             type = 'tv', audioRange = 5.0,  renderTarget = 'tablet' },
    { model = 'sm_prop_smug_tv_flat_01',         type = 'tv', audioRange = 30.0, renderTarget = 'tv_flat_01' },
    { model = 'xm_prop_x17_tv_flat_01',          type = 'tv', audioRange = 30.0, renderTarget = 'tv_flat_01' },
    { model = 'ch_prop_ch_tv_rt_01a',            type = 'tv', audioRange = 30.0, renderTarget = 'ch_tv_rt_01a' },
    { model = 'des_tvsmash_start',               type = 'tv', audioRange = 20.0, renderTarget = 'tvscreen' },
    { model = 'apa_mp_h_str_avunitl_01_b',       type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },
    { model = 'apa_mp_h_str_avunitl_04',         type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },
    { model = 'apa_mp_h_str_avunitm_01',         type = 'tv', audioRange = 25.0, renderTarget = 'tvscreen' },
    { model = 'apa_mp_h_str_avunitm_03',         type = 'tv', audioRange = 25.0, renderTarget = 'tvscreen' },
    { model = 'apa_mp_h_str_avunits_01',         type = 'tv', audioRange = 20.0, renderTarget = 'tvscreen' },
    { model = 'apa_mp_h_str_avunits_04',         type = 'tv', audioRange = 20.0, renderTarget = 'tvscreen' },
    { model = 'hei_heist_str_avunitl_03',        type = 'tv', audioRange = 30.0, renderTarget = 'tvscreen' },
    { model = 'xs_prop_arena_screen_tv_01',      type = 'tv', audioRange = 30.0,  renderTarget = 'screen_tv_01' },
    { model = 'xs_prop_arena_bigscreen_01',      type = 'tv', audioRange = 100.0, renderTarget = 'bigscreen_01' },
    { model = 'vw_prop_vw_cinema_tv_01',         type = 'tv', audioRange = 30.0,  renderTarget = 'tvscreen' },
    { model = 'sm_prop_smug_monitor_01',         type = 'tv', audioRange = 12.0,  renderTarget = 'smug_monitor_01' },
    { model = 'xm_prop_x17_computer_02',         type = 'tv', audioRange = 10.0,  renderTarget = 'monitor_02' },
    { model = 'xm_prop_x17dlc_monitor_wall_01a', type = 'tv', audioRange = 20.0,  renderTarget = 'prop_x17dlc_monitor_wall_01a' },
    { model = 'gr_prop_gr_trailer_tv',           type = 'tv', audioRange = 20.0,  renderTarget = 'gr_trailertv_01' },
    { model = 'gr_prop_gr_trailer_tv_02',        type = 'tv', audioRange = 20.0,  renderTarget = 'gr_trailertv_02' },
    { model = 'gr_prop_gr_trailer_monitor_01',   type = 'tv', audioRange = 12.0,  renderTarget = 'gr_trailer_monitor_01' },
    { model = 'gr_prop_gr_trailer_monitor_02',   type = 'tv', audioRange = 12.0,  renderTarget = 'gr_trailer_monitor_02' },
    { model = 'gr_prop_gr_trailer_monitor_03',   type = 'tv', audioRange = 12.0,  renderTarget = 'gr_trailer_monitor_03' },

    -- ── Radios & Speakers (audio only) ───────────────────────
    { model = 'prop_boombox_01',                   type = 'radio', audioRange = 20.0 },
    { model = 'prop_tapeplayer_01',                type = 'radio', audioRange = 10.0 },
    { model = 'prop_radio_01',                     type = 'radio', audioRange = 8.0  },
    { model = 'prop_ghettoblast_01',               type = 'radio', audioRange = 20.0 },
    { model = 'prop_ghettoblast_02',               type = 'radio', audioRange = 25.0 },
    { model = 'prop_car_boot_01',                  type = 'radio', audioRange = 15.0 },
    { model = 'prop_portable_hifi_01',             type = 'radio', audioRange = 12.0 },
    { model = 'ba_prop_battle_club_speaker_large',  type = 'radio', audioRange = 50.0 },
    { model = 'ba_prop_battle_club_speaker_med',   type = 'radio', audioRange = 35.0 },
    { model = 'ba_prop_battle_club_speaker_small', type = 'radio', audioRange = 20.0 },
    { model = 'prop_speaker_01',                   type = 'radio', audioRange = 30.0 },
    { model = 'prop_speaker_02',                   type = 'radio', audioRange = 25.0 },
    { model = 'prop_speaker_03',                   type = 'radio', audioRange = 20.0 },
    { model = 'prop_speaker_04',                   type = 'radio', audioRange = 15.0 },
    { model = 'prop_speaker_05',                   type = 'radio', audioRange = 25.0 },
    { model = 'prop_speaker_06',                   type = 'radio', audioRange = 30.0 },
    { model = 'prop_speaker_07',                   type = 'radio', audioRange = 20.0 },
    { model = 'prop_speaker_08',                   type = 'radio', audioRange = 15.0 },
    { model = 'sm_prop_smug_radio_01',             type = 'radio', audioRange = 15.0 },
    { model = 'bkr_prop_clubhouse_jukebox_01a',    type = 'radio', audioRange = 30.0 },
    { model = 'bkr_prop_clubhouse_jukebox_01b',    type = 'radio', audioRange = 30.0 },
    { model = 'bkr_prop_clubhouse_jukebox_02a',    type = 'radio', audioRange = 30.0 },
    { model = 'prop_50s_jukebox',                  type = 'radio', audioRange = 25.0 },
    { model = 'prop_jukebox_01',                   type = 'radio', audioRange = 25.0 },
    { model = 'ch_prop_arcade_jukebox_01a',        type = 'radio', audioRange = 25.0 },
}

-- ============================================================
-- AUTO-BUILD LOOKUP TABLE  (do not modify)
-- ============================================================
Config.DeviceLookup = {}
for _, device in ipairs(Config.Devices) do
    Config.DeviceLookup[joaat(device.model)] = device
end
