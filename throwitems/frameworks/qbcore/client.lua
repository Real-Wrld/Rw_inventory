

Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'qbcore' then
        return
    end

    function Framework:getCore()
        return exports['qb-core']:GetCoreObject();
    end

    function Framework:Notify(message, type)
        QBCore = QBCore or exports['qb-core']:GetCoreObject()
        QBCore.Functions.Notify(message, type or 'error')
    end
end)

