-- Trade System Server Module
-- Handles trade logic, validation, and item swapping

local activeTrades = {}    -- tradeId -> trade data
local pendingRequests = {} -- sourceId -> targetId
local tradeCounter = 0

-- Generate unique trade ID
local function generateTradeId()
    tradeCounter = tradeCounter + 1
    return string.format('trade_%d_%d', os.time(), tradeCounter)
end

-- Get player name
local function getPlayerName(playerId)
    local player = exports.ox_core:GetPlayer(playerId)
    if player then
        return player.name or GetPlayerName(playerId)
    end
    return GetPlayerName(playerId) or 'Player'
end

-- Request trade with another player
RegisterNetEvent('ox_inventory:requestTrade', function(targetId)
    local source = source

    if source == targetId then
        return TriggerClientEvent('ox_lib:notify', source,
            { title = 'Trade', description = 'Cannot trade with yourself', type = 'error' })
    end

    -- Check if target exists
    if not GetPlayerPed(targetId) then
        return TriggerClientEvent('ox_lib:notify', source,
            { title = 'Trade', description = 'Player not found', type = 'error' })
    end

    -- Check if either player already in trade
    for _, trade in pairs(activeTrades) do
        if trade.player1 == source or trade.player2 == source then
            return TriggerClientEvent('ox_lib:notify', source,
                { title = 'Trade', description = 'Already in a trade', type = 'error' })
        end
        if trade.player1 == targetId or trade.player2 == targetId then
            return TriggerClientEvent('ox_lib:notify', source,
                { title = 'Trade', description = 'Player is busy', type = 'error' })
        end
    end

    -- Store pending request
    pendingRequests[source] = targetId

    local sourceName = getPlayerName(source)
    TriggerClientEvent('ox_inventory:tradeRequest', targetId, source, sourceName)
    TriggerClientEvent('ox_lib:notify', source, { title = 'Trade', description = 'Trade request sent', type = 'info' })
end)

-- Accept trade request
RegisterNetEvent('ox_inventory:acceptTrade', function()
    local source = source

    -- Find who requested trade with us
    local requesterId = nil
    for reqId, targetId in pairs(pendingRequests) do
        if targetId == source then
            requesterId = reqId
            break
        end
    end

    if not requesterId then
        return TriggerClientEvent('ox_lib:notify', source,
            { title = 'Trade', description = 'No pending trade request', type = 'error' })
    end

    -- Clear pending request
    pendingRequests[requesterId] = nil

    -- Create trade session
    local tradeId = generateTradeId()
    activeTrades[tradeId] = {
        player1 = requesterId,
        player2 = source,
        items1 = {},
        items2 = {},
        confirmed1 = false,
        confirmed2 = false
    }

    local requesterName = getPlayerName(requesterId)
    local accepterName = getPlayerName(source)

    -- Open trade windows for both players
    TriggerClientEvent('ox_inventory:openTrade', requesterId, source, accepterName, tradeId)
    TriggerClientEvent('ox_inventory:openTrade', source, requesterId, requesterName, tradeId)
end)

-- Decline trade request
RegisterNetEvent('ox_inventory:declineTrade', function()
    local source = source

    -- Find and remove pending request
    for reqId, targetId in pairs(pendingRequests) do
        if targetId == source then
            pendingRequests[reqId] = nil
            TriggerClientEvent('ox_lib:notify', reqId,
                { title = 'Trade', description = 'Trade request declined', type = 'error' })
            break
        end
    end
end)

-- Cancel outgoing trade request
RegisterNetEvent('ox_inventory:cancelTradeRequest', function()
    local source = source
    pendingRequests[source] = nil
end)

-- Find trade by player
local function findTradeByPlayer(playerId)
    for tradeId, trade in pairs(activeTrades) do
        if trade.player1 == playerId or trade.player2 == playerId then
            return tradeId, trade
        end
    end
    return nil, nil
end

-- Add item to trade
RegisterNetEvent('ox_inventory:addTradeItem', function(slot)
    local source = source
    local tradeId, trade = findTradeByPlayer(source)

    if not trade then return end

    -- Get player inventory
    local inventory = exports.ox_inventory:GetInventory(source)
    if not inventory then return end

    local item = inventory.items[slot]
    if not item then return end

    -- Add to trade items
    local items = (trade.player1 == source) and trade.items1 or trade.items2
    local isPlayer1 = trade.player1 == source

    -- Check if already in trade
    for _, ti in ipairs(items) do
        if ti.slot == slot then return end
    end

    table.insert(items, {
        slot = item.slot,
        name = item.name,
        count = item.count,
        weight = item.weight or 0,
        metadata = item.metadata
    })

    -- Reset confirmations when items change
    trade.confirmed1 = false
    trade.confirmed2 = false

    -- Update both players
    local partner = isPlayer1 and trade.player2 or trade.player1
    TriggerClientEvent('ox_inventory:updateMyTradeItems', source, items)
    TriggerClientEvent('ox_inventory:updateTheirTradeItems', partner, items)
    TriggerClientEvent('ox_inventory:setTheirConfirmed', source, false)
    TriggerClientEvent('ox_inventory:setTheirConfirmed', partner, false)
end)

-- Remove item from trade
RegisterNetEvent('ox_inventory:removeTradeItem', function(slot)
    local source = source
    local tradeId, trade = findTradeByPlayer(source)

    if not trade then return end

    local isPlayer1 = trade.player1 == source
    local items = isPlayer1 and trade.items1 or trade.items2

    -- Remove from trade
    for i, item in ipairs(items) do
        if item.slot == slot then
            table.remove(items, i)
            break
        end
    end

    -- Reset confirmations
    trade.confirmed1 = false
    trade.confirmed2 = false

    -- Update both players
    local partner = isPlayer1 and trade.player2 or trade.player1
    TriggerClientEvent('ox_inventory:updateMyTradeItems', source, items)
    TriggerClientEvent('ox_inventory:updateTheirTradeItems', partner, items)
    TriggerClientEvent('ox_inventory:setTheirConfirmed', source, false)
    TriggerClientEvent('ox_inventory:setTheirConfirmed', partner, false)
end)

-- Confirm trade
RegisterNetEvent('ox_inventory:confirmTrade', function()
    local source = source
    local tradeId, trade = findTradeByPlayer(source)

    if not trade then return end

    local isPlayer1 = trade.player1 == source
    local partner = isPlayer1 and trade.player2 or trade.player1

    if isPlayer1 then
        trade.confirmed1 = true
    else
        trade.confirmed2 = true
    end

    -- Notify partner
    TriggerClientEvent('ox_inventory:setTheirConfirmed', partner, true)

    -- Check if both confirmed
    if trade.confirmed1 and trade.confirmed2 then
        -- Execute trade
        local success = executeTrade(tradeId, trade)

        -- Close trade and notify
        TriggerClientEvent('ox_inventory:closeTrade', trade.player1)
        TriggerClientEvent('ox_inventory:closeTrade', trade.player2)
        TriggerClientEvent('ox_inventory:tradeComplete', trade.player1, success)
        TriggerClientEvent('ox_inventory:tradeComplete', trade.player2, success)

        activeTrades[tradeId] = nil
    end
end)

-- Execute the actual item swap
function executeTrade(tradeId, trade)
    local inv1 = exports.ox_inventory:GetInventory(trade.player1)
    local inv2 = exports.ox_inventory:GetInventory(trade.player2)

    if not inv1 or not inv2 then return false end

    -- Remove items from player 1 and give to player 2
    for _, item in ipairs(trade.items1) do
        local removed = exports.ox_inventory:RemoveItem(trade.player1, item.name, item.count, item.metadata, item.slot)
        if removed then
            exports.ox_inventory:AddItem(trade.player2, item.name, item.count, item.metadata)
        end
    end

    -- Remove items from player 2 and give to player 1
    for _, item in ipairs(trade.items2) do
        local removed = exports.ox_inventory:RemoveItem(trade.player2, item.name, item.count, item.metadata, item.slot)
        if removed then
            exports.ox_inventory:AddItem(trade.player1, item.name, item.count, item.metadata)
        end
    end

    return true
end

-- Cancel trade
RegisterNetEvent('ox_inventory:cancelTrade', function()
    local source = source
    local tradeId, trade = findTradeByPlayer(source)

    if trade then
        TriggerClientEvent('ox_inventory:closeTrade', trade.player1)
        TriggerClientEvent('ox_inventory:closeTrade', trade.player2)

        local partner = (trade.player1 == source) and trade.player2 or trade.player1
        TriggerClientEvent('ox_lib:notify', partner, { title = 'Trade', description = 'Trade cancelled', type = 'error' })

        activeTrades[tradeId] = nil
    end
end)

-- Handle player disconnect
AddEventHandler('playerDropped', function()
    local source = source

    -- Clear pending requests
    pendingRequests[source] = nil
    for reqId, targetId in pairs(pendingRequests) do
        if targetId == source then
            pendingRequests[reqId] = nil
        end
    end

    -- Cancel any active trade
    local tradeId, trade = findTradeByPlayer(source)
    if trade then
        local partner = (trade.player1 == source) and trade.player2 or trade.player1
        TriggerClientEvent('ox_inventory:closeTrade', partner)
        TriggerClientEvent('ox_lib:notify', partner,
            { title = 'Trade', description = 'Trade partner disconnected', type = 'error' })
        activeTrades[tradeId] = nil
    end
end)

return {}
