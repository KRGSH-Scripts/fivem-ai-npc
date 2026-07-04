--- 
--- State Tool - NPC-Zustand verwalten
---

ToolState = {}

function ToolState.Execute(netId, state)
    local validStates = {'idle', 'wandering', 'working', 'social', 'following', 'sleeping'}
    local isValid = false
    
    for _, s in ipairs(validStates) do
        if s == state then
            isValid = true
            break
        end
    end
    
    if not isValid then
        return {success = false, error = "Ungültiger Zustand"}
    end
    
    PedManager.SetPedState(netId, state)
    TriggerClientEvent('ai-peds:client:setState', -1, netId, state)
    return {success = true, state = state}
end

-- Zustand abrufen
function ToolState.Get(netId)
    return PedManager.Peds[netId] and PedManager.Peds[netId].state or 'idle'
end

return ToolState