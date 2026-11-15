-- Ground Pickup Server Callbacks
-- Handles item retrieval from ground drops using loot modal

if not lib then return end

-- Direct require of Inventory module (not via event handler which fires too early)
local Inventory = require 'modules.inventory.server'

-- Get items from a ground drop for loot modal
lib.callback.register('ox_inventory:getGroundItems', function(source, dropId)
    if not Inventory then
        return nil
    end

    -- Handle dropId format - may be number or string like "drop-123"
    local drop = Inventory(dropId)

    if not drop then
        -- Try with 'drop-' prefix if just a number was passed
        if type(dropId) == 'number' or tonumber(dropId) then
            drop = Inventory('drop-' .. tostring(dropId))
        end
    end

    if not drop or drop.type ~= 'drop' then
        return nil
    end

    -- Check distance
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local dropCoords = drop.coords

    if not dropCoords then
        return nil
    end

    local distance = #(playerCoords - dropCoords)
    if distance > 8.0 then
        return nil
    end

    -- Format items for loot modal
    local items = {}
    local itemCount = 0

    if drop.items then
        for slot, item in pairs(drop.items) do
            if item then
                itemCount = itemCount + 1
                items[slot] = {
                    slot = slot,
                    name = item.name,
                    label = item.label,
                    count = item.count,
                    metadata = item.metadata,
                    weight = item.weight,
                    durability = item.metadata and item.metadata.durability,
                }
            end
        end
    end

    return items
end)

-- Take a single item from ground drop
lib.callback.register('ox_inventory:takeGroundItem', function(source, dropId, slot)
    if not Inventory then return false end

    local drop = Inventory(dropId)

    -- Handle dropId format
    if not drop and (type(dropId) == 'number' or tonumber(dropId)) then
        drop = Inventory('drop-' .. tostring(dropId))
        dropId = 'drop-' .. tostring(dropId)
    end

    local player = Inventory(source)

    if not drop or not player or drop.type ~= 'drop' then
        return false
    end

    -- Check distance
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local dropCoords = drop.coords

    if not dropCoords or #(playerCoords - dropCoords) > 8.0 then
        return false
    end

    local item = drop.items[slot]
    if not item then return false end

    -- Try to add to player inventory
    local success = Inventory.AddItem(player, item.name, item.count, item.metadata)

    if success then
        -- Remove from drop
        Inventory.SetSlot(drop, nil, -item.count, nil, slot)

        -- Check if drop is empty
        local hasItems = false
        for _, v in pairs(drop.items) do
            if v then
                hasItems = true
                break
            end
        end

        if not hasItems then
            TriggerClientEvent('ox_inventory:removeDrop', -1, dropId)
        end

        return true
    end

    return false
end)

-- Take all items from ground drop
lib.callback.register('ox_inventory:takeAllGroundItems', function(source, dropId)
    if not Inventory then return false end

    local drop = Inventory(dropId)

    -- Handle dropId format
    if not drop and (type(dropId) == 'number' or tonumber(dropId)) then
        drop = Inventory('drop-' .. tostring(dropId))
        dropId = 'drop-' .. tostring(dropId)
    end

    local player = Inventory(source)

    if not drop or not player or drop.type ~= 'drop' then
        return false
    end

    -- Check distance
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local dropCoords = drop.coords

    if not dropCoords or #(playerCoords - dropCoords) > 8.0 then
        return false
    end

    local takenAny = false

    for slot, item in pairs(drop.items) do
        if item then
            local success = Inventory.AddItem(player, item.name, item.count, item.metadata)

            if success then
                Inventory.SetSlot(drop, nil, -item.count, nil, slot)
                takenAny = true
            end
        end
    end

    -- Check if drop is empty
    local hasItems = false
    for _, v in pairs(drop.items) do
        if v then
            hasItems = true
            break
        end
    end

    if not hasItems then
        TriggerClientEvent('ox_inventory:removeDrop', -1, dropId)
    end

    return takenAny
end)
