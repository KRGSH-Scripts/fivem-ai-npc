Target = {}

-- Target für Peds erstellen
function Target.AddPedTargets()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2000)
            
            for netId, pedData in pairs(AIController.RegisteredPeds) do
                local ped = NetToPed(netId)
                if DoesEntityExist(ped) then
                    -- QB-Target Integration
                    if Config.UseQbCore and exports['qb-target'] then
                        exports['qb-target']:AddEntity(ped, {
                            options = {
                                {
                                    type = "client",
                                    event = "ai-peds:client:interactPed",
                                    icon = "fas fa-comments",
                                    label = "Mit NPC sprechen",
                                    netId = netId
                                },
                                {
                                    type = "server",
                                    event = "ai-peds:server:followPlayer",
                                    icon = "fas fa-walking",
                                    label = "Follow me",
                                    netId = netId
                                }
                            },
                            distance = 2.5
                        })
                    end
                end
            end
        end
    end)
end

-- Ped-Interaktion
RegisterNetEvent('ai-peds:client:interactPed', function(data)
    local netId = data.netId
    local ped = NetToPed(netId)
    
    if DoesEntityExist(ped) then
        -- Gesprächs-Animation
        Animations.PlaySocialAnim(ped, true)
        
        -- Zufällige Antwort
        local greetings = Config.ChatMessages.greetings
        local greeting = greetings[math.random(1, #greetings)]
        ChatSystem.ShowChatMessage(ped, greeting, 4000)
        
        -- Ped folgen lassen
        local playerPed = PlayerPedId()
        TaskFollowToOffsetOfEntity(ped, playerPed, 0.0, 1.0, 0.0, 1.0, 10000, 1.0, true)
        
        SetTimeout(15000, function()
            if DoesEntityExist(ped) then
                ClearPedTasksImmediately(ped)
            end
        end)
    end
end)

-- Target-Labels aktualisieren basierend auf Ped-Status
function Target.UpdatePedLabels(netId, state)
    -- Wird von AIController aufgerufen
end

return Target