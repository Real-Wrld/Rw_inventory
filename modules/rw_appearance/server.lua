if not lib then return end

local CATEGORY_TO_COMPONENT = {
    hat = 'hat',
    mask = 'mask',
    glasses = 'glasses',
    shirt = 'torso',
    pants = 'legs',
    shoes = 'shoes',
    vest = 'armor',
    bag = 'bag',
    chain = 'necklace',
    gloves = 'arms',
    accessories = 'decals',
}

local COMPONENT_TO_CATEGORY = {}
for category, component in pairs(CATEGORY_TO_COMPONENT) do
    COMPONENT_TO_CATEGORY[component] = category
end

local function Items()
    return exports.ox_inventory:Items()
end

local function deepCopyComponents(components)
    local copy = {}
    for key, data in pairs(components) do
        copy[key] = {
            drawable = data.drawable,
            texture = data.texture or 0,
        }
    end
    return copy
end

local function resolveCategory(item)
    if item.metadata and item.metadata.category then
        return item.metadata.category
    end

    local def = Items()[item.name]
    if not def then return nil end

    return def.category or (def.client and def.client.category)
end

local function resolveComponents(item)
    if item.metadata and item.metadata.components then
        return deepCopyComponents(item.metadata.components)
    end

    local def = Items()[item.name]
    if def and def.components then
        return deepCopyComponents(def.components)
    end

    if RWClothingPresets and RWClothingPresets[item.name] then
        return deepCopyComponents(RWClothingPresets[item.name])
    end

    local category = resolveCategory(item)
    local componentName = category and CATEGORY_TO_COMPONENT[category]
    if not componentName then return nil end

    local drawable = item.metadata and item.metadata.drawable or 1
    local texture = item.metadata and item.metadata.texture or 0

    if category == 'shirt' then
        return {
            torso = { drawable = drawable, texture = texture },
            undershirt = { drawable = 15, texture = 0 },
            arms = { drawable = drawable, texture = texture },
        }
    end

    return {
        [componentName] = {
            drawable = drawable,
            texture = texture,
        },
    }
end

local function resolveReturnItemName(itemName, currentComponents)
    if itemName and Items()[itemName] then
        return itemName
    end

    for compName in pairs(currentComponents) do
        local category = COMPONENT_TO_CATEGORY[compName]
        if category then
            for name, def in pairs(Items()) do
                if name:find('^clothing_') and (def.category == category or (def.client and def.client.category == category)) then
                    return name
                end
            end
        end
    end

    return 'clothing_piece'
end

lib.callback.register('rw_inventory:unequipOutfit', function(source)
    return { componentsToReset = { 'torso', 'undershirt', 'arms', 'legs', 'shoes', 'mask', 'hat', 'glasses', 'bag', 'armor', 'necklace', 'decals' } }
end)

lib.callback.register('rw_inventory:toggleClothingVisibility', function(source, slotKey, hidden)
    return true
end)

lib.callback.register('rw_inventory:unequipClothing', function(source, componentKey, targetSlot, currentComponents, itemName)
    if not currentComponents or next(currentComponents) == nil then
        return false
    end

    local returnName = resolveReturnItemName(itemName or componentKey, currentComponents)
    local def = Items()[returnName]
    local label = def and def.label or ('Custom ' .. tostring(componentKey or 'Clothing'))

    local metadata = {
        components = deepCopyComponents(currentComponents),
        label = label,
        category = def and def.category or (def and def.client and def.client.category),
    }

    local success = exports.ox_inventory:AddItem(source, returnName, 1, metadata, targetSlot)
    if success then
        return { components = currentComponents, itemName = returnName }
    end

    return false
end)

lib.callback.register('rw_inventory:equipClothing', function(source, slot)
    local item = exports.ox_inventory:GetSlot(source, slot)
    local components = item and resolveComponents(item)

    if not item or not components then
        return false
    end

    local success = exports.ox_inventory:RemoveItem(source, item.name, 1, nil, slot)

    if success then
        return {
            components = components,
            itemName = item.name,
            label = item.metadata and item.metadata.label or item.label or item.name,
        }
    end

    return false
end)

lib.callback.register('rw_inventory:equipOutfit', function(source, slot)
    local item = exports.ox_inventory:GetSlot(source, slot)
    if not item then return false end

    local components = item.metadata and item.metadata.components
    if not components and RWClothingPresets then
        components = RWClothingPresets[item.name]
    end

    if not components then
        return false
    end

    local success = exports.ox_inventory:RemoveItem(source, item.name, 1, nil, slot)
    if not success then return false end

    local lockedSlots = item.metadata and item.metadata.lockedSlots or {}
    return {
        components = deepCopyComponents(components),
        lockedSlots = lockedSlots,
    }
end)
