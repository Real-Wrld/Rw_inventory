local Config = lib.require('data.mining')

-- Payout Event
RegisterNetEvent('ox_inventory:payoutMining', function()
    local source = source
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)

    -- 1. Security Check: Distance to Zone
    local isInZone = false
    for _, zone in pairs(Config.zones) do
        if #(playerCoords - zone.coords) <= (zone.radius + 10.0) then -- Slight buffer for sync
            isInZone = true
            break
        end
    end

    if not isInZone then
        -- silent reject: mining outside zone
        return
    end

    -- 2. Calculate Rewards
    local rewards = {}

    -- Function to roll for items in a category
    local function rollCategory(categoryTable)
        for item, data in pairs(categoryTable) do
            local roll = math.random(1, 100)
            if roll <= data.chance then
                local amount = math.random(data.min, data.max)
                if amount > 0 then
                    rewards[item] = amount
                end
            end
        end
    end

    -- Roll across different categories
    rollCategory(Config.rewards.common)
    rollCategory(Config.rewards.rare)
    rollCategory(Config.rewards.gems)

    -- 3. Give Items
    local addedItems = {}
    for item, count in pairs(rewards) do
        local success, response = exports.ox_inventory:AddItem(source, item, count)
        if success then
            table.insert(addedItems, count .. 'x ' .. item)
        end
    end

    -- 4. Notify User
    if #addedItems > 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Mining Payout',
            description = 'You found: ' .. table.concat(addedItems, ', '),
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Mining',
            description = 'You found nothing this time.',
            type = 'inform'
        })
    end
end)
