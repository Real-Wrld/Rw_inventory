

if not lib then return end

--[[
    Player inventory delivery guard (3.10.5) — client side.

    See modules/rwload/server.lua. While this client has no inventory it
    asks the server for one: 1.5 s after the page is up, then every 5 s, and
    at once (rate-limited) when the inventory key hits the not-loaded guard in
    client.lua. The server ignores the request until the framework has a
    character for this connection, so polling on the character screen costs
    one tiny event every 5 s and nothing else. Once loaded, the loop only
    reads a flag; after a logout it starts asking again.
]]

local FIRST_DELAY_MS = 1500
local POLL_MS = 5000
local MIN_GAP_MS = 2000

local attempts = 0
local lastSent = -MIN_GAP_MS

---@param why? 'poll' | 'keypress'
---@return boolean sent
function client.requestPlayerInventory(why)
    if PlayerData.loaded then return false end

    local now = GetGameTimer()

    if now - lastSent < MIN_GAP_MS then return false end

    lastSent = now
    attempts += 1
    TriggerServerEvent('ox_inventory:requestPlayerInventory', attempts, why or 'poll')

    return true
end

CreateThread(function()
    while not client.uiLoaded do Wait(250) end

    Wait(FIRST_DELAY_MS)

    while true do
        if PlayerData.loaded then
            attempts = 0
        else
            client.requestPlayerInventory('poll')
        end

        Wait(POLL_MS)
    end
end)

