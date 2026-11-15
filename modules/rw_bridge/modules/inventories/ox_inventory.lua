local OxInventory = {}
local OxInv = nil

local function oxInv()
    if not OxInv then
        OxInv = exports.ox_inventory
    end
    return OxInv
end

function OxInventory.Initialize()
    if GetResourceState("ox_inventory") ~= "started" then
        RW.Utils.Error("ox_inventory not started!")
        return false
    end
    OxInv = exports.ox_inventory
    RW.Utils.Debug("ox_inventory module initialized")
    return true
end

if IsDuplicityVersion() then
    function OxInventory.AddItem(source, item, amount, metadata, slot)
        return OxInv:AddItem(source, item, amount, metadata, slot)
    end
    
    function OxInventory.RemoveItem(source, item, amount, metadata, slot)
        return OxInv:RemoveItem(source, item, amount, metadata, slot)
    end
    
    function OxInventory.GetItem(source, item, metadata, returnCount)
        return OxInv:GetItem(source, item, metadata, returnCount)
    end
    
    function OxInventory.GetItemCount(source, item, metadata)
        return OxInv:GetItemCount(source, item, metadata) or 0
    end
    
    function OxInventory.HasItem(source, item, amount)
        if not amount then amount = 1 end
        return OxInventory.GetItemCount(source, item) >= amount
    end
    
    function OxInventory.SetItemMetadata(source, slot, metadata)
        return OxInv:SetMetadata(source, slot, metadata)
    end
    
    function OxInventory.GetInventory(source)
        return OxInv:GetInventory(source)
    end
    
    function OxInventory.GetInventoryItems(source)
        return OxInv:GetInventoryItems(source)
    end
    
    function OxInventory.CanCarry(source, item, amount)
        return OxInv:CanCarryItem(source, item, amount)
    end
    
    function OxInventory.GetItemLabel(item)
        local itemData = OxInv:Items(item)
        if itemData and itemData.label then
            return itemData.label
        end
        return item
    end
    
    function OxInventory.GetItemWeight(item)
        local itemData = OxInv:Items(item)
        if itemData and itemData.weight then
            return itemData.weight
        end
        return 0
    end
    
    function OxInventory.CreateUseableItem(item, cb)
        RW.Utils.Debug("ox_inventory uses item definitions for useable items")
    end
    
    function OxInventory.ClearInventory(source)
        return OxInv:ClearInventory(source)
    end
    
    function OxInventory.GetSlot(source, slot)
        return OxInv:GetSlot(source, slot)
    end
    
    function OxInventory.GetSlots(source)
        return OxInv:GetSlots(source)
    end
    
    function OxInventory.SetSlotCount(source, slots)
        return OxInv:SetSlotCount(source, slots)
    end
    
    function OxInventory.SetMaxWeight(source, maxWeight)
        return OxInv:SetMaxWeight(source, maxWeight)
    end
    
    function OxInventory.GetItems()
        return OxInv:Items()
    end
else
    -- Never call exports.ox_inventory from inside ox_inventory — that recurses through rw_bridge exports.
    local function directGetItemCount(item)
        if client and client.getItemCount then
            return client.getItemCount(item) or 0
        end
        return 0
    end

    function OxInventory.HasItem(item, amount)
        if not amount then amount = 1 end
        return directGetItemCount(item) >= amount
    end

    function OxInventory.GetItemCount(item)
        return directGetItemCount(item)
    end

    function OxInventory.GetPlayerItems()
        return PlayerData and PlayerData.inventory or {}
    end

    function OxInventory.GetPlayerWeight()
        return PlayerData and PlayerData.weight or 0
    end

    function OxInventory.GetPlayerMaxWeight()
        return PlayerData and PlayerData.maxWeight or 0
    end

    function OxInventory.UseItem(item)
        if client and client.useItem then
            return client.useItem(item)
        end
    end

    function OxInventory.OpenInventory(invType, data)
        if client and client.openInventory then
            return client.openInventory(invType, data)
        end
    end

    function OxInventory.CloseInventory()
        if client and client.closeInventory then
            return client.closeInventory()
        end
    end
end

RW.RegisterModule("inventories", "ox_inventory", OxInventory)

