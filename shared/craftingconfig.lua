-- Crafting System Configuration
-- Customize crafting behavior, animations, and UI options

return {
    -- ==========================================
    -- WORKBENCH OPTIONS
    -- ==========================================
    workbench = {
        -- Default prop model for crafting benches (can be overridden per-bench)
        -- Using custom forge model from stream/ folder
        defaultModel = 'forge',

        -- Spawn workbench props at zone locations
        spawnProps = true,

        -- Height offset for prop placement (negative = lower)
        propHeightOffset = -1.0,

        -- Freeze props in place
        freezeProps = true,
    },

    -- ==========================================
    -- CRAFTING ANIMATIONS
    -- ==========================================
    animation = {
        -- Enable crafting animations
        enabled = true,

        -- Animation dictionary and clip
        dict = 'mini@repair',
        anim = 'fixing_a_ped',

        -- Animation flags (49 = upper body, looped)
        flags = 49,

        -- Prop to attach during crafting (false to disable)
        prop = {
            enabled = true,
            model = 'prop_tool_hammer',
            bone = 57005, -- Right hand
            offset = vec3(0.10, 0.02, -0.04),
            rotation = vec3(-100.0, 0.0, 0.0),
        },
    },

    -- ==========================================
    -- PROGRESS BAR (lib.progressBar)
    -- ==========================================
    progressBar = {
        -- Use ox_lib progress bar
        enabled = true,

        -- Position on screen ('bottom', 'middle', 'top')
        position = 'bottom',

        -- Show cancel instruction
        canCancel = true,

        -- Disable controls during crafting
        disable = {
            move = true,
            car = true,
            combat = true,
        },
    },

    -- ==========================================
    -- XP & LEVELING
    -- ==========================================
    xp = {
        -- Enable XP system
        enabled = true,

        -- XP required per level (can be a number or function)
        -- Formula: baseXP * (level ^ multiplier)
        baseXP = 100,
        multiplier = 1.5,

        -- Max crafting level
        maxLevel = 50,

        -- Show XP gain notifications
        showNotifications = true,

        -- Bonus XP for first craft of an item
        firstCraftBonus = 50,

        -- Rank icons for leveling display (hosted on imgbb)
        rankIcons = {
            [1] = 'https://i.ibb.co/7ds51BSg/diamond-amethyst-1.png',
            [2] = 'https://i.ibb.co/S4PQWBVD/diamond-amethyst-2.png',
            [3] = 'https://i.ibb.co/TBRqR3bn/diamond-amethyst-3.png',
            [4] = 'https://i.ibb.co/kstJ5LcD/diamond-amethyst-4.png',
            [5] = 'https://i.ibb.co/FLqsSgdw/diamond-amethyst-5.png',
            [6] = 'https://i.ibb.co/rRLFGp7X/diamond-amethyst-6.png',
            [7] = 'https://i.ibb.co/bgb29L8N/diamond-amethyst-7.png',
            [8] = 'https://i.ibb.co/JWG2N7DM/diamond-amethyst-8.png',
            [9] = 'https://i.ibb.co/FbLSVRbb/diamond-amethyst-9.png',
            [10] = 'https://i.ibb.co/cKHKZh3M/diamond-amethyst-10.png',
            [11] = 'https://i.ibb.co/Q3vwWpwv/diamond-amethyst-11.png',
            [12] = 'https://i.ibb.co/sSJVjLB/diamond-amethyst-12.png',
        },
    },

    -- ==========================================
    -- BLUEPRINTS
    -- ==========================================
    blueprints = {
        -- Require blueprints for non-basic recipes
        required = true,

        -- Remove blueprint item after learning (false = keep item)
        consumeOnLearn = true,

        -- Time to learn a blueprint (ms)
        learnTime = 2000,

        -- Notification when learning
        learnNotification = true,
    },

    -- ==========================================
    -- UI OPTIONS
    -- ==========================================
    ui = {
        -- Show tier colors in crafting UI
        tierColors = {
            basic = '#4CAF50',     -- Green
            advanced = '#2196F3',  -- Blue
            master = '#F44336',    -- Red
            legendary = '#FFD700', -- Gold
        },

        -- Show item requirements in tooltip
        showRequirements = true,

        -- Show XP reward in recipe tooltip
        showXPReward = true,

        -- Shift to reveal detailed info
        shiftToReveal = true,
    },

    -- ==========================================
    -- SOUNDS
    -- ==========================================
    sounds = {
        -- Enable crafting sounds
        enabled = true,

        -- Sound when crafting starts
        craftStart = {
            name = 'Hack_Loop',
            set = 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS',
        },

        -- Sound when crafting completes
        craftComplete = {
            name = 'PICKUP_WEAPON_SMOKEGRENADE',
            set = 'HUD_FRONTEND_WEAPONS_PICKUPS_SOUNDSET',
        },

        -- Sound when learning blueprint
        learnBlueprint = {
            name = 'CHALLENGE_UNLOCKED',
            set = 'HUD_AWARDS',
        },
    },

    -- ==========================================
    -- BLIPS
    -- ==========================================
    blips = {
        -- Show blips for crafting benches
        enabled = true,

        -- Default blip settings (can be overridden per-bench)
        default = {
            sprite = 566,
            color = 31,
            scale = 0.8,
            shortRange = true,
        },
    },
}
