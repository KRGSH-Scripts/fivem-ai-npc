PedBehavior = {}

-- Zufällige Wander-Route generieren
function PedBehavior.GenerateWanderRoute(ped, center, radius)
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius
    local offsetX = math.cos(angle) * distance
    local offsetY = math.sin(angle) * distance
    
    return vector3(center.x + offsetX, center.y + offsetY, center.z)
end

-- Ped zum Ziel navigieren
function PedBehavior.NavigateTo(ped, targetCoords, speed)
    speed = speed or 1.0
    TaskGoToCoord(ped, targetCoords.x, targetCoords.y, targetCoords.z, speed, false, 0, 0)
end

-- Prüfen ob Ped ein Ziel erreicht hat
function PedBehavior.HasReachedTarget(ped, targetCoords, threshold)
    threshold = threshold or 1.0
    local pedCoords = GetEntityCoords(ped)
    return #(pedCoords - targetCoords) < threshold
end

-- Zufällige Wartezeit
function PedBehavior.GetRandomWaitTime()
    return math.random(Config.Behaviors.wandering.minWaitTime, Config.Behaviors.wandering.maxWaitTime)
end

-- Arbeitszeit prüfen
function PedBehavior.IsWorkHour()
    local hour = GetClockHours()
    local workStart = Config.Behaviors.working.workHours.start
    local workFinish = Config.Behaviors.working.workHours.finish
    
    return hour >= workStart and hour < workFinish
end

-- Ped-Blockade erstellen (für Gruppen)
function PedBehavior.CreateConversationGroup(peds)
    for _, ped in ipairs(peds) do
        TaskSetBlockingOfNonTemporaryEvents(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
    end
end

-- Ped-Bewegung freigeben
function PedBehavior.ReleasePed(ped)
    ClearPedTasksImmediately(ped)
    SetBlockingOfNonTemporaryEvents(ped, false)
end

-- Zufällige Szene erstellen
function PedBehavior.CreateRandomScene(ped, sceneType)
    -- Szene-Typ: idle, work, social
    if sceneType == 'idle' then
        Animations.PlayRandomIdle(ped)
    elseif sceneType == 'work' then
        -- Work-Animations basierend auf Model
        local model = GetEntityModel(ped)
        if string.find(model, 'construction') then
            Animations.PlayWorkAnim(ped, 'construction')
        elseif string.find(model, 'farmer') then
            Animations.PlayWorkAnim(ped, 'farming')
        end
    end
end

return PedBehavior