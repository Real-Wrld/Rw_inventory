--  Item rarity table — Arc Raiders / Destiny inspired
--
--  Tiers (lowest → highest):
--    common     ─ gray   (default for everything not listed)
--    uncommon   ─ green
--    rare       ─ blue
--    epic       ─ purple
--    legendary  ─ orange / gold
--    mythic     ─ pink
--
--  Anything not listed renders without rarity wash (clean slot).
--  Disable the whole system: `set inventory:rarity 0` in server.cfg.
-- ─────────────────────────────────────────────────────────────

return {
    -- ═══ MELEE WEAPONS ════════════════════════════════════════
    WEAPON_KNIFE         = 'common',
    WEAPON_NIGHTSTICK    = 'common',
    WEAPON_HAMMER        = 'common',
    WEAPON_BAT           = 'common',
    WEAPON_GOLFCLUB      = 'common',
    WEAPON_CROWBAR       = 'common',
    WEAPON_BOTTLE        = 'common',
    WEAPON_KNUCKLE       = 'common',
    WEAPON_FLASHLIGHT    = 'common',
    WEAPON_POOLCUE       = 'common',
    WEAPON_WRENCH        = 'common',
    WEAPON_BALL          = 'common',
    WEAPON_CANDYCANE     = 'common',
    WEAPON_HATCHET       = 'uncommon',
    WEAPON_MACHETE       = 'uncommon',
    WEAPON_SWITCHBLADE   = 'uncommon',
    WEAPON_STONE_HATCHET = 'rare',
    WEAPON_DAGGER        = 'rare',
    WEAPON_BATTLEAXE     = 'epic',

    -- ═══ PISTOLS / SIDEARMS ═══════════════════════════════════
    WEAPON_PISTOL          = 'uncommon',
    WEAPON_PISTOL_MK2      = 'rare',
    WEAPON_PISTOLXM3       = 'rare',
    WEAPON_COMBATPISTOL    = 'uncommon',
    WEAPON_APPISTOL        = 'rare',
    WEAPON_PISTOL50        = 'rare',
    WEAPON_SNSPISTOL       = 'common',
    WEAPON_SNSPISTOL_MK2   = 'uncommon',
    WEAPON_HEAVYPISTOL     = 'rare',
    WEAPON_VINTAGEPISTOL   = 'epic',
    WEAPON_CERAMICPISTOL   = 'rare',
    WEAPON_NAVYREVOLVER    = 'epic',
    WEAPON_REVOLVER        = 'rare',
    WEAPON_REVOLVER_MK2    = 'epic',
    WEAPON_DOUBLEACTION    = 'epic',
    WEAPON_MARKSMANPISTOL  = 'rare',
    WEAPON_STUNGUN         = 'uncommon',
    WEAPON_FLAREGUN        = 'uncommon',
    WEAPON_GADGETPISTOL    = 'epic',
    WEAPON_TECPISTOL       = 'rare',

    -- ═══ SMGs ═════════════════════════════════════════════════
    WEAPON_MICROSMG        = 'uncommon',
    WEAPON_SMG             = 'rare',
    WEAPON_SMG_MK2         = 'epic',
    WEAPON_ASSAULTSMG      = 'rare',
    WEAPON_COMBATPDW       = 'rare',
    WEAPON_MACHINEPISTOL   = 'uncommon',
    WEAPON_MINISMG         = 'rare',

    -- ═══ SHOTGUNS ═════════════════════════════════════════════
    WEAPON_PUMPSHOTGUN     = 'rare',
    WEAPON_PUMPSHOTGUN_MK2 = 'epic',
    WEAPON_SAWNOFFSHOTGUN  = 'uncommon',
    WEAPON_ASSAULTSHOTGUN  = 'epic',
    WEAPON_BULLPUPSHOTGUN  = 'rare',
    WEAPON_MUSKET          = 'epic',
    WEAPON_HEAVYSHOTGUN    = 'epic',
    WEAPON_DBSHOTGUN       = 'rare',
    WEAPON_AUTOSHOTGUN     = 'legendary',
    WEAPON_COMBATSHOTGUN   = 'epic',

    -- ═══ ASSAULT RIFLES ═══════════════════════════════════════
    WEAPON_ASSAULTRIFLE       = 'epic',
    WEAPON_ASSAULTRIFLE_MK2   = 'legendary',
    WEAPON_CARBINERIFLE       = 'epic',
    WEAPON_CARBINERIFLE_MK2   = 'legendary',
    WEAPON_ADVANCEDRIFLE      = 'epic',
    WEAPON_SPECIALCARBINE     = 'epic',
    WEAPON_SPECIALCARBINE_MK2 = 'legendary',
    WEAPON_BULLPUPRIFLE       = 'epic',
    WEAPON_BULLPUPRIFLE_MK2   = 'legendary',
    WEAPON_COMPACTRIFLE       = 'rare',
    WEAPON_MILITARYRIFLE      = 'legendary',
    WEAPON_HEAVYRIFLE         = 'legendary',
    WEAPON_TACTICALRIFLE      = 'epic',
    WEAPON_BATTLERIFLE        = 'legendary',

    -- ═══ SNIPERS ══════════════════════════════════════════════
    WEAPON_SNIPERRIFLE       = 'legendary',
    WEAPON_HEAVYSNIPER       = 'legendary',
    WEAPON_HEAVYSNIPER_MK2   = 'mythic',
    WEAPON_MARKSMANRIFLE     = 'legendary',
    WEAPON_MARKSMANRIFLE_MK2 = 'mythic',
    WEAPON_PRECISIONRIFLE    = 'legendary',

    -- ═══ LMGs / HEAVY ═════════════════════════════════════════
    WEAPON_MG                    = 'legendary',
    WEAPON_COMBATMG              = 'legendary',
    WEAPON_COMBATMG_MK2          = 'mythic',
    WEAPON_GUSENBERG             = 'epic',
    WEAPON_RPG                   = 'mythic',
    WEAPON_GRENADELAUNCHER       = 'mythic',
    WEAPON_MINIGUN               = 'mythic',
    WEAPON_FIREWORK              = 'epic',
    WEAPON_RAILGUN               = 'mythic',
    WEAPON_RAILGUNXM3            = 'mythic',
    WEAPON_HOMINGLAUNCHER        = 'mythic',
    WEAPON_COMPACTLAUNCHER       = 'epic',
    WEAPON_EMPLAUNCHER           = 'mythic',
    WEAPON_SNOWLAUNCHER          = 'rare',
    WEAPON_RAYPISTOL             = 'mythic',
    WEAPON_RAYCARBINE            = 'mythic',
    WEAPON_RAYMINIGUN            = 'mythic',

    -- ═══ EXPLOSIVES / THROWABLES ══════════════════════════════
    WEAPON_GRENADE          = 'epic',
    WEAPON_STICKYBOMB       = 'legendary',
    WEAPON_PROXMINE         = 'legendary',
    WEAPON_PIPEBOMB         = 'legendary',
    WEAPON_BZGAS            = 'rare',
    WEAPON_TEARGAS          = 'rare',
    WEAPON_MOLOTOV          = 'uncommon',
    WEAPON_SMOKEGRENADE     = 'rare',
    WEAPON_FIREEXTINGUISHER = 'common',
    WEAPON_PETROLCAN        = 'common',
    WEAPON_FERTILIZERCAN    = 'common',
    WEAPON_HAZARDCAN        = 'common',
    WEAPON_FLARE            = 'common',
    WEAPON_SNOWBALL         = 'common',
    WEAPON_METALDETECTOR    = 'uncommon',

    -- ═══ WEAPON ATTACHMENTS ═══════════════════════════════════
    -- barrel / grip / accessories
    at_barrel       = 'uncommon',
    at_grip         = 'uncommon',
    at_flashlight   = 'common',
    at_compensator  = 'rare',

    -- extended / drum magazines (more rounds = rarer)
    at_clip_extended_pistol  = 'uncommon',
    at_clip_extended_smg     = 'uncommon',
    at_clip_extended_shotgun = 'rare',
    at_clip_extended_rifle   = 'rare',
    at_clip_extended_sniper  = 'epic',
    at_clip_extended_mg      = 'epic',
    at_clip_drum_smg         = 'rare',
    at_clip_drum_shotgun     = 'epic',
    at_clip_drum_rifle       = 'epic',

    -- muzzle attachments
    at_muzzle_flat      = 'uncommon',
    at_muzzle_tactical  = 'uncommon',
    at_muzzle_fat       = 'uncommon',
    at_muzzle_squared   = 'rare',
    at_muzzle_bell      = 'rare',
    at_muzzle_heavy     = 'rare',
    at_muzzle_slanted   = 'rare',
    at_muzzle_split     = 'rare',
    at_muzzle_precision = 'epic',

    -- suppressors
    at_suppressor_light = 'rare',
    at_suppressor_heavy = 'epic',

    -- scopes (miras) — tier by capability
    at_scope_small    = 'uncommon',
    at_scope_medium   = 'rare',
    at_scope_large    = 'rare',
    at_scope_macro    = 'rare',
    at_scope_holo     = 'epic',
    at_scope_advanced = 'epic',
    at_scope_nv       = 'legendary',  -- night vision
    at_scope_thermal  = 'mythic',     -- thermal — top tier

    -- weapon skins (cosmetic — mostly common, premium ones higher)
    at_skin_brushstroke    = 'common',
    at_skin_burgershot     = 'common',
    at_skin_camo           = 'common',
    at_skin_cluckinbell    = 'common',
    at_skin_festive        = 'common',
    at_skin_geometric      = 'common',
    at_skin_hate           = 'common',
    at_skin_leopard        = 'common',
    at_skin_love           = 'common',
    at_skin_metal          = 'common',
    at_skin_patriotic      = 'common',
    at_skin_player         = 'common',
    at_skin_skull          = 'common',
    at_skin_splatter       = 'common',
    at_skin_tiedye         = 'common',
    at_skin_trippy         = 'common',
    at_skin_wall           = 'common',
    at_skin_wood           = 'common',
    at_skin_woodland       = 'common',
    at_skin_zebra          = 'common',
    at_skin_bulletholes    = 'common',
    at_skin_blagueurs      = 'uncommon',
    at_skin_bodyguard      = 'uncommon',
    at_skin_boom           = 'uncommon',
    at_skin_luchalibre     = 'uncommon',
    at_skin_security       = 'uncommon',
    at_skin_pimp           = 'uncommon',
    at_skin_sessanta       = 'uncommon',
    at_skin_vagos          = 'rare',
    at_skin_ballas         = 'rare',
    at_skin_king           = 'rare',
    at_skin_dollar         = 'rare',
    at_skin_luxe           = 'rare',
    at_skin_vip            = 'rare',
    at_skin_pearl          = 'rare',
    at_skin_fatalincursion = 'epic',
    at_skin_perseus        = 'epic',
    at_skin_diamond        = 'legendary',

    -- ═══ FOOD / DRINK / JUNK (all common) ═════════════════════
    burger          = 'common',
    burger_chicken  = 'common',
    pizza_ham       = 'common',
    pizza_ham_slice = 'common',
    fries           = 'common',
    bsfries         = 'common',
    water           = 'common',
    sprunk          = 'common',
    mustard         = 'common',
    testburger      = 'common',
    garbage         = 'common',
    paperbag        = 'common',
    panties         = 'common',
    scrapmetal      = 'common',
    ferros          = 'common',
    tubos           = 'common',
    metais          = 'uncommon',

    -- ═══ MONEY VARIANTS ═══════════════════════════════════════
    money          = 'common',
    wet_money      = 'common',
    dry_money      = 'common',
    black_money    = 'uncommon',  -- dirty / off-the-grid
    unmarked_money = 'uncommon',

    -- ═══ CARDS / IDs / DOCUMENTS — all common (basic papers) ══
    card_id           = 'common',
    idcard            = 'common',
    identification    = 'common',
    card_bank         = 'common',
    mastercard        = 'common',
    american_express  = 'common',
    inspection_done   = 'common',
    inspection_failed = 'common',

    -- ═══ ELECTRONICS / UTILITY ════════════════════════════════
    phone           = 'common',
    bm_burner_phone = 'uncommon',  -- burner phones are sketchier
    radio           = 'uncommon',
    obd_tablet      = 'rare',       -- mechanic diagnostic
    quadro          = 'uncommon',
    billing_machine = 'rare',
    clothing        = 'common',
    lockpick        = 'uncommon',
    parachute       = 'rare',
    c4              = 'rare',

    -- ═══ MEDICAL ══════════════════════════════════════════════
    bandage    = 'common',
    icepack    = 'common',
    crutch     = 'common',
    wheelchair = 'uncommon',
    medikit    = 'uncommon',
    tweezers   = 'uncommon',
    suturekit  = 'uncommon',
    burncream  = 'uncommon',
    medbag     = 'rare',
    sedative   = 'rare',
    defib      = 'epic',

    -- ═══ COMBAT GEAR ══════════════════════════════════════════
    armour = 'rare',

    -- ═══ WALLETS ══════════════════════════════════════════════
    wallet_basic   = 'uncommon',
    wallet_premium = 'epic',

    -- ═══ BACKPACKS — tier by capacity ═════════════════════════
    backpack_level_1             = 'uncommon',
    backpack_level_2             = 'rare',
    backpack_level_3             = 'epic',
    backpack_level_4             = 'legendary',
    backpack_fingerprint_padlock = 'epic',

    -- ═══ MINING / CRAFTING ════════════════════════════════════
    miner_battery   = 'uncommon',
    miner_pickaxe   = 'uncommon',
    miner_drillhand = 'uncommon',
    miner_drill     = 'rare',
    miner_helmet    = 'uncommon',
    miner_stone     = 'common',
    miner_ore       = 'common',
    miner_gold      = 'rare',
    miner_diamond   = 'epic',
    miner_rare      = 'legendary',

    -- ═══ REALWRLD ADDITIONS (generated 2026-10-25) ═══
    -- His items missing from the vendor map, tiered from data/shops.lua
    -- prices with his old UI's thresholds (>=500 rare, >=5000 epic,
    -- >=50000 legendary). Hand-tune freely — delete a line to clean it.
    WEAPON_COPPERHEAD = 'legendary',
    WEAPON_DIAN = 'legendary',
    WEAPON_KENSHIN = 'legendary',
    WEAPON_LEXINGTON = 'legendary',
    WEAPON_OMAHA = 'legendary',
    WEAPON_TAMAYURA = 'legendary',
    WEAPON_TSUNAMI = 'legendary',
    WEAPON_ascia = 'epic',
    WEAPON_bat1 = 'epic',
    WEAPON_carnage = 'legendary',
    WEAPON_ham1 = 'epic',
    WEAPON_machetecustom = 'epic',
    blueprint_WEAPON_MASAMUNE = 'legendary',
    blueprint_WEAPON_NEKOMATA = 'legendary',
    blueprint_WEAPON_SARATOGA = 'legendary',
    blueprint_WEAPON_ascia = 'legendary',
    blueprint_WEAPON_carnage = 'legendary',
    blueprint_WEAPON_motosega = 'legendary',
    blueprint_WEAPON_silverhand = 'legendary',
    blueprint_WEAPON_skippy = 'legendary',

    -- Forge / crafting / printer materials (polish pass 2026-11-02):
    -- tiered by the rarest thing they make across data/crafting.lua and
    -- modules/rwprinter/config/items.lua — feeds an epic/master-or-
    -- legendary-tier product -> epic; feeds a rare/advanced one -> rare.
    adamantite_ore = 'epic',
    amethyst = 'epic',
    arcane_crystal = 'epic',
    arcane_dust = 'epic',
    carbon_fiber = 'epic',
    cobalt_ore = 'epic',
    dark_glass = 'epic',
    diamond = 'epic',
    electronics = 'epic',
    emerald = 'epic',
    emp_grenade = 'epic',
    gold_band = 'epic',
    hacking_device = 'epic',
    infernal_dust = 'epic',
    leather = 'epic',
    master_lockpick = 'epic',
    master_weapon_parts = 'epic',
    mithril_ore = 'epic',
    onyx = 'epic',
    refined_gem = 'epic',
    refined_mithril = 'epic',
    reinforced_handle = 'epic',
    ruby = 'epic',
    rune_core = 'epic',
    runite_ore = 'epic',
    sapphire = 'epic',
    shadow_silk = 'epic',
    steel_pickaxe = 'epic',
    titanium_alloy = 'epic',
    tool_parts = 'epic',
    cloth = 'rare',
    fishing_line = 'rare',
    fishing_rod = 'rare',
    plastic = 'rare',
    rubber = 'rare',
}
