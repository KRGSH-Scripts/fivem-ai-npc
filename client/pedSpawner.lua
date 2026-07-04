PedSpawner = {}
PedSpawner.SpawnedPeds = {}
PedSpawner.PedModels = {}

-- Ped-Model laden
function PedSpawner.LoadModel(model)
    if not IsModelInCdimage(model) then return false end
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    return true
end

-- Ped entfernen
function PedSpawner.DeletePed(pedNetId)
    local ped = NetToPed(pedNetId)
    if DoesEntityExist(ped) then
        DeletePed(ped)
    end
    PedSpawner.SpawnedPeds[pedNetId] = nil
end

-- Alle Peds entfernen
function PedSpawner.CleanupPeds()
    for netId, ped in pairs(PedSpawner.SpawnedPeds) do
        if DoesEntityExist(ped) then
            DeletePed(ped)
        end
    end
    PedSpawner.SpawnedPeds = {}
end

-- Ped-Model vorbereiten
function PedSpawner.PrepareModels()
    -- FreeRoam-Modelle laden (für dynamische Peds)
    if Config.FreeRoamModels then
        PedSpawner.LoadModel(Config.FreeRoamModels.male)
        PedSpawner.LoadModel(Config.FreeRoamModels.female)
    else
        PedSpawner.LoadModel('mp_m_freemode_01')
        PedSpawner.LoadModel('mp_f_freemode_01')
    end
    
    -- Weitere Modelle für Referenz
    for category, models in pairs(Config.PedModels or {}) do
        for _, model in ipairs(models) do
            PedSpawner.LoadModel(model)
        end
    end
end

-- Ped mit Outfit spawnen (FreeRoam)
function PedSpawner.SpawnPed(model, coords, options, outfit, persona)
    if not PedSpawner.LoadModel(model) then
        if Config.Debug then
            print("^1[AI-Peds] Model "..model.." konnte nicht geladen werden")
        end
        return nil
    end
    
    local ped = CreatePed(28, model, coords.x, coords.y, coords.z, coords.w, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedCanPlayAmbientAnims(ped, true)
    SetPedCanPlayAmbientBaseAnims(ped, true)
    
    -- FreeRoam Outfit anwenden (wenn vorhanden)
    if outfit then
        PedSpawner.ApplyOutfit(ped, outfit)
    end
    
    if options then
        if options.blip then
            local blip = AddBlipForEntity(ped)
            SetBlipSprite(blip, options.blip.sprite or 1)
            SetBlipColour(blip, options.blip.color or 49)
            SetBlipScale(blip, options.blip.scale or 0.8)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(options.blip.name or "AI Ped")
            EndTextCommandSetBlipName(blip)
        end
        
        if options.scenario then
            TaskStartScenarioAtPosition(ped, options.scenario, coords.x, coords.y, coords.z, coords.w, -1, true, true)
        end
    end
    
    return ped
end

-- Outfit auf Ped anwenden
function PedSpawner.ApplyOutfit(ped, outfit)
    if not outfit then return end
    
    -- Komponenten anwenden: [componentId] = {drawable, texture}
    for componentId, variation in pairs(outfit) do
        if variation[1] and variation[2] then
            SetPedComponentVariation(ped, tonumber(componentId), variation[1], variation[2], 2)
        end
    end
end

-- Net ID zu Ped-Entity
function PedSpawner.GetPedFromNetId(netId)
    return NetToPed(netId)
end

return PedSpawner