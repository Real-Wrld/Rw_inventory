

Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'standalone' then
        return
    end

    function Framework:Notify(message)
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, true)
    end
end)

