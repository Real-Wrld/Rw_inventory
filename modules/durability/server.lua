-- Item Durability Decay System
-- Tools and weapons degrade with use

if not lib then return end


local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
    -- Durability decay rates per use
    decayRates = {
        -- Mining/crafting tools
        pickaxe = 2,         -- 2% per use (50 uses before broken)
        steel_pickaxe = 1,   -- 1% per use (100 uses)
        runic_pickaxe = 0.5, -- 0.5% per use (200 uses)

        -- Lockpicks
        lockpick = 25, -- 25% per use (4 uses max)
        advanced_lockpick = 10,
        cobalt_lockpick = 5,
        master_lockpick = 3,

        -- Repair kits (consume on use)
        repairkit = 100, -- Single use

        -- Weapons degrade slowly
        WEAPON_PISTOL = 0.1,
        WEAPON_SMG = 0.08,
        WEAPON_RIFLE = 0.05,

        -- Default for unlisted items
        default = 1,
    },

    -- Minimum durability before item breaks
    breakThreshold = 0,

    -- Items that CAN'T have durability (consumables, etc)
    noDurability = {
        'water', 'burger', 'coffee', 'bandage', 'painkillers',
        'money', 'black_money', 'markedbills',
    },

    -- Enable notifications
    notifyOnLowDurability = true,
    lowDurabilityThreshold = 15, -- Warn when durability below 15%
}

-- ============================================================================
-- DURABILITY FUNCTIONS
-- ============================================================================

---Check if item can have durability
---@param itemName string
---@return boolean
local function CanHaveDurability(itemName)
    -- Check exclusion list
    for _, excluded in ipairs(CONFIG.noDurability) do
        if excluded == itemName then
            return false
        end
    end

    -- Check if item data specifies durability
    local item = Items(itemName)
    if item and item.durability ~= nil then
        return true
    end

    -- Check if it has a decay rate
    if CONFIG.decayRates[itemName] then
        return true
    end

    return false
end

---Get decay rate for item
---@param itemName string
---@return number decay rate (percentage per use)
local function GetDecayRate(itemName)
    return CONFIG.decayRates[itemName] or CONFIG.decayRates.default
end

---Decay item durability
---@param source number Player source
---@param slot number Inventory slot
---@param amount number? Optional override decay amount
---@return boolean success
---@return number? newDurability
---@return boolean? itemBroken
local function DecayItem(source, slot, amount)
    local inv = Inventory(source)
    if not inv then return false end

    local item = inv.items[slot]
    if not item then return false end

    -- Check if item can have durability
    if not CanHaveDurability(item.name) then
        return true -- Success but no durability change
    end

    -- Get current durability (default 100)
    local metadata = item.metadata or {}
    local currentDurability = metadata.durability or 100

    -- Calculate decay
    local decayRate = amount or GetDecayRate(item.name)
    local newDurability = math.max(0, currentDurability - decayRate)

    -- Update metadata
    metadata.durability = newDurability

    -- Check if item should break
    local broken = newDurability <= CONFIG.breakThreshold

    if broken then
        -- Remove the item
        Inventory.RemoveItem(inv, item.name, 1, nil, slot)

        -- Notify player
        lib.notify(source, {
            title = 'Item Broken',
            description = string.format('Your %s has broken!', item.label or item.name),
            type = 'error',
            duration = 4000,
        })

        return true, 0, true
    end

    -- Update the slot with new metadata
    Inventory.SetMetadata(inv, slot, metadata)

    -- Warn on low durability
    if CONFIG.notifyOnLowDurability and newDurability <= CONFIG.lowDurabilityThreshold then
        lib.notify(source, {
            title = 'Low Durability',
            description = string.format('%s: %d%% remaining', item.label or item.name, math.floor(newDurability)),
            type = 'warning',
            duration = 3000,
        })
    end

    return true, newDurability, false
end

---Repair item durability
---@param source number Player source
---@param slot number Inventory slot
---@param repairAmount number Amount to repair (0-100)
---@return boolean success
---@return number? newDurability
local function RepairItem(source, slot, repairAmount)
    local inv = Inventory(source)
    if not inv then return false end

    local item = inv.items[slot]
    if not item then return false end

    if not CanHaveDurability(item.name) then
        return false
    end

    local metadata = item.metadata or {}
    local currentDurability = metadata.durability or 100

    -- Calculate new durability (max 100)
    local newDurability = math.min(100, currentDurability + repairAmount)
    metadata.durability = newDurability

    Inventory.SetMetadata(inv, slot, metadata)

    lib.notify(source, {
        title = 'Item Repaired',
        description = string.format('%s: %d%% → %d%%', item.label or item.name,
            math.floor(currentDurability), math.floor(newDurability)),
        type = 'success',
        duration = 3000,
    })

    return true, newDurability
end

---Get item durability
---@param source number Player source
---@param slot number Inventory slot
---@return number? durability (nil if item doesn't have durability)
local function GetDurability(source, slot)
    local inv = Inventory(source)
    if not inv then return nil end

    local item = inv.items[slot]
    if not item then return nil end

    if not CanHaveDurability(item.name) then
        return nil
    end

    local metadata = item.metadata or {}
    return metadata.durability or 100
end

-- ============================================================================
-- EVENT HOOKS
-- ============================================================================

-- Hook into item use to decay durability
AddEventHandler('ox_inventory:usedItem', function(source, itemName, slot, metadata)
    -- Only decay certain item types on use
    if CONFIG.decayRates[itemName] then
        DecayItem(source, slot)
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

local Durability = {
    DecayItem = DecayItem,
    RepairItem = RepairItem,
    GetDurability = GetDurability,
    CanHaveDurability = CanHaveDurability,
    GetDecayRate = GetDecayRate,
    CONFIG = CONFIG,
}

exports('GetDurabilitySystem', function() return Durability end)

-- Register callback for client to check durability
lib.callback.register('ox_inventory:getDurability', function(source, slot)
    return GetDurability(source, slot)
end)

-- Register callback for repair
lib.callback.register('ox_inventory:repairItem', function(source, slot, repairKitSlot)
    local inv = Inventory(source)
    if not inv then return false end

    -- Check if player has repair kit
    local repairKit = inv.items[repairKitSlot]
    if not repairKit or repairKit.name ~= 'repairkit' then
        return false, 'no_repair_kit'
    end

    -- Consume repair kit
    local removed = Inventory.RemoveItem(inv, 'repairkit', 1, nil, repairKitSlot)
    if not removed then
        return false, 'remove_failed'
    end

    -- Repair the item (50% repair)
    local success, newDurability = RepairItem(source, slot, 50)
    return success, newDurability
end)


return Durability
