if not lib then return end

--- Server-side cache module for custom ox_inventory.
--- Provides a shared table used during resource startup.

local Cache = {
    players = {},
}

function Cache.get(source, key)
    local player = Cache.players[source]
    return player and player[key]
end

function Cache.set(source, key, value)
    if not Cache.players[source] then
        Cache.players[source] = {}
    end

    Cache.players[source][key] = value
end

function Cache.clear(source)
    Cache.players[source] = nil
end

AddEventHandler('playerDropped', function()
    Cache.clear(source)
end)

return Cache
