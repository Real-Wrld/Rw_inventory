--  REALWRLD Software® · ox_inventory · drop prop models (seed)
--
--  Which world model a dropped item shows as when Item Drop Physics is
--  on (RWInv.Features.itemDrops + RWInv.Drops in config.lua).
--
--  Simple forms:
--    [item] = 'model'                     one model
--    [item] = { 'model', 'alt_model' }    candidates: the first model that
--                                         exists in the client's game files
--                                         wins (DLC renames degrade cleanly)
--
--  Extended form (a table with a `model` key):
--    [item] = {
--        model    = { 'prop_a', 'prop_b' }, -- string or list, first valid wins
--        offset   = { x = 0.0, y = 0.0, z = 0.0 },  -- metres added to the scatter position (±2.0)
--        rotation = { x = 0.0, y = 0.0, z = 0.0 },  -- pitch/roll/yaw; replaces the w_* rule
--        physics  = false,      -- per-item override of Drops.physics (nil = inherit)
--        bag      = false,      -- true = always represented by the shared bag
--        bagWhenUnknown = true, -- no candidate model on this client: true = bag, false = show nothing
--        stackLimit = 3,        -- cap on copies in scatter mode (0 = never copy, e.g. money)
--    }
--  `scale` is NOT supported: GTA V has no object-scale native. Pick a
--  model of the right size instead.
--
--  Anything not listed goes into the shared bag (`__categories.default`
--  or RWInv.Drops.bagModel). Admins can override every entry in-game
--  (Settings › Admin › Item props); those overrides live in the server
--  KVP `rw:dropProps` and never rewrite this file. `__categories`
--  keys other than `default` are reserved for future use.
-- ─────────────────────────────────────────────────────────────

return {
    __categories = {
        ammo       = 'prop_box_ammo03a',
        attachment = 'prop_box_ammo02a',
        weapon     = 'prop_box_guncase_01a',   -- WEAPON_* when Drops.weaponProps = false
        food       = 'prop_food_bs_burger2',
        drink      = 'prop_ld_flow_bottle',
        medical    = 'prop_ld_health_pack',
        money      = 'prop_cash_pile_01',
        clothing   = { 'prop_ld_shirt_01', 'prop_cs_shirt_pile' },
        bag        = { 'prop_cs_heist_bag_01', 'prop_michael_backpack' },
        default    = 'prop_med_bag_01b',
    },

    -- ═══ common ox items ═══════════════════════════════════════
    water          = 'prop_ld_flow_bottle',
    burger         = 'prop_cs_burger_01',
    testburger     = 'prop_cs_burger_01',
    burger_chicken = 'prop_cs_burger_01',
    pizza_ham      = 'prop_pizza_box_02',
    pizza_ham_slice = { 'prop_pizza_box_01', 'prop_pizza_box_02' },
    fries          = 'prop_food_bs_chips',
    bsfries        = 'prop_food_bs_chips',
    sprunk         = { 'prop_ld_can_01', 'prop_ld_can_01b' },
    cola           = 'prop_ecola_can',
    ecola          = 'prop_ecola_can',
    beer           = 'prop_amb_beer_bottle',
    coffee         = 'prop_fib_coffee',
    bandage        = 'prop_ld_health_pack',
    medikit        = 'prop_ld_health_pack',
    firstaid       = 'prop_ld_health_pack',
    medbag         = { 'xm_prop_x17_bag_med_01a', 'prop_ld_health_pack' },
    tweezers       = { 'prop_tool_screwdvr01', 'prop_ld_health_pack' },
    suturekit      = 'prop_ld_health_pack',
    icepack        = 'prop_ld_health_pack',
    burncream      = 'prop_ld_health_pack',
    defib          = { 'prop_ld_health_pack' },
    sedative       = { 'prop_syringe_01', 'prop_ld_health_pack' },
    phone          = { model = { 'prop_npc_phone', 'prop_npc_phone_02' }, physics = false },
    bm_burner_phone = 'prop_npc_phone_02',
    obd_tablet     = 'prop_cs_tablet',
    billing_machine = { 'prop_cs_tablet', 'prop_npc_phone' },
    money          = { model = 'prop_cash_pile_01', stackLimit = 0 },
    black_money    = 'prop_money_bag_01',
    unmarked_money = 'prop_money_bag_01',
    wet_money      = 'prop_cash_pile_01',
    dry_money      = 'prop_cash_pile_01',
    lockpick       = { 'prop_tool_screwdvr01', 'prop_tool_screwdvr02' },
    radio          = 'prop_cs_hand_radio',
    armour         = 'prop_bodyarmour_02',
    clothing_armor = 'prop_bodyarmour_02',
    parachute      = 'p_parachute_s',
    garbage        = 'prop_rub_binbag_01',
    paperbag       = 'prop_paper_bag_small',
    panties        = { 'prop_cs_panties_02', 'prop_ld_shirt_01' },
    mustard        = { 'prop_mustard_01', 'prop_food_bs_sauce_01' },
    ketchup        = { 'prop_ketchup_01', 'prop_food_bs_sauce_02' },
    scrapmetal     = 'prop_rub_scrap_04',
    copper         = { 'prop_rub_scrap_02', 'prop_rub_scrap_04' },
    iron           = { 'prop_rub_scrap_05', 'prop_rub_scrap_04' },
    ferros         = { 'prop_rub_scrap_05', 'prop_rub_scrap_04' },
    metais         = { 'prop_rub_scrap_02', 'prop_rub_scrap_04' },
    tubos          = { 'prop_rub_scrap_03', 'prop_rub_scrap_04' },
    clothing       = { 'prop_ld_shirt_01', 'prop_cs_shirt_pile' },
    identification = { 'prop_ld_id_card_01', 'prop_ld_wallet_01' },
    idcard         = { 'prop_ld_id_card_01', 'prop_ld_wallet_01' },
    card_id        = { 'prop_ld_id_card_01', 'prop_ld_wallet_01' },
    card_bank      = { 'prop_ld_id_card_01', 'prop_ld_wallet_01' },
    mastercard     = { 'prop_ld_id_card_01', 'prop_ld_wallet_01' },
    american_express = { 'prop_ld_id_card_01', 'prop_ld_wallet_01' },
    wallet_basic   = 'prop_ld_wallet_01',
    wallet_premium = 'prop_ld_wallet_01',
    c4             = 'prop_c4_final_green',
    graffiti       = 'prop_cs_spray_can',
    wheelchair     = 'prop_wheelchair_01',
    crutch         = { 'prop_crutch_01', 'prop_med_bag_01b' },
    miner_pickaxe  = 'prop_tool_pickaxe',
    miner_drill    = 'prop_tool_drill',
    miner_drillhand = 'prop_tool_drill',
    miner_battery  = 'prop_cs_battery_01',
    miner_helmet   = { 'prop_hard_hat_01', 'prop_med_bag_01b' },
    miner_stone    = { 'prop_rock_4_a', 'prop_rock_1_a' },
    miner_ore      = { 'prop_rock_4_a', 'prop_rock_1_a' },
    miner_gold     = 'prop_gold_bar',
    miner_diamond  = { 'prop_cs_diamond_01', 'prop_gold_bar' },
    miner_rare     = { 'prop_cs_diamond_01', 'prop_gold_bar' },
    backpack_level_1 = { 'prop_cs_heist_bag_01', 'prop_michael_backpack' },
    backpack_level_2 = { 'prop_cs_heist_bag_01', 'prop_michael_backpack' },
    backpack_level_3 = { 'prop_cs_heist_bag_02', 'prop_michael_backpack' },
    backpack_level_4 = { 'prop_cs_heist_bag_02', 'prop_michael_backpack' },
    backpack_padlock = { 'prop_cs_padlock', 'prop_box_ammo02a' },
    backpack_fingerprint_padlock = { 'prop_cs_padlock', 'prop_box_ammo02a' },
    mag_pistol     = 'prop_box_ammo03a',
    mag_rifle      = 'prop_box_ammo03a',
    mag_smg        = 'prop_box_ammo03a',
    mag_sniper     = 'prop_box_ammo03a',
    mag_shotgun    = 'prop_box_ammo03a',
    mag_mg         = 'prop_box_ammo03a',

    -- ═══ pistols ═══════════════════════════════════════════════
    WEAPON_PISTOL          = 'w_pi_pistol',
    WEAPON_PISTOL_MK2      = 'w_pi_pistolmk2',
    WEAPON_COMBATPISTOL    = 'w_pi_combatpistol',
    WEAPON_APPISTOL        = 'w_pi_appistol',
    WEAPON_STUNGUN         = 'w_pi_stungun',
    WEAPON_PISTOL50        = 'w_pi_pistol50',
    WEAPON_SNSPISTOL       = 'w_pi_sns_pistol',
    WEAPON_SNSPISTOL_MK2   = 'w_pi_sns_pistolmk2',
    WEAPON_HEAVYPISTOL     = 'w_pi_heavypistol',
    WEAPON_VINTAGEPISTOL   = 'w_pi_vintage_pistol',
    WEAPON_FLAREGUN        = 'w_pi_flaregun',
    WEAPON_MARKSMANPISTOL  = 'w_pi_singleshot',
    WEAPON_REVOLVER        = 'w_pi_revolver',
    WEAPON_REVOLVER_MK2    = 'w_pi_revolvermk2',
    WEAPON_DOUBLEACTION    = 'w_pi_wep1_gun',
    WEAPON_NAVYREVOLVER    = 'w_pi_wep2_gun',
    WEAPON_RAYPISTOL       = 'w_pi_raygun',
    WEAPON_CERAMICPISTOL   = 'w_pi_ceramic_pistol',
    WEAPON_GADGETPISTOL    = { 'w_pi_pistolxm3', 'w_pi_gadgetpistol', 'w_pi_pistol' },
    WEAPON_PISTOLXM3       = { 'w_pi_pistolxm3_pistol', 'w_pi_pistolxm3', 'w_pi_pistol' },

    -- ═══ smgs ══════════════════════════════════════════════════
    WEAPON_MICROSMG        = 'w_sb_microsmg',
    WEAPON_SMG             = 'w_sb_smg',
    WEAPON_SMG_MK2         = 'w_sb_smgmk2',
    WEAPON_ASSAULTSMG      = 'w_sb_assaultsmg',
    WEAPON_COMBATPDW       = 'w_sb_pdw',
    WEAPON_MACHINEPISTOL   = 'w_sb_compactsmg',
    WEAPON_MINISMG         = 'w_sb_minismg',
    WEAPON_GUSENBERG       = 'w_sb_gusenberg',
    WEAPON_TECPISTOL       = { 'w_sb_tecpistol', 'w_sb_smgxm3', 'w_sb_tacticalsmg', 'w_sb_smgmk2' },

    -- ═══ rifles ════════════════════════════════════════════════
    WEAPON_ASSAULTRIFLE        = 'w_ar_assaultrifle',
    WEAPON_ASSAULTRIFLE_MK2    = 'w_ar_assaultriflemk2',
    WEAPON_CARBINERIFLE        = 'w_ar_carbinerifle',
    WEAPON_CARBINERIFLE_MK2    = 'w_ar_carbineriflemk2',
    WEAPON_ADVANCEDRIFLE       = 'w_ar_advancedrifle',
    WEAPON_SPECIALCARBINE      = 'w_ar_specialcarbine',
    WEAPON_SPECIALCARBINE_MK2  = 'w_ar_specialcarbinemk2',
    WEAPON_BULLPUPRIFLE        = 'w_ar_bullpuprifle',
    WEAPON_BULLPUPRIFLE_MK2    = 'w_ar_bullpupriflemk2',
    WEAPON_COMPACTRIFLE        = 'w_ar_assaultrifle_smg',
    WEAPON_MILITARYRIFLE       = 'w_ar_militaryrifle',
    WEAPON_HEAVYRIFLE          = 'w_ar_heavyrifleh',
    WEAPON_TACTICALRIFLE       = { 'w_ar_tacticalrifle', 'w_ar_carbinerifle' },
    WEAPON_BATTLERIFLE         = { 'w_ar_battlerifle', 'w_ar_heavyrifleh' },
    WEAPON_RAYCARBINE          = { 'w_ar_scarbine', 'w_ar_sraycarbine', 'w_ar_carbinerifle' },
    WEAPON_MUSKET              = 'w_ar_musket',
    WEAPON_RAILGUN             = 'w_ar_railgun',
    WEAPON_RAILGUNXM3          = { 'w_ar_railgunxm3', 'w_ar_railgun' },

    -- ═══ machine guns ══════════════════════════════════════════
    WEAPON_MG              = 'w_mg_mg',
    WEAPON_COMBATMG        = 'w_mg_combatmg',
    WEAPON_COMBATMG_MK2    = 'w_mg_combatmgmk2',
    WEAPON_MINIGUN         = 'w_mg_minigun',
    WEAPON_RAYMINIGUN      = { 'w_mg_sminigun', 'w_mg_minigun' },

    -- ═══ shotguns ══════════════════════════════════════════════
    WEAPON_PUMPSHOTGUN     = 'w_sg_pumpshotgun',
    WEAPON_PUMPSHOTGUN_MK2 = 'w_sg_pumpshotgunmk2',
    WEAPON_SAWNOFFSHOTGUN  = 'w_sg_sawnoff',
    WEAPON_ASSAULTSHOTGUN  = 'w_sg_assaultshotgun',
    WEAPON_BULLPUPSHOTGUN  = 'w_sg_bullpupshotgun',
    WEAPON_HEAVYSHOTGUN    = 'w_sg_heavyshotgun',
    WEAPON_DBSHOTGUN       = 'w_sg_doublebarrel',
    WEAPON_AUTOSHOTGUN     = 'w_sg_sweeper',
    WEAPON_COMBATSHOTGUN   = 'w_sg_pumpshotgunh',

    -- ═══ snipers ═══════════════════════════════════════════════
    WEAPON_SNIPERRIFLE       = 'w_sr_sniperrifle',
    WEAPON_HEAVYSNIPER       = 'w_sr_heavysniper',
    WEAPON_HEAVYSNIPER_MK2   = 'w_sr_heavysnipermk2',
    WEAPON_MARKSMANRIFLE     = 'w_sr_marksmanrifle',
    WEAPON_MARKSMANRIFLE_MK2 = 'w_sr_marksmanriflemk2',
    WEAPON_PRECISIONRIFLE    = { 'w_sr_precisionrifle', 'w_sr_marksmanrifle' },

    -- ═══ heavy ═════════════════════════════════════════════════
    WEAPON_GRENADELAUNCHER = 'w_lr_grenadelauncher',
    WEAPON_RPG             = 'w_lr_rpg',
    WEAPON_FIREWORK        = 'w_lr_firework',
    WEAPON_HOMINGLAUNCHER  = 'w_lr_homing',
    WEAPON_COMPACTLAUNCHER = 'w_lr_compactgl',
    WEAPON_EMPLAUNCHER     = { 'w_lr_compactml', 'w_lr_compactgl' },
    WEAPON_SNOWLAUNCHER    = { 'w_lr_snowlauncher', 'w_lr_compactgl' },

    -- ═══ melee ═════════════════════════════════════════════════
    WEAPON_KNIFE           = 'w_me_knife_01',
    WEAPON_NIGHTSTICK      = 'w_me_nightstick',
    WEAPON_HAMMER          = 'w_me_hammer',
    WEAPON_BAT             = 'w_me_bat',
    WEAPON_GOLFCLUB        = 'w_me_gclub',
    WEAPON_CROWBAR         = 'w_me_crowbar',
    WEAPON_BOTTLE          = 'w_me_bottle',
    WEAPON_DAGGER          = 'w_me_dagger',
    WEAPON_HATCHET         = 'w_me_hatchet',
    WEAPON_KNUCKLE         = 'w_me_knuckle',
    WEAPON_MACHETE         = 'w_me_machette_lr',
    WEAPON_FLASHLIGHT      = 'w_me_flashlight',
    WEAPON_SWITCHBLADE     = 'w_me_switchblade',
    WEAPON_BATTLEAXE       = 'w_me_battleaxe',
    WEAPON_POOLCUE         = 'w_me_poolcue',
    WEAPON_WRENCH          = 'w_me_wrench',
    WEAPON_STONE_HATCHET   = 'w_me_stonehatchet',
    WEAPON_CANDYCANE       = { 'w_me_candycane', 'w_me_nightstick' },

    -- ═══ throwables / misc ═════════════════════════════════════
    WEAPON_GRENADE         = 'w_ex_grenadefrag',
    WEAPON_BZGAS           = 'w_ex_grenadegas',
    WEAPON_TEARGAS         = 'w_ex_grenadesmoke',
    WEAPON_SMOKEGRENADE    = 'w_ex_grenadesmoke',
    WEAPON_MOLOTOV         = 'w_ex_molotov',
    WEAPON_STICKYBOMB      = 'w_ex_pe',
    WEAPON_PROXMINE        = 'w_ex_apmine',
    WEAPON_PIPEBOMB        = 'w_ex_pipebomb',
    WEAPON_SNOWBALL        = 'w_ex_snowball',
    WEAPON_BALL            = 'w_am_baseball',
    WEAPON_FLARE           = 'w_am_flare',
    WEAPON_PETROLCAN       = 'w_am_jerrycan',
    WEAPON_HAZARDCAN       = { 'w_am_jerrycan_sf', 'w_am_jerrycan' },
    WEAPON_FERTILIZERCAN   = { 'w_am_fertilizercan', 'w_am_jerrycan' },
    WEAPON_FIREEXTINGUISHER = 'w_am_fire_exting',
    WEAPON_METALDETECTOR   = { 'w_am_metaldetector', 'w_me_flashlight' },

    -- ═══ attachments ═══════════════════════════════════════════
    at_flashlight        = 'w_at_ar_flsh',
    at_suppressor_light  = 'w_at_pi_supp',
    at_suppressor_heavy  = 'w_at_ar_supp_02',
    at_grip              = 'w_at_ar_afgrip',
    at_barrel            = { 'w_at_ar_barrel_01', 'prop_box_ammo02a' },
    at_compensator       = { 'w_at_ar_comp', 'w_at_pi_comp', 'prop_box_ammo02a' },
    at_scope_macro       = 'w_at_scope_macro',
    at_scope_small       = 'w_at_scope_small',
    at_scope_medium      = 'w_at_scope_medium',
    at_scope_large       = 'w_at_scope_large',
    at_scope_advanced    = { 'w_at_scope_large_2', 'w_at_scope_large' },
    at_scope_holo        = { 'w_at_sights', 'w_at_scope_small' },
    at_scope_nv          = { 'w_at_scope_nv', 'w_at_scope_large' },
    at_scope_thermal     = { 'w_at_scope_thermal', 'w_at_scope_large' },
    at_muzzle_flat       = { 'w_at_muzzle_1', 'prop_box_ammo02a' },
    at_muzzle_tactical   = { 'w_at_muzzle_2', 'prop_box_ammo02a' },
    at_muzzle_fat        = { 'w_at_muzzle_3', 'prop_box_ammo02a' },
    at_muzzle_precision  = { 'w_at_muzzle_4', 'prop_box_ammo02a' },
    at_muzzle_heavy      = { 'w_at_muzzle_5', 'prop_box_ammo02a' },
    at_muzzle_slanted    = { 'w_at_muzzle_6', 'prop_box_ammo02a' },
    at_muzzle_split      = { 'w_at_muzzle_7', 'prop_box_ammo02a' },
    at_muzzle_squared    = { 'w_at_muzzle_8', 'prop_box_ammo02a' },
    at_muzzle_bell       = { 'w_at_muzzle_9', 'prop_box_ammo02a' },
}
