-- Registers core exports before the rest of ox_inventory client loads.
if not lib then return end

-- The NUI page preloads and posts uiLoaded as soon as its bundle mounts,
-- before client.lua reaches its own registration -- the post got an empty
-- response (the 'Unexpected end of JSON input' rejection). Register here,
-- in the first client file that runs; client.lua's copy is removed.
RegisterNUICallback('uiLoaded', function(_, cb)
    if client then client.uiLoaded = true end
    cb(1)
end)

PlayerData = PlayerData or {}

local function searchNotReady(search)
	if search == 'count' or search == 2 then return 0 end
	if search == 'slots' or search == 1 then return {} end
	return false
end

exports('Search', function(search, item, metadata)
	if not PlayerData.loaded or not PlayerData.inventory then
		return searchNotReady(search)
	end

	local impl = rawget(_G, '__ox_inventory_search')
	if impl then
		return impl(search, item, metadata)
	end

	return searchNotReady(search)
end)

exports('GetPlayerItems', function()
	return PlayerData.inventory
end)

exports('GetPlayerWeight', function()
	return PlayerData.weight or 0
end)

exports('GetPlayerMaxWeight', function()
	return PlayerData.maxWeight or 30000
end)

exports('Items', function(item)
	local impl = rawget(_G, '__ox_inventory_items')
	if impl then return impl(item) end
end)
