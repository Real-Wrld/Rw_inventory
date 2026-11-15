-- Crafting Statistics System
-- Tracks crafted items, player stats, and provides leaderboards

if not lib then return end

local MySQL = MySQL

-- ============================================================================
-- DATABASE SCHEMA
-- ============================================================================

-- Create table if not exists (run once on startup)
MySQL.ready(function()
    CreateThread(function()
        -- Yield to ensure we don't start blocking immediately
        Wait(1000)

        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `ox_crafting_stats` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `identifier` VARCHAR(60) NOT NULL,
                `item_name` VARCHAR(50) NOT NULL,
                `count` INT DEFAULT 1,
                `first_crafted` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                `last_crafted` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE KEY `player_item` (`identifier`, `item_name`),
                KEY `identifier` (`identifier`),
                KEY `item_name` (`item_name`),
                KEY `idx_count` (`count` DESC),
                KEY `idx_identifier_count` (`identifier`, `count` DESC),
                KEY `idx_itemname_count` (`item_name`, `count` DESC)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])

        Wait(0)

        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `ox_crafting_totals` (
                `identifier` VARCHAR(60) PRIMARY KEY,
                `total_crafted` INT DEFAULT 0,
                `unique_items` INT DEFAULT 0,
                `rare_crafted` INT DEFAULT 0,
                `legendary_crafted` INT DEFAULT 0,
                `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                KEY `idx_total_crafted` (`total_crafted` DESC)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])

        -- Optimization: Ensure indexes exist for existing tables
        -- Deferred to T+30s to run AFTER full server startup (non-blocking)
        Wait(30000)

        local function EnsureIndex(tableName, indexName, columns)
            MySQL.query(('SHOW INDEX FROM `%s` WHERE Key_name = ?'):format(tableName), { indexName }, function(result)
                if not result or #result == 0 then
                    MySQL.query(('CREATE INDEX `%s` ON `%s` (%s)'):format(indexName, tableName, columns))
                end
            end)
        end

        EnsureIndex('ox_crafting_stats', 'idx_identifier_count', 'identifier, count DESC')
        EnsureIndex('ox_crafting_stats', 'idx_itemname_count', 'item_name, count DESC')
        EnsureIndex('ox_crafting_totals', 'idx_total_crafted', 'total_crafted DESC')
    end)
end)

-- ============================================================================
-- TRACKING FUNCTIONS
-- ============================================================================

---Track a crafted item
---@param source number Player source
---@param itemName string Item crafted
---@param count number Amount crafted
---@param tier string? Item tier (basic, advanced, master, legendary)
local function TrackCraft(source, itemName, count, tier)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    if not identifier then return end

    count = count or 1
    tier = tier or 'basic'

    -- Update item-specific stats (upsert)
    MySQL.query([[
        INSERT INTO ox_crafting_stats (identifier, item_name, count)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE count = count + ?
    ]], { identifier, itemName, count, count })

    -- Update totals
    local rareInc = (tier == 'master' or tier == 'advanced') and count or 0
    local legendaryInc = tier == 'legendary' and count or 0

    MySQL.query([[
        INSERT INTO ox_crafting_totals (identifier, total_crafted, unique_items, rare_crafted, legendary_crafted)
        VALUES (?, ?, 1, ?, ?)
        ON DUPLICATE KEY UPDATE
            total_crafted = total_crafted + ?,
            rare_crafted = rare_crafted + ?,
            legendary_crafted = legendary_crafted + ?
    ]], { identifier, count, rareInc, legendaryInc, count, rareInc, legendaryInc })

    -- Update unique items count lazily (avoid expensive subquery on every craft)
    MySQL.scalar('SELECT COUNT(DISTINCT item_name) FROM ox_crafting_stats WHERE identifier = ?', { identifier }, function(count)
        if count then
            MySQL.update('UPDATE ox_crafting_totals SET unique_items = ? WHERE identifier = ?', { count, identifier })
        end
    end)
end

---Get player's crafting stats
---@param source number Player source
---@return table|nil stats
local function GetPlayerStats(source)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    if not identifier then return nil end

    local totals = MySQL.single.await([[
        SELECT total_crafted, unique_items, rare_crafted, legendary_crafted
        FROM ox_crafting_totals WHERE identifier = ?
    ]], { identifier })

    local topItems = MySQL.query.await([[
        SELECT item_name, count FROM ox_crafting_stats
        WHERE identifier = ?
        ORDER BY count DESC LIMIT 5
    ]], { identifier })

    return {
        totals = totals or { total_crafted = 0, unique_items = 0, rare_crafted = 0, legendary_crafted = 0 },
        topItems = topItems or {},
    }
end

-- ============================================================================
-- LEADERBOARDS
-- ============================================================================

---Get top crafters leaderboard
---@param limit number? Max results (default 10)
---@return table leaderboard
local function GetLeaderboard(limit)
    limit = limit or 10

    local results = MySQL.query.await([[
        SELECT
            t.identifier,
            t.total_crafted,
            t.unique_items,
            t.rare_crafted,
            t.legendary_crafted
        FROM ox_crafting_totals t
        ORDER BY t.total_crafted DESC
        LIMIT ?
    ]], { limit })

    -- Add player names
    local leaderboard = {}
    for i, row in ipairs(results or {}) do
        -- Try to find player name from connected players
        local playerName = 'Unknown'
        for _, playerId in ipairs(GetPlayers()) do
            local pid = GetPlayerIdentifierByType(playerId, 'license')
            if pid == row.identifier then
                playerName = GetPlayerName(playerId) or 'Unknown'
                break
            end
        end

        leaderboard[i] = {
            rank = i,
            name = playerName,
            identifier = row.identifier,
            totalCrafted = row.total_crafted,
            uniqueItems = row.unique_items,
            rareCrafted = row.rare_crafted,
            legendaryCrafted = row.legendary_crafted,
        }
    end

    return leaderboard
end

---Get top crafters of a specific item
---@param itemName string Item name
---@param limit number? Max results (default 10)
---@return table leaderboard
local function GetItemLeaderboard(itemName, limit)
    limit = limit or 10

    local results = MySQL.query.await([[
        SELECT identifier, count, last_crafted
        FROM ox_crafting_stats
        WHERE item_name = ?
        ORDER BY count DESC
        LIMIT ?
    ]], { itemName, limit })

    local leaderboard = {}
    for i, row in ipairs(results or {}) do
        local playerName = 'Unknown'
        for _, playerId in ipairs(GetPlayers()) do
            local pid = GetPlayerIdentifierByType(playerId, 'license')
            if pid == row.identifier then
                playerName = GetPlayerName(playerId) or 'Unknown'
                break
            end
        end

        leaderboard[i] = {
            rank = i,
            name = playerName,
            count = row.count,
            lastCrafted = row.last_crafted,
        }
    end

    return leaderboard
end

-- ============================================================================
-- CALLBACKS
-- ============================================================================

-- Get player's own stats
lib.callback.register('ox_inventory:getCraftingStats', function(source)
    return GetPlayerStats(source)
end)

-- Get global leaderboard
lib.callback.register('ox_inventory:getCraftingLeaderboard', function(source, limit)
    return GetLeaderboard(limit or 10)
end)

-- Get item-specific leaderboard
lib.callback.register('ox_inventory:getItemLeaderboard', function(source, itemName, limit)
    return GetItemLeaderboard(itemName, limit or 10)
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

local CraftingStats = {
    TrackCraft = TrackCraft,
    GetPlayerStats = GetPlayerStats,
    GetLeaderboard = GetLeaderboard,
    GetItemLeaderboard = GetItemLeaderboard,
}

exports('GetCraftingStats', function() return CraftingStats end)

return CraftingStats
