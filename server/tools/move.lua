--- 
--- Move Tool - NPC navigiert zu Koordinaten
---

ToolMove = {}

function ToolMove.Execute(netId, x, y, z, speed)
    TriggerClientEvent('ai-peds:client:setTarget', -1, netId, vector3(x, y, z))
    TriggerClientEvent('ai-peds:client:navigateTo', -1, netId, vector3(x, y, z), speed or 1.0)
    return true
end

return ToolMove