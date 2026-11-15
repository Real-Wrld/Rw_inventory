if not lib then return end

local Inventory = require 'modules.inventory.server'

local pendingThrows = {}
local activeLockKeys = {}
local throwSyncCounter = 0

local Config = RWThrowConfig or {}
local PENDING_TIMEOUT = Config.pendingTimeout or 120

local function getPendingTimeout()
    return PENDING_TIMEOUT
end

local function hasPendingThrow(lockKey, expectedPlayerId)
    local playerId = activeLockKeys[lockKey]
    if not playerId then return false end
    if expectedPlayerId and playerId ~= expectedPlayerId then return false end
    return true
end

local function removePendingThrow(playerId, throwCount)
    local playerThrows = pendingThrows[playerId]
    if not playerThrows then return end

    local entry = playerThrows[throwCount]
    if not entry then return end

    if entry.lockKey then
        activeLockKeys[entry.lockKey] = nil
    end

    playerThrows[throwCount] = nil

    if not next(playerThrows) then
        pendingThrows[playerId] = nil
    end
end

local function returnAllPendingThrows(playerId)
    local playerThrows = pendingThrows[playerId]
    if not playerThrows then return end

    for _, entry in pairs(playerThrows) do
        exports.ox_inventory:AddItem(playerId, entry.itemName, entry.amount, entry.metadata)
        if entry.lockKey then
            activeLockKeys[entry.lockKey] = nil
        end
    end

    pendingThrows[playerId] = nil
end

local function expireOldPendingThrows(playerId)
    local playerThrows = pendingThrows[playerId]
    if not playerThrows then return end

    local now = os.time()

    for throwCount, entry in pairs(playerThrows) do
        if now - entry.timestamp > getPendingTimeout() then
            exports.ox_inventory:AddItem(playerId, entry.itemName, entry.amount, entry.metadata)
            if entry.lockKey then
                activeLockKeys[entry.lockKey] = nil
            end
            playerThrows[throwCount] = nil
        end
    end

    if not next(playerThrows) then
        pendingThrows[playerId] = nil
    end
end

local function clearThrowStateBags(playerId)
    local state = Player(playerId).state
    state:set('rw_throwMode', nil, true)
    state:set('rw_throwData', nil, true)
end

RegisterNetEvent('rw_inventory:throwHit', function(targetServerId, velocity)
    if type(targetServerId) == 'number' then
        TriggerClientEvent('rw_inventory:throwHit', targetServerId, velocity)
    end
end)

RegisterNetEvent('rw_inventory:throw:enterMode', function(propModel, itemName, slotIndex, throwCount)
    local src = source
    if not itemName or not slotIndex or not throwCount then return end

    local lockKey = ('%s:%s:%s'):format(src, itemName, slotIndex)
    expireOldPendingThrows(src)
    if hasPendingThrow(lockKey) then return end

    local item = exports.ox_inventory:GetSlot(src, slotIndex)
    if not item or item.name ~= itemName or item.count < 1 then return end

    local itemData = exports.ox_inventory:Items(item.name)
    if itemData and (itemData.weapon or itemData.permanent) then return end
    if item.name:lower():find('^weapon_') then return end

    if not exports.ox_inventory:RemoveItem(src, item.name, 1, item.metadata, slotIndex) then
        return
    end

    pendingThrows[src] = pendingThrows[src] or {}
    pendingThrows[src][throwCount] = {
        itemName = item.name,
        label = item.label or (itemData and itemData.label) or item.name,
        amount = 1,
        metadata = item.metadata,
        propModel = propModel,
        lockKey = lockKey,
        timestamp = os.time(),
    }

    activeLockKeys[lockKey] = src

    Player(src).state:set('rw_throwMode', {
        propModel = propModel,
        timestamp = GetGameTimer(),
    }, true)
end)

RegisterNetEvent('rw_inventory:throw:sync', function(propModel, startCoords, velocity)
    local src = source
    throwSyncCounter = throwSyncCounter + 1

    Player(src).state:set('rw_throwData', {
        id = throwSyncCounter,
        propModel = propModel,
        startCoords = startCoords,
        velocity = velocity,
        timestamp = GetGameTimer(),
    }, true)
end)

RegisterNetEvent('rw_inventory:throw:land', function(_, _, _, _)
    local src = source
    Player(src).state:set('rw_throwData', nil, true)
    TriggerClientEvent('rw_inventory:throw:propLanded', -1, src)
end)

RegisterNetEvent('rw_inventory:throw:finalize', function(landedCoords, throwCount)
    local src = source
    if not throwCount then return end

    local playerThrows = pendingThrows[src]
    if not playerThrows then return end

    local entry = playerThrows[throwCount]
    if not entry then return end

    if landedCoords then
        local x = landedCoords.x or landedCoords[1]
        local y = landedCoords.y or landedCoords[2]
        local z = landedCoords.z or landedCoords[3]

        if x and y and z then
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 then
                local pcoords = GetEntityCoords(ped)
                if #(pcoords - vec3(x, y, z)) <= 80.0 then
                    local model = entry.propModel and joaat(entry.propModel) or nil
                    local spawnCoords = vec3(x, y, z + 0.2)

                    local dropId = exports.ox_inventory:CustomDrop('Throw', {
                        { entry.itemName, entry.amount, entry.metadata }
                    }, spawnCoords, 1, 10000, nil, model)

                    if dropId and Inventory.Drops and Inventory.Drops[dropId] then
                        Inventory.Drops[dropId].thrown = true
                        TriggerClientEvent('rw_inventory:thrownDrop', -1, dropId, Inventory.Drops[dropId])
                    end
                else
                    exports.ox_inventory:AddItem(src, entry.itemName, entry.amount, entry.metadata)
                end
            end
        end
    else
        exports.ox_inventory:AddItem(src, entry.itemName, entry.amount, entry.metadata)
    end

    removePendingThrow(src, throwCount)

    if not pendingThrows[src] then
        clearThrowStateBags(src)
    end
end)

RegisterNetEvent('rw_inventory:throw:clearState', function()
    local src = source
    returnAllPendingThrows(src)
    clearThrowStateBags(src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    returnAllPendingThrows(src)
    clearThrowStateBags(src)
end)

lib.callback.register('rw_inventory:pickupThrownDrop', function(source, dropId)
    if dropId == nil then return false end

    local drop = Inventory(dropId)
    if not drop or drop.type ~= 'drop' then return false end

    local playerPed = GetPlayerPed(source)
    if not playerPed or playerPed == 0 then return false end

    local pcoords = GetEntityCoords(playerPed)
    if not drop.coords or #(pcoords - drop.coords) > 4.0 then return false end

    local moved = false

    for _, slotItem in pairs(drop.items or {}) do
        if slotItem and slotItem.name then
            if exports.ox_inventory:AddItem(source, slotItem.name, slotItem.count or 1, slotItem.metadata) then
                moved = true
            end
        end
    end

    if moved then
        Inventory.Clear(drop)
        Inventory.Remove(drop)
        if Inventory.Drops then Inventory.Drops[dropId] = nil end
        TriggerClientEvent('ox_inventory:removeDrop', -1, dropId)
    end

    return moved
end)
