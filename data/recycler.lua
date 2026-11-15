-- Recycler configuration (ported from subtronics-recycler)
return {
    syncRecyclers = true,
    debug = false,

    dataPersistence = {
        enabled = true,
        autoSaveInterval = 30000,
        saveOnStart = true,
        saveOnComplete = true,
        saveOnCancel = true,
        saveOnPlayerDisconnect = true,
        cleanupOfflinePlayers = true,
    },

    recycleTime = 5000,
    recycleTimePerItem = 2000,
    maxRecycleTime = 30000,
    maxItemsPerRecycle = 10,
    recyclingSound = true,

    enableRecyclerAnimation = true,
    recyclerAnimation = {
        dictionary = 'clip@sm_ex_shredder',
        animation = 'shredder_movement',
        playbackRate = 1.0,
        loop = true,
    },

    useTarget = true,
    target = {
        icon = 'fas fa-recycle',
        label = 'Use Recycler',
        distance = 3.0,
    },

    enableBlips = true,
    blip = {
        sprite = 365,
        color = 25,
        scale = 0.7,
        shortRange = true,
        name = 'Recycler',
    },

    marker = {
        type = 1,
        scale = vector3(1.0, 1.0, 1.0),
        color = { r = 0, g = 255, b = 0, a = 100 },
        bobUpAndDown = false,
        faceCamera = false,
        rotate = false,
    },

    model = 'sm_ex_shredder',

    locations = {
        { id = 'recycler_1', coords = vector4(41.13, -2659.54, 11.04, 268.0), blip = true, marker = true, enabled = true },
        { id = 'recycler_2', coords = vector4(41.13, -2665.49, 11.04, 268.0), blip = false, marker = true, enabled = true },
        { id = 'recycler_3', coords = vector4(41.13, -2662.4087, 11.04, 268.0), blip = false, marker = true, enabled = true },
        { id = 'recycler_4', coords = vector4(26.50, -2659.79, 11.04, 87.0), blip = false, marker = true, enabled = true },
        { id = 'recycler_5', coords = vector4(26.50, -2662.75, 11.04, 87.0), blip = false, marker = true, enabled = true },
        { id = 'recycler_6', coords = vector4(26.50, -2665.89, 11.04, 87.0), blip = false, marker = true, enabled = true },
    },

    recipes = {

    ["sandwich"] = {
        outputs = {
            { item = "plastic", amount = { min = 1, max = 2 } },
        },
        chance = 100,
        time = 2000
    },
    ["water_bottle"] = {
        outputs = {
            { item = "plastic", amount = { min = 1, max = 2 } },
        },
        chance = 100,
        time = 2000
    },
    ["lockpick"] = {
        outputs = {
            { item = "steel", amount = { min = 1, max = 3 } },
        },
        chance = 100,
        time = 3000
    },

    ["45acp"] = {
        outputs = {
            { item = "tuning_component", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 3000
    },
    ["9x19mm"] = {
        outputs = {
            { item = "tuning_component", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 3000
    },
    ["12ga"] = {
        outputs = {
            { item = "tuning_component", amount = { min = 2, max = 2 } },
        },
        chance = 100,
        time = 3000
    },
    ["545x39"] = {
        outputs = {
            { item = "tuning_component", amount = { min = 3, max = 3 } },
        },
        chance = 100,
        time = 3000
    },
    ["556x45"] = {
        outputs = {
            { item = "tuning_component", amount = { min = 3, max = 3 } },
        },
        chance = 100,
        time = 3000
    },
    ["762x39"] = {
        outputs = {
            { item = "tuning_component", amount = { min = 4, max = 4 } },
        },
        chance = 100,
        time = 3000
    },
    ["762x54"] = {
        outputs = {
            { item = "tuning_component", amount = { min = 5, max = 5 } },
        },
        chance = 100,
        time = 3000
    },
    ["308win"] = {
        outputs = {
            { item = "tuning_component", amount = { min = 5, max = 5 } },
        },
        chance = 100,
        time = 3000
    },

    ["loot_pclean"] = {
        outputs = {
            { item = "plastic", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 2000
    },
    ["loot_raid"] = {
        outputs = {
            { item = "aluminum",        amount = { min = 1, max = 1 } },
            { item = "loot_slicontube", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 2000
    },
    ["spray"] = {
        outputs = {
            { item = "aluminum",        amount = { min = 1, max = 1 } },
            { item = "loot_slicontube", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 2000
    },
    ["loot_bleach"] = {
        outputs = {
            { item = "plastic", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 2000
    },
    ["loot_shampoo"] = {
        outputs = {
            { item = "plastic", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 2000
    },
    ["loot_tpaper"] = {
        outputs = {
            { item = "loot_cloth", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 2000
    },
    ["loot_cloth"] = {
        outputs = {
            { item = "loot_rope", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 2000
    },
    ["loot_tpaste"] = {
        outputs = {
            { item = "plastic", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 2000
    },
    ["loot_dogtag"] = {
        outputs = {
            { item = "iron", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 2000
    },
    ["tissuebox"] = {
        outputs = {
            { item = "loot_cloth", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 2000
    },

    ["loot_hdd"] = {
        outputs = {
            { item = "loot_escrap", amount = { min = 1, max = 1 } },
            { item = "steel",       amount = { min = 1, max = 1 } },
            { item = "scrap",       amount = { min = 1, max = 1 } },
            { item = "copper",      amount = { min = 1, max = 1 } },
            { item = "loot_cables", amount = { min = 1, max = 1 } },
        },
        chance = 85,
        time = 5000
    },
    ["loot_hdd2"] = {
        outputs = {
            { item = "loot_escrap", amount = { min = 1, max = 1 } },
            { item = "steel",       amount = { min = 1, max = 1 } },
            { item = "scrap",       amount = { min = 1, max = 1 } },
            { item = "copper",      amount = { min = 1, max = 1 } },
            { item = "loot_cables", amount = { min = 1, max = 1 } },
        },
        chance = 85,
        time = 5000
    },
    ["loot_magnet"] = {
        outputs = {
            { item = "steel",    amount = { min = 1, max = 1 } },
            { item = "aluminum", amount = { min = 1, max = 1 } },
            { item = "iron",     amount = { min = 1, max = 1 } },
            { item = "scrap",    amount = { min = 1, max = 1 } },
        },
        chance = 90,
        time = 4000
    },
    ["loot_ssd"] = {
        outputs = {
            { item = "plastic",     amount = { min = 1, max = 1 } },
            { item = "rubber",      amount = { min = 1, max = 1 } },
            { item = "loot_escrap", amount = { min = 1, max = 1 } },
            { item = "aluminum",    amount = { min = 1, max = 1 } },
            { item = "loot_cables", amount = { min = 1, max = 1 } },
        },
        chance = 85,
        time = 5000
    },
    ["loot_propane"] = {
        outputs = {
            { item = "scrap", amount = { min = 1, max = 1 } },
            { item = "iron",  amount = { min = 1, max = 1 } },
            { item = "steel", amount = { min = 1, max = 1 } },
        },
        chance = 90,
        time = 4000
    },
    ["loot_metalsheet"] = {
        outputs = {
            { item = "scrap", amount = { min = 1, max = 1 } },
            { item = "iron",  amount = { min = 1, max = 1 } },
            { item = "steel", amount = { min = 1, max = 1 } },
        },
        chance = 95,
        time = 4000
    },
    ["loot_cpu"] = {
        outputs = {
            { item = "loot_escrap", amount = { min = 1, max = 1 } },
            { item = "scrap",       amount = { min = 1, max = 1 } },
            { item = "aluminum",    amount = { min = 1, max = 1 } },
            { item = "copper",      amount = { min = 1, max = 1 } },
            { item = "loot_cfan",   amount = { min = 1, max = 1 } },
        },
        chance = 80,
        time = 6000
    },
    ["loot_dvd"] = {
        outputs = {
            { item = "loot_escrap",  amount = { min = 1, max = 1 } },
            { item = "scrap",        amount = { min = 1, max = 1 } },
            { item = "aluminum",     amount = { min = 1, max = 1 } },
            { item = "steel",        amount = { min = 1, max = 1 } },
            { item = "loot_adapter", amount = { min = 1, max = 1 } },
            { item = "loot_nails",   amount = { min = 1, max = 1 } },
        },
        chance = 75,
        time = 7000
    },

    ["charcoal"] = {
        outputs = {
            { item = "charcoal_powder", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 3000
    },
    ["sulfure"] = {
        outputs = {
            { item = "sulfure_powder", amount = { min = 1, max = 1 } },
        },
        chance = 100,
        time = 3000
    },
},

    translations = {
        ui_title = 'Recycler',
        ui_subtitle = 'Break down items into raw materials',
        ui_start_recycling = 'Start Recycling',
        ui_cancel = 'Cancel',
        ui_close = 'Close',
        ui_recycling_complete = 'Recycling complete!',
        ui_no_items = 'No recyclable items',
        ui_invalid_item = 'This item cannot be recycled',
        ui_recycling_in_progress = 'Recycling in progress...',
        ui_processing_items = 'Processing items...',
        ui_cancel_process = 'Cancel',
        ui_estimated_time = 'Estimated time',
        ui_processing_time = 'Processing time',
        ui_success_rate = 'Success rate',
        ui_clear_queue = 'Clear queue',
        ui_ready = 'Ready',
        ui_processing = 'Processing',
        ui_empty = 'Empty',
        ui_your_items = 'Your items',
        ui_recycling_queue = 'Recycling queue',
        ui_expected_outputs = 'Expected outputs',
        ui_collected_outputs = 'Collected outputs',
        ui_items = 'Items',
        ui_enter_amount = 'Enter amount',
        ui_confirm = 'Confirm',
        ui_collect_item = 'Collect',
        ui_collect_all = 'Collect all',
        ui_recycler_help = 'Press ~INPUT_CONTEXT~ to use Recycler',
    },
}
