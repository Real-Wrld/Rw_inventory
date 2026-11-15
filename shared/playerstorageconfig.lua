-- Player Storage System Configuration
-- Customize player-owned stashes, safes, and storage placement

return {
    -- ==========================================
    -- STASH TYPES & PRICING
    -- ==========================================
    stashTypes = {
        small = {
            label = 'Small Safe',
            model = 'p_v_43_safe_s',
            slots = 50,
            maxWeight = 100000, -- 100kg
            price = 50000,      -- $50,000
            description = 'A compact safe for basic storage.',
        },
        medium = {
            label = 'Medium Safe',
            model = 'prop_ld_int_safe_01',
            slots = 100,
            maxWeight = 250000, -- 250kg
            price = 150000,     -- $150,000
            description = 'A larger safe with more capacity.',
        },
        large = {
            label = 'Large Vault',
            model = 'prop_ld_bank_vaultsml',
            slots = 200,
            maxWeight = 500000, -- 500kg
            price = 500000,     -- $500,000
            description = 'A massive vault for serious storage.',
        },
    },

    -- ==========================================
    -- PLACEMENT OPTIONS
    -- ==========================================
    placement = {
        -- Use object_gizmo for placement (if available)
        useGizmo = true,

        -- Max placement distance from player
        maxDistance = 5.0,

        -- Allow rotation during placement
        allowRotation = true,

        -- Placement preview color (RGBA)
        previewColor = { 100, 200, 100, 150 },

        -- Cancel placement color (RGBA)
        cancelColor = { 200, 100, 100, 150 },

        -- Sound when placing
        placeSound = true,
    },

    -- ==========================================
    -- OWNERSHIP & PERMISSIONS
    -- ==========================================
    ownership = {
        -- Max stashes per player (0 = unlimited)
        maxStashesPerPlayer = 5,

        -- Allow sharing with other players
        allowSharing = false,

        -- Allow gang/job shared stashes
        allowGroupStashes = false,
    },

    -- ==========================================
    -- INTERACTION OPTIONS
    -- ==========================================
    interaction = {
        -- Use ox_target for stash interaction
        useTarget = true,

        -- Interaction distance
        distance = 2.0,

        -- Icon for target interaction
        icon = 'fas fa-lock',

        -- Open animation
        openAnimation = {
            enabled = true,
            dict = 'missheistdockssetup1clipboard@base',
            anim = 'base',
            duration = 1000,
        },
    },

    -- ==========================================
    -- SECURITY OPTIONS
    -- ==========================================
    security = {
        -- Require item to open stash (false = no item needed)
        requireKey = false,
        keyItem = 'stash_key',

        -- Lock timeout after failed attempts (minutes)
        lockoutTime = 5,
        maxFailedAttempts = 3,

        -- Allow stash destruction/removal
        allowDestruction = true,
        destructionRequiresItem = true,
        destructionItem = 'thermite',
    },

    -- ==========================================
    -- PERSISTENCE
    -- ==========================================
    database = {
        -- Table name for stash data
        tableName = 'ox_inventory_stashes',

        -- Save stash contents on change (vs periodic save)
        saveOnChange = true,

        -- Periodic save interval (ms) if saveOnChange is false
        saveInterval = 60000,
    },

    -- ==========================================
    -- UI OPTIONS
    -- ==========================================
    ui = {
        -- Show stash type icon
        showTypeIcon = true,

        -- Show capacity bar
        showCapacityBar = true,

        -- Shop UI title
        shopTitle = 'Safe Emporium',

        -- Show prices in shop
        showPrices = true,
    },

    -- ==========================================
    -- BLIPS
    -- ==========================================
    blips = {
        -- Show blips for owned stashes
        showOwned = true,

        -- Blip sprite for owned stashes
        sprite = 478,
        color = 2,
        scale = 0.6,
        shortRange = true,

        -- Only show on minimap when nearby
        shortRangeDistance = 100.0,
    },

    -- ==========================================
    -- SOUNDS
    -- ==========================================
    sounds = {
        -- Enable interaction sounds
        enabled = true,

        open = {
            name = 'PIN_BUTTON',
            set = 'ATM_SOUNDS',
        },

        close = {
            name = 'BACK',
            set = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
        },

        place = {
            name = 'PLACED_PROP_PICKUP',
            set = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
        },
    },

    -- ==========================================
    -- DEBUG
    -- ==========================================
    debug = {
        -- Enable debug logging
        enabled = false,

        -- Show placement zones
        showZones = false,
    },
}
