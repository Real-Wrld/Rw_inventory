-- Blueprint & Crafting Progression System
-- Manages player blueprints, crafting XP, and levels

if not lib then return end

local MySQL = MySQL
local Blueprints = lib.load('data.blueprints') or {}

-- Crafting Level XP Requirements
local LEVEL_XP = {
    [1] = 0,
    [2] = 100,
    [3] = 250,
    [4] = 500,
    [5] = 800,
    [6] = 1200,
    [7] = 1700,
    [8] = 2300,
    [9] = 3000,
    [10] = 4000,
    [11] = 5200,
    [12] = 6600,
    [13] = 8200,
    [14] = 10000,
    [15] = 12500,
    [16] = 15500,
    [17] = 19000,
    [18] = 23000,
    [19] = 28000,
    [20] = 34000,
    [21] = 41000,
    [22] = 49000,
    [23] = 58000,
    [24] = 68000,
    [25] = 80000,
    [26] = 95000,
    [27] = 112000,
    [28] = 132000,
    [29] = 155000,
    [30] = 180000,
}

-- Tier colors for reference (used in UI)
local TIER_COLORS = {
    basic = '#22c55e',     -- Green
    advanced = '#3b82f6',  -- Blue
    master = '#ef4444',    -- Red
    legendary = '#f59e0b', -- Gold
}

-- Player crafting data cache
local PlayerCraftingData = {}

-- Calculate level from XP
local function GetLevelFromXP(xp)
    local level = 1
    -- Iterate from level 1 to 30 in order (pairs() doesn't guarantee order)
    for lvl = 1, 30 do
        local required = LEVEL_XP[lvl]
        if required and xp >= required then
            level = lvl
        else
            break
        end
    end
    return level
end


-- Get XP required for next level
local function GetXPForNextLevel(level)
    return LEVEL_XP[level + 1] or LEVEL_XP[30]
end

-- Initialize player crafting data
local function InitializePlayerData(source)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    if not identifier then return nil end

    -- Check if we have cached data
    if PlayerCraftingData[source] then
        return PlayerCraftingData[source]
    end

    -- Try to load from database
    local result = MySQL.single.await(
        'SELECT crafting_xp, learned_blueprints FROM ox_inventory_crafting WHERE identifier = ?', { identifier })

    if result then
        local learnedBlueprints = json.decode(result.learned_blueprints) or {}
        PlayerCraftingData[source] = {
            identifier = identifier,
            xp = result.crafting_xp or 0,
            level = GetLevelFromXP(result.crafting_xp or 0),
            learnedRecipes = learnedBlueprints,
        }
    else
        -- Create new entry
        PlayerCraftingData[source] = {
            identifier = identifier,
            xp = 0,
            level = 1,
            learnedRecipes = {},
        }
        MySQL.insert.await(
            'INSERT INTO ox_inventory_crafting (identifier, crafting_xp, learned_blueprints) VALUES (?, 0, ?)',
            { identifier, '[]' })
    end

    return PlayerCraftingData[source]
end

-- Save player data to database
local function SavePlayerData(source)
    local data = PlayerCraftingData[source]
    if not data then return end

    MySQL.update('UPDATE ox_inventory_crafting SET crafting_xp = ?, learned_blueprints = ? WHERE identifier = ?', {
        data.xp,
        json.encode(data.learnedRecipes),
        data.identifier
    })
end

-- Get player crafting data
local function GetPlayerCraftingData(source)
    return InitializePlayerData(source)
end

-- Check if player has learned a specific recipe
local function HasLearnedRecipe(source, recipeName)
    local data = GetPlayerCraftingData(source)
    if not data then return false end

    for _, recipe in ipairs(data.learnedRecipes) do
        if recipe == recipeName then
            return true
        end
    end
    return false
end

-- Learn a blueprint
local function LearnBlueprint(source, blueprintItemName)
    local blueprint = Blueprints[blueprintItemName]
    if not blueprint then
        return false, 'invalid_blueprint'
    end

    local data = GetPlayerCraftingData(source)
    if not data then
        return false, 'no_player_data'
    end

    -- Check if already learned
    if HasLearnedRecipe(source, blueprint.recipe) then
        return false, 'already_learned'
    end

    -- Check level requirement
    if data.level < blueprint.requiredLevel then
        return false, 'level_too_low'
    end

    -- Learn the recipe
    table.insert(data.learnedRecipes, blueprint.recipe)
    SavePlayerData(source)

    -- Notify client with full data
    TriggerClientEvent('ox_inventory:blueprintLearned', source, {
        recipe = blueprint.recipe,
        tier = blueprint.tier or 'basic',
        label = blueprint.label or blueprint.recipe,
    })

    return true
end

-- Calculate XP Multiplier
local function GetXPMultiplier(source)
    local multiplier = 1.0

    -- Global Multiplier (TODO: Move to config)
    multiplier = multiplier * 1.0

    -- TODO: Add buff check here (e.g., 'intelligence_potion')
    -- local buffs = exports.ox_inventory:GetPlayerBuffs(source)
    -- if buffs and buffs.crafting_xp then multiplier = multiplier * buffs.crafting_xp end

    return multiplier
end

-- Add crafting XP
local function AddCraftingXP(source, amount)
    local data = GetPlayerCraftingData(source)
    if not data then
        return
    end

    local multiplier = GetXPMultiplier(source)
    local finalAmount = math.floor(amount * multiplier)

    local oldLevel = data.level
    data.xp = data.xp + finalAmount
    data.level = GetLevelFromXP(data.xp)


    -- Check for level up
    if data.level > oldLevel then
        TriggerClientEvent('ox_inventory:craftingLevelUp', source, {
            oldLevel = oldLevel,
            newLevel = data.level,
            totalXP = data.xp
        })
    end

    -- Compute relative XP values for progress bar
    local currentLevelBaseXP = LEVEL_XP[data.level] or 0
    local nextLevelTotalXP = GetXPForNextLevel(data.level)
    local xpProgress = data.xp - currentLevelBaseXP
    local xpRequiredForLevel = nextLevelTotalXP - currentLevelBaseXP

    TriggerClientEvent('ox_inventory:craftingXPGain', source, {
        amount = finalAmount,
        baseAmount = amount,
        multiplier = multiplier,
        totalXP = data.xp,
        level = data.level,
        xpForNextLevel = nextLevelTotalXP,
        relativeXP = xpProgress,
        relativeNextLevelXP = xpRequiredForLevel,
    })

    SavePlayerData(source)
end

-- Check if player can craft a recipe
local function CanCraftRecipe(source, recipe)
    local data = GetPlayerCraftingData(source)
    if not data then return false, 'no_player_data' end

    -- Check for entry-level items first (requiredLevel = 0 AND tier = 'basic')
    -- These can be crafted without learning a blueprint
    local isEntryLevel = recipe.requiredLevel == 0 and recipe.tier == 'basic'

    if isEntryLevel then
        return true
    end

    -- Verify player has learned this recipe
    if not HasLearnedRecipe(source, recipe.name) then
        return false, 'recipe_not_learned'
    end

    -- Check tier level requirements
    local tierLevels = {
        basic = 0,
        advanced = 5,
        master = 15,
        legendary = 25,
    }

    local requiredLevel = recipe.requiredLevel or tierLevels[recipe.tier] or 0
    if data.level < requiredLevel then
        return false, 'level_too_low'
    end

    return true
end

-- Clean up on player drop
AddEventHandler('playerDropped', function()
    local source = source
    if PlayerCraftingData[source] then
        SavePlayerData(source)
        PlayerCraftingData[source] = nil
    end
end)

-- Exports
exports('GetPlayerCraftingData', GetPlayerCraftingData)
exports('HasLearnedRecipe', HasLearnedRecipe)
exports('LearnBlueprint', LearnBlueprint)
exports('AddCraftingXP', AddCraftingXP)
exports('CanCraftRecipe', CanCraftRecipe)
exports('GetLevelFromXP', GetLevelFromXP)
exports('GetXPForNextLevel', GetXPForNextLevel)

-- Callbacks for client
lib.callback.register('ox_inventory:getCraftingData', function(source)
    local data = GetPlayerCraftingData(source)
    if not data then return nil end

    -- Calculate relative XP for progress bar
    local currentLevelBaseXP = LEVEL_XP[data.level] or 0
    local nextLevelTotalXP = GetXPForNextLevel(data.level)

    local xpProgress = data.xp - currentLevelBaseXP
    local xpRequiredForLevel = nextLevelTotalXP - currentLevelBaseXP

    return {
        xp = data.xp, -- Total XP (keep for backend)
        level = data.level,
        learnedRecipes = data.learnedRecipes,
        xpForNextLevel = nextLevelTotalXP, -- Total XP needed for next level

        -- New relative values for UI
        relativeXP = xpProgress,
        relativeNextLevelXP = xpRequiredForLevel,

        tierColors = TIER_COLORS,
    }
end)

lib.callback.register('ox_inventory:learnBlueprint', function(source, blueprintItemName)
    return LearnBlueprint(source, blueprintItemName)
end)

-- Handle blueprint item usage
-- This is triggered when player uses a blueprint item
RegisterNetEvent('ox_inventory:useBlueprint', function(blueprintItemName, slot)
    local source = source
    local success, reason = LearnBlueprint(source, blueprintItemName)

    if success then
        -- Remove the blueprint item from inventory
        exports.ox_inventory:RemoveItem(source, blueprintItemName, 1, nil, slot)

        local blueprint = Blueprints[blueprintItemName]
        lib.notify(source, {
            title = '📘 Blueprint Learned!',
            description = ('You learned: %s'):format(blueprint and blueprint.label or blueprintItemName),
            type = 'success',
            duration = 5000
        })
    else
        local messages = {
            already_learned = 'You already know this recipe!',
            level_too_low = 'Your crafting level is too low',
            invalid_blueprint = 'Invalid blueprint',
            no_player_data = 'Unable to save progress',
        }

        lib.notify(source, {
            title = 'Cannot Learn',
            description = messages[reason] or 'Failed to learn blueprint',
            type = 'error',
            duration = 3000
        })
    end
end)

-- ==========================================
-- Use ox_inventory's hook system to intercept blueprint usage
-- This is more reliable than framework-based registration
-- ==========================================

-- Build item filter from Blueprints table
local blueprintItemFilter = {}
local blueprintCount = 0
for itemName in pairs(Blueprints) do
    blueprintItemFilter[itemName] = true
    blueprintCount = blueprintCount + 1
end

---Handle blueprint item usage via ox_inventory hook
---@param payload { source: number, inventoryId: number, item: table, consume: number? }
---@return boolean? - false to block item use (e.g. already learned)
local function onBlueprintUse(payload)
    local item = payload.item
    local itemName = item and item.name
    local blueprint = itemName and Blueprints[itemName]

    if not blueprint then
        return -- Not a blueprint item in this hook's filter
    end

    local source = payload.source


    local success, reason = LearnBlueprint(source, itemName)

    if success then
        lib.notify(source, {
            title = '📘 Blueprint Learned!',
            description = ('You learned: %s'):format(blueprint.label or itemName),
            type = 'success',
            duration = 5000
        })


        -- Allow normal item flow to run (progress bar + consume removes the blueprint item)
        return
    end

    local messages = {
        already_learned = 'You already know this recipe!',
        level_too_low = 'Your crafting level is too low',
        invalid_blueprint = 'Invalid blueprint',
        no_player_data = 'Unable to save progress',
    }

    lib.notify(source, {
        title = 'Cannot Learn',
        description = messages[reason] or 'Failed to learn blueprint',
        type = 'error',
        duration = 3000
    })


    return false
end

-- Build the item filter and count for hook registration
local blueprintItemFilter = {}
local blueprintCount = 0
for itemName, _ in pairs(Blueprints) do
    blueprintItemFilter[itemName] = true
    blueprintCount = blueprintCount + 1
end

-- Register the blueprint hook via ox_inventory's hook system
-- This intercepts item usage for all blueprint items and handles learning + removal
if blueprintCount > 0 then
    exports.ox_inventory:registerHook('usingItem', onBlueprintUse, {
        itemFilter = blueprintItemFilter,
    })
end


-- DEBUG: Print loaded blueprints count


return {
    GetPlayerCraftingData = GetPlayerCraftingData,
    HasLearnedRecipe = HasLearnedRecipe,
    LearnBlueprint = LearnBlueprint,
    AddCraftingXP = AddCraftingXP,
    CanCraftRecipe = CanCraftRecipe,
    GetXPForNextLevel = GetXPForNextLevel,
    TIER_COLORS = TIER_COLORS,
    LEVEL_XP = LEVEL_XP,
}
