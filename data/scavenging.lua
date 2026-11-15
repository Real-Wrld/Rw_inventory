-- Scavenging Loot Tables Configuration
-- Defines searchable locations, loot pools, and drop chances
-- Blueprints are RARE drops with low probability

return {
    -- ==========================================
    -- LOOT POOLS
    -- ==========================================
    pools = {
        -- Garbage/Junk pool (common)
        garbage = {
            { name = 'trash',      weight = 30, count = { min = 1, max = 3 } },
            { name = 'scrapmetal', weight = 25, count = { min = 1, max = 2 } },
            { name = 'plastic',    weight = 20, count = { min = 1, max = 3 } },
            { name = 'paper',      weight = 15, count = { min = 1, max = 5 } },
            { name = 'cloth',      weight = 10, count = { min = 1, max = 2 } },
        },

        -- Electronics pool (uncommon)
        electronics = {
            { name = 'electronics', weight = 35, count = { min = 1, max = 2 } },
            { name = 'copper',      weight = 25, count = { min = 1, max = 3 } },
            { name = 'scrapmetal',  weight = 20, count = { min = 1, max = 2 } },
            { name = 'glass',       weight = 15, count = { min = 1, max = 2 } },
            { name = 'plastic',     weight = 5,  count = { min = 1, max = 1 } },
        },

        -- Medical pool (uncommon)
        medical = {
            { name = 'bandage',          weight = 35, count = { min = 1, max = 3 } },
            { name = 'painkillers',      weight = 25, count = { min = 1, max = 2 } },
            { name = 'alcohol',          weight = 20, count = { min = 1, max = 1 } },
            { name = 'cloth',            weight = 15, count = { min = 1, max = 2 } },
            { name = 'medical_supplies', weight = 5,  count = { min = 1, max = 1 } },
        },

        -- Hardware pool (uncommon)
        hardware = {
            { name = 'scrapmetal', weight = 30, count = { min = 1, max = 3 } },
            { name = 'steel',      weight = 20, count = { min = 1, max = 2 } },
            { name = 'rubber',     weight = 20, count = { min = 1, max = 2 } },
            { name = 'plastic',    weight = 15, count = { min = 1, max = 2 } },
            { name = 'aluminum',   weight = 10, count = { min = 1, max = 1 } },
            { name = 'titanium',   weight = 5,  count = { min = 1, max = 1 } },
        },
        
        -- Other (uncommon)
        other = {
            { name = 'diamond', weight = 150, count = { min = 1, max = 1 } },
            { name = 'diamond_ring',      weight = 200, count = { min = 1, max = 2 } },
            { name = 'cleaningkit',     weight = 400, count = { min = 1, max = 2 } },
            { name = 'plastic_bag',    weight = 30, count = { min = 1, max = 4 } },
            { name = 'gold_ingot',   weight = 1000, count = { min = 1, max = 1 } },
            { name = 'grinder',   weight = 700,  count = { min = 1, max = 1 } },
            { name = 'ruby',   weight = 155,  count = { min = 1, max = 1 } },
        },

        -- Blueprint pool (RARE) - Low chance to roll, then pick from these
        blueprints = {
            -- Advanced blueprints (most common in blueprint pool)
            { name = 'blueprint_advanced_lockpick',       weight = 20,   count = { min = 1, max = 1 } },
            { name = 'blueprint_advanced_radio',          weight = 18,   count = { min = 1, max = 1 } },
            { name = 'blueprint_advancedrepairkit',       weight = 18,   count = { min = 1, max = 1 } },
            { name = 'blueprint_advanced_armor',          weight = 15,   count = { min = 1, max = 1 } },
            { name = 'blueprint_cobalt_lockpick',         weight = 12,   count = { min = 1, max = 1 } }, -- New
            { name = 'blueprint_nightvision',             weight = 10,   count = { min = 1, max = 1 } },
            { name = 'blueprint_thermite',                weight = 8,    count = { min = 1, max = 1 } },
            { name = 'blueprint_shadow_parachute',        weight = 8,    count = { min = 1, max = 1 } }, -- New
            -- Master blueprints (rare in blueprint pool)
            { name = 'blueprint_master_lockpick',         weight = 4,    count = { min = 1, max = 1 } },
            { name = 'blueprint_master_medkit',           weight = 3,    count = { min = 1, max = 1 } },
            { name = 'blueprint_adamantite_armor',        weight = 3,    count = { min = 1, max = 1 } }, -- New
            { name = 'blueprint_emp_grenade',             weight = 2,    count = { min = 1, max = 1 } },
            { name = 'blueprint_hacking_device',          weight = 1,    count = { min = 1, max = 1 } },
            { name = 'blueprint_c4',                      weight = 0.5,  count = { min = 1, max = 1 } },
            { name = 'blueprint_infernal_charge',         weight = 0.5,  count = { min = 1, max = 1 } }, -- New
            -- Khan futuristic weapon blueprints (rare — power scales with weight)
            { name = 'blueprint_WEAPON_ascia',            weight = 1.2,  count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_motosega',         weight = 0.7,  count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_SARATOGA',         weight = 0.55, count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_carnage',          weight = 0.45, count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_skippy',           weight = 0.25, count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_silverhand',       weight = 0.12, count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_MASAMUNE',         weight = 0.1,  count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_NEKOMATA',         weight = 0.04, count = { min = 1, max = 1 } },
            -- Legendary blueprints (EXTREMELY rare)
            { name = 'blueprint_legendary_toolkit',       weight = 0.3,  count = { min = 1, max = 1 } },
            { name = 'blueprint_legendary_armor',         weight = 0.1,  count = { min = 1, max = 1 } },
            { name = 'blueprint_runite_blade',            weight = 0.1,  count = { min = 1, max = 1 } }, -- New
            { name = 'blueprint_ramp',                    weight = 0.15, count = { min = 1, max = 1 } }, -- Ramp
            { name = 'blueprint_legendary_emp',           weight = 0.08, count = { min = 1, max = 1 } },
            { name = 'blueprint_legendary_hacking_suite', weight = 0.02, count = { min = 1, max = 1 } },
        },
    },

    -- ==========================================
    -- SEARCHABLE LOCATIONS
    -- ==========================================
    locations = {
        -- Store Shelves (common location)
        store_shelves = {
            label = 'Search Shelves',
            model = { 'prop_shelves_01', 'prop_shelves_02', 'prop_shelves_03', 'prop_shelves_04', 'prop_shelves_05' },
            animation = { dict = 'anim@gangops@facility@servers@bodysearch@', anim = 'player_search' },
            duration = 5000,   -- 5 seconds to search
            cooldown = 300000, -- 5 minutes cooldown per location

            -- Loot chances (must sum to 100)
            lootChances = {
                { pool = 'nothing',     chance = 25 },
                { pool = 'garbage',     chance = 30 },
                { pool = 'other',       chance = 20 },
                { pool = 'hardware',    chance = 12 },
                { pool = 'electronics', chance = 8 },
                { pool = 'blueprints',  chance = 5 },
            },
        },

        -- Dumpsters (garbage mostly)
        --[[
        dumpster = {
            label = 'Search Dumpster',
            model = { 'prop_dumpster_01a', 'prop_dumpster_02a', 'prop_dumpster_02b', 'prop_dumpster_3a' },
            animation = { dict = 'amb@prop_human_bum_bin@base', anim = 'base' }, -- Crouching/rummaging
            duration = 4000,
            cooldown = 180000,                                                   -- 3 minutes

            lootChances = {
                { pool = 'nothing',     chance = 50 },
                { pool = 'garbage',     chance = 40 },
                { pool = 'electronics', chance = 6 },
                { pool = 'blueprints',  chance = 4 }, -- Slightly higher than shelves (people throw stuff away)
            },
        },
        ]]

        -- Storage Crates (industrial areas)
        storage_crate = {
            label = 'Search Crate',
            model = { 'prop_box_wood01a', 'prop_box_wood02a', 'prop_box_wood03a', 'prop_box_wood04a' },
            animation = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', anim = 'machinic_loop_mechandplayer' },
            duration = 6000,
            cooldown = 420000, -- 7 minutes

            lootChances = {
                { pool = 'nothing',     chance = 30 },
                { pool = 'hardware',    chance = 40 },
                { pool = 'garbage',     chance = 15 },
                { pool = 'electronics', chance = 10 },
                { pool = 'blueprints',  chance = 5 }, -- Better odds at industrial
            },
        },

        -- Filing Cabinets (offices)
        filing_cabinet = {
            label = 'Search Cabinet',
            model = { 'v_res_fa_cabinetside', 'p_v_43_safe_s', 'v_corp_filecabdoor' },
            animation = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', anim = 'machinic_loop_mechandplayer' },
            duration = 4000,
            cooldown = 240000, -- 4 minutes

            lootChances = {
                { pool = 'nothing',     chance = 45 },
                { pool = 'garbage',     chance = 30 },
                { pool = 'electronics', chance = 12 },
                { pool = 'blueprints',  chance = 8 }, -- Office = more likely to find blueprints
                { pool = 'medical',     chance = 5 },
            },
        },

        -- Medical Cabinets (hospitals, clinics)
        medical_cabinet = {
            label = 'Search Medical Cabinet',
            model = { 'v_med_cabinet01', 'v_med_cabinet02', 'prop_med_bag_01' },
            animation = { dict = 'amb@medic@standing@tendtodead@base', anim = 'base' },
            duration = 5000,
            cooldown = 360000, -- 6 minutes

            lootChances = {
                { pool = 'nothing',    chance = 35 },
                { pool = 'medical',    chance = 50 },
                { pool = 'garbage',    chance = 10 },
                { pool = 'blueprints', chance = 5 }, -- Medical blueprints here
            },
        },

        -- Tool Cabinets (garages, mechanic shops)
        tool_cabinet = {
            label = 'Search Tool Cabinet',
            model = { 'prop_tool_box_01', 'prop_tool_box_02', 'prop_tool_box_05', 'prop_tool_bench02' },
            animation = { dict = 'mini@repair', anim = 'fixing_a_player' },
            duration = 5000,
            cooldown = 300000, -- 5 minutes

            lootChances = {
                { pool = 'nothing',     chance = 25 },
                { pool = 'hardware',    chance = 50 },
                { pool = 'electronics', chance = 12 },
                { pool = 'blueprints',  chance = 8 }, -- Tools = crafting stuff
                { pool = 'garbage',     chance = 5 },
            },
        },

        -- Hidden Stash (rare spawn, best odds)
        hidden_stash = {
            label = 'Search Hidden Stash',
            model = { 'prop_cs_cardbox_01', 'hei_prop_heist_safedeposit' },
            animation = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', anim = 'machinic_loop_mechandplayer' },
            duration = 8000,   -- Longer search
            cooldown = 600000, -- 10 minutes

            lootChances = {
                { pool = 'nothing',     chance = 15 },
                { pool = 'hardware',    chance = 25 },
                { pool = 'electronics', chance = 25 },
                { pool = 'blueprints',  chance = 15 }, -- Best odds for blueprints!
                { pool = 'garbage',     chance = 20 },
            },
        },
    },

    -- ==========================================
    -- RARE MATERIAL POOLS (Remote Locations)
    -- ==========================================
    rare_materials = {
        -- High Tech / Military (Humane Labs, Fort Zancudo nearby)
        high_tech = {
            { name = 'carbon_fiber',             weight = 30, count = { min = 1, max = 2 } },
            { name = 'titanium_alloy',           weight = 20, count = { min = 1, max = 1 } },
            { name = 'advanced_circuit',         weight = 15, count = { min = 1, max = 1 } },
            { name = 'blueprint_hacking_device', weight = 10, count = { min = 1, max = 1 } },
            { name = 'infernal_dust',            weight = 5,  count = { min = 1, max = 3 } }, -- New: Explosive residue
        },

        -- Mystical / Ancient (Mt Chiliad, Altruist Camp)
        mystical = {
            { name = 'arcane_dust',              weight = 40, count = { min = 1, max = 3 } },
            { name = 'rune_core',                weight = 20, count = { min = 1, max = 1 } },
            { name = 'onyx',                     weight = 10, count = { min = 1, max = 1 } },
            { name = 'shadow_silk',              weight = 10, count = { min = 1, max = 3 } }, -- New: Mystical fabric
            { name = 'blueprint_revive_crystal', weight = 5,  count = { min = 1, max = 1 } },
        }
    },

    -- ==========================================
    -- SEARCHABLE LOCATIONS
    -- ==========================================


    -- ==========================================
    -- REMOTE ZONES (The "hard to get" places)
    -- ==========================================
    zones = {
        -- Humane Labs Areas (High Tech Scavenging)
        humane_labs_industrial = {
            coords = vec3(3538.0, 3669.0, 28.0), -- Chemical tanks area
            radius = 60.0,
            lootType = 'high_tech',
            targetModels = { 'prop_tank_types01a', 'prop_ind_flu_tank_01', 'prop_box_ammo04a', 'prop_crate_01a' },
            label = 'Search Chemical Tank',
            animation = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', anim = 'machinic_loop_mechandplayer' },
            cooldown = 600000, -- 10 mins
        },

        -- Mt Chiliad Summit / Mystery Area (Mystical Scavenging)
        chiliad_ruins = {
            coords = vec3(501.5, 5597.0, 796.0), -- Near the mural/viewpoint
            radius = 100.0,
            lootType = 'mystical',
            targetModels = { 'prop_rock_1_a', 'prop_rock_1_b', 'prop_gravestones_01a', 'prop_idol_case_01' }, -- Searching specific rocks/ruins
            label = 'Search Ancient Ruins',
            animation = { dict = 'amb@medic@standing@kneel@base', anim = 'base' },
            cooldown = 900000, -- 15 mins
        },

        -- Altruist Camp (Cultist / Mystical)
        altruist_camp = {
            coords = vec3(-1170.0, 4926.0, 224.0),
            radius = 80.0,
            lootType = 'mystical',
            targetModels = { 'prop_box_wood02a', 'prop_crate_01a', 'prop_skull_01', 'prop_barrow_01a' },
            label = 'Search Cultist Supplies',
            animation = { dict = 'missexile3', anim = 'ex03_dingy_search_case_base_michael' },
            cooldown = 600000,
        },

        -- Prison Perimeter (Restricted / High Risk)
        -- Outside the main yard, near admin/watchtowers
        prison_perimeter = {
            coords = vec3(1845.0, 2585.0, 46.0), -- Near the visitor/admin parking entrance
            radius = 70.0,
            lootType = 'high_tech',              -- Good place for security manuals/parts
            targetModels = { 'prop_box_ammo04a', 'prop_crate_01a', 'prop_security_case_01' },
            label = 'Search Security Supplies',
            animation = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', anim = 'machinic_loop_mechandplayer' },
            cooldown = 900000,
        }
    },

    -- ==========================================
    -- GLOBAL SETTINGS
    -- ==========================================
    settings = {
        -- Police alert settings (80% chance to alert when scavenging)
        policeAlertChance = 80,
        minCopsForAlert = 0, -- Set to 0 to always alert

        -- Notification messages
        messages = {
            nothing = 'You found nothing useful...',
            searching = 'Searching...',
            cooldown = 'This location was recently searched.',
            found = 'You found: %s x%d',
            blueprint = '🎉 RARE FIND! You discovered: %s',
            policeAlert = 'Someone may have seen you...',
        },

        -- Experience for searching
        searchXP = 5,
        blueprintBonusXP = 50,
        rareMaterialBonusXP = 20,

        -- Search distance
        maxDistance = 2.3,
    },
}
