Database = {}

-- Ped-Beziehungen speichern/laden
function Database.LoadPedRelationships()
    local result = MySQL.Sync.fetchAll('SELECT * FROM ai_peds_relationships', {})
    
    if result then
        for _, row in ipairs(result) do
            PedManager.UpdateRelationships(
                tonumber(row.ped1_netid),
                tonumber(row.ped2_netid),
                row.relation,
                {
                    sympathy = row.sympathy or 50,
                    trust = row.trust or 50,
                    respect = row.respect or 50,
                    familiarity = row.familiarity or 0
                }
            )
        end
    end
end

-- Ped-Beziehung speichern
function Database.SavePedRelationship(pedNetId1, pedNetId2, relation, values)
    values = values or {}
    MySQL.Async.execute([[
        INSERT INTO ai_peds_relationships (ped1_netid, ped2_netid, sympathy, trust, respect, familiarity, relation) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
        sympathy = VALUES(sympathy),
        trust = VALUES(trust),
        respect = VALUES(respect),
        familiarity = VALUES(familiarity),
        relation = VALUES(relation)
    ]], {
        pedNetId1,
        pedNetId2,
        values.sympathy or 50,
        values.trust or 50,
        values.respect or 50,
        values.familiarity or 0,
        relation or 'neutral'
    })
end

-- Ped-Beziehung laden
function Database.GetPedRelationship(pedNetId1, pedNetId2)
    local result = MySQL.Sync.fetchAll([[
        SELECT * FROM ai_peds_relationships 
        WHERE (ped1_netid = ? AND ped2_netid = ?) OR (ped1_netid = ? AND ped2_netid = ?)
    ]], {pedNetId1, pedNetId2, pedNetId2, pedNetId1})
    
    if result and result[1] then
        local row = result[1]
        local isPed1First = (row.ped1_netid == pedNetId1)
        return {
            ped1_netid = row.ped1_netid,
            ped2_netid = row.ped2_netid,
            sympathy = row.sympathy or 50,
            trust = row.trust or 50,
            respect = row.respect or 50,
            familiarity = row.familiarity or 0,
            relation = row.relation or 'neutral'
        }
    end
    return nil
end

-- Ped-Interaktion speichern
function Database.SavePedInteraction(pedNetId, playerId, interactionType)
    MySQL.Async.insert('INSERT INTO ai_peds_interactions (ped_netid, player_id, interaction_type, timestamp) VALUES (?, ?, ?, ?)', {
        pedNetId,
        playerId,
        interactionType,
        os.time()
    }, function(insertId)
        if Config.Debug then
            print("^3[AI-Peds] Interaktion gespeichert: "..insertId)
        end
    end)
end

-- Ped-Statistiken laden
function Database.LoadPedStats(pedNetId)
    local result = MySQL.Sync.fetchAll('SELECT * FROM ai_peds_stats WHERE ped_netid = ?', {pedNetId})
    
    if result and result[1] then
        return {
            happiness = result[1].happiness or 50,
            energy = result[1].energy or 100,
            socialLevel = result[1].social_level or 50
        }
    end
    
    return {happiness = 50, energy = 100, socialLevel = 50}
end

-- Ped-Statistiken speichern
function Database.SavePedStats(pedNetId, stats)
    MySQL.Async.execute([[
        INSERT INTO ai_peds_stats (ped_netid, happiness, energy, social_level) 
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
        happiness = VALUES(happiness),
        energy = VALUES(energy),
        social_level = VALUES(social_level)
    ]], {
        pedNetId,
        stats.happiness,
        stats.energy,
        stats.socialLevel
    })
end

-- Ped-Persona speichern
function Database.SavePedPersona(pedNetId, persona, outfit)
    MySQL.Async.execute([[
        INSERT INTO ai_peds_personas (ped_netid, name, personality, model, outfit_components, created_at) 
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
        name = VALUES(name),
        personality = VALUES(personality),
        model = VALUES(model),
        outfit_components = VALUES(outfit_components)
    ]], {
        pedNetId,
        persona.name,
        persona.personality,
        persona.model,
        json.encode(outfit),
        os.time()
    })
end

-- Ped-Persona laden
function Database.LoadPedPersona(pedNetId)
    local result = MySQL.Sync.fetchAll('SELECT * FROM ai_peds_personas WHERE ped_netid = ?', {pedNetId})
    
    if result and result[1] then
        local outfit = {}
        if result[1].outfit_components then
            outfit = json.decode(result[1].outfit_components) or {}
        end
        
        return {
            name = result[1].name,
            personality = result[1].personality,
            model = result[1].model,
            outfit = outfit
        }
    end
    
    return nil
end

-- Migration prüfen und Tabellen erstellen (wenn oxmysql verfügbar)
Citizen.CreateThread(function()
    Wait(5000) -- Warten bis MySQL bereit ist
    
    if GetResourceState('oxmysql') == 'started' then
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS ai_peds_stats (
                ped_netid INT PRIMARY KEY,
                happiness INT DEFAULT 50,
                energy INT DEFAULT 100,
                social_level INT DEFAULT 50
            )
        ]], function() end)
        
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS ai_peds_relationships (
                id INT AUTO_INCREMENT PRIMARY KEY,
                ped1_netid INT,
                ped2_netid INT,
                sympathy INT DEFAULT 50,
                trust INT DEFAULT 50,
                respect INT DEFAULT 50,
                familiarity INT DEFAULT 0,
                relation VARCHAR(20) DEFAULT 'neutral',
                UNIQUE KEY unique_pair (ped1_netid, ped2_netid)
            )
        ]], function() end)
        
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS ai_peds_interactions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                ped_netid INT,
                player_id INT,
                interaction_type VARCHAR(50),
                timestamp INT
            )
        ]], function() end)
        
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS ai_peds_personas (
                ped_netid INT PRIMARY KEY,
                name VARCHAR(50),
                personality TEXT,
                model VARCHAR(50),
                outfit_components TEXT,
                created_at INT
            )
        ]], function() end)
        
        if Config.Debug then
            print("^2[AI-Peds] Datenbank-Tabellen bereit")
        end
    end
end)

return Database