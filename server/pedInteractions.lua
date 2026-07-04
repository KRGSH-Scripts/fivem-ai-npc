PedInteractions = {}

-- Ped-Reaktion auf Spieler-Interaktion
function PedInteractions.HandlePlayerInteraction(pedNetId, playerId, interactionType)
    local pedData = PedManager.GetPedFromNetId(pedNetId)
    if not pedData then return end
    
    -- Interaktion speichern
    Database.SavePedInteraction(pedNetId, playerId, interactionType)
    
    -- Ped-Stats laden
    local stats = Database.LoadPedStats(pedNetId)
    
    -- Reaktion basierend auf Interaktion und Beziehung zum Spieler
    local sympathyChange = 0
    local trustChange = 0
    
    if interactionType == 'greet' then
        stats.socialLevel = math.min(100, stats.socialLevel + 10)
        PedManager.SetPedState(netId, 'social')
        
        -- Positive Reaktion wenn hohe Sympathie
        local rel = PedManager.GetRelationship(pedNetId, playerId)
        if rel.sympathy and rel.sympathy > 50 then
            sympathyChange = 10
            trustChange = 5
        else
            sympathyChange = 5
        end
        
        TriggerClientEvent('ai-peds:client:showChat', -1, pedNetId, "Hallo! Schön dich zu sehen!", 3000)
        
    elseif interactionType == 'follow' then
        PedManager.SetPedState(netId, 'following')
        trustChange = -5 -- Folgen kostet Vertrauen
        TriggerClientEvent('ai-peds:client:showChat', -1, pedNetId, "Folge dir!", 3000)
        
    elseif interactionType == 'ignore' then
        stats.socialLevel = math.max(0, stats.socialLevel - 5)
        sympathyChange = -10
        
    elseif interactionType == 'help' then
        stats.socialLevel = math.min(100, stats.socialLevel + 15)
        stats.happiness = math.min(100, stats.happiness + 10)
        sympathyChange = 15
        trustChange = 10
        TriggerClientEvent('ai-peds:client:showChat', -1, pedNetId, "Danke für die Hilfe!", 4000)
    end
    
    -- Stats speichern
    Database.SavePedStats(pId, stats)
    
    -- Beziehung zum Spieler aktualisieren
    PedManager.AdjustRelationshipValues(pedNetId, playerId, sympathyChange, trustChange, 0)
end

-- Ped-zu-Ped Interaktionen
function PedInteractions.HandlePedToPed(pedNetId1, pedNetId2, interactionType)
    if not PedManager.Peds[pedNetId1] or not PedManager.Peds[pedNetId2] then return end
    
    -- Prüfe Kommunikationsreichweite
    local ped1 = NetToPed(pedNetId1)
    local ped2 = NetToPed(pedNetId2)
    
    if not DoesEntityExist(ped1) or not DoesEntityExist(ped2) then return end
    
    if not ChatSystem.IsInChatRange(ped1, ped2) then
        -- Zu weit entfernt - keine Kommunikation
        return
    end
    
    local stats1 = Database.LoadPedStats(pedNetId1)
    local stats2 = Database.LoadPedStats(pedNetId2)
    
    -- Aktuelle Beziehung abrufen
    local rel = PedManager.GetRelationship(pedNetId1, pedNetId2)
    
    -- Reaktion basierend auf Beziehung
    local sympathyChange1, trustChange1, respectChange1 = 0, 0, 0
    local sympathyChange2, trustChange2, respectChange2 = 0, 0, 0
    
    if interactionType == 'chat' then
        -- Freundliche Unterhaltung
        if rel.relation == 'friend' then
            sympathyChange1 = 5
            sympathyChange2 = 5
            respectChange1 = 3
            respectChange2 = 3
        elseif rel.relation == 'enemy' then
            sympathyChange1 = -5
            sympathyChange2 = -5
        else
            sympathyChange1 = 3
            sympathyChange2 = 3
        end
        
        stats1.socialLevel = math.min(100, stats1.socialLevel + 5)
        stats2.socialLevel = math.min(100, stats2.socialLevel + 5)
    end
    
    Database.SavePedStats(pedNetId1, stats1)
    Database.SavePedStats(pedNetId2, stats2)
    
    PedManager.AdjustRelationshipValues(pedNetId1, pedNetId2, sympathyChange1, trustChange1, respectChange1)
    PedManager.AdjustRelationshipValues(pedNetId2, pedNetId1, sympathyChange2, trustChange2, respectChange2)
end

-- Ped-Gruppenbildung basierend auf Beziehungen
function PedInteractions.FormSocialGroups()
    local groups = {}
    
    for netId, pedData in pairs(PedManager.Peds) do
        if not pedData.groupId then
            -- Suche nach passenden Gruppenmitgliedern
            local potentialMembers = {netId}
            
            for otherNetId, otherPedData in pairs(PedManager.Peds) do
                if otherNetId ~= netId and not otherPedData.groupId then
                    local rel = PedManager.GetRelationship(netId, otherNetId)
                    
                    -- Hohe Sympathie und Vertrautheit für Gruppenbildung
                    if rel.sympathy > 60 and rel.trust > 50 then
                        table.insert(potentialMembers, otherNetId)
                    end
                end
            end
            
            if #potentialMembers > 2 then
                local groupId = math.random(10000, 99999)
                for _, memberNetId in ipairs(potentialMembers) do
                    if PedManager.Peds[memberNetId] then
                        PedManager.Peds[memberNetId].groupId = groupId
                        PedManager.Peds[memberNetId].groupTopic = PedInteractions.GetGroupTopic()
                    end
                end
                table.insert(groups, {id = groupId, members = potentialMembers})
            end
        end
    end
    
    return groups
end

-- Zufälliges Gruppenthema
function PedInteractions.GetGroupTopic()
    local topics = {
        "Wetter",
        "Arbeit",
        "Familie",
        "Politik",
        "Sport",
        "Technologie",
        "Urlaub",
        "Essen"
    }
    return topics[math.random(1, #topics)]
end

return PedInteractions