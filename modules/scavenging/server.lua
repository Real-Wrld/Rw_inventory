-- Scavenging Server Module
-- Handles loot generation, cooldowns, item distribution, and police alerts

if not lib then return end

local ScavengingConfig = lib.load('data.scavenging')
if not ScavengingConfig then return end

local CraftingModule
local ok, result = pcall(function()
    return lib.load('modules.crafting.blueprints')
end)
if ok and result then
    CraftingModule = result
end

-- Player cooldowns: { [source] = { [locationHash] = timestamp } }
local PlayerCooldowns = {}

-- Get count of online police officers
local function GetOnlineCops()
    local cops = 0

    -- Try wasabi_police first
    if GetResourceState('wasabi_police') == 'started' then
        local success, count = pcall(function()
            return exports.wasabi_police:GetCopCount()
        end)

        if success and type(count) == 'number' then
            return count
        end
    end

    -- Fallback: check for police job
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        if GetResourceState('qbx_core') == 'started' then
            local player = exports.qbx_core:GetPlayer(tonumber(playerId))
            if player and player.PlayerData and player.PlayerData.job then
                local jobName = player.PlayerData.job.name
                if jobName == 'police' or jobName == 'lspd' or jobName == 'bcso' or jobName == 'sasp' then
                    cops = cops + 1
                end
            end
        elseif GetResourceState('qb-core') == 'started' then
            local player = exports['qb-core']:GetPlayer(tonumber(playerId))
            if player and player.PlayerData and player.PlayerData.job then
                local jobName = player.PlayerData.job.name
                if jobName == 'police' or jobName == 'lspd' or jobName == 'bcso' or jobName == 'sasp' then
                    cops = cops + 1
                end
            end
        end
    end

    return cops
end

-- Trigger police dispatch alert for scavenging
local function TriggerScavengingAlert(source, locationType, streetName)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    streetName = streetName or 'Unknown Location'
    local title = '10-15 - Suspicious Activity'
    local message = 'Someone is searching through property near ' .. streetName
    local sent = false

    if GetResourceState('rcore_dispatch') == 'started' then
        local ok = pcall(function()
            exports['rcore_dispatch']:SendAlert({
                code = title,
                default_priority = 'low',
                coords = playerCoords,
                job = { 'police' },
                text = message,
                type = 'alerts',
                blip_time = 5,
                blip = {
                    sprite = 458,
                    colour = 5,
                    scale = 0.8,
                    text = 'Suspicious Activity',
                    flashes = false,
                    radius = 30.0,
                },
            })
        end)
        if ok then return true end
    end

    if GetResourceState('cd_dispatch') == 'started' then
        local dispatchData = {
            job_table = { 'police', 'sheriff', 'highway', 'lspd', 'bcso', 'sasp' },
            coords = vector3(playerCoords.x, playerCoords.y, playerCoords.z),
            title = title,
            message = message,
            flash = 0,
            unique_id = tostring(math.random(10000, 99999)),
            sound = 1,
            blip = {
                sprite = 458,
                colour = 5,
                scale = 0.8,
                flashes = false,
                text = 'Suspicious Activity',
                time = 5,
                radius = 30.0,
            },
        }
        TriggerEvent('cd_dispatch:AddNotification', dispatchData)
        TriggerClientEvent('cd_dispatch:AddNotification', -1, dispatchData)
        sent = true
    end

    if GetResourceState('ps-dispatch') == 'started' then
        pcall(function()
            exports['ps-dispatch']:CustomAlert({
                coords = playerCoords,
                message = 'Suspicious Activity - ' .. streetName,
                dispatchCode = '10-15',
                description = 'Someone searching through property',
                radius = 30.0,
                sprite = 458,
                color = 5,
                scale = 0.8,
                length = 2,
            })
        end)
        sent = true
    end

    if GetResourceState('qb-dispatch') == 'started' then
        TriggerEvent('qb-dispatch:server:notify', {
            coords = playerCoords,
            sprite = 458,
            color = 5,
            scale = 0.8,
            length = 2,
            sound = 'Lose_1st',
            msg = message,
        })
        sent = true
    end

    return sent
end

-- Get total weight of a pool
local function GetPoolTotalWeight(pool)
    local total = 0
    for _, item in ipairs(pool) do
        total = total + item.weight
    end
    return total
end

-- Pick random item from pool based on weights
local function PickFromPool(poolName)
    local pool = ScavengingConfig.pools[poolName]
    if not pool then return nil end

    local totalWeight = GetPoolTotalWeight(pool)
    local random = math.random() * totalWeight
    local cumulative = 0

    for _, item in ipairs(pool) do
        cumulative = cumulative + item.weight
        if random <= cumulative then
            local count = math.random(item.count.min, item.count.max)
            return {
                name = item.name,
                count = count,
                isBlueprint = poolName == 'blueprints',
            }
        end
    end

    -- Fallback to first item
    local firstItem = pool[1]
    return {
        name = firstItem.name,
        count = math.random(firstItem.count.min, firstItem.count.max),
        isBlueprint = poolName == 'blueprints',
    }
end

-- Pick which loot pool to use based on location chances
local function PickLootPool(locationConfig)
    local random = math.random() * 100
    local cumulative = 0

    for _, chanceData in ipairs(locationConfig.lootChances) do
        cumulative = cumulative + chanceData.chance
        if random <= cumulative then
            return chanceData.pool
        end
    end

    return 'nothing'
end

-- Check if location is on cooldown for player
local function IsOnCooldown(source, locationHash, cooldownTime)
    if not PlayerCooldowns[source] then
        PlayerCooldowns[source] = {}
    end

    local lastSearch = PlayerCooldowns[source][locationHash]
    if not lastSearch then return false end

    local currentTime = os.time() * 1000
    return (currentTime - lastSearch) < cooldownTime
end

-- Set cooldown for player at location
local function SetCooldown(source, locationHash)
    if not PlayerCooldowns[source] then
        PlayerCooldowns[source] = {}
    end
    PlayerCooldowns[source][locationHash] = os.time() * 1000
end

-- Get remaining cooldown time
local function GetRemainingCooldown(source, locationHash, cooldownTime)
    if not PlayerCooldowns[source] or not PlayerCooldowns[source][locationHash] then
        return 0
    end

    local currentTime = os.time() * 1000
    local elapsed = currentTime - PlayerCooldowns[source][locationHash]
    local remaining = cooldownTime - elapsed

    return math.max(0, math.floor(remaining / 1000))
end

-- Clean up player cooldowns on drop
AddEventHandler('playerDropped', function()
    PlayerCooldowns[source] = nil
end)

-- Main search callback
lib.callback.register('ox_inventory:searchLocation', function(source, locationType, locationHash, streetName)
    local locationConfig = ScavengingConfig.locations[locationType]
    if not locationConfig then
        return { success = false, error = 'invalid_location' }
    end

    -- Check cooldown
    if IsOnCooldown(source, locationHash, locationConfig.cooldown) then
        local remaining = GetRemainingCooldown(source, locationHash, locationConfig.cooldown)
        return {
            success = false,
            error = 'cooldown',
            remaining = remaining,
            message = ScavengingConfig.settings.messages.cooldown,
        }
    end

    -- Set cooldown immediately
    SetCooldown(source, locationHash)

    -- Trigger police alert (80% chance based on settings)
    local alertChance = ScavengingConfig.settings.policeAlertChance or 80
    local minCops = ScavengingConfig.settings.minCopsForAlert or 0
    local alertRoll = math.random(1, 100)
    local copCount = GetOnlineCops()

    if alertRoll <= alertChance and copCount >= minCops then
        TriggerScavengingAlert(source, locationType, streetName)
    end

    -- Pick loot pool
    local poolName = PickLootPool(locationConfig)

    -- Nothing found
    if poolName == 'nothing' then
        -- Give small XP for trying
        if CraftingModule and CraftingModule.AddCraftingXP then
            CraftingModule.AddCraftingXP(source, ScavengingConfig.settings.searchXP)
        end

        return {
            success = true,
            found = false,
            message = ScavengingConfig.settings.messages.nothing,
        }
    end

    -- Pick item from pool
    local loot = PickFromPool(poolName)
    if not loot then
        return {
            success = true,
            found = false,
            message = ScavengingConfig.settings.messages.nothing,
        }
    end

    -- Try to add item to player inventory
    local added = exports.ox_inventory:AddItem(source, loot.name, loot.count)

    if not added then
        return {
            success = false,
            error = 'inventory_full',
            message = 'Your inventory is full!',
        }
    end

    -- Calculate XP reward
    local xpReward = ScavengingConfig.settings.searchXP
    if loot.isBlueprint then
        xpReward = xpReward + ScavengingConfig.settings.blueprintBonusXP
    end

    -- Add crafting XP
    if CraftingModule and CraftingModule.AddCraftingXP then
        CraftingModule.AddCraftingXP(source, xpReward)
    end

    -- Get item label for UI
    local itemData = exports.ox_inventory:Items()[loot.name]
    local label = itemData and itemData.label or loot.name

    -- Format message
    local message
    if loot.isBlueprint then
        message = string.format(ScavengingConfig.settings.messages.blueprint, label)
    else
        message = string.format(ScavengingConfig.settings.messages.found, label, loot.count)
    end

    return {
        success = true,
        found = true,
        item = loot.name,
        label = label,
        count = loot.count,
        isBlueprint = loot.isBlueprint,
        message = message,
        xpGained = xpReward,
    }
end)

-- Get location config for client
lib.callback.register('ox_inventory:getScavengingConfig', function(source)
    return ScavengingConfig.locations
end)

-- Remote zone / rare material search
lib.callback.register('ox_inventory:searchZone', function(source, zoneId, locationHash, streetName)
    local zone = ScavengingConfig.zones and ScavengingConfig.zones[zoneId]
    if not zone then
        return { success = false, error = 'invalid_location', message = 'Unknown search zone.' }
    end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - zone.coords) > ((zone.radius or 50.0) + 15.0) then
        return { success = false, error = 'out_of_zone', message = 'You left the search area.' }
    end

    local cooldownKey = ('zone:%s:%s'):format(zoneId, tostring(locationHash))
    local cooldownTime = zone.cooldown or 600000

    if IsOnCooldown(source, cooldownKey, cooldownTime) then
        local remaining = GetRemainingCooldown(source, cooldownKey, cooldownTime)
        return {
            success = false,
            error = 'cooldown',
            remaining = remaining,
            message = ScavengingConfig.settings.messages.cooldown,
        }
    end

    SetCooldown(source, cooldownKey)

    local alertChance = ScavengingConfig.settings.policeAlertChance or 80
    local minCops = ScavengingConfig.settings.minCopsForAlert or 0
    if math.random(1, 100) <= alertChance and GetOnlineCops() >= minCops then
        TriggerScavengingAlert(source, zoneId, streetName)
    end

    local pool = zone.lootType and ScavengingConfig.rare_materials and ScavengingConfig.rare_materials[zone.lootType]
    if not pool or #pool == 0 then
        return {
            success = true,
            found = false,
            message = ScavengingConfig.settings.messages.nothing,
        }
    end

    -- Weighted pick from rare materials pool
    local totalWeight = 0
    for i = 1, #pool do
        totalWeight = totalWeight + (pool[i].weight or 1)
    end

    local roll = math.random() * totalWeight
    local cumulative = 0
    local picked = pool[1]

    for i = 1, #pool do
        cumulative = cumulative + (pool[i].weight or 1)
        if roll <= cumulative then
            picked = pool[i]
            break
        end
    end

    local count = math.random(picked.count.min, picked.count.max)
    local added = exports.ox_inventory:AddItem(source, picked.name, count)

    if not added then
        return {
            success = false,
            error = 'inventory_full',
            message = 'Your inventory is full!',
        }
    end

    local isBlueprint = type(picked.name) == 'string' and picked.name:find('blueprint', 1, true) ~= nil
    local xpReward = (ScavengingConfig.settings.searchXP or 5) + (ScavengingConfig.settings.rareMaterialBonusXP or 20)
    if isBlueprint then
        xpReward = xpReward + (ScavengingConfig.settings.blueprintBonusXP or 50)
    end

    if CraftingModule and CraftingModule.AddCraftingXP then
        CraftingModule.AddCraftingXP(source, xpReward)
    end

    local itemData = exports.ox_inventory:Items()[picked.name]
    local label = itemData and itemData.label or picked.name

    return {
        success = true,
        found = true,
        item = picked.name,
        label = label,
        count = count,
        isBlueprint = isBlueprint,
        message = string.format(ScavengingConfig.settings.messages.found, label, count),
        xpGained = xpReward,
    }
end)
