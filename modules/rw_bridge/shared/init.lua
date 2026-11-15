if not RW then
    RW = {}
end

RW.Ready = false
RW.Framework = nil
RW.FrameworkObject = nil
RW.Inventory = nil
RW.HasOxLib = false
RW.Appearance = nil
RW.Modules = {
    Framework = nil,
    Inventory = nil,
    Appearance = nil
}

if not RW.RegisteredModules then
    RW.RegisteredModules = {
        frameworks = {},
        inventories = {},
        appearances = {}
    }
end

function RW.RegisterModule(category, name, module)
    if not RW.RegisteredModules[category] then
        if RW.Utils and RW.Utils.Error then
            RW.Utils.Error("Unknown module category:", category)
        end
        return
    end
    
    RW.RegisteredModules[category][name] = module
    
    if RW.Utils and RW.Utils.Debug then
        RW.Utils.Debug(string.format("Registered %s module: %s", category, name))
    end
end

if IsDuplicityVersion() then
    RW.Players = {}
else
    RW.PlayerData = nil
end

function DetectFramework()
    if Config.Framework then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Framework override from config:", Config.Framework)
        end
        return Config.Framework
    end
    
    if RW.Utils.IsResourceStarted(Config.ResourceNames.qbox) then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Detected QBox framework")
        end
        return "qbox"
    end
    
    if RW.Utils.IsResourceStarted(Config.ResourceNames.qbcore) then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Detected QB-Core framework")
        end
        return "qbcore"
    end
    
    if RW.Utils.IsResourceStarted(Config.ResourceNames.esx) then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Detected ESX framework")
        end
        return "esx"
    end
    
    return nil
end

function DetectInventory()
    if Config.Inventory then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Inventory override from config:", Config.Inventory)
        end
        return Config.Inventory
    end
    
    if RW.Utils.IsResourceStarted(Config.ResourceNames.ox_inventory) then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Detected ox_inventory")
        end
        return "ox_inventory"
    end
    
    if RW.Utils.IsResourceStarted(Config.ResourceNames.qs_inventory) then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Detected qs-inventory")
        end
        return "qs-inventory"
    end
    
    if RW.Utils.IsResourceStarted(Config.ResourceNames.codem_inventory) then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Detected codem-inventory")
        end
        return "codem-inventory"
    end
    
    if RW.Utils.IsResourceStarted(Config.ResourceNames.qb_inventory) then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Detected qb-inventory")
        end
        return "qb-inventory"
    end
    
    if RW.Utils.IsResourceStarted(Config.ResourceNames.esx_inventory) then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Detected esx_inventory")
        end
        return "esx_inventory"
    end
    
    if RW.Utils and RW.Utils.Debug then
        RW.Utils.Debug("No external inventory detected, using native")
    end
    return "native"
end

function GetFrameworkModule(frameworkName)
    local module = RW.RegisteredModules.frameworks[frameworkName]
    if not module then
        if RW.Utils and RW.Utils.Error then
            RW.Utils.Error("Framework module not registered:", frameworkName)
        end
        return nil
    end
    
    if RW.Utils and RW.Utils.Debug then
        RW.Utils.Debug("Selected framework module:", frameworkName)
    end
    return module
end

function GetInventoryModule(inventoryName)
    if inventoryName == "native" then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Using native framework inventory")
        end
        return nil
    end
    
    local module = RW.RegisteredModules.inventories[inventoryName]
    if not module then
        if RW.Utils and RW.Utils.Error then
            RW.Utils.Error("Inventory module not registered:", inventoryName)
        end
        return nil
    end
    
    if RW.Utils and RW.Utils.Debug then
        RW.Utils.Debug("Selected inventory module:", inventoryName)
    end
    return module
end

function DetectAppearance()
    if Config.Appearance then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Appearance override from config:", Config.Appearance)
        end
        return Config.Appearance
    end
    
    if RW.Utils.IsResourceStarted(Config.ResourceNames.illenium_appearance) then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Detected illenium-appearance")
        end
        return "illenium-appearance"
    end
    
    if RW.Utils.IsResourceStarted(Config.ResourceNames.qb_clothing) then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Detected qb-clothing")
        end
        return "qb-clothing"
    end
    
    if RW.Utils.IsResourceStarted(Config.ResourceNames.esx_skin) then
        if RW.Utils and RW.Utils.Debug then
            RW.Utils.Debug("Detected esx_skin")
        end
        return "esx_skin"
    end
    
    if RW.Utils and RW.Utils.Debug then
        RW.Utils.Debug("No appearance system detected")
    end
    return nil
end

function GetAppearanceModule(appearanceName)
    if not appearanceName then return nil end
    
    local module = RW.RegisteredModules.appearances[appearanceName]
    if not module then
        if RW.Utils and RW.Utils.Error then
            RW.Utils.Error("Appearance module not registered:", appearanceName)
        end
        return nil
    end
    
    if RW.Utils and RW.Utils.Debug then
        RW.Utils.Debug("Selected appearance module:", appearanceName)
    end
    return module
end

function InitializeBridge()
    RW.Framework = DetectFramework()
    if not RW.Framework then
        RW.Utils.Error(Config.Translate("no_framework"))
        return false
    end
    
    RW.Utils.Print(Config.Translate("framework_detected", RW.Framework))
    
    RW.Inventory = DetectInventory()
    RW.Utils.Print(Config.Translate("inventory_detected", RW.Inventory))
    
    RW.Appearance = DetectAppearance()
    if RW.Appearance then
        RW.Utils.Print(Config.Translate("appearance_detected", RW.Appearance))
    end
    
    RW.HasOxLib = RW.Utils.IsResourceStarted(Config.ResourceNames.ox_lib)
    if RW.HasOxLib then
        RW.Utils.Debug("ox_lib detected, will use for UI features")
    end
    
    RW.Modules.Framework = GetFrameworkModule(RW.Framework)
    if not RW.Modules.Framework then
        RW.Utils.Error("Failed to load framework module!")
        return false
    end
    
    if RW.Inventory ~= "native" then
        RW.Modules.Inventory = GetInventoryModule(RW.Inventory)
    end
    
    if RW.Appearance then
        RW.Modules.Appearance = GetAppearanceModule(RW.Appearance)
    end
    
    RW.Ready = true
    RW.Utils.Print(Config.Translate("bridge_ready"))
    
    TriggerEvent(Config.EventPrefix .. ":ready", RW.Framework, RW.Inventory)
    return true
end

function RW.WaitForReady(timeout)
    timeout = timeout or 10000
    local startTime = GetGameTimer()
    
    while not RW.Ready do
        Wait(100)
        if (GetGameTimer() - startTime) > timeout then
            RW.Utils.Error("Bridge initialization timeout!")
            return false
        end
    end
    return true
end

exports("IsReady", function()
    return RW.Ready
end)

exports("GetFramework", function()
    return RW.Framework
end)

exports("GetInventorySystem", function()
    return RW.Inventory
end)

exports("HasOxLib", function()
    return RW.HasOxLib
end)

exports("GetAppearanceSystem", function()
    return RW.Appearance
end)

exports("WaitForReady", function(timeout)
    return RW.WaitForReady(timeout)
end)

exports("Translate", function(key, ...)
    return Config.Translate(key, ...)
end)

CreateThread(function()
    Wait(500)
    if not InitializeBridge() then
        RW.Utils.Error("Bridge initialization failed!")
        return
    end
    
    if RW.Modules.Framework and RW.Modules.Framework.Initialize then
        RW.Modules.Framework.Initialize()
    end
    
    if RW.Modules.Inventory and RW.Modules.Inventory.Initialize then
        RW.Modules.Inventory.Initialize()
    end
    
    if RW.Modules.Appearance and RW.Modules.Appearance.Initialize then
        RW.Modules.Appearance.Initialize()
    end
end)

