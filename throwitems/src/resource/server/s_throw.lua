-- s_throw.lua  –  Server-side throw state management for bablo-throwitems

if GetCurrentResourceName() ~= "bablo-throwitems" then
    error("Resource name must be 'bablo-throwitems'")
    return
end

-- ─── State ────────────────────────────────────────────────────────────────────

local throwSyncCounter = 0   -- incremented on every throw:sync, used as throwData.id

-- pendingThrows[playerId][throwCount] = { itemName, label, amount, metadata,
--                                         propModel, lockKey, timestamp }
local pendingThrows = {}

-- activeLockKeys[lockKey] = playerId
-- Prevents the same throw being processed twice (deduplicated by lockKey)
local activeLockKeys = {}

local PENDING_TIMEOUT_SECONDS = 120   -- return item to player after this many seconds

-- ─── Helpers ──────────────────────────────────────────────────────────────────

-- Returns true if a pending throw exists; optionally checks a specific throwCount
function HasPendingThrow(lockKey, expectedPlayerId)
    local playerId = activeLockKeys[lockKey]
    if not playerId then return false end
    if expectedPlayerId and playerId ~= expectedPlayerId then return false end
    return true
end

-- Removes a single pending throw entry and releases its lock key
function RemovePendingThrow(playerId, throwCount)
    local playerThrows = pendingThrows[playerId]
    if not playerThrows then return end

    local entry = playerThrows[throwCount]
    if not entry then return end

    if entry.lockKey then
        activeLockKeys[entry.lockKey] = nil
    end

    playerThrows[throwCount] = nil

    if next(playerThrows) == nil then
        pendingThrows[playerId] = nil
    end
end

-- Returns all pending items to the player's inventory and clears their throws
function ReturnAllPendingThrows(playerId)
    local playerThrows = pendingThrows[playerId]
    if not playerThrows then return end

    for _, entry in pairs(playerThrows) do
        Inventory:addPlayerItem(playerId, entry.itemName, entry.amount, entry.metadata)
        if entry.lockKey then
            activeLockKeys[entry.lockKey] = nil
        end
    end

    pendingThrows[playerId] = nil
end

-- Returns timed-out pending throws to the player and clears them
function ExpireOldPendingThrows(playerId)
    local playerThrows = pendingThrows[playerId]
    if not playerThrows then return end

    local now = os.time()
    local anyRemoved = false

    for throwCount, entry in pairs(playerThrows) do
        local age = now - entry.timestamp
        if age > PENDING_TIMEOUT_SECONDS then
            Inventory:addPlayerItem(playerId, entry.itemName, entry.amount, entry.metadata)
            if entry.lockKey then
                activeLockKeys[entry.lockKey] = nil
            end
            playerThrows[throwCount] = nil
            anyRemoved = true
        end
    end

    if next(playerThrows) == nil then
        pendingThrows[playerId] = nil
    end
end

-- Clears a player's state bags for throw mode
function ClearThrowStateBags(playerId)
    local state = Player(playerId).state
    state:set("throwMode", nil, true)
    state:set("throwData", nil, true)
end

-- ─── Net events ───────────────────────────────────────────────────────────────

RegisterNetEvent("bablo-throwitems:throw:enterMode")
AddEventHandler("bablo-throwitems:throw:enterMode", function(propModel, itemName, slotIndex, throwCount)
    local playerId = source
    if not (itemName and slotIndex) or not throwCount then return end

    -- Build a deduplification key: "playerId:itemName:slotIndex"
    local lockKey = tostring(playerId) .. ":" .. tostring(itemName) .. ":" .. tostring(slotIndex)

    -- Expire stale entries first, then check for duplicate
    ExpireOldPendingThrows(playerId)
    if HasPendingThrow(lockKey) then return end

    -- Validate the item exists in the player's inventory
    local item = Inventory:getSpecificPlayerItem(playerId, { slot = slotIndex })
    if not item then return end

    local amount   = item.quantity or 1
    local metadata = item.metadata

    -- Resolve display label
    local label = itemName
    if Inventory.getItemLabel then
        label = Inventory:getItemLabel(itemName) or itemName
    end

    -- Remove the item from inventory
    local removed = Inventory:removeSpecificPlayerItem(playerId, { item = itemName, slot = slotIndex }, amount)
    if not removed then return end

    -- Store the pending throw entry
    pendingThrows[playerId] = pendingThrows[playerId] or {}
    pendingThrows[playerId][throwCount] = {
        itemName  = itemName,
        label     = label,
        amount    = amount,
        metadata  = metadata,
        propModel = propModel,
        lockKey   = lockKey,
        timestamp = os.time(),
    }

    activeLockKeys[lockKey] = playerId

    -- Broadcast throw state to nearby clients for prop sync
    Player(playerId).state:set("throwMode", {
        propModel = propModel,
        timestamp = GetGameTimer(),
    }, true)
end)

RegisterNetEvent("bablo-throwitems:throw:sync")
AddEventHandler("bablo-throwitems:throw:sync", function(propModel, startCoords, velocity)
    local playerId = source
    throwSyncCounter = throwSyncCounter + 1

    Player(playerId).state:set("throwData", {
        id          = throwSyncCounter,
        propModel   = propModel,
        startCoords = startCoords,
        velocity    = velocity,
        timestamp   = GetGameTimer(),
    }, true)
end)

RegisterNetEvent("bablo-throwitems:throw:land")
AddEventHandler("bablo-throwitems:throw:land", function(itemName, landedCoords, landedRot, throwCount)
    local playerId = source

    -- Clear throwData state bag; notify all clients the prop landed
    Player(playerId).state:set("throwData", nil, true)
    TriggerClientEvent("bablo-throwitems:throw:propLanded", -1, playerId, itemName, landedCoords, landedRot)
end)

RegisterNetEvent("bablo-throwitems:throw:finalize")
AddEventHandler("bablo-throwitems:throw:finalize", function(landedCoords, throwCount)
    local playerId = source
    if not throwCount then return end

    local playerThrows = pendingThrows[playerId]
    if not playerThrows then return end

    local entry = playerThrows[throwCount]
    if not entry then return end

    -- Spawn the ground item if a landing position was provided
    if entry and landedCoords and CreateGroundItem then
        if sendWebhook then
            sendWebhook(playerId, "THROWN_ITEM", entry.label)
        end

        CreateGroundItem({
            itemName  = entry.itemName,
            label     = entry.label,
            metadata  = entry.metadata,
            amount    = entry.amount,
            propModel = entry.propModel or Config.DefaultProp,
            coords    = landedCoords,
            rotation  = vector3(0.0, 0.0, 0.0),
            droppedBy = playerId,
        })
    end

    RemovePendingThrow(playerId, throwCount)

    -- If no more pending throws, clear state bags
    if not pendingThrows[playerId] then
        ClearThrowStateBags(playerId)
    end
end)

RegisterNetEvent("bablo-throwitems:throw:clearState")
AddEventHandler("bablo-throwitems:throw:clearState", function()
    local playerId = source
    ReturnAllPendingThrows(playerId)
    ClearThrowStateBags(playerId)
end)

AddEventHandler("playerDropped", function()
    local playerId = source
    ReturnAllPendingThrows(playerId)
    ClearThrowStateBags(playerId)
end)
