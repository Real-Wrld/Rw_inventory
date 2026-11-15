-- s_place.lua  –  Server-side item placement / give for bablo-throwitems

if GetCurrentResourceName() ~= "bablo-throwitems" then
    error("Resource name must be 'bablo-throwitems'")
    return
end

-- ─── Helper ───────────────────────────────────────────────────────────────────

local function GetItemLabel(itemName)
    if Inventory.getItemLabel then
        return Inventory:getItemLabel(itemName) or itemName
    end
    return itemName
end

-- ─── place:finalize ───────────────────────────────────────────────────────────

RegisterNetEvent("bablo-throwitems:place:finalize")
AddEventHandler("bablo-throwitems:place:finalize", function(itemName, slotIndex, propModel, placedCoords, placedRot)
    local playerId = source
    if not (itemName and slotIndex) or not placedCoords then return end

    -- Validate player ped exists
    local ped = GetPlayerPed(playerId)
    if not (ped and DoesEntityExist(ped)) then return end

    -- Server-side distance check (client max + 2 m tolerance)
    local maxDist = (Config.PlaceMaxDistance or 5.0) + 2.0
    if #(GetEntityCoords(ped) - placedCoords) > maxDist then return end

    -- Read metadata before removing
    local existingItem = Inventory:getSpecificPlayerItem(playerId, { slot = slotIndex })
    local metadata     = existingItem and existingItem.metadata or nil

    local label = GetItemLabel(itemName)

    -- Remove item from inventory
    local removed = Inventory:removeSpecificPlayerItem(
        playerId, { item = itemName, slot = slotIndex }, 1)
    if not removed then return end

    if sendWebhook then
        sendWebhook(playerId, "PLACED_ITEM", label)
    end

    local rotation = placedRot or vector3(0.0, 0.0, 0.0)
    local prop     = propModel or Config.DefaultProp

    if CreateGroundItem then
        CreateGroundItem({
            itemName  = itemName,
            label     = label,
            metadata  = metadata,
            propModel = prop,
            coords    = placedCoords,
            rotation  = rotation,
            droppedBy = playerId,
            frozen    = true,
        })
    end
end)

-- ─── place:giveItem ───────────────────────────────────────────────────────────

RegisterNetEvent("bablo-throwitems:place:giveItem")
AddEventHandler("bablo-throwitems:place:giveItem", function(itemName, slotIndex, targetServerId)
    local giverId = source
    if not (itemName and slotIndex) or not targetServerId then return end

    local giverPed  = GetPlayerPed(giverId)
    local targetPed = GetPlayerPed(targetServerId)

    if not (giverPed  and DoesEntityExist(giverPed))  then return end
    if not (targetPed and DoesEntityExist(targetPed)) then return end

    -- Server-side distance check
    local maxDist = (Config.PlaceGiveDistance or 3.0) + 2.0
    if #(GetEntityCoords(giverPed) - GetEntityCoords(targetPed)) > maxDist then return end

    -- Read metadata before removing
    local existingItem = Inventory:getSpecificPlayerItem(giverId, { slot = slotIndex })
    local metadata     = existingItem and existingItem.metadata or nil

    -- Remove from giver
    local removed = Inventory:removeSpecificPlayerItem(
        giverId, { item = itemName, slot = slotIndex }, 1)
    if not removed then
        if Framework and Framework.Notify then
            Framework:Notify(giverId, "Failed to give item!")
        end
        return
    end

    -- Give to target
    local added = Inventory:addPlayerItem(targetServerId, itemName, 1, metadata)
    if not added then
        -- Refund giver if target can't carry
        Inventory:addPlayerItem(giverId, itemName, 1, metadata)
        if Framework and Framework.Notify then
            Framework:Notify(giverId, "Player cannot carry this item!")
        end
        return
    end

    if sendWebhook then
        sendWebhook(giverId, "GAVE_ITEM", GetItemLabel(itemName))
    end
end)
