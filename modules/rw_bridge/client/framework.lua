function GetNativeFramework()
    return RW.FrameworkObject
end

function ExecuteForFramework(handlers)
    if not RW.Ready then
        RW.Utils.Warn("Bridge not ready for framework execution")
        return nil
    end
    
    local frameworkHandler = handlers[RW.Framework]
    if frameworkHandler then
        return frameworkHandler(RW.FrameworkObject)
    end
    
    if handlers.any then
        return handlers.any(RW.FrameworkObject, RW.Framework)
    end
    
    if handlers.default then
        return handlers.default(RW.FrameworkObject, RW.Framework)
    end
    
    return nil
end

function IsFramework(frameworkName)
    return RW.Framework == frameworkName
end

function IsESX()
    return RW.Framework == "esx"
end

function IsQBCore()
    return RW.Framework == "qbcore"
end

function IsQBox()
    return RW.Framework == "qbox"
end

function GetClientInfo()
    local info = {}
    info.framework = RW.Framework
    info.inventory = RW.Inventory
    info.hasOxLib = RW.HasOxLib
    info.playerLoaded = exports.ox_inventory:IsPlayerLoaded()
    return info
end

exports("GetNativeFramework", GetNativeFramework)
exports("ExecuteForFramework", ExecuteForFramework)
exports("IsFramework", IsFramework)
exports("IsESX", IsESX)
exports("IsQBCore", IsQBCore)
exports("IsQBox", IsQBox)
exports("GetClientInfo", GetClientInfo)

