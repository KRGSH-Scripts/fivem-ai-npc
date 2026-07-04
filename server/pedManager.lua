PedManager = {}

PedManager.Peds = {}
PedManager.NetIdCounter = 1000

-- Ped erstellen
function PedManager.CreatePedData(model, coords, workType, workCoords)
    local netId = PedManager.NetIdCounter
    PedManager.NetIdCounter = PedManager.NetIdCounter + 1
    
    return {
        netId = netId,
        model = model,
        coords = coords,
        workType = workType or 'none',
        workCoords = workCoords,
        state = 'idle',
        lastInteraction = os.time(),
        relationships = {},
        persona = nil,
        outfit = nil
    }
end

-- KI-Persona generieren (mit Async-Callback)
function PedManager.GeneratePersona(pedNetId, gender, callback)
    gender = gender or (math.random(1, 2) == 1 and 'male' or 'female')
    
    -- Fallback-Persona
    local fallbackPersona = {
        name = PedManager.GenerateRandomName(gender),
        personality = PedManager.GenerateRandomPersonality(),
        model = Config.FreeRoamModels[gender]
    }
    
    -- Versuche KI-Persona zu generieren wenn OpenRouter aktiv
    if Settings.OpenRouterEnabled and Settings.OpenRouterApiKey ~= "" then
        PedManager.RequestKIPersonality(gender, function(kiPersonality)
            if kiPersonality then
                fallbackPersona.personality = kiPersonality
            end
            if callback then callback(fallbackPersona) end
        end)
    else
        if callback then
            callback(fallbackPersona)
        else
            return fallbackPersona
        end
    end
    
    return fallbackPersona
end

-- KI-Personality anfordern (Async mit Callback)
function PedManager.RequestKIPersonality(gender, callback)
    -- In FiveM kann man mit PerformHttpRequest eine HTTP-Anfrage stellen
    -- Für eine vollständige KI-Integration bräuchte man:
    -- 1. Eine HTTP-Proxy-Ressource der KI
    -- 2. Oder einen externen Dienst
    
    -- Placeholder für KI-Anfrage
    CreateThread(function()
        Wait(100)
        -- Standard-Fallback
        callback(PedManager.GenerateRandomPersonality())
    end)
end

-- KI-Prompt für Persönlichkeit
function PedManager.GenerateKPPrompt(gender)
    return string.format([[
Du bist ein NPC-Personality-Generator für GTA V Rollenspiel.
Generiere eine einprägsliche Persönlichkeit (max 20 Wörter) für einen %s Ped.

Antworte nur mit einem Wort oder kurzer Phrase:
]], gender == 'male' and 'männlichen' or 'weiblichen')
end

-- Zufälligen Namen generieren
function PedManager.GenerateRandomName(gender)
    gender = gender or (math.random(1, 2) == 1 and 'male' or 'female')
    
    local firstName = Config.KIPersona.firstNames[gender][math.random(1, #Config.KIPersona.firstNames[gender])]
    local lastName = Config.KIPersona.lastNames[math.random(1, #Config.KIPersona.lastNames)]
    
    return firstName .. " " .. lastName
end

-- Zufällige Persönlichkeit generieren
function PedManager.GenerateRandomPersonality()
    local personalities = {
        "ein fröhlicher und hilfsbereiter Einwohner",
        "ein rauer aber loyaler Arbeiter",
        "ein neugieriger Student",
        "ein müder Business-Mann",
        "ein entspannte Surfer-Mädchen",
        "ein sarkastischer Witzbold",
        "ein einfacher Alltagshelfer",
        "ein hippe Jugendlicher",
        "ein weiser Rentner",
        "ein sportlicher Typ"
    }
    
    return personalities[math.random(1, #personalities)]
end

-- Zufälliges Outfit generieren (FreeRoam Komponenten)
function PedManager.GenerateRandomOutfit(model)
    local outfit = {}
    
    -- FreeRoam Komponenten aus Config verwenden
    for componentId, range in pairs(Config.OutfitComponents) do
        outfit[componentId] = {
            math.random(range[1], range[2]),  -- drawable
            math.random(range[3], range[4])   -- texture
        }
    end
    
    return outfit
end

-- Ped spawnen (mit FreeRoam und Persona)
function PedManager.SpawnPed(coords, model, workType)
    -- Generiere zufälliges Geschlecht und Persona
    local gender = math.random(1, 2) == 1 and 'male' or 'female'
    local persona = PedManager.GeneratePersona(nil, gender)
    local outfit = PedManager.GenerateRandomOutfit(persona.model)
    
    -- Verwende FreeRoam-Model anstelle von festem Modell
    local actualModel = model or persona.model
    
    local workCoords = nil
    if workType and Config.Behaviors.working.workLocations then
        local workLoc = Config.Behaviors.working.workLocations[math.random(1, #Config.Behaviors.working.workLocations)]
        workCoords = workLoc.coords
    end
    
    local pedData = PedManager.CreatePedData(actualModel, coords, workType, workCoords)
    pedData.persona = persona
    pedData.outfit = outfit
    PedManager.Peds[pedData.netId] = pedData
    
    -- Persona in Datenbank speichern
    Database.SavePedPersona(pedData.netId, persona, outfit)
    
    -- An alle Clients senden
    TriggerClientEvent('ai-peds:client:spawnPed', -1, pedData.netId, {
        model = pedData.model,
        coords = pedData.coords,
        options = {
            blip = {
                name = persona.name or "AI Ped",
                sprite = 1,
                color = 49,
                scale = 0.8
            }
        },
        workType = pedData.workType,
        workCoords = pedData.workCoords,
        persona = persona,
        outfit = outfit
    })
    
    return pedData.netId
end

-- Alle Peds spawnen (mit FreeRoam)
function PedManager.SpawnAllPeds()
    for i = 1, 20 do
        local randomCoords = vector4(
            math.random(100.0, 2000.0),
            math.random(-2000.0, 100.0),
            30.0,
            math.random(0.0, 360.0)
        )
        PedManager.SpawnPed(randomCoords)
    end
    
    -- Spezifische Peds an konfigurierten Locations
    for i, spawnLoc in ipairs(Config.SpawnLocations) do
        PedManager.SpawnPed(spawnLoc.coords, nil, nil)
    end
    
    if Config.Debug then
        print("^2[AI-Peds] "..PedManager.GetPedCount().." Peds gespawnt")
    end
end

-- Ped entfernen
function PedManager.DeletePed(netId)
    PedManager.Peds[netId] = nil
    TriggerClientEvent('ai-peds:client:deletePed', -1, netId)
end

-- Ped-Status setzen
function PedManager.SetPedState(netId, state)
    if PedManager.Peds[netId] then
        PedManager.Peds[netId].state = state
    end
end

-- Ped von NetID holen
function PedManager.GetPedFromNetId(netId)
    return PedManager.Peds[netId]
end

-- Alle Peds synchronisieren
function PedManager.SyncPedsToPlayer(playerId)
    local pedsTable = {}
    
    for netId, pedData in pairs(PedManager.Peds) do
        pedsTable[netId] = {
            model = pedData.model,
            coords = pedData.coords,
            workType = pedData.workType,
            workCoords = pedData.workCoords,
            persona = pedData.persona,
            outfit = pedData.outfit
        }
    end
    
    TriggerClientEvent('ai-peds:client:syncPeds', playerId, pedsTable)
end

-- Alle Peds evaluieren (KI-Entscheidungen)
function PedManager.EvaluateAllPeds()
    local hour = os.date("*t").hour
    local pedCount = 0
    
    for netId, pedData in pairs(PedManager.Peds) do
        local newState = PedManager.EvaluatePedState(pedData, hour)
        PedManager.SetPedState(netId, newState)
        
        -- An Client senden
        TriggerClientEvent('ai-peds:client:setState', -1, netId, newState)
        
        pedCount = pedCount + 1
    end
    
    if Config.Debug then
        print("^3[AI-Peds] "..pedCount.." Peds evaluiert")
    end
end

-- Einzelnen Ped-Status evaluieren
function PedManager.EvaluatePedState(pedData, hour)
    -- Zufällige Ausnahme: manche Peds machen, was sie wollen
    if math.random() < 0.1 then
        return 'wandering'
    end
    
    -- Arbeitszeit
    if hour >= Config.Behaviors.working.workHours.start and hour < Config.Behaviors.working.workHours.finish then
        if pedData.workType ~= 'none' and math.random() < 0.7 then
            return 'working'
        elseif math.random() < 0.5 then
            return 'social'
        end
    else
        if math.random() < 0.4 then
            return 'social'
        end
    end
    
    return 'wandering'
end

-- Alle Peds aufräumen
function PedManager.CleanupAllPeds()
    for netId, _ in pairs(PedManager.Peds) do
        TriggerClientEvent('ai-peds:client:deletePed', -1, netId)
    end
    PedManager.Peds = {}
end

-- Ped-Anzahl
function PedManager.GetPedCount()
    local count = 0
    for _ in pairs(PedManager.Peds) do
        count = count + 1
    end
    return count
end

-- Ped-Beziehungen verwalten
function PedManager.UpdateRelationships(netId1, netId2, relation, values)
    values = values or {}
    
    if PedManager.Peds[netId1] then
        PedManager.Peds[netId1].relationships[netId2] = {
            relation = relation,
            sympathy = values.sympathy or 50,
            trust = values.trust or 50,
            respect = values.respect or 50,
            familiarity = values.familiarity or 0
        }
    end
    if PedManager.Peds[netId2] then
        PedManager.Peds[netId2].relationships[netId1] = {
            relation = relation,
            sympathy = values.sympathy or 50,
            trust = values.trust or 50,
            respect = values.respect or 50,
            familiarity = values.familiarity or 0
        }
    end
    
    -- In Datenbank speichern
    Database.SavePedRelationship(netId1, netId2, relation, values)
end

-- Ped-Beziehung abrufen
function PedManager.GetRelationship(netId1, netId2)
    if PedManager.Peds[netId1] and PedManager.Peds[netId1].relationships[netId2] then
        return PedManager.Peds[netId1].relationships[netId2]
    end
    return {relation = 'neutral', sympathy = 50, trust = 50, respect = 50, familiarity = 0}
end

-- Beziehungswerte beeinflussen (nach Kommunikation)
function PedManager.AdjustRelationshipValues(netId1, netId2, sympathyChange, trustChange, respectChange)
    if not PedManager.Peds[netId1] or not PedManager.Peds[netId2] then return end
    
    local rel = PedManager.GetRelationship(netId1, netId2)
    
    rel.sympathy = math.max(0, math.min(100, rel.sympathy + (sympathyChange or 0)))
    rel.trust = math.max(0, math.min(100, rel.trust + (trustChange or 0)))
    rel.respect = math.max(0, math.min(100, rel.respect + (respectChange or 0)))
    rel.familiarity = math.max(0, math.min(100, rel.familiarity + 5)) -- Bekanntschaft steigt immer
    
    -- Relation Status aktualisieren basierend auf Werten
    local newRelation = 'neutral'
    if rel.sympathy >= 80 and rel.trust >= 70 then
        newRelation = 'friend'
    elseif rel.sympathy < 20 or rel.trust < 20 then
        newRelation = 'enemy'
    end
    
    PedManager.UpdateRelationships(netId1, netId2, newRelation, rel)
end

return PedManager