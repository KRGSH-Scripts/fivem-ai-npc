--- 
--- Remember Tool - NPC-Erinnerungen speichern
---

ToolRemember = {}

function ToolRemember.Execute(netId, key, value)
    if PedManager.Peds[netId] then
        PedManager.Peds[netId].memories = PedManager.Peds[netId].memories or {}
        PedManager.Peds[netId].memories[key] = {
            value = value,
            timestamp = os.time()
        }
        return {success = true, key = key}
    end
    return {success = false, error = "Ped nicht gefunden"}
end

-- Erinnerung abrufen
function ToolRemember.Get(netId, key)
    if PedManager.Peds[netId] and PedManager.Peds[netId].memories then
        return PedManager.Peds[netId].memories[key]
    end
    return nil
end

return ToolRemember