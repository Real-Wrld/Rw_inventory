-- Dynamic Loot System
-- Adjusts loot drops based on player level, time of day, and random events

if not lib then return end


-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
    -- Level-based multipliers (higher level = better loot chance)
    levelBonuses = {
        { minLevel = 1,  maxLevel = 5,  rareChance = 1.0, quantityBonus = 0 },
        { minLevel = 6,  maxLevel = 10, rareChance = 1.2, quantityBonus = 0.1 },
        { minLevel = 11, maxLevel = 15, rareChance = 1.5, quantityBonus = 0.2 },
        { minLevel = 16, maxLevel = 20, rareChance = 2.0, quantityBonus = 0.3 },
        { minLevel = 21, maxLevel = 25, rareChance = 2.5, quantityBonus = 0.4 },
        { minLevel = 26, maxLevel = 30, rareChance = 3.0, quantityBonus = 0.5 },
    },

    -- Time of day modifiers (server time in hours 0-23)
    timeModifiers = {
        -- Night time (better for theft/scavenging)
        { startHour = 22, endHour = 4, rareChance = 1.5, label = 'Night Owl' },
        -- Early morning (quiet time)
        { startHour = 5,  endHour = 7, rareChance = 1.2, label = 'Early Bird' },
        -- Default daytime
        default = { rareChance = 1.0, label = 'Normal' },
    },

    -- Random events (chance per search/theft)
    events = {
        {
            name = 'jackpot',
            chance = 0.5, -- 0.5% chance
            quantityMultiplier = 3,
            rareChanceBonus = 5.0,
            message = '🎰 JACKPOT! You found a hidden stash!',
        },
        {
            name = 'double_drop',
            chance = 5, -- 5% chance
            quantityMultiplier = 2,
            rareChanceBonus = 1.0,
            message = '✨ Double Drop! Lucky find!',
        },
        {
            name = 'nothing_extra',
            chance = 10, -- 10% chance to find extra nothing (bad luck)
            quantityMultiplier = 0.5,
            rareChanceBonus = 0.5,
            message = 'Slim pickings today...',
        },
    },

    -- Debug mode
    debug = false,
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function DebugLog(msg)
    if CONFIG.debug then
    end
end

---Get player crafting level from blueprints module
---@param source number
---@return number level
local function GetPlayerLevel(source)
    -- Try to get from blueprints module
    local ok, result = pcall(function()
        local BlueprintSystem = lib.load('modules.crafting.blueprints')
        if BlueprintSystem and BlueprintSystem.GetPlayerCraftingData then
            local data = BlueprintSystem.GetPlayerCraftingData(source)
            return data and data.level or 1
        end
        return 1
    end)
    return ok and result or 1
end

---Get level bonus for player
---@param level number
---@return table { rareChance, quantityBonus }
local function GetLevelBonus(level)
    for _, bonus in ipairs(CONFIG.levelBonuses) do
        if level >= bonus.minLevel and level <= bonus.maxLevel then
            return bonus
        end
    end
    return CONFIG.levelBonuses[1]
end

---Get current server hour
---@return number hour (0-23)
local function GetServerHour()
    return tonumber(os.date('%H')) or 12
end

---Get time of day modifier
---@return table { rareChance, label }
local function GetTimeModifier()
    local hour = GetServerHour()

    for _, mod in pairs(CONFIG.timeModifiers) do
        if type(mod) == 'table' and mod.startHour then
            -- Handle overnight ranges (e.g., 22-4)
            if mod.startHour > mod.endHour then
                if hour >= mod.startHour or hour <= mod.endHour then
                    return mod
                end
            elseif hour >= mod.startHour and hour <= mod.endHour then
                return mod
            end
        end
    end

    return CONFIG.timeModifiers.default
end

---Roll for random event
---@return table|nil event or nil
local function RollEvent()
    local roll = math.random() * 100

    local cumulative = 0
    for _, event in ipairs(CONFIG.events) do
        cumulative = cumulative + event.chance
        if roll <= cumulative then
            return event
        end
    end

    return nil
end

-- ============================================================================
-- MAIN API
-- ============================================================================

---Calculate loot modifiers for a player
---@param source number Player source
---@return table modifiers { rareChanceMultiplier, quantityMultiplier, event, levelBonus, timeBonus }
local function CalculateLootModifiers(source)
    local level = GetPlayerLevel(source)
    local levelBonus = GetLevelBonus(level)
    local timeModifier = GetTimeModifier()
    local event = RollEvent()

    -- Base multipliers
    local rareChanceMultiplier = levelBonus.rareChance * timeModifier.rareChance
    local quantityMultiplier = 1 + levelBonus.quantityBonus

    -- Apply event if rolled
    local eventMessage = nil
    if event then
        rareChanceMultiplier = rareChanceMultiplier * event.rareChanceBonus
        quantityMultiplier = quantityMultiplier * event.quantityMultiplier
        eventMessage = event.message
    end

    local result = {
        rareChanceMultiplier = rareChanceMultiplier,
        quantityMultiplier = quantityMultiplier,
        event = event,
        eventMessage = eventMessage,
        playerLevel = level,
        timeLabel = timeModifier.label,
    }

    DebugLog(string.format('Player %d (Lvl %d): Rare x%.2f, Qty x%.2f, Time: %s, Event: %s',
        source, level, rareChanceMultiplier, quantityMultiplier,
        timeModifier.label, event and event.name or 'none'))

    return result
end

---Apply modifiers to a loot count
---@param baseCount number Base item count
---@param modifiers table From CalculateLootModifiers
---@return number adjusted count
local function ApplyQuantityModifier(baseCount, modifiers)
    return math.floor(baseCount * modifiers.quantityMultiplier + 0.5)
end

---Check if rare item should drop (adjusted by modifiers)
---@param baseChance number Base rare chance (0-100)
---@param modifiers table From CalculateLootModifiers
---@return boolean shouldDrop
local function ShouldDropRare(baseChance, modifiers)
    local adjustedChance = baseChance * modifiers.rareChanceMultiplier
    return math.random() * 100 <= adjustedChance
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

local DynamicLoot = {
    CalculateLootModifiers = CalculateLootModifiers,
    ApplyQuantityModifier = ApplyQuantityModifier,
    ShouldDropRare = ShouldDropRare,
    GetPlayerLevel = GetPlayerLevel,
    GetTimeModifier = GetTimeModifier,
    CONFIG = CONFIG,
}

exports('GetDynamicLoot', function() return DynamicLoot end)

-- Callback for client to get their modifiers (for UI display)
lib.callback.register('ox_inventory:getLootModifiers', function(source)
    return CalculateLootModifiers(source)
end)


return DynamicLoot
