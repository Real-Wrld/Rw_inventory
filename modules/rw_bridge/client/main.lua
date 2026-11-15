CreateThread(function()
    local ready = RW.WaitForReady()
    if not ready then
        RW.Utils.Error("Failed to initialize client components - bridge not ready")
        return
    end
    
    RW.Utils.Debug("Client components initialized")
    
    while true do
        if exports.ox_inventory:IsPlayerLoaded() then
            break
        end
        Wait(500)
    end
    
    RW.Utils.Debug("Player loaded, client fully ready")
end)

RegisterNetEvent(Config.EventPrefix .. ":notify", function(message, type, length)
    exports.ox_inventory:Notify(message, type, length)
end)

RegisterNetEvent(Config.EventPrefix .. ":client:setComponent", function(componentId, drawableId, textureId)
    exports.ox_inventory:SetPedComponent(nil, componentId, drawableId, textureId)
end)

RegisterNetEvent(Config.EventPrefix .. ":client:setProp", function(componentId, drawableId, textureId)
    exports.ox_inventory:SetPedProp(nil, componentId, drawableId, textureId)
end)

RegisterNetEvent(Config.EventPrefix .. ":client:setHair", function(drawableId, textureId, highlightColor)
    exports.ox_inventory:SetPedHair(nil, drawableId, textureId, highlightColor)
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RW.Utils.Debug("RW Bridge client started")
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RW.Utils.Debug("RW Bridge client stopping")
        RW.PlayerData = nil
    end
end)

