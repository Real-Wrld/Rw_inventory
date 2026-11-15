

Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'qbox' then
        return
    end

    function Framework:getCore()
        return exports['qb-core']:GetCoreObject();
    end

    function Framework:Notify(message, type)
        lib.notify({ description = message, type = type or 'error' })
    end
end)

