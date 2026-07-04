dependencies {
    'oxmysql',
    'qb-core',
    'qb-target'
}

server_scripts {
    'shared/config.lua',
    'shared/settings.lua',
    'server/scheduler.lua',
    'server/tools.lua',
    'server/tools/speak.lua',
    'server/tools/move.lua',
    'server/tools/work.lua',
    'server/tools/interact.lua',
    'server/tools/relationship.lua',
    'server/tools/state.lua',
    'server/tools/scan.lua',
    'server/tools/remember.lua',
    'server/main.lua',
    'server/pedManager.lua',
    'server/pedInteractions.lua',
    'server/database.lua',
    'server/openrouter.lua'
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

-- HTTP-Endpoints für KI-Anfragen (falls aktiviert)
server_export 'GetOpenRouterChatResponse'
server_export 'SetOpenRouterEnabled'