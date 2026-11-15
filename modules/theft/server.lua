-- Store Theft Server Module
-- Handles loot generation, cooldowns, and police dispatch

if not lib then return end

local TheftConfig = lib.load('data.theft')

if not TheftConfig then
    return
end

if not TheftConfig.settings then
    return
end

if not TheftConfig.pools then
    return
end

-- Try to load crafting module for XP (optional)
local CraftingModule
local ok, result = pcall(function()
    return lib.load('modules.crafting.blueprints')
end)
if ok and result then
    CraftingModule = result
end

-- Player cooldowns: { [source] = { [locationHash] = timestamp } }
local PlayerCooldowns = {}

-- Get total weight of a pool
local function GetPoolTotalWeight(pool)
    local total = 0
    for _, item in ipairs(pool) do
        total = total + item.weight
    end
    return total
end

-- Determine blueprint tier from item name
local function GetBlueprintTier(itemName)
    if not itemName then return 'legendary' end
    local name = itemName:lower()

    if name:find('_basic_') or name:find('basic_') then
        return 'basic'
    elseif name:find('_advanced_') or name:find('advanced_') or name:find('advancedrepairkit') then
        return 'advanced'
    elseif name:find('_master_') or name:find('master_') then
        return 'master'
    else
        -- Default to legendary for rare blueprints (thermite, nightvision, etc.)
        return 'legendary'
    end
end

-- Pick random item from pool based on weights
local function PickFromPool(poolName)
    local pool = TheftConfig.pools[poolName]
    if not pool then return nil end

    local totalWeight = GetPoolTotalWeight(pool)
    local random = math.random() * totalWeight
    local cumulative = 0

    for _, item in ipairs(pool) do
        cumulative = cumulative + item.weight
        if random <= cumulative then
            local count = math.random(item.count.min, item.count.max)
            local isBlueprint = poolName == 'blueprints'
            return {
                name = item.name,
                count = count,
                isBlueprint = isBlueprint,
                blueprintTier = isBlueprint and GetBlueprintTier(item.name) or nil,
            }
        end
    end

    -- Fallback to first item
    local firstItem = pool[1]
    local isBlueprint = poolName == 'blueprints'
    return {
        name = firstItem.name,
        count = math.random(firstItem.count.min, firstItem.count.max),
        isBlueprint = isBlueprint,
        blueprintTier = isBlueprint and GetBlueprintTier(firstItem.name) or nil,
    }
end

-- Pick which loot pool to use (zone lootChances override store defaults)
local function PickLootPool(storeType, zoneLootChances)
    local lootChances = zoneLootChances
    if type(lootChances) ~= 'table' then
        local storeConfig = TheftConfig[storeType]
        lootChances = storeConfig and storeConfig.lootChances
    end
    if not lootChances then
        return 'nothing'
    end

    local random = math.random() * 100
    local cumulative = 0

    for _, chanceData in ipairs(lootChances) do
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

-- Get count of online police officers
local function GetOnlineCops()
    local cops = 0

    -- Try wasabi_police first
    if GetResourceState('wasabi_police') == 'started' then
        -- Use the documented export for online police count
        local success, count = pcall(function()
            return exports.wasabi_police:getPoliceOnline()
        end)

        if success and type(count) == 'number' then
            return count
        end
    end

    -- Fallback: check for police job using QBX/QB/ESX
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        -- Try QBX/QB method
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

local POLICE_JOBS = { 'police', 'lspd', 'bcso', 'sasp', 'sheriff', 'highway' }

-- Ping supported dispatch systems (silent for the thief).
local function TriggerPoliceAlert(source, storeType, storeName, coords, streetName)
    local storeConfig = TheftConfig[storeType]
    if not storeConfig or not storeConfig.dispatch then
        return false
    end

    local dispatchConfig = storeConfig.dispatch
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local title = ('%s - %s'):format(dispatchConfig.code or '10-31', dispatchConfig.message or 'Store Theft')
    local message = ('%s at %s (%s)'):format(
        dispatchConfig.description or 'Store theft in progress',
        storeName or 'Unknown Store',
        streetName or 'Unknown Location'
    )
    local sent = false

    -- rcore_dispatch (this server) — native path only (CD bridge would double-fire)
    if GetResourceState('rcore_dispatch') == 'started' then
        local ok = pcall(function()
            exports['rcore_dispatch']:SendAlert({
                code = title,
                default_priority = 'medium',
                coords = playerCoords,
                job = { 'police' },
                text = message,
                type = 'shop_robbery',
                blip_time = 5,
                blip = {
                    sprite = dispatchConfig.blipSprite or 52,
                    colour = dispatchConfig.blipColor or 1,
                    scale = dispatchConfig.blipScale or 1.0,
                    text = dispatchConfig.message or 'Store Theft',
                    flashes = true,
                    radius = dispatchConfig.radius or 0,
                },
            })
        end)
        if ok then return true end
    end

    -- cd_dispatch (standalone installs)
    if GetResourceState('cd_dispatch') == 'started' then
        local dispatchData = {
            job_table = POLICE_JOBS,
            coords = playerCoords,
            title = title,
            message = message,
            flash = 0,
            unique_id = tostring(math.random(10000, 99999)),
            sound = 1,
            blip = {
                sprite = dispatchConfig.blipSprite or 52,
                colour = dispatchConfig.blipColor or 1,
                scale = dispatchConfig.blipScale or 1.0,
                flashes = true,
                text = dispatchConfig.message or 'Store Theft',
                time = 5,
                radius = dispatchConfig.radius or 30.0,
            },
        }
        TriggerClientEvent('cd_dispatch:AddNotification', -1, dispatchData)
        TriggerEvent('cd_dispatch:AddNotification', dispatchData)
        sent = true
    end

    if GetResourceState('ps-dispatch') == 'started' then
        pcall(function()
            exports['ps-dispatch']:CustomAlert({
                coords = playerCoords,
                message = (dispatchConfig.message or 'Store Theft') .. ' - ' .. (storeName or ''),
                dispatchCode = dispatchConfig.code or '10-31',
                description = message,
                radius = dispatchConfig.radius or 30.0,
                sprite = dispatchConfig.blipSprite or 52,
                color = dispatchConfig.blipColor or 1,
                scale = dispatchConfig.blipScale or 1.0,
                length = 3,
            })
        end)
        sent = true
    end

    if GetResourceState('qb-dispatch') == 'started' then
        TriggerEvent('qb-dispatch:server:notify', {
            coords = playerCoords,
            sprite = dispatchConfig.blipSprite or 52,
            color = dispatchConfig.blipColor or 1,
            scale = dispatchConfig.blipScale or 1.0,
            length = 3,
            sound = 'robbery',
            msg = message,
        })
        sent = true
    end

    if GetResourceState('qs-dispatch') == 'started' then
        TriggerEvent('qs-dispatch:server:CreateDispatchCall', {
            job = POLICE_JOBS,
            callLocation = playerCoords,
            callCode = { code = dispatchConfig.code or '10-31', snippet = dispatchConfig.message or 'Store Theft' },
            message = message,
            flashes = true,
            blip = {
                sprite = dispatchConfig.blipSprite or 52,
                scale = dispatchConfig.blipScale or 1.0,
                colour = dispatchConfig.blipColor or 1,
                flashes = true,
                text = dispatchConfig.message or 'Store Theft',
                time = 5 * 60 * 1000,
            },
        })
        sent = true
    end

    if not sent then
        TriggerClientEvent('ox_inventory:policeAlert', -1, {
            coords = playerCoords,
            message = dispatchConfig.message or 'Store Theft',
            storeName = storeName,
            storeType = storeType,
        })
        sent = true
    end

    return sent
end

-- Clean up player cooldowns on drop
AddEventHandler('playerDropped', function()
    PlayerCooldowns[source] = nil
end)

-- Load anti-cheat module for rate limiting
local AntiCheat = lib.load('modules.anticheat.server')

-- Main theft callback
lib.callback.register('ox_inventory:storeTheft', function(source, storeType, locationHash, storeName, coords, streetName, zoneLootChances)


    -- Rate limit check
    if AntiCheat and AntiCheat.CheckRateLimit then
        local allowed, remaining = AntiCheat.CheckRateLimit(source, 'theft')
        if not allowed then
            return {
                success = false,
                error = 'rate_limited',
                message = string.format('Wait %ds before stealing again',
                    remaining or 0)
            }
        end
    end

    -- Validate config is loaded
    if not TheftConfig then
        return { success = false, error = 'config_error', message = 'Server configuration error' }
    end

    if not TheftConfig.settings then
        return { success = false, error = 'config_error', message = 'Server configuration error' }
    end

    -- Validate storeType is supported
    if not TheftConfig[storeType] then
        return { success = false, error = 'invalid_store', message = 'Unknown store type' }
    end

    -- Check cooldown
    if IsOnCooldown(source, locationHash, TheftConfig.settings.cooldown) then
        local remaining = GetRemainingCooldown(source, locationHash, TheftConfig.settings.cooldown)
        return {
            success = false,
            error = 'cooldown',
            remaining = remaining,
            message = TheftConfig.settings.messages.cooldown,
        }
    end

    -- Set cooldown immediately
    SetCooldown(source, locationHash)

    -- Checks passed

    -- Pick loot pool (per-rack override when provided)
    local poolName = PickLootPool(storeType, zoneLootChances)

    -- Trigger police alert (chance-based) — silent for thief, ping dispatch only
    local policeAlerted = false
    local alertRoll = math.random(1, 100)
    local copCount = GetOnlineCops()

    if alertRoll <= TheftConfig.settings.policeAlertChance and copCount >= TheftConfig.settings.minCopsForAlert then
        policeAlerted = TriggerPoliceAlert(source, storeType, storeName, coords, streetName)
    end

    -- Nothing found
    if poolName == 'nothing' then
        -- Give small XP for trying
        if CraftingModule and CraftingModule.AddCraftingXP then
            CraftingModule.AddCraftingXP(source, TheftConfig.settings.searchXP)
        end

        return {
            success = true,
            found = false,
            message = TheftConfig.settings.messages.nothing,
            policeAlerted = policeAlerted,
        }
    end

    -- Pick item from pool
    local loot = PickFromPool(poolName)
    if not loot then
        return {
            success = true,
            found = false,
            message = TheftConfig.settings.messages.nothing,
            policeAlerted = policeAlerted,
        }
    end

    -- Verify item exists before adding
    local itemDef = exports.ox_inventory:Items(loot.name)
    if not itemDef then
        return {
            success = false,
            error = 'item_missing',
            message = string.format('Error: Item "%s" not defined in inventory', loot.name),
            policeAlerted = policeAlerted
        }
    end

    -- Try to add item to player inventory immediately (Scavenging logic)
    local added, reason = exports.ox_inventory:AddItem(source, loot.name, loot.count, loot.metadata)

    if not added then
        return {
            success = false,
            error = 'inventory_error',
            message = 'Error: ' .. tostring(reason), -- Show actual reason to user for debugging
            policeAlerted = policeAlerted
        }
    end

    -- Get item data for label
    local itemData = exports.ox_inventory:Items()[loot.name]
    local label = itemData and itemData.label or loot.name

    -- Calculate XP reward
    local xpReward = TheftConfig.settings.searchXP
    if loot.isBlueprint then
        xpReward = xpReward + TheftConfig.settings.blueprintBonusXP
    end

    -- Add crafting XP
    if CraftingModule and CraftingModule.AddCraftingXP then
        CraftingModule.AddCraftingXP(source, xpReward)
    end

    -- Format message
    local message
    if loot.isBlueprint then
        message = string.format(TheftConfig.settings.messages.blueprint, label)
    else
        message = string.format(TheftConfig.settings.messages.found, loot.count, label)
    end

    return {
        success = true,
        found = true,
        item = loot.name,
        label = label,
        count = loot.count,
        isBlueprint = loot.isBlueprint,
        blueprintTier = loot.blueprintTier, -- Pass tier to client
        message = message,
        policeAlerted = policeAlerted,
        xpGained = xpReward
    }
end)
