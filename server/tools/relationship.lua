--- 
--- Relationship Tool - Beziehungswerte abrufen/setzen
---

ToolRelationship = {}

-- Beziehung abrufen
function ToolRelationship.Get(netId1, netId2)
    return PedManager.GetRelationship(netId1, netId2)
end

-- Beziehung aktualisieren
function ToolRelationship.Update(netId1, netId2, relation, values)
    PedManager.UpdateRelationships(netId1, netId2, relation, values)
    return {success = true}
end

-- Beziehung anpassen
function ToolRelationship.Adjust(netId1, netId2, sympathyChange, trustChange, respectChange)
    PedManager.AdjustRelationshipValues(netId1, netId2, sympathyChange, trustChange, respectChange)
    return {success = true}
end

return ToolRelationship