

Framework = Framework or {}

CreateThread(function()
    if Config.Framework ~= 'esx' then
        return
    end

    local ESX = exports['es_extended']:getSharedObject()

    function Framework:getCore()
        return ESX
    end

    function Framework:Notify(message, notifyType)
        ESX.ShowNotification(message)
    end
end)

