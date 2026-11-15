if not lib then return end

local CraftingBenches = {}
local Items = require 'modules.items.client'
local createBlip = require 'modules.utils.client'.CreateBlip
local Utils = require 'modules.utils.client'
local markerColour = { 150, 150, 30 }
local prompt = {
	options = { icon = 'fa-wrench' },
	message = ('**%s**  \n%s'):format(locale('open_crafting_bench'),
		locale('interact_prompt', GetControlInstructionalButton(0, 38, true):sub(3)))
}

-- Current crafting state
local currentBenchId = nil
local currentBenchIndex = nil
local isCraftingActive = false

-- Configuration
local CRAFTING_DURATION_MULTIPLIER = 2.0 -- Multiply all crafting durations by this value (default: 2x longer)

-- Open the custom forge crafting UI
local function openForgeCraftingUI(benchId, benchIndex, benchData, craftingData)
	currentBenchId = benchId
	currentBenchIndex = benchIndex

	-- Prepare recipes with item data
	local recipes = {}
	for i, recipe in ipairs(benchData.items or {}) do
		local item = Items(recipe.name)
		recipes[i] = {
			name = recipe.name,
			label = item and item.label or recipe.name,
			tier = recipe.tier or 'basic',
			requiredLevel = recipe.requiredLevel, -- Pass explicitly (nil if not defined)
			blueprint = recipe.blueprint or false,
			xpReward = recipe.xpReward or 10,
			ingredients = recipe.ingredients or {},
			duration = recipe.duration or 5000,
			count = recipe.count or 1,
			weight = recipe.weight or 0,
			slot = recipe.slot or i,
		}
	end

	-- Fetch existing forge orders for this bench
	local orders = lib.callback.await('ox_inventory:getForgeOrders', false, benchId)

	-- Debug: log crafting data being sent to UI
	local learnedRecipes = craftingData and craftingData.learnedRecipes or {}

	-- Sync live player inventory into NUI for material counts — silent so the
	-- personal inventory panel does not cover the forge UI.
	local playerItems = exports.ox_inventory:GetPlayerItems() or {}
	SendNUIMessage({
		action = 'setupInventory',
		data = {
			silent = true,
			leftInventory = {
				id = 'player',
				type = 'player',
				slots = shared.playerslots or 50,
				weight = 0,
				maxWeight = shared.playerweight or 30000,
				items = playerItems,
			}
		}
	})

	-- Send NUI message to open custom forge UI
	SendNUIMessage({
		action = 'openCrafting',
		data = {
			benchId = benchId,
			benchLabel = benchData.label or 'Crafting Bench',
			recipes = recipes,
			xp = craftingData and craftingData.xp or 0,
			level = craftingData and craftingData.level or 1,
			xpForNextLevel = craftingData and craftingData.xpForNextLevel or 100,
			relativeXP = craftingData and craftingData.relativeXP or 0,
			relativeNextLevelXP = craftingData and craftingData.relativeNextLevelXP or 100,
			learnedRecipes = craftingData and craftingData.learnedRecipes or {},
			activeOrders = orders and orders.active or {},
			completedOrders = orders and orders.completed or {},
		}
	})

	-- Enable NUI focus so mouse works immediately
	SetNuiFocus(true, true)

	-- Show notification
	lib.notify({
		title = benchData.label or 'Crafting Bench',
		description = 'Crafting station opened',
		type = 'inform',
		duration = 2000,
	})
end

-- Handle crafting bench interaction
local function interactWithBench(benchId, benchIndex)
	-- Request crafting data from server
	local result = lib.callback.await('ox_inventory:openCraftingBench', false, benchId, benchIndex)

	if result then
		local benchData = CraftingBenches[benchId]
		if benchData then
			openForgeCraftingUI(benchId, benchIndex, benchData, result.craftingData)
		end
	end
end

---@param id number
---@param data table
local function createCraftingBench(id, data)
	CraftingBenches[id] = {}
	local recipes = data.items

	if recipes then
		data.slots = #recipes

		for i = 1, data.slots do
			local recipe = recipes[i]
			local item = Items(recipe.name)

			if item then
				recipe.weight = item.weight
				recipe.slot = i
			else
				warn(('failed to setup crafting recipe (bench: %s, slot: %s) - item "%s" does not exist'):format(id, i,
					recipe.name))
			end
		end

		local blip = data.blip

		if blip then
			blip.name = blip.name or ('ox_crafting_%s'):format(data.label and id or 0)
			AddTextEntry(blip.name, data.label or locale('crafting_bench'))
		end

		if shared.target then
			data.points = nil
			if data.zones then
				for i = 1, #data.zones do
					local zone = data.zones[i]
					zone.name = ("craftingbench_%s:%s"):format(id, i)
					zone.id = id
					zone.index = i

					-- Spawn workbench prop if model is specified
					local modelName = zone.model or data.model or 'prop_tool_bench02'

					-- Helper to check if model is valid (checking CdImage is safer for custom props)
					local function isValidModel(model)
						if not model then return false end
						local hash = type(model) == 'number' and model or GetHashKey(model)
						return IsModelInCdimage(hash) or IsModelValid(hash)
					end

					-- Prefer vanilla bench if custom forge assets aren't streamed
					if not isValidModel(modelName) then
						modelName = 'prop_tool_bench02'
					end

					if modelName and isValidModel(modelName) then
						lib.requestModel(modelName)
						local prop = CreateObject(modelName, zone.coords.x, zone.coords.y, zone.coords.z - 1.0, false,
							false,
							false)
						if DoesEntityExist(prop) then
							SetEntityHeading(prop, zone.rotation or 0.0)
							FreezeEntityPosition(prop, true)
							SetEntityCollision(prop, true, true)
							PlaceObjectOnGroundProperly(prop)
							CraftingBenches[id].props = CraftingBenches[id].props or {}
							CraftingBenches[id].props[i] = prop
						end
					end

					zone.options = {
						{
							label = zone.label or locale('open_crafting_bench'),
							canInteract = data.groups and function()
								return client.hasGroup(data.groups)
							end or nil,
							onSelect = function()
								-- Use custom forge UI instead of standard inventory
								interactWithBench(id, i)
							end,
							distance = zone.distance or 2.0,
							icon = zone.icon or 'fas fa-hammer',
						}
					}

					exports.ox_target:addBoxZone(zone)

					if blip then
						createBlip(blip, zone.coords)
					end
				end
			end
		elseif data.points then
			data.zones = nil

			for i = 1, #data.points do
				local coords = data.points[i]

				lib.points.new({
					coords = coords,
					distance = 16,
					benchid = id,
					index = i,
					inv = 'crafting',
					prompt = prompt,
					marker = markerColour,
					nearby = Utils.nearbyMarker
				})

				if blip then
					createBlip(blip, coords)
				end
			end
		end

		CraftingBenches[id] = data
	end
end

-- NUI Callbacks for crafting
RegisterNUICallback('closeCrafting', function(_, cb)
	currentBenchId = nil
	currentBenchIndex = nil
	isCraftingActive = false
	SetNuiFocus(false, false) -- Release mouse control
	cb(1)
end)

RegisterNUICallback('forgeCraftItem', function(data, cb)
	local recipeSlot = data.recipeSlot or data.slot -- Accept both parameter names
	if not currentBenchId or not recipeSlot then
		cb({ success = false, reason = 'invalid_state' })
		return
	end

	local benchData = CraftingBenches[currentBenchId]
	if not benchData then
		cb({ success = false, reason = 'invalid_bench' })
		return
	end

	local recipe = benchData.items[recipeSlot]
	if not recipe then
		cb({ success = false, reason = 'invalid_recipe' })
		return
	end

	-- Notify crafting started
	local itemData = Items(recipe.name)
	lib.notify({
		title = 'Crafting',
		description = 'Started crafting ' .. (itemData and itemData.label or recipe.name),
		type = 'inform',
		icon = 'hammer',
		duration = 3000,
	})

	isCraftingActive = true

	-- Request server to craft (this handles the progress bar)
	local success, reason = lib.callback.await('ox_inventory:craftItem', false,
		currentBenchId, currentBenchIndex, recipeSlot, data.toSlot)

	isCraftingActive = false

	if success then
		local craftedItemData = Items(recipe.name)
		lib.notify({
			title = 'Crafting Complete!',
			description = 'Successfully crafted ' .. (craftedItemData and craftedItemData.label or recipe.name),
			type = 'success',
			icon = 'check',
			duration = 4000,
		})
		cb({ success = true })
	else
		-- Map reason codes to user-friendly messages
		local errorMessages = {
			cannot_carry = 'Not enough space in inventory',
			cancelled = 'Crafting was cancelled',
			missing_ingredient = 'You are missing required ingredients',
			not_enough_ingredients = 'You don\'t have enough of the required materials',
			ingredient_removed = 'Materials were removed from your inventory',
			slot_empty = 'Error: inventory state changed unexpectedly',
			remove_failed = 'Failed to use crafting materials',
			no_inventory = 'Inventory error - please try again',
			invalid_bench = 'Invalid crafting bench',
			no_permission = 'You are not allowed to use this bench',
			too_far = 'You are too far from the crafting bench',
			invalid_recipe = 'Invalid recipe selected',
			cannot_craft = 'You cannot craft this recipe (missing blueprint or level)',
			item_not_found = 'Error: crafted item does not exist in database',
		}

		local errorMsg = errorMessages[reason] or ('Failed to craft item: ' .. tostring(reason))

		lib.notify({
			title = 'Crafting Failed',
			description = errorMsg,
			type = 'error',
			icon = 'xmark',
			duration = 4000,
		})
		cb({ success = false, reason = reason })
	end
end)

-- Submit forge order (background crafting)
RegisterNUICallback('submitForgeOrder', function(data, cb)
	if not currentBenchId or not data.queue or #data.queue == 0 then
		cb({ success = false, reason = 'invalid_state' })
		return
	end

	local success, reason = lib.callback.await('ox_inventory:submitForgeOrder', false,
		currentBenchId, currentBenchIndex, data.queue)

	if success then
		-- Refresh orders and send to UI
		local orders = lib.callback.await('ox_inventory:getForgeOrders', false, currentBenchId)
		SendNUIMessage({
			action = 'updateOrders',
			data = {
				activeOrders = orders and orders.active or {},
				completedOrders = orders and orders.completed or {},
			}
		})
	else
		lib.notify({
			title = 'Forge Order Failed',
			description = reason == 'missing_materials' and 'Not enough materials'
				or reason == 'cannot_craft' and 'Cannot craft this item'
				or 'Failed to submit order',
			type = 'error',
			duration = 3000,
		})
	end

	cb({ success = success, reason = reason })
end)

-- Collect completed forge order (supports partial collection from batched orders)
RegisterNUICallback('collectOrder', function(data, cb)
	if not data.orderId then
		cb({ success = false, reason = 'invalid_order' })
		return
	end

	-- Pass itemIndex for partial collection (defaults to 1 if not provided)
	local success, reason = lib.callback.await('ox_inventory:collectForgeOrder', false, data.orderId, data.itemIndex or 1)

	if success then
		-- Refresh orders
		local orders = lib.callback.await('ox_inventory:getForgeOrders', false, currentBenchId)
		SendNUIMessage({
			action = 'updateOrders',
			data = {
				activeOrders = orders and orders.active or {},
				completedOrders = orders and orders.completed or {},
			}
		})
	else
		lib.notify({
			title = 'Collection Failed',
			description = reason == 'cannot_carry' and 'Inventory is full'
				or reason == 'order_not_ready' and 'Order not ready yet'
				or 'Failed to collect',
			type = 'error',
			duration = 3000,
		})
	end

	cb({ success = success, reason = reason })
end)

-- Collect all completed orders
RegisterNUICallback('collectAllOrders', function(_, cb)
	if not currentBenchId then
		cb({ success = false, reason = 'invalid_state' })
		return
	end

	local success, reason = lib.callback.await('ox_inventory:collectAllForgeOrders', false, currentBenchId)

	if success then
		-- Refresh orders
		local orders = lib.callback.await('ox_inventory:getForgeOrders', false, currentBenchId)
		SendNUIMessage({
			action = 'updateOrders',
			data = {
				activeOrders = orders and orders.active or {},
				completedOrders = orders and orders.completed or {},
			}
		})
	else
		lib.notify({
			title = 'Collection Failed',
			description = reason == 'cannot_carry_all' and 'Cannot carry all items'
				or reason == 'no_orders' and 'No completed orders'
				or 'Failed to collect',
			type = 'error',
			duration = 3000,
		})
	end

	cb({ success = success, reason = reason })
end)

-- Refresh orders (for countdown updates)
RegisterNUICallback('refreshOrders', function(_, cb)
	if not currentBenchId then
		cb({ success = false })
		return
	end

	local orders = lib.callback.await('ox_inventory:getForgeOrders', false, currentBenchId)
	SendNUIMessage({
		action = 'updateOrders',
		data = {
			activeOrders = orders and orders.active or {},
			completedOrders = orders and orders.completed or {},
		}
	})
	cb({ success = true })
end)

-- Cancel a forge order
RegisterNUICallback('cancelOrder', function(data, cb)
	if not data.orderId then
		cb({ success = false, reason = 'invalid_order' })
		return
	end

	local success, refundPercent = lib.callback.await('ox_inventory:cancelForgeOrder', false, data.orderId)

	if success then
		-- Refresh orders
		local orders = lib.callback.await('ox_inventory:getForgeOrders', false, currentBenchId)
		SendNUIMessage({
			action = 'updateOrders',
			data = {
				activeOrders = orders and orders.active or {},
				completedOrders = orders and orders.completed or {},
			}
		})
	end

	cb({ success = success, refundPercent = refundPercent })
end)

-- Get forge capacity
RegisterNUICallback('getCapacity', function(_, cb)
	local capacity = lib.callback.await('ox_inventory:getForgeCapacity', false)
	cb(capacity or { current = 0, max = 5, level = 1, bonusSlots = 0, masteryBonus = 0 })
end)

-- Toggle favorite recipe
RegisterNUICallback('toggleFavorite', function(data, cb)
	if not currentBenchId or not data.recipeName then
		cb({ success = false })
		return
	end

	local isFavorited = lib.callback.await('ox_inventory:toggleFavorite', false, currentBenchId, data.recipeName)
	cb({ success = true, isFavorited = isFavorited })
end)

-- Get player's favorite recipes
RegisterNUICallback('getFavorites', function(_, cb)
	if not currentBenchId then
		cb({})
		return
	end

	local favorites = lib.callback.await('ox_inventory:getRecipeFavorites', false, currentBenchId)
	cb(favorites or {})
end)

-- Get crafting settings
RegisterNUICallback('getCraftSettings', function(_, cb)
	local settings = lib.callback.await('ox_inventory:getCraftSettings', false)
	cb(settings or { autoCollect = false, soundEnabled = true })
end)

-- Update crafting setting
RegisterNUICallback('updateCraftSetting', function(data, cb)
	if not data.setting then
		cb({ success = false })
		return
	end

	local success = lib.callback.await('ox_inventory:updateCraftSettings', false, data.setting, data.value)
	cb({ success = success })
end)

-- Get forge history
RegisterNUICallback('getForgeHistory', function(data, cb)
	if not currentBenchId then
		cb({})
		return
	end

	local history = lib.callback.await('ox_inventory:getForgeHistory', false, currentBenchId, data.limit or 20)
	cb(history or {})
end)

-- Client callback for crafting progress bar
lib.callback.register('ox_inventory:startCrafting', function(benchId, recipeId)
	-- Validate inputs
	if not benchId or not recipeId then
		return false
	end

	local benchData = CraftingBenches[benchId]
	if not benchData then
		return false
	end

	if not benchData.items then
		return false
	end

	local recipe = benchData.items[recipeId]
	if not recipe then
		return false
	end

	-- Request animation dict
	lib.requestAnimDict('mini@repair')

	-- Use ox_lib progress bar with duration multiplier
	local recipeItem = Items(recipe.name)
	local recipeLabel = recipeItem and recipeItem.label or recipe.name
	local baseDuration = recipe.duration or 5000
	local adjustedDuration = math.floor(baseDuration * CRAFTING_DURATION_MULTIPLIER)

	local success = lib.progressBar({
		duration = adjustedDuration,
		label = 'Forging ' .. recipeLabel .. '...',
		useWhileDead = false,
		canCancel = true,
		disable = {
			move = true,
			car = true,
			combat = true,
		},
		anim = {
			dict = 'mini@repair',
			clip = 'fixing_a_player',
			flag = 49,
		},
	})

	-- Clear animation
	ClearPedTasks(PlayerPedId())

	if success then
		-- Send NUI update for completion animation
		SendNUIMessage({
			action = 'craftingComplete',
			data = {
				recipeName = recipe.name,
				xpGained = recipe.xpReward or 10,
			}
		})
	end

	return success
end)

-- Listen for blueprint learned events
RegisterNetEvent('ox_inventory:blueprintLearned', function(data)
	-- Celebration modal is handled in NUI (non-blocking, auto-dismiss)
	SendNUIMessage({
		action = 'blueprintLearned',
		data = {
			recipe = data.recipe,
			label = data.label or data.recipe,
			tier = data.tier or 'basic',
		}
	})
end)

-- Listen for crafting XP gain
RegisterNetEvent('ox_inventory:craftingXPGain', function(data)
	-- Update the UI with new XP (action must match App.tsx useNuiEvent listener)
	SendNUIMessage({
		action = 'craftingXPGain',
		data = {
			xp = data.totalXP,
			level = data.level,
			xpForNextLevel = data.xpForNextLevel,
			relativeXP = data.relativeXP or 0,
			relativeNextLevelXP = data.relativeNextLevelXP or 0,
		}
	})
end)

-- Listen for crafting level up
RegisterNetEvent('ox_inventory:craftingLevelUp', function(data)
	lib.notify({
		title = 'Level Up!',
		description = 'You reached Crafting Level ' .. data.newLevel .. '!',
		type = 'success',
		icon = 'star',
		duration = 6000,
	})

	-- Update the UI
	SendNUIMessage({
		action = 'updateXP',
		data = {
			xp = data.totalXP,
			level = data.newLevel,
		}
	})
end)

for id, data in pairs(lib.load('data.crafting') or {}) do createCraftingBench(data.name or id, data) end

-- Forge world props open benches by id (see modules/forge/client.lua)
RegisterNetEvent('ox_inventory:openCrafting', function(benchId, _)
	interactWithBench(benchId, 1)
end)

return CraftingBenches
