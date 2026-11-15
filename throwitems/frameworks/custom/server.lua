

Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'standalone' then
        return
    end

    function Framework:getPlayerName(source)
        return GetPlayerName(source)
    end
end)

