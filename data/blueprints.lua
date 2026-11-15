-- Blueprint Definitions
-- Blueprints are consumable items that teach players special crafting recipes
-- Each blueprint unlocks one specific recipe when used
-- ENHANCED: More blueprints for all new recipes

return {
    -- ==========================================
    -- BASIC TIER BLUEPRINTS (Green Glow)
    -- Requires Crafting Level 1
    -- ==========================================
    blueprint_lockpick = {
        label = 'Lockpick Blueprint',
        description = 'Learn to craft standard lockpicks',
        recipe = 'lockpick',
        tier = 'basic',
        requiredLevel = 1,
    },

    blueprint_bandage = {
        label = 'Bandage Blueprint',
        description = 'Learn to craft basic medical bandages',
        recipe = 'bandage',
        tier = 'basic',
        requiredLevel = 1,
    },

    blueprint_radio = {
        label = 'Radio Blueprint',
        description = 'Learn to craft communication radios',
        recipe = 'radio',
        tier = 'basic',
        requiredLevel = 1,
    },

    blueprint_repairkit = {
        label = 'Repair Kit Blueprint',
        description = 'Learn to craft vehicle repair kits',
        recipe = 'repairkit',
        tier = 'basic',
        requiredLevel = 1,
    },

    blueprint_flashlight = {
        label = 'Flashlight Blueprint',
        description = 'Learn to craft flashlights',
        recipe = 'flashlight',
        tier = 'basic',
        requiredLevel = 1,
    },

    blueprint_binoculars = {
        label = 'Binoculars Blueprint',
        description = 'Learn to craft binoculars',
        recipe = 'binoculars',
        tier = 'basic',
        requiredLevel = 1,
    },

    blueprint_armor = {
        label = 'Armor Blueprint',
        description = 'Learn to craft standard body armor',
        recipe = 'armor',
        tier = 'basic',
        requiredLevel = 1,
    },

    blueprint_reinforced_handle = {
        label = 'Reinforced Handle Blueprint',
        description = 'Learn to craft reinforced tool handles',
        recipe = 'reinforced_handle',
        tier = 'basic',
        requiredLevel = 1,
    },

    blueprint_fishing_line = {
        label = 'Fishing Line Blueprint',
        description = 'Learn to craft durable fishing lines',
        recipe = 'fishing_line',
        tier = 'basic',
        requiredLevel = 1,
    },

    blueprint_tool_parts = {
        label = 'Tool Parts Blueprint',
        description = 'Learn to craft essential tool components',
        recipe = 'tool_parts',
        tier = 'basic',
        requiredLevel = 1,
    },

    blueprint_gold_band = {
        label = 'Gold Band Blueprint',
        description = 'Learn to craft decorative gold bands',
        recipe = 'gold_band',
        tier = 'basic',
        requiredLevel = 1,
    },

    -- ==========================================
    -- ADVANCED TIER BLUEPRINTS (Blue Glow)
    -- Requires Crafting Level 5+
    -- ==========================================
    blueprint_advanced_lockpick = {
        label = 'Advanced Lockpick Blueprint',
        description = 'Learn to craft superior lockpicks',
        recipe = 'advanced_lockpick',
        tier = 'advanced',
        requiredLevel = 5,
    },

    blueprint_advanced_radio = {
        label = 'Advanced Radio Blueprint',
        description = 'Learn to craft long-range radios',
        recipe = 'advanced_radio',
        tier = 'advanced',
        requiredLevel = 5,
    },

    blueprint_advanced_armor = {
        label = 'Advanced Armor Blueprint',
        description = 'Learn to craft reinforced body armor',
        recipe = 'advanced_armor',
        tier = 'advanced',
        requiredLevel = 8,
    },

    blueprint_advancedrepairkit = {
        label = 'Advanced Repair Kit Blueprint',
        description = 'Learn to craft advanced vehicle repair kits',
        recipe = 'advancedrepairkit',
        tier = 'advanced',
        requiredLevel = 7,
    },

    blueprint_nightvision = {
        label = 'Night Vision Blueprint',
        description = 'Learn to craft night vision goggles',
        recipe = 'nightvision',
        tier = 'advanced',
        requiredLevel = 10,
    },

    blueprint_thermite = {
        label = 'Thermite Blueprint',
        description = 'Learn to craft thermite charges',
        recipe = 'thermite',
        tier = 'advanced',
        requiredLevel = 12,
    },

    -- ==========================================
    -- MASTER TIER BLUEPRINTS (Red Glow)
    -- Requires Crafting Level 15+
    -- ==========================================
    blueprint_master_lockpick = {
        label = 'Master Lockpick Blueprint',
        description = 'Learn to craft unbreakable lockpicks',
        recipe = 'master_lockpick',
        tier = 'master',
        requiredLevel = 15,
    },

    blueprint_master_medkit = {
        label = 'Master Medkit Blueprint',
        description = 'Learn to craft military-grade medkits',
        recipe = 'master_medkit',
        tier = 'master',
        requiredLevel = 16,
    },

    blueprint_master_weapon_parts = {
        label = 'Master Weapon Parts Blueprint',
        description = 'Learn to craft precision weapon components',
        recipe = 'master_weapon_parts',
        tier = 'master',
        requiredLevel = 18,
    },

    blueprint_c4 = {
        label = 'C4 Explosive Blueprint',
        description = 'Learn to craft C4 plastic explosives',
        recipe = 'c4',
        tier = 'master',
        requiredLevel = 20,
    },

    blueprint_hacking_device = {
        label = 'Hacking Device Blueprint',
        description = 'Learn to craft advanced hacking devices',
        recipe = 'hacking_device',
        tier = 'master',
        requiredLevel = 19,
    },

    blueprint_emp_grenade = {
        label = 'EMP Grenade Blueprint',
        description = 'Learn to craft electromagnetic pulse grenades',
        recipe = 'emp_grenade',
        tier = 'master',
        requiredLevel = 17,
    },

    -- ==========================================
    -- LEGENDARY TIER BLUEPRINTS (Gold Glow)
    -- Requires Crafting Level 25+
    -- ==========================================
    blueprint_legendary_toolkit = {
        label = 'Legendary Toolkit Blueprint',
        description = 'Learn to craft the ultimate multi-tool',
        recipe = 'legendary_toolkit',
        tier = 'legendary',
        requiredLevel = 25,
    },

    blueprint_legendary_armor = {
        label = 'Legendary Armor Blueprint',
        description = 'Learn to craft experimental body armor',
        recipe = 'legendary_armor',
        tier = 'legendary',
        requiredLevel = 27,
    },

    blueprint_legendary_hacking_suite = {
        label = 'Legendary Hacking Suite Blueprint',
        description = 'Learn to craft the ultimate hacking suite',
        recipe = 'legendary_hacking_suite',
        tier = 'legendary',
        requiredLevel = 28,
    },

    blueprint_legendary_emp = {
        label = 'Legendary EMP Blueprint',
        description = 'Learn to craft a devastating EMP device',
        recipe = 'legendary_emp',
        tier = 'legendary',
        requiredLevel = 26,
    },

    -- ==========================================
    -- RPG CONTENT PACK BLUEPRINTS
    -- ==========================================

    blueprint_skeleton_key = {
        label = 'Skeleton Key Blueprint',
        description = 'Legendary schematic for the ultimate lockpick',
        recipe = 'skeleton_key',
        tier = 'legendary',
        requiredLevel = 28,
    },

    blueprint_quantum_lockpick = {
        label = 'Quantum Lockpick Blueprint',
        description = 'Legendary schematic for the ultimate lockpick',
        recipe = 'quantum_lockpick',
        tier = 'legendary',
        requiredLevel = 30,
    },

    blueprint_steel_pickaxe = {
        label = 'Steel Pickaxe Blueprint',
        description = 'Schematic for a reinforced mining pickaxe',
        recipe = 'steel_pickaxe',
        tier = 'advanced',
        requiredLevel = 8,
    },

    blueprint_runic_pickaxe = {
        label = 'Runic Pickaxe Blueprint',
        description = 'Ancient schematic for a legendary pickaxe',
        recipe = 'runic_pickaxe',
        tier = 'legendary',
        requiredLevel = 25,
    },

    blueprint_quality_fishing_rod = {
        label = 'Quality Fishing Rod Blueprint',
        description = 'Schematic for professional fishing equipment',
        recipe = 'quality_fishing_rod',
        tier = 'advanced',
        requiredLevel = 6,
    },

    blueprint_salvage_kit = {
        label = 'Salvage Kit Blueprint',
        description = 'Schematic for vehicle salvage tools',
        recipe = 'salvage_kit',
        tier = 'advanced',
        requiredLevel = 10,
    },

    blueprint_master_toolset = {
        label = 'Master Toolset Blueprint',
        description = 'Schematic for premium repair tools',
        recipe = 'master_toolset',
        tier = 'master',
        requiredLevel = 18,
    },

    blueprint_diamond_necklace = {
        label = 'Diamond Necklace Blueprint',
        description = 'Schematic for crafting diamond jewelry',
        recipe = 'diamond_necklace',
        tier = 'master',
        requiredLevel = 15,
    },

    blueprint_ruby_ring = {
        label = 'Ruby Ring Blueprint',
        description = 'Schematic for ruby jewelry',
        recipe = 'ruby_ring',
        tier = 'advanced',
        requiredLevel = 10,
    },

    blueprint_silencer = {
        label = 'Silencer Blueprint',
        description = 'Rare schematic for a weapon suppressor',
        recipe = 'silencer',
        tier = 'legendary',
        requiredLevel = 25,
    },

    blueprint_extended_mag = {
        label = 'Extended Mag Blueprint',
        description = 'Rare schematic for extended magazines',
        recipe = 'extended_mag',
        tier = 'legendary',
        requiredLevel = 25,
    },

    blueprint_drill = {
        label = 'Drill Blueprint',
        description = 'Schematic for a safe-cracking drill',
        recipe = 'drill',
        tier = 'advanced',
        requiredLevel = 8,
    },

    blueprint_gps_tracker = {
        label = 'GPS Tracker Blueprint',
        description = 'Schematic for a covert tracking device',
        recipe = 'gps_tracker',
        tier = 'advanced',
        requiredLevel = 6,
    },

    blueprint_radio_jammer = {
        label = 'Radio Jammer Blueprint',
        description = 'Schematic for a communications jammer',
        recipe = 'radio_jammer',
        tier = 'advanced',
        requiredLevel = 10,
    },

    blueprint_medic_bag = {
        label = 'Medic Bag Blueprint',
        description = 'Schematic for an advanced medical kit',
        recipe = 'medic_bag',
        tier = 'advanced',
        requiredLevel = 8,
    },

    blueprint_thermal_scope = {
        label = 'Thermal Scope Blueprint',
        description = 'Schematic for thermal imaging optics',
        recipe = 'thermal_scope',
        tier = 'master',
        requiredLevel = 15,
    },

    blueprint_explosive_charge = {
        label = 'Explosive Charge Blueprint',
        description = 'Schematic for military breaching charges',
        recipe = 'explosive_charge',
        tier = 'master',
        requiredLevel = 18,
    },

    blueprint_stim_shot = {
        label = 'Stim Shot Blueprint',
        description = 'Formula for combat stimulants',
        recipe = 'stim_shot',
        tier = 'master',
        requiredLevel = 15,
    },

    blueprint_keycard_cloner = {
        label = 'Keycard Cloner Blueprint',
        description = 'Schematic for a keycard duplicator',
        recipe = 'keycard_cloner',
        tier = 'master',
        requiredLevel = 20,
    },

    blueprint_plasma_cutter = {
        label = 'Plasma Cutter Blueprint',
        description = 'Ancient schematic for a legendary cutting tool',
        recipe = 'plasma_cutter',
        tier = 'legendary',
        requiredLevel = 25,
    },

    blueprint_shadow_cloak = {
        label = 'Shadow Cloak Blueprint',
        description = 'Mystical pattern for a cloak of shadows',
        recipe = 'shadow_cloak',
        tier = 'legendary',
        requiredLevel = 28,
    },

    blueprint_revive_syringe = {
        label = 'Revive Syringe Blueprint',
        description = 'Arcane formula for resurrection serum',
        recipe = 'revive_syringe',
        tier = 'legendary',
        requiredLevel = 25,
    },

    blueprint_ramp = {
        label = 'Ramp Blueprint',
        description = 'Legendary schematic for crafting portable ramps',
        recipe = 'ramp',
        tier = 'legendary',
        requiredLevel = 25,
    },

    -- Khan futuristic weapons (Industrial Forge) — level scales with power
    blueprint_WEAPON_ascia = {
        label = 'Ascia Blueprint',
        description = 'Schematic for a futuristic combat axe',
        recipe = 'WEAPON_ascia',
        tier = 'master',
        requiredLevel = 15,
    },
    blueprint_WEAPON_motosega = {
        label = 'Chainsaw Blueprint',
        description = 'Schematic for a brutal motorized saw',
        recipe = 'WEAPON_motosega',
        tier = 'master',
        requiredLevel = 18,
    },
    blueprint_WEAPON_SARATOGA = {
        label = 'Saratoga Blueprint',
        description = 'Schematic for a futuristic SMG',
        recipe = 'WEAPON_SARATOGA',
        tier = 'master',
        requiredLevel = 18,
    },
    blueprint_WEAPON_carnage = {
        label = 'Carnage Blueprint',
        description = 'Schematic for a devastating shotgun',
        recipe = 'WEAPON_carnage',
        tier = 'master',
        requiredLevel = 19,
    },
    blueprint_WEAPON_skippy = {
        label = 'Skippy Blueprint',
        description = 'Schematic for a smart-targeting pistol — rare',
        recipe = 'WEAPON_skippy',
        tier = 'master',
        requiredLevel = 20,
    },
    blueprint_WEAPON_silverhand = {
        label = 'Malorian Arms Blueprint',
        description = 'Schematic for the legendary Malorian Arms 3516',
        recipe = 'WEAPON_silverhand',
        tier = 'master',
        requiredLevel = 22,
    },
    blueprint_WEAPON_MASAMUNE = {
        label = 'Masamune Blueprint',
        description = 'Schematic for a precision futuristic rifle',
        recipe = 'WEAPON_MASAMUNE',
        tier = 'master',
        requiredLevel = 23,
    },
    blueprint_WEAPON_NEKOMATA = {
        label = 'Nekomata Blueprint',
        description = 'Schematic for a dual-barrel sniper — extremely rare',
        recipe = 'WEAPON_NEKOMATA',
        tier = 'legendary',
        requiredLevel = 26,
    },
}
