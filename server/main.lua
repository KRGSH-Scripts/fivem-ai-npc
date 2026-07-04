local QBCore = nil
local ESX = nil
local OpenRouter = nil

-- Framework init
Citizen.CreateThread(function()
    if Config.UseQbCore then
        QBCore = exports['qb-core']:GetCoreObject()
    else
        ESX = exports['esx:getSharedObject']
    end
    
    -- OpenRouter AI initialisieren
    OpenRouter = exports.ox_lib:getResource('openrouter') or require 'server.openrouter'
    OpenRouter.Initialize(Settings)
end)

-- Ressource Start
print("^2[AI-Peds] Server gestartet")

-- Alle Peds spawnen
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    PedManager.SpawnAllPeds()
end)

-- Client ready
RegisterNetEvent('ai-peds:client:ready', function()
    local src = source
    PedManager.SyncPedsToPlayer(src)
end)

-- KI-generierte Chat-Nachricht vom Client anfordern
RegisterNetEvent('ai-peds:server:requestAiChat', function(netId, prompt, context)
    if OpenRouter and OpenRouter.Enabled then
        OpenRouter.GetChatResponse(netId, prompt, context, function(response)
            if response then
                TriggerClientEvent('ai-peds:client:showChat', -1, netId, response, 4000)
            end
        end)
    end
end)

-- Chat-Nachricht vom Server
RegisterNetEvent('ai-peds:server:sendChatMessage', function(netId, message)
    -- An alle Clients senden
    TriggerClientEvent('ai-peds:client:showChat', -1, netId, message, 4000)
end)

-- Spezielle Ped-Befehle
RegisterNetEvent('ai-peds:server:followPlayer', function(netId)
    local src = source
    local ped = PedManager.GetPedFromNetId(netId)
    
    if ped then
        PedManager.SetPedState(netId, 'following')
        TriggerClientEvent('ai-peds:client:followPlayer', -1, netId, src)
    end
end)

-- Admin Ped spawnen
RegisterNetEvent('ai-peds:server:adminSpawnPed', function(coords, pedType, gender)
    local src = source
    
    -- Ped-Typ bestimmen und workType setzen
    local workType = nil
    if pedType and pedType ~= "random" then
        if pedType == "business" or pedType == "construction" or pedType == "farmer" then
            workType = pedType
        end
    end
    
    PedManager.SpawnPed(coords, nil, workType)
    
    -- Bestätigung
    SendChatMessage(src, {0, 255, 0}, "Ped wurde gespawnt!")
end)

-- Beziehungswerte abrufen (für KI-Entscheidungen)
RegisterNetEvent('ai-peds:server:getRelationship', function(pedNetId1, pedNetId2)
    local src = source
    local rel = PedManager.GetRelationship(pedNetId1, pedNetId2)
    TriggerClientEvent('ai-peds:client:relationshipUpdate', src, pedNetId1, pedNetId2, rel)
end)

-- Beziehung nach Interaktion aktualisieren
RegisterNetEvent('ai-peds:server:updateRelationship', function(netId1, netId2, interactionType)
    PedInteractions.HandlePedToPed(netId1, netId2, interactionType)
end)

-- Umgebungs-Scan-Ergebnis von Client
RegisterNetEvent('ai-peds:server:environmentScanResult', function(scannerNetId, results)
    -- Könnte für KI-Entscheidungen genutzt werden
    PedManager.Peds[scannerNetId].lastScan = results
end)

-- Ped-Perspektive für KI bereitstellen
RegisterNetEvent('ai-peds:server:getPedPerspective', function(netId)
    local pedData = PedManager.GetPedFromNetId(netId)
    if pedData then
        TriggerClientEvent('ai-peds:client:pedPerspectiveResult', source, netId, {
            persona = pedData.persona,
            relationships = pedData.relationships,
            state = pedData.state,
            memories = pedData.memories
        })
    end
end)

-- Tool-Ausführung via Server
RegisterNetEvent('ai-peds:server:executeTool', function(toolName, ...)
    local src = source
    local result = exports['ai-peds']:ExecuteTool(toolName, ...)
    TriggerClientEvent('ai-peds:client:toolResult', src, toolName, result)
end)

-- Peds alle 30 Sekunden neu evaluieren
SetInterval(function()
    PedManager.EvaluateAllPeds()
end, 30000)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    PedManager.CleanupAllPeds()
end)

-- Export für andere Ressourcen
exports('SpawnPedAtLocation', function(coords, model, workType)
    return PedManager.SpawnPed(coords, model, workType)
end)

exports('DeletePed', function(netId)
    return PedManager.DeletePed(netId)
end)

exports('GetPedCount', function()
    return PedManager.GetPedCount()
end)

exports('GetOpenRouterChatResponse', function(netId, prompt, context)
    if OpenRouter and OpenRouter.Enabled then
        OpenRouter.GetChatResponse(netId, prompt, context, function(response)
            return response
        end)
    end
    return nil
end)

exports('SetOpenRouterEnabled', function(enabled, apiKey, model)
    Settings.OpenRouterEnabled = enabled
    Settings.OpenRouterApiKey = apiKey or Settings.OpenRouterApiKey
    Settings.OpenRouterModel = model or Settings.OpenRouterModel
    
    if OpenRouter then
        OpenRouter.Initialize(Settings)
    end
end)

---
-- Admin Commands
---

-- Admin-Gruppen prüfen (QB- oder ESX)
local function IsPlayerAdmin(src)
    if QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        -- QB-Core permissions check
        local permission = QBCore.Functions.GetPermission(src)
        return permission == 'admin' or permission == 'god' or permission == 'mod'
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin'
    end
    return true -- Für Testzwecke, wenn kein Framework
end

-- Chat-Nachricht Hilfsfunktion
local function SendChatMessage(src, color, message)
    if QBCore then
        TriggerClientEvent('QBCore:Notify', src, message, 'success')
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = color,
            args = {"AI-Peds", message}
        })
    end
end

-- /ai-peds-spawn - Ped an aktueller Position spawnen
RegisterCommand('ai-peds-spawn', function(source, args, raw)
    if not source or source == 0 then return end -- Nur In-Game
    
    if not IsPlayerAdmin(source) then
        SendChatMessage(source, {255, 0, 0}, "Du hast keine Berechtigung!")
        return
    end
    
    -- Ped-Typ bestimmen
    local pedType = args[1] or "random"
    local gender = args[2] or (math.random(1, 2) == 1 and "male" or "female")
    
    TriggerClientEvent('ai-peds:client:spawnAtCoords', source, pedType, gender)
end, false)

-- /ai-peds-delete - Ped in der Nähe löschen
RegisterCommand('ai-peds-delete', function(source, args, raw)
    if not source or source == 0 then return end
    
    if not IsPlayerAdmin(source) then
        SendChatMessage(source, {255, 0, 0}, "Du hast keine Berechtigung!")
        return
    end
    
    TriggerClientEvent('ai-peds:client:findAndDeletePed', source)
end, false)

-- /ai-peds-cleanup - Alle Peds entfernen
RegisterCommand('ai-peds-cleanup', function(source, args, raw)
    if not source or source == 0 then return end
    
    if not IsPlayerAdmin(source) then
        SendChatMessage(source, {255, 0, 0}, "Du hast keine Berechtigung!")
        return
    end
    
    PedManager.CleanupAllPeds()
    SendChatMessage(source, {0, 255, 0}, "Alle Peds wurden entfernt!")
end, false)

-- /ai-peds-count - Anzahl der Peds anzeigen
RegisterCommand('ai-peds-count', function(source, args, raw)
    if not source or source == 0 then return end
    
    if not IsPlayerAdmin(source) then
        SendChatMessage(source, {255, 0, 0}, "Du hast keine Berechtigung!")
        return
    end
    
    local count = PedManager.GetPedCount()
    SendChatMessage(source, {0, 255, 255}, "Aktive Peds: "..count)
end, false)

-- /ai-peds-ki - OpenRouter KI aktivieren/deaktivieren
RegisterCommand('ai-peds-ki', function(source, args, raw)
    if not source or source == 0 then return end
    
    if not IsPlayerAdmin(source) then
        SendChatMessage(source, {255, 0, 0}, "Du hast keine Berechtigung!")
        return
    end
    
    local action = args[1]
    if action == "enable" then
        -- API-Key wird vom Server-Start gelesen
        Settings.OpenRouterEnabled = true
        if OpenRouter then OpenRouter.Initialize(Settings) end
        SendChatMessage(source, {0, 255, 0}, "KI-Chat wurde aktiviert!")
    elseif action == "disable" then
        Settings.OpenRouterEnabled = false
        SendChatMessage(source, {255, 255, 0}, "KI-Chat wurde deaktiviert!")
    else
        SendChatMessage(source, {255, 255, 0}, "Nutzung: /ai-peds-ki [enable/disable]")
    end
end, false)