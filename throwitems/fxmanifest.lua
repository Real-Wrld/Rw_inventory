

fx_version 'adamant'
game 'gta5'
version '1.0.6'
author 'rw Resources'
lua54 'yes'

dependencies {
    'ox_lib'
}

files {
    'dui/index.html',
    'dui/dot.html'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/*.lua',
    'src/inventories/*.lua',
    'src/resource/shared/*.lua'
}

client_scripts {
    'integrations/*.lua',
    'src/resource/client/**/*.lua',
    'src/interactions/*.lua',
    'frameworks/qbox/client.lua',
    'frameworks/esx/client.lua',
    'frameworks/qbcore/client.lua'
}

server_scripts {
    "webhooks.lua",
    'src/resource/server/**/*.lua',
    'frameworks/qbox/server.lua',
    'frameworks/esx/server.lua',
    'frameworks/qbcore/server.lua'
}

escrow_ignore {
    'frameworks/**/*.lua',
    'integrations/*.lua',
    'locales/*.lua',
    'src/inventories/*.lua',
    'src/interactions/*.lua',
    'config.lua',
    'webhooks.lua',
    'src/resource/shared/*.lua'
}

dependency '/assetpacks'

