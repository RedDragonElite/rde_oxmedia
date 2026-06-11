fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'rde_oxmedia'
author      'Red Dragon Elite | SerpentsByte'
description 'Next-generation media streaming — StateBag sync, GlobalState prop sync, proximity audio, DUI rendering'
version     '1.0.1'
repository  'https://github.com/RedDragonElite/rde_oxmedia'

dependencies {
    '/server:7290',
    'ox_lib',
    'ox_core',
}

optional_dependencies {
    'ox_target',
    'rde_props',
}

-- ox_lib must load first so `lib` global is available everywhere
shared_script '@ox_lib/init.lua'

shared_scripts {
    'config.lua',
    -- locales/*.lua intentionally NOT in shared_scripts:
    -- these files only contain `return {...}` and are loaded on-demand
    -- via lib.load() in client.lua. Running them as shared_scripts
    -- would execute them globally but discard the return value.
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

files {
    'web/index.html',
    'web/mediaelement-and-player.min.js',
    'web/mediaelementplayer.min.js',
}

-- NOTE: No ui_page — control UI uses ox_lib context menus only.
-- DUI is created internally via CreateDui() pointing to Config.DuiUrl (external HTTPS).
-- This is required for YouTube's IFrame API (Error 163 fix).
