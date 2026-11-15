if not lib then return end

local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'

local MONEY_ITEM = 'money'
local VALID_DURATIONS = { [24] = true, [48] = true }

-- ============================================================================
-- HELPERS
-- ============================================================================

local function getPlayerIdentifier(source)
    return GetPlayerIdentifierByType(source, 'license')
end

local function findPlayerByIdentifier(identifier)
    if not identifier then return nil end
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src and GetPlayerIdentifierByType(src, 'license') == identifier then
            return src
        end
    end
    return nil
end

local function decodeMetadata(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) ~= 'string' or raw == '' then return {} end
    local ok, decoded = pcall(json.decode, raw)
    return (ok and type(decoded) == 'table') and decoded or {}
end

local function encodeMetadata(metadata)
    if type(metadata) == 'string' then return metadata end
    return json.encode(metadata or {})
end

local function notify(source, nType, description)
    if not source then return end
    TriggerClientEvent('ox_lib:notify', source, {
        type = nType or 'inform',
        description = description
    })
end

local function logTransaction(txType, data)
    MySQL.insert(
        'INSERT INTO ox_market_transactions (type, listing_id, request_id, seller, seller_name, buyer, buyer_name, item, label, count, price) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            txType,
            data.listing_id or nil,
            data.request_id or nil,
            data.seller or '',
            data.seller_name or 'Unknown',
            data.buyer or '',
            data.buyer_name or 'Unknown',
            data.item,
            data.label or data.item,
            data.count or 1,
            data.price or 0
        }
    )
end

local function queuePayout(identifier, amount, reason)
    if not identifier or not amount or amount < 1 then return end
    MySQL.insert(
        'INSERT INTO ox_market_pending_payouts (identifier, amount, reason) VALUES (?, ?, ?)',
        { identifier, amount, reason or 'market_payout' }
    )
end

local function queueReturn(identifier, item, count, metadata, label)
    if not identifier or not item or not count or count < 1 then return end
    MySQL.insert(
        'INSERT INTO ox_market_pending_returns (identifier, item, count, metadata, label) VALUES (?, ?, ?, ?, ?)',
        { identifier, item, count, encodeMetadata(metadata), label or item }
    )
end

--- Pay money to a player if online, otherwise queue a pending payout
local function payPlayer(identifier, amount, reason, onlineNotify)
    if not identifier or not amount or amount < 1 then return false end

    local src = findPlayerByIdentifier(identifier)
    if src then
        local inv = Inventory(src)
        if inv and Inventory.AddItem(inv, MONEY_ITEM, amount) then
            if onlineNotify then
                notify(src, 'success', onlineNotify)
            end
            return true
        end
    end

    queuePayout(identifier, amount, reason)
    return false
end

--- Give an item to a player if online & can carry, otherwise queue pending return
local function giveItemOrQueue(identifier, item, count, metadata, label, onlineNotify)
    metadata = metadata or {}
    local src = findPlayerByIdentifier(identifier)
    if src then
        local inv = Inventory(src)
        if inv and Inventory.CanCarryItem(inv, item, count, metadata) and Inventory.AddItem(inv, item, count, metadata) then
            if onlineNotify then
                notify(src, 'success', onlineNotify)
            end
            return true
        end
    end

    queueReturn(identifier, item, count, metadata, label)
    return false
end

local function minNextBid(listing)
    local current = tonumber(listing.current_bid) or 0
    if current <= 0 then
        local starting = tonumber(listing.starting_bid) or tonumber(listing.price) or 0
        return math.max(starting, 1)
    end

    local increase = math.max(math.floor(current * 0.05), 100)
    return current + increase
end

local function claimListing(listingId, newStatus)
    local affected = MySQL.update.await(
        'UPDATE ox_market_listings SET status = ? WHERE id = ? AND status = ?',
        { newStatus, listingId, 'active' }
    )
    return affected and affected > 0
end

local function deleteListing(listingId)
    MySQL.update('DELETE FROM ox_market_bids WHERE listing_id = ?', { listingId })
    MySQL.update('DELETE FROM ox_market_listings WHERE id = ?', { listingId })
end

local function refundBidder(identifier, amount, name, reason)
    if not identifier or not amount or amount < 1 then return end
    payPlayer(identifier, amount, reason or 'auction_outbid_refund',
        ('You were outbid on the market. $%s has been refunded.'):format(amount))
end

-- ============================================================================
-- PENDING PAYOUTS / RETURNS
-- ============================================================================

local function processPendingForPlayer(source)
    local identifier = getPlayerIdentifier(source)
    if not identifier then return { payouts = 0, returns = 0 } end

    local inv = Inventory(source)
    if not inv then return { payouts = 0, returns = 0 } end

    local payoutsPaid = 0
    local returnsGiven = 0

    local payouts = MySQL.query.await(
        'SELECT * FROM ox_market_pending_payouts WHERE identifier = ? ORDER BY id ASC',
        { identifier }
    ) or {}

    for i = 1, #payouts do
        local row = payouts[i]
        local amount = tonumber(row.amount) or 0
        if amount > 0 and Inventory.AddItem(inv, MONEY_ITEM, amount) then
            MySQL.update('DELETE FROM ox_market_pending_payouts WHERE id = ?', { row.id })
            payoutsPaid += amount
        end
    end

    local returns = MySQL.query.await(
        'SELECT * FROM ox_market_pending_returns WHERE identifier = ? ORDER BY id ASC',
        { identifier }
    ) or {}

    for i = 1, #returns do
        local row = returns[i]
        local metadata = decodeMetadata(row.metadata)
        local count = tonumber(row.count) or 1
        if Inventory.CanCarryItem(inv, row.item, count, metadata) and Inventory.AddItem(inv, row.item, count, metadata) then
            MySQL.update('DELETE FROM ox_market_pending_returns WHERE id = ?', { row.id })
            returnsGiven += 1
        end
    end

    if payoutsPaid > 0 or returnsGiven > 0 then
        local parts = {}
        if payoutsPaid > 0 then
            parts[#parts + 1] = ('$%s market payout'):format(payoutsPaid)
        end
        if returnsGiven > 0 then
            parts[#parts + 1] = ('%s returned item(s)'):format(returnsGiven)
        end
        notify(source, 'success', ('Market: claimed %s.'):format(table.concat(parts, ' and ')))
    end

    return { payouts = payoutsPaid, returns = returnsGiven }
end

-- ============================================================================
-- AUCTION SETTLEMENT
-- ============================================================================

--- Settle an active auction (buyout or expiry with bids).
--- On normal bid wins, escrow already holds current_bid from the winner.
local function settleAuction(listing, buyerSource, isBuyout)
    local listingId = listing.id
    local metadata = decodeMetadata(listing.metadata)

    if not isBuyout then
        local price = tonumber(listing.current_bid) or 0
        local buyerIdentifier = listing.current_bidder
        local buyerName = listing.current_bidder_name or 'Unknown'

        if not buyerIdentifier or price < 1 then
            return false, 'no_bids'
        end

        if not claimListing(listingId, 'sold') then
            return false, 'listing_unavailable'
        end

        giveItemOrQueue(buyerIdentifier, listing.item, listing.count, metadata, listing.label,
            ('You won the auction for %s!'):format(listing.label or listing.item))

        payPlayer(listing.owner, price, 'auction_won',
            ('Your auction for %s sold for $%s!'):format(listing.label or listing.item, price))

        deleteListing(listingId)

        logTransaction('auction_won', {
            listing_id = listingId,
            seller = listing.owner,
            seller_name = listing.owner_name,
            buyer = buyerIdentifier,
            buyer_name = buyerName,
            item = listing.item,
            label = listing.label,
            count = listing.count,
            price = price
        })

        return true
    end

    -- Buyout path
    local price = tonumber(listing.buyout) or 0
    if price < 1 then return false, 'invalid_price' end
    if not buyerSource then return false, 'inv_error' end

    local buyerIdentifier = getPlayerIdentifier(buyerSource)
    local buyerName = GetPlayerName(buyerSource) or 'Unknown'
    local inv = Inventory(buyerSource)
    if not inv then return false, 'inv_error' end

    if listing.owner == buyerIdentifier then
        return false, 'cannot_buy_own'
    end

    local prevBidder = listing.current_bidder
    local prevBid = tonumber(listing.current_bid) or 0
    local alreadyEscrowed = (prevBidder == buyerIdentifier) and prevBid or 0
    local charge = price - alreadyEscrowed

    if charge > 0 and Inventory.GetItemCount(inv, MONEY_ITEM) < charge then
        return false, 'cannot_afford'
    end

    if not Inventory.CanCarryItem(inv, listing.item, listing.count, metadata) then
        return false, 'cannot_carry'
    end

    if not claimListing(listingId, 'sold') then
        return false, 'listing_unavailable'
    end

    if charge > 0 then
        if not Inventory.RemoveItem(inv, MONEY_ITEM, charge) then
            MySQL.update('UPDATE ox_market_listings SET status = ? WHERE id = ?', { 'active', listingId })
            return false, 'cannot_afford'
        end
    elseif charge < 0 then
        Inventory.AddItem(inv, MONEY_ITEM, -charge)
    end

    if not Inventory.AddItem(inv, listing.item, listing.count, metadata) then
        if charge > 0 then
            Inventory.AddItem(inv, MONEY_ITEM, charge)
        elseif charge < 0 then
            Inventory.RemoveItem(inv, MONEY_ITEM, -charge)
        end
        MySQL.update('UPDATE ox_market_listings SET status = ? WHERE id = ?', { 'active', listingId })
        return false, 'inventory_full'
    end

    -- Refund previous high bidder when someone else buys out
    if prevBidder and prevBid > 0 and prevBidder ~= buyerIdentifier then
        refundBidder(prevBidder, prevBid, listing.current_bidder_name, 'auction_buyout_refund')
    end

    payPlayer(listing.owner, price, 'auction_buyout',
        ('Your auction for %s was bought out for $%s!'):format(listing.label or listing.item, price))

    deleteListing(listingId)

    logTransaction('buyout', {
        listing_id = listingId,
        seller = listing.owner,
        seller_name = listing.owner_name,
        buyer = buyerIdentifier,
        buyer_name = buyerName,
        item = listing.item,
        label = listing.label,
        count = listing.count,
        price = price
    })

    return true
end

-- ============================================================================
-- EXPIRY PROCESSING
-- ============================================================================

local function expireListing(listing)
    local listingId = listing.id
    local mode = listing.mode or 'buynow'
    local metadata = decodeMetadata(listing.metadata)

    if mode == 'auction' then
        local currentBid = tonumber(listing.current_bid) or 0
        if listing.current_bidder and currentBid > 0 then
            settleAuction(listing, nil, false)
            return
        end

        -- No bids: return item to seller
        if not claimListing(listingId, 'expired') then return end
        giveItemOrQueue(listing.owner, listing.item, listing.count, metadata, listing.label,
            ('Your auction for %s expired with no bids. Item returned.'):format(listing.label or listing.item))
        deleteListing(listingId)
        return
    end

    -- Buy-now expired: return item
    if not claimListing(listingId, 'expired') then return end
    giveItemOrQueue(listing.owner, listing.item, listing.count, metadata, listing.label,
        ('Your market listing for %s expired. Item returned.'):format(listing.label or listing.item))
    deleteListing(listingId)
end

-- ============================================================================
-- STARTUP: Schema migrations + expiry thread + pending for online players
-- ============================================================================

CreateThread(function()
    Wait(2000)

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `ox_market_bids` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `listing_id` int(11) NOT NULL,
      `bidder` varchar(50) NOT NULL,
      `bidder_name` varchar(50) DEFAULT 'Unknown',
      `amount` int(11) NOT NULL,
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      KEY `idx_listing_id` (`listing_id`),
      KEY `idx_bidder` (`bidder`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `ox_market_pending_payouts` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `identifier` varchar(50) NOT NULL,
      `amount` int(11) NOT NULL,
      `reason` varchar(255) DEFAULT NULL,
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      KEY `idx_identifier` (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `ox_market_pending_returns` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `identifier` varchar(50) NOT NULL,
      `item` varchar(50) NOT NULL,
      `count` int(11) NOT NULL DEFAULT 1,
      `metadata` longtext DEFAULT NULL,
      `label` varchar(100) DEFAULT NULL,
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      KEY `idx_identifier` (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    local alters = {
        "ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `mode` varchar(20) NOT NULL DEFAULT 'buynow'",
        "ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `starting_bid` int(11) NOT NULL DEFAULT 0",
        "ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `buyout` int(11) DEFAULT NULL",
        "ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `current_bid` int(11) NOT NULL DEFAULT 0",
        "ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `current_bidder` varchar(50) DEFAULT NULL",
        "ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `current_bidder_name` varchar(50) DEFAULT NULL",
        "ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `duration_hours` int(11) NOT NULL DEFAULT 24",
        "ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `status` varchar(20) NOT NULL DEFAULT 'active'",
        "ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `expires_at` timestamp NULL DEFAULT NULL",
    }

    for i = 1, #alters do
        pcall(function()
            MySQL.query.await(alters[i])
        end)
    end

    Wait(3000)

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src and Inventory(src) then
            processPendingForPlayer(src)
        end
    end
end)

CreateThread(function()
    Wait(8000)
    while true do
        local expired = MySQL.query.await(
            "SELECT * FROM ox_market_listings WHERE status = 'active' AND expires_at IS NOT NULL AND expires_at < NOW()"
        ) or {}

        for i = 1, #expired do
            local ok, err = pcall(expireListing, expired[i])
            if not ok then
                print(('[ox_market] expireListing error for #%s: %s'):format(expired[i].id, err))
            end
        end

        Wait(60000)
    end
end)

-- Hook inventory ready / player loaded
AddEventHandler('ox_inventory:setPlayerInventory', function(player)
    local source = type(player) == 'table' and (player.source or player.id) or player
    source = tonumber(source)
    if not source then return end
    SetTimeout(2500, function()
        if Inventory(source) then
            processPendingForPlayer(source)
        end
    end)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local source = Player and (Player.PlayerData and Player.PlayerData.source or Player.source)
    source = tonumber(source)
    if not source then return end
    SetTimeout(3000, function()
        if Inventory(source) then
            processPendingForPlayer(source)
        end
    end)
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    SetTimeout(3000, function()
        if Inventory(src) then
            processPendingForPlayer(src)
        end
    end)
end)

AddEventHandler('qbx_core:server:playerLoaded', function(player)
    local source = type(player) == 'table' and (player.PlayerData and player.PlayerData.source or player.source) or player
    source = tonumber(source)
    if not source then return end
    SetTimeout(3000, function()
        if Inventory(source) then
            processPendingForPlayer(source)
        end
    end)
end)

-- ============================================================================
-- CALLBACKS: Pending claims (client may call when market opens)
-- ============================================================================

lib.callback.register('ox_market:claimPending', function(source)
    return processPendingForPlayer(source)
end)

RegisterNetEvent('ox_market:claimPending', function()
    local source = source
    processPendingForPlayer(source)
end)

-- ============================================================================
-- LISTINGS: Browse
-- ============================================================================

lib.callback.register('ox_market:getListings', function(source, filters)
    processPendingForPlayer(source)

    local query = "SELECT * FROM ox_market_listings WHERE status = 'active' AND (expires_at IS NULL OR expires_at > NOW())"
    local params = {}

    if filters then
        if filters.search and filters.search ~= '' then
            query = query .. ' AND (label LIKE ? OR item LIKE ?)'
            local search = '%' .. filters.search .. '%'
            params[#params + 1] = search
            params[#params + 1] = search
        end

        if filters.tier and filters.tier ~= '' and filters.tier ~= 'all' then
            query = query .. ' AND tier = ?'
            params[#params + 1] = filters.tier
        end

        if filters.mode and filters.mode ~= '' and filters.mode ~= 'all' then
            query = query .. ' AND mode = ?'
            params[#params + 1] = filters.mode
        end

        if filters.minPrice and filters.minPrice > 0 then
            query = query .. ' AND price >= ?'
            params[#params + 1] = filters.minPrice
        end

        if filters.maxPrice and filters.maxPrice > 0 then
            query = query .. ' AND price <= ?'
            params[#params + 1] = filters.maxPrice
        end
    end

    query = query .. ' ORDER BY created_at DESC LIMIT 100'

    return MySQL.query.await(query, params) or {}
end)

lib.callback.register('ox_market:getMyListings', function(source)
    local identifier = getPlayerIdentifier(source)
    return MySQL.query.await(
        "SELECT * FROM ox_market_listings WHERE owner = ? AND status = 'active' ORDER BY created_at DESC",
        { identifier }
    ) or {}
end)

-- ============================================================================
-- LISTINGS: Sellable inventory for UI picker
-- ============================================================================

lib.callback.register('ox_market:getSellableItems', function(source)
    local inv = Inventory(source)
    if not inv or not inv.items then return {} end

    local result = {}
    for slot, item in pairs(inv.items) do
        if item and item.name and item.name ~= MONEY_ITEM then
            local meta = item.metadata or {}
            result[#result + 1] = {
                slot = item.slot or slot,
                name = item.name,
                label = item.label or item.name,
                count = item.count or 1,
                metadata = meta,
                tier = meta.tier or meta.rarity or 'basic'
            }
        end
    end

    table.sort(result, function(a, b)
        return (a.slot or 0) < (b.slot or 0)
    end)

    return result
end)

-- ============================================================================
-- LISTINGS: Create
-- ============================================================================

lib.callback.register('ox_market:createListing', function(source, data)
    local inv = Inventory(source)
    if not inv then return { success = false, error = 'inv_error' } end
    if type(data) ~= 'table' then return { success = false, error = 'invalid_data' } end

    local mode = data.mode or 'buynow'
    if mode ~= 'buynow' and mode ~= 'auction' then
        return { success = false, error = 'invalid_mode' }
    end

    local durationHours = tonumber(data.durationHours) or 24
    if not VALID_DURATIONS[durationHours] then
        return { success = false, error = 'invalid_duration' }
    end

    local price = tonumber(data.price)
    local count = tonumber(data.count) or 1
    if not price or price < 1 then return { success = false, error = 'invalid_price' } end
    if count < 1 then return { success = false, error = 'invalid_count' } end

    local buyout = data.buyout ~= nil and tonumber(data.buyout) or nil
    if buyout ~= nil then
        if buyout < 1 then return { success = false, error = 'invalid_buyout' } end
        if mode == 'auction' and buyout <= price then
            return { success = false, error = 'buyout_too_low' }
        end
    end

    local itemName = data.item
    local metadata = data.metadata
    local slot = data.slot and tonumber(data.slot) or nil

    if slot then
        local slotItem = inv.items[slot]
        if not slotItem then return { success = false, error = 'invalid_slot' } end
        itemName = slotItem.name
        metadata = slotItem.metadata or {}
        if (slotItem.count or 0) < count then
            return { success = false, error = 'missing_item' }
        end
    end

    if not itemName or itemName == '' or itemName == MONEY_ITEM then
        return { success = false, error = 'invalid_item' }
    end

    local itemData = Items(itemName)
    if not itemData then return { success = false, error = 'invalid_item_type' } end

    metadata = metadata or {}

    local owned = Inventory.GetItem(inv, itemName, metadata, true)
    if not owned or owned < count then
        return { success = false, error = 'missing_item' }
    end

    if not Inventory.RemoveItem(inv, itemName, count, metadata, slot) then
        return { success = false, error = 'remove_failed' }
    end

    local expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (durationHours * 3600))

    local startingBid = mode == 'auction' and price or 0
    local listingPrice = price
    local tier = data.tier or metadata.tier or metadata.rarity or 'basic'

    local id = MySQL.insert.await(
        [[INSERT INTO ox_market_listings
          (owner, owner_name, item, label, count, price, tier, metadata, mode, starting_bid, buyout,
           current_bid, current_bidder, current_bidder_name, duration_hours, status, expires_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NULL, NULL, ?, 'active', ?)]],
        {
            getPlayerIdentifier(source),
            GetPlayerName(source),
            itemName,
            data.label or itemData.label or itemName,
            count,
            listingPrice,
            tier,
            encodeMetadata(metadata),
            mode,
            startingBid,
            buyout,
            durationHours,
            expiresAt
        }
    )

    if id then
        return { success = true, id = id }
    end

    Inventory.AddItem(inv, itemName, count, metadata)
    return { success = false, error = 'db_error' }
end)

-- ============================================================================
-- LISTINGS: Cancel
-- ============================================================================

lib.callback.register('ox_market:cancelListing', function(source, listingId)
    local identifier = getPlayerIdentifier(source)
    local listing = MySQL.single.await(
        "SELECT * FROM ox_market_listings WHERE id = ? AND owner = ? AND status = 'active'",
        { listingId, identifier }
    )

    if not listing then return false, 'listing_not_found' end

    local inv = Inventory(source)
    if not inv then return false, 'inv_error' end

    local metadata = decodeMetadata(listing.metadata)
    if not Inventory.CanCarryItem(inv, listing.item, listing.count, metadata) then
        return false, 'cannot_carry'
    end

    if not claimListing(listingId, 'cancelled') then
        return false, 'listing_unavailable'
    end

    -- Refund current bidder escrow if auction had bids
    local currentBid = tonumber(listing.current_bid) or 0
    if listing.mode == 'auction' and listing.current_bidder and currentBid > 0 then
        refundBidder(listing.current_bidder, currentBid, listing.current_bidder_name, 'auction_cancelled_refund')
    end

    if not Inventory.AddItem(inv, listing.item, listing.count, metadata) then
        MySQL.update('UPDATE ox_market_listings SET status = ? WHERE id = ?', { 'active', listingId })
        return false, 'inventory_full'
    end

    deleteListing(listingId)
    return true
end)

-- ============================================================================
-- LISTINGS: Buy (buynow or auction buyout)
-- ============================================================================

lib.callback.register('ox_market:buyItem', function(source, listingId)
    local inv = Inventory(source)
    if not inv then return false, 'inv_error' end

    local listing = MySQL.single.await(
        "SELECT * FROM ox_market_listings WHERE id = ? AND status = 'active'",
        { listingId }
    )

    if not listing then return false, 'listing_not_found' end

    local mode = listing.mode or 'buynow'
    local buyerIdentifier = getPlayerIdentifier(source)

    if listing.owner == buyerIdentifier then
        return false, 'cannot_buy_own'
    end

    if mode == 'auction' then
        local buyout = tonumber(listing.buyout)
        if not buyout or buyout < 1 then
            return false, 'no_buyout'
        end
        return settleAuction(listing, source, true)
    end

    -- Buy-now purchase
    local price = tonumber(listing.price) or 0
    if price < 1 then return false, 'invalid_price' end

    local itemData = Items(listing.item)
    if not itemData then return false, 'invalid_item_type' end

    local metadata = decodeMetadata(listing.metadata)

    if Inventory.GetItemCount(inv, MONEY_ITEM) < price then
        return false, 'cannot_afford'
    end

    if not Inventory.CanCarryItem(inv, listing.item, listing.count, metadata) then
        return false, 'cannot_carry'
    end

    if not claimListing(listingId, 'sold') then
        return false, 'listing_unavailable'
    end

    if not Inventory.RemoveItem(inv, MONEY_ITEM, price) then
        MySQL.update('UPDATE ox_market_listings SET status = ? WHERE id = ?', { 'active', listingId })
        return false, 'money_transfer_failed'
    end

    if not Inventory.AddItem(inv, listing.item, listing.count, metadata) then
        Inventory.AddItem(inv, MONEY_ITEM, price)
        MySQL.update('UPDATE ox_market_listings SET status = ? WHERE id = ?', { 'active', listingId })
        return false, 'inventory_full'
    end

    payPlayer(listing.owner, price, 'listing_sale',
        ('Your listing for %s was purchased for $%s!'):format(listing.label or listing.item, price))

    deleteListing(listingId)

    logTransaction('sale', {
        listing_id = listingId,
        seller = listing.owner,
        seller_name = listing.owner_name,
        buyer = buyerIdentifier,
        buyer_name = GetPlayerName(source),
        item = listing.item,
        label = listing.label,
        count = listing.count,
        price = price
    })

    return true
end)

-- ============================================================================
-- AUCTIONS: Place bid (escrow)
-- ============================================================================

lib.callback.register('ox_market:placeBid', function(source, listingId, amount)
    local inv = Inventory(source)
    if not inv then return false, 'inv_error' end

    amount = tonumber(amount)
    if not amount or amount < 1 then return false, 'invalid_bid' end

    local listing = MySQL.single.await(
        "SELECT * FROM ox_market_listings WHERE id = ? AND status = 'active'",
        { listingId }
    )

    if not listing then return false, 'listing_not_found' end
    if (listing.mode or 'buynow') ~= 'auction' then return false, 'not_auction' end

    local bidder = getPlayerIdentifier(source)
    if listing.owner == bidder then return false, 'cannot_bid_own' end

    if listing.current_bidder == bidder then
        return false, 'already_high_bidder'
    end

    local minimum = minNextBid(listing)
    if amount < minimum then
        return false, 'bid_too_low'
    end

    local buyout = tonumber(listing.buyout)
    if buyout and buyout > 0 and amount >= buyout then
        -- Treat as buyout
        return settleAuction(listing, source, true)
    end

    if Inventory.GetItemCount(inv, MONEY_ITEM) < amount then
        return false, 'cannot_afford'
    end

    if not Inventory.RemoveItem(inv, MONEY_ITEM, amount) then
        return false, 'cannot_afford'
    end

    local prevBidder = listing.current_bidder
    local prevBid = tonumber(listing.current_bid) or 0
    local bidderName = GetPlayerName(source) or 'Unknown'

    local affected = MySQL.update.await(
        [[UPDATE ox_market_listings
           SET current_bid = ?, current_bidder = ?, current_bidder_name = ?
           WHERE id = ? AND status = 'active'
             AND (current_bid = ? OR (current_bid IS NULL AND ? = 0))
             AND (current_bidder = ? OR (current_bidder IS NULL AND ? IS NULL))]],
        {
            amount, bidder, bidderName,
            listingId,
            prevBid, prevBid,
            prevBidder, prevBidder
        }
    )

    if not affected or affected < 1 then
        Inventory.AddItem(inv, MONEY_ITEM, amount)
        return false, 'bid_race_lost'
    end

    if prevBidder and prevBid > 0 then
        refundBidder(prevBidder, prevBid, listing.current_bidder_name, 'auction_outbid_refund')
    end

    MySQL.insert(
        'INSERT INTO ox_market_bids (listing_id, bidder, bidder_name, amount) VALUES (?, ?, ?, ?)',
        { listingId, bidder, bidderName, amount }
    )

    logTransaction('bid', {
        listing_id = listingId,
        seller = listing.owner,
        seller_name = listing.owner_name,
        buyer = bidder,
        buyer_name = bidderName,
        item = listing.item,
        label = listing.label,
        count = listing.count,
        price = amount
    })

    local sellerSrc = findPlayerByIdentifier(listing.owner)
    if sellerSrc then
        notify(sellerSrc, 'inform',
            ('New bid of $%s on your auction for %s.'):format(amount, listing.label or listing.item))
    end

    return true, { current_bid = amount, minimum_next = amount + math.max(math.floor(amount * 0.05), 100) }
end)

-- ============================================================================
-- REQUESTS
-- ============================================================================

lib.callback.register('ox_market:getRequests', function(source)
    local identifier = getPlayerIdentifier(source)
    return MySQL.query.await(
        [[SELECT * FROM ox_market_requests
          WHERE status = 'active' OR (status = 'fulfilled' AND owner = ?)
          ORDER BY created_at DESC]],
        { identifier }
    ) or {}
end)

lib.callback.register('ox_market:createRequest', function(source, data)
    local inv = Inventory(source)
    if not inv then return { success = false, error = 'inv_error' } end

    if not data.item or data.item == '' then return { success = false, error = 'invalid_item' } end
    if not data.count or data.count < 1 then return { success = false, error = 'invalid_count' } end
    if not data.price or data.price < 1 then return { success = false, error = 'invalid_price' } end

    if not Inventory.RemoveItem(inv, MONEY_ITEM, data.price) then
        return { success = false, error = 'cannot_afford' }
    end

    local id = MySQL.insert.await(
        'INSERT INTO ox_market_requests (owner, owner_name, item, label, count, price, tier, materials, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            getPlayerIdentifier(source),
            GetPlayerName(source),
            data.item,
            data.label or data.item,
            data.count,
            data.price,
            data.tier or 'basic',
            json.encode(data.materials or {}),
            'active'
        }
    )

    if id then
        return { success = true, id = id }
    end

    Inventory.AddItem(inv, MONEY_ITEM, data.price)
    return { success = false, error = 'db_error' }
end)

lib.callback.register('ox_market:fulfillRequest', function(source, requestId)
    local inv = Inventory(source)
    if not inv then return false, 'inv_error' end

    local request = MySQL.single.await(
        'SELECT * FROM ox_market_requests WHERE id = ? AND status = ?',
        { requestId, 'active' }
    )

    if not request then return false, 'request_invalid' end

    local fulfillerIdentifier = getPlayerIdentifier(source)
    if request.owner == fulfillerIdentifier then return false, 'cannot_fulfill_own' end

    if Inventory.GetItemCount(inv, request.item) < request.count then
        return false, 'missing_item'
    end

    if not Inventory.RemoveItem(inv, request.item, request.count) then
        return false, 'remove_failed'
    end

    Inventory.AddItem(inv, MONEY_ITEM, request.price)

    MySQL.update('UPDATE ox_market_requests SET status = ?, fulfilled_by = ? WHERE id = ?', {
        'fulfilled',
        fulfillerIdentifier,
        requestId
    })

    logTransaction('request_fulfilled', {
        request_id = requestId,
        seller = fulfillerIdentifier,
        seller_name = GetPlayerName(source),
        buyer = request.owner,
        buyer_name = request.owner_name,
        item = request.item,
        label = request.label,
        count = request.count,
        price = request.price
    })

    local requesterSource = findPlayerByIdentifier(request.owner)
    if requesterSource then
        notify(requesterSource, 'success',
            ('Your request for %s has been fulfilled! Visit the market to collect.'):format(
                request.label or request.item))
    end

    return true
end)

lib.callback.register('ox_market:collectFulfilled', function(source, requestId)
    local inv = Inventory(source)
    if not inv then return false, 'inv_error' end

    local request = MySQL.single.await(
        'SELECT * FROM ox_market_requests WHERE id = ? AND status = ? AND owner = ?',
        { requestId, 'fulfilled', getPlayerIdentifier(source) }
    )

    if not request then return false, 'invalid_collection' end

    if not Inventory.CanCarryItem(inv, request.item, request.count) then
        return false, 'cannot_carry'
    end

    if Inventory.AddItem(inv, request.item, request.count) then
        MySQL.update('DELETE FROM ox_market_requests WHERE id = ?', { requestId })
        return true
    end

    return false, 'cannot_carry'
end)

lib.callback.register('ox_market:cancelRequest', function(source, requestId)
    local identifier = getPlayerIdentifier(source)
    local request = MySQL.single.await(
        'SELECT * FROM ox_market_requests WHERE id = ? AND status = ? AND owner = ?',
        { requestId, 'active', identifier }
    )

    if not request then return false, 'request_not_found' end

    local inv = Inventory(source)
    if not inv then return false, 'inv_error' end

    Inventory.AddItem(inv, MONEY_ITEM, request.price)
    MySQL.update('DELETE FROM ox_market_requests WHERE id = ?', { requestId })

    return true
end)

-- ============================================================================
-- TRANSACTIONS
-- ============================================================================

lib.callback.register('ox_market:getTransactions', function(source)
    local identifier = getPlayerIdentifier(source)
    return MySQL.query.await(
        'SELECT * FROM ox_market_transactions WHERE seller = ? OR buyer = ? ORDER BY created_at DESC LIMIT 50',
        { identifier, identifier }
    ) or {}
end)
