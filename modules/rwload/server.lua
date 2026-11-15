if not lib then return end

--[[
    Player inventory delivery guard (3.10.5) — server side.

    The inventory used to reach the client through ONE push
    (ox_inventory:setPlayerInventory), sent when the framework said the
    character had loaded. One lost push — the client resource still starting
    on the player's side, the page not up yet, a framework event that fired
    before this resource was ready, a load abandoned on the server — left the
    player in the server for the whole session with
        "cannot open inventory (player inventory has not loaded)"
    and every other script answering "invalid player" for them.

    The client now asks for its inventory (ox_inventory:requestPlayerInventory)
    for as long as it has none: shortly after its page is up, then every few
    seconds, and at once when the inventory key hits the not-loaded guard
    (modules/rwload/client.lua). This handler answers:
      · loaded on the server            → re-send the copy it has (no database read)
      · loaded for ANOTHER character of
        the same connection             → a stale inventory a logout never removed:
                                          drop it, then load the current one
      · not loaded, framework has the
        character                       → load it exactly as the bridge does on the
                                          framework's own event (server.frameworkPlayer)
      · framework has no character yet  → ignored (character screen); the client
                                          asks again later
    Nothing from the client is trusted: the framework decides which character
    this connection owns. Per-player cooldown.
]]

local Inventory = require 'modules.inventory.server'

local COOLDOWN_MS = 1500
local lastRequest = {}

---@param src number
---@return string outcome
local function answer(src)
    if type(server.frameworkPlayer) ~= 'function' then return 'bridge cannot name the character' end

    local ok, identifier, load = pcall(server.frameworkPlayer, src)

    if not ok then return ('bridge failed: %s'):format(tostring(identifier)) end
    if identifier == nil then return 'no character loaded' end

    if server.loadingInventory and server.loadingInventory[src] then return 'load in progress' end

    local inv = Inventory.Peek(src)

    if inv and inv.player and tostring(inv.owner) ~= tostring(identifier) then
        local dropped, err = pcall(server.playerDropped, src)

        if not dropped then return ('could not drop the stale inventory: %s'):format(tostring(err)) end

        inv = nil
    end

    if inv and inv.player then
        return server.pushPlayerInventory(inv) and 'resent' or 'resend refused'
    end

    if type(load) ~= 'function' then return 'not loaded and the bridge cannot load on request' end

    local loaded, err = pcall(load)

    if not loaded then return ('load failed: %s'):format(tostring(err)) end

    return 'loaded'
end

-- Outcomes worth a console line: a recovery (the push really was lost) and a
-- failure. "no character loaded" repeats every poll on the character screen
-- and stays silent unless inventory:loglevel is 2 or more.
local QUIET = { ['no character loaded'] = true, ['load in progress'] = true }

RegisterNetEvent('ox_inventory:requestPlayerInventory', function(attempt, why)
    local src = source

    if type(src) ~= 'number' or src <= 0 then return end

    local now = GetGameTimer()

    if (lastRequest[src] or 0) > now then return end

    lastRequest[src] = now + COOLDOWN_MS

    local outcome = answer(src)

    if QUIET[outcome] and (server.loglevel or 1) < 2 then return end

    print(('^3[ox_inventory]^7 player.%s asked for their inventory (%s, attempt %s): %s'):format(
        src, tostring(why or '?'), tostring(tonumber(attempt) or '?'), outcome))
end)

AddEventHandler('playerDropped', function()
    lastRequest[source] = nil
end)
