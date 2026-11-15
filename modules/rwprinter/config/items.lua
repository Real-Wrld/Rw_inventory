-- ═══════════════════════════════════════════════════════════════════════════
--  REALWRLD · 3D PRINTER SYSTEM
--  config/items.lua — what the printers can make
-- ═══════════════════════════════════════════════════════════════════════════
--
--  GENERATED FILE — do not hand-edit the item list.
--
--  This catalogue was generated from the RealWrld forge recipes in
--  ox_inventory's data/crafting.lua (every crafting station, de-duplicated
--  by result item): result item -> key, ingredients -> materials,
--  duration (ms) -> time (s), count -> amount. Power is derived from the
--  material count: 6 + 3 per material unit, capped at 220 Wh.
--
--  THIS FILE IS THE SEED, NOT THE LIVE CATALOGUE.
--
--  On the first start it is copied into the database, and from then on the
--  database is what the printers read. Editing this file has no effect in
--  game until you open /printeradmin and press "Restore defaults" — which
--  loads this file again and throws away everything edited in the console.
--
--  ─────────────────────────────────────────────────────────────────────────
--  EVERY KEY MUST EXIST IN YOUR INVENTORY
--
--  For weapons the key is the weapon hash name (e.g. 'WEAPON_PISTOL').
--
--  FIELDS
--
--    key          the inventory item name (it has to exist there)
--    label        name shown in the interface. nil = the key itself
--    image        image file. nil = "<key>.png"
--    time         seconds to print, before PrinterConfig.TimeMultiplier
--    amount       how many units come out of one print
--    category     one of the ids in PrinterConfig.Categories below
--    materials    { [item] = amount } taken the moment the job is queued
--    power        energy spent, in watt hours (nil = 0 = free)
--    job          nil, or 'mechanic', or { 'mechanic', 'police' }
--    grade        minimum job grade (nil = any)
--    prop         model that materialises on the bed while it prints
--                 (WEAPON_* keys are built from the weapon hash, no prop)
--    description  text in the detail panel
--    enabled      false hides it from every printer
--    sort         orders items inside a category (lower comes first)
--
--  NOTE: forge recipe metadata (durability, registered, armor values) has
--  no equivalent in the printer seed format and is not carried over —
--  printed items are plain items.
--
-- ═══════════════════════════════════════════════════════════════════════════

--- Categories shown as filters in the interface.
--- The `id` must have a matching 'cat_<id>' entry in locales/, and `icon` is
--- one of the icon names the interface ships with:
---   crosshair · shield · wrench · layers · chip · car · heart · package
PrinterConfig.Categories = {
    { id = 'weapons', icon = 'crosshair' },
    { id = 'gear', icon = 'shield' },
    { id = 'tools', icon = 'wrench' },
    { id = 'materials', icon = 'layers' },
    { id = 'electronics', icon = 'chip' },
    { id = 'medical', icon = 'heart' },
    { id = 'vehicle', icon = 'car' },
    { id = 'misc', icon = 'package' },
}

PrinterConfig.Items = {

    -- ──────────────────────────────────────────────────────────────────
    --  WEAPONS
    -- ──────────────────────────────────────────────────────────────────

    ['thermite'] = {
        label       = 'Thermite Charge',
        time        = 10,
        amount      = 2,
        category    = 'weapons',
        materials   = { ['arcane_dust'] = 15, ['mithril_ore'] = 3, ['ruby'] = 3 },
        power       = 69,
        description = 'Advanced tier forge recipe - Downtown Workshop.',
        sort        = 10,
    },

    ['WEAPON_MASAMUNE'] = {
        label       = 'Masamune',
        time        = 60,
        amount      = 1,
        category    = 'weapons',
        materials   = { ['arcane_dust'] = 45, ['diamond'] = 2, ['emerald'] = 5, ['master_weapon_parts'] = 7, ['mithril_ore'] = 14, ['rune_core'] = 3, ['titanium_alloy'] = 12 },
        power       = 220,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 20,
    },

    ['WEAPON_SARATOGA'] = {
        label       = 'Saratoga',
        time        = 34,
        amount      = 1,
        category    = 'weapons',
        materials   = { ['arcane_dust'] = 15, ['master_weapon_parts'] = 3, ['mithril_ore'] = 7, ['onyx'] = 4, ['titanium_alloy'] = 7 },
        power       = 114,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 30,
    },

    ['WEAPON_ascia'] = {
        label       = 'Ascia',
        time        = 18,
        amount      = 1,
        category    = 'weapons',
        materials   = { ['carbon_fiber'] = 2, ['master_weapon_parts'] = 1, ['onyx'] = 1, ['titanium_alloy'] = 3 },
        power       = 27,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 40,
    },

    ['WEAPON_carnage'] = {
        label       = 'Carnage',
        time        = 36,
        amount      = 1,
        category    = 'weapons',
        materials   = { ['arcane_dust'] = 18, ['dark_glass'] = 5, ['master_weapon_parts'] = 3, ['mithril_ore'] = 9, ['ruby'] = 5 },
        power       = 126,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 50,
    },

    ['WEAPON_motosega'] = {
        label       = 'Motosega',
        time        = 30,
        amount      = 1,
        category    = 'weapons',
        materials   = { ['dark_glass'] = 2, ['master_weapon_parts'] = 2, ['mithril_ore'] = 6, ['ruby'] = 3, ['titanium_alloy'] = 8 },
        power       = 69,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 60,
    },

    ['WEAPON_silverhand'] = {
        label       = 'Silverhand',
        time        = 55,
        amount      = 1,
        category    = 'weapons',
        materials   = { ['arcane_dust'] = 50, ['diamond'] = 4, ['master_weapon_parts'] = 6, ['mithril_ore'] = 12, ['ruby'] = 4, ['rune_core'] = 3 },
        power       = 220,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 70,
    },

    ['WEAPON_skippy'] = {
        label       = 'Skippy',
        time        = 42,
        amount      = 1,
        category    = 'weapons',
        materials   = { ['arcane_dust'] = 35, ['emerald'] = 3, ['master_weapon_parts'] = 4, ['rune_core'] = 2, ['sapphire'] = 5, ['titanium_alloy'] = 6 },
        power       = 171,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 80,
    },

    ['c4'] = {
        label       = 'C4 Explosive',
        time        = 20,
        amount      = 1,
        category    = 'weapons',
        materials   = { ['arcane_dust'] = 30, ['dark_glass'] = 5, ['ruby'] = 5, ['rune_core'] = 2 },
        power       = 132,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 90,
    },

    ['emp_grenade'] = {
        label       = 'EMP Grenade',
        time        = 18,
        amount      = 2,
        category    = 'weapons',
        materials   = { ['amethyst'] = 4, ['arcane_dust'] = 20, ['mithril_ore'] = 5, ['rune_core'] = 2 },
        power       = 99,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 100,
    },

    ['infernal_charge'] = {
        label       = 'Infernal Charge',
        time        = 15,
        amount      = 1,
        category    = 'weapons',
        materials   = { ['electronics'] = 2, ['infernal_dust'] = 10, ['runite_ore'] = 1 },
        power       = 45,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 110,
    },

    ['WEAPON_NEKOMATA'] = {
        label       = 'Nekomata',
        time        = 75,
        amount      = 1,
        category    = 'weapons',
        materials   = { ['arcane_dust'] = 75, ['dark_glass'] = 8, ['diamond'] = 6, ['master_weapon_parts'] = 10, ['mithril_ore'] = 18, ['rune_core'] = 5, ['sapphire'] = 6 },
        power       = 220,
        description = 'Legendary tier forge recipe - Industrial Forge.',
        sort        = 120,
    },

    ['runite_blade'] = {
        label       = 'Runite Blade',
        time        = 60,
        amount      = 1,
        category    = 'weapons',
        materials   = { ['adamantite_ore'] = 2, ['diamond'] = 1, ['leather'] = 2, ['runite_ore'] = 5 },
        power       = 36,
        description = 'Legendary tier forge recipe - Arcane Sanctum.',
        sort        = 130,
    },

    -- ──────────────────────────────────────────────────────────────────
    --  GEAR
    -- ──────────────────────────────────────────────────────────────────

    ['armor'] = {
        label       = 'Body Armor',
        time        = 8,
        amount      = 1,
        category    = 'gear',
        materials   = { ['carbon_fiber'] = 3, ['mithril_ore'] = 2, ['titanium_alloy'] = 2 },
        power       = 27,
        description = 'Basic tier forge recipe - Downtown Workshop.',
        sort        = 10,
    },

    ['advanced_armor'] = {
        label       = 'Advanced Armor',
        time        = 12,
        amount      = 1,
        category    = 'gear',
        materials   = { ['carbon_fiber'] = 5, ['mithril_ore'] = 5, ['onyx'] = 2 },
        power       = 42,
        description = 'Advanced tier forge recipe - Downtown Workshop.',
        sort        = 20,
    },

    ['shadow_parachute'] = {
        label       = 'Shadow Parachute',
        time        = 8,
        amount      = 1,
        category    = 'gear',
        materials   = { ['cloth'] = 5, ['rubber'] = 2, ['shadow_silk'] = 5 },
        power       = 42,
        description = 'Advanced tier forge recipe - Downtown Workshop.',
        sort        = 30,
    },

    ['adamantite_armor'] = {
        label       = 'Adamantite Armor',
        time        = 20,
        amount      = 1,
        category    = 'gear',
        materials   = { ['adamantite_ore'] = 5, ['shadow_silk'] = 3, ['titanium_alloy'] = 5 },
        power       = 45,
        description = 'Master tier forge recipe - Desert Workshop.',
        sort        = 40,
    },

    ['legendary_armor'] = {
        label       = 'Reactive Armor',
        time        = 30,
        amount      = 1,
        category    = 'gear',
        materials   = { ['carbon_fiber'] = 10, ['diamond'] = 3, ['mithril_ore'] = 15, ['rune_core'] = 5 },
        power       = 105,
        description = 'Legendary tier forge recipe - Arcane Sanctum.',
        sort        = 50,
    },

    -- ──────────────────────────────────────────────────────────────────
    --  TOOLS
    -- ──────────────────────────────────────────────────────────────────

    ['binoculars'] = {
        label       = 'Binoculars',
        time        = 5,
        amount      = 1,
        category    = 'tools',
        materials   = { ['dark_glass'] = 2, ['emerald'] = 1 },
        power       = 15,
        description = 'Basic tier forge recipe - Downtown Workshop.',
        sort        = 10,
    },

    ['flashlight'] = {
        label       = 'Flashlight',
        time        = 3,
        amount      = 1,
        category    = 'tools',
        materials   = { ['dark_glass'] = 1, ['sapphire'] = 1 },
        power       = 12,
        description = 'Basic tier forge recipe - Downtown Workshop.',
        sort        = 20,
    },

    ['lockpick'] = {
        label       = 'Lockpick',
        time        = 3,
        amount      = 1,
        category    = 'tools',
        materials   = { ['carbon_fiber'] = 1, ['titanium_alloy'] = 1 },
        power       = 12,
        description = 'Basic tier forge recipe - Downtown Workshop.',
        sort        = 30,
    },

    ['pickaxe'] = {
        label       = 'Pickaxe',
        time        = 4,
        amount      = 1,
        category    = 'tools',
        materials   = { ['aluminum'] = 3, ['steel'] = 2 },
        power       = 21,
        description = 'Basic tier forge recipe - Craftsman\'s Corner.',
        sort        = 40,
    },

    ['repairkit'] = {
        label       = 'Repair Kit',
        time        = 4,
        amount      = 1,
        category    = 'tools',
        materials   = { ['mithril_ore'] = 1, ['titanium_alloy'] = 2 },
        power       = 15,
        description = 'Basic tier forge recipe - Downtown Workshop.',
        sort        = 50,
    },

    ['advanced_lockpick'] = {
        label       = 'Advanced Lockpick',
        time        = 6,
        amount      = 2,
        category    = 'tools',
        materials   = { ['arcane_dust'] = 5, ['ruby'] = 1, ['titanium_alloy'] = 3 },
        power       = 33,
        description = 'Advanced tier forge recipe - Downtown Workshop.',
        sort        = 60,
    },

    ['advancedrepairkit'] = {
        label       = 'Advanced Repair Kit',
        time        = 8,
        amount      = 1,
        category    = 'tools',
        materials   = { ['arcane_dust'] = 8, ['emerald'] = 2, ['titanium_alloy'] = 5 },
        power       = 51,
        description = 'Advanced tier forge recipe - Downtown Workshop.',
        sort        = 70,
    },

    ['cobalt_lockpick'] = {
        label       = 'Cobalt Lockpick',
        time        = 5,
        amount      = 2,
        category    = 'tools',
        materials   = { ['cobalt_ore'] = 2, ['plastic'] = 2, ['titanium_alloy'] = 1 },
        power       = 21,
        description = 'Advanced tier forge recipe - Downtown Workshop.',
        sort        = 80,
    },

    ['quality_fishing_rod'] = {
        label       = 'Quality Fishing Rod',
        time        = 8,
        amount      = 1,
        category    = 'tools',
        materials   = { ['emerald'] = 1, ['fishing_line'] = 2, ['fishing_rod'] = 1 },
        power       = 18,
        description = 'Advanced tier forge recipe - Craftsman\'s Corner.',
        sort        = 90,
    },

    ['salvage_kit'] = {
        label       = 'Salvage Kit',
        time        = 10,
        amount      = 1,
        category    = 'tools',
        materials   = { ['electronics'] = 2, ['tool_parts'] = 1 },
        power       = 15,
        description = 'Advanced tier forge recipe - Craftsman\'s Corner.',
        sort        = 100,
    },

    ['steel_pickaxe'] = {
        label       = 'Steel Pickaxe',
        time        = 10,
        amount      = 1,
        category    = 'tools',
        materials   = { ['refined_mithril'] = 2, ['reinforced_handle'] = 1 },
        power       = 15,
        description = 'Advanced tier forge recipe - Craftsman\'s Corner.',
        sort        = 110,
    },

    ['master_lockpick'] = {
        label       = 'Master Lockpick',
        time        = 10,
        amount      = 3,
        category    = 'tools',
        materials   = { ['arcane_dust'] = 20, ['diamond'] = 1, ['rune_core'] = 1, ['titanium_alloy'] = 5 },
        power       = 87,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 120,
    },

    ['master_toolset'] = {
        label       = 'Master Toolset',
        time        = 18,
        amount      = 1,
        category    = 'tools',
        materials   = { ['diamond'] = 1, ['tool_parts'] = 2 },
        power       = 15,
        description = 'Master tier forge recipe - Craftsman\'s Corner.',
        sort        = 130,
    },

    ['legendary_toolkit'] = {
        label       = 'Legendary Toolkit',
        time        = 25,
        amount      = 1,
        category    = 'tools',
        materials   = { ['arcane_dust'] = 50, ['diamond'] = 2, ['mithril_ore'] = 10, ['rune_core'] = 3 },
        power       = 201,
        description = 'Legendary tier forge recipe - Arcane Sanctum.',
        sort        = 140,
    },

    ['runic_pickaxe'] = {
        label       = 'Runic Pickaxe',
        time        = 25,
        amount      = 1,
        category    = 'tools',
        materials   = { ['rune_core'] = 1, ['runite_ore'] = 1, ['steel_pickaxe'] = 1 },
        power       = 15,
        description = 'Legendary tier forge recipe - Craftsman\'s Corner.',
        sort        = 150,
    },

    ['skeleton_key'] = {
        label       = 'Skeleton Key',
        time        = 30,
        amount      = 1,
        category    = 'tools',
        materials   = { ['arcane_crystal'] = 1, ['master_lockpick'] = 2 },
        power       = 15,
        description = 'Legendary tier forge recipe - Craftsman\'s Corner.',
        sort        = 160,
    },

    -- ──────────────────────────────────────────────────────────────────
    --  MATERIALS
    -- ──────────────────────────────────────────────────────────────────

    ['fishing_line'] = {
        label       = 'Fishing Line',
        time        = 3,
        amount      = 2,
        category    = 'materials',
        materials   = { ['cloth'] = 2, ['rubber'] = 1 },
        power       = 15,
        description = 'Basic tier forge recipe - Craftsman\'s Corner.',
        sort        = 10,
    },

    ['gold_band'] = {
        label       = 'Gold Band',
        time        = 4,
        amount      = 1,
        category    = 'materials',
        materials   = { ['arcane_dust'] = 5, ['onyx'] = 1 },
        power       = 24,
        description = 'Basic tier forge recipe - Craftsman\'s Corner.',
        sort        = 20,
    },

    ['reinforced_handle'] = {
        label       = 'Reinforced Handle',
        time        = 4,
        amount      = 1,
        category    = 'materials',
        materials   = { ['cobalt_ore'] = 1, ['titanium_alloy'] = 1 },
        power       = 12,
        description = 'Basic tier forge recipe - Craftsman\'s Corner.',
        sort        = 30,
    },

    ['tool_parts'] = {
        label       = 'Tool Parts',
        time        = 5,
        amount      = 1,
        category    = 'materials',
        materials   = { ['mithril_ore'] = 1, ['titanium_alloy'] = 1 },
        power       = 12,
        description = 'Basic tier forge recipe - Craftsman\'s Corner.',
        sort        = 40,
    },

    ['refined_gem'] = {
        label       = 'Refined Gem',
        time        = 8,
        amount      = 1,
        category    = 'materials',
        materials   = { ['arcane_dust'] = 10, ['diamond'] = 1 },
        power       = 39,
        description = 'Advanced tier forge recipe - Craftsman\'s Corner.',
        sort        = 50,
    },

    ['master_weapon_parts'] = {
        label       = 'Master Weapon Parts',
        time        = 18,
        amount      = 1,
        category    = 'materials',
        materials   = { ['mithril_ore'] = 8, ['onyx'] = 3, ['ruby'] = 2, ['titanium_alloy'] = 6 },
        power       = 63,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 60,
    },

    -- ──────────────────────────────────────────────────────────────────
    --  ELECTRONICS
    -- ──────────────────────────────────────────────────────────────────

    ['radio'] = {
        label       = 'Radio',
        time        = 5,
        amount      = 1,
        category    = 'electronics',
        materials   = { ['carbon_fiber'] = 2, ['sapphire'] = 1 },
        power       = 15,
        description = 'Basic tier forge recipe - Downtown Workshop.',
        sort        = 10,
    },

    ['advanced_radio'] = {
        label       = 'Advanced Radio',
        time        = 8,
        amount      = 1,
        category    = 'electronics',
        materials   = { ['arcane_dust'] = 3, ['mithril_ore'] = 2, ['sapphire'] = 2 },
        power       = 27,
        description = 'Advanced tier forge recipe - Downtown Workshop.',
        sort        = 20,
    },

    ['nightvision'] = {
        label       = 'Night Vision Goggles',
        time        = 15,
        amount      = 1,
        category    = 'electronics',
        materials   = { ['dark_glass'] = 3, ['emerald'] = 3, ['rune_core'] = 1 },
        power       = 27,
        description = 'Advanced tier forge recipe - Downtown Workshop.',
        sort        = 30,
    },

    ['hacking_device'] = {
        label       = 'Hacking Device',
        time        = 25,
        amount      = 1,
        category    = 'electronics',
        materials   = { ['arcane_dust'] = 25, ['emerald'] = 3, ['rune_core'] = 2, ['sapphire'] = 5 },
        power       = 111,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 40,
    },

    ['legendary_emp'] = {
        label       = 'Legendary EMP Device',
        time        = 40,
        amount      = 1,
        category    = 'electronics',
        materials   = { ['amethyst'] = 8, ['diamond'] = 3, ['emp_grenade'] = 3, ['rune_core'] = 6 },
        power       = 66,
        description = 'Legendary tier forge recipe - Arcane Sanctum.',
        sort        = 50,
    },

    ['legendary_hacking_suite'] = {
        label       = 'Legendary Hacking Suite',
        time        = 45,
        amount      = 1,
        category    = 'electronics',
        materials   = { ['diamond'] = 5, ['emerald'] = 5, ['hacking_device'] = 2, ['rune_core'] = 8, ['sapphire'] = 5 },
        power       = 81,
        description = 'Legendary tier forge recipe - Arcane Sanctum.',
        sort        = 60,
    },

    -- ──────────────────────────────────────────────────────────────────
    --  MEDICAL
    -- ──────────────────────────────────────────────────────────────────

    ['bandage'] = {
        label       = 'Bandage',
        time        = 2,
        amount      = 2,
        category    = 'medical',
        materials   = { ['cloth'] = 5 },
        power       = 21,
        description = 'Basic tier forge recipe - Downtown Workshop.',
        sort        = 10,
    },

    ['master_medkit'] = {
        label       = 'Master Medkit',
        time        = 15,
        amount      = 1,
        category    = 'medical',
        materials   = { ['amethyst'] = 2, ['arcane_dust'] = 15, ['emerald'] = 3, ['rune_core'] = 1 },
        power       = 69,
        description = 'Master tier forge recipe - Industrial Forge.',
        sort        = 20,
    },

    -- ──────────────────────────────────────────────────────────────────
    --  VEHICLE
    -- ──────────────────────────────────────────────────────────────────

    ['ramp'] = {
        label       = 'Portable Ramp',
        time        = 15,
        amount      = 1,
        category    = 'vehicle',
        materials   = { ['carbon_fiber'] = 8, ['mithril_ore'] = 5, ['titanium_alloy'] = 10 },
        power       = 75,
        description = 'Legendary tier forge recipe - Arcane Sanctum.',
        sort        = 10,
    },

    -- ──────────────────────────────────────────────────────────────────
    --  MISC
    -- ──────────────────────────────────────────────────────────────────

    ['emerald_pendant'] = {
        label       = 'Emerald Pendant',
        time        = 7,
        amount      = 1,
        category    = 'misc',
        materials   = { ['emerald'] = 1, ['gold_band'] = 1 },
        power       = 12,
        description = 'Advanced tier forge recipe - Craftsman\'s Corner.',
        sort        = 10,
    },

    ['ruby_ring'] = {
        label       = 'Ruby Ring',
        time        = 6,
        amount      = 1,
        category    = 'misc',
        materials   = { ['gold_band'] = 1, ['ruby'] = 1 },
        power       = 12,
        description = 'Advanced tier forge recipe - Craftsman\'s Corner.',
        sort        = 20,
    },

    ['diamond_necklace'] = {
        label       = 'Diamond Necklace',
        time        = 15,
        amount      = 1,
        category    = 'misc',
        materials   = { ['diamond'] = 1, ['gold_band'] = 1, ['refined_gem'] = 1 },
        power       = 15,
        description = 'Master tier forge recipe - Craftsman\'s Corner.',
        sort        = 30,
    },

    ['sapphire_bracelet'] = {
        label       = 'Sapphire Bracelet',
        time        = 10,
        amount      = 1,
        category    = 'misc',
        materials   = { ['refined_mithril'] = 1, ['sapphire'] = 2 },
        power       = 15,
        description = 'Master tier forge recipe - Craftsman\'s Corner.',
        sort        = 40,
    },

}
