if not lib then return end

local VehicleKeys = {}

-- Create a vehicle key item for a player using the keyfob system
-- The keyfob stores multiple vehicle plates in its metadata
---@param source number
---@param plate string
---@param model string|nil
function VehicleKeys.CreateKey(source, plate, model)
    if not source or not plate then return false end

    plate = plate:gsub('%s+', '') -- trim whitespace

    -- Check if player already has a keyfob
    local keyfobs = exports.ox_inventory:Search(source, 'slots', 'keyfob')
    if keyfobs and type(keyfobs) == 'table' then
        -- Prefer array shape; fall back to first entry in a map
        local keyfob = keyfobs[1]
        if not keyfob then
            for _, v in pairs(keyfobs) do
                if type(v) == 'table' and v.name == 'keyfob' then
                    keyfob = v
                    break
                elseif type(v) == 'table' and v[1] then
                    keyfob = v[1]
                    break
                end
            end
        end

        if keyfob and keyfob.slot then
            local plates = (keyfob.metadata and keyfob.metadata.plates) or {}

            for _, existingPlate in ipairs(plates) do
                if type(existingPlate) == 'string' and existingPlate:gsub('%s+', '') == plate then
                    lib.notify(source, { type = 'inform', description = 'You already have keys for this vehicle' })
                    return true
                end
            end

            table.insert(plates, plate)

            local newMetadata = {
                plates = plates,
                description = 'Vehicles: ' .. #plates,
                image = 'carkeys.png',
            }

            -- Update in place — remove+add races inventory sync and drops keys
            exports.ox_inventory:SetMetadata(source, keyfob.slot, newMetadata)
            return true
        end
    end

    -- Create a new keyfob with this plate
    local metadata = {
        plates = { plate },
        description = 'Vehicles: 1',
        image = 'carkeys.png',
    }

    local success = exports.ox_inventory:AddItem(source, 'keyfob', 1, metadata)
    return success and true or false
end

exports('CreateVehicleKey', VehicleKeys.CreateKey)

-- qbx_vehiclekeys Compatibility: GiveKeys export (accepts source and vehicle entity/plate)
local function GiveKeys(source, vehicle)
    if not source then return end
    local plate
    if type(vehicle) == 'number' and DoesEntityExist(vehicle) then
        plate = GetVehicleNumberPlateText(vehicle)
    elseif type(vehicle) == 'string' then
        plate = vehicle
    end

    if not plate then return end
    plate = plate:gsub('%s+', '')

    return VehicleKeys.CreateKey(source, plate)
end
exports('GiveKeys', GiveKeys)

-- qbx_vehiclekeys event compatibility
RegisterNetEvent('qbx_vehiclekeys:server:giveKeys', function(target, vehicleNetId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or vehicle == 0 then return end
    local recipient = target or src
    GiveKeys(recipient, vehicle)
end)

-- Compatibility Event (Optional: if other scripts call a specific event)
RegisterNetEvent('ox_inventory:server:CreateVehicleKey', function(plate, model)
    local source = source
    VehicleKeys.CreateKey(source, plate, model)
end)

RegisterNetEvent('RW-Inventory:vehiclekeys:giveKeys', function(plate, model)
    local source = source
    VehicleKeys.CreateKey(source, plate, model)
end)

RegisterNetEvent('RW-Inventory:vehiclekeys:breakLockpick', function(itemName)
    local source = source
    exports.ox_inventory:RemoveItem(source, itemName, 1)
end)

-- Commands
lib.addCommand('givekeys', {
    help = 'Give vehicle keys to another player',
    params = {
        { name = 'target', type = 'playerId', help = 'Target player ID (Optional)', optional = true },
    }
}, function(source, args)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not vehicle or vehicle == 0 then
        -- Find closest vehicle
        vehicle = lib.getClosestVehicle(coords, 5.0, true)
    end

    if not vehicle or vehicle == 0 then
        return lib.notify(source, { type = 'error', description = 'No vehicle found nearby' })
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    plate = plate and plate:gsub('%s+', '') or 'UNKNOWN' -- Trim spaces

    -- Check if source has keys (check both legacy carkeys AND new keyfob)
    local hasKeys = false

    -- Check new keyfob system first
    local keyfobs = exports.ox_inventory:Search(source, 'slots', 'keyfob')
    if keyfobs then
        for _, item in pairs(keyfobs) do
            if item.metadata and item.metadata.plates then
                for _, p in ipairs(item.metadata.plates) do
                    if p == plate then
                        hasKeys = true
                        break
                    end
                end
            end
            if hasKeys then break end
        end
    end

    -- Also check legacy carkeys for backward compatibility
    if not hasKeys then
        local items = exports.ox_inventory:Search(source, 'slots', 'carkeys')
        if items then
            for _, item in pairs(items) do
                if item.metadata and item.metadata.plate and item.metadata.plate:gsub('%s+', '') == plate then
                    hasKeys = true
                    break
                end
            end
        end
    end

    if not hasKeys then
        return lib.notify(source, { type = 'error', description = 'You do not have keys for this vehicle' })
    end

    -- Determine target
    local target = args.target
    if not target then
        -- Get closest player
        local players = lib.getNearbyPlayers(coords, 5.0)
        if players and #players > 0 then
            -- Filter self? getNearbyPlayers excludes source usually? No, it takes coords.
            for _, p in ipairs(players) do
                if p.id ~= source then
                    target = p.id
                    break
                end
            end
        end
    end

    if not target then
        -- Check passengers if in vehicle
        if GetVehiclePedIsIn(ped, false) == vehicle then
            -- Give to all passengers? Original code did that.
            -- Logic: Single target preferred, or all.
            -- I'll stick to single target finding.
            return lib.notify(source, { type = 'error', description = 'No player found nearby' })
        end
        return lib.notify(source, { type = 'error', description = 'No player found nearby' })
    end

    VehicleKeys.CreateKey(target, plate, GetEntityModel(vehicle))
    lib.notify(source, { type = 'success', description = 'You gave the keys' })
    lib.notify(target, { type = 'success', description = 'You received keys' })
end)

lib.addCommand('addkeys', {
    help = 'Admin: Give yourself keys for the vehicle',
    restricted = 'group.admin'
}, function(source, args)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not vehicle or vehicle == 0 then
        vehicle = lib.getClosestVehicle(coords, 5.0, true)
    end

    if not vehicle or vehicle == 0 then
        return lib.notify(source, { type = 'error', description = 'No vehicle found nearby' })
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    plate = plate and plate:gsub('%s+', '') or 'UNKNOWN'

    VehicleKeys.CreateKey(source, plate, GetEntityModel(vehicle))
    lib.notify(source, { type = 'success', description = 'Keys added (Admin)' })
end)

lib.addCommand('getkeys', {
    help = 'Admin: Give yourself keys for the closest vehicle',
    restricted = 'group.admin'
}, function(source, args)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not vehicle or vehicle == 0 then
        vehicle = lib.getClosestVehicle(coords, 5.0, true)
    end

    if not vehicle or vehicle == 0 then
        return lib.notify(source, { type = 'error', description = 'No vehicle found nearby' })
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    plate = plate and plate:gsub('%s+', '') or 'UNKNOWN'

    VehicleKeys.CreateKey(source, plate, GetEntityModel(vehicle))
    lib.notify(source, { type = 'success', description = 'Keys added (Admin - getkeys)' })
end)

---@param source number
---@return string|nil
local function getCitizenId(source)
    if GetResourceState('qbx_core') == 'started' then
        local player = exports.qbx_core:GetPlayer(source)
        return player and player.PlayerData.citizenid
    end

    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(source)
        return player and player.PlayerData.citizenid
    end

    return nil
end

---Return plates from the keyfob that belong to this player in player_vehicles
---@param source number
---@param plates string[]
---@return string[]
local function filterOwnedPlates(source, plates)
    if not plates or #plates == 0 then return {} end

    local citizenid = getCitizenId(source)
    if not citizenid then return {} end

    local owned = {}

    for _, plate in ipairs(plates) do
        local normalized = plate:gsub('%s+', '')
        local exists = MySQL.scalar.await(
            'SELECT 1 FROM player_vehicles WHERE plate = ? AND citizenid = ? LIMIT 1',
            { normalized, citizenid }
        )

        if exists then
            owned[#owned + 1] = normalized
        end
    end

    return owned
end

lib.callback.register('ox_inventory:filterOwnedPlates', function(source, plates)
    return filterOwnedPlates(source, plates or {})
end)

lib.callback.register('ox_inventory:isPlateOwnedByPlayer', function(source, plate)
    if not plate then return false end
    return #filterOwnedPlates(source, { plate }) > 0
end)

-- Callback to get all plates from player's keyfob
lib.callback.register('ox_inventory:getKeyfobPlates', function(source)
    local keyfobs = exports.ox_inventory:Search(source, 'slots', 'keyfob')
    if not keyfobs or #keyfobs == 0 then
        return nil
    end

    local keyfob = keyfobs[1]
    local plates = keyfob.metadata and keyfob.metadata.plates or {}

    return {
        plates = plates,
        slot = keyfob.slot
    }
end)

-- Callback to remove a specific plate from keyfob
lib.callback.register('ox_inventory:removeKeyfobPlate', function(source, plateToRemove)
    if not plateToRemove then return false end

    local keyfobs = exports.ox_inventory:Search(source, 'slots', 'keyfob')
    if not keyfobs or #keyfobs == 0 then
        return false, 'no_keyfob'
    end

    local keyfob = keyfobs[1]
    local plates = keyfob.metadata and keyfob.metadata.plates or {}

    -- Find and remove the plate
    local found = false
    local newPlates = {}
    for _, plate in ipairs(plates) do
        if plate == plateToRemove then
            found = true
        else
            table.insert(newPlates, plate)
        end
    end

    if not found then
        return false, 'plate_not_found'
    end

    -- Update or remove the keyfob
    exports.ox_inventory:RemoveItem(source, 'keyfob', 1, nil, keyfob.slot)

    if #newPlates > 0 then
        -- Still has plates, update keyfob
        local newMetadata = {
            plates = newPlates,
            description = 'Vehicles: ' .. #newPlates
        }
        exports.ox_inventory:AddItem(source, 'keyfob', 1, newMetadata)
    end
    -- If no plates left, keyfob is simply removed

    lib.notify(source, { type = 'success', description = 'Key removed from keyfob' })
    return true
end)

return VehicleKeys
