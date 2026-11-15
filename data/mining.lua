return {
    -- Targetable rock models for ox_target
    models = {
        'prop_rock_1_a',
        'prop_rock_1_b',
        'prop_rock_1_c',
        'prop_rock_1_d',
        'cs_x_rubble',
        'prop_asteroid_01',
        'prop_rock_5_smash1'
    },

    -- Mining Locations / Zones
    zones = {
        {
            name = 'davis_quarry',
            coords = vec3(2953.0, 2788.0, 41.0),
            radius = 150.0,
            label = 'Davis Quartz Quarry',
            blip = { id = 618, colour = 5, scale = 0.8, label = 'Mining Zone' }
        },
        {
            name = 'grand_senora_mining',
            coords = vec3(269.0, 2901.0, 40.0), -- Approximate desert mining area
            radius = 100.0,
            label = 'Desert Mining',
        }
    },

    -- Loot Table
    -- Chance is out of 100
    -- Min/Max is quantity
    rewards = {
        common = {
            stone = { chance = 100, min = 1, max = 3 },
            iron = { chance = 60, min = 1, max = 2 },
        },
        rare = {
            mithril_ore = { chance = 30, min = 1, max = 2 },
            titanium_alloy = { chance = 25, min = 1, max = 2 },
            cobalt_ore = { chance = 20, min = 1, max = 2 }, -- New
            gold = { chance = 15, min = 1, max = 1 },
        },
        gems = {
            amethyst = { chance = 8, min = 1, max = 1 },
            ruby = { chance = 5, min = 1, max = 1 },
            sapphire = { chance = 5, min = 1, max = 1 },
            emerald = { chance = 3, min = 1, max = 1 },
            diamond = { chance = 1, min = 1, max = 1 },
        },
        legendary = { -- New Tier
            adamantite_ore = { chance = 2, min = 1, max = 1 },
            runite_ore = { chance = 0.5, min = 1, max = 1 },
        }
    },

    -- Mining Settings
    duration = 5000,                   -- ms
    animDict = 'melee@hatchet@streamed_core',
    animName = 'plyr_rear_takedown_b', -- A swinging animation
    prop = 'prop_tool_pickaxe',
}
