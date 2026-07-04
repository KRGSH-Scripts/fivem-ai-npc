---
--- NPC Tools - Hauptdatei, lädt alle Tools
---

NPCObjects = {}

-- Tool-Module laden
NPCObjects.ToolModules = {
    speak = require 'tools/speak',
    move = require 'tools/move',
    work = require 'tools/work',
    interact = require 'tools/interact',
    relationship = require 'tools/relationship',
    state = require 'tools/state',
    scan = require 'tools/scan',
    remember = require 'tools/remember'
}

-- Tool-Registry für externe Tools
NPCObjects.ExternalTools = {}

-- Tool-Schema-Definitionen
NPCObjects.ToolSchemas = {
    speak = {
        name = "speak",
        description = "Lässt einen NPC etwas sagen",
        parameters = {
            netId = "number (Ped-NetId)",
            message = "string (Zu sprechender Text)",
            emotion = "string (optional: happy/sad/angry/neutral)",
            duration = "number (optional: Anzeigedauer in ms)"
        }
    },
    moveTo = {
        name = "moveTo",
        description = "Bewegt einen NPC zu Koordinaten",
        parameters = {
            netId = "number (Ped-NetId)",
            x = "number",
            y = "number",
            z = "number",
            speed = "number (optional: 0.5-2.0)"
        }
    },
    workAt = {
        name = "workAt",
        description = "NPC arbeitet an einem Ort",
        parameters = {
            netId = "number (Ped-NetId)",
            location = "string (work_location name)",
            duration = "number (optional: Arbeitsdauer in ms)"
        }
    },
    interact = {
        name = "interact",
        description = "Interagiert mit einem anderen NPC",
        parameters = {
            netId = "number (ausführender Ped-NetId)",
            targetNetId = "number (Zielfeld-NetId)",
            action = "string (chat/follow/greet)"
        }
    },
    getRelationship = {
        name = "getRelationship",
        description = "Holt Beziehungswerte zwischen NPCs",
        parameters = {netId1 = "number", netId2 = "number"}
    },
    setState = {
        name = "setState",
        description = "Setzt den Zustand eines NPCs",
        parameters = {netId = "number", state = "string"}
    },
    scanEnvironment = {
        name = "scanEnvironment",
        description = "Scannt Umgebung nach NPCs im Radius",
        parameters = {netId = "number", radius = "number (optional, default 10)"}
    },
    remember = {
        name = "remember",
        description = "Speichert NPC-Erinnerungen für KI-Entscheidungen",
        parameters = {netId = "number", key = "string", value = "any"}
    }
}

-- Tool ausführen
function NPCObjects.ExecuteTool(toolName, ...)
    local args = {...}
    local unpackFn = table.unpack or unpack

    -- Prüfe Standard-Tools
    if NPCObjects.ToolModules[toolName] then
        local success, result = pcall(function()
            return NPCObjects.ToolModules[toolName].Execute(unpackFn(args))
        end)
        
        if success then
            return {success = true, result = result, tool = toolName}
        else
            return {success = false, error = tostring(result), tool = toolName}
        end
    end
    
    -- Prüfe externe Tools
    if NPCObjects.ExternalTools[toolName] then
        local success, result = pcall(function()
            return NPCObjects.ExternalTools[toolName].execute(unpackFn(args))
        end)
        
        if success then
            return {success = true, result = result, tool = toolName}
        else
            return {success = false, error = tostring(result), tool = toolName}
        end
    end
    
    return {success = false, error = "Tool nicht gefunden: " .. tostring(toolName)}
end

-- Tool registrieren
function NPCObjects.RegisterTool(name, toolDef)
    NPCObjects.ExternalTools[name] = toolDef
end

-- Schema für KI abrufen
function NPCObjects.GetToolSchema()
    return NPCObjects.ToolSchemas
end

-- Exports
exports('ExecuteTool', function(toolName, ...)
    return NPCObjects.ExecuteTool(toolName, ...)
end)

exports('RegisterTool', function(name, toolDef)
    NPCObjects.RegisterTool(name, toolDef)
end)

exports('GetToolSchema', function()
    return NPCObjects.GetToolSchema()
end)

return NPCObjects