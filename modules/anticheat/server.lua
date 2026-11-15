-- Anti-Cheat & Rate Limiting Module
-- Protects inventory actions from abuse and suspicious activity

if not lib then return end


local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'

-- ============================================================================
-- RATE LIMITING
-- ============================================================================

-- Rate limit storage: { [source] = { [action] = { count, lastReset } } }
local RateLimits = {}

-- Rate limit configuration
local RATE_LIMITS = {
    craft = { limit = 10, window = 60 },    -- 10 crafts per 60 seconds
    theft = { limit = 5, window = 120 },    -- 5 thefts per 2 minutes
    search = { limit = 15, window = 60 },   -- 15 searches per minute
    drop = { limit = 20, window = 60 },     -- 20 drops per minute
    transfer = { limit = 50, window = 60 }, -- 50 transfers per minute
}

---Check if action is rate limited
---@param source number Player source
---@param action string Action type (craft, theft, search, drop, transfer)
---@return boolean allowed
---@return number? remaining Seconds until reset
local function CheckRateLimit(source, action)
    local config = RATE_LIMITS[action]
    if not config then return true end

    local now = os.time()

    if not RateLimits[source] then
        RateLimits[source] = {}
    end

    if not RateLimits[source][action] then
        RateLimits[source][action] = { count = 0, lastReset = now }
    end

    local limit = RateLimits[source][action]

    -- Reset if window expired
    if (now - limit.lastReset) >= config.window then
        limit.count = 0
        limit.lastReset = now
    end

    -- Check if over limit
    if limit.count >= config.limit then
        local remaining = config.window - (now - limit.lastReset)
        return false, remaining
    end

    -- Increment counter
    limit.count = limit.count + 1
    return true
end

---Reset rate limits for player (on reconnect)
---@param source number
local function ResetRateLimits(source)
    RateLimits[source] = nil
end

-- ============================================================================
-- ITEM VALIDATION
-- ============================================================================

---Validate item exists and has valid properties
---@param itemName string
---@param count number
---@param metadata table?
---@return boolean valid
---@return string? error
local function ValidateItem(itemName, count, metadata)
    -- Check item exists
    local item = Items(itemName)
    if not item then
        return false, 'item_not_found'
    end

    -- Check count is valid
    if type(count) ~= 'number' or count <= 0 or count > 1000000 then
        return false, 'invalid_count'
    end

    -- Check count doesn't exceed stack limit
    if item.stack and count > item.stack then
        return false, 'exceeds_stack'
    end

    -- Validate metadata if present
    if metadata then
        if type(metadata) ~= 'table' then
            return false, 'invalid_metadata'
        end

        -- Check durability is within bounds
        if metadata.durability then
            if type(metadata.durability) ~= 'number' or metadata.durability < 0 or metadata.durability > 100 then
                return false, 'invalid_durability'
            end
        end
    end

    return true
end

---Validate inventory weight
---@param inv table Inventory object
---@param addWeight number Weight to add
---@return boolean valid
local function ValidateWeight(inv, addWeight)
    if not inv then return false end
    local newWeight = (inv.weight or 0) + addWeight
    return newWeight <= (inv.maxWeight or 100000)
end

---Validate slot is valid for inventory
---@param inv table Inventory object
---@param slot number Slot number
---@return boolean valid
local function ValidateSlot(inv, slot)
    if not inv then return false end
    if type(slot) ~= 'number' then return false end
    return slot >= 1 and slot <= (inv.slots or 50)
end

-- ============================================================================
-- SUSPICIOUS ACTIVITY LOGGING
-- ============================================================================

-- Suspicious activity counters
local SuspiciousActivity = {}

---Log suspicious activity
---@param source number
---@param activityType string
---@param details string
local function LogSuspicious(source, activityType, details)
    local playerName = GetPlayerName(source) or 'Unknown'
    local identifier = GetPlayerIdentifierByType(source, 'license') or 'unknown'

    -- Track activity count
    if not SuspiciousActivity[source] then
        SuspiciousActivity[source] = { count = 0, activities = {} }
    end

    SuspiciousActivity[source].count = SuspiciousActivity[source].count + 1
    table.insert(SuspiciousActivity[source].activities, {
        type = activityType,
        details = details,
        time = os.time()
    })

    -- Log to console

    -- Auto-kick if too many suspicious activities
    if SuspiciousActivity[source].count >= 10 then
        DropPlayer(source, 'Kicked for suspicious inventory activity')
    end
end

---Get suspicious activity count for player
---@param source number
---@return number
local function GetSuspiciousCount(source)
    if not SuspiciousActivity[source] then return 0 end
    return SuspiciousActivity[source].count
end

-- ============================================================================
-- TRANSACTION VALIDATION
-- ============================================================================

---Validate an inventory transaction
---@param source number
---@param action string Transaction type
---@param fromInv table? Source inventory
---@param toInv table? Target inventory
---@param itemName string
---@param count number
---@return boolean valid
---@return string? error
local function ValidateTransaction(source, action, fromInv, toInv, itemName, count)
    -- Rate limit check
    local allowed, remaining = CheckRateLimit(source, action)
    if not allowed then
        return false, string.format('rate_limited_%ds', remaining or 0)
    end

    -- Item validation
    local valid, err = ValidateItem(itemName, count, nil)
    if not valid then
        LogSuspicious(source, 'invalid_item', string.format('%s: %s x%d', err, itemName, count))
        return false, err
    end

    -- Source inventory check
    if fromInv then
        local hasItem = Inventory.GetItemCount(fromInv, itemName) >= count
        if not hasItem then
            LogSuspicious(source, 'insufficient_items', string.format('%s x%d', itemName, count))
            return false, 'insufficient_items'
        end
    end

    -- Target inventory weight check
    if toInv then
        local item = Items(itemName)
        local addWeight = (item.weight or 0) * count
        if not ValidateWeight(toInv, addWeight) then
            return false, 'exceeds_weight'
        end
    end

    return true
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

-- Clean up on player drop
AddEventHandler('playerDropped', function()
    local source = source
    ResetRateLimits(source)
    SuspiciousActivity[source] = nil
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

local AntiCheat = {
    CheckRateLimit = CheckRateLimit,
    ResetRateLimits = ResetRateLimits,
    ValidateItem = ValidateItem,
    ValidateWeight = ValidateWeight,
    ValidateSlot = ValidateSlot,
    ValidateTransaction = ValidateTransaction,
    LogSuspicious = LogSuspicious,
    GetSuspiciousCount = GetSuspiciousCount,
}

exports('GetAntiCheat', function() return AntiCheat end)


return AntiCheat
