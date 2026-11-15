

Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'qbcore' then
        return
    end

    function Framework:getCore()
        return exports['qb-core']:GetCoreObject();
    end

    local QBCore = Framework:getCore();

    function Framework:Notify(source, message)
        TriggerClientEvent('QBCore:Notify', source, message)
    end

    function Framework:getPlayerName(source)
        source = tonumber(source)
        local player = QBCore.Functions.GetPlayer(source)

        if player and player.Functions.GetName then
            return player.Functions.GetName()
        end

        return "Unknown Player"
    end
end)

