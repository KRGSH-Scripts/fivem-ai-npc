local QBCore = nil
local ESX = nil

-- Framework init
Citizen.CreateThread(function()
    if Config.UseQbCore then
        QBCore = exports['qb-core']:GetCoreObject()
    else
        ESX = exports['esx:getSharedObject']
    end
end)

-- Ressource Start
Citizen.CreateThread(function()
    print("^2[AI-Peds] Client gestartet")
    
    -- Models vorladen
    PedSpawner.PrepareModels()
    
    -- Server informieren, dass wir bereit sind
    TriggerServerEvent('ai-peds:client:ready')
    
    -- Target-System starten
    Target.AddPedTargets()
end)

-- Sync mit Server-Peds
RegisterNetEvent('ai-peds:client:spawnPed', function(netId, pedData)
    local ped = PedSpawner.SpawnPed(pedData.model, pedData.coords, pedData.options, pedData.outfit, pedData.persona)
    
    if ped then
        AIController.RegisterPed(netId, {
            model = pedData.model,
            spawnCoords = pedData.coords,
            workType = pedData.workType,
            workCoords = pedData.workCoords,
            persona = pedData.persona,
            outfit = pedData.outfit
        })
        
        -- AI-Think-Thread starten
        AIController.Think(netId)
        
        if Config.Debug then
            print("^3[AI-Peds] Ped gespawnt: "..netId.." ("..(pedData.persona and pedData.persona.name or "Unbenannt")..")")
        end
    end
end)

RegisterNetEvent('ai-peds:client:deletePed', function(netId)
    PedSpawner.DeletePed(netId)
end)

RegisterNetEvent('ai-peds:client:syncPeds', function(pedsTable)
    -- Bestehende Peds aufräumen
    PedSpawner.CleanupPeds()
    
    -- Neue Peds spawnen
    for netId, pedData in pairs(pedsTable) do
        local ped = PedSpawner.SpawnPed(pedData.model, pedData.coords, pedData.options, pedData.outfit, pedData.persona)
        
        if ped then
            AIController.RegisterPed(netId, {
                model = pedData.model,
                spawnCoords = pedData.coords,
                workType = pedData.workType,
                workCoords = pedData.workCoords,
                persona = pedData.persona,
                outfit = pedData.outfit
            })
            AIController.Think(netId)
        end
    end
end)

-- Emote basierend auf Stimmung abspielen
RegisterNetEvent('ai-peds:client:playEmote', function(netId, mood)
    local ped = NetToPed(netId)
    if DoesEntityExist(ped) then
        Animations.PlayEmote(ped, mood)
    end
end)

-- Ped folgen lassen
RegisterNetEvent('ai-peds:client:followPlayer', function(netId, playerId)
    local ped = NetToPed(netId)
    if DoesEntityExist(ped) then
        local playerPed = GetPlayerPed(GetPlayerFromServerId(playerId))
        if DoesEntityExist(playerPed) then
            TaskFollowToOffsetOfEntity(ped, playerPed, 0.0, 1.0, 0.0, 1.0, 10000, 1.0, true)
            ChatSystem.ShowChatMessage(ped, "Folge dir!", 3000)
        end
    end
end)

-- Navigieren zu Ziel
RegisterNetEvent('ai-peds:client:navigateTo', function(netId, targetCoords, speed)
    local ped = NetToPed(netId)
    if DoesEntityExist(ped) then
        PedBehavior.NavigateTo(ped, targetCoords, speed or 1.0)
    end
end)

-- Umgebung scannen (für Tools)
RegisterNetEvent('ai-peds:client:scanEnvironment', function(scannerNetId, radius)
    local scannerPed = NetToPed(scannerNetId)
    if not DoesEntityExist(scannerPed) then return end
    
    local results = {}
    for netId, pedData in pairs(AIController.RegisteredPeds) do
        if netId ~= scannerNetId then
            local ped = NetToPed(netId)
            if DoesEntityExist(ped) then
                local dist = #(GetEntityCoords(scannerPed) - GetEntityCoords(ped))
                if dist <= radius then
                    table.insert(results, {
                        netId = netId,
                        distance = dist,
                        persona = pedData.persona,
                        state = AIController.GetState(netId)
                    })
                end
            end
        end
    end
    
    TriggerServerEvent('ai-peds:server:environmentScanResult', scannerNetId, results)
end)

-- Ped-Perspektive für KI bereitstellen
RegisterNetEvent('ai-peds:client:pedPerspectiveResult', function(netId, perspective)
    -- Wird von KI-Modellen genutzt um Entscheidungen zu treffen
end)

-- Tool-Ergebnis vom Server
RegisterNetEvent('ai-peds:client:toolResult', function(toolName, result)
    -- Tool-Ausführung abgeschlossen
    if result.success then
        if Config.Debug then
            print("^2[AI-Peds] Tool '"..toolName.."' ausgeführt: "..tostring(result.result))
        end
    else
        print("^1[AI-Peds] Tool-Fehler '"..toolName.."': "..tostring(result.error))
    end
end)

-- Tool für KI aufrufen
function AIController.CallTool(toolName, ...)
    TriggerServerEvent('ai-peds:server:executeTool', toolName, ...)
end

---
-- Admin Spawn-Hilfen
---

-- Ped an aktuellen Koords spawnen
RegisterNetEvent('ai-peds:client:spawnAtCoords', function(pedType, gender)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- Server informieren
    TriggerServerEvent('ai-peds:server:adminSpawnPed', vector4(coords.x, coords.y, coords.z, heading), pedType, gender)
end)

-- Ped in der Nähe finden und löschen
RegisterNetEvent('ai-peds:client:findAndDeletePed', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPed = nil
    local closestDist = 5.0
    
    for netId, pedData in pairs(AIController.RegisteredPeds) do
        local ped = NetToPed(netId)
        if DoesEntityExist(ped) then
            local dist = #(GetEntityCoords(ped) - playerCoords)
            if dist < closestDist then
                closestDist = dist
                closestPed = netId
            end
        end
    end
    
    if closestPed then
        TriggerServerEvent('ai-peds:server:deletePed', closestPed)
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 0},
            args = {"AI-Peds", "Kein Ped in der Nähe gefunden!"}
        })
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    PedSpawner.CleanupPeds()
end)

-- Debug Befehle
if Config.Debug then
    RegisterCommand('ai-peds-list', function()
        print("^3[AI-Peds] Registrierte Peds:")
        for netId, pedData in pairs(AIController.RegisteredPeds) do
            print("  - "..netId..": "..pedData.model)
        end
    end, false)
    
    RegisterCommand('ai-peds-state', function(source, args)
        local netId = tonumber(args[1])
        if netId and AIController.RegisteredPeds[netId] then
            print("^3[AI-Peds] State: "..tostring(AIController.GetState(netId)))
        end
    end, false)
end