if not lib then return end

local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'
local AdminShops = require 'modules.shops.admin_server'
local Shops = {}
local locations = shared.target and 'targets' or 'locations'

---@class OxShopItem
---@field slot number
---@field weight number

local function setupShopItems(id, shopType, shopName, groups)
	local shop = id and Shops[shopType][id] or Shops[shopType] --[[@as OxShop]]

	for i = 1, shop.slots do
		local slot = shop.items[i]

		if slot.grade and not groups then
			slot.grade = nil
		end

		local Item = Items(slot.name)

		if Item then
			---@type OxShopItem
			slot = {
				name = Item.name,
				slot = i,
				weight = Item.weight,
				count = slot.count,
				price = (server.randomprices and (not slot.currency or slot.currency == 'money')) and (math.ceil(slot.price * (math.random(80, 120)/100))) or slot.price or 0,
				metadata = slot.metadata,
				license = slot.license,
				currency = slot.currency,
				grade = slot.grade
			}

			if slot.metadata then
				slot.weight = Inventory.SlotWeight(Item, slot, true)
			end

			shop.items[i] = slot
		end
	end
end

---@param shopType string
---@param properties OxShop
local function registerShopType(shopType, properties)
	local shopLocations = properties[locations] or properties.locations

	if shopLocations then
		Shops[shopType] = properties
	else
		Shops[shopType] = {
			label = properties.name,
			id = shopType,
			groups = properties.groups or properties.jobs,
			items = properties.inventory,
			slots = #properties.inventory,
			type = 'shop',
		}

		setupShopItems(nil, shopType, properties.name, properties.groups or properties.jobs)
	end
end

---@param shopType string
---@param id number
local function createShop(shopType, id)
	local shop = Shops[shopType]

	if not shop then return end

	local store = (shop[locations] or shop.locations)?[id]

	if not store then return end

	local groups = shop.groups or shop.jobs
    local coords

    if shared.target then
        if store.length then
            local z = store.loc.z + math.abs(store.minZ - store.maxZ) / 2
            coords = vec3(store.loc.x, store.loc.y, z)
        else
            coords = store.coords or store.loc
        end
    else
        coords = store
    end

	shop[id] = {
		label = shop.name,
		id = shopType..' '..id,
		groups = groups,
		items = table.clone(shop.inventory),
		slots = #shop.inventory,
		type = 'shop',
		coords = coords,
		distance = shared.target and shop.targets?[id]?.distance,
	}

	setupShopItems(id, shopType, shop.name, groups)

	return shop[id]
end

for shopType, shopDetails in pairs(lib.load('data.shops') or {}) do
	registerShopType(shopType, shopDetails)
end

---@param shopType string
---@param shopDetails OxShop
exports('RegisterShop', function(shopType, shopDetails)
	registerShopType(shopType, shopDetails)
end)

lib.callback.register('ox_inventory:openShop', function(source, data)
	local left, shop = Inventory(source)

	if not left then return end

	if data then
		shop = Shops[data.type]

		if not shop then return end

		if not shop.items then
			shop = (data.id and shop[data.id] or createShop(data.type, data.id))

			if not shop then return end
		end

		---@cast shop OxShop

		if shop.groups then
			local group = server.hasGroup(left, shop.groups)
			if not group then return end
		end

		if type(shop.coords) == 'vector3' and #(GetEntityCoords(GetPlayerPed(source)) - shop.coords) > 10 then
			return
		end

		---@diagnostic disable-next-line: assign-type-mismatch
		left:openInventory(left)
		left.currentShop = shop.id
	end

	return { label = left.label, type = left.type, slots = left.slots, weight = left.weight, maxWeight = left.maxWeight }, shop
end)

local function canAffordItem(inv, currency, price)
	local canAfford = price >= 0 and Inventory.GetItemCount(inv, currency) >= price

	return canAfford or {
		type = 'error',
		description = locale('cannot_afford', ('%s%s'):format((currency == 'money' and locale('$') or math.groupdigits(price)), (currency == 'money' and math.groupdigits(price) or ' '..Items(currency).label)))
	}
end

local function removeCurrency(inv, currency, price)
	Inventory.RemoveItem(inv, currency, price)
end

local TriggerEventHooks = require 'modules.hooks.server'

local function isRequiredGrade(grade, rank)
	if type(grade) == "table" then
		for i=1, #grade do
			if grade[i] == rank then
				return true
			end
		end
		return false
	else
		return rank >= grade
	end
end

lib.callback.register('ox_inventory:buyItem', function(source, data)
	if data.toType ~= 'player' then
		return false, false, { type = 'error', description = locale('cannot_give', 'shop') or 'Invalid buy target' }
	end

	if data.count == nil then data.count = 1 end

	local playerInv = Inventory(source)

	if not playerInv or not playerInv.currentShop then
		return false, false, { type = 'error', description = locale('inventory_right_access') or 'Shop unavailable' }
	end

	local shopKey = playerInv.currentShop
	local shop
	local shopType, shopId

	if type(shopKey) == 'string' then
		shopType, shopId = shopKey:match('^(.-) (%d-)$')
	end

	-- Admin free-spawn catalogs live only in OpenAdminShops — resolve first
	if playerInv.adminShop or (type(shopKey) == 'string' and shopKey:sub(1, 6) == 'admin_') then
		shop = AdminShops.resolveAdminShop(source, shopKey)
	end

	if not shop then
		if not shopType then shopType = shopKey end
		if shopId then shopId = tonumber(shopId) end
		shop = shopId and Shops[shopType] and Shops[shopType][shopId] or Shops[shopType]
	end

	if not shop then
		local ok, resolved = pcall(function()
			return exports[shared.resource]:ResolveAdminShop(source, shopKey)
		end)
		if ok then shop = resolved end
	end

	if not shop or type(shop) ~= 'table' or not shop.items then
		return false, false, { type = 'error', description = locale('inventory_right_access') or 'Shop unavailable' }
	end

	local fromData = shop.items[data.fromSlot]
	local toData = playerInv.items[data.toSlot]

	if not fromData then
		return false, false, { type = 'error', description = locale('item_not_enough', 'shop') or 'Item missing from shop' }
	end

	if fromData.count then
		if fromData.count == 0 then
			return false, false, { type = 'error', description = locale('shop_nostock') }
		elseif data.count > fromData.count then
			data.count = fromData.count
		end
	end

	local isAdminShop = playerInv.adminShop or shop.adminFree

	if not isAdminShop and fromData.license and server.hasLicense and not server.hasLicense(playerInv, fromData.license) then
		return false, false, { type = 'error', description = locale('item_unlicensed') }
	end

	if not isAdminShop and fromData.grade then
		local _, rank = server.hasGroup(playerInv, shop.groups)
		if not isRequiredGrade(fromData.grade, rank) then
			return false, false, { type = 'error', description = locale('stash_lowgrade') }
		end
	end

	local currency = fromData.currency or 'money'
	local fromItem = Items(fromData.name)

	if not fromItem then
		return false, false, { type = 'error', description = locale('item_not_enough', fromData.name) or 'Unknown item' }
	end

	local result = fromItem.cb and fromItem.cb('buying', fromItem, playerInv, data.fromSlot, shop)
	if result == false then
		return false, false, { type = 'error', description = locale('cannot_use') or 'Cannot buy this item' }
	end

	local toItem = toData and Items(toData.name)
	local metadata, count = Items.Metadata(playerInv, fromItem, fromData.metadata and table.clone(fromData.metadata) or {}, data.count)
	local price = isAdminShop and 0 or (count * (fromData.price or 0))

	if toData ~= nil and not (fromItem.name == toItem?.name and fromItem.stack and table.matches(toData.metadata, metadata)) then
		return false, false, { type = 'error', description = locale('unable_stack_items') }
	end

	local newWeight = playerInv.weight + (fromItem.weight + (metadata?.weight or 0)) * count

	if newWeight > playerInv.maxWeight then
		return false, false, { type = 'error', description = locale('cannot_carry') }
	end

	local canAfford = canAffordItem(playerInv, currency, price)
	if canAfford ~= true then
		return false, false, canAfford
	end

	if not TriggerEventHooks('buyItem', {
		source = source,
		shopType = shopType or shopKey,
		shopId = shopId,
		toInventory = playerInv.id,
		toSlot = data.toSlot,
		fromSlot = fromData,
		itemName = fromData.name,
		metadata = metadata,
		count = count,
		price = fromData.price or 0,
		totalPrice = price,
		currency = currency,
	}) then
		return false, false, { type = 'error', description = locale('unable_stack_items') }
	end

	Inventory.SetSlot(playerInv, fromItem, count, metadata, data.toSlot)
	playerInv.weight = newWeight

	if price > 0 then
		removeCurrency(playerInv, currency, price)
	end

	if fromData.count and not isAdminShop then
		shop.items[data.fromSlot].count = fromData.count - count
	end

	if server.syncInventory then server.syncInventory(playerInv) end

	local message = isAdminShop
		and ('Added %sx %s'):format(count, metadata?.label or fromItem.label)
		or locale('purchased_for', count, metadata?.label or fromItem.label, (currency == 'money' and locale('$') or math.groupdigits(price)), (currency == 'money' and math.groupdigits(price) or ' '..Items(currency).label))

	if server.loglevel > 0 then
		if server.loglevel > 1 or (fromData.price or 0) >= 500 then
			lib.logger(playerInv.owner, 'buyItem', ('"%s" %s'):format(playerInv.label, message:lower()), ('shop:%s'):format(shop.label))
		end
	end

	return true, {
		data.toSlot,
		playerInv.items[data.toSlot],
		shop.items[data.fromSlot].count and shop.items[data.fromSlot],
		playerInv.weight,
	}, { type = 'success', description = message }
end)

server.shops = Shops
