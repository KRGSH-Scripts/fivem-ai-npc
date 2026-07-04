Settings = {}

-- OpenRouter API Einstellungen (Optional)
Settings.OpenRouterApiKey = "" -- Deinen API-Key hier eintragen
Settings.OpenRouterEnabled = false

-- FiveM HTTP Einstellungen
Settings.UseHTTP = false -- Aktiviert echte KI-Anfragen (benötigt HTTPS-Resource)

-- KI-Token-Überschreitungs-Schutz
Settings.MaxTokensPerMinute = 100
Settings.CurrentTokens = 0

-- Scheduler-Einstellungen
Settings.Scheduler = {
    enabled = true,
    interval = 120000, -- 2 Minuten
    workTimeCheck = true
}

-- KI-Prompt-Vorlagen
Settings.KiPormpts = {
    chat = [[
Du bist ein NPC in einem GTA5-Rollenspiel. 
Du bist ein {{personality}} mit folgenden Eigenschaften:
- Aktuelle Tätigkeit: {{activity}}
- Stimmung (0-100): {{mood}}
- Sozialer Score (0-100): {{social}}

Antworte kurz (max 50 Wörter) auf: "{{message}}"
Sei kreativ und bleibe in der Rolle!
]],
    
    decision = [[
Du bist ein NPC in GTA5. Entscheide basierend auf:
- Tageszeit: {{hour}}:00 Uhr
- Aktueller Zustand: {{state}}
- Soziale Verbindungen: {{relationships}}

Was solltest du als nächstes tun? Antworte mit einem der folgenden Begriffe:
idle, wandering, working, social, sleep
]]
}

return Settings