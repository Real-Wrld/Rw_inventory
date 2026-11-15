-- Store Theft Configuration
-- Defines theft locations, loot pools, and dispatch settings

return {
    -- ==========================================
    -- CONFIGURATION
    -- ==========================================
    settings = {
        -- Theft duration (how long to search/steal)
        duration = 8000, -- 8 seconds

        -- Cooldown per location (milliseconds)
        cooldown = 600000, -- 10 minutes

        -- Global cooldown between any theft (prevent spamming)
        globalCooldown = 120000, -- 2 minutes

        -- Chance to trigger police alert (0-100)
        policeAlertChance = 80, -- 80% chance to alert police

        -- Required cops online for large-scale alerts
        minCopsForAlert = 0, -- Set to 0 to always alert (or 1-2 for balance)

        -- XP rewards
        searchXP = 5,
        blueprintBonusXP = 50,

        -- Animation (searching through electronics/displays)
        animation = {
            dict = 'anim@gangops@facility@servers@bodysearch@',
            anim = 'player_search',
        },

        -- Messages (no thief-facing "cops notified" text — alerts go to dispatch only)
        messages = {
            stealing = 'Searching through merchandise...',
            found = 'Found %dx %s',
            blueprint = '🎉 Found a Blueprint: %s!',
            nothing = 'Nothing useful here...',
            cooldown = 'This area has been recently searched',
        },
    },

    -- ==========================================
    -- LOOT POOLS FOR STORE THEFT
    -- ==========================================
    pools = {
        -- General Store items (common goods)
        general_store = {
            { name = 'water',     weight = 25, count = { min = 1, max = 3 } },
            { name = 'burger',    weight = 20, count = { min = 1, max = 2 } },
            { name = 'donut',     weight = 15, count = { min = 1, max = 3 } },
            { name = 'coffee',    weight = 15, count = { min = 1, max = 2 } },
            { name = 'bandage',   weight = 10, count = { min = 1, max = 2 } },
            { name = 'cigarette', weight = 8,  count = { min = 1, max = 5 } },
            { name = 'lighter',   weight = 5,  count = { min = 1, max = 1 } },
            { name = 'cloth',     weight = 2,  count = { min = 1, max = 2 } },
        },

        -- Digital Den items (electronics/tech)
        digital_den = {
            { name = 'phone',       weight = 20, count = { min = 1, max = 1 } },
            { name = 'electronics', weight = 25, count = { min = 1, max = 3 } },
            { name = 'radio',       weight = 35, count = { min = 1, max = 1 } },
            { name = 'flashlight',  weight = 55, count = { min = 1, max = 1 } },
            { name = 'binoculars',  weight = 70, count = { min = 1, max = 1 } },
            { name = 'copper',      weight = 60,  count = { min = 1, max = 3 } },
            { name = 'glass',       weight = 5,  count = { min = 1, max = 2 } },
            { name = 'sapphire',    weight = 40,  count = { min = 1, max = 1 } },
        },

        -- Junk pool (common trash)
        junk = {
            { name = 'trash',      weight = 35, count = { min = 1, max = 2 } },
            { name = 'plastic',    weight = 25, count = { min = 1, max = 3 } },
            { name = 'paper',      weight = 20, count = { min = 1, max = 5 } },
            { name = 'scrapmetal', weight = 15, count = { min = 1, max = 2 } },
            { name = 'glass',      weight = 5,  count = { min = 1, max = 2 } },
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

        -- Blueprint pool (RARE) - same as scavenging
        blueprints = {
            -- Advanced blueprints
            { name = 'blueprint_advanced_lockpick', weight = 25, count = { min = 1, max = 1 } },
            { name = 'blueprint_advanced_radio',    weight = 20, count = { min = 1, max = 1 } },
            { name = 'blueprint_advancedrepairkit', weight = 20, count = { min = 1, max = 1 } },
            { name = 'blueprint_advanced_armor',    weight = 15, count = { min = 1, max = 1 } },
            { name = 'blueprint_nightvision',       weight = 10, count = { min = 1, max = 1 } },
            { name = 'blueprint_thermite',          weight = 5,  count = { min = 1, max = 1 } },
            -- Master blueprints (rare)
            { name = 'blueprint_master_lockpick',   weight = 3,  count = { min = 1, max = 1 } },
            { name = 'blueprint_master_medkit',     weight = 2,  count = { min = 1, max = 1 } },
            -- Khan futuristic weapon blueprints (theft slightly better than scavenging)
            { name = 'blueprint_WEAPON_ascia',      weight = 1.5, count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_motosega',   weight = 0.9, count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_SARATOGA',   weight = 0.7, count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_carnage',    weight = 0.55, count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_skippy',     weight = 0.3, count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_silverhand', weight = 0.15, count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_MASAMUNE',   weight = 0.12, count = { min = 1, max = 1 } },
            { name = 'blueprint_WEAPON_NEKOMATA',   weight = 0.05, count = { min = 1, max = 1 } },
        },

        -- Xero Gas items (similar to general store)
        xero_gas = {
            { name = 'water',     weight = 25, count = { min = 1, max = 3 } },
            { name = 'cola',      weight = 20, count = { min = 1, max = 3 } },
            { name = 'burger',    weight = 15, count = { min = 1, max = 2 } },
            { name = 'cigarette', weight = 10, count = { min = 1, max = 5 } },
            { name = 'lighter',   weight = 5,  count = { min = 1, max = 1 } },
            { name = 'jerrycan',  weight = 5,  count = { min = 1, max = 1 } }, -- Added jerrycan for gas station theme
        },

        -- Davis supermarket aisle pools (per-rack)
        supermarket_food = {
            { name = 'water',       weight = 22, count = { min = 1, max = 3 } },
            { name = 'cola',        weight = 18, count = { min = 1, max = 2 } },
            { name = 'burger',      weight = 16, count = { min = 1, max = 2 } },
            { name = 'sandwich',    weight = 14, count = { min = 1, max = 2 } },
            { name = 'donut',       weight = 12, count = { min = 1, max = 3 } },
            { name = 'coffee',      weight = 10, count = { min = 1, max = 2 } },
            { name = 'fresh_apple', weight = 8,  count = { min = 1, max = 3 } },
            { name = 'lettuce',     weight = 6,  count = { min = 1, max = 2 } },
            { name = 'tomato',      weight = 6,  count = { min = 1, max = 2 } },
            { name = 'milk',        weight = 5,  count = { min = 1, max = 1 } },
        },

        supermarket_electronics = {
            { name = 'electronics', weight = 28, count = { min = 1, max = 3 } },
            { name = 'phone',       weight = 18, count = { min = 1, max = 1 } },
            { name = 'radio',       weight = 16, count = { min = 1, max = 1 } },
            { name = 'flashlight',  weight = 14, count = { min = 1, max = 1 } },
            { name = 'binoculars',  weight = 10, count = { min = 1, max = 1 } },
            { name = 'copper',      weight = 10, count = { min = 1, max = 3 } },
            { name = 'glass',       weight = 4,  count = { min = 1, max = 2 } },
        },

        supermarket_farming = {
            { name = 'trowel',        weight = 22, count = { min = 1, max = 1 } },
            { name = 'plant_spray',   weight = 18, count = { min = 1, max = 2 } },
            { name = 'carrot_seeds',  weight = 16, count = { min = 1, max = 3 } },
            { name = 'potato_seeds',  weight = 16, count = { min = 1, max = 3 } },
            { name = 'weed_seed',     weight = 8,  count = { min = 1, max = 2 } },
            { name = 'fresh_apple',   weight = 10, count = { min = 1, max = 2 } },
            { name = 'plastic_bag',   weight = 10, count = { min = 1, max = 3 } },
        },

        supermarket_pharma = {
            { name = 'bandage',     weight = 30, count = { min = 1, max = 3 } },
            { name = 'painkillers', weight = 25, count = { min = 1, max = 2 } },
            { name = 'firstaid',    weight = 12, count = { min = 1, max = 1 } },
            { name = 'cloth',       weight = 15, count = { min = 1, max = 2 } },
            { name = 'syringe',     weight = 8,  count = { min = 1, max = 1 } },
            { name = 'water',       weight = 10, count = { min = 1, max = 2 } },
        },
    },

    -- ==========================================
    -- GENERAL STORE LOCATIONS
    -- Relative offsets from store center
    -- ==========================================
    general_store = {
        -- All 24/7 convenience store locations
        locations = {
            -- Strawberry (near user's coords)
            { center = vector3(25.0, -1347.0, 29.5),   name = 'Strawberry 24/7' },
            -- Other 24/7 stores (add more as needed)
            { center = vector3(1960.0, 3740.0, 32.0),  name = 'Sandy Shores 24/7' },
            { center = vector3(549.0, 2670.0, 42.0),   name = 'Harmony 24/7' },
            { center = vector3(2678.0, 3280.0, 55.0),  name = 'Route 68 24/7' },
            { center = vector3(1729.0, 6414.0, 35.0),  name = 'Paleto Bay 24/7' },
            { center = vector3(-47.0, -1757.0, 29.0),  name = 'Davis Ave 24/7' },
            { center = vector3(-706.0, -913.0, 19.0),  name = 'Little Seoul 24/7' },
            { center = vector3(-1820.0, 794.0, 138.0), name = 'Richman 24/7' },
            { center = vector3(1165.0, -323.0, 69.0),  name = 'Mirror Park 24/7' },
            { center = vector3(373.0, 325.0, 103.0),   name = 'Downtown Vinewood 24/7' },
            { center = vector3(1134.0, -982.0, 46.0),  name = 'Murrieta Heights LTD' },
            { center = vector3(-1222.0, -906.0, 12.0), name = 'Vespucci LTD' },
            { center = vector3(-1487.0, -379.0, 40.0), name = 'Morningwood Rob\'s' },
            { center = vector3(-2966.0, 391.0, 15.0),  name = 'Chumash 24/7' },
            { center = vector3(1698.0, 4923.0, 42.0),  name = 'Grapeseed 24/7' },
        },

        -- Theft zones relative to each store (offsets from center)
        -- These are designed for the standard 24/7 store model
        zones = {
            {
                offset = vector3(0.0, 0.0, 0.0), -- Counter area (near register)
                heading = 0.0,
                label = 'Search Behind Counter',
                icon = 'fas fa-cash-register',
                size = vector3(3.0, 2.0, 2.0),
            },
            {
                offset = vector3(-2.0, 2.0, 0.0), -- Left side shelves
                heading = 0.0,
                label = 'Search Shelves',
                icon = 'fas fa-boxes-stacked',
                size = vector3(3.0, 3.0, 2.0),
            },
            {
                offset = vector3(2.0, 2.0, 0.0), -- Right side shelves
                heading = 0.0,
                label = 'Search Display Rack',
                icon = 'fas fa-store',
                size = vector3(3.0, 3.0, 2.0),
            },
            {
                offset = vector3(0.0, -3.0, 0.0), -- Refrigerators/coolers
                heading = 0.0,
                label = 'Search Coolers',
                icon = 'fas fa-snowflake',
                size = vector3(4.0, 2.0, 2.0),
            },
            {
                offset = vector3(8.79, 1.76, -1.0), -- Front entrance area
                heading = 262.9,
                label = 'Search Entrance Display',
                icon = 'fas fa-door-open',
                size = vector3(3.0, 3.0, 2.0),
            },
        },

        -- Loot chances for general stores
        lootChances = {
            { pool = 'nothing',       chance = 20 }, -- 20% nothing
            { pool = 'other',       chance = 25 }, -- 25% other
            { pool = 'junk',          chance = 30 }, -- 30% junk
            { pool = 'general_store', chance = 40 }, -- 40% store items
            { pool = 'blueprints',    chance = 5 },  -- 5% blueprints (lucky!)
        },

        -- Police dispatch settings
        dispatch = {
            code = '10-31', -- Robbery in progress
            message = 'Store Theft in Progress',
            description = 'A Store has triggered their alarm!',
            blipSprite = 431,
            blipColor = 1,
            blipScale = 1.0,
            radius = 30.0, -- Radius for officer to respond
        },
    },

    -- ==========================================
    -- DIGITAL DEN LOCATIONS
    -- ==========================================
    digital_den = {
        locations = {
            -- Main Digital Den location (user's coords)
            { center = vector3(240.0, -1489.0, 29.29), name = 'Digital Den Davis' },
            -- Add more DigitalDen locations if they exist
        },

        -- Theft zones for DigitalDen (centered around store)
        zones = {
            {
                offset = vector3(0.0, 0.0, 0.0), -- Main counter
                heading = 0.0,
                label = 'Search Electronics Counter',
                icon = 'fas fa-desktop',
                size = vector3(3.0, 2.0, 2.0),
            },
            {
                offset = vector3(-2.0, 2.0, 0.0), -- Left display
                heading = 0.0,
                label = 'Search Phone Display',
                icon = 'fas fa-mobile-alt',
                size = vector3(3.0, 3.0, 2.0),
            },
            {
                offset = vector3(2.0, 2.0, 0.0), -- Right display
                heading = 0.0,
                label = 'Search Gaming Section',
                icon = 'fas fa-gamepad',
                size = vector3(3.0, 3.0, 2.0),
            },
            {
                offset = vector3(0.0, -2.0, 0.0), -- Back storage
                heading = 0.0,
                label = 'Search Storage Room',
                icon = 'fas fa-warehouse',
                size = vector3(4.0, 2.0, 2.0),
            },
            -- User-specified coordinates (calculated as offsets from center 240.0, -1489.0, 29.29)
            {
                offset = vector3(4.34, 2.46, -1.0), -- vec4(244.34, -1486.54, 28.29, 312.23)
                heading = 312.23,
                label = 'Search Laptop Display',
                icon = 'fas fa-laptop',
                size = vector3(3.0, 2.0, 2.0),
            },
            {
                offset = vector3(-2.83, -4.3, -1.0), -- vec4(237.17, -1493.3, 28.29, 131.82)
                heading = 131.82,
                label = 'Search Accessory Rack',
                icon = 'fas fa-headphones',
                size = vector3(3.0, 2.0, 2.0),
            },
            {
                offset = vector3(-6.27, -0.6, -1.0), -- vec4(233.73, -1489.6, 28.29, 133.51)
                heading = 133.51,
                label = 'Search Tablet Stand',
                icon = 'fas fa-tablet-alt',
                size = vector3(3.0, 2.0, 2.0),
            },
            {
                offset = vector3(0.77, 6.18, -1.0), -- vec4(240.77, -1482.82, 28.29, 311.37)
                heading = 311.37,
                label = 'Search Speaker Wall',
                icon = 'fas fa-volume-up',
                size = vector3(3.0, 2.0, 2.0),
            },
        },

        -- Loot chances for DigitalDen (better electronics)
        lootChances = {
            { pool = 'nothing',     chance = 20 }, -- 20% nothing
            { pool = 'junk',        chance = 20 }, -- 20% junk
            { pool = 'other',        chance = 25 }, -- 25% other
            { pool = 'digital_den', chance = 50 }, -- 50% electronics
            { pool = 'blueprints',  chance = 8 },  -- 8% blueprints (better odds for tech!)
        },

        -- Police dispatch settings
        dispatch = {
            code = '10-31', -- Robbery in progress
            message = 'Electronics Store Robbery',
            description = 'An alarm has been triggered from Digital Den!',
            blipSprite = 521, -- Computer/tech icon
            blipColor = 1,
            blipScale = 1.0,
            radius = 30.0,
        },
    },

    -- ==========================================
    -- XERO GAS STATION LOCATIONS
    -- ==========================================
    xero_gas = {
        locations = {
            -- Pacific Bluffs Xero Gas (Base location for calculations)
            { center = vector3(-2060.0, -320.0, 13.0), name = 'Pacific Bluffs Xero' },
            -- Add other Xero Gas stations here (just need their center coord)
        },

        zones = {
            {
                offset = vector3(-8.89, -6.24, 0.74), -- vec4(-2068.89, -326.24, 13.74, 171.37)
                heading = 171.37,
                label = 'Search Shelf',
                icon = 'fas fa-box-open',
                size = vector3(2.0, 1.0, 2.0),
            },
            {
                offset = vector3(-5.98, -5.63, 0.47), -- vec4(-2065.98, -325.63, 13.47, 176.77)
                heading = 176.77,
                label = 'Search Food Shelf',
                icon = 'fas fa-utensils',
                size = vector3(2.0, 1.0, 2.0),
            },
            {
                offset = vector3(-8.49, -12.08, 0.29), -- vec4(-2068.49, -332.08, 13.29, 84.17)
                heading = 84.17,
                label = 'Search Condiments',
                icon = 'fas fa-bottle-droplet',
                size = vector3(1.5, 1.0, 2.0),
            },
            {
                offset = vector3(1.2, 2.46, 0.72), -- vec4(-2058.8, -317.54, 13.72, 339.13)
                heading = 339.13,
                label = 'Search Safe',
                icon = 'fas fa-vault',
                size = vector3(1.0, 1.0, 1.5),
            },
        },

        lootChances = {
            { pool = 'nothing',    chance = 20 },
            { pool = 'junk',       chance = 25 },
            { pool = 'other',       chance = 30 },
            { pool = 'xero_gas',   chance = 40 },
            { pool = 'blueprints', chance = 5 },
        },

        dispatch = {
            code = '10-31',
            message = 'Gas Station Robbery',
            description = 'A suspect is stealing from a gas station!',
            blipSprite = 361, -- Jerry can icon
            blipColor = 1,
            blipScale = 1.0,
            radius = 30.0,
        },
    },

    -- ==========================================
    -- DAVIS SUPERMARKET (absolute rack coords)
    -- Zones may set `coords` + per-rack `lootChances`.
    -- ==========================================
    supermarket = {
        locations = {
            { center = vector3(65.0, -1778.0, 29.5), name = 'Davis Supermarket' },
        },

        zones = {
            -- Food racks
            {
                coords = vector3(58.63, -1771.48, 29.31),
                heading = 138.90,
                label = 'Search Food Rack',
                icon = 'fas fa-shopping-basket',
                size = vector3(1.8, 1.4, 2.2),
                lootChances = {
                    { pool = 'nothing',          chance = 15 },
                    { pool = 'junk',             chance = 15 },
                    { pool = 'supermarket_food', chance = 60 },
                    { pool = 'blueprints',       chance = 5 },
                    { pool = 'other',            chance = 5 },
                },
            },
            {
                coords = vector3(54.38, -1774.83, 29.31),
                heading = 323.15,
                label = 'Search Food Rack',
                icon = 'fas fa-shopping-basket',
                size = vector3(1.8, 1.4, 2.2),
                lootChances = {
                    { pool = 'nothing',          chance = 15 },
                    { pool = 'junk',             chance = 15 },
                    { pool = 'supermarket_food', chance = 60 },
                    { pool = 'blueprints',       chance = 5 },
                    { pool = 'other',            chance = 5 },
                },
            },
            {
                coords = vector3(51.32, -1777.45, 29.31),
                heading = 311.81,
                label = 'Search Food Rack',
                icon = 'fas fa-shopping-basket',
                size = vector3(1.8, 1.4, 2.2),
                lootChances = {
                    { pool = 'nothing',          chance = 15 },
                    { pool = 'junk',             chance = 15 },
                    { pool = 'supermarket_food', chance = 60 },
                    { pool = 'blueprints',       chance = 5 },
                    { pool = 'other',            chance = 5 },
                },
            },
            {
                coords = vector3(69.80, -1771.36, 29.31),
                heading = 150.24,
                label = 'Search Food Rack',
                icon = 'fas fa-shopping-basket',
                size = vector3(1.8, 1.4, 2.2),
                lootChances = {
                    { pool = 'nothing',          chance = 15 },
                    { pool = 'junk',             chance = 15 },
                    { pool = 'supermarket_food', chance = 60 },
                    { pool = 'blueprints',       chance = 5 },
                    { pool = 'other',            chance = 5 },
                },
            },

            -- Electronics stands
            {
                coords = vector3(81.38, -1779.73, 29.35),
                heading = 240.94,
                label = 'Search Electronics Stand',
                icon = 'fas fa-microchip',
                size = vector3(1.8, 1.4, 2.2),
                lootChances = {
                    { pool = 'nothing',                 chance = 15 },
                    { pool = 'junk',                    chance = 15 },
                    { pool = 'supermarket_electronics', chance = 55 },
                    { pool = 'blueprints',              chance = 8 },
                    { pool = 'other',                   chance = 7 },
                },
            },
            {
                coords = vector3(79.11, -1777.66, 29.35),
                heading = 243.78,
                label = 'Search Electronics Stand',
                icon = 'fas fa-microchip',
                size = vector3(1.8, 1.4, 2.2),
                lootChances = {
                    { pool = 'nothing',                 chance = 15 },
                    { pool = 'junk',                    chance = 15 },
                    { pool = 'supermarket_electronics', chance = 55 },
                    { pool = 'blueprints',              chance = 8 },
                    { pool = 'other',                   chance = 7 },
                },
            },

            -- Farming equipment
            {
                coords = vector3(77.45, -1787.82, 29.99),
                heading = 56.69,
                label = 'Search Farming Equipment',
                icon = 'fas fa-seedling',
                size = vector3(2.0, 1.6, 2.2),
                lootChances = {
                    { pool = 'nothing',             chance = 15 },
                    { pool = 'junk',                chance = 15 },
                    { pool = 'supermarket_farming', chance = 55 },
                    { pool = 'blueprints',          chance = 7 },
                    { pool = 'other',               chance = 8 },
                },
            },

            -- Pharmaceuticals
            {
                coords = vector3(68.18, -1784.90, 30.83),
                heading = 232.44,
                label = 'Search Pharmaceuticals Stand',
                icon = 'fas fa-pills',
                size = vector3(1.8, 1.4, 2.2),
                lootChances = {
                    { pool = 'nothing',            chance = 15 },
                    { pool = 'junk',               chance = 10 },
                    { pool = 'supermarket_pharma', chance = 60 },
                    { pool = 'blueprints',         chance = 7 },
                    { pool = 'other',              chance = 8 },
                },
            },
            {
                coords = vector3(70.98, -1781.54, 30.83),
                heading = 232.44,
                label = 'Search Pharmaceuticals Stand',
                icon = 'fas fa-pills',
                size = vector3(1.8, 1.4, 2.2),
                lootChances = {
                    { pool = 'nothing',            chance = 15 },
                    { pool = 'junk',               chance = 10 },
                    { pool = 'supermarket_pharma', chance = 60 },
                    { pool = 'blueprints',         chance = 7 },
                    { pool = 'other',              chance = 8 },
                },
            },
            {
                coords = vector3(74.19, -1777.73, 30.83),
                heading = 232.44,
                label = 'Search Pharmaceuticals Stand',
                icon = 'fas fa-pills',
                size = vector3(1.8, 1.4, 2.2),
                lootChances = {
                    { pool = 'nothing',            chance = 15 },
                    { pool = 'junk',               chance = 10 },
                    { pool = 'supermarket_pharma', chance = 60 },
                    { pool = 'blueprints',         chance = 7 },
                    { pool = 'other',              chance = 8 },
                },
            },
        },

        -- Fallback if a zone has no lootChances
        lootChances = {
            { pool = 'nothing',          chance = 20 },
            { pool = 'junk',             chance = 20 },
            { pool = 'supermarket_food', chance = 50 },
            { pool = 'blueprints',       chance = 5 },
            { pool = 'other',            chance = 5 },
        },

        dispatch = {
            code = '10-31',
            message = 'Supermarket Theft',
            description = 'Someone is stealing merchandise from the supermarket!',
            blipSprite = 52,
            blipColor = 1,
            blipScale = 1.0,
            radius = 35.0,
        },
    },
}
