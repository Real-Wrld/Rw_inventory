if not lib then return end

RWAppearance = {}
local equippedAccessories = {}
local lockedSlots = {}
local currentOutfit = nil
local originalAppearance = nil

local clothingMap = {
    mask = 1,
    arms = 3,
    legs = 4,
    bag = 5,
    shoes = 6,
    necklace = 7,
    undershirt = 8,
    armor = 9,
    decals = 10,
    torso = 11
}

local propMap = {
    hat = 0,
    glasses = 1,
    ears = 2,
    watch = 6,
    bracelet = 7
}

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

local function copyComponents(components)
    if not components then return nil end
    local copy = {}
    for key, data in pairs(components) do
        copy[key] = {
            drawable = data.drawable,
            texture = data.texture or 0,
        }
    end
    return copy
end

local function resolveClientComponents(itemName, itemMeta)
    if itemMeta and itemMeta.components then
        return copyComponents(itemMeta.components)
    end

    if RWClothingPresets and RWClothingPresets[itemName] then
        return copyComponents(RWClothingPresets[itemName])
    end

    local category = itemMeta and itemMeta.category
    if not category then
        local itemsConfig = exports.ox_inventory:Items()
        local def = itemsConfig and itemsConfig[itemName]
        category = def and (def.category or (def.client and def.client.category))
    end

    local componentName = category and CATEGORY_TO_COMPONENT[category]
    if not componentName then return nil end

    if category == 'shirt' then
        return {
            torso = { drawable = 15, texture = 0 },
            undershirt = { drawable = 15, texture = 0 },
            arms = { drawable = 15, texture = 0 },
        }
    end

    return {
        [componentName] = { drawable = 1, texture = 0 },
    }
end

local function resolveAnimKey(itemName, itemMeta)
    if RWClothingData and RWClothingData.animations and RWClothingData.animations[itemName] then
        return itemName
    end

    local components = resolveClientComponents(itemName, itemMeta)
    if components then
        for compName in pairs(components) do
            if RWClothingData and RWClothingData.animations and RWClothingData.animations[compName] then
                return compName
            end
        end
    end

    local category = itemMeta and itemMeta.category
    if category and CATEGORY_TO_COMPONENT[category] then
        return CATEGORY_TO_COMPONENT[category]
    end

    return 'torso'
end

local function unequipConflictsBeforeEquip(components)
    if not components then return end

    local conflicts = {}
    for compName in pairs(components) do
        for _, eq in ipairs(equippedAccessories) do
            if eq.metadata and eq.metadata.components and eq.metadata.components[compName] then
                conflicts[#conflicts + 1] = eq
                break
            end
        end
    end

    for i = 1, #conflicts do
        local eq = conflicts[i]
        local done = false
        RWAppearance.HandleUnequipClothing({
            name = eq.name,
            itemName = eq.name,
            componentKey = next(eq.metadata.components),
        }, function() end)
    end
end

function RWAppearance.Apply(components)
    if not components then return end
    for name, data in pairs(components) do
        local isClothing = clothingMap[name]
        local isProp = propMap[name]
        if isProp then
            exports.ox_inventory:SetPedProp(nil, isProp, data.drawable, data.texture)
        elseif isClothing then
            exports.ox_inventory:SetPedComponent(nil, isClothing, data.drawable, data.texture)
        end
    end
end

function RWAppearance.Remove(components)
    if not components then return end
    for name in pairs(components) do
        local isProp = propMap[name]
        local isClothing = clothingMap[name]
        if isProp then
            exports.ox_inventory:SetPedProp(nil, isProp, -1, 0)
        elseif isClothing then
            if originalAppearance and originalAppearance.components and originalAppearance.components[isClothing] then
                local compData = originalAppearance.components[isClothing]
                exports.ox_inventory:SetPedComponent(nil, isClothing, compData.drawable, compData.texture)
            else
                exports.ox_inventory:SetPedComponent(nil, isClothing, 0, 0)
            end
        end
    end
end

function RWAppearance.RestoreAll()
    originalAppearance = exports.ox_inventory:GetPedAppearance()
    for _, item in ipairs(equippedAccessories) do
        if item.metadata and item.metadata.components then
            RWAppearance.Apply(item.metadata.components)
        end
    end
    if currentOutfit and currentOutfit.metadata and currentOutfit.metadata.components then
        local hiddenSlots = currentOutfit.hiddenSlots or {}
        for name, comp in pairs(currentOutfit.metadata.components) do
            if not hiddenSlots[name] then
                RWAppearance.Apply({[name] = comp})
            end
        end
    end
end

function RWAppearance.IsLocked(slot)
    return lockedSlots[slot] == true
end

function RWAppearance.GetEquipped()
    return equippedAccessories
end

function RWAppearance.GetLockedSlots()
    return lockedSlots
end

function RWAppearance.AddEquipped(item)
    if item.metadata and item.metadata.components then
        for name in pairs(item.metadata.components) do
            for i = #equippedAccessories, 1, -1 do
                local eqItem = equippedAccessories[i]
                if eqItem.metadata and eqItem.metadata.components and eqItem.metadata.components[name] then
                    table.remove(equippedAccessories, i)
                    break
                end
            end
        end
    end
    equippedAccessories[#equippedAccessories + 1] = item
end

function RWAppearance.RemoveEquipped(itemName)
    for i = #equippedAccessories, 1, -1 do
        if equippedAccessories[i].name == itemName then
            table.remove(equippedAccessories, i)
            return
        end
    end
end

function RWAppearance.SetCurrentOutfit(outfit)
    currentOutfit = outfit
end

function RWAppearance.SetLockedSlots(slots)
    lockedSlots = {}
    if slots then
        for _, slot in ipairs(slots) do
            lockedSlots[slot] = true
        end
    end
    exports.ox_inventory:sendNuiMessage({
        action = "updateLockedSlots",
        data = lockedSlots
    })
end

local function playClothingAnim(animType)
    local animConfig = RWClothingData and RWClothingData.animations and RWClothingData.animations[animType]
    if not animConfig then return true end
    
    lib.requestAnimDict(animConfig.dict)
    
    local label = locale("equipping_" .. animType) or locale("equipping") or "Equipping..."
    
    local success = lib.progressBar({
        duration = animConfig.duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = { combat = true, move = true },
        anim = { dict = animConfig.dict, clip = animConfig.name, flag = animConfig.flags }
    })
    
    RemoveAnimDict(animConfig.dict)
    return success
end

local function playOutfitRemoveAnim(cb)
    if currentOutfit then
        local animConfig = RWClothingData and RWClothingData.animations and RWClothingData.animations.outfit
        if animConfig then
            lib.requestAnimDict(animConfig.dict)
            
            local label = locale("unequipping_outfit") or "Removing outfit..."
            
            local success = lib.progressBar({
                duration = animConfig.duration,
                label = label,
                useWhileDead = false,
                canCancel = true,
                disable = { combat = true, move = true },
                anim = { dict = animConfig.dict, clip = animConfig.name, flag = animConfig.flags }
            })
            
            RemoveAnimDict(animConfig.dict)
            if not success then return cb(false) end
        end
        
        local response = lib.callback.await("rw_inventory:unequipOutfit", false)
        if response then
            local gender = exports.ox_inventory:GetPedModel() == 1885233650 and "m" or "f"
            local defaults = RWClothingDefaults and RWClothingDefaults[gender]
            
            if response.componentsToReset then
                for _, name in ipairs(response.componentsToReset) do
                    local defData = defaults and defaults[name]
                    if defData then
                        local isProp = propMap[name]
                        local isClothing = clothingMap[name]
                        if isProp then
                            exports.ox_inventory:SetPedProp(nil, isProp, defData.drawable, defData.texture)
                        elseif isClothing then
                            exports.ox_inventory:SetPedComponent(nil, isClothing, defData.drawable, defData.texture)
                        end
                    else
                        RWAppearance.Remove({[name] = true})
                    end
                end
            end
            
            currentOutfit = nil
            lockedSlots = {}
            
            exports.ox_inventory:sendNuiMessage({
                action = "outfitUnequipped",
                data = { componentsToReset = response.componentsToReset }
            })
            
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end
end

function RWAppearance.HandleToggleClothingVisibility(data, cb)
    local slotKey = data.slotKey
    local hidden = data.hidden
    
    if not slotKey then return cb(false) end
    
    local animConfig = RWClothingData and RWClothingData.animations and RWClothingData.animations[slotKey]
    if animConfig then
        lib.requestAnimDict(animConfig.dict)
        local duration = math.floor(animConfig.duration * 0.6)
        
        local label
        if hidden then
            label = locale("hiding_" .. slotKey) or locale("hiding_clothing") or "Hiding..."
        else
            label = locale("showing_" .. slotKey) or locale("showing_clothing") or "Showing..."
        end
        
        local success = lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = { combat = true, move = true },
            anim = { dict = animConfig.dict, clip = animConfig.name, flag = animConfig.flags }
        })
        
        RemoveAnimDict(animConfig.dict)
        if not success then return cb(false) end
    end
    
    if hidden then
        local gender = exports.ox_inventory:GetPedModel() == 1885233650 and "m" or "f"
        local defaults = RWClothingDefaults and RWClothingDefaults[gender]
        local defData = defaults and defaults[slotKey]
        
        if defData then
            local isProp = propMap[slotKey]
            local isClothing = clothingMap[slotKey]
            if isProp then
                exports.ox_inventory:SetPedProp(nil, isProp, defData.drawable, defData.texture)
            elseif isClothing then
                exports.ox_inventory:SetPedComponent(nil, isClothing, defData.drawable, defData.texture)
            end
        else
            RWAppearance.Remove({[slotKey] = true})
        end
    else
        if currentOutfit and currentOutfit.metadata and currentOutfit.metadata.components and currentOutfit.metadata.components[slotKey] then
            RWAppearance.Apply({[slotKey] = currentOutfit.metadata.components[slotKey]})
        end
    end
    
    if currentOutfit then
        currentOutfit.hiddenSlots = currentOutfit.hiddenSlots or {}
        currentOutfit.hiddenSlots[slotKey] = hidden or nil
    end
    
    lib.callback.await("rw_inventory:toggleClothingVisibility", false, slotKey, hidden)
    cb(true)
end

function RWAppearance.HandleUnequipClothing(data, cb)
    local componentKey = data.componentKey or data.name
    local itemName = data.itemName or data.name
    if not componentKey then return cb(false) end

    if componentKey == 'outfit' or data.name == 'outfit' then
        if currentOutfit then
            return playOutfitRemoveAnim(cb)
        end
    end

    for _, item in ipairs(equippedAccessories) do
        if item.name == itemName or item.name == data.name then
            if item.metadata and item.metadata.components then
                for compName in pairs(item.metadata.components) do
                    if lockedSlots[compName] then
                        lib.notify({
                            type = 'error',
                            description = locale('slot_locked')
                        })
                        return cb(false)
                    end
                end
            end
        end
    end

    local animKey = componentKey
    local animConfig = RWClothingData and RWClothingData.animations and RWClothingData.animations[animKey]
    if animConfig then
        lib.requestAnimDict(animConfig.dict)
        
        local label = locale('unequipping_' .. animKey) or locale('unequipping') or 'Removing...'
        
        local success = lib.progressBar({
            duration = animConfig.duration,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = { combat = true, move = true },
            anim = { dict = animConfig.dict, clip = animConfig.name, flag = animConfig.flags }
        })
        
        RemoveAnimDict(animConfig.dict)
        if not success then return cb(false) end
    end
    
    local currentComponents = {}
    local foundInEquipped = false
    for _, item in ipairs(equippedAccessories) do
        if item.name == itemName or item.name == data.name then
            foundInEquipped = true
            if item.metadata and item.metadata.components then
                currentComponents = copyComponents(item.metadata.components)
            end
            break
        end
    end

    local needsPedFallback = not foundInEquipped or next(currentComponents) == nil

    if needsPedFallback then
        local isClothing = clothingMap[componentKey]
        local isProp = propMap[componentKey]
        local ped = PlayerPedId()

        if componentKey == 'torso' or componentKey == 'shirt' then
            currentComponents.torso = { drawable = GetPedDrawableVariation(ped, 11), texture = GetPedTextureVariation(ped, 11) }
            currentComponents.undershirt = { drawable = GetPedDrawableVariation(ped, 8), texture = GetPedTextureVariation(ped, 8) }
            currentComponents.arms = { drawable = GetPedDrawableVariation(ped, 3), texture = GetPedTextureVariation(ped, 3) }
        elseif isClothing then
            currentComponents[componentKey] = {
                drawable = GetPedDrawableVariation(ped, isClothing),
                texture = GetPedTextureVariation(ped, isClothing),
            }
        elseif isProp then
            local drawable = GetPedPropIndex(ped, isProp)
            local texture = GetPedPropTextureIndex(ped, isProp)
            if drawable ~= -1 then
                currentComponents[componentKey] = { drawable = drawable, texture = texture }
            end
        end
    end

    local response = lib.callback.await('rw_inventory:unequipClothing', false, componentKey, data.targetSlot, currentComponents, itemName)
    if response then
        if response.components then
            local gender = exports.ox_inventory:GetPedModel() == 1885233650 and "m" or "f"
            local defaults = RWClothingDefaults and RWClothingDefaults[gender]

            for compName in pairs(response.components) do
                local defData = defaults and defaults[compName]
                if defData then
                    local isProp = propMap[compName]
                    local isClothing = clothingMap[compName]
                    if isProp then
                        exports.ox_inventory:SetPedProp(nil, isProp, defData.drawable, defData.texture)
                    elseif isClothing then
                        exports.ox_inventory:SetPedComponent(nil, isClothing, defData.drawable, defData.texture)
                    end
                else
                    RWAppearance.Remove({[compName] = true})
                end
            end

            RWAppearance.RemoveEquipped(itemName)

            exports.ox_inventory:sendNuiMessage({
                action = 'clothingUnequipped',
                data = { name = itemName }
            })

            if exports.ox_inventory:GetAppearanceSystem() then
                exports.ox_inventory:SaveAppearance()
            end

            cb(true)
        else
            
            cb(false)
        end
    else
        cb(false)
    end
end

function RWAppearance.HandleUnequipOutfit(data, cb)
    playOutfitRemoveAnim(cb)
end

function RWAppearance.EquipClothingItem(item, slotData)
    local itemName = (slotData and slotData.name) or item.name
    local itemSlot = (slotData and slotData.slot) or item.slot
    local itemMeta = (slotData and slotData.metadata) or item.metadata

    local pendingComponents = resolveClientComponents(itemName, itemMeta)
    unequipConflictsBeforeEquip(pendingComponents)

    if not playClothingAnim(resolveAnimKey(itemName, itemMeta)) then
        return
    end

    local response = lib.callback.await('rw_inventory:equipClothing', false, itemSlot)

    if response then
        if response.replaced then
            for _, replacedItem in ipairs(response.replaced) do
                RWAppearance.RemoveEquipped(replacedItem.name)
                exports.ox_inventory:sendNuiMessage({
                    action = 'clothingUnequipped',
                    data = { name = replacedItem.name }
                })
            end
        end

        RWAppearance.Apply(response.components)

        RWAppearance.AddEquipped({
            name = itemName,
            label = response.label or (itemMeta and itemMeta.label) or itemName,
            metadata = {
                category = itemMeta and itemMeta.category,
                label = response.label or (itemMeta and itemMeta.label) or itemName,
                components = copyComponents(response.components),
            },
        })

        exports.ox_inventory:SaveAppearance()

        exports.ox_inventory:sendNuiMessage({
            action = 'clothingEquipped',
            data = { name = itemName }
        })
        exports.ox_inventory:sendNuiMessage({
            action = 'updateEquipment'
        })
    end
end

function RWAppearance.EquipOutfitItem(item)
    if not playClothingAnim("outfit") then return end
    
    local response = lib.callback.await("rw_inventory:equipOutfit", false, item.slot)
    if response then
        RWAppearance.Apply(response.components)
        
        RWAppearance.SetCurrentOutfit({
            name = item.metadata and item.metadata.label or item.name,
            metadata = item.metadata
        })
        
        RWAppearance.SetLockedSlots(response.lockedSlots)
        
        local equippedSlots = {}
        equippedSlots.outfit = {
            name = "outfit",
            label = item.metadata and item.metadata.label or item.name
        }
        
        local itemsConfig = exports.ox_inventory:Items()
        for compName in pairs(response.components) do
            local configItem = itemsConfig and itemsConfig[compName]
            equippedSlots[compName] = {
                name = compName,
                label = configItem and configItem.label or compName
            }
        end
        
        exports.ox_inventory:SaveAppearance()

        exports.ox_inventory:SaveAppearance()

        exports.ox_inventory:sendNuiMessage({
            action = 'outfitEquipped',
            data = {
                outfit = {
                    name = item.name,
                    label = item.metadata and item.metadata.label or item.name
                },
                equippedSlots = equippedSlots,
                lockedSlots = response.lockedSlots
            }
        })
    end
end

RegisterNetEvent("rw_inventory:loadAccessories", function(accessories, outfit)
    equippedAccessories = accessories or {}
    if outfit then
        currentOutfit = {
            name = outfit.name,
            metadata = outfit.metadata,
            hiddenSlots = outfit.hiddenSlots or {}
        }
        
        lockedSlots = {}
        if outfit.lockedSlots then
            for _, slot in pairs(outfit.lockedSlots) do
                lockedSlots[slot] = true
            end
        end
    else
        currentOutfit = nil
        lockedSlots = {}
    end
    
    RWAppearance.RestoreAll()
end)

RegisterNetEvent("rw_inventory:updateLockedSlots", function(slots)
    lockedSlots = {}
    if slots then
        for _, slot in ipairs(slots) do
            lockedSlots[slot] = true
        end
    end
    exports.ox_inventory:sendNuiMessage({
        action = "updateLockedSlots",
        data = lockedSlots
    })
end)

function RWAppearance.GetEquippedForNUI()
    local equippedItems = {}
    local ped = PlayerPedId()
    local gender = exports.ox_inventory:GetPedModel() == 1885233650 and "m" or "f"
    local defaults = RWClothingDefaults and RWClothingDefaults[gender] or {}
    local itemsConfig = exports.ox_inventory:Items()

    for compName, compId in pairs(clothingMap) do
        local drawable = GetPedDrawableVariation(ped, compId)
        local defData = defaults[compName]
        local isDefault = (defData and defData.drawable == drawable) or (not defData and drawable == 0)
        
        if not isDefault then
            local configItem = itemsConfig and itemsConfig[compName]
            equippedItems[compName] = {
                name = compName,
                label = configItem and configItem.label or compName
            }
        end
    end
    
    for compName, compId in pairs(propMap) do
        local drawable = GetPedPropIndex(ped, compId)
        local defData = defaults[compName]
        local isDefault = (defData and defData.drawable == drawable) or (not defData and drawable == -1)
        
        if not isDefault then
            local configItem = itemsConfig and itemsConfig[compName]
            equippedItems[compName] = {
                name = compName,
                label = configItem and configItem.label or compName
            }
        end
    end

    for _, item in ipairs(equippedAccessories) do
        if item.metadata and item.metadata.components then
            for compName in pairs(item.metadata.components) do
                equippedItems[compName] = {
                    name = item.name,
                    label = item.label or (item.metadata and item.metadata.label)
                }
            end
        end
    end
    
    local hiddenSlots = {}
    if currentOutfit and currentOutfit.metadata and currentOutfit.metadata.components then
        equippedItems.outfit = {
            name = "outfit",
            label = currentOutfit.name
        }
        
        local itemsConfig = exports.ox_inventory:Items()
        for compName in pairs(currentOutfit.metadata.components) do
            local configItem = itemsConfig and itemsConfig[compName]
            equippedItems[compName] = {
                name = compName,
                label = configItem and configItem.label or compName
            }
        end
        
        if currentOutfit.hiddenSlots then
            for slot, hidden in pairs(currentOutfit.hiddenSlots) do
                if hidden then
                    hiddenSlots[slot] = true
                end
            end
        end
    end
    
    return {
        equippedItems = equippedItems,
        lockedSlots = lockedSlots,
        hiddenSlots = hiddenSlots,
        outfit = currentOutfit
    }
end

exports("isClothingSlotLocked", function(...) return RWAppearance.IsLocked(...) end)
exports("getEquippedAccessories", function(...) return RWAppearance.GetEquipped(...) end)
exports("getLockedClothingSlots", function(...) return RWAppearance.GetLockedSlots(...) end)
exports("applyAppearance", function(...) return RWAppearance.Apply(...) end)
exports("removeAppearance", function(...) return RWAppearance.Remove(...) end)
exports("restoreAppearance", function(...) return RWAppearance.RestoreAll(...) end)
exports("addEquippedAccessory", function(...) return RWAppearance.AddEquipped(...) end)
exports("removeEquippedAccessory", function(...) return RWAppearance.RemoveEquipped(...) end)
exports("setCurrentOutfit", function(...) return RWAppearance.SetCurrentOutfit(...) end)
exports("setLockedSlots", function(...) return RWAppearance.SetLockedSlots(...) end)
exports("getEquippedForNUI", function(...) return RWAppearance.GetEquippedForNUI(...) end)
exports("handleToggleClothingVisibility", function(...) return RWAppearance.HandleToggleClothingVisibility(...) end)
exports("handleUnequipClothing", function(...) return RWAppearance.HandleUnequipClothing(...) end)
exports("handleUnequipOutfit", function(...) return RWAppearance.HandleUnequipOutfit(...) end)
exports("equipClothingItem", function(...) return RWAppearance.EquipClothingItem(...) end)
exports("equipOutfitItem", function(...) return RWAppearance.EquipOutfitItem(...) end)

