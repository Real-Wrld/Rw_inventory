-- Crafting Recipes with Premium Materials & Crafting Locations
-- Tier colors: Basic = Green, Advanced = Blue, Master = Red, Legendary = Gold
-- Materials: Gems (Diamond, Ruby, etc.), Fantasy (Rune Core, Mithril, etc.)

return {
	-- ==========================================
	-- DOWNTOWN CRAFTING BENCH
	-- Location: Legion Square area
	-- ==========================================
	{
		name = 'downtown_crafting',
		label = 'Downtown Workshop',
		items = {
			-- ====== BASIC TIER (Green) - Available to all ======
			{
				name = 'lockpick',
				tier = 'basic',
				blueprint = true,
				xpReward = 10,
				ingredients = {
					titanium_alloy = 1,
					carbon_fiber = 1,
				},
				duration = 3000,
				count = 1,
			},
			{
				name = 'bandage',
				tier = 'basic',
				blueprint = true,
				xpReward = 8,
				ingredients = {
					cloth = 5,
				},
				duration = 2000,
				count = 2,
			},
			{
				name = 'radio',
				tier = 'basic',
				blueprint = true,
				xpReward = 15,
				ingredients = {
					sapphire = 1,
					carbon_fiber = 2,
				},
				duration = 5000,
				count = 1,
			},
			{
				name = 'repairkit',
				tier = 'basic',
				blueprint = true,
				xpReward = 12,
				ingredients = {
					titanium_alloy = 2,
					mithril_ore = 1,
				},
				duration = 4000,
				count = 1,
			},
			{
				name = 'flashlight',
				tier = 'basic',
				blueprint = true,
				xpReward = 8,
				ingredients = {
					sapphire = 1,
					dark_glass = 1,
				},
				duration = 3000,
				count = 1,
			},
			{
				name = 'binoculars',
				tier = 'basic',
				blueprint = true,
				xpReward = 15,
				ingredients = {
					dark_glass = 2,
					emerald = 1,
				},
				duration = 5000,
				count = 1,
			},
			{
				name = 'armor',
				tier = 'basic',
				blueprint = true,
				xpReward = 20,
				ingredients = {
					mithril_ore = 2,
					titanium_alloy = 2,
					carbon_fiber = 3,
				},
				duration = 8000,
				count = 1,
			},

			-- ====== ADVANCED TIER (Blue) - Requires Blueprint + Level 5 ======
			{
				name = 'advanced_lockpick',
				tier = 'advanced',
				blueprint = true,
				xpReward = 25,
				ingredients = {
					titanium_alloy = 3,
					ruby = 1,
					arcane_dust = 5,
				},
				duration = 6000,
				count = 2,
				metadata = {
					durability = 150,
				},
			},
			{
				name = 'advanced_radio',
				tier = 'advanced',
				blueprint = true,
				xpReward = 30,
				ingredients = {
					sapphire = 2,
					mithril_ore = 2,
					arcane_dust = 3,
				},
				duration = 8000,
				count = 1,
			},
			{
				name = 'advanced_armor',
				tier = 'advanced',
				blueprint = true,
				xpReward = 40,
				ingredients = {
					mithril_ore = 5,
					onyx = 2,
					carbon_fiber = 5,
				},
				duration = 12000,
				count = 1,
			},
			{
				name = 'advancedrepairkit',
				tier = 'advanced',
				blueprint = true,
				xpReward = 35,
				ingredients = {
					titanium_alloy = 5,
					emerald = 2,
					arcane_dust = 8,
				},
				duration = 8000,
				count = 1,
			},
			{
				name = 'nightvision',
				tier = 'advanced',
				blueprint = true,
				xpReward = 45,
				ingredients = {
					emerald = 3,
					dark_glass = 3,
					rune_core = 1,
				},
				duration = 15000,
				count = 1,
			},
			{
				name = 'thermite',
				tier = 'advanced',
				blueprint = true,
				xpReward = 50,
				ingredients = {
					ruby = 3,
					arcane_dust = 15,
					mithril_ore = 3,
				},
				duration = 10000,
				count = 2,
			},
			-- New RPG Item: Cobalt Lockpick
			{
				name = 'cobalt_lockpick',
				tier = 'advanced',
				blueprint = true,
				xpReward = 35,
				ingredients = {
					cobalt_ore = 2,
					titanium_alloy = 1,
					plastic = 2,
				},
				duration = 5000,
				count = 2,
			},
			-- New RPG Item: Shadow Parachute
			{
				name = 'shadow_parachute',
				tier = 'advanced',
				blueprint = true,
				xpReward = 40,
				ingredients = {
					shadow_silk = 5,
					cloth = 5,
					rubber = 2,
				},
				duration = 8000,
				count = 1,
			},
		},
		zones = {
			{
				coords = vec3(-263.05, -963.69, 31.22),
				size = vec3(2.5, 1.5, 1.0),
				distance = 2.0,
				rotation = 0.0,
				label = 'Downtown Workshop',
			},
		},
		blip = { id = 566, colour = 4, scale = 0.6 },
	},

	-- ==========================================
	-- INDUSTRIAL FORGE
	-- Location: La Mesa industrial area
	-- Specializes in MASTER tier items
	-- ==========================================
	{
		name = 'industrial_forge',
		label = 'Industrial Forge',
		items = {
			-- Basic items also available
			{
				name = 'lockpick',
				tier = 'basic',
				blueprint = true,
				xpReward = 10,
				ingredients = {
					titanium_alloy = 1,
					carbon_fiber = 1,
				},
				duration = 3000,
				count = 1,
			},
			{
				name = 'armor',
				tier = 'basic',
				blueprint = true,
				xpReward = 20,
				ingredients = {
					mithril_ore = 2,
					titanium_alloy = 2,
					carbon_fiber = 3,
				},
				duration = 8000,
				count = 1,
			},

			-- ====== MASTER TIER (Red) - Requires Blueprint + Level 15 ======
			{
				name = 'master_lockpick',
				tier = 'master',
				blueprint = true,
				xpReward = 50,
				ingredients = {
					titanium_alloy = 5,
					diamond = 1,
					rune_core = 1,
					arcane_dust = 20,
				},
				duration = 10000,
				count = 3,
				metadata = {
					durability = 300,
				},
			},
			{
				name = 'master_medkit',
				tier = 'master',
				blueprint = true,
				xpReward = 55,
				ingredients = {
					emerald = 3,
					amethyst = 2,
					rune_core = 1,
					arcane_dust = 15,
				},
				duration = 15000,
				count = 1,
			},
			{
				name = 'master_weapon_parts',
				tier = 'master',
				blueprint = true,
				xpReward = 60,
				ingredients = {
					mithril_ore = 8,
					titanium_alloy = 6,
					onyx = 3,
					ruby = 2,
				},
				duration = 18000,
				count = 1,
			},

			-- ====== FUTURISTIC WEAPONS (Khan) — harder = more materials / higher level ======
			-- T1 melee
			{
				name = 'WEAPON_ascia',
				tier = 'master',
				blueprint = true,
				xpReward = 55,
				ingredients = {
					master_weapon_parts = 1,
					titanium_alloy = 3,
					carbon_fiber = 2,
					onyx = 1,
				},
				duration = 18000,
				count = 1,
				metadata = { registered = false },
			},
			-- T2 melee (brutal)
			{
				name = 'WEAPON_motosega',
				tier = 'master',
				blueprint = true,
				xpReward = 75,
				ingredients = {
					master_weapon_parts = 2,
					titanium_alloy = 8,
					mithril_ore = 6,
					ruby = 3,
					dark_glass = 2,
				},
				duration = 30000,
				count = 1,
				metadata = { registered = false },
			},
			-- T3 SMG
			{
				name = 'WEAPON_SARATOGA',
				tier = 'master',
				blueprint = true,
				xpReward = 90,
				ingredients = {
					master_weapon_parts = 3,
					mithril_ore = 7,
					titanium_alloy = 7,
					onyx = 4,
					arcane_dust = 15,
				},
				duration = 34000,
				count = 1,
				metadata = { registered = false },
			},
			-- T3 shotgun
			{
				name = 'WEAPON_carnage',
				tier = 'master',
				blueprint = true,
				xpReward = 95,
				ingredients = {
					master_weapon_parts = 3,
					mithril_ore = 9,
					ruby = 5,
					dark_glass = 5,
					arcane_dust = 18,
				},
				duration = 36000,
				count = 1,
				metadata = { registered = false },
			},
			-- T4 smart pistol (rare)
			{
				name = 'WEAPON_skippy',
				tier = 'master',
				blueprint = true,
				xpReward = 110,
				ingredients = {
					master_weapon_parts = 4,
					titanium_alloy = 6,
					sapphire = 5,
					emerald = 3,
					rune_core = 2,
					arcane_dust = 35,
				},
				duration = 42000,
				count = 1,
				metadata = { registered = false },
			},
			-- T5 legendary pistol
			{
				name = 'WEAPON_silverhand',
				tier = 'master',
				blueprint = true,
				xpReward = 140,
				ingredients = {
					master_weapon_parts = 6,
					mithril_ore = 12,
					diamond = 4,
					ruby = 4,
					rune_core = 3,
					arcane_dust = 50,
				},
				duration = 55000,
				count = 1,
				metadata = { registered = false },
			},
			-- T5 top rifle
			{
				name = 'WEAPON_MASAMUNE',
				tier = 'master',
				blueprint = true,
				xpReward = 150,
				ingredients = {
					master_weapon_parts = 7,
					mithril_ore = 14,
					titanium_alloy = 12,
					emerald = 5,
					diamond = 2,
					rune_core = 3,
					arcane_dust = 45,
				},
				duration = 60000,
				count = 1,
				metadata = { registered = false },
			},
			-- T6 OP sniper (hardest craft)
			{
				name = 'WEAPON_NEKOMATA',
				tier = 'legendary',
				blueprint = true,
				xpReward = 200,
				ingredients = {
					master_weapon_parts = 10,
					mithril_ore = 18,
					diamond = 6,
					sapphire = 6,
					rune_core = 5,
					arcane_dust = 75,
					dark_glass = 8,
				},
				duration = 75000,
				count = 1,
				metadata = { registered = false },
			},
			{
				name = 'c4',
				tier = 'master',
				blueprint = true,
				xpReward = 75,
				ingredients = {
					ruby = 5,
					arcane_dust = 30,
					rune_core = 2,
					dark_glass = 5,
				},
				duration = 20000,
				count = 1,
			},
			{
				name = 'hacking_device',
				tier = 'master',
				blueprint = true,
				xpReward = 70,
				ingredients = {
					sapphire = 5,
					emerald = 3,
					rune_core = 2,
					arcane_dust = 25,
				},
				duration = 25000,
				count = 1,
			},
			{
				name = 'emp_grenade',
				tier = 'master',
				blueprint = true,
				xpReward = 65,
				ingredients = {
					amethyst = 4,
					rune_core = 2,
					mithril_ore = 5,
					arcane_dust = 20,
				},
				duration = 18000,
				count = 2,
			},
			-- New RPG Item: Infernal Charge
			{
				name = 'infernal_charge',
				tier = 'master',
				blueprint = true,
				xpReward = 80,
				ingredients = {
					infernal_dust = 10,
					runite_ore = 1,
					electronics = 2,
				},
				duration = 15000,
				count = 1,
			},
		},
		zones = {
			{
				coords = vec3(1087.12, -2004.52, 31.25),
				size = vec3(3.0, 2.0, 1.0),
				distance = 2.0,
				rotation = 90.0,
				label = 'Industrial Forge',
			},
		},
		blip = { id = 537, colour = 4, scale = 0.6 },
	},

	-- ==========================================
	-- ARCANE SANCTUM
	-- Location: Pacific Bluffs cemetery area
	-- Specializes in LEGENDARY tier items
	-- ==========================================
	{
		name = 'arcane_sanctum',
		label = 'Arcane Sanctum',
		items = {
			-- Master items also available here
			{
				name = 'hacking_device',
				tier = 'master',
				blueprint = true,
				xpReward = 70,
				ingredients = {
					sapphire = 5,
					emerald = 3,
					rune_core = 2,
					arcane_dust = 25,
				},
				duration = 25000,
				count = 1,
			},

			-- ====== LEGENDARY TIER (Gold) - Requires Blueprint + Level 25 ======
			{
				name = 'legendary_toolkit',
				tier = 'legendary',
				blueprint = true,
				xpReward = 100,
				ingredients = {
					diamond = 2,
					mithril_ore = 10,
					rune_core = 3,
					arcane_dust = 50,
				},
				duration = 25000,
				count = 1,
				metadata = {
					durability = 500,
				},
			},
			{
				name = 'legendary_armor',
				tier = 'legendary',
				blueprint = true,
				xpReward = 150,
				ingredients = {
					diamond = 3,
					mithril_ore = 15,
					rune_core = 5,
					carbon_fiber = 10,
				},
				duration = 30000,
				count = 1,
				metadata = {
					armor = 100,
				},
			},
			{
				name = 'legendary_hacking_suite',
				tier = 'legendary',
				blueprint = true,
				xpReward = 200,
				ingredients = {
					diamond = 5,
					sapphire = 5,
					emerald = 5,
					rune_core = 8,
					hacking_device = 2,
				},
				duration = 45000,
				count = 1,
			},
			{
				name = 'legendary_emp',
				tier = 'legendary',
				blueprint = true,
				xpReward = 175,
				ingredients = {
					diamond = 3,
					amethyst = 8,
					rune_core = 6,
					emp_grenade = 3,
				},
				duration = 40000,
				count = 1,
			},
			-- New RPG Item: Runite Blade
			{
				name = 'runite_blade',
				tier = 'legendary',
				blueprint = true,
				xpReward = 250,
				ingredients = {
					runite_ore = 5,
					adamantite_ore = 2,
					diamond = 1,
					leather = 2, -- Assuming leather handles
				},
				duration = 60000,
				count = 1,
			},
			-- Portable Ramp for stunts
			{
				name = 'ramp',
				tier = 'legendary',
				blueprint = true,
				xpReward = 100,
				ingredients = {
					titanium_alloy = 10,
					carbon_fiber = 8,
					mithril_ore = 5,
				},
				duration = 15000,
				count = 1,
			},
		},
		zones = {
			{
				coords = vec3(-1712.55, -186.92, 57.69),
				size = vec3(2.0, 2.0, 1.0),
				distance = 2.0,
				rotation = 45.0,
				label = 'Arcane Sanctum',
			},
		},
		blip = { id = 310, colour = 4, scale = 0.6 },
	},

	-- ==========================================
	-- SANDY SHORES WORKSHOP
	-- Location: Sandy Shores airfield
	-- General purpose, all basic + some advanced
	-- ==========================================
	{
		name = 'sandy_workshop',
		label = 'Desert Workshop',
		items = {
			{
				name = 'lockpick',
				tier = 'basic',
				blueprint = true,
				xpReward = 10,
				ingredients = {
					titanium_alloy = 1,
					carbon_fiber = 1,
				},
				duration = 3000,
				count = 1,
			},
			{
				name = 'bandage',
				tier = 'basic',
				blueprint = true,
				xpReward = 8,
				ingredients = {
					cloth = 5,
				},
				duration = 2000,
				count = 2,
			},
			{
				name = 'repairkit',
				tier = 'basic',
				blueprint = true,
				xpReward = 12,
				ingredients = {
					titanium_alloy = 2,
					mithril_ore = 1,
				},
				duration = 4000,
				count = 1,
			},
			{
				name = 'armor',
				tier = 'basic',
				blueprint = true,
				xpReward = 20,
				ingredients = {
					mithril_ore = 2,
					titanium_alloy = 2,
					carbon_fiber = 3,
				},
				duration = 8000,
				count = 1,
			},
			-- Some advanced items
			{
				name = 'advanced_lockpick',
				tier = 'advanced',
				blueprint = true,
				xpReward = 25,
				ingredients = {
					titanium_alloy = 3,
					ruby = 1,
					arcane_dust = 5,
				},
				duration = 6000,
				count = 2,
			},
			{
				name = 'thermite',
				tier = 'advanced',
				blueprint = true,
				xpReward = 50,
				ingredients = {
					ruby = 3,
					arcane_dust = 15,
					mithril_ore = 3,
				},
				duration = 10000,
				count = 2,
			},
			-- New RPG Item: Adamantite Armor
			{
				name = 'adamantite_armor',
				tier = 'master', -- Higher tier available in desert
				blueprint = true,
				xpReward = 100,
				ingredients = {
					adamantite_ore = 5,
					titanium_alloy = 5,
					shadow_silk = 3,
				},
				duration = 20000,
				count = 1,
				metadata = {
					armor = 100,
				},
			},
		},
		zones = {
			{
				coords = vec3(1746.62, 3293.01, 41.11),
				size = vec3(2.5, 1.5, 1.0),
				distance = 2.0,
				rotation = 30.0,
				label = 'Desert Workshop',
			},
		},
		blip = { id = 566, colour = 4, scale = 0.6 },
	},

	-- ==========================================
	-- PALETO BAY WORKSHOP
	-- Location: Paleto Bay
	-- General purpose, remote location bonus
	-- ==========================================
	{
		name = 'paleto_workshop',
		label = 'Northern Workshop',
		items = {
			{
				name = 'lockpick',
				tier = 'basic',
				blueprint = true,
				xpReward = 10,
				ingredients = {
					titanium_alloy = 1,
					carbon_fiber = 1,
				},
				duration = 3000,
				count = 1,
			},
			{
				name = 'repairkit',
				tier = 'basic',
				blueprint = true,
				xpReward = 12,
				ingredients = {
					titanium_alloy = 2,
					mithril_ore = 1,
				},
				duration = 4000,
				count = 1,
			},
			{
				name = 'advanced_armor',
				tier = 'advanced',
				blueprint = true,
				xpReward = 40,
				ingredients = {
					mithril_ore = 5,
					onyx = 2,
					carbon_fiber = 5,
				},
				duration = 12000,
				count = 1,
			},
			{
				name = 'nightvision',
				tier = 'advanced',
				blueprint = true,
				xpReward = 45,
				ingredients = {
					emerald = 3,
					dark_glass = 3,
					rune_core = 1,
				},
				duration = 15000,
				count = 1,
			},
		},
		zones = {
			{
				coords = vec3(-174.89, 6168.04, 31.57),
				size = vec3(2.0, 1.5, 1.0),
				distance = 2.0,
				rotation = 45.0,
				label = 'Northern Workshop',
			},
		},
		blip = { id = 566, colour = 4, scale = 0.6 },
	},

	-- ==========================================
	-- CRAFTSMAN'S CORNER (Content Pack 2)
	-- Location: Textile City - Component Crafting
	-- ==========================================
	{
		name = 'craftsmans_corner',
		label = "Craftsman's Corner",
		items = {
			-- ====== ENTRY LEVEL - No Blueprint Required ======
			{
				name = 'pickaxe',
				tier = 'basic',
				xpReward = 5,
				requiredLevel = 0, -- Anyone can craft this!
				ingredients = {
					steel = 2,
					aluminum = 3,
				},
				duration = 4000,
				count = 1,
			},
			-- Intermediate Components
			{
				name = 'reinforced_handle',
				tier = 'basic',
				blueprint = true,
				xpReward = 12,
				ingredients = {
					cobalt_ore = 1,
					titanium_alloy = 1,
				},
				duration = 4000,
				count = 1,
			},
			{
				name = 'fishing_line',
				tier = 'basic',
				blueprint = true,
				xpReward = 8,
				ingredients = {
					cloth = 2,
					rubber = 1,
				},
				duration = 3000,
				count = 2,
			},
			{
				name = 'tool_parts',
				tier = 'basic',
				blueprint = true,
				xpReward = 15,
				ingredients = {
					mithril_ore = 1,
					titanium_alloy = 1,
				},
				duration = 5000,
				count = 1,
			},
			{
				name = 'gold_band',
				tier = 'basic',
				blueprint = true,
				xpReward = 10,
				ingredients = {
					arcane_dust = 5,
					onyx = 1,
				},
				duration = 4000,
				count = 1,
			},
			{
				name = 'refined_gem',
				tier = 'advanced',
				blueprint = true,
				xpReward = 25,
				ingredients = {
					arcane_dust = 10,
					diamond = 1,
				},
				duration = 8000,
				count = 1,
			},
			-- Upgraded Mining Tools
			{
				name = 'steel_pickaxe',
				tier = 'advanced',
				blueprint = true,
				xpReward = 35,
				ingredients = {
					reinforced_handle = 1,
					refined_mithril = 2,
				},
				duration = 10000,
				count = 1,
			},
			{
				name = 'runic_pickaxe',
				tier = 'legendary',
				blueprint = true,
				xpReward = 100,
				ingredients = {
					steel_pickaxe = 1,
					runite_ore = 1,
					rune_core = 1,
				},
				duration = 25000,
				count = 1,
			},
			-- Fishing Upgrades
			{
				name = 'quality_fishing_rod',
				tier = 'advanced',
				blueprint = true,
				xpReward = 30,
				ingredients = {
					fishing_rod = 1,
					fishing_line = 2,
					emerald = 1,
				},
				duration = 8000,
				count = 1,
			},
			-- Utility Tools
			{
				name = 'salvage_kit',
				tier = 'advanced',
				blueprint = true,
				xpReward = 40,
				ingredients = {
					tool_parts = 1,
					electronics = 2,
				},
				duration = 10000,
				count = 1,
			},
			{
				name = 'master_toolset',
				tier = 'master',
				blueprint = true,
				xpReward = 65,
				ingredients = {
					tool_parts = 2,
					diamond = 1,
				},
				duration = 18000,
				count = 1,
			},
			{
				name = 'skeleton_key',
				tier = 'legendary',
				blueprint = true,
				xpReward = 120,
				ingredients = {
					master_lockpick = 2,
					arcane_crystal = 1,
				},
				duration = 30000,
				count = 1,
			},
			-- Sellable Jewelry
			{
				name = 'ruby_ring',
				tier = 'advanced',
				blueprint = true,
				xpReward = 25,
				ingredients = {
					ruby = 1,
					gold_band = 1,
				},
				duration = 6000,
				count = 1,
			},
			{
				name = 'emerald_pendant',
				tier = 'advanced',
				blueprint = true,
				xpReward = 30,
				ingredients = {
					emerald = 1,
					gold_band = 1,
				},
				duration = 7000,
				count = 1,
			},
			{
				name = 'sapphire_bracelet',
				tier = 'master',
				blueprint = true,
				xpReward = 45,
				ingredients = {
					sapphire = 2,
					refined_mithril = 1,
				},
				duration = 10000,
				count = 1,
			},
			{
				name = 'diamond_necklace',
				tier = 'master',
				blueprint = true,
				xpReward = 60,
				ingredients = {
					diamond = 1,
					gold_band = 1,
					refined_gem = 1,
				},
				duration = 15000,
				count = 1,
			},
		},
		zones = {
			{
				coords = vec3(712.34, -962.18, 30.39),
				size = vec3(2.5, 2.0, 1.0),
				distance = 2.0,
				rotation = 0.0,
				label = "Craftsman's Corner",
			},
		},
		blip = { id = 566, colour = 4, scale = 0.6 },
	},
}
