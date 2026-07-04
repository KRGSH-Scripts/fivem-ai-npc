OpenRouterAI = {}

-- OpenRouter.ai API Integration
OpenRouterAI.Enabled = false
OpenRouterAI.ApiKey = "" -- In settings.lua eintragen
OpenRouterAI.Model = "openai/gpt-3.5-turbo" -- Free model
OpenRouterAI.RequestQueue = {}
OpenRouterAI.LastRequestTime = 0

-- KI-Nachricht vom Ped-Chat abrufen
function OpenRouterAI.GetChatResponse(pedNetId, prompt, context, callback)
    if not OpenRouterAI.Enabled or not OpenRouterAI.ApiKey or OpenRouterAI.ApiKey == "" then
        callback(nil) -- Fallback
        return
    end
    
    -- Rate-Limiting prüfen (100 requests/minute)
    local now = os.time()
    if now - OpenRouterAI.LastRequestTime < 0.6 then
        Wait(600)
    end
    
    local fullPrompt = string.format([[
Du bist ein NPC in einem GTA5-Rollenspiel. Du bist ein freundlicher Ped mit der Rolle eines %s.
Aktuell ist es %d Uhr und du bist %s.
Du hast gerade folgende Nachricht gehört: "%s"

Antworte kurz (max 30 Wörter) als würdest du mit einem Spieler sprechen. Sei kreativ und bleibe in der Rolle!
]], 
        context.role or "Bürgers",
        GetClockHours(),
        context.state or "idle",
        prompt
    )
    
    -- HTTP-Anfrung via PerformHttpRequest
    Citizen.CreateThread(function()
        local requestData = {
            model = OpenRouterAI.Model,
            messages = {
                {role = "user", content = fullPrompt}
            },
            max_tokens = 50
        }
        
        -- Da FiveM serverseitig HTTP-Aufrufe ermöglichen
        -- Dies ist eine Basisimplementierung
        -- Eine komplette Implementierung bräuchte eine externe API
        callback(nil)
    end)
end

-- KI-Entscheidung für Ped-Status
function OpenRouterAI.GetDecision(pedNetId, pedData, callback)
    if not OpenRouterAI.Enabled or not OpenRouterAI.ApiKey or OpenRouterAI.ApiKey == "" then
        callback({wanderTime = PedBehavior.GetRandomWaitTime()}) -- Fallback
        return
    end
    
    local hour = GetClockHours()
    
    local decisionPrompt = string.format([[
Du bist ein AI-NPC in GTA5. Es ist %d Uhr.
Dein aktueller Status: %s
Dein sozialer Score: %d

Sollst du: wandern, arbeiten, reden oder idle bleiben?
Antworte nur mit einem Wort: wander, work, social, idle
]],
        hour,
        pedData.state or 'idle',
        pedData.socialLevel or 50
    )
    
    -- Placeholder für echte KI-Entscheidung
    callback({wanderTime = PedBehavior.GetRandomWaitTime()})
end

-- OpenRouter für Peds aktivieren
function OpenRouterAI.Initialize(settings)
    if settings and settings.OpenRouterApiKey then
        OpenRouterAI.ApiKey = settings.OpenRouterApiKey
        OpenRouterAI.Enabled = settings.OpenRouterEnabled or false
        OpenRouterAI.Model = settings.OpenRouterModel or "openai/gpt-3.5-turbo"
    end
end

return OpenRouterAI