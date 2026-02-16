fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Fuse'
github 'https://github.com/fusefivem'
description 'FD Cocaine | Fuse Development'

dependency 'ox_lib'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

files {
    'locales/*.json'
}

client_scripts {
    'game/src/cl/*.lua'
}

server_scripts {
    'game/src/sv/*.lua'
}
