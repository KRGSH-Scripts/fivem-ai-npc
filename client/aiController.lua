AIController = {}
AIController.RegisteredPeds = {}
AIController.PedStates = {}
AIController.PedTargets = {}

-- Ped registrieren
function AIController.RegisterPed(netId, pedData)
    AIController.RegisteredPeds[netId] = pedData
    AIController.PedStates[netId] = 'idle'
    AIController.PedTargets[netId] = nil
end

-- Ped deregistrieren
function AIController.UnregisterPed(netId)
    AIController.RegisteredPeds[netId] = nil
    AIController.PedStates[netId] = nil
    AIController.PedTargets[netId] = nil
end

-- Ped-Status setzen
function AIController.SetState(netId, state)
    AIController.PedStates[netId] = state
end

-- Ped-Status abfragen
function AIController.GetState(netId)
    return AIController.PedStates[netId] or 'idle'
end

-- Gedankengut-Status
AIController.Thoughts = {}

function AIController.SetThought(netId, thought)
    AIController.Thoughts[netId] = {
        text = thought,
        time = GetGameTimer()
    }
end

function AIController.GetThought(netId)
    return AIController.Thoughts[netId]
end

-- Haupt-Think-Thread für jeden Ped
function AIController.Think(netId)
    local ped = NetToPed(netId)
    if not DoesEntityExist(ped) then return end
    
    CreateThread(function()
        while DoesEntityExist(ped) and AIController.RegisteredPeds[netId] do
            local state = AIController.GetState(netId)
            
            if state == 'idle' then
                AIController.ProcessIdle(netId, ped)
            elseif state == 'wandering' then
                AIController.ProcessWandering(netId, ped)
            elseif state == 'working' then
                AIController.ProcessWorking(netId, ped)
            elseif state == 'social' then
                AIController.ProcessSocial(netId, ped)
            end
            
            Wait(1000)
        end
    end)
end

-- Idle-Verhalten
function AIController.ProcessIdle(netId, ped)
    local pedData = AIController.RegisteredPeds[netId]
    local decision = math.random(1, 100)
    
    -- Beziehungsperspektive berücksichtigen
    local relationshipInfluence = AIController.GetRelationshipInfluence(netId)
    
    if PedBehavior.IsWorkHour() then
        if decision < (60 + relationshipInfluence) then
            AIController.SetThought(netId, "Zeit zur Arbeit!")
            AIController.SetState(netId, 'working')
        elseif decision < (85 + relationshipInfluence) then
            AIController.SetState(netId, 'social')
        else
            AIController.SetState(netId, 'wandering')
        end
    else
        if decision < 40 then
            AIController.SetState(netId, 'social')
        elseif decision < 80 then
            AIController.SetState(netId, 'wandering')
        else
            PedBehavior.CreateRandomScene(ped, 'idle')
        end
    end
end

-- Beziehungsinfluss für Entscheidungen
function AIController.GetRelationshipInfluence(netId)
    local influence = 0
    local ped = NetToPed(netId)
    
    for otherNetId, otherData in pairs(AIController.RegisteredPeds) do
        local otherPed = NetToPed(otherNetId)
        if DoesEntityExist(otherPed) and ChatSystem.IsInChatRange(ped, otherPed) then
            -- Server fragt Beziehung ab
            TriggerServerEvent('ai-peds:server:getRelationship', netId, otherNetId)
        end
    end
    
    return influence
end

-- Soziales Verhalten (mit Beziehungsperspektive)
function AIController.ProcessSocial(netId, ped)
    local pedData = AIController.RegisteredPeds[netId]
    local nearbyPeds = AIController.GetNearbyPedsForSocial(netId, ped)
    
    if #nearbyPeds > 0 then
        -- Ped mit bester Beziehung wählen
        local partnerNetId = AIController.SelectBestConversationPartner(netId, nearbyPeds)
        
        if partnerNetId then
            local partnerPed = NetToPed(partnerNetId)
            
            -- Beide Peds zum Gespräch bringen
            PedBehavior.CreateConversationGroup({ped, partnerPed})
            
            -- Emotion basierend auf Beziehung
            local rel = PedManager.GetRelationship(netId, partnerNetId)
            local emotion = AIController.DetermineEmotionFromRelationship(rel)
            
            -- Gesprächs-Animationen
            Animations.PlaySocialAnim(ped, true)
            Animations.PlaySocialAnim(partnerPed, true)
            
            -- KI-generierte oder Fallback-Nachricht
            local persona = pedData.persona or "ein freundlicher Ped"
            local topic = pedData.groupTopic or "Alltägliches"
            
            -- Nachricht basierend auf Persönlichkeit
            local msg1 = AIController.GenerateContextMessage(pedData, topic, rel)
            local msg2 = AIController.GenerateContextMessage(AIController.RegisteredPeds[partnerNetId], topic, rel)
            
            ChatSystem.ShowChatMessage(ped, msg1, 3000, emotion)
            Wait(2000)
            ChatSystem.ShowChatMessage(partnerPed, msg2, 3000, emotion)
            
            -- Beziehung nach Kommunikation anpassen
            TriggerServerEvent('ai-peds:server:updateRelationship', netId, partnerNetId, 'chat')
            
            Wait(8000)
            
            -- Gespräch beenden
            Animations.StopAnim(ped, 'amb@world_human_talking@male_a@idle_a', 'idle_a')
            Animations.StopAnim(partnerPed, 'amb@world_human_talking@male_a@idle_a', 'idle_a')
        end
    end
    
    AIController.SetState(netId, 'idle')
end

-- Emotion basierend auf Beziehung bestimmen
function AIController.DetermineEmotionFromRelationship(rel)
    if not rel then return "neutral" end
    if rel.sympathy > 70 then return "happy" end
    if rel.sympathy < 30 then return "sad" end
    if rel.trust < 30 then return "angry" end
    return "neutral"
end

-- Kontext-Nachricht generieren
function AIController.GenerateContextMessage(pedData, topic, relationship)
    local baseMessages = Config.ChatMessages.casualChatter
    
    -- Persönlichkeit beeinflussen
    if pedData.persona and string.find(pedData.persona, "fröhlich") then
        return baseMessages[math.random(1, #baseMessages)] .. " 😊"
    elseif pedData.persona and string.find(pedData.persona, "rauher") then
        return baseMessages[math.random(1, #baseMessages)] .. " ...naja"
    end
    
    -- Beziehung beeinflussen
    if relationship and relationship.sympathy > 70 then
        return baseMessages[math.random(1, #baseMessages)] .. " Freut mich!"
    end
    
    return baseMessages[math.random(1, #baseMessages)]
end

-- Besten Gesprächspartner wählen basierend auf Beziehung
function AIController.SelectBestConversationPartner(netId, nearbyPeds)
    local bestNetId = nil
    local bestScore = -1
    
    for _, otherNetId in ipairs(nearbyPeds) do
        -- Server fragt Beziehung ab
        local score = math.random(1, 100) -- Placeholder
        -- Echte Logik: TriggerServerEvent für Beziehung prüfen
        
        if score > bestScore then
            bestScore = score
            bestNetId = otherNetId
        end
    end
    
    return bestNetId
end

-- Nahe Peds für Soziales Verhalten (10 Meter)
function AIController.GetNearbyPedsForSocial(netId, ped)
    local nearbyPeds = {}
    
    for otherNetId, otherData in pairs(AIController.RegisteredPeds) do
        if otherNetId ~= netId then
            local otherPed = NetToPed(otherNetId)
            if DoesEntityExist(otherPed) and ChatSystem.IsInChatRange(ped, otherPed) then
                table.insert(nearbyPeds, otherNetId)
            end
        end
    end
    
    return nearbyPeds
end

-- Ped-Steuerung von Server-Anweisungen
RegisterNetEvent('ai-peds:client:setState', function(netId, state)
    AIController.SetState(netId, state)
end)

RegisterNetEvent('ai-peds:client:setTarget', function(netId, targetCoords)
    AIController.PedTargets[netId] = targetCoords
end)

RegisterNetEvent('ai-peds:client:showChat', function(netId, message, duration, emotion)
    local ped = NetToPed(netId)
    if DoesEntityExist(ped) then
        ChatSystem.ShowChatMessage(ped, message, duration, emotion)
    end
end)

RegisterNetEvent('ai-peds:client:relationshipUpdate', function(netId1, netId2, values)
    -- Beziehungswerte für KI-Entscheidungen speichern
    if AIController.RegisteredPeds[netId1] then
        AIController.RegisteredPeds[netId1].relationshipCache = AIController.RegisteredPeds[netId1].relationshipCache or {}
        AIController.RegisteredPeds[netId1].relationshipCache[netId2] = values
    end
end)

return AIController