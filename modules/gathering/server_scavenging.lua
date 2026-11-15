if not lib then return end

local Config = lib.load('data.scavenging')
if not Config then return end

-- Cooldown Tracking: { [source] = { [zoneId|locId] = time } }
local cooldowns = {}

-- Police Alert Configuration
local AlertConfig = {
    enabled = true,
    chance = 80, -- 80% chance to trigger alert
    minCops = 0, -- Minimum cops required for alert
}

-- Get count of online police officers
local function GetOnlineCops()
    local cops = 0

    -- Try wasabi_police first
    if GetResourceState('wasabi_police') == 'started' then
        local success, copCount = pcall(function()
            return exports.wasabi_police:GetCopCount()
        end)
        if success and copCount then return copCount end
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

-- Trigger police dispatch alert
local function TriggerScavengingAlert(source, locationType, streetName)
    if not AlertConfig.enabled then return end

    -- Check chance
    if math.random(1, 100) > AlertConfig.chance then return end

    -- Check minimum cops
    local copCount = GetOnlineCops()
    if copCount < AlertConfig.minCops then return end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)

    -- Use passed street name or default
    streetName = streetName or 'Unknown Location'

    -- cd_dispatch
    if GetResourceState('cd_dispatch') == 'started' then
        local dispatchData = {
            job_table = { 'police', 'sheriff', 'highway' },
            coords = vector3(playerCoords.x, playerCoords.y, playerCoords.z),
            title = '10-15 - Suspicious Activity',
            message = 'Someone searching through property near ' .. streetName,
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

        local success = pcall(function()
            exports['cd_dispatch']:AddNotification(dispatchData)
        end)

        if not success then
            TriggerEvent('cd_dispatch:AddNotification', dispatchData)
        end

        return
    end

    -- ps-dispatch fallback
    if GetResourceState('ps-dispatch') == 'started' then
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
    end
end

RegisterNetEvent('ox_inventory:payoutScavenging', function(zoneId, locationId, streetName)
    local source = source
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local currentTime = os.time()

    local lootPools = {}
    local xpReward = Config.settings.searchXP

    -- Trigger police alert (15% chance)
    TriggerScavengingAlert(source, zoneId or locationId, streetName)

    -- A. Validate Zone (Strict)
    if zoneId then
        local zone = Config.zones[zoneId]
        if not zone then return end -- Invalid zone

        if #(playerCoords - zone.coords) > (zone.radius + 15.0) then
            return
        end

        -- Check Zone Cooldown (Global or Player specific? Usually Player for searching, but Zone for huge loots?)
        -- Let's do Player cooldown for now to allow others to loot, unless it's a "chest" that disappears.
        -- Given the design, it's "Searching Area", so Player cooldown makes sense.
        if cooldowns[source] and cooldowns[source][zoneId] and currentTime < cooldowns[source][zoneId] then
            TriggerClientEvent('ox_lib:notify', source,
                { type = 'error', description = Config.settings.messages.cooldown })
            return
        end

        -- Set Cooldown
        if not cooldowns[source] then cooldowns[source] = {} end
        cooldowns[source][zoneId] = currentTime + (zone.cooldown / 1000)

        -- Determine Loot
        if zone.lootType and Config.rare_materials[zone.lootType] then
            table.insert(lootPools, Config.rare_materials[zone.lootType])
            xpReward = xpReward + Config.settings.rareMaterialBonusXP
        end

        -- B. Validate Global Location (Less Strict, relies on client cooldown mostly + sanity)
    elseif locationId then
        local loc = Config.locations[locationId]
        if not loc then return end

        if not cooldowns[source] then cooldowns[source] = {} end
        -- Shared cooldown for generic searches to prevent spam-searching one shelf repeatedly
        if cooldowns[source][locationId] and currentTime < cooldowns[source][locationId] then
            -- Allow searching *different* instances?
            -- Without entity ID, we can't distinguish shelf A from shelf B.
            -- For now, minimal cooldown to prevent macro-spam.
            if currentTime < cooldowns[source][locationId] then
                return
            end
        end
        cooldowns[source][locationId] = currentTime + 5 -- 5s cooldown between generic searches

        -- Determine Loot
        if loc.lootChances then
            local roll = math.random(1, 100)
            local current = 0
            for _, chanceInfo in ipairs(loc.lootChances) do
                current = current + chanceInfo.chance
                if roll <= current then
                    -- Selected this pool
                    if chanceInfo.pool ~= 'nothing' then
                        if Config.pools[chanceInfo.pool] then
                            table.insert(lootPools, Config.pools[chanceInfo.pool])
                        end
                        -- Check for Bonus XP if blueprint
                        if chanceInfo.pool == 'blueprints' then
                            xpReward = xpReward + Config.settings.blueprintBonusXP
                        end
                    end
                    break
                end
            end
        end
    end

    -- Process Loot Generation - Roll for EACH item in pool separately
    -- This allows finding multiple different items per search!
    local rewards = {}
    for _, pool in ipairs(lootPools) do
        for _, itemData in ipairs(pool) do
            -- Roll against item's weight as drop chance (0-100)
            local roll = math.random(1, 100)
            if roll <= itemData.weight then
                local count = math.random(itemData.count.min, itemData.count.max)
                if count > 0 then
                    rewards[itemData.name] = (rewards[itemData.name] or 0) + count
                end
            end
        end
    end

    -- Fallback: If nothing dropped, guarantee at least one common item
    local itemCount = 0
    for _ in pairs(rewards) do itemCount = itemCount + 1 end

    if itemCount == 0 and #lootPools > 0 then
        -- Pick a random item from first pool as fallback
        local pool = lootPools[1]
        if pool and #pool > 0 then
            local randomItem = pool[math.random(1, #pool)]
            local count = math.random(randomItem.count.min, randomItem.count.max)
            if count > 0 then
                rewards[randomItem.name] = count
            end
        end
    end

    -- Give Rewards and track special finds
    local addedItems = {}
    local foundBlueprint = false
    local blueprintName = nil

    for item, count in pairs(rewards) do
        local success, response = exports.ox_inventory:AddItem(source, item, count)
        if success then
            -- Check if it's a blueprint
            if string.find(item, 'blueprint') then
                foundBlueprint = true
                blueprintName = item
            end

            -- Get item label for nice display
            local itemData = exports.ox_inventory:Items()[item]
            local label = itemData and itemData.label or item
            table.insert(addedItems, count .. 'x ' .. label)
        end
    end

    -- Enhanced Notifications based on what was found
    if #addedItems > 0 then
        if foundBlueprint then
            -- BLUEPRINT FOUND - Extra special notification!
            local itemData = exports.ox_inventory:Items()[blueprintName]
            local label = itemData and itemData.label or blueprintName

            -- Determine blueprint tier for appropriate notification
            local tier = 'RARE'
            local notifyType = 'success'
            local icon = 'scroll'

            if string.find(blueprintName, 'legendary') then
                tier = '🏆 LEGENDARY'
                notifyType = 'success'
            elseif string.find(blueprintName, 'master') then
                tier = '⭐ MASTER'
                notifyType = 'success'
            elseif string.find(blueprintName, 'advanced') then
                tier = '🔷 ADVANCED'
                notifyType = 'success'
            end

            TriggerClientEvent('ox_lib:notify', source, {
                id = 'blueprint_find',
                title = tier .. ' BLUEPRINT FOUND!',
                description = label,
                type = notifyType,
                icon = icon,
                duration = 8000,
                position = 'top',
            })

            -- Play success sound via client
            TriggerClientEvent('ox_inventory:playSound', source, 'PICK_UP_COLLECTIBLE', 'HUD_AWARDS')

            -- Also show the regular items if any (excluding blueprint)
            local otherItems = {}
            for _, itemStr in ipairs(addedItems) do
                if not string.find(itemStr, 'lueprint') then
                    table.insert(otherItems, itemStr)
                end
            end

            if #otherItems > 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Scavenging',
                    description = 'Also found: ' .. table.concat(otherItems, ', '),
                    type = 'success',
                    duration = 4000,
                })
            end
        else
            -- Regular loot notification
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Scavenging Success',
                description = 'Found: ' .. table.concat(addedItems, ', '),
                type = 'success',
                duration = 4000,
            })
        end

        -- Give XP
        if xpReward and xpReward > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Crafting XP',
                description = '+' .. xpReward .. ' XP',
                type = 'inform',
                duration = 2000,
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Scavenging',
            description = Config.settings.messages.nothing or 'Nothing useful found...',
            type = 'inform',
            duration = 2000,
        })
    end
end)
