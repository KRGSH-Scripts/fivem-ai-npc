resource_manifest_version '75475'

name 'ai-peds'
version '1.0.0'
description 'KI-gesteuerte Peds die kommunizieren, arbeiten und leben'
author 'AI Assistant'

shared_script 'shared/config.lua'

server_scripts {
    '@oxmysql/lib/mysql.lua',
    'server/main.lua',
    'server/pedManager.lua',
    'server/pedInteractions.lua',
    'server/database.lua'
}

client_scripts {
    'client/main.lua',
    'client/aiController.lua',
    'client/pedBehavior.lua',
    'client/pedSpawner.lua',
    'client/chatSystem.lua',
    'client/animations.lua',
    'client/target.lua'
}

dependencies {
    'oxmysql'
}