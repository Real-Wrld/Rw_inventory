function GetInventorySystemFn(funcName)
    if RW.Modules.Inventory then
        if RW.Modules.Inventory[funcName] then
            return RW.Modules.Inventory[funcName]
        end
    end
    if RW.Modules.Framework then
        if RW.Modules.Framework[funcName] then
            return RW.Modules.Framework[funcName]
        end
    end
    return nil
end

function HasItem(item, amount)
    if not RW.Ready then
        return false
    end
    if not amount then
        amount = 1
    end
    local fn = GetInventorySystemFn("HasItem")
    if fn then
        return fn(item, amount)
    end
    return false
end

function GetItemCount(item)
    if client and client.getItemCount then
        return client.getItemCount(item) or 0
    end
    if not RW.Ready then
        return 0
    end
    local fn = GetInventorySystemFn("GetItemCount")
    if fn then
        return fn(item)
    end
    return 0
end

function GetPlayerItems()
    if not RW.Ready then
        return {}
    end
    local fn = GetInventorySystemFn("GetPlayerItems")
    if fn then
        return fn()
    end
    return {}
end

function GetPlayerWeight()
    if not RW.Ready then
        return 0
    end
    local fn = GetInventorySystemFn("GetPlayerWeight")
    if fn then
        return fn()
    end
    return 0
end

function GetPlayerMaxWeight()
    if not RW.Ready then
        return 0
    end
    local fn = GetInventorySystemFn("GetPlayerMaxWeight")
    if fn then
        return fn()
    end
    return 0
end

function OpenInventory(inventoryType, data)
    if not RW.Ready then
        return
    end
    local fn = GetInventorySystemFn("OpenInventory")
    if fn then
        return fn(inventoryType, data)
    end
    RW.Utils.Warn("OpenInventory: Not supported by current inventory")
end

function CloseInventory()
    if not RW.Ready then
        return
    end
    local fn = GetInventorySystemFn("CloseInventory")
    if fn then
        return fn()
    end
end

RegisterNetEvent(Config.EventPrefix .. ":client:itemAdded", function(item, amount)
    TriggerEvent(Config.EventPrefix .. ":client:itemAdded", item, amount)
end)

RegisterNetEvent(Config.EventPrefix .. ":client:itemRemoved", function(item, amount)
    TriggerEvent(Config.EventPrefix .. ":client:itemRemoved", item, amount)
end)

exports("HasItem", HasItem)
exports("GetItemCount", GetItemCount)
exports("GetPlayerItems", GetPlayerItems)
exports("GetPlayerWeight", GetPlayerWeight)
exports("GetPlayerMaxWeight", GetPlayerMaxWeight)
exports("OpenInventory", OpenInventory)
exports("CloseInventory", CloseInventory)

