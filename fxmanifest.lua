fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'
name 'ox_inventory'
author 'MikeyBandz'
version '2.47.8-custom'
repository 'https://github.com/overextended/ox_inventory'
description 'Slot-based inventory with item metadata support'

dependencies {
    '/server:6116',
    '/onesync',
    'oxmysql',
    'ox_lib',
    '/assetpacks',
}

-- ox_target is runtime-required for targeting but intentionally not a hard dependency:
-- ensure/restart ox_target must not cascade-stop ox_inventory (that stack-overflow crashed the server).
-- Start order is enforced in server.cfg (ox_target then ox_inventory).

-- Custom forge model (forge) streamed from /stream folder (with white_sup_table fallback)

data_file 'DLC_ITYP_REQUEST' 'stream/ex_metadata_generic.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/oxlyn_3dprinter.ytyp'

shared_script '@ox_lib/init.lua'

shared_scripts {
    'data/rw/config.lua',
    'data/rw/clothing.lua',
    'data/rw/clothings.lua',
    'data/rw/clothing_presets.lua',
    'data/rw/throw.lua',
    'data/rw/trashbins.lua',
    -- RealWrld 3D printer module (modules/rwprinter) — shared state, in the
    -- standalone resource's documented order: config creates PrinterConfig,
    -- items fills it, locales load before utils reads them.
    'modules/rwprinter/config/config.lua',
    'modules/rwprinter/config/items.lua',
    'modules/rwprinter/locales/en.lua',
    'modules/rwprinter/locales/pt.lua',
    'modules/rwprinter/locales/fr.lua',
    'modules/rwprinter/shared/utils.lua',
    'modules/rwprinter/shared/catalog.lua',
    'modules/rwprinter/bridge/custom.lua',
    'modules/rwprinter/bridge/framework.lua',
    'modules/rwprinter/bridge/inventory.lua',
    'modules/rwprinter/bridge/notify.lua',
}

ox_libs {
    'locale',
    'table',
    'math',
}

server_scripts {
    'lib/server.lua',
    '@oxmysql/lib/MySQL.lua',
    'init.lua',
    -- 3D printer module, server side ('@oxmysql/lib/MySQL.lua' already above)
    'modules/rwprinter/server/database.lua',
    'modules/rwprinter/server/catalog.lua',
    'modules/rwprinter/server/main.lua',
    'modules/rwprinter/server/admin.lua',
    'modules/rwprinter/server/editor.lua',
}

client_scripts {
    'lib/client.lua',
    'rwsoftware.lua',
    'client_exports.lua',
    'init.lua',
    -- 3D printer module, client side
    'modules/rwprinter/client/textui.lua',
    'modules/rwprinter/client/progress.lua',
    'modules/rwprinter/client/printfx.lua',
    'modules/rwprinter/client/head.lua',
    'modules/rwprinter/client/placement.lua',
    'modules/rwprinter/client/main.lua',
    'modules/rwprinter/client/editor.lua',
}

ui_page 'web/build/index.html'
ui_page_preload 'yes'

files {
    'client.lua',
    'client_exports.lua',
    'config.lua',
    'server.lua',
    'locales/*.json',
    'web/build/index.html',
    'web/build/app.html',
    'web/panels/**/*',
    'web/printer/**/*',
    'web/build/assets/*.js',
    'web/build/assets/*.css',
    'web/build/assets/*.png',
    'web/build/assets/*.svg',
    'web/build/assets/*.woff2',
    'web/fonts/**/*',
    'web/fontawesome/**/*',
    'web/images/*.png',
    'web/images/shops/*.png',
    'web/chrome/*.png',
    'web/chrome/*.svg',
    'web/clothing/**/*.png',
    'modules/**/shared.lua',
    'modules/**/server.lua',
    'modules/shops/admin_server.lua',
    'modules/locks.lua',
    'modules/**/client.lua',
    'modules/bridge/client.lua',
    'modules/market/client.lua',
    'modules/gathering/client_mining.lua',
    'modules/gathering/client_scavenging.lua',
    'modules/gathering/server_mining.lua',
    'modules/gathering/server_scavenging.lua',
    'modules/scavenging/*.lua',
    'modules/drops/*.lua',
    'modules/items/ramp.lua',
    'modules/items/special_blueprints.lua',
    'modules/theft/client.lua',
    'modules/theft/server.lua',
    'modules/bridge/server.lua',
    'modules/market/server.lua',
    'modules/forge/*.lua',
    'modules/recycler/*.lua',
    'data/recycler_data.json',
    'modules/crafting/blueprints.lua',
    'modules/rw-weapon-sling/config.lua',
    'modules/rw-weapon-sling/config.json',
    'modules/rw-weapon-sling/shared.lua',
    'modules/rw-weapon-sling/client/*.lua',
    'modules/rw-weapon-sling/server/*.lua',
    'modules/rw_bridge/load_shared.lua',
    'modules/rw_bridge/load_client.lua',
    'modules/rw_bridge/**/*.lua',
    'modules/rw_config/client.lua',
    'modules/rw_integration/client.lua',
    'modules/rw_loader/client.lua',
    'modules/rw_loader/server.lua',
    'modules/utils/target_client.lua',
    'data/rw/*.lua',
    'setup/crafting_database.sql',
    'setup/market_database.sql',
    'data/*.lua',
    'shared/vehiclekeysconfig.lua',
}
