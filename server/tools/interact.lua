--- 
--- Interact Tool - NPC interagiert mit anderen NPCs
---

ToolInteract = {}

function ToolInteract.Execute(netId, targetNetId, action)
    if action == 'chat' then
        PedInteractions.HandlePedToPed(netId, targetNetId, 'chat')
        return {success = true, action = "chat"}
    elseif action == 'follow' then
        TriggerClientEvent('ai-peds:client:followPed', -1, netId, targetNetId)
        return {success = true, action = "follow"}
    elseif action == 'greet' then
        TriggerClientEvent('ai-peds:client:showChat', -1, netId, "Hallo!", 3000, "happy")
        return {success = true, action = "greet"}
    end
    return {success = false, error = "Unbekannte Aktion"}
end

return ToolInteract