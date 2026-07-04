Config = {}

-- Allgemeine Einstellungen
Config.Debug = false
Config.UseQbCore = true -- Set to false to use ESX

-- Peds Einstellungen
Config.SpawnLocations = {
    {coords = vector4(230.0, -800.0, 30.0, 100.0), model = 'a_m_m_business_01'}, -- Forum
    {coords = vector4(-450.0, -2750.0, 6.0, 45.0), model = 'a_m_m_farmer_01'}, -- Farm
    {coords = vector4(1200.0, -1300.0, 35.0, 180.0), model = 'a_f_m_business_02'}, -- City
    {coords = vector4(-1400.0, -400.0, 20.0, 270.0), model = 'a_m_m_hillbilly_01'}, -- Country
    {coords = vector4(500.0, -900.0, 25.0, 90.0), model = 'a_f_m_downtown_01'} -- Downtown
}

-- KI Verhaltensweisen
Config.Behaviors = {
    wandering = {
        enabled = true,
        minWaitTime = 3000, -- ms
        maxWaitTime = 10000,
        minWalkTime = 5000,
        maxWalkTime = 20000,
        walkingStyle = {1, 2, 3, 4, 5} -- 1=normal, 2=confident, 3=drunk, etc.
    },
    working = {
        enabled = true,
        workHours = {start = 8, finish = 18}, -- 8 AM to 6 PM game time
        workLocations = {
            {name = 'construction', coords = vector4(-450.0, -2750.0, 6.0, 0), model = 'a_m_m_constructionworker_01'},
            {name = 'shop', coords = vector4(230.0, -800.0, 30.0, 0), model = 'a_m_m_business_01'},
            {name = 'farm', coords = vector4(2000.0, 4800.0, 28.0, 0), model = 'a_m_m_farmer_01'}
        }
    },
    social = {
        enabled = true,
        chatRange = 5.0, -- meters
        groupChatChance = 0.3, -- 30% chance to include nearby peds
        talkTime = {min = 5000, max = 15000}
    }
}

-- Kommunikation
Config.ChatMessages = {
    greetings = {
        "Hey, wie geht's?",
        "Guten Tag!",
        "Was ist los hier?",
        "Hallo zusammen!",
        "Schön dich zu sehen!"
    },
    workTopics = {
        "Die Arbeit nervt total heute...",
        "Hab schon wieder zu lange geblüzt",
        "Wann haben wir Freizeit?",
        "Der Chef nervt wieder",
        "Heute war eine schöne Arbeitsphase"
    },
    casualChatter = {
        "Stimmt der Wetterbericht?",
        "Kennst du schon das neue Restaurant?",
        "Die Welt ist schon verrückt...",
        "Alles wird gut, oder?",
        "Zeit für einen Kaffee"
    }
}

-- Animationen
Config.Animations = {
    idle = {
        {'amb@world_human_stand_fishing@idle_a', 'idle_a'},
        {'mp_ped_intercept_arms_folded', 'idle'},
        {'anim@mp_sit_taxi@rps', 'sit'}
    },
    work = {
        {'amb@world_human_construction_worker@male@base', 'base'},
        {'amb@world_human_farmer@male@base', 'base'},
        {'anim@mp_sit_taxi@rps', 'sit'}
    },
    social = {
        {'amb@world_human_talking@male_a@idle_a', 'idle_a'},
        {'amb@world_human_talking@male_b@idle_a', 'idle_a'}
    }
}

-- Ped-Modelle für verschiedene Berufe
Config.PedModels = {
    business = {'a_m_m_business_01', 'a_f_m_business_02', 'a_m_y_business_02', 'a_f_y_business_04'},
    construction = {'a_m_m_constructionworker_01', 'a_m_y_constructivedriver_01'},
    farmer = {'a_m_m_farmer_01', 'a_f_m_farmer_01'},
    casual = {'a_m_m_beach_01', 'a_f_m_tourist_01', 'a_m_y_tourist_01', 'a_f_y_tourist_02'}
}

-- FreeRoam Models für dynamische Peds
Config.FreeRoamModels = {
    male = 'mp_m_freemode_01',
    female = 'mp_f_freemode_01'
}

-- KI-Persona Einstellungen
Config.KIPersona = {
    firstNames = {
        male = {'Liam', 'Noah', 'Paul', 'Elias', 'Finn', 'Leon', 'Louis', 'Ben', 'Paul', 'Lukas'},
        female = {'Mia', 'Emma', 'Hannah', 'Lea', 'Anna', 'Lena', 'Lina', 'Marie', 'Sophie', 'Laura'}
    },
    lastNames = {'Müller', 'Schmidt', 'Weber', 'Klein', 'Wagner', 'Becker', 'Schneider', 'Fischer', 'Meyer', 'Wolf'}
}

-- Kleidungs-Variationen für FreeRoam Peds
Config.OutfitComponents = {
    -- Komponenten-IDs für FreeRoam Modelle (GTA V Komponenten)
    -- [komponentenId] = {drawableMin, drawableMax, textureMin, textureMax}
    [1] = {0, 45, 0, 1},   -- Gesicht (Face)
    [2] = {0, 100, 0, 1},  -- Haare (Hair) - drawable + texture für Farbe
    [3] = {0, 200, 0, 5},  -- Oberkörper (Torso) - undershirt + tattoos
    [4] = {0, 150, 0, 5},  -- Hose (Legs)
    [5] = {0, 50, 0, 1},   -- Bags/Hüte (Bags/Parachute)
    [6] = {0, 50, 0, 2},   -- Schuhe (Shoes)
    [7] = {0, 50, 0, 2},   -- Schmuck (Accessories) - Maske, Brillen
    [8] = {0, 10, 0, 1},   -- Zubehör (Shirt/Scarf)
    [9] = {0, 10, 0, 1},   -- Weste (Armor)
    [10] = {0, 200, 0, 1}, -- Gesichtsausdruck (Decoration/Tattoos)
    [11] = {0, 50, 0, 2},  -- Kopftuch/Mütze (Top)
    [12] = {0, 200, 0, 5}  -- Hände/Arme (Watches/Bracelets)
}