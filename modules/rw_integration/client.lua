if not lib then return end

local CharacterPreview = require 'modules.character.client'

local function rw()
    return exports.ox_inventory
end

local refreshQueued = false

local function refreshCharacterPreview()
    if not LocalPlayer.state.invOpen then return end
    if CharacterPreview.sync then
        CharacterPreview.sync()
        return
    end
    if refreshQueued then return end
    refreshQueued = true
    SetTimeout(80, function()
        refreshQueued = false
        if not LocalPlayer.state.invOpen then return end
        if CharacterPreview.isOpen and CharacterPreview.isOpen() then
            CharacterPreview.sync()
        else
            CharacterPreview.open()
        end
    end)
end

RegisterNetEvent('ox_inventory:equipClothing', function(itemData, slotInfo)
    rw():equipClothingItem(itemData, slotInfo)
    refreshCharacterPreview()
end)

RegisterNetEvent('ox_inventory:equipOutfit', function(itemData, slotInfo)
    rw():equipOutfitItem(slotInfo or itemData)
    refreshCharacterPreview()
end)

RegisterNUICallback('equipClothing', function(data, cb)
    local item = type(data) == 'table' and (data.item or data) or nil
    if type(item) ~= 'table' or not item.slot or not item.name then
        cb(false)
        return
    end
    -- data.targetSlot is the wardrobe UI id (hat/shirt/…), NOT the bag slot index.
    -- EquipClothingItem must receive the numeric inventory slot from the dragged item.
    rw():equipClothingItem(item, {
        name = item.name,
        slot = item.slot,
        metadata = item.metadata,
    })
    refreshCharacterPreview()
    cb(true)
end)

RegisterNUICallback('unequipClothing', function(data, cb)
    if type(data) == 'table' then
        if not data.componentKey and data.slot then
            local slotToName = {
                hat = 'hat',
                mask = 'mask',
                glasses = 'glasses',
                shirt = 'torso',
                vest = 'armor',
                bag = 'bag',
                chain = 'necklace',
                gloves = 'arms',
                pants = 'legs',
                shoes = 'shoes',
                accessories = 'watch',
            }
            data.componentKey = slotToName[data.slot] or data.slot
        end

        if not data.name and data.componentKey then
            data.name = data.componentKey
        end
    end

    rw():handleUnequipClothing(data, cb)
    refreshCharacterPreview()
end)

RegisterNUICallback('toggleClothingVisibility', function(data, cb)
    rw():handleToggleClothingVisibility(data, cb)
    refreshCharacterPreview()
end)

RegisterNUICallback('unequipOutfit', function(data, cb)
    rw():handleUnequipOutfit(data, cb)
    refreshCharacterPreview()
end)

RegisterNUICallback('getEquippedClothing', function(_, cb)
    local ok, equipped = pcall(function()
        return rw():getEquippedForNUI()
    end)
    cb(ok and equipped or {})
end)

RegisterNUICallback('openWeaponAttachments', function(data, cb)
    rw():handleWeaponPreview(data, cb)
end)

RegisterNUICallback('closeWeaponAttachments', function(data, cb)
    rw():handleWeaponPreviewClose(data, cb)
end)

RegisterNUICallback('rotateWeapon', function(data, cb)
    rw():handleWeaponPreviewRotate(data, cb)
end)

RegisterNUICallback('weaponPreviewZoom', function(data, cb)
    rw():handleWeaponPreviewZoom(data, cb)
end)

RegisterNUICallback('weaponPreviewComponent', function(data, cb)
    rw():handleWeaponPreviewComponent(data, cb)
end)

RegisterNUICallback('weaponPreviewHover', function(data, cb)
    rw():handleWeaponPreviewHover(data, cb)
end)

RegisterNUICallback('weaponPreviewUnhover', function(data, cb)
    rw():handleWeaponPreviewUnhover(data, cb)
end)

RegisterNUICallback('attachComponent', function(data, cb)
    rw():handleWeaponPreviewComponent({ action = 'attach', name = data.component, slot = data.slot }, cb)
end)

RegisterNUICallback('removeComponent', function(data, cb)
    rw():handleWeaponPreviewComponent({ action = 'remove', name = data.component, slot = data.slot }, cb)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        pcall(function()
            exports.ox_inventory:closeWeaponCustomization()
        end)
    end
end)
