local QBInventory = {}

function QBInventory.Initialize()
    if GetResourceState("qb-inventory") ~= "started" then
        RW.Utils.Error("qb-inventory not started!")
        return false
    end
    RW.Utils.Debug("qb-inventory module initialized")
    return true
end

if IsDuplicityVersion() then
    function QBInventory.AddItem(source, item, amount, slot, info)
        local player = exports.ox_inventory:GetPlayer(source)
        if not player or not player._qbPlayer then return false end
        return player._qbPlayer.Functions.AddItem(item, amount, slot, info)
    end
    
    function QBInventory.RemoveItem(source, item, amount, slot)
        local player = exports.ox_inventory:GetPlayer(source)
        if not player or not player._qbPlayer then return false end
        return player._qbPlayer.Functions.RemoveItem(item, amount, slot)
    end
    
    function QBInventory.GetItem(source, item)
        local player = exports.ox_inventory:GetPlayer(source)
        if not player or not player._qbPlayer then return nil end
        return player._qbPlayer.Functions.GetItemByName(item)
    end
    
    function QBInventory.GetItemCount(source, item, metadata)
        local itemData = QBInventory.GetItem(source, item, metadata)
        if itemData and itemData.amount then
            return itemData.amount
        end
        return 0
    end
    
    function QBInventory.HasItem(source, item, amount)
        if not amount then amount = 1 end
        local player = exports.ox_inventory:GetPlayer(source)
        if not player or not player._qbPlayer then return false end
        return player._qbPlayer.Functions.HasItem(item, amount)
    end
    
    function QBInventory.SetItemMetadata(source, slot, metadata)
        RW.Utils.Warn("SetItemMetadata not directly supported in qb-inventory")
        return false
    end
    
    function QBInventory.GetInventory(source)
        local player = exports.ox_inventory:GetPlayer(source)
        if not player or not player._qbPlayer then return {} end
        return player._qbPlayer.PlayerData.items or {}
    end
    
    function QBInventory.GetInventoryItems(source)
        return QBInventory.GetInventory(source)
    end
    
    function QBInventory.CanCarry(source, item, amount)
        return true
    end
    
    function QBInventory.GetItemLabel(item)
        if RW.FrameworkObject and RW.FrameworkObject.Shared and RW.FrameworkObject.Shared.Items then
            local itemData = RW.FrameworkObject.Shared.Items[item]
            if itemData and itemData.label then
                return itemData.label
            end
        end
        return item
    end
    
    function QBInventory.GetItemWeight(item)
        if RW.FrameworkObject and RW.FrameworkObject.Shared and RW.FrameworkObject.Shared.Items then
            local itemData = RW.FrameworkObject.Shared.Items[item]
            if itemData and itemData.weight then
                return itemData.weight
            end
        end
        return 0
    end
    
    function QBInventory.CreateUseableItem(item, cb)
        if RW.FrameworkObject then
            RW.FrameworkObject.Functions.CreateUseableItem(item, function(source, itemData)
                local player = exports.ox_inventory:GetPlayer(source)
                cb(source, player, itemData)
            end)
        end
    end
    
    function QBInventory.ClearInventory(source)
        local player = exports.ox_inventory:GetPlayer(source)
        if not player or not player._qbPlayer then return false end
        player._qbPlayer.PlayerData.items = {}
        player._qbPlayer.Functions.UpdatePlayerData()
        return true
    end
    
    function QBInventory.GetSlot(source, slot)
        local inventory = QBInventory.GetInventory(source)
        return inventory[slot]
    end
    
    function QBInventory.GetItems()
        if RW.FrameworkObject and RW.FrameworkObject.Shared then
            return RW.FrameworkObject.Shared.Items or {}
        end
        return {}
    end
else
    function QBInventory.HasItem(item, amount)
        if not amount then amount = 1 end
        if RW.FrameworkObject then
            return RW.FrameworkObject.Functions.HasItem(item, amount)
        end
        return false
    end
    
    function QBInventory.GetItemCount(item)
        if RW.FrameworkObject then
            local itemData = RW.FrameworkObject.Functions.GetItemByName(item)
            if itemData and itemData.amount then
                return itemData.amount
            end
        end
        return 0
    end
    
    function QBInventory.GetPlayerItems()
        local pData = exports.ox_inventory:GetPlayerData()
        if pData and pData.items then
            return pData.items
        end
        return {}
    end
end

RW.RegisterModule("inventories", "qb-inventory", QBInventory)

