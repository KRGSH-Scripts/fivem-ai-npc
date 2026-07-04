--- 
--- Work Tool - NPC arbeitet an einem Ort
---

ToolWork = {}

function ToolWork.Execute(netId, location, duration)
    local workCoords = nil
    for _, workLoc in ipairs(Config.Behaviors.working.workLocations) do
        if workLoc.name == location then
            workCoords = workLoc.coords
            break
        end
    end
    
    if workCoords then
        PedManager.SetPedState(netId, 'working')
        TriggerClientEvent('ai-peds:client:navigateTo', -1, netId, workCoords, 1.5)
        return {success = true, location = location}
    end
    return {success = false, error = "Location nicht gefunden"}
end

return ToolWork