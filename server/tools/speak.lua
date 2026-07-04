--- 
--- Speak Tool - NPC spricht etwas
---

ToolSpeak = {}

function ToolSpeak.Execute(netId, message, emotion, duration)
    TriggerClientEvent('ai-peds:client:showChat', -1, netId, message, duration or 4000, emotion)
    return true
end

return ToolSpeak