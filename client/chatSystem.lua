ChatSystem = {}
ChatSystem.Messages = {}
ChatSystem.ActiveChats = {}

-- Beziehungswerte (0-100)
ChatSystem.RelationshipValues = {
    sympathy = 50,    -- Sympathie (0-100)
    trust = 50,       -- Vertrauen (0-100)
    respect = 50,     -- Respekt (0-100)
    familiarity = 0   -- Bekanntschaft (0-100)
}

-- Chat-Nachricht anzeigen (3D Text über Ped)
function ChatSystem.ShowChatMessage(ped, message, duration, emotion)
    if not DoesEntityExist(ped) then return end
    
    -- Emotionale Farbe basierend auf Stimmung
    local color = {255, 255, 255} -- Standard Weiß
    if emotion == "happy" then
        color = {100, 255, 100} -- Hellgrün
    elseif emotion == "angry" then
        color = {255, 100, 100} -- Hellrot
    elseif emotion == "sad" then
        color = {100, 100, 255} -- Hellblau
    elseif emotion == "surprised" then
        color = {255, 255, 100} -- Gelb
    end
    
    table.insert(ChatSystem.Messages, {
        ped = ped,
        message = message,
        startTime = GetGameTimer(),
        endTime = GetGameTimer() + (duration or 5000),
        offset = 0.0,
        color = color
    })
    
    -- Ped animieren während des Sprechens
    Animations.PlaySocialAnim(ped, true)
end

-- Chat-Nachricht entfernen
function ChatSystem.RemoveMessage(index)
    local msg = ChatSystem.Messages[index]
    if msg then
        Animations.StopAnim(NetToPed(msg.ped), 'amb@world_human_talking@male_a@idle_a', 'idle_a')
    end
    table.remove(ChatSystem.Messages, index)
end

-- 3D Text Rendering mit Farbe
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        for i = #ChatSystem.Messages, 1, -1 do
            local msg = ChatSystem.Messages[i]
            if msg and DoesEntityExist(msg.ped) then
                local coords = GetEntityCoords(msg.ped)
                coords.z = coords.z + 1.2 + msg.offset
                msg.offset = math.sin(GetGameTimer() / 500) * 0.1
                
                DrawText3DWithColor(coords.x, coords.y, coords.z, msg.message, msg.color)
                
                if GetGameTimer() > msg.endTime then
                    ChatSystem.RemoveMessage(i)
                end
            else
                table.remove(ChatSystem.Messages, i)
            end
        end
    end
end)

function DrawText3DWithColor(x, y, z, text, color)
    SetDrawOrigin(x, y, z, 0)
    SetTextFont(4)
    SetTextProportion(1)
    SetTextScale(0.35, 0.35)
    SetTextColour(color[1], color[2], color[3], 215)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Prüft ob Ped in Kommunikationsreichweite ist (10 Meter)
function ChatSystem.IsInChatRange(ped1, ped2)
    if not DoesEntityExist(ped1) or not DoesEntityExist(ped2) then return false end
    return #(GetEntityCoords(ped1) - GetEntityCoords(ped2)) <= 10.0
end

-- Ped-Nachricht senden
function ChatSystem.SendPedMessage(netId, message)
    TriggerServerEvent('ai-peds:server:sendChatMessage', netId, message)
end

-- Peds zum Chat hinzufügen (innerhalb 10m)
function ChatSystem.GetNearbyPeds(excludeNetId)
    local nearbyPeds = {}
    local excludePed = NetToPed(excludeNetId)
    if not DoesEntityExist(excludePed) then return nearbyPeds end
    
    for netId, pedData in pairs(AIController.RegisteredPeds) do
        if netId ~= excludeNetId then
            local ped = NetToPed(netId)
            if DoesEntityExist(ped) and ChatSystem.IsInChatRange(excludePed, ped) then
                table.insert(nearbyPeds, netId)
            end
        end
    end
    
    return nearbyPeds
end

return ChatSystem