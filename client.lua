if not lib then return end

require 'modules.bridge.client'
require 'modules.interface.client'

local success, Inventory = pcall(require, 'modules.inventory.client')

if not success then
	print('^1[CRITICAL] Failed to load modules.inventory.client: ' .. tostring(Inventory) .. '^7')
	Inventory = {}
end

local Utils = require 'modules.utils.client'
local Weapon = require 'modules.weapon.client'
require 'modules.weapons.client'

local function tryRequire(name)
	local ok, err = pcall(require, name)
	if not ok then
		warn(('[ox_inventory] optional module skipped (%s): %s'):format(name, err))
	end
	return ok
end

local CharacterPreview = require 'modules.character.client'
-- Item Drop Physics (optional — RWInv.Features.itemDrops in config.lua).
local RWDrops = require 'modules.rwdrops.client'
-- Ground drop points: item props (above) or one classic bag per drop.
local DropPoints = require 'modules.rwdroppoints.client'

-- REALWRLD Creator V4 modules (merged 2026-10-24)
require 'modules.playerinfo.client'
require 'modules.rwadmin.client'
require 'modules.rwbackdrop.client'
require 'modules.rwclothing.client'
require 'modules.rwlocale.client'
require 'modules.rwweaponwheel.client'
local ShopFav = require 'modules.rwshop.client'
require 'modules.rwpocket.client'
require 'modules.pedpreview.client'
require 'modules.rwload.client'

tryRequire 'modules.gathering.client_mining'
tryRequire 'modules.scavenging.client'
tryRequire 'modules.theft.client'
tryRequire 'modules.trading.client'
tryRequire 'modules.items.special_blueprints'
tryRequire 'modules.vehiclekeys.client'

local slingOk, slingErr = pcall(function()
    require 'modules.rw-weapon-sling.config'
    require 'modules.rw-weapon-sling.client.main'
end)
if not slingOk then
    print('^1[ox_inventory] weapon sling failed to load: ' .. tostring(slingErr) .. '^7')
end

tryRequire 'modules.market.client'
local currentWeapon


exports('getCurrentWeapon', function()
	return currentWeapon
end)

RegisterNetEvent('ox_inventory:disarm', function(noAnim)
	currentWeapon = Weapon.Disarm(currentWeapon, noAnim)
end)

RegisterNetEvent('ox_inventory:clearWeapons', function()
	Weapon.ClearAll(currentWeapon)
end)

local StashTarget

exports('setStashTarget', function(id, owner)
	StashTarget = id and { id = id, owner = owner }
end)

---@type boolean | number
local invBusy = true

---@type boolean?
local invOpen = false
local plyState = LocalPlayer.state
local IsPedCuffed = IsPedCuffed
local playerPed = cache.ped

lib.onCache('ped', function(ped)
	playerPed = ped
	Utils.WeaponWheel()
end)

plyState:set('invBusy', true, true)
plyState:set('invHotkeys', false, false)
plyState:set('canUseWeapons', false, false)

local function canOpenInventory()
	if not PlayerData.loaded or not PlayerData.inventory then
		return shared.info('cannot open inventory', '(player inventory has not loaded)')
	end

	if IsPauseMenuActive() then return end

	if invBusy or invOpen == nil or ((currentWeapon and currentWeapon.timer or 0) > 0) then
		return shared.info('cannot open inventory', '(is busy)')
	end

	if PlayerData.dead or IsPedFatallyInjured(playerPed) then
		return shared.info('cannot open inventory', '(fatal injury)')
	end

	if PlayerData.cuffed or IsPedCuffed(playerPed) then
		return shared.info('cannot open inventory', '(cuffed)')
	end

	return true
end

---@param ped number
---@return boolean
local function canOpenTarget(ped)
	return IsPedFatallyInjured(ped)
		or IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3)
		or IsPedCuffed(ped)
		or IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3)
		or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 3)
		or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_enter', 3)
		or IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3)
end

local defaultInventory = {
	type = 'newdrop',
	slots = shared.playerslots,
	weight = 0,
	maxWeight = shared.playerweight,
	items = {}
}

local currentInventory = defaultInventory

-- ─────────────────────────────────────────────────────────────
-- REALWRLD Creator V4 UI glue (merged 2026-10-24): config mirrors,
-- hotbar key labels, right-panel meta, shop slot refresh, the
-- NUI error reporter, and the shop basket callbacks.
-- ─────────────────────────────────────────────────────────────
local rwCfg = require 'modules.rwconfig.shared'.Get()
local hudCfg = type(rwCfg.Hud) == 'table' and rwCfg.Hud or {}
local NATIVE_NOTIFY = type(rwCfg.Shop) == 'table' and rwCfg.Shop.nativeNotify == true

local hotbarBind
local hotkeyBinds = {}
local hotbarAlwaysNui = false
local pendingGive
local lastPanelDist, lastPanelOwner, lastPanelOwnerId, lastPanelOwnerSent

local function keyLabel(bind, fallback)
	local ok, key = pcall(function() return bind and bind:getCurrentKey() or '' end)
	if not ok or type(key) ~= 'string' or key == '' or #key > 5 then return fallback end
	return key
end

local function pushHotbarKeys()
	local keys = {}
	for i = 1, 5 do keys[i] = keyLabel(hotkeyBinds[i], tostring(i)) end
	SendNUIMessage({ action = 'oxlynHotbarKeys', data = { keys = keys, hotbar = keyLabel(hotbarBind, '') } })
end

-- Right-panel context chips: one small message only when the quantised
-- distance (0.5 m) or the owner changes — never per frame.
local function pushPanelMeta(dist, ownerId)
	local q = math.floor(dist * 2 + 0.5) / 2
	local owner

	if ownerId then
		if lastPanelOwnerId ~= ownerId then
			lastPanelOwnerId = ownerId
			local name = ''
			local serverId = tonumber(ownerId)

			if serverId then
				local playerIdx = GetPlayerFromServerId(serverId)
				if playerIdx and playerIdx ~= -1 then name = GetPlayerName(playerIdx) or '' end
			end

			lastPanelOwner = name
		end

		owner = lastPanelOwner ~= '' and lastPanelOwner or nil
	end

	if q ~= lastPanelDist or owner ~= (lastPanelOwnerSent or nil) then
		lastPanelDist = q
		lastPanelOwnerSent = owner
		SendNUIMessage({ action = 'oxlynPanelMeta', data = { distance = q, owner = owner } })
	end
end

local function pushShopSlots(slots)
	if not slots or not slots[1] then return end

	local items = {}

	for i = 1, #slots do
		items[i] = { item = slots[i], inventory = 'shop' }
	end

	SendNUIMessage({
		action = 'refreshSlots',
		data = { items = items }
	})
end

-- NUI error reporter: the Creator UI reports its own JS errors here.
RegisterNUICallback('rwClientError', function(data, cb)
	cb(1)
	if type(data) ~= 'table' then return end
	local where = ('%s:%s:%s'):format(tostring(data.source or '?'), tostring(data.line or 0), tostring(data.col or 0))
	print(('^3[ox_inventory] NUI %s:^0 %s ^5(%s, build %s)^0\n%s'):format(tostring(data.kind or 'error'), tostring(data.message or '?'):sub(1, 400), where, tostring(data.build or '?'), tostring(data.stack or ''):sub(1, 1500)))
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynClientError', function(data, cb)
	cb(1)
	if type(data) ~= 'table' then return end
	local where = ('%s:%s:%s'):format(tostring(data.source or '?'), tostring(data.line or 0), tostring(data.col or 0))
	print(('^3[ox_inventory] NUI %s:^0 %s ^5(%s, build %s)^0\n%s'):format(tostring(data.kind or 'error'), tostring(data.message or '?'):sub(1, 400), where, tostring(data.build or '?'), tostring(data.stack or ''):sub(1, 1500)))
end)

RegisterNUICallback('rwShopWallet', function(data, cb)
	local session = lib.callback.await('ox_inventory:rwShopWallet', 200)

	-- Lazy restock happened server-side on open: refresh those shop rows.
	if session and session.restocked then pushShopSlots(session.restocked) end

	-- This character's favourites of this shop type (client KVP, modules/rwshop/client.lua)
	if session then
		ShopFav.setWho(session.who)
		local shop = type(data) == 'table' and data.shop or (currentInventory and currentInventory.id)
		session.favourites = ShopFav.list(shop)
	end

	cb(session or false)
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynShopWallet', function(data, cb)
	local session = lib.callback.await('ox_inventory:rwShopWallet', 200)

	-- Lazy restock happened server-side on open: refresh those shop rows.
	if session and session.restocked then pushShopSlots(session.restocked) end

	-- This character's favourites of this shop type (client KVP, modules/rwshop/client.lua)
	if session then
		ShopFav.setWho(session.who)
		local shop = type(data) == 'table' and data.shop or (currentInventory and currentInventory.id)
		session.favourites = ShopFav.list(shop)
	end

	cb(session or false)
end)

RegisterNUICallback('rwShopBuy', function(data, cb)
	local response, result, message = lib.callback.await('ox_inventory:rwShopBuy', 1000, data)

	if result then pushShopSlots(result.slots) end

	if message and NATIVE_NOTIFY then
		lib.notify(message)
	end

	cb({
		success = response == true,
		wallet = result and result.wallet or nil,
		message = message,
		code = message and message.code or nil,
	})
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynShopBuy', function(data, cb)
	local response, result, message = lib.callback.await('ox_inventory:rwShopBuy', 1000, data)

	if result then pushShopSlots(result.slots) end

	if message and NATIVE_NOTIFY then
		lib.notify(message)
	end

	cb({
		success = response == true,
		wallet = result and result.wallet or nil,
		message = message,
		code = message and message.code or nil,
	})
end)

RegisterNUICallback('rwShopSell', function(data, cb)
	local response, result, message = lib.callback.await('ox_inventory:rwShopSell', 1000, data)

	if result then pushShopSlots(result.slots) end

	if message and NATIVE_NOTIFY then
		lib.notify(message)
	end

	cb({
		success = response == true,
		wallet = result and result.wallet or nil,
		total = result and result.total or nil,
		currency = result and result.currency or nil,
		message = message,
		code = message and message.code or nil,
	})
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynShopSell', function(data, cb)
	local response, result, message = lib.callback.await('ox_inventory:rwShopSell', 1000, data)

	if result then pushShopSlots(result.slots) end

	if message and NATIVE_NOTIFY then
		lib.notify(message)
	end

	cb({
		success = response == true,
		wallet = result and result.wallet or nil,
		total = result and result.total or nil,
		currency = result and result.currency or nil,
		message = message,
		code = message and message.code or nil,
	})
end)

local function closeTrunk()
	if currentInventory and currentInventory.type == 'trunk' then
		local coords = GetEntityCoords(playerPed, true)
		---@todo animation for vans?
		Utils.PlayAnimAdvanced(0, 'anim@heists@fleeca_bank@scope_out@return_case', 'trevor_action', coords.x, coords.y,
			coords.z, 0.0, 0.0, GetEntityHeading(playerPed), 2.0, 2.0, 1000, 49, 0.25)

		CreateThread(function()
			local entity = currentInventory.entity
			local door = currentInventory.door
			Wait(900)

			if type(door) == 'table' then
				for i = 1, #door do
					SetVehicleDoorShut(entity, door[i], false)
				end
			else
				SetVehicleDoorShut(entity, door, false)
			end
		end)
	end
end

local CraftingBenches = require 'modules.crafting.client'
local Vehicles = lib.load('data.vehicles')

---@param inv string?
---@param data any?
---@return boolean?
function client.openInventory(inv, data)
	-- RW soft-diag: numeric-only stash ids are almost always a bad caller (not a real RegisterStash name)
	if inv == 'stash' then
		local sid = type(data) == 'table' and tostring(data.id or '') or tostring(data or '')
		if sid:match('^%d+$') then
			StashNumOpenLog = StashNumOpenLog or {}
			if not StashNumOpenLog[sid] then
				StashNumOpenLog[sid] = true
				local stack = Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString())
				warn(('[RW-stashspam] client openInventory stash id=%s data=%s\n%s'):format(sid, json.encode(data), tostring(stack)))
			end
			-- Soft block: do not round-trip to server for bare numeric stash names (stops console spam)
			return false
		end
	end
	if invOpen then
		if not inv and currentInventory and currentInventory.type == 'newdrop' then
			return client.closeInventory()
		end

		if IsNuiFocused() then
			if inv == 'container' and currentInventory and currentInventory.id == PlayerData.inventory[data].metadata.container then
				return client.closeInventory()
			end

			if currentInventory and currentInventory.type == 'drop' and (not data or currentInventory.id == (type(data) == 'table' and data.id or data)) then
				return client.closeInventory()
			end

			if inv ~= 'drop' and inv ~= 'container' then
				if (data and data.id or data) == (currentInventory and currentInventory.id) then
					-- Triggering exports.ox_inventory:openInventory('stash', 'mystash') twice in rapid succession is weird behaviour
					return warn(("script tried to open inventory, but it is already open\n%s"):format(Citizen
						.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString())))
				else
					return client.closeInventory()
				end
			end
		end
	elseif IsNuiFocused() then
		-- If triggering from another nui, may need to wait for focus to end.
		Wait(100)

		-- People still complain about this being an "error" and ask "how fix" despite being a warning
		-- for people with above room-temperature iqs to look into resource conflicts on their own.
		-- if IsNuiFocused() then
		-- 	warn('other scripts have nui focus and may cause issues (e.g. disable focus, prevent input, overlap inventory window)')
		-- end
	end

	if inv == 'dumpster' and cache.vehicle then
		return lib.notify({ id = 'inventory_right_access', type = 'error', description = locale('inventory_right_access') })
	end

	if not canOpenInventory() then
		return lib.notify({
			id = 'inventory_player_access',
			type = 'error',
			description = locale(
				'inventory_player_access')
		})
	end

	local left, right, accessError

	if inv == 'player' and data ~= cache.serverId then
		local targetId, targetPed

		if not data then
			targetId, targetPed = Utils.GetClosestPlayer()
			data = targetId and GetPlayerServerId(targetId)
		else
			local serverId = type(data) == 'table' and data.id or data

			if serverId == cache.serverId then return end

			targetId = serverId and GetPlayerFromServerId(serverId)
			targetPed = targetId and GetPlayerPed(targetId)
		end

		local targetCoords = targetPed and GetEntityCoords(targetPed)

		if not targetCoords or #(targetCoords - GetEntityCoords(playerPed)) > 1.8 or not (client.hasGroup(shared.police) or canOpenTarget(targetPed)) then
			return lib.notify({
				id = 'inventory_right_access',
				type = 'error',
				description = locale(
					'inventory_right_access')
			})
		end
	end

	if inv == 'shop' and invOpen == false then
		if cache.vehicle then
			return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
		end

		left, right, accessError = lib.callback.await('ox_inventory:openShop', 200, data)
	elseif inv == 'crafting' then
		if cache.vehicle then
			return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
		end

		left, right, accessError = lib.callback.await('ox_inventory:openCraftingBench', 200, data.id, data.index)

		if left then
			right = CraftingBenches[data.id]

			if not right or not right.items then return end

			local coords, distance

			if not right.zones and not right.points then
				coords = GetEntityCoords(cache.ped)
				distance = 2
			else
				coords = shared.target and right.zones and right.zones[data.index].coords or
					right.points and right.points[data.index]
				distance = coords and shared.target and right.zones[data.index].distance or 2
			end

			right = {
				type = 'crafting',
				id = data.id,
				label = right.label or locale('crafting_bench'),
				index = data.index,
				slots = right.slots,
				items = right.items,
				coords = coords,
				distance = distance
			}
		end
	elseif invOpen ~= nil then
		if inv == 'policeevidence' then
			if not data then
				local input = lib.inputDialog(locale('police_evidence'), {
					{ label = locale('locker_number'), type = 'number', required = true, icon = 'calculator' }
				}) --[[@as number[]? ]]

				if not input then return end

				data = input[1]
			end
		end

		left, right, accessError = lib.callback.await('ox_inventory:openInventory', false, inv, data)
	end

	if accessError then
		return lib.notify({ id = accessError, type = 'error', description = locale(accessError) })
	end

	-- Stash does not exist
	if not left then
		if left == false then return false end

		if invOpen == false then
			return lib.notify({
				id = 'inventory_right_access',
				type = 'error',
				description = locale(
					'inventory_right_access')
			})
		end

		if invOpen then return client.closeInventory() end

		return
	end


	if not cache.vehicle then
		if inv == 'player' then
			Utils.PlayAnim(0, 'mp_common', 'givetake1_a', 8.0, 1.0, 2000, 50, 0.0, 0, 0, 0)
		elseif inv ~= 'trunk' then
			Utils.PlayAnim(0, 'pickup_object', 'putdown_low', 5.0, 1.5, 1000, 48, 0.0, 0, 0, 0)
		end
	end

	plyState.invOpen = true

	-- REALWRLD (merged 2026-10-24): authoritative UI-open signal for modules
	-- (ped preview), plus the airborne forced-compact flag for the UI.
	TriggerEvent('ox_inventory:uiOpen', right and right.type or nil)

	do
		local ped = PlayerPedId()
		local airborne = IsPedFalling(ped) or IsPedInParachuteFreeFall(ped) or IsPedRagdoll(ped) or IsPedSwimming(ped) or IsEntityInAir(ped)
		SendNUIMessage({ action = 'oxlynForceCompact', data = { enabled = airborne } })
	end

	SetInterval(client.interval, 100)
	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(true)
	closeTrunk()

	currentInventory = right or defaultInventory
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups

	-- Driving: player-only inventory must not auto-close from coords drift (default newdrop panel has 1.8m leash).
	if cache.vehicle and (not right or not right.id or right.type == 'player') then
		currentInventory.ignoreSecurityChecks = true
		currentInventory.coords = nil
	end

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = currentInventory
		}
	})

	CreateThread(function()
		local ok = lib.callback.await('ox_inventory:isInventoryAdmin', false)
		SendNUIMessage({ action = 'setInventoryAdmin', data = ok == true })
	end)

	-- Send player health to UI
	local playerHealth = GetEntityHealth(playerPed) - 100 -- GTA health is 100-200, normalize to 0-100
	if playerHealth < 0 then playerHealth = 0 end
	if playerHealth > 100 then playerHealth = 100 end
	SendNUIMessage({
		action = 'updatePlayerHealth',
		data = playerHealth
	})

	-- Send player armor to UI
	local playerArmor = GetPedArmour(playerPed)
	if playerArmor < 0 then playerArmor = 0 end
	if playerArmor > 100 then playerArmor = 100 end
	SendNUIMessage({
		action = 'updatePlayerArmor',
		data = playerArmor
	})

	CharacterPreview.open()

	if currentInventory and not currentInventory.coords and inv ~= 'container' and not (cache.vehicle and currentInventory.ignoreSecurityChecks) then
		currentInventory.coords = GetEntityCoords(playerPed)
	end

	if inv == 'trunk' then
		SetTimeout(200, function()
			---@todo animation for vans?
			Utils.PlayAnim(0, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 3.0, 3.0, -1, 49, 0.0, 0, 0,
				0)

			local entity = data.entity or NetworkGetEntityFromNetworkId(data.netid)
			currentInventory.entity = entity
			currentInventory.door = data.door

			if not currentInventory.door then
				local vehicleHash = GetEntityModel(entity)
				local vehicleClass = GetVehicleClass(entity)
				currentInventory.door = vehicleClass == 12 and { 2, 3 } or Vehicles.Storage[vehicleHash] and 4 or 5
			end

			while currentInventory and currentInventory.entity == entity and invOpen and DoesEntityExist(entity) and Inventory.CanAccessTrunk(entity) do
				Wait(100)
			end

			if invOpen then client.closeInventory() end
		end)
	end

	return true
end

RegisterNetEvent('ox_inventory:openInventory', client.openInventory)
exports('openInventory', client.openInventory)

---@param name string
---@param metadata? table
---@param strict? boolean
function client.getItemCount(name, metadata, strict)
	local count = 0
	local inventory = PlayerData.inventory

	if inventory then
		for _, item in pairs(inventory) do
			if item.name == name then
				if not metadata then
					count = count + (item.count or 1)
				else
					-- Simple metadata check if Utils.ItemMatches isn't available or for speed
					local matches = true
					for k, v in pairs(metadata) do
						if item.metadata[k] ~= v then
							matches = false
							break
						end
					end
					if matches then
						count = count + (item.count or 1)
					end
				end
			end
		end
	end

	return count
end

exports('GetItemCount', client.getItemCount)

RegisterNetEvent('ox_inventory:forceOpenInventory', function(left, right)
	if source == '' then return end

	plyState.invOpen = true

	-- REALWRLD (merged 2026-10-24): authoritative UI-open signal for modules
	-- (ped preview), plus the airborne forced-compact flag for the UI.
	TriggerEvent('ox_inventory:uiOpen', right and right.type or nil)

	do
		local ped = PlayerPedId()
		local airborne = IsPedFalling(ped) or IsPedInParachuteFreeFall(ped) or IsPedRagdoll(ped) or IsPedSwimming(ped) or IsEntityInAir(ped)
		SendNUIMessage({ action = 'oxlynForceCompact', data = { enabled = airborne } })
	end

	SetInterval(client.interval, 100)
	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(true)
	closeTrunk()

	currentInventory = right or defaultInventory
	currentInventory.ignoreSecurityChecks = true
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = currentInventory
		}
	})

	CharacterPreview.open()
end)

local Animations = lib.load('data.animations')
local Items = require 'modules.items.client'
local usingItem = false

---@param data { name: string, label: string, count: number, slot: number, metadata: table<string, any>, weight: number }
lib.callback.register('ox_inventory:usingItem', function(data, noAnim)
	local item = Items[data.name]

	if item and usingItem then
		if not item.client then return true end
		---@cast item +OxClientProps
		item = item.client

		if type(item.anim) == 'string' then
			item.anim = Animations.anim[item.anim]
		end

		if item.prop then
			if item.prop[1] then
				for i = 1, #item.prop do
					if type(item.prop) == 'string' then
						item.prop = Animations.prop[item.prop[i]]
					end
				end
			elseif type(item.prop) == 'string' then
				item.prop = Animations.prop[item.prop]
			end
		end

		if not item.disable then
			item.disable = { combat = true }
		elseif item.disable.combat == nil then
			-- Backwards compatibility; you probably don't want people shooting while eating and bandaging anyway
			item.disable.combat = true
		end

		local success = (not item.usetime or noAnim or lib.progressBar({
			duration = item.usetime,
			label = item.label or locale('using', data.metadata.label or data.label),
			useWhileDead = item.useWhileDead,
			canCancel = item.cancel,
			disable = item.disable,
			anim = item.anim or item.scenario,
			prop = item.prop --[[@as ProgressProps]]
		})) and not PlayerData.dead

		if success then
			if item.notification then
				lib.notify({ description = item.notification })
			end

			if item.status then
				if client.setPlayerStatus then
					client.setPlayerStatus(item.status)
				end
			end

			return true
		end
	end
end)

local function canUseItem(isAmmo)
	local ped = cache.ped

	return not usingItem
		and (not isAmmo or currentWeapon)
		and PlayerData.loaded
		and not PlayerData.dead
		and not invBusy
		and not lib.progressActive()
		and not IsPedRagdoll(ped)
		and not IsPedFalling(ped)
		and not IsPedShooting(playerPed)
end

---@param data table
---@param cb fun(response: SlotWithItem | false)?
---@param noAnim? boolean
local function useItem(data, cb, noAnim)
	local slotData, result = PlayerData.inventory[data.slot]

	if not slotData or not canUseItem(data.ammo and true) then
		if currentWeapon then
			return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
		end

		return
	end

	if currentWeapon and currentWeapon.timer ~= 0 then
		if not currentWeapon.timer or currentWeapon.timer - GetGameTimer() > 100 then return end

		DisablePlayerFiring(cache.playerId, true)
	end

	if invOpen and data.close then client.closeInventory() end

	usingItem = true
	---@type boolean?
	result = lib.callback.await('ox_inventory:useItem', 200, data.name, data.slot, slotData.metadata, noAnim)

	if result and cb then
		local success, response = pcall(cb, result and slotData)

		if not success and response then
			warn(('^1An error occurred while calling item "%s" callback!\n^1SCRIPT ERROR: %s^0'):format(slotData.name,
				response))
		end
	end

	if result then
		TriggerEvent('ox_inventory:usedItem', slotData.name, slotData.slot, next(slotData.metadata) and slotData
			.metadata)
	end

	Wait(500)
	usingItem = false
end

AddEventHandler('ox_inventory:usedItem', function(name, slot, metadata)
	TriggerServerEvent('ox_inventory:usedItemInternal', slot)
end)

AddEventHandler('ox_inventory:item', useItem)
exports('useItem', useItem)

---@param slot number
---@return boolean?
local function useSlot(slot, noAnim)
	local item = PlayerData.inventory[slot]
	if not item then return end

	local data = Items[item.name]
	if not data then return end

	if canUseItem(data.ammo and true) then
		if data.component and not currentWeapon then
			return lib.notify({ id = 'weapon_hand_required', type = 'error', description = locale('weapon_hand_required') })
		end

		local durability = item.metadata.durability --[[@as number?]]
		local consume = data.consume --[[@as number?]]
		local label = item.metadata.label or item.label --[[@as string]]

		-- Naive durability check to get an early exit
		-- People often don't call the 'useItem' export and then complain about "broken" items being usable
		-- This won't work with degradation since we need access to os.time on the server
		if durability and durability <= 100 and consume then
			if durability <= 0 then
				return lib.notify({ type = 'error', description = locale('no_durability', label) })
			elseif consume ~= 0 and consume < 1 and durability < consume * 100 then
				return lib.notify({ type = 'error', description = locale('not_enough_durability', label) })
			end
		end

		data.slot = slot

		if item.metadata.container then
			return client.openInventory('container', item.slot)
		elseif data.client then
			if invOpen and data.close then client.closeInventory() end

			if data.export then
				return data.export(data, { name = item.name, slot = item.slot, metadata = item.metadata })
			elseif data.client.event then -- re-add it, so I don't need to deal with morons taking screenshots of errors when using trigger event
				return TriggerEvent(data.client.event, data,
					{ name = item.name, slot = item.slot, metadata = item.metadata })
			end
		end

		if data.effect then
			data:effect({ name = item.name, slot = item.slot, metadata = item.metadata })
		elseif data.weapon then
			if EnableWeaponWheel or not plyState.canUseWeapons then return end

			if IsCinematicCamRendering() then SetCinematicModeActive(false) end

			if currentWeapon then
				if not currentWeapon.timer or currentWeapon.timer ~= 0 then return end

				local weaponSlot = currentWeapon.slot
				currentWeapon = Weapon.Disarm(currentWeapon)

				if weaponSlot == data.slot then return end
			end

			GiveWeaponToPed(playerPed, data.hash, 0, false, true)
			SetCurrentPedWeapon(playerPed, data.hash, false)

			if data.hash ~= GetSelectedPedWeapon(playerPed) then
				-- silenced: item cannot be used in current context
				return lib.notify({ type = 'error', description = locale('cannot_use', data.label) })
			end

			RemoveWeaponFromPed(cache.ped, data.hash)

			useItem(data, function(result)
				if result then
					local sleep
					currentWeapon, sleep = Weapon.Equip(item, data, noAnim)

					if sleep then Wait(sleep) end
				end
			end, noAnim)
		elseif currentWeapon then
			if data.ammo then
				if EnableWeaponWheel or currentWeapon.metadata.durability <= 0 then return end

				local clipSize = GetMaxAmmoInClip(playerPed, currentWeapon.hash, true)
				local currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)
				local _, maxAmmo = GetMaxAmmo(playerPed, currentWeapon.hash)

				if maxAmmo < clipSize then clipSize = maxAmmo end

				if currentAmmo == clipSize then return end

				useItem(data, function(resp)
					if not resp or resp.name ~= (currentWeapon and currentWeapon.ammo) then return end

					if currentWeapon.metadata.specialAmmo ~= resp.metadata.type and type(currentWeapon.metadata.specialAmmo) == 'string' then
						local clipComponentKey = ('%s_CLIP'):format(Items[currentWeapon.name].model:gsub('WEAPON_',
							'COMPONENT_'))
						local specialClip = ('%s_%s'):format(clipComponentKey,
							(resp.metadata.type or currentWeapon.metadata.specialAmmo):upper())

						if type(resp.metadata.type) == 'string' then
							if not HasPedGotWeaponComponent(playerPed, currentWeapon.hash, specialClip) then
								if not DoesWeaponTakeWeaponComponent(currentWeapon.hash, specialClip) then
									warn('cannot use clip with this weapon')
									return
								end

								local defaultClip = ('%s_01'):format(clipComponentKey)

								if not HasPedGotWeaponComponent(playerPed, currentWeapon.hash, defaultClip) then
									warn('cannot use clip with currently equipped clip')
									return
								end

								if currentAmmo > 0 then
									warn('cannot mix special ammo with base ammo')
									return
								end

								currentWeapon.metadata.specialAmmo = resp.metadata.type

								GiveWeaponComponentToPed(playerPed, currentWeapon.hash, specialClip)
							end
						elseif HasPedGotWeaponComponent(playerPed, currentWeapon.hash, specialClip) then
							if currentAmmo > 0 then
								warn('cannot mix special ammo with base ammo')
								return
							end

							currentWeapon.metadata.specialAmmo = nil

							RemoveWeaponComponentFromPed(playerPed, currentWeapon.hash, specialClip)
						end
					end

					if maxAmmo > clipSize then
						clipSize = GetMaxAmmoInClip(playerPed, currentWeapon.hash, true)
					end

					currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)
					local missingAmmo = clipSize - currentAmmo
					local addAmmo = resp.count > missingAmmo and missingAmmo or resp.count
					local newAmmo = currentAmmo + addAmmo

					if newAmmo == currentAmmo then return end

					AddAmmoToPed(playerPed, currentWeapon.hash, addAmmo)

					if cache.vehicle then
						if cache.seat > -1 or IsVehicleStopped(cache.vehicle) then
							TaskReloadWeapon(playerPed, true)
						else
							-- This is a hacky solution for forcing ammo to properly load into the
							-- weapon clip while driving; without it, ammo will be added but won't
							-- load until the player stops doing anything. i.e. if you keep shooting,
							-- the weapon will not reload until the clip empties.
							-- And yes - for some reason RefillAmmoInstantly needs to run in a loop.
							lib.waitFor(function()
								RefillAmmoInstantly(playerPed)

								local _, ammo = GetAmmoInClip(playerPed, currentWeapon.hash)
								return ammo == newAmmo or nil
							end)
						end
					else
						Wait(100)
						MakePedReload(playerPed)

						SetTimeout(100, function()
							while IsPedReloading(playerPed) do
								DisableControlAction(0, 22, true)
								Wait(0)
							end
						end)
					end

					lib.callback.await('ox_inventory:updateWeapon', false, 'load', newAmmo, false,
						currentWeapon.metadata.specialAmmo)
				end)
			elseif data.component then
				local components = data.client.component

				if not components then return end

				local componentType = data.type
				local weaponComponents = PlayerData.inventory[currentWeapon.slot].metadata.components

				-- Checks if the weapon already has the same component type attached
				for componentIndex = 1, #weaponComponents do
					if componentType == Items[weaponComponents[componentIndex]].type then
						return lib.notify({
							id = 'component_slot_occupied',
							type = 'error',
							description = locale(
								'component_slot_occupied', componentType)
						})
					end
				end

				for i = 1, #components do
					local component = components[i]

					if DoesWeaponTakeWeaponComponent(currentWeapon.hash, component) then
						if HasPedGotWeaponComponent(playerPed, currentWeapon.hash, component) then
							lib.notify({
								id = 'component_has',
								type = 'error',
								description = locale('component_has',
									label)
							})
						else
							useItem(data, function(data)
								if data then
									local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component',
										tostring(data.slot), currentWeapon.slot)

									if success then
										GiveWeaponComponentToPed(playerPed, currentWeapon.hash, component)
										TriggerEvent('ox_inventory:updateWeaponComponent', 'added', component, data.name)
									end
								end
							end)
						end
						return
					end
				end
				lib.notify({ id = 'component_invalid', type = 'error', description = locale('component_invalid', label) })
			elseif data.allowArmed then
				useItem(data)
			else
				return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
			end
		elseif not data.ammo and not data.component then
			useItem(data)
		end
	end
end
exports('useSlot', useSlot)

---@param id number
---@param slot number
local function useButton(id, slot)
	if PlayerData.loaded and not invBusy and not lib.progressActive() then
		local item = PlayerData.inventory[slot]
		if not item then return end

		local data = Items[item.name]
		local buttons = data and data.buttons

		if buttons and buttons[id] and buttons[id].action then
			buttons[id].action(slot)
		end
	end
end

local function openNearbyInventory() client.openInventory('player') end

exports('openNearbyInventory', openNearbyInventory)

local currentInstance
local playerCoords
local Shops = require 'modules.shops.client'

---@todo remove or replace when the bridge module gets restructured
function OnPlayerData(key, val)
	if key ~= 'groups' and key ~= 'ped' and key ~= 'dead' then return end

	if key == 'groups' then
		Inventory.Stashes()
		Inventory.Evidence()
		Shops.refreshShops()
	elseif key == 'dead' and val then
		currentWeapon = Weapon.Disarm(currentWeapon)
		client.closeInventory()
	end

	Utils.WeaponWheel()
end

-- People consistently ignore errors when one of the "modules" failed to load
if not Utils or not Weapon or not Items or not Inventory then return end

local invHotkeys = false

---@type function?
local function registerCommands()
	RegisterCommand('steal', openNearbyInventory, false)

	local function openGlovebox(vehicle)
		if not IsPedInAnyVehicle(playerPed, false) or not NetworkGetEntityIsNetworked(vehicle) then return end

		local vehicleHash = GetEntityModel(vehicle)
		local vehicleClass = GetVehicleClass(vehicle)
		local checkVehicle = Vehicles.Storage[vehicleHash]

		-- No storage or no glovebox
		if (checkVehicle == 0 or checkVehicle == 2) or (not Vehicles.glovebox[vehicleClass] and not Vehicles.glovebox.models[vehicleHash]) then return end

		local isOpen = client.openInventory('glovebox',
			{ id = 'glove' .. GetVehicleNumberPlateText(vehicle), netid = NetworkGetNetworkIdFromEntity(vehicle) })

		if isOpen then
			currentInventory.entity = vehicle
		end
	end

	local primary = lib.addKeybind({
		name = 'inv',
		description = locale('open_player_inventory'),
		defaultKey = client.keys[1],
		onPressed = function()
			if invOpen then
				return client.closeInventory()
			end

			-- While driving: open PLAYER inventory (with 3D clone). Glovebox stays on secondary key / vehicle access.
			if cache.vehicle then
				if invBusy or not canOpenInventory() then
					return lib.notify({
						id = 'inventory_player_access',
						type = 'error',
						description = locale('inventory_player_access')
					})
				end
				return client.openInventory()
			end

			local closest = lib.points.getClosestPoint()

			if closest and closest.currentDistance < 1.2 and (not closest.instance or closest.instance == currentInstance) then
				if closest.inv == 'crafting' then
					return client.openInventory('crafting', { id = closest.id, index = closest.index })
				elseif closest.inv ~= 'license' and closest.inv ~= 'policeevidence' then
					return client.openInventory(closest.inv or 'drop', { id = closest.invId, type = closest.type })
				end
			end

			return client.openInventory()
		end
	})

	lib.addKeybind({
		name = 'inv2',
		description = locale('open_secondary_inventory'),
		defaultKey = client.keys[2],
		onPressed = function(self)
			if primary:getCurrentKey() == self:getCurrentKey() then
				return warn(("secondary inventory keybind '%s' disabled (keybind cannot match primary inventory keybind)")
					:format(self:getCurrentKey()))
			end

			if invOpen then
				return client.closeInventory()
			end

			if invBusy or not canOpenInventory() then
				return lib.notify({
					id = 'inventory_player_access',
					type = 'error',
					description = locale(
						'inventory_player_access')
				})
			end

			if StashTarget then
				return client.openInventory('stash', StashTarget)
			end

			if cache.vehicle then
				return openGlovebox(cache.vehicle)
			end

			local entity, entityType = Utils.Raycast(2|16)

			if not entity then return end

			if not shared.target and entityType == 3 then
				local model = GetEntityModel(entity)

				if Inventory.Dumpsters[model] then
					return Inventory.OpenDumpster(entity)
				end
			end

			if entityType ~= 2 then return end

			Inventory.OpenTrunk(entity)
		end
	})

	lib.addKeybind({
		name = 'reloadweapon',
		description = locale('reload_weapon'),
		defaultKey = 'r',
		onPressed = function(self)
			if not currentWeapon or EnableWeaponWheel or not canUseItem(true) then return end

			if currentWeapon.ammo then
				if currentWeapon.metadata.durability > 0 then
					local slotId = Inventory.GetSlotIdWithItem(currentWeapon.ammo,
						{ type = currentWeapon.metadata.specialAmmo }, false)

					if slotId then
						useSlot(slotId)
					end
				else
					lib.notify({
						id = 'no_durability',
						type = 'error',
						description = locale('no_durability',
							currentWeapon.label)
					})
				end
			end
		end
	})

	hotbarBind = lib.addKeybind({
		name = 'hotbar',
		description = locale('disable_hotbar'),
		defaultKey = client.keys[3],
		onPressed = function()
			if hotbarAlwaysNui or EnableWeaponWheel or IsNuiFocused() or lib.progressActive() then return end
			SendNUIMessage({ action = 'toggleHotbar' })
		end
	})

	for i = 1, 5 do
		hotkeyBinds[i] = lib.addKeybind({
			name = ('hotkey%s'):format(i),
			description = locale('use_hotbar', i),
			defaultKey = tostring(i),
			onPressed = function()
				if invOpen or EnableWeaponWheel or not invHotkeys or IsNuiFocused() then return end
				useSlot(i)
			end
		})
	end

	registerCommands = nil
end

function client.closeInventory(server)
	-- because somehow people are triggering this when the inventory isn't loaded
	-- and they're incapable of debugging, and I can't repro on a fresh install
	if not client.interval then return end

	if invOpen then
		invOpen = nil
		pendingGive = nil
		lastPanelDist, lastPanelOwner, lastPanelOwnerId, lastPanelOwnerSent = nil, nil, nil, nil
		TriggerEvent('ox_inventory:uiClose')
		SendNUIMessage({ action = 'oxlynForceCompact', data = { enabled = false } })
		SetNuiFocus(false, false)
		SetNuiFocusKeepInput(false)

		-- Restore gameplay camera before blur fades out (prevents underworld flash + launch bugs)
		CharacterPreview.close()

		TriggerScreenblurFadeOut(500)
		closeTrunk()
		SendNUIMessage({ action = 'closeInventory' })
		SetInterval(client.interval, 200)

		Wait(200)

		if invOpen ~= nil then return end

		if not server and currentInventory then
			TriggerServerEvent('ox_inventory:closeInventory')
		end

		currentInventory = nil
		plyState.invOpen = false
		defaultInventory.coords = nil
	end
end

RegisterNetEvent('ox_inventory:closeInventory', client.closeInventory)
exports('closeInventory', client.closeInventory)

---@param data updateSlot[]
---@param weight number
local function updateInventory(data, weight)
	local changes = {}
	---@type table<string, number>
	local itemCount = {}

	if not PlayerData.inventory then return end

	for i = 1, #data do
		local v = data[i]
		if not v.inventory or v.inventory == cache.serverId then
			v.inventory = 'player'
			local item = v.item

			if currentWeapon and item and currentWeapon.slot == item.slot then
				if item.metadata then
					currentWeapon.metadata = item.metadata
					TriggerEvent('ox_inventory:currentWeapon', currentWeapon)
				else
					currentWeapon = Weapon.Disarm(currentWeapon, true)
				end
			end

			local curItem = PlayerData.inventory[item.slot]

			if curItem and curItem.name then
				itemCount[curItem.name] = (itemCount[curItem.name] or 0) - curItem.count
			end

			if item.count then
				itemCount[item.name] = (itemCount[item.name] or 0) + item.count
			end

			changes[item.slot] = item.count and item or false
			if not item.count then item.name = nil end
			PlayerData.inventory[item.slot] = item.name and item or nil
		end
	end

	SendNUIMessage({ action = 'refreshSlots', data = { items = data, itemCount = itemCount } })

	if weight ~= PlayerData.weight then client.setPlayerData('weight', weight) end

	for itemName, count in pairs(itemCount) do
		local item = Items(itemName)

		if item then
			item.count = item.count + count

			TriggerEvent('ox_inventory:itemCount', item.name, item.count)

			if count < 0 then
				if shared.framework == 'esx' then
					TriggerEvent('esx:removeInventoryItem', item.name, item.count)
				end

				if item.client and item.client.remove then
					item.client.remove(item.count)
				end
			elseif count > 0 then
				if shared.framework == 'esx' then
					TriggerEvent('esx:addInventoryItem', item.name, item.count)
				end

				if item.client and item.client.add then
					item.client.add(item.count)
				end
			end
		end
	end

	client.setPlayerData('inventory', PlayerData.inventory)
	TriggerEvent('ox_inventory:updateInventory', changes)
end

RegisterNetEvent('ox_inventory:updateSlots', function(items, weights)
	if source ~= '' and next(items) then updateInventory(items, weights) end
end)

RegisterNetEvent('ox_inventory:inventoryReturned', function(data)
	if source == '' then return end
	if currentWeapon then currentWeapon = Weapon.Disarm(currentWeapon) end

	lib.notify({ description = locale('items_returned') })
	client.closeInventory()

	local num, items = 0, {}

	for _, slotData in pairs(data[1]) do
		num = num + 1
		items[num] = { item = slotData, inventory = cache.serverId }
	end

	updateInventory(items, data[3])
end)

RegisterNetEvent('ox_inventory:inventoryConfiscated', function(message)
	if source == '' then return end
	if message then lib.notify({ description = locale('items_confiscated') }) end
	if currentWeapon then currentWeapon = Weapon.Disarm(currentWeapon) end

	client.closeInventory()

	local num, items = 0, {}

	for slot in pairs(PlayerData.inventory) do
		num = num + 1
		items[num] = { item = { slot = slot }, inventory = cache.serverId }
	end

	updateInventory(items, 0)
end)


---@param point CPoint
local function nearbyDrop(point)
	if GetResourceState('oxlyn_itemdrops') == 'started' then return end -- REALWRLD Item Drop Physics draws the drops while it runs
	if not point.instance or point.instance == currentInstance then
		---@diagnostic disable-next-line: param-type-mismatch
		DrawMarker(2, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 150,
			30, 30, 222, false, false, 0, true, false, false, false)
	end
end

---@param point CPoint
local function onEnterDrop(point)
	if GetResourceState('oxlyn_itemdrops') == 'started' then return end -- REALWRLD Item Drop Physics draws the drops while it runs
	if not point.instance or point.instance == currentInstance and not point.entity then
		local model = point.model or client.dropmodel

		-- Prevent breaking inventory on invalid point.model instead use default client.dropmodel
		if not IsModelValid(model) and not IsModelInCdimage(model) then
			model = client.dropmodel
		end
		lib.requestModel(model)

		local entity = CreateObject(model, point.coords.x, point.coords.y, point.coords.z, false, true, true)

		SetModelAsNoLongerNeeded(model)
		PlaceObjectOnGroundProperly(entity)
		FreezeEntityPosition(entity, true)
		SetEntityCollision(entity, false, true)

		point.entity = entity
	end
end

local function onExitDrop(point)
	local entity = point.entity

	if entity then
		Utils.DeleteEntity(entity)
		point.entity = nil
	end
end

DropPoints.instance = function() return currentInstance end
local createDrop = DropPoints.create

RegisterNetEvent('ox_inventory:createDrop', function(dropId, data, owner, slot)
	if client.drops then
		createDrop(dropId, data, true)
	end

	if owner == cache.serverId then
		if currentWeapon and currentWeapon.slot == slot then
			currentWeapon = Weapon.Disarm(currentWeapon)
		end

		if invOpen and #(GetEntityCoords(playerPed) - data.coords) <= 1 then
			if not cache.vehicle then
				client.openInventory('drop', dropId)
			else
				SendNUIMessage({
					action = 'setupInventory',
					data = { rightInventory = currentInventory }
				})
			end
		end
	end
end)

RegisterNetEvent('ox_inventory:removeDrop', function(dropId)
	if client.drops then
		local point = client.drops[dropId]

		if point then
			client.drops[dropId] = nil
			DropPoints.remove(point)
		end
	end
end)

---@type function?
local function setStateBagHandler(stateId)
	AddStateBagChangeHandler('invOpen', stateId, function(_, _, value)
		invOpen = value
	end)

	AddStateBagChangeHandler('invBusy', stateId, function(_, _, value)
		invBusy = value
	end)

	AddStateBagChangeHandler('canUseWeapons', stateId, function(_, _, value)
		if not value and currentWeapon then
			currentWeapon = Weapon.Disarm(currentWeapon)
		end
	end)

	AddStateBagChangeHandler('instance', stateId, function(_, _, value)
		currentInstance = value

		if client.drops then
			-- Iterate over known drops and remove any points in a different instance (ignoring no instance)
			for dropId, point in pairs(client.drops) do
				if point.instance then
					-- off the map either way (props / bag gone); kept in client.drops
					-- so it can be re-created when the player is back in its instance
					DropPoints.remove(point)

					if point.instance == value then
						-- Recreate the drop using data from the old point
						createDrop(dropId, point)
					end
				end
			end
		end
	end)

	AddStateBagChangeHandler('dead', stateId, function(_, _, value)
		Utils.WeaponWheel()
		PlayerData.dead = value
	end)

	AddStateBagChangeHandler('invHotkeys', stateId, function(_, _, value)
		invHotkeys = value
	end)

	setStateBagHandler = nil
end

lib.onCache('seat', function(seat)
	if seat then
		local hasWeapon = GetCurrentPedVehicleWeapon(cache.ped)

		if hasWeapon then
			return Utils.WeaponWheel(true)
		end
	end

	Utils.WeaponWheel(false)
end)

lib.onCache('vehicle', function(vehicle)
	if not invOpen then return end

	-- Player inventory while seated must stay open.
	-- Only close vehicle-bound inventories (glovebox/trunk) when leaving THAT vehicle.
	local invEntity = currentInventory and currentInventory.entity
	if not invEntity then return end

	if not vehicle or vehicle ~= invEntity then
		return client.closeInventory()
	end
end)

RegisterNetEvent('ox_inventory:setPlayerInventory', function(currentDrops, inventory, weight, player)
	if source == '' then return end

	---@class PlayerData
	---@field inventory table<number, SlotWithItem?>
	---@field weight number
	PlayerData = player
	PlayerData.id = cache.playerId
	PlayerData.source = cache.serverId
	PlayerData.maxWeight = shared.playerweight

	setmetatable(PlayerData, {
		__index = function(self, key)
			if key == 'ped' then
				return PlayerPedId()
			end
		end
	})

	if setStateBagHandler then setStateBagHandler(('player:%s'):format(cache.serverId)) end

	local ItemData = table.create(0, #Items)

	-- Per-item rarity tiers (data/itemRarity.lua), read by the UI + drop prompts.
	local rarities = client.rarity and (lib.load('data.itemRarity') or {}) or {}

	for _, v in pairs(Items --[[@as table<string, OxClientItem>]]) do
		local buttons = v.buttons and {} or nil

		if buttons then
			for i = 1, #v.buttons do
				buttons[i] = { label = v.buttons[i].label, group = v.buttons[i].group }
			end
		end

		ItemData[v.name] = {
			label = v.label,
			stack = v.stack,
			close = v.close,
			count = 0,
			description = v.description,
			buttons = buttons,
			ammoName = v.ammoname,
			image = v.client and v.client.image,
			rarity = rarities[v.name]
		}
	end

	for _, data in pairs(inventory) do
		local item = Items[data.name]

		if item then
			item.count = item.count + data.count
			ItemData[data.name].count = ItemData[data.name].count + data.count
			local add = item.client and item.client.add

			if add then
				add(item.count)
			end
		end
	end

	local phone = Items.phone

	if phone and phone.count < 1 then
		pcall(function()
			return exports.npwd:setPhoneDisabled(true)
		end)
	end

	client.setPlayerData('inventory', inventory)
	client.setPlayerData('weight', weight)
	currentWeapon = nil
	Weapon.ClearAll()

	local uiLocales = {}
	local locales = lib.getLocales()

	for k, v in pairs(locales) do
		if k:find('^ui_') then
			uiLocales[k] = v
		end
	end

	uiLocales['$'] = locales['$']
	uiLocales.ammo_type = locales.ammo_type

	do
		-- Same rule: a broken drop must not keep the player from loading.
		local ok, err = pcall(DropPoints.load, currentDrops)

		if not ok then
			lib.print.error(('drop points failed to load: %s'):format(err))
		end
	end

	local hasTextUi
	local uiOptions = { icon = 'fa-id-card' }

	---@param point CPoint
	local function nearbyLicense(point)
		---@diagnostic disable-next-line: param-type-mismatch
		DrawMarker(2, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 30,
			150, 30, 222, false, false, 0, true, false, false, false)

		if point.isClosest and point.currentDistance < 1.2 then
			if not hasTextUi then
				hasTextUi = point
				lib.showTextUI(point.message, uiOptions)
			end

			if IsControlJustReleased(0, 38) then
				lib.callback('ox_inventory:buyLicense', 1000, function(success, message)
					if success ~= nil then
						lib.notify({
							id = message,
							type = success == false and 'error' or 'success',
							description = locale(message, locale('license', point.type:gsub("^%l", string.upper)))
						})
					end
				end, point.invId)
			end
		elseif hasTextUi == point then
			hasTextUi = false
			lib.hideTextUI()
		end
	end

	for id, data in pairs(lib.load('data.licenses')) do
		lib.points.new({
			coords = data.coords,
			distance = 16,
			inv = 'license',
			type = data.name,
			price = data.price,
			invId = id,
			nearby = nearbyLicense,
			message = ('**%s**  \n%s'):format(locale('purchase_license', data.name),
				locale('interact_prompt', GetControlInstructionalButton(0, 38, true):sub(3)))
		})
	end

	-- Wait for UI to load with timeout and retry mechanism
	local uiLoadTimeout = 10000 -- 10 seconds timeout
	local startTime = GetGameTimer()
	local reloadAttempts = 0
	local maxReloads = 2


	while not client.uiLoaded do
		Wait(100)

		local elapsed = GetGameTimer() - startTime

		if elapsed > uiLoadTimeout then
			reloadAttempts = reloadAttempts + 1

			if reloadAttempts <= maxReloads then

				-- Force NUI frame reload
				SendNUIMessage({ action = 'forceReload' })
				Wait(500)
				SetNuiFocus(false, false)

				-- Reset timer for next attempt
				startTime = GetGameTimer()
			else
				client.uiLoaded = true -- Force continue
				break
			end
		end
	end


	SendNUIMessage({
		action = 'init',
		data = {
			locale = uiLocales,
			items = ItemData,
			leftInventory = {
				id = cache.playerId,
				slots = shared.playerslots,
				items = PlayerData.inventory,
				maxWeight = shared.playerweight,
			},
			imagepath = client.imagepath
		}
	})

	pushHotbarKeys()

	PlayerData.loaded = true

	lib.notify({ description = locale('inventory_setup') })
	Shops.refreshShops()
	Inventory.Stashes()
	Inventory.Evidence()

	if registerCommands then registerCommands() end

	TriggerEvent('ox_inventory:updateInventory', PlayerData.inventory)

	local lastHealth, lastArmor
	client.interval = SetInterval(function()
		if invOpen == false then
			playerCoords = GetEntityCoords(playerPed)

			if currentWeapon and IsPedUsingActionMode(playerPed) then
				SetPedUsingActionMode(playerPed, false, -1, 'DEFAULT_ACTION')
			end
		elseif invOpen == true then
			if not canOpenInventory() then
				client.closeInventory()
			else
				playerCoords = GetEntityCoords(playerPed)

				if currentInventory and not currentInventory.ignoreSecurityChecks then
					local maxDistance = (currentInventory.distance or currentInventory.type == 'stash' and 4.8 or 1.8) +
						0.2

					if currentInventory.coords then
						pushPanelMeta(#(playerCoords - currentInventory.coords), currentInventory.owner)
					end

					if currentInventory.type == 'otherplayer' then
						local id = GetPlayerFromServerId(currentInventory.id)
						local ped = GetPlayerPed(id)
						local pedCoords = GetEntityCoords(ped)

						if not id or #(playerCoords - pedCoords) > maxDistance or not (client.hasGroup(shared.police) or canOpenTarget(ped)) then
							client.closeInventory()
							lib.notify({
								id = 'inventory_lost_access',
								type = 'error',
								description = locale(
									'inventory_lost_access')
							})
						else
							TaskTurnPedToFaceCoord(playerPed, pedCoords.x, pedCoords.y, pedCoords.z, 50)
						end
					elseif currentInventory.coords and (#(playerCoords - currentInventory.coords) > maxDistance or canOpenTarget(playerPed)) then
						client.closeInventory()
						lib.notify({
							id = 'inventory_lost_access',
							type = 'error',
							description = locale(
								'inventory_lost_access')
						})
					end
				end
			end
		end

		local health = GetEntityHealth(playerPed) - 100
		if health < 0 then health = 0 end
		if health > 100 then health = 100 end

		if health ~= lastHealth then
			lastHealth = health
			SendNUIMessage({ action = 'updatePlayerHealth', data = health })
		end

		local armor = GetPedArmour(playerPed)
		if armor ~= lastArmor then
			lastArmor = armor
			SendNUIMessage({ action = 'updatePlayerArmor', data = armor })
		end

		if client.parachute and GetPedParachuteState(playerPed) ~= -1 then
			Utils.DeleteEntity(client.parachute[1])
			client.parachute = false
		end

		if EnableWeaponWheel then return end

		local weaponHash = GetSelectedPedWeapon(playerPed)

		if currentWeapon then
			if weaponHash ~= currentWeapon.hash and currentWeapon.timer then
				local weaponCount = Items[currentWeapon.name] and Items[currentWeapon.name].count

				if weaponCount > 0 then
					SetCurrentPedWeapon(playerPed, currentWeapon.hash, true)
					SetAmmoInClip(playerPed, currentWeapon.hash, currentWeapon.metadata.ammo)
					SetPedCurrentWeaponVisible(playerPed, true, false, false, false)

					weaponHash = GetSelectedPedWeapon(playerPed)
				end

				if weaponHash ~= currentWeapon.hash then
					currentWeapon = Weapon.Disarm(currentWeapon, true)
				end
			end
		elseif client.weaponmismatch and not client.ignoreweapons[weaponHash] then
			local weaponType = GetWeapontypeGroup(weaponHash)

			if weaponType ~= 0 and weaponType ~= `GROUP_UNARMED` then
				Weapon.Disarm(currentWeapon, true)
			end
		end
	end, 200)

	local playerId = cache.playerId
	local EnableKeys = client.enablekeys
	local DisablePlayerVehicleRewards = DisablePlayerVehicleRewards
	local DisableAllControlActions = DisableAllControlActions
	local HideHudAndRadarThisFrame = HideHudAndRadarThisFrame
	local EnableControlAction = EnableControlAction
	local DisablePlayerFiring = DisablePlayerFiring
	local HudWeaponWheelIgnoreSelection = HudWeaponWheelIgnoreSelection
	local DisableControlAction = DisableControlAction
	local IsPedShooting = IsPedShooting
	local IsControlJustReleased = IsControlJustReleased

	client.tick = SetInterval(function()
		DisablePlayerVehicleRewards(playerId)

		if invOpen then
			DisableAllControlActions(0)
			HideHudAndRadarThisFrame()

			for i = 1, #EnableKeys do
				EnableControlAction(0, EnableKeys[i], true)
			end

			if currentInventory.type == 'newdrop' then
				EnableControlAction(0, 30, true)
				EnableControlAction(0, 31, true)
			end

			-- Keep driving when inventory is open (3D ped preview must not freeze the car)
			if cache.vehicle then
				EnableControlAction(0, 71, true)  -- accelerate
				EnableControlAction(0, 72, true)  -- brake
				EnableControlAction(0, 59, true)  -- veh move LR
				EnableControlAction(0, 63, true)  -- veh turn left
				EnableControlAction(0, 64, true)  -- veh turn right
				EnableControlAction(0, 76, true)  -- handbrake
				EnableControlAction(0, 75, true)  -- exit vehicle (optional escape)
			end
		else
			if invBusy then
				DisableControlAction(0, 23, true)
				DisableControlAction(0, 36, true)
			end

			if usingItem or invOpen or IsPedCuffed(playerPed) then
				DisablePlayerFiring(playerId, true)
			end

			if not EnableWeaponWheel then
				HudWeaponWheelIgnoreSelection()
				DisableControlAction(0, 37, true)
			end

			if currentWeapon and currentWeapon.timer then
				DisableControlAction(0, 80, true)
				DisableControlAction(0, 140, true)

				if currentWeapon.metadata.durability <= 0 or not currentWeapon.timer then
					DisablePlayerFiring(playerId, true)
				elseif client.aimedfiring and not currentWeapon.melee and currentWeapon.group ~= `GROUP_PETROLCAN` and not IsPlayerFreeAiming(playerId) then
					DisablePlayerFiring(playerId, true)
				end

				local weaponAmmo = currentWeapon.metadata.ammo

				if not invBusy and currentWeapon.timer ~= 0 and currentWeapon.timer < GetGameTimer() then
					currentWeapon.timer = 0

					if weaponAmmo then
						TriggerServerEvent('ox_inventory:updateWeapon', 'ammo', weaponAmmo)

						if client.autoreload and currentWeapon.ammo and GetAmmoInPedWeapon(playerPed, currentWeapon.hash) == 0 then
							local slotId = Inventory.GetSlotIdWithItem(currentWeapon.ammo,
								{ type = currentWeapon.metadata.specialAmmo }, false)

							if slotId then
								CreateThread(function() useSlot(slotId) end)
							end
						end
					elseif currentWeapon.metadata.durability then
						TriggerServerEvent('ox_inventory:updateWeapon', 'melee', currentWeapon.melee)
						currentWeapon.melee = 0
					end
				elseif weaponAmmo then
					if IsPedShooting(playerPed) then
						local currentAmmo
						local durabilityDrain = Items[currentWeapon.name].durability

						if currentWeapon.group == `GROUP_PETROLCAN` or currentWeapon.group == `GROUP_FIREEXTINGUISHER` then
							currentAmmo = weaponAmmo - durabilityDrain < 0 and 0 or weaponAmmo - durabilityDrain
							currentWeapon.metadata.durability = currentAmmo
							currentWeapon.metadata.ammo = (weaponAmmo < currentAmmo) and 0 or currentAmmo

							if currentAmmo <= 0 then
								SetPedInfiniteAmmo(playerPed, false, currentWeapon.hash)
							end
						else
							currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)

							if currentAmmo < weaponAmmo then
								currentAmmo = (weaponAmmo < currentAmmo) and 0 or currentAmmo
								currentWeapon.metadata.ammo = currentAmmo
								currentWeapon.metadata.durability = currentWeapon.metadata.durability -
									(durabilityDrain * math.abs((weaponAmmo or 0.1) - currentAmmo))
							end
						end

						if currentAmmo <= 0 then
							if cache.vehicle then
								TaskSwapWeapon(playerPed, true)
							end

							currentWeapon.timer = GetGameTimer() + 200
						else
							currentWeapon.timer = GetGameTimer() + (GetWeaponTimeBetweenShots(currentWeapon.hash) * 1000) +
								100
						end
					end
				elseif currentWeapon.throwable then
					if not invBusy and IsControlPressed(0, 24) then
						invBusy = 1

						CreateThread(function()
							local weapon = currentWeapon

							while currentWeapon and (not IsPedWeaponReadyToShoot(cache.ped) or IsDisabledControlPressed(0, 24)) and GetSelectedPedWeapon(playerPed) == weapon.hash do
								Wait(0)
							end

							if GetSelectedPedWeapon(playerPed) == weapon.hash then Wait(700) end

							while IsPedPlantingBomb(playerPed) do Wait(0) end

							TriggerServerEvent('ox_inventory:updateWeapon', 'throw', nil, weapon.slot)
							plyState:set('invBusy', false, true)

							currentWeapon = nil

							RemoveWeaponFromPed(playerPed, weapon.hash)
							TriggerEvent('ox_inventory:currentWeapon')
						end)
					end
				elseif currentWeapon.melee and IsControlJustReleased(0, 24) and IsPedPerformingMeleeAction(playerPed) then
					currentWeapon.melee = currentWeapon.melee + 1
					currentWeapon.timer = GetGameTimer() + 200
				end
			end
		end
	end)

	plyState:set('invBusy', false, true)
	plyState:set('invOpen', false, false)
	plyState:set('invHotkeys', true, false)
	plyState:set('canUseWeapons', true, false)
	collectgarbage('collect')
end)

AddEventHandler('onResourceStop', function(resourceName)
	if shared.resource == resourceName then
		client.onLogout()
	end
end)

RegisterNetEvent('ox_inventory:viewInventory', function(left, right)
	if source == '' then return end

	plyState.invOpen = true

	-- REALWRLD (merged 2026-10-24): authoritative UI-open signal for modules
	-- (ped preview), plus the airborne forced-compact flag for the UI.
	TriggerEvent('ox_inventory:uiOpen', right and right.type or nil)

	do
		local ped = PlayerPedId()
		local airborne = IsPedFalling(ped) or IsPedInParachuteFreeFall(ped) or IsPedRagdoll(ped) or IsPedSwimming(ped) or IsEntityInAir(ped)
		SendNUIMessage({ action = 'oxlynForceCompact', data = { enabled = airborne } })
	end

	SetInterval(client.interval, 100)
	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(true)
	closeTrunk()

	currentInventory = right or defaultInventory
	currentInventory.ignoreSecurityChecks = true
	currentInventory.type = 'inspect'
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = currentInventory
		}
	})

	CharacterPreview.open()
end)

-- uiLoaded is registered in client_exports.lua (the page preloads and posts before this file runs).

RegisterNUICallback('getItemData', function(itemName, cb)
	cb(Items[itemName])
end)

RegisterNUICallback('removeComponent', function(data, cb)
	cb(1)

	if not currentWeapon then
		return TriggerServerEvent('ox_inventory:updateWeapon', 'component', data)
	end

	if data.slot ~= currentWeapon.slot then
		return lib.notify({ id = 'weapon_hand_wrong', type = 'error', description = locale('weapon_hand_wrong') })
	end

	local itemSlot = PlayerData.inventory[currentWeapon.slot]

	if not itemSlot then return end

	for _, component in pairs(Items[data.component].client.component) do
		if HasPedGotWeaponComponent(playerPed, currentWeapon.hash, component) then
			for k, v in pairs(itemSlot.metadata.components) do
				if v == data.component then
					local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component', k)

					if success then
						RemoveWeaponComponentFromPed(playerPed, currentWeapon.hash, component)
						TriggerEvent('ox_inventory:updateWeaponComponent', 'removed', component, data.component)
					end

					break
				end
			end
		end
	end
end)

RegisterNUICallback('removeAmmo', function(slot, cb)
	cb(1)
	local slotData = PlayerData.inventory[slot]

	if not slotData or not slotData.metadata.ammo or slotData.metadata.ammo == 0 then return end

	local success = lib.callback.await('ox_inventory:removeAmmoFromWeapon', false, slot)

	if success and currentWeapon and slot == currentWeapon.slot then
		SetPedAmmo(playerPed, currentWeapon.hash, 0)
	end
end)

RegisterNUICallback('useItem', function(slot, cb)
	useSlot(slot --[[@as number]])
	cb(1)
end)

local function giveItemToTarget(serverId, slotId, count)
	if type(slotId) ~= 'number' then return TypeError('slotId', 'number', type(slotId)) end
	if count and type(count) ~= 'number' then return TypeError('count', 'number', type(count)) end

	if currentWeapon and slotId == currentWeapon.slot then
		currentWeapon = Weapon.Disarm(currentWeapon)
	end

	Utils.PlayAnim(0, 'mp_common', 'givetake1_a', 1.0, 1.0, 2000, 50, 0.0, 0, 0, 0)

	local notification = lib.callback.await('ox_inventory:giveItem', false, slotId, serverId, count or 0)

	if notification then
		lib.notify({ type = 'error', description = locale(table.unpack(notification)) })
	end
end

exports('giveItemToTarget', giveItemToTarget)

local function isGiveTargetValid(ped, coords)
	if cache.vehicle and GetVehiclePedIsIn(ped, false) == cache.vehicle then
		return true
	end

	local entity = Utils.Raycast(1|2|4|8|16, coords + vec3(0, 0, 0.5), 0.2)

	return entity == ped and IsEntityVisible(ped)
end

RegisterNUICallback('giveItem', function(data, cb)
	cb(1)

	if usingItem then return end

	-- REALWRLD in-UI give target picker (merged 2026-10-24): with the picker on
	-- (RWInv.Hud.givePicker, default), GIVE opens the target list inside
	-- the inventory UI; nothing is handed over until the giver picks.
	if hudCfg.givePicker ~= false then
		local coords = cache.vehicle and GetWorldPositionOfEntityBone(playerPed, 0) or GetEntityCoords(playerPed)
		local nearbyPlayers = lib.getNearbyPlayers(coords, tonumber(hudCfg.giveRange) or 3.0)
		local giveList, n = {}, 0

		for i = 1, #nearbyPlayers do
			local option = nearbyPlayers[i]

			if isGiveTargetValid(option.ped, option.coords) then
				local playerName = GetPlayerName(option.id)
				option.id = GetPlayerServerId(option.id)
				option.label = playerName
				n += 1
				giveList[n] = option
			end
		end

		if n == 0 then
			return lib.notify({ id = 'rw_give_nobody', type = 'error', description = locale('rw_give_nobody') })
		end

		local targets = {}
		pendingGive = { slot = data.slot, count = data.count, ids = {}, expires = GetGameTimer() + 15000 }

		table.sort(giveList, function(a, b) return #(coords - a.coords) < #(coords - b.coords) end)

		for i = 1, n do
			local o = giveList[i]
			targets[i] = { id = o.id, name = tostring(o.label), dist = math.floor(#(coords - o.coords) * 10 + 0.5) / 10 }
			pendingGive.ids[o.id] = true
		end

		return SendNUIMessage({ action = 'oxlynGiveTargets', data = { slot = data.slot, count = data.count, targets = targets } })
	end

	if client.giveplayerlist then
		local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(playerPed), 3.0)
		local nearbyCount = #nearbyPlayers

		if nearbyCount == 0 then
			return lib.notify({
				id = 'inventory_give_nearby',
				type = 'error',
				description = 'No one nearby to give to',
			})
		end

		if nearbyCount == 1 then
			local option = nearbyPlayers[1]

			if not isGiveTargetValid(option.ped, option.coords) then return end

			return giveItemToTarget(GetPlayerServerId(option.id), data.slot, data.count)
		end

		local giveList, n = {}, 0

		for i = 1, #nearbyPlayers do
			local option = nearbyPlayers[i]

			if isGiveTargetValid(option.ped, option.coords) then
				local playerName = GetPlayerName(option.id)
				option.id = GetPlayerServerId(option.id)
				---@diagnostic disable-next-line: inject-field
				option.label = ('[%s] %s'):format(option.id, playerName)
				n = n + 1
				giveList[n] = option
			end
		end

		if n == 0 then
			return lib.notify({
				id = 'inventory_give_nearby',
				type = 'error',
				description = 'No one nearby to give to',
			})
		end

		lib.registerMenu({
			id = 'ox_inventory:givePlayerList',
			title = 'Give item',
			options = giveList,
		}, function(selected)
			giveItemToTarget(giveList[selected].id, data.slot, data.count)
		end)

		return lib.showMenu('ox_inventory:givePlayerList')
	end

	if cache.vehicle then
		local seats = GetVehicleMaxNumberOfPassengers(cache.vehicle) - 1

		if seats >= 0 then
			local passenger = GetPedInVehicleSeat(cache.vehicle, cache.seat - 2 * (cache.seat % 2) + 1)

			if passenger ~= 0 and IsEntityVisible(passenger) then
				return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)), data.slot, data
					.count)
			end
		end

		return
	end

	local entity = Utils.Raycast(1|2|4|8|16, GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 3.0, 0.5), 0.2)

	if entity and IsPedAPlayer(entity) and IsEntityVisible(entity) and #(GetEntityCoords(playerPed, true) - GetEntityCoords(entity, true)) < 3.0 then
		return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)), data.slot, data.count)
	end
end)

RegisterNUICallback('rwGiveTo', function(data, cb)
	cb(1)
	if not pendingGive or GetGameTimer() > pendingGive.expires then pendingGive = nil return end
	local id = tonumber(data and data.id)
	if not id or not pendingGive.ids[id] then return end
	local p = pendingGive
	pendingGive = nil
	giveItemToTarget(id, p.slot, p.count)
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynGiveTo', function(data, cb)
	cb(1)
	if not pendingGive or GetGameTimer() > pendingGive.expires then pendingGive = nil return end
	local id = tonumber(data and data.id)
	if not id or not pendingGive.ids[id] then return end
	local p = pendingGive
	pendingGive = nil
	giveItemToTarget(id, p.slot, p.count)
end)

RegisterNUICallback('rwGiveCancel', function(_, cb)
	pendingGive = nil
	cb(1)
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynGiveCancel', function(_, cb)
	pendingGive = nil
	cb(1)
end)

-- The floating hotbar's always-on mode is web-side; the NUI reports it so
-- the keybind can skip the redundant toggle pulse.
RegisterNUICallback('rwHotbarMode', function(data, cb)
	hotbarAlwaysNui = type(data) == 'table' and data.always == true
	cb(1)
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynHotbarMode', function(data, cb)
	hotbarAlwaysNui = type(data) == 'table' and data.always == true
	cb(1)
end)

RegisterNUICallback('useButton', function(data, cb)
	useButton(data.id, data.slot)
	cb(1)
end)

RegisterNUICallback('throwItem', function(data, cb)
	cb(1)
	if type(data) ~= 'table' or not data.slot then return end
	if cache.vehicle or IsPedFalling(playerPed) or IsPedRagdoll(playerPed) then
		return lib.notify({ type = 'error', description = 'You cannot throw right now' })
	end

	local slotItem = PlayerData.inventory and PlayerData.inventory[data.slot]
	if not slotItem or not slotItem.name then
		return lib.notify({ type = 'error', description = 'Item not found' })
	end

	local itemData = Items[slotItem.name]
	if (itemData and (itemData.weapon or itemData.permanent)) or slotItem.name:lower():find('^weapon_') then
		return lib.notify({ type = 'error', description = 'That item cannot be thrown' })
	end

	CreateThread(function()
		client.closeInventory()
		Wait(150)
		if RWThrow and RWThrow.Start then
			RWThrow.Start(slotItem)
		else
			exports.ox_inventory:startThrow(slotItem)
		end
	end)
end)

RegisterNUICallback('exit', function(_, cb)
	client.closeInventory()
	cb(1)
end)

-- NOTE: ox_inventory:startCrafting callback is registered in modules/crafting/client.lua
-- Do NOT register it here to avoid duplicate callback issues

local swapActive = false

---Synchronise and validate all item movement between the NUI and server.
RegisterNUICallback('swapItems', function(data, cb)
	if swapActive or not invOpen or invBusy or usingItem then return cb(false) end

	swapActive = true

	if data.toType == 'newdrop' then
		if cache.vehicle or IsPedFalling(playerPed) then
			swapActive = false
			return cb(false)
		end

		local coords = GetEntityCoords(playerPed)

		if IsEntityInWater(playerPed) then
			local destination = vec3(coords.x, coords.y, -200)
			local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y,
				destination.z, 511, cache.ped, 4)

			while true do
				Wait(0)
				local retval, hit, endCoords = GetShapeTestResult(handle)

				if retval ~= 1 then
					if not hit then return end

					data.coords = vec3(endCoords.x, endCoords.y, endCoords.z + 1.0)

					break
				end
			end
		else
			data.coords = coords
		end
	end

	if currentInstance then
		data.instance = currentInstance
	end

	if currentWeapon and data.fromType ~= data.toType then
		if (data.fromType == 'player' and data.fromSlot == currentWeapon.slot) or (data.toType == 'player' and data.toSlot == currentWeapon.slot) then
			currentWeapon = Weapon.Disarm(currentWeapon, true)
		end
	end

	local success, response, weaponSlot = lib.callback.await('ox_inventory:swapItems', false, data)
	swapActive = false

	cb(success or false)

	if success then
		if weaponSlot and currentWeapon then
			currentWeapon.slot = weaponSlot
		end

		if response then
			updateInventory(response.items, response.weight)
		end
	elseif response then
		if type(response) == 'table' then
			SendNUIMessage({ action = 'refreshSlots', data = { items = response } })
		else
			lib.notify({ type = 'error', description = locale(response) })
		end
	end
end)

RegisterNUICallback('buyItem', function(data, cb)
	---@type boolean, false | { [1]: number, [2]: SlotWithItem, [3]: SlotWithItem | false, [4]: number}, NotifyProps
	local response, data, message = lib.callback.await('ox_inventory:buyItem', false, data)

	if data then
		updateInventory({
			{
				item = data[2],
				inventory = cache.serverId
			}
		}, data[4])

		if data[3] then
			SendNUIMessage({
				action = 'refreshSlots',
				data = {
					items = {
						{
							item = data[3],
							inventory = 'shop'
						}
					}
				}
			})
		end
	end

	if message then
		lib.notify(message)
	end

	cb(response == true)
end)

RegisterNUICallback('craftItem', function(data, cb)
	-- Check if this is being called from standard crafting UI (needs currentInventory)
	-- If currentInventory is nil, this may be a custom forge UI call which is handled elsewhere
	if not currentInventory then
		cb(false)
		return
	end

	cb(true)

	local id, index = currentInventory.id, currentInventory.index

	for i = 1, data.count do
		local success, response = lib.callback.await('ox_inventory:craftItem', 200, id, index, data.fromSlot, data
			.toSlot)

		if not success then
			if response then lib.notify({ type = 'error', description = locale(response or 'cannot_perform') }) end
			break
		end
	end

	if not currentInventory or currentInventory.type ~= 'crafting' then
		client.openInventory('crafting', { id = id, index = index })
	end
end)

lib.callback.register('ox_inventory:getVehicleData', function(netid)
	local entity = NetworkGetEntityFromNetworkId(netid)

	if entity then
		return GetEntityModel(entity), GetVehicleClass(entity)
	end
end)

-- Admin shop browser (NUI)
RegisterNUICallback('isInventoryAdmin', function(_, cb)
	local ok = lib.callback.await('ox_inventory:isInventoryAdmin', false)
	cb(ok == true)
end)

RegisterNUICallback('getAdminShops', function(_, cb)
	local list = lib.callback.await('ox_inventory:getAdminShops', false)
	cb(list or {})
end)

RegisterNUICallback('openAdminShop', function(data, cb)
	local left, right = lib.callback.await('ox_inventory:openAdminShop', false, data)
	if not left or not right then
		cb(false)
		return
	end

	if not invOpen then
		invOpen = true
		plyState.invOpen = true
		SetNuiFocus(true, true)
		SetNuiFocusKeepInput(true)
		SetInterval(client.interval, 100)
	end

	-- Admin shop is a dual-panel buy UI — do not open the character studio over it
	CharacterPreview.close()

	currentInventory = right
	currentInventory.ignoreSecurityChecks = true
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = right,
		}
	})

	cb(true)
end)

require 'modules.rw_loader.client'

exports('sendNuiMessage', function(payload)
    SendNUIMessage(payload)
end)

RegisterNUICallback('ensureCharacterPreview', function(_, cb)
	if not CharacterPreview.isOpen or not CharacterPreview.isOpen() then
		CharacterPreview.open()
	end
	cb(1)
end)

RegisterNUICallback('closeCharacterPreview', function(_, cb)
	CharacterPreview.close()
	cb(1)
end)

-- Panels app (Phase 5): the trade window's click-to-add picker reads the
-- player's own items (drags cannot cross from the Creator UI iframe).
RegisterNUICallback('rwKeyfobPlates', function(data, cb)
    local item = data and data.slot and PlayerData.inventory and PlayerData.inventory[data.slot]
    if not item then return cb({}) end
    cb({ name = item.name, plates = item.metadata and item.metadata.plates or {} })
end)

-- Shell tooltip injector: full instance data for the hovered player slot,
-- so the tooltip can render the item's detailed metadata block (and the
-- keyfob's stored plates) again. The Creator app only surfaces a fixed
-- row set natively; everything else on the item rides through here.
RegisterNUICallback('rwItemDetails', function(data, cb)
    local item = data and data.slot and PlayerData.inventory and PlayerData.inventory[data.slot]
    if not item then return cb(false) end
    cb({
        name = item.name,
        label = item.label,
        count = item.count,
        weight = item.weight,
        metadata = item.metadata or {},
    })
end)

-- Weapon inspect (3D customization): the app has no entry for it, so the
-- shell's context-menu injector calls this bridge; the customization
-- module does the rest (closes the inventory, spawns the 3D preview).
RegisterNUICallback('rwWeaponInspect', function(data, cb)
    local item = data and data.slot and PlayerData.inventory and PlayerData.inventory[data.slot]
    if not item or not item.name or not item.name:lower():find('^weapon_') then
        return cb(false)
    end
    cb(true)
    local ok, err = pcall(function()
        exports.ox_inventory:handleWeaponPreview({ slot = data.slot })
    end)
    if not ok then print(('[rw] weapon inspect bridge failed: %s'):format(err)) end
end)

RegisterNUICallback('rwTradeItems', function(_, cb)
    cb(exports.ox_inventory:GetPlayerItems())
end)
