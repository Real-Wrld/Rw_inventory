if not lib then return end

local CraftingBenches = {}
local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'
local BlueprintSystem = require 'modules.crafting.blueprints'

---@param id number
---@param data table
local function createCraftingBench(id, data)
	CraftingBenches[id] = {}
	local recipes = data.items

	if recipes then
		for i = 1, #recipes do
			local recipe = recipes[i]
			local item = Items(recipe.name)

			if item then
				recipe.weight = item.weight
				recipe.slot = i
			else
				warn(('failed to setup crafting recipe (bench: %s, slot: %s) - item "%s" does not exist'):format(id, i,
					recipe.name))
			end

			for ingredient, needs in pairs(recipe.ingredients) do
				if needs < 1 then
					item = Items(ingredient)

					if item and not item.durability then
						item.durability = true
					end
				end
			end
		end

		if shared.target then
			data.points = nil
		else
			data.zones = nil
		end

		CraftingBenches[id] = data
	end
end

CreateThread(function()
	while not shared.ready do Wait(100) end
	for id, data in pairs(lib.load('data.crafting') or {}) do
		createCraftingBench(data.name or id, data)
		Wait(0)
	end
end)

---falls back to player coords if zones and points are both nil
---@param source number
---@param bench table
---@param index number
---@return vector3
local function getCraftingCoords(source, bench, index)
	if not bench.zones and not bench.points then
		return GetEntityCoords(GetPlayerPed(source))
	else
		return shared.target and bench.zones[index].coords or bench.points[index]
	end
end

lib.callback.register('ox_inventory:openCraftingBench', function(source, id, index)
	local left, bench = Inventory(source), CraftingBenches[id]

	if not left then return end

	if bench then
		local groups = bench.groups
		local coords = getCraftingCoords(source, bench, index)

		if not coords then return end

		if groups and not server.hasGroup(left, groups) then return end
		if #(GetEntityCoords(GetPlayerPed(source)) - coords) > 10 then return end

		if left.open and left.open ~= source then
			local inv = Inventory(left.open) --[[@as OxInventory]]

			-- Why would the player inventory open with an invalid target? Can't repro but whatever.
			if inv?.player then
				inv:closeInventory()
			end
		end

		left:openInventory(left)
	end

	-- Get player crafting data for UI (compute all fields explicitly to avoid serialization issues)
	local craftingData = nil
	if BlueprintSystem and BlueprintSystem.GetPlayerCraftingData then
		local rawData = BlueprintSystem.GetPlayerCraftingData(source)
		if rawData then
			-- Compute relative XP values (same logic as getCraftingData callback)
			local LEVEL_XP = BlueprintSystem.LEVEL_XP
			local currentLevelBaseXP = LEVEL_XP and LEVEL_XP[rawData.level] or 0
			local nextLevelTotalXP = BlueprintSystem.GetXPForNextLevel and BlueprintSystem.GetXPForNextLevel(rawData.level) or 100
			local xpProgress = rawData.xp - currentLevelBaseXP
			local xpRequiredForLevel = nextLevelTotalXP - currentLevelBaseXP

			-- Build a clean crafting data object (no internal fields like 'identifier')
			-- Ensure learnedRecipes is always a table (defensive against nil)
			local learnedRecipes = rawData.learnedRecipes
			if type(learnedRecipes) ~= 'table' then
				learnedRecipes = {}
			end


			craftingData = {
				xp = rawData.xp or 0,
				level = rawData.level or 1,
				xpForNextLevel = nextLevelTotalXP,
				relativeXP = xpProgress,
				relativeNextLevelXP = xpRequiredForLevel,
				learnedRecipes = learnedRecipes,
			}
		end
	end

	return {
		label = left.label,
		type = left.type,
		slots = left.slots,
		weight = left.weight,
		maxWeight = left.maxWeight,
		craftingData = craftingData
	}
end)

local TriggerEventHooks = require 'modules.hooks.server'

-- Load anti-cheat module for rate limiting
local AntiCheat = lib.load('modules.anticheat.server')

lib.callback.register('ox_inventory:craftItem', function(source, id, index, recipeId, toSlot)

	-- Rate limit check
	if AntiCheat and AntiCheat.CheckRateLimit then
		local allowed, remaining = AntiCheat.CheckRateLimit(source, 'craft')
		if not allowed then
			return false, 'rate_limited'
		end
	end

	local left, bench = Inventory(source), CraftingBenches[id]

	if not left then
		return false, 'no_inventory'
	end

	if not bench then
		return false, 'invalid_bench'
	end

	local groups = bench.groups
	local coords = getCraftingCoords(source, bench, index)

	if groups and not server.hasGroup(left, groups) then
		return false, 'no_permission'
	end

	local playerCoords = GetEntityCoords(GetPlayerPed(source))
	local distance = #(playerCoords - coords)
	if distance > 10 then
		return false, 'too_far'
	end

	local recipe = bench.items[recipeId]

	if not recipe then
		return false, 'invalid_recipe'
	end


	-- Check if player can craft this recipe (blueprint/level requirements)
	if BlueprintSystem and BlueprintSystem.CanCraftRecipe then
		local canCraft, reason = BlueprintSystem.CanCraftRecipe(source, recipe)
		if not canCraft then
			return false, reason or 'cannot_craft'
		end
	else
	end

	local tbl, num = {}, 0

	for name in pairs(recipe.ingredients) do
		num += 1
		tbl[num] = name
	end

	local craftedItem = Items(recipe.name)
	if not craftedItem then
		return false, 'item_not_found'
	end

	local craftCount = (type(recipe.count) == 'number' and recipe.count) or
		(table.type(recipe.count) == 'array' and math.random(recipe.count[1], recipe.count[2])) or 1

	-- Modified weight calculation
	local newWeight = left.weight
	local items = Inventory.Search(left, 'slots', tbl) or {}
	---@todo new iterator or something to accept a map
	-- First subtract weight of ingredients that will be removed
	for name, needs in pairs(recipe.ingredients) do
		if needs > 0 then
			local item = Items(name)
			if item then
				newWeight -= (item.weight * needs)
			end
		end
	end

	-- Add weight of crafted item
	newWeight += (craftedItem.weight + (recipe.metadata?.weight or 0)) * craftCount

	if newWeight > left.maxWeight then
		return false, 'cannot_carry'
	end

	local items = Inventory.Search(left, 'slots', tbl) or {}
	table.wipe(tbl)

	for name, needs in pairs(recipe.ingredients) do
		if needs == 0 then break end

		local slots = items[name] or items

		if #slots == 0 then
			return false, 'missing_ingredient'
		end

		for i = 1, #slots do
			local slot = slots[i]

			if needs == 0 then
				if not slot.metadata.durability or slot.metadata.durability > 0 then
					break
				end
			elseif needs < 1 then
				local item = Items(name)
				local durability = slot.metadata.durability

				if durability and durability >= needs * 100 then
					if durability > 100 then
						local degrade = (slot.metadata.degrade or item.degrade) * 60
						local percentage = ((durability - os.time()) * 100) / degrade

						if percentage >= needs * 100 then
							tbl[slot.slot] = needs
							break
						end
					else
						tbl[slot.slot] = needs
						break
					end
				end
			elseif needs <= slot.count then
				tbl[slot.slot] = needs
				break
			else
				tbl[slot.slot] = slot.count
				needs -= slot.count
			end

			if needs == 0 then break end
			-- Player does not have enough items (ui should prevent crafting if lacking items, so this shouldn't trigger)
			if needs > 0 and i == #slots then
				return false, 'not_enough_ingredients'
			end
		end
	end

	if not TriggerEventHooks('craftItem', {
			source = source,
			benchId = id,
			benchIndex = index,
			recipe = recipe,
			toInventory = left.id,
			toSlot = toSlot,
		}) then
		return false, 'hook_blocked'
	end

	local success = lib.callback.await('ox_inventory:startCrafting', source, id, recipeId)

	if success then
		for name, needs in pairs(recipe.ingredients) do
			if Inventory.GetItemCount(left, name) < needs then
				return false, 'ingredient_removed'
			end
		end

		for slot, count in pairs(tbl) do
			local invSlot = left.items[slot]

			if not invSlot then
				return false, 'slot_empty'
			end

			if count < 1 then
				local item = Items(invSlot.name)
				local durability = invSlot.metadata.durability or 100

				if durability > 100 then
					local degrade = (invSlot.metadata.degrade or item.degrade) * 60
					durability -= degrade * count
				else
					durability -= count * 100
				end

				if invSlot.count > 1 then
					local emptySlot = Inventory.GetEmptySlot(left)

					if emptySlot then
						local newItem = Inventory.SetSlot(left, item, 1, table.deepclone(invSlot.metadata),
							emptySlot)

						if newItem then
							Items.UpdateDurability(left, newItem, item, durability < 0 and 0 or durability)
						end
					end

					invSlot.count -= 1
					invSlot.weight = Inventory.SlotWeight(item, invSlot)

					left:syncSlotsWithClients({
						{
							item = invSlot,
							inventory = left.id
						}
					}, true)
				else
					Items.UpdateDurability(left, invSlot, item, durability < 0 and 0 or durability)
				end
			else
				local removed = invSlot and Inventory.RemoveItem(left, invSlot.name, count, nil, slot)
				-- Failed to remove item (inventory state unexpectedly changed?)
				if not removed then
					return false, 'remove_failed'
				end
			end
		end

		Inventory.AddItem(left, craftedItem, craftCount, recipe.metadata or {},
			craftedItem.stack and toSlot or nil)

		-- Award crafting XP
		if BlueprintSystem and BlueprintSystem.AddCraftingXP and recipe.xpReward then
			BlueprintSystem.AddCraftingXP(source, recipe.xpReward)
		end

		-- Track crafting statistics
		local CraftingStats = lib.load('modules.statistics.server')
		if CraftingStats and CraftingStats.TrackCraft then
			CraftingStats.TrackCraft(source, craftedItem.name, craftCount, recipe.tier)
		end
	else
	end

	return success
end)

-- ==========================================
-- BACKGROUND FORGE ORDER SYSTEM
-- ==========================================

-- Tier-based crafting durations (milliseconds)
local TIER_DURATIONS = {
	basic = 30000,   -- 30 seconds
	advanced = 60000, -- 1 minute
	master = 180000, -- 3 minutes
	legendary = 300000, -- 5 minutes
}

-- Forge configuration
local FORGE_CONFIG = {
	maxActiveOrders = 5,       -- Base order limit
	maxPerLevel = 10,          -- +1 slot per X levels
	maxQueueItems = 10,        -- Max items per submission
	rushSpeedMultiplier = 2,   -- Rush orders are 2x faster
	rushMaterialMultiplier = 1.5, -- Rush costs 50% more materials
}

-- Mastery bonuses (time reduction based on level)
local MASTERY_BONUSES = {
	{ level = 10,  reduction = 0.10 }, -- 10% faster at level 10
	{ level = 25,  reduction = 0.20 }, -- 20% faster at level 25
	{ level = 50,  reduction = 0.30 }, -- 30% faster at level 50
	{ level = 75,  reduction = 0.40 }, -- 40% faster at level 75
	{ level = 100, reduction = 0.50 }, -- 50% faster at level 100
}

-- Quality tiers for crafted items
local QUALITY_CONFIG = {
	tiers = {
		{ name = 'standard',   chance = 60, statBonus = 0 },
		{ name = 'superior',   chance = 25, statBonus = 10 },
		{ name = 'masterwork', chance = 12, statBonus = 25 },
		{ name = 'legendary',  chance = 3,  statBonus = 50 },
	},
	levelBonus = 0.002, -- +0.2% better quality chance per level
}

-- Get mastery time reduction for a player level
local function getMasteryBonus(level)
	local reduction = 0
	for _, bonus in ipairs(MASTERY_BONUSES) do
		if level >= bonus.level then
			reduction = bonus.reduction
		end
	end
	return reduction
end

-- Roll quality tier based on player level
local function rollQuality(playerLevel)
	local levelBonus = (playerLevel or 1) * QUALITY_CONFIG.levelBonus
	local roll = math.random() * 100
	local cumulative = 0

	-- Iterate from worst to best quality
	for i = #QUALITY_CONFIG.tiers, 1, -1 do
		local tier = QUALITY_CONFIG.tiers[i]
		local adjustedChance = tier.chance
		if i > 1 then -- Boost non-standard quality with level
			adjustedChance = adjustedChance + (levelBonus * (5 - i))
		end
		cumulative = cumulative + adjustedChance
		if roll <= cumulative then
			return tier.name
		end
	end
	return 'standard'
end

-- Helper: Get recipe from bench by slot
local function getRecipeFromBench(benchId, recipeSlot)
	local bench = CraftingBenches[benchId]
	if not bench or not bench.items then return nil end
	return bench.items[recipeSlot]
end

-- Helper: Get recipe by name (for collecting)
local function getRecipeByName(benchId, recipeName)
	local bench = CraftingBenches[benchId]
	if not bench or not bench.items then return nil end
	for _, recipe in ipairs(bench.items) do
		if recipe.name == recipeName then
			return recipe
		end
	end
	return nil
end

-- Helper: Get player identifier
local function getPlayerIdentifier(source)
	return GetPlayerIdentifierByType(source, 'license') or tostring(source)
end

-- ==========================================
-- ORDER COMPLETION NOTIFICATIONS (timer-driven)
-- ==========================================

local notifiedOrders = {}
local scheduledTimers = {}
local licenseSources = {}

local function cachePlayerLicense(source)
	local license = GetPlayerIdentifierByType(source, 'license')
	if license then
		licenseSources[license] = source
	end
	return license
end

local function getOnlineSourceByLicense(owner)
	local cached = licenseSources[owner]
	if cached and GetPlayerName(cached) then
		return cached
	end

	for _, playerId in ipairs(GetPlayers()) do
		local src = tonumber(playerId)
		if src and getPlayerIdentifier(src) == owner then
			licenseSources[owner] = src
			return src
		end
	end
end

local function getOrderItemLabel(order)
	local bench = CraftingBenches[order.bench_id]
	local label = order.recipe_name

	if bench and bench.items then
		for _, recipe in ipairs(bench.items) do
			if recipe.name == order.recipe_name then
				local item = Items(recipe.name)
				if item then label = item.label end
				break
			end
		end
	end

	return label
end

local function notifyForgeComplete(order)
	if not order or notifiedOrders[order.id] then return end

	local source = getOnlineSourceByLicense(order.owner)
	if not source then return end

	TriggerClientEvent('ox_lib:notify', source, {
		title = 'Forge Complete!',
		description = ('%dx %s is ready for pickup!'):format(order.quantity, getOrderItemLabel(order)),
		type = 'success',
		icon = 'check-circle',
		duration = 8000,
	})

	notifiedOrders[order.id] = os.time() * 1000
end

local function clearOrderSchedule(orderId)
	scheduledTimers[orderId] = nil
	notifiedOrders[orderId] = nil
end

local function scheduleOrderNotification(order)
	if not order or scheduledTimers[order.id] or notifiedOrders[order.id] then return end
	if order.collected or order.cancelled then return end

	local now = os.time() * 1000
	local delay = math.max(0, order.end_time - now)
	scheduledTimers[order.id] = true

	SetTimeout(delay, function()
		scheduledTimers[order.id] = nil

		local row = MySQL.single.await([[
			SELECT id, owner, recipe_name, quantity, bench_id, collected, cancelled
			FROM ox_forge_orders
			WHERE id = ?
		]], { order.id })

		if row and not row.collected and not row.cancelled then
			notifyForgeComplete(row)
		end
	end)
end

local function hydrateForgeSchedules()
	local now = os.time() * 1000
	local pending = MySQL.query.await([[
		SELECT id, owner, recipe_name, quantity, bench_id, end_time, collected, cancelled
		FROM ox_forge_orders
		WHERE collected = FALSE AND cancelled = FALSE
		ORDER BY end_time ASC
		LIMIT 500
	]])

	for _, order in ipairs(pending or {}) do
		if order.end_time <= now then
			-- Avoid notifying stale orders from months ago on restart
			if now - order.end_time < 3600000 then
				notifyForgeComplete(order)
			end
		else
			scheduleOrderNotification(order)
		end
	end
end

local function cleanupForgeOrders()
	MySQL.update('DELETE FROM ox_forge_orders WHERE collected = TRUE AND created_at < DATE_SUB(NOW(), INTERVAL 7 DAY)')
	MySQL.update('DELETE FROM ox_forge_orders WHERE cancelled = TRUE AND created_at < DATE_SUB(NOW(), INTERVAL 3 DAY)')
end

local function ensureForgeIndexes()
	MySQL.query('SHOW INDEX FROM `ox_forge_orders` WHERE Key_name = ?', { 'idx_forge_active_end' }, function(result)
		if not result or #result == 0 then
			MySQL.query('CREATE INDEX `idx_forge_active_end` ON `ox_forge_orders` (`collected`, `cancelled`, `end_time`)')
		end
	end)
end

AddEventHandler('playerDropped', function()
	local src = source
	for license, cached in pairs(licenseSources) do
		if cached == src then
			licenseSources[license] = nil
		end
	end
end)

AddEventHandler('ox_inventory:setPlayerInventory', function(player)
	local src = type(player) == 'table' and (player.source or player.id) or player
	src = tonumber(src)
	if not src then return end

	local license = cachePlayerLicense(src)
	if not license then return end

	SetTimeout(2500, function()
		if not GetPlayerName(src) then return end

		local now = os.time() * 1000
		local orders = MySQL.query.await([[
			SELECT id, owner, recipe_name, quantity, bench_id, end_time
			FROM ox_forge_orders
			WHERE owner = ? AND collected = FALSE AND cancelled = FALSE AND end_time <= ?
			ORDER BY end_time ASC
			LIMIT 20
		]], { license, now })

		for _, order in ipairs(orders or {}) do
			notifyForgeComplete(order)
		end
	end)
end)

MySQL.ready(function()
	CreateThread(function()
		Wait(5000)
		ensureForgeIndexes()
		cleanupForgeOrders()
		hydrateForgeSchedules()

		for _, playerId in ipairs(GetPlayers()) do
			cachePlayerLicense(tonumber(playerId))
		end
	end)

	CreateThread(function()
		while true do
			Wait(3600000)
			cleanupForgeOrders()

			local now = os.time() * 1000
			for orderId, notifyTime in pairs(notifiedOrders) do
				if now - notifyTime > 3600000 then
					notifiedOrders[orderId] = nil
				end
			end
		end
	end)
end)

-- Submit a forge order (materials consumed, order stored in DB)
lib.callback.register('ox_inventory:submitForgeOrder', function(source, benchId, benchIndex, queue)
	local left = Inventory(source)
	local bench = CraftingBenches[benchId]

	if not left or not bench then return false, 'invalid_bench' end

	-- Validate distance
	local coords = getCraftingCoords(source, bench, benchIndex)
	if coords and #(GetEntityCoords(GetPlayerPed(source)) - coords) > 10 then
		return false, 'too_far'
	end

	-- Calculate total materials needed for entire queue
	local totalMaterials = {}
	local totalWeight = 0

	for _, item in ipairs(queue) do
		local recipe = getRecipeFromBench(benchId, item.recipeSlot)
		if not recipe then return false, 'invalid_recipe' end

		-- Check blueprint/level requirements
		if BlueprintSystem and BlueprintSystem.CanCraftRecipe then
			local canCraft, reason = BlueprintSystem.CanCraftRecipe(source, recipe)
			if not canCraft then
				return false, reason or 'cannot_craft'
			end
		end

		-- Accumulate materials
		for mat, qty in pairs(recipe.ingredients) do
			totalMaterials[mat] = (totalMaterials[mat] or 0) + (qty * item.quantity)
		end

		-- Calculate weight change
		local craftedItem = Items(recipe.name)
		if craftedItem then
			totalWeight = totalWeight + (craftedItem.weight * (recipe.count or 1) * item.quantity)
		end
	end

	-- Validate player has all materials
	for mat, qty in pairs(totalMaterials) do
		if Inventory.GetItemCount(left, mat) < qty then
			return false, 'missing_materials'
		end
	end

	-- Check if player can carry all the results
	local newWeight = left.weight - totalWeight -- Materials removed
	for _, item in ipairs(queue) do
		local recipe = getRecipeFromBench(benchId, item.recipeSlot)
		local craftedItem = Items(recipe.name)
		if craftedItem then
			newWeight = newWeight + (craftedItem.weight * (recipe.count or 1) * item.quantity)
		end
	end
	-- Note: Weight check happens at collection time since orders persist

	-- Remove all materials NOW
	for mat, qty in pairs(totalMaterials) do
		Inventory.RemoveItem(left, mat, qty)
	end

	-- Insert orders into database and track totals for notification
	local identifier = getPlayerIdentifier(source)
	local now = os.time() * 1000
	local totalItems = 0
	local maxEndTime = now
	local orderNames = {}

	for _, item in ipairs(queue) do
		local recipe = getRecipeFromBench(benchId, item.recipeSlot)
		local tier = recipe.tier or 'basic'
		local baseDuration = (TIER_DURATIONS[tier] or TIER_DURATIONS.basic)

		-- Insert single order with full quantity (optimized: 1 row per batch)
		local endTime = now + baseDuration
		local orderId = MySQL.insert.await(
			'INSERT INTO ox_forge_orders (owner, bench_id, recipe_name, quantity, start_time, end_time) VALUES (?, ?, ?, ?, ?, ?)',
			{ identifier, benchId, recipe.name, item.quantity, now, endTime })

		scheduleOrderNotification({
			id = orderId,
			owner = identifier,
			recipe_name = recipe.name,
			quantity = item.quantity,
			bench_id = benchId,
			end_time = endTime,
			collected = false,
			cancelled = false,
		})

		if endTime > maxEndTime then
			maxEndTime = endTime
		end

		totalItems = totalItems + item.quantity

		-- Get item label for notification
		local craftedItem = Items(recipe.name)
		local label = craftedItem and craftedItem.label or recipe.name
		table.insert(orderNames, ('%dx %s'):format(item.quantity, label))
	end

	-- Calculate total time for display
	local totalTimeMs = maxEndTime - now
	local totalSeconds = math.floor(totalTimeMs / 1000)
	local timeText
	if totalSeconds >= 60 then
		local mins = math.floor(totalSeconds / 60)
		local secs = totalSeconds % 60
		timeText = secs > 0 and ('%dm %ds'):format(mins, secs) or ('%dm'):format(mins)
	else
		timeText = ('%ds'):format(totalSeconds)
	end

	-- Notify player with details
	TriggerClientEvent('ox_lib:notify', source, {
		title = '🔥 Forge Started!',
		description = ('Forging %d item%s\nEstimated time: %s'):format(
			totalItems,
			totalItems > 1 and 's' or '',
			timeText
		),
		type = 'success',
		icon = 'fire',
		duration = 6000,
	})

	-- Send individual item notifications (max 3 to avoid spam)
	local itemsToShow = math.min(#orderNames, 3)
	for i = 1, itemsToShow do
		SetTimeout(i * 500, function()
			TriggerClientEvent('ox_lib:notify', source, {
				title = 'Forging...',
				description = orderNames[i],
				type = 'inform',
				icon = 'hammer',
				duration = 3000,
			})
		end)
	end

	if #orderNames > 3 then
		SetTimeout(2000, function()
			TriggerClientEvent('ox_lib:notify', source, {
				title = 'Forging...',
				description = ('...and %d more item%s'):format(#orderNames - 3, (#orderNames - 3) > 1 and 's' or ''),
				type = 'inform',
				icon = 'hammer',
				duration = 3000,
			})
		end)
	end

	return true
end)

-- Get player's forge orders (active and completed)
lib.callback.register('ox_inventory:getForgeOrders', function(source, benchId)
	local identifier = getPlayerIdentifier(source)
	local now = os.time() * 1000

	local orders = MySQL.query.await([[
		SELECT id, recipe_name, quantity, start_time, end_time
		FROM ox_forge_orders
		WHERE owner = ? AND bench_id = ? AND collected = FALSE AND cancelled = FALSE
	]], { identifier, benchId })

	local active, completed = {}, {}

	for _, order in ipairs(orders or {}) do
		local recipe = getRecipeByName(benchId, order.recipe_name)
		local recipeLabel = recipe and Items(recipe.name) and Items(recipe.name).label or order.recipe_name
		local tier = recipe and recipe.tier or 'basic'
		local isReady = order.end_time <= now

		-- Expand quantity into virtual entries for UI slide-out animation
		for i = 1, order.quantity do
			local orderData = {
				id = order.id,
				itemIndex = i, -- Which item in the batch (for partial collection)
				recipeName = order.recipe_name,
				recipeLabel = recipeLabel,
				tier = tier,
				quantity = 1,       -- UI sees individual items
				totalQuantity = order.quantity, -- Original batch size for reference
				startTime = order.start_time,
				endTime = order.end_time,
				isReady = isReady,
			}

			if isReady then
				table.insert(completed, orderData)
			else
				table.insert(active, orderData)
			end
		end
	end

	return { active = active, completed = completed }
end)

-- Collect a completed forge order (supports partial collection from batches)
lib.callback.register('ox_inventory:collectForgeOrder', function(source, orderId, itemIndex)
	local identifier = getPlayerIdentifier(source)
	local now = os.time() * 1000
	local left = Inventory(source)

	if not left then return false end

	local order = MySQL.single.await([[
		SELECT * FROM ox_forge_orders
		WHERE id = ? AND owner = ? AND end_time <= ? AND collected = FALSE
	]], { orderId, identifier, now })

	if not order then return false, 'order_not_ready' end

	-- Find recipe for weight/count info
	local recipe = getRecipeByName(order.bench_id, order.recipe_name)
	local craftedItem = Items(order.recipe_name)

	if not craftedItem then return false, 'invalid_item' end

	-- Calculate items to add (1 item from batch)
	local craftCount = recipe and recipe.count or 1

	-- Check weight
	local addWeight = craftedItem.weight * craftCount
	if left.weight + addWeight > left.maxWeight then
		return false, 'cannot_carry'
	end

	-- Add crafted items
	Inventory.AddItem(left, craftedItem.name, craftCount)

	-- Award crafting XP (proportional)
	if BlueprintSystem and BlueprintSystem.AddCraftingXP and recipe and recipe.xpReward then
		BlueprintSystem.AddCraftingXP(source, recipe.xpReward)
	end

	-- Decrement quantity or mark as collected
	if order.quantity > 1 then
		MySQL.update('UPDATE ox_forge_orders SET quantity = quantity - 1 WHERE id = ?', { orderId })
	else
		MySQL.update('UPDATE ox_forge_orders SET collected = TRUE WHERE id = ?', { orderId })
		clearOrderSchedule(orderId)
	end

	-- Notify
	local label = craftedItem.label or order.recipe_name
	TriggerClientEvent('ox_lib:notify', source, {
		title = 'Item Collected',
		description = ('Received %dx %s'):format(craftCount, label),
		type = 'success',
		duration = 3000,
	})

	return true
end)

-- Collect all completed orders at once
lib.callback.register('ox_inventory:collectAllForgeOrders', function(source, benchId)
	local identifier = getPlayerIdentifier(source)
	local now = os.time() * 1000
	local left = Inventory(source)

	if not left then return false end

	local orders = MySQL.query.await([[
		SELECT * FROM ox_forge_orders
		WHERE owner = ? AND bench_id = ? AND end_time <= ? AND collected = FALSE AND cancelled = FALSE
	]], { identifier, benchId, now })

	if not orders or #orders == 0 then return false, 'no_orders' end

	-- Calculate total weight first
	local totalWeight = 0
	for _, order in ipairs(orders) do
		local craftedItem = Items(order.recipe_name)
		local recipe = getRecipeByName(order.bench_id, order.recipe_name)
		local craftCount = (recipe and recipe.count or 1) * order.quantity
		if craftedItem then
			totalWeight = totalWeight + (craftedItem.weight * craftCount)
		end
	end

	if left.weight + totalWeight > left.maxWeight then
		return false, 'cannot_carry_all'
	end

	-- Process all orders
	local totalXP = 0
	local collectedItems = {}

	for _, order in ipairs(orders) do
		local craftedItem = Items(order.recipe_name)
		local recipe = getRecipeByName(order.bench_id, order.recipe_name)
		local craftCount = (recipe and recipe.count or 1) * order.quantity

		if craftedItem then
			Inventory.AddItem(left, craftedItem.name, craftCount)

			local label = craftedItem.label or order.recipe_name
			collectedItems[label] = (collectedItems[label] or 0) + craftCount

			if recipe and recipe.xpReward then
				totalXP = totalXP + (recipe.xpReward * order.quantity)
			end
		end

		MySQL.update('UPDATE ox_forge_orders SET collected = TRUE WHERE id = ?', { order.id })
		clearOrderSchedule(order.id)
	end

	-- Award XP
	if BlueprintSystem and BlueprintSystem.AddCraftingXP and totalXP > 0 then
		BlueprintSystem.AddCraftingXP(source, totalXP)
	end

	-- Build notification message
	local itemList = {}
	for label, count in pairs(collectedItems) do
		table.insert(itemList, ('%dx %s'):format(count, label))
	end

	TriggerClientEvent('ox_lib:notify', source, {
		title = 'All Items Collected!',
		description = table.concat(itemList, ', '),
		type = 'success',
		duration = 5000,
	})

	return true
end)

-- ==========================================
-- PHASE 14: CANCEL ORDER
-- ==========================================
lib.callback.register('ox_inventory:cancelForgeOrder', function(source, orderId)
	local identifier = getPlayerIdentifier(source)
	local now = os.time() * 1000

	-- Get the order
	local order = MySQL.single.await([[
		SELECT * FROM ox_forge_orders
		WHERE id = ? AND owner = ? AND collected = FALSE AND cancelled = FALSE
	]], { orderId, identifier })

	if not order then
		return false, 'order_not_found'
	end

	-- Calculate progress percentage
	local elapsed = now - order.start_time
	local duration = order.end_time - order.start_time
	local progress = math.min(100, (elapsed / duration) * 100)

	-- Calculate refund percentage based on progress
	local refundPercent
	if progress < 25 then
		refundPercent = 0.75 -- 75% refund
	elseif progress < 50 then
		refundPercent = 0.50 -- 50% refund
	elseif progress < 75 then
		refundPercent = 0.25 -- 25% refund
	else
		refundPercent = 0 -- No refund, too late
	end

	-- Mark as cancelled
	MySQL.update.await('UPDATE ox_forge_orders SET cancelled = TRUE WHERE id = ?', { orderId })
	clearOrderSchedule(orderId)

	-- Refund materials if applicable
	if refundPercent > 0 then
		local bench = CraftingBenches[order.bench_id]
		local recipe = getRecipeByName(order.bench_id, order.recipe_name)
		local inventory = Inventory(source)

		if recipe and inventory then
			local refundedItems = {}
			for material, amount in pairs(recipe.ingredients) do
				local refundAmount = math.floor(amount * order.quantity * refundPercent)
				if refundAmount > 0 then
					Inventory.AddItem(inventory, material, refundAmount)
					local item = Items(material)
					table.insert(refundedItems, ('%dx %s'):format(refundAmount, item and item.label or material))
				end
			end

			if #refundedItems > 0 then
				TriggerClientEvent('ox_lib:notify', source, {
					title = 'Order Cancelled',
					description = ('Refunded: %s'):format(table.concat(refundedItems, ', ')),
					type = 'inform',
					icon = 'rotate-left',
					duration = 5000,
				})
			end
		end
	else
		TriggerClientEvent('ox_lib:notify', source, {
			title = 'Order Cancelled',
			description = 'Too late for refund (over 75% complete)',
			type = 'warning',
			duration = 4000,
		})
	end

	return true, refundPercent
end)

-- ==========================================
-- PHASE 14: CAPACITY CHECK
-- ==========================================
lib.callback.register('ox_inventory:getForgeCapacity', function(source)
	local identifier = getPlayerIdentifier(source)

	-- Get player level for capacity bonus
	local level = 1
	if BlueprintSystem and BlueprintSystem.GetCraftingLevel then
		level = BlueprintSystem.GetCraftingLevel(source) or 1
	end

	local baseCapacity = FORGE_CONFIG.maxActiveOrders
	local bonusSlots = math.floor(level / FORGE_CONFIG.maxPerLevel)
	local maxCapacity = baseCapacity + bonusSlots

	-- Count current active orders
	local activeCount = MySQL.scalar.await([[
		SELECT COUNT(*) FROM ox_forge_orders
		WHERE owner = ? AND collected = FALSE AND cancelled = FALSE
	]], { identifier }) or 0

	return {
		current = activeCount,
		max = maxCapacity,
		level = level,
		bonusSlots = bonusSlots,
		masteryBonus = getMasteryBonus(level),
	}
end)

-- ==========================================
-- PHASE 15: FAVORITES
-- ==========================================
lib.callback.register('ox_inventory:getRecipeFavorites', function(source, benchId)
	local identifier = getPlayerIdentifier(source)

	local favorites = MySQL.query.await([[
		SELECT recipe_name FROM ox_recipe_favorites
		WHERE owner = ? AND bench_id = ?
	]], { identifier, benchId })

	local result = {}
	if favorites then
		for _, fav in ipairs(favorites) do
			result[fav.recipe_name] = true
		end
	end
	return result
end)

lib.callback.register('ox_inventory:toggleFavorite', function(source, benchId, recipeName)
	local identifier = getPlayerIdentifier(source)

	-- Check if already favorited
	local existing = MySQL.scalar.await([[
		SELECT id FROM ox_recipe_favorites
		WHERE owner = ? AND bench_id = ? AND recipe_name = ?
	]], { identifier, benchId, recipeName })

	if existing then
		-- Remove favorite
		MySQL.query.await('DELETE FROM ox_recipe_favorites WHERE id = ?', { existing })
		return false -- Now unfavorited
	else
		-- Add favorite
		MySQL.insert.await([[
			INSERT INTO ox_recipe_favorites (owner, bench_id, recipe_name)
			VALUES (?, ?, ?)
		]], { identifier, benchId, recipeName })
		return true -- Now favorited
	end
end)

-- ==========================================
-- PHASE 16: PLAYER SETTINGS
-- ==========================================
lib.callback.register('ox_inventory:getCraftSettings', function(source)
	local identifier = getPlayerIdentifier(source)

	local settings = MySQL.single.await([[
		SELECT * FROM ox_player_craft_settings WHERE owner = ?
	]], { identifier })

	if not settings then
		-- Create default settings
		MySQL.insert.await([[
			INSERT INTO ox_player_craft_settings (owner) VALUES (?)
		]], { identifier })
		return { autoCollect = false, soundEnabled = true }
	end

	return {
		autoCollect = settings.auto_collect == 1,
		soundEnabled = settings.sound_enabled == 1,
	}
end)

lib.callback.register('ox_inventory:updateCraftSettings', function(source, setting, value)
	local identifier = getPlayerIdentifier(source)
	local column = setting == 'autoCollect' and 'auto_collect' or 'sound_enabled'

	MySQL.update.await(([[
		INSERT INTO ox_player_craft_settings (owner, %s)
		VALUES (?, ?)
		ON DUPLICATE KEY UPDATE %s = VALUES(%s)
	]]):format(column, column, column), { identifier, value and 1 or 0 })

	return true
end)

-- ==========================================
-- PHASE 16: FORGE HISTORY
-- ==========================================
lib.callback.register('ox_inventory:getForgeHistory', function(source, benchId, limit)
	local identifier = getPlayerIdentifier(source)
	limit = limit or 20

	local history = MySQL.query.await([[
		SELECT id, recipe_name, quantity, start_time, end_time, quality, created_at
		FROM ox_forge_orders
		WHERE owner = ? AND bench_id = ? AND collected = TRUE AND cancelled = FALSE
		ORDER BY end_time DESC
		LIMIT ?
	]], { identifier, benchId, limit })

	if not history then return {} end

	-- Enrich with item labels
	local result = {}
	for _, order in ipairs(history) do
		local recipe = getRecipeByName(benchId, order.recipe_name)
		local item = Items(order.recipe_name)
		table.insert(result, {
			id = order.id,
			recipeName = order.recipe_name,
			recipeLabel = item and item.label or order.recipe_name,
			quantity = order.quantity,
			startTime = order.start_time,
			endTime = order.end_time,
			quality = order.quality,
			createdAt = order.created_at,
		})
	end

	return result
end)
