-- Admin shop browser — catalogs + city shops (group.admin / ACE)

if not lib then return end

local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'

---@type table<string, OxShop>
local AdminCatalogs = {}

---@type table<number, OxShop>
local OpenAdminShops = {}

local function isInventoryAdmin(source)
	if not source then return false end

	-- Use numeric source — tostring(source) breaks IsPlayerAceAllowed on FiveM
	if IsPlayerAceAllowed(source, 'ox_inventory.admin') then return true end
	if IsPlayerAceAllowed(source, 'admin') then return true end
	if IsPlayerAceAllowed(source, 'command') then return true end
	if IsPlayerAceAllowed(source, 'command.additem') then return true end
	if IsPlayerAceAllowed(source, 'group.admin') then return true end

	local player = exports.qbx_core:GetPlayer(source)
	if player and player.PlayerData then
		local group = player.PlayerData.group
		if group == 'admin' or group == 'god' then return true end
	end

	return false
end

local function classifyItem(name, item)
	local n = name:lower()
	if item.weapon or n:find('weapon_', 1, true) then return 'weapons' end
	if item.ammo or n:find('ammo', 1, true) then return 'ammo' end
	if item.component or item.tint then return 'attachments' end
	if n:find('burger', 1, true) or n:find('water', 1, true) or n:find('cola', 1, true)
		or n:find('food', 1, true) or n:find('drink', 1, true) or n:find('sandwich', 1, true)
		or n:find('pizza', 1, true) or n:find('coffee', 1, true) or n:find('beer', 1, true)
		or n:find('whiskey', 1, true) or n:find('gatorade', 1, true) or n:find('jarrito', 1, true) or n:find('cheetos', 1, true) or n:find('pringles', 1, true) or n:find('fries', 1, true) then
		return 'food'
	end
	if n:find('bandage', 1, true) or n:find('medkit', 1, true) or n:find('painkiller', 1, true)
		or n:find('firstaid', 1, true) or n:find('armor', 1, true) or n:find('armour', 1, true) then
		return 'medical'
	end
	if n:find('shirt', 1, true) or n:find('pants', 1, true) or n:find('hat', 1, true)
		or n:find('shoes', 1, true) or n:find('jacket', 1, true) or n:find('mask', 1, true)
		or n:find('glasses', 1, true) or n:find('clothing', 1, true) or item.clothing then
		return 'clothes'
	end
	if n:find('prop', 1, true) or n:find('tool', 1, true) or n:find('lockpick', 1, true)
		or n:find('repair', 1, true) or n:find('phone', 1, true) or n:find('radio', 1, true)
		or n:find('drill', 1, true) or n:find('saw', 1, true) or n:find('keyfob', 1, true) then
		return 'props'
	end
	return 'misc'
end

local CATALOG_META = {
	{ id = 'weapons', label = 'Weapons' },
	{ id = 'ammo', label = 'Ammo' },
	{ id = 'attachments', label = 'Attachments' },
	{ id = 'food', label = 'Food & Drink' },
	{ id = 'medical', label = 'Medical' },
	{ id = 'clothes', label = 'Clothes' },
	{ id = 'props', label = 'Props & Tools' },
	{ id = 'misc', label = 'Everything Else' },
}

local function rebuildCatalogs()
	local buckets = {}
	for i = 1, #CATALOG_META do
		buckets[CATALOG_META[i].id] = {}
	end

	for name, item in pairs(Items()) do
		if type(item) == 'table' and item.name then
			local cat = classifyItem(name, item)
			local bucket = buckets[cat] or buckets.misc
			bucket[#bucket + 1] = {
				name = item.name,
				price = 0,
				count = 9999,
			}
		end
	end

	AdminCatalogs = {}
	for i = 1, #CATALOG_META do
		local meta = CATALOG_META[i]
		local inventory = buckets[meta.id] or {}
		table.sort(inventory, function(a, b) return a.name < b.name end)

		local items = {}
		local slot = 0
		for i = 1, #inventory do
			local entry = inventory[i]
			local Item = Items(entry.name)
			if Item then
				slot += 1
				items[slot] = {
					name = Item.name,
					label = Item.label,
					slot = slot,
					weight = Item.weight,
					count = 9999,
					price = 0,
				}
			end
		end

		AdminCatalogs[meta.id] = {
			id = ('admin_catalog_%s'):format(meta.id),
			label = ('Admin · %s'):format(meta.label),
			type = 'shop',
			slots = slot,
			items = items,
			adminFree = true,
		}
	end
end

CreateThread(function()
	Wait(2000)
	rebuildCatalogs()
end)

local function listAdminShops(source)
	if not isInventoryAdmin(source) then return {} end
	if not next(AdminCatalogs) then rebuildCatalogs() end

	local entries = {}

	for i = 1, #CATALOG_META do
		local meta = CATALOG_META[i]
		local catalog = AdminCatalogs[meta.id]
		if catalog and catalog.slots > 0 then
			entries[#entries + 1] = {
				id = meta.id,
				label = meta.label,
				kind = 'catalog',
				itemCount = catalog.slots,
			}
		end
	end

	local shopsData = lib.load('data.shops') or {}
	for shopType, shop in pairs(shopsData) do
		entries[#entries + 1] = {
			id = shopType,
			label = shop.name or shopType,
			kind = 'shop',
		}
	end

	table.sort(entries, function(a, b)
		if a.kind ~= b.kind then return a.kind == 'catalog' end
		return a.label < b.label
	end)

	return entries
end

local function buildShopFromCityDef(shopType)
	local shopsData = lib.load('data.shops') or {}
	local def = shopsData[shopType]
	if not def then return end

	local inventory = def.inventory or {}
	local items = {}
	local slot = 0

	for i = 1, #inventory do
		local entry = inventory[i]
		local Item = Items(entry.name)
		if Item then
			slot += 1
			items[slot] = {
				name = Item.name,
				label = Item.label,
				slot = slot,
				weight = Item.weight,
				count = entry.count or 9999,
				price = 0,
				metadata = entry.metadata,
				currency = entry.currency,
			}
		end
	end

	return {
		id = ('admin_shop_%s'):format(shopType),
		label = ('Admin · %s'):format(def.name or shopType),
		type = 'shop',
		slots = slot,
		items = items,
		adminFree = true,
	}
end

lib.callback.register('ox_inventory:isInventoryAdmin', function(source)
	return isInventoryAdmin(source)
end)

lib.callback.register('ox_inventory:getAdminShops', function(source)
	return listAdminShops(source)
end)

lib.callback.register('ox_inventory:openAdminShop', function(source, data)
	if not isInventoryAdmin(source) then return end
	if type(data) ~= 'table' or not data.id then return end

	local left = Inventory(source)
	if not left then return end

	local shop
	if data.kind == 'catalog' then
		if not next(AdminCatalogs) then rebuildCatalogs() end
		shop = AdminCatalogs[data.id]
	else
		shop = buildShopFromCityDef(data.id)
	end

	if not shop or not shop.items or shop.slots < 1 then return end

	-- Keep player inventory open as the active container without wiping shop state after
	if not left.open then
		left:openInventory(left)
	else
		left.open = left.id
		left.openedBy[left.id] = true
	end

	left.currentShop = shop.id
	left.adminShop = true
	OpenAdminShops[source] = shop

	return {
		id = left.id,
		label = left.label,
		type = left.type,
		slots = left.slots,
		weight = left.weight,
		maxWeight = left.maxWeight,
		groups = left.player and left.player.groups or nil,
	}, shop
end)

---@param source number
---@param shopId string
---@return OxShop?
local function resolveAdminShop(source, shopId)
	local shop = OpenAdminShops[source]
	if shop and shop.id == shopId then return shop end
	return nil
end

exports('IsInventoryAdmin', isInventoryAdmin)
exports('ResolveAdminShop', resolveAdminShop)

AddEventHandler('playerDropped', function()
	OpenAdminShops[source] = nil
end)

RegisterNetEvent('ox_inventory:closeInventory', function()
	local src = source
	OpenAdminShops[src] = nil
	local inv = Inventory(src)
	if inv then
		inv.adminShop = nil
		inv.currentShop = nil
	end
end)

return {
	isInventoryAdmin = isInventoryAdmin,
	resolveAdminShop = resolveAdminShop,
}
