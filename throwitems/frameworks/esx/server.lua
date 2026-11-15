

Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'esx' then
        return
    end

    function Framework:getCore()
        return exports['es_extended']:getSharedObject();
    end

    function Framework:Notify(source, message)
        TriggerClientEvent('esx:showNotification', source, message)
    end

    function Framework:getPlayerName(source)
        source = tonumber(source)
        local ESX = Framework:getCore()
        local player = ESX.GetPlayerFromId(source)

        if player and player.getName then
            return player.getName()
        end

        return "Unknown Player"
    end
end)

