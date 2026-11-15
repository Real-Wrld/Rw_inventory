

Framework = Framework or {}

CreateThread(function()
    if Config.Framework ~= 'qbox' then
        return
    end

    function Framework:getCore()
        return exports['qb-core']:GetCoreObject();
    end

    function Framework:Notify(source, message)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Notification',
            description = message,
            type = 'inform'
        })
    end
end)

