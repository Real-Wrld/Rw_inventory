if not lib then return end

-- ═════════════════════════════════════════════════════════════
--  REALWRLD · ox_inventory · Pocket slot (client relay)
--
--  The server owns the pocket (modules/rwpocket/server.lua); this only
--  keeps its public state for the page:
--    ox_inventory:rwPocket  { enabled, safe, countWeight, blacklist,
--                                slot, slots, has }  → NUI `oxlynPocket`
--    NUI `oxlynPocketState`    the page asks on mount (answers the cache)
--    NUI `oxlynPocketDenied`   a refused move (client.lua swapItems): the
--                              page shows the reason on the pocket tile
--  `client.pocketSlots()` is the slot count the NUI init sizes the
--  pockets with (N + 1 while the player has the pocket).
-- ═════════════════════════════════════════════════════════════

local Pocket = {}
local cached = nil

local function push()
    if cached then SendNUIMessage({ action = 'oxlynPocket', data = cached }) end
end

RegisterNetEvent('ox_inventory:rwPocket', function(data)
    if source == '' or type(data) ~= 'table' then return end
    cached = data
    push()
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNetEvent('ox_inventory:oxlynPocket', function(data)
    if source == '' or type(data) ~= 'table' then return end
    cached = data
    push()
end)

RegisterNUICallback('rwPocketState', function(_, cb)
    cb(cached or { enabled = false })
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynPocketState', function(_, cb)
    cb(cached or { enabled = false })
end)

---Slot count of the player's inventory (the pocket included), or nil.
---@return integer?
function Pocket.slots()
    return cached and tonumber(cached.slots) or nil
end

---A refused move whose reason is the pocket's: shown on the pocket tile, not as a notification.
---@param reason any
---@return boolean handled
function Pocket.denied(reason)
    if type(reason) ~= 'string' or reason:sub(1, 7) ~= 'pocket_' then return false end
    SendNUIMessage({ action = 'oxlynPocketDenied', data = { reason = reason } })
    return true
end

-- a resource restart while playing: ask once the page is up
CreateThread(function()
    while not (client and client.uiLoaded) do Wait(250) end
    if cached then return push() end
    local ok, data = pcall(lib.callback.await, 'ox_inventory:rwPocketSync', false)
    if ok and type(data) == 'table' and not cached then
        cached = data
        push()
    end
end)

if client then client.pocketSlots = Pocket.slots end

return Pocket
