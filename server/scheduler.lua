---
--- AI Scheduler - KV-Cache optimierte KI-Updates
---

AIScheduler = {}
AIScheduler.Interval = Settings.Scheduler and Settings.Scheduler.interval or 120000
AIScheduler.Enabled = Settings.Scheduler and Settings.Scheduler.enabled or false

-- Wetter
function AIScheduler.GetWeather()
    local weatherTypes = {"EXTRASUNNY", "CLEAR", "NEUTRAL", "SMOG", "FOGGY", "OVERCAST", "RAIN", "THUNDER"}
    return weatherTypes[math.random(1, #weatherTypes)]
end

-- NPC-Perspektive erstellen
function AIScheduler.GetPerspective(netId)
    local ped = PedManager.GetPedFromNetId(netId)
    if not ped then return nil end
    
    return {
        id = netId,
        name = ped.persona and ped.persona.name or "NPC",
        pers = ped.persona and ped.persona.personality or "neutral",
        state = ped.state or "idle",
        work = ped.workType or "none",
        x = ped.coords and ped.coords.x or 0,
        y = ped.coords and ped.coords.y or 0,
        z = ped.coords and ped.coords.z or 0,
        weather = AIScheduler.GetWeather(),
        hour = GetClockHours(),
        workTime = PedBehavior.IsWorkHour(),
        relCount = AIScheduler.GetRelCount(netId, ped.relationships),
        nearCount = AIScheduler.CountNearby(netId, ped.coords)
    }
end

-- Relationships zählen
function AIScheduler.GetRelCount(netId, rels)
    if not rels then return 0 end
    local count = 0
    for _ in pairs(rels) do count = count + 1 end
    return count
end

-- NPCs in der Nähe zählen
function AIScheduler.CountNearby(netId, coords)
    local count = 0
    if not coords then return count end
    
    for otherId, otherPed in pairs(PedManager.Peds) do
        if otherId ~= netId and otherPed.coords then
            if #(vector3(coords.x, coords.y, coords.z) - vector3(otherPed.coords.x, otherPed.coords.y, otherPed.coords.z)) <= 10.0 then
                count = count + 1
            end
        end
    end
    return count
end

-- KV-Cache optimierter Markdown Prompt
function AIScheduler.GeneratePrompt(netId, p)
    return string.format([[# NPC_%d
NAME: %s
PERS: %s
STATE: %s
WORK: %s
POS: %.1f,%.1f
WEATHER: %s
HOUR: %d
WORKTIME: %s
RELS: %d
NEAR: %d

# TOOLS: speak, moveTo, workAt, interact, setState, getRelationship, remember

# DECISION:
]],
        p.id,
        p.name,
        p.pers,
        p.state,
        p.work,
        p.x, p.y,
        p.weather,
        p.hour,
        p.workTime and "yes" or "no",
        p.relCount,
        p.nearCount)
end

-- LLM Antwort parsen
function AIScheduler.ParseResponse(response)
    if not response then return nil end
    
    -- Einfaches Parsing: "TOOL: param=value, ..."
    local tool = string.match(response, "#%s*(%w+)%s*:")
    if not tool then
        tool = string.match(response, "^(%w+)") -- Einfaches Wort am Anfang
    end
    
    if tool then
        local params = {}
        for k,v in string.gmatch(response, "(%w+)[=:][%s\"']*(%S+)") do
            params[k] = tonumber(v) or v
        end
        return {tool=tool, params=params}
    end
    return nil
end

-- KI-Entscheidung anfragen
function AIScheduler.RequestDecision(netId, perspective)
    if not Settings.OpenRouterEnabled then return nil end
    
    local prompt = AIScheduler.GeneratePrompt(netId, perspective)
    -- Placeholder für PerformHttpRequest
    return nil
end

-- NPC Update
function AIScheduler.UpdatePed(netId)
    local p = AIScheduler.GetPerspective(netId)
    if not p then return end
    
    local decision = AIScheduler.RequestDecision(netId, p)
    if decision then
        exports['ai-peds']:ExecuteTool(decision.tool, netId, decision.params)
    else
        AIScheduler.Fallback(netId, p)
    end
end

-- Fallback ohne KI
function AIScheduler.Fallback(netId, p)
    if p.workTime and p.work ~= "none" and math.random(1,10) < 6 then
        exports['ai-peds']:ExecuteTool('setState', netId, 'working')
    elseif p.nearCount > 0 and math.random(1,10) < 4 then
        exports['ai-peds']:ExecuteTool('setState', netId, 'social')
    else
        exports['ai-peds']:ExecuteTool('setState', netId, 'wandering')
    end
end

-- Scheduler Loop
function AIScheduler.Start()
    if AIScheduler.Enabled then return end
    AIScheduler.Enabled = true
    
    CreateThread(function()
        while AIScheduler.Enabled do
            Wait(AIScheduler.Interval)
            for netId,_ in pairs(PedManager.Peds) do
                AIScheduler.UpdatePed(netId)
            end
        end
    end)
end

function AIScheduler.Stop()
    AIScheduler.Enabled = false
end

AddEventHandler('onResourceStart', function(r) if r==GetCurrentResourceName() then AIScheduler.Start() end end)
AddEventHandler('onResourceStop', function(r) if r==GetCurrentResourceName() then AIScheduler.Stop() end end)

return AIScheduler