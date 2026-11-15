if not lib then return end

local Items = require 'modules.items.shared' --[[@as table<string, OxClientItem>]]

local function sendDisplayMetadata(data)
	SendNUIMessage({
		action = 'displayMetadata',
		data = data
	})
end

--- use array of single key value pairs to dictate order
---@param metadata string | table<string, string> | table<string, string>[]
---@param value? string
local function displayMetadata(metadata, value)
	local data = {}

	if type(metadata) == 'string' then
		if not value then return end

		data = { { metadata = metadata, value = value } }
	elseif table.type(metadata) == 'array' then
		for i = 1, #metadata do
			for k, v in pairs(metadata[i]) do
				data[i] = {
					metadata = k,
					value = v,
				}
			end
		end
	else
		for k, v in pairs(metadata) do
			data[#data + 1] = {
				metadata = k,
				value = v,
			}
		end
	end

	if client.uiLoaded then
		return sendDisplayMetadata(data)
	end

	CreateThread(function()
		repeat Wait(100) until client.uiLoaded

		sendDisplayMetadata(data)
	end)
end

exports('displayMetadata', displayMetadata)

---@param _ table?
---@param name string?
---@return table?
local function getItem(_, name)
	if not name then return Items end

	if type(name) ~= 'string' then return end

	-- Exact key first (preserves mixed-case custom weapons e.g. WEAPON_ascia)
	local item = Items[name]
	if item then return item end

	local lower = name:lower()
	item = Items[lower]
	if item then return item end

	-- Stock weapons are WEAPON_PISTOL-style. Custom packs may use WEAPON_ascia (meta casing).
	if lower:sub(1, 7) == 'weapon_' then
		item = Items[lower:upper()]
		if item then return item end

		item = Items['WEAPON_' .. lower:sub(8)]
		if item then return item end
	end

	return nil
end

setmetatable(Items --[[@as table]], {
	__call = getItem
})

---@cast Items +fun(itemName: string): OxClientItem
---@cast Items +fun(): table<string, OxClientItem>

local function Item(name, cb)
	local item = Items[name]
	if item then
		if not item.client?.export and not item.client?.event then
			item.effect = cb
		end
	end
end

local ox_inventory = exports[shared.resource]
-----------------------------------------------------------------------------------------------
-- Clientside item use functions
-----------------------------------------------------------------------------------------------

Item('bandage', function(data, slot)
	local maxHealth = GetEntityMaxHealth(cache.ped)
	local health = GetEntityHealth(cache.ped)

	-- Skip if already at full health (still allow wasabi bleed clear below after use)
	ox_inventory:useItem(data, function(data)
		if data then
			SetEntityHealth(cache.ped, math.min(maxHealth, math.floor(health + maxHealth / 16)))
			lib.notify({ description = 'You feel better already' })

			-- wasabi-ambulance Bandages are disabled for ox_inventory; clear bleed/injury after a real use
			if GetResourceState('wasabi_ambulance') == 'started' then
				pcall(function()
					exports.wasabi_ambulance:clearPlayerInjury()
				end)
				TriggerEvent('mythic_hospital:client:RemoveBleed')
				TriggerEvent('mythic_hospital:client:ResetLimbs')
			end
		end
	end)
end)

Item('armour', function(data, slot)
	if GetPedArmour(cache.ped) < 100 then
		ox_inventory:useItem(data, function(data)
			if data then
				SetPlayerMaxArmour(PlayerData.id, 100)
				SetPedArmour(cache.ped, 100)
			end
		end)
	end
end)

client.parachute = false
Item('parachute', function(data, slot)
	if not client.parachute then
		ox_inventory:useItem(data, function(data)
			if data then
				local chute = `GADGET_PARACHUTE`
				SetPlayerParachuteTintIndex(PlayerData.id, -1)
				GiveWeaponToPed(cache.ped, chute, 0, true, false)
				SetPedGadget(cache.ped, chute, true)
				lib.requestModel(1269906701)
				client.parachute = { CreateParachuteBagObject(cache.ped, true, true), slot?.metadata?.type or -1 }
				if slot.metadata.type then
					SetPlayerParachuteTintIndex(PlayerData.id, slot.metadata.type)
				end
			end
		end)
	end
end)

Item('phone', function(data, slot)
	local success, result = pcall(function()
		return exports.npwd:isPhoneVisible()
	end)

	if success then
		exports.npwd:setPhoneVisible(not result)
	end
end)

Item('clothing', function(data, slot)
	local metadata = slot.metadata

	if not metadata.drawable then return end
	if not metadata.texture then return end

	if metadata.prop then
		if not SetPedPreloadPropData(cache.ped, metadata.prop, metadata.drawable, metadata.texture) then
			return
		end
	elseif metadata.component then
		if not IsPedComponentVariationValid(cache.ped, metadata.component, metadata.drawable, metadata.texture) then
			return
		end
	else
		return
	end

	ox_inventory:useItem(data, function(data)
		if data then
			metadata = data.metadata

			if metadata.prop then
				local prop = GetPedPropIndex(cache.ped, metadata.prop)
				local texture = GetPedPropTextureIndex(cache.ped, metadata.prop)

				if metadata.drawable == prop and metadata.texture == texture then
					return ClearPedProp(cache.ped, metadata.prop)
				end

				-- { prop = 0, drawable = 2, texture = 1 } = grey beanie
				SetPedPropIndex(cache.ped, metadata.prop, metadata.drawable, metadata.texture, false);
			elseif metadata.component then
				local drawable = GetPedDrawableVariation(cache.ped, metadata.component)
				local texture = GetPedTextureVariation(cache.ped, metadata.component)

				if metadata.drawable == drawable and metadata.texture == texture then
					return -- item matches (setup defaults so we can strip?)
				end

				-- { component = 4, drawable = 4, texture = 1 } = jeans w/ belt
				SetPedComponentVariation(cache.ped, metadata.component, metadata.drawable, metadata.texture, 0);
			end
		end
	end)
end)

-----------------------------------------------------------------------------------------------

_G.__ox_inventory_items = function(item) return getItem(nil, item) end
exports('Items', _G.__ox_inventory_items)
exports('ItemList', _G.__ox_inventory_items)

-- Load ramp placement module asynchronously to avoid blocking inventory load
CreateThread(function()
	Wait(1000) -- Wait for inventory to fully initialize
	local success, err = pcall(lib.load, 'modules.items.ramp')
	if not success then
	else
	end
end)

return Items
