--  REALWRLD Software® · ox_inventory · Pocket slot · server
-- ═════════════════════════════════════════════════════════════
--
--  An OPTIONAL extra slot of the player inventory that holds ONE item
--  stack (any count). Server-authoritative:
--
--    • the slot: player slots N (`inventory:slots`) → the pocket is slot
--      N + 1 (`Pocket.index()`), persisted with the rest of the inventory,
--      so no saved item moves. `inv.pocket` marks an inventory that has it
--      (the slot count grows to N + 1). Automatic placement (AddItem
--      without a slot, GetEmptySlot, GetSlotForItem, give, pickups, shop
--      baskets) never lands there; only a drag, or an explicit slot that
--      passes the blacklist.
--    • safe on death (`safeOnDeath`): ClearInventory / ConfiscateInventory
--      / CreateDropFromPlayer keep it; while the player is dead (framework
--      state + a grace window after the revive) RemoveItem cannot take it
--      (by name: the rest is removed; by that slot: refused) and other
--      players cannot take it out. Protection re-checks the blacklist at
--      that moment, so a blacklisted item that got there anyhow is never
--      kept.
--    • off (`enabled = false`, the default): nothing changes for anyone.
--      A player who still has an item parked in the pocket gets it moved
--      into a free slot on load (logged `pocket_rehome`); with a full
--      inventory the slot stays, drain-only (items come out, nothing goes
--      in) — an item is never deleted.
--
--  Config: config.lua `RWInv.PocketSlot` + admin overrides in KVP
--  `rw:pocketConfig` (Settings › World › Pocket slot, admin window ›
--  Server), broadcast live. Other death scripts: see docs/POCKET_SLOT.md.
-- ═════════════════════════════════════════════════════════════

if not lib then return end

local Shared = require 'modules.rwpocket.shared'
local conf = require 'modules.rwconfig.shared'.Get()
local Log = require 'modules.rwlogs.server'

local Pocket = {}
local KVP_KEY = 'rw:pocketConfig'
local KEY_TYPES = { enabled = 'boolean', safeOnDeath = 'boolean', countWeight = 'boolean', blacklist = 'table' }

local rawConf = type(conf.PocketSlot) == 'table' and conf.PocketSlot or {}
local deathHook = type(rawConf.isDead) == 'function' and rawConf.isDead or nil

-- ─── effective config (config.lua + admin overrides) ─────────
local overrides = {}
do
    local raw = GetResourceKvpString(KVP_KEY)
    local ok, doc = pcall(json.decode, raw or '')
    if ok and type(doc) == 'table' and type(doc.overrides) == 'table' then
        for k, t in pairs(KEY_TYPES) do
            local v = doc.overrides[k]
            if type(v) == t then overrides[k] = k == 'blacklist' and Shared.cleanList(v) or v end
        end
    end
end

local state = {}

local function rawConfig()
    local out = {}
    for k, v in pairs(rawConf) do out[k] = v end
    for k, v in pairs(overrides) do out[k] = v end
    return out
end

local function recompute()
    state.cfg = Shared.sanitize(rawConfig())
    state.compiled = Shared.compile(state.cfg.blacklist)
end
recompute()

---@return { enabled: boolean, safeOnDeath: boolean, countWeight: boolean, blacklist: string[], graceSeconds: number }
function Pocket.config() return state.cfg end

---The pocket's slot index: one past the player's normal slots.
---@return integer
function Pocket.index() return (tonumber(shared.playerslots) or 50) + 1 end

-- Resolved lazily: the inventory module requires this one at load.
local InventoryMod, ItemsMod
local function Inv()
    if not InventoryMod then InventoryMod = require 'modules.inventory.server' end
    return InventoryMod
end
local function ItemsDb()
    if ItemsMod == nil then
        local ok, m = pcall(require, 'modules.items.server')
        ItemsMod = ok and type(m) == 'table' and m or false
    end
    return ItemsMod or nil
end

local function L(key, fallback, ...)
    local s = locale(key, ...)
    if s == nil or s == key then
        if select('#', ...) > 0 then return fallback:format(...) end
        return fallback
    end
    return s
end

local function notify(src, kind, text)
    if tonumber(src) and tonumber(src) > 0 then
        TriggerClientEvent('ox_lib:notify', src, { id = 'rw_pocket', type = kind, description = text })
    end
end

local function record(action, fields)
    if Log and Log.enabled and Log.enabled(action) then pcall(Log.record, action, fields) end
end

-- ═════════════════════════════════════════════════════════════
--  THE SLOT
-- ═════════════════════════════════════════════════════════════

---The pocket slot of an inventory that has one (player inventories only).
---@param inv table?
---@return integer?
function Pocket.slotOf(inv)
    return type(inv) == 'table' and inv.type == 'player' and inv.pocket or nil
end

---@param inv table?
---@param slot any
---@return boolean
function Pocket.is(inv, slot)
    local p = Pocket.slotOf(inv)
    return p ~= nil and tonumber(slot) == p
end

---Why an item may not go in the pocket, nil when it may:
---'pocket_off' (the system is off), 'pocket_blocked' (blacklist),
---'pocket_container' (a backpack would carry its whole contents past death).
---@param name any
---@return string?
function Pocket.refusal(name)
    if not state.cfg.enabled then return 'pocket_off' end
    if type(name) ~= 'string' or Shared.blocked(state.compiled, name) then return 'pocket_blocked' end
    local Items = ItemsDb()
    if Items and type(Items.containers) == 'table' and Items.containers[name] then return 'pocket_container' end
    return nil
end

---@param name any
---@return boolean
function Pocket.allows(name) return Pocket.refusal(name) == nil end

---The pocket slot when it holds an item that is kept on death right now
---(on, safe, an allowed item) — else nil.
---@param inv table?
---@return integer?
function Pocket.protectedSlot(inv)
    local p = Pocket.slotOf(inv)
    if not p or not state.cfg.enabled or not state.cfg.safeOnDeath then return nil end
    local data = inv.items and inv.items[p]
    if type(data) ~= 'table' or not data.name or Pocket.refusal(data.name) then return nil end
    return p
end

-- ─── death state ─────────────────────────────────────────────
--  Framework truth first (QB / Qbox keep the ped ALIVE while «dead», so
--  the ped is never asked): an optional RWInv.PocketSlot.isDead(src)
--  hook, the usual state bags, QB / Qbox metadata isdead / inlaststand,
--  ND metadata; then the death events of ESX / qb-ambulancejob. A revive
--  keeps the pocket locked for `graceSeconds` more: respawn flows remove
--  items right after the revive (esx_ambulancejob clears its death status
--  BEFORE removeItemsAfterRPDeath runs).
local deadState = {}

local function markDead(src, dead)
    src = tonumber(src)
    if not src or src <= 0 then return end
    local s = deadState[src]
    if dead then
        deadState[src] = { dead = true }
    elseif s and s.dead then
        deadState[src] = { dead = false, graceUntil = GetGameTimer() + state.cfg.graceSeconds * 1000 }
    end
end
Pocket.markDead = markDead

local DEATH_BAGS = { 'isDead', 'isdead', 'dead', 'laststand', 'inLaststand', 'inlaststand' }

---@param src number
---@return boolean
function Pocket.isDead(src)
    src = tonumber(src)
    if not src or src <= 0 then return false end

    if deathHook then
        local ok, res = pcall(deathHook, src)
        if ok and type(res) == 'boolean' then return res end
    end

    local bag = Player(src)
    local st = bag and bag.state
    if st then
        for i = 1, #DEATH_BAGS do
            if st[DEATH_BAGS[i]] then return true end
        end
    end

    local s = deadState[src]
    if s then
        if s.dead then return true end
        if s.graceUntil then
            if GetGameTimer() < s.graceUntil then return true end
            deadState[src] = nil
        end
    end

    -- the framework's player object last (a cross-resource call)
    local fw = shared.framework
    if fw == 'qb' or fw == 'qbx' or fw == 'nd' then
        local ok, dead = pcall(function()
            if fw == 'nd' then
                local p = NDCore and NDCore.getPlayer and NDCore.getPlayer(src)
                local m = p and p.metadata
                return m and (m.dead or m.isDead) and true or false
            end
            local p = fw == 'qbx' and exports.qbx_core:GetPlayer(src) or (server.GetPlayerFromId and server.GetPlayerFromId(src))
            local m = p and p.PlayerData and p.PlayerData.metadata
            return m and (m.isdead or m.inlaststand) and true or false
        end)
        if ok and dead then return true end
    end

    return false
end

---The protected pocket slot while its owner is dead (nothing may take it), else nil.
---@param inv table?
---@return integer?
function Pocket.lockedSlot(inv)
    local p = Pocket.protectedSlot(inv)
    if p and Pocket.isDead(inv.id) then return p end
    return nil
end

if shared.framework == 'esx' then
    RegisterNetEvent('esx:onPlayerDeath', function() markDead(source, true) end)
    RegisterNetEvent('esx:onPlayerSpawn', function() markDead(source, false) end)
    RegisterNetEvent('esx_ambulancejob:setDeathStatus', function(isDead) markDead(source, isDead == true or isDead == 1) end)
elseif shared.framework == 'qb' then
    RegisterNetEvent('hospital:server:SetDeathStatus', function(isDead) markDead(source, isDead == true) end)
    RegisterNetEvent('hospital:server:SetLaststandStatus', function(bool) markDead(source, bool == true) end)
end

-- a state bag that goes back to false (revive) opens the grace window
for i = 1, #DEATH_BAGS do
    AddStateBagChangeHandler(DEATH_BAGS[i], nil, function(bagName, _, value)
        local src = tonumber((tostring(bagName):match('^player:(%d+)$')))
        if not src then return end
        if value then markDead(src, true) else markDead(src, false) end
    end)
end

AddEventHandler('playerDropped', function() deadState[source] = nil end)

-- ─── weight ──────────────────────────────────────────────────
---`countWeight = false`: what the pocket's item weighs is added to the
---capacity (Inventory.MaxWeight), so it never takes room from the pockets.
---@param inv table?
---@return number
function Pocket.freeWeight(inv)
    local p = Pocket.slotOf(inv)
    if not p or not state.cfg.enabled or state.cfg.countWeight then return 0 end
    local data = inv.items and inv.items[p]
    return type(data) == 'table' and tonumber(data.weight) or 0
end

---@return boolean
function Pocket.countsWeight() return not state.cfg.enabled or state.cfg.countWeight end

---Correction for Inventory.GetItemSlots' free-slot count: the pocket is
---not a free slot for automatic placement.
---@param inv table
---@return integer
function Pocket.emptyAdjust(inv)
    local p = Pocket.slotOf(inv)
    if not p then return 0 end
    local filled = inv.items[p] ~= nil
    if p <= (inv.slots or 0) then return filled and 0 or -1 end
    return filled and 1 or 0
end

---Stable order for a by-name walk over slots: the pocket last.
---@param inv table
---@param list table[] slot tables ({ slot = n, ... })
function Pocket.sortLast(inv, list)
    local p = Pocket.slotOf(inv)
    if not p or type(list) ~= 'table' then return list end
    for i = 1, #list do
        local s = list[i]
        if type(s) == 'table' and s.slot == p and i < #list then
            table.remove(list, i)
            list[#list + 1] = s
            break
        end
    end
    return list
end

-- ═════════════════════════════════════════════════════════════
--  LOAD · ATTACH · REHOME
-- ═════════════════════════════════════════════════════════════

---First empty slot of `items` in 1..last, skipping `skip`.
local function firstFree(items, last, skip)
    for i = 1, last do
        if i ~= skip and items[i] == nil then return i end
    end
end

---The normal slots of an inventory whose pocket is `p`.
local function normalLast(slots, p)
    slots = tonumber(slots) or 0
    if slots == p then return p - 1 end
    return slots
end

local pendingNotice = {}

---server.setPlayerInventory, before Inventory.Create: the loaded slots
---(slot → data, weights already set). Moves a parked item out of the
---pocket when the system is off (or when it holds an item the pocket no
---longer allows) and returns the slot count to create the inventory with.
local rehomed = {} -- source -> the load moved the pocket item (attach marks the inventory changed)

---@param source number
---@param inventory table<number, table>
---@return integer slots
function Pocket.prepareLoad(source, inventory)
    -- a character that logged out dead must not hand the lock to the next
    -- one (multichar has no spawn event to clear it)
    deadState[tonumber(source) or 0] = nil

    local N = tonumber(shared.playerslots) or 50
    local P = Pocket.index()
    local data = inventory[P]

    if data and (not state.cfg.enabled or Pocket.refusal(data.name)) then
        local i = firstFree(inventory, N, P)
        if i then
            inventory[P] = nil
            data.slot = i
            inventory[i] = data
            rehomed[source] = true
            record('pocket_rehome', { item = data.name, count = data.count, metadata = data.metadata, actor = source, target = source, extra = { fromSlot = P, toSlot = i, reason = state.cfg.enabled and 'blocked' or 'off' } })
            pendingNotice[source] = { 'inform', L('rw_pocket_moved', 'Your pocket item was moved into your inventory') }
        elseif not state.cfg.enabled then
            record('pocket_rehome', { item = data.name, count = data.count, metadata = data.metadata, actor = source, target = source, severity = 1, extra = { fromSlot = P, parked = true, reason = 'full' } })
            pendingNotice[source] = { 'warning', L('rw_pocket_parked', 'The pocket slot is off — make room and move its item out') }
        end
    end

    if state.cfg.enabled or inventory[P] then return math.max(N, P) end
    return N
end

---After Inventory.Create (player): marks the inventory that has the pocket.
---@param inv table
function Pocket.attach(inv)
    if type(inv) ~= 'table' or inv.type ~= 'player' then return end
    local P = Pocket.index()
    if state.cfg.enabled or inv.items[P] then
        inv.pocket = P
        if (inv.slots or 0) < P and state.cfg.enabled then inv.slots = P end
    else
        inv.pocket = nil
    end
    -- a rehome is a real change: unsaved, it repeated (log + notice) on every login
    if rehomed[inv.id] then
        inv.changed = true
        rehomed[inv.id] = nil
    end
end

---What the client / NUI gets (per player: its slot count).
---@param inv table?
function Pocket.publicState(inv)
    local cfg = state.cfg
    local list = {}
    for i = 1, #cfg.blacklist do list[i] = cfg.blacklist[i] end
    return {
        enabled = cfg.enabled,
        safe = cfg.safeOnDeath,
        countWeight = cfg.countWeight,
        blacklist = list,
        slot = Pocket.index(),
        slots = type(inv) == 'table' and inv.slots or nil,
        has = type(inv) == 'table' and inv.pocket ~= nil or nil,
    }
end

---@param src number
---@param inv table?
function Pocket.push(src, inv)
    TriggerClientEvent('ox_inventory:rwPocket', src, Pocket.publicState(inv))
end

---server.setPlayerInventory, after the client got its inventory.
---@param inv table
function Pocket.afterLoad(inv)
    local n = pendingNotice[inv.id]
    if n then
        pendingNotice[inv.id] = nil
        notify(inv.id, n[1], n[2])
    end
end

---Brings one online inventory in line with the config (runtime switch).
---@param inv table
---@return boolean changed
function Pocket.reconcile(inv)
    if type(inv) ~= 'table' or inv.type ~= 'player' then return false end
    local P = Pocket.index()
    local updates, slotsChanged = {}, false

    if state.cfg.enabled then
        if not inv.pocket then
            inv.pocket = P
            if (inv.slots or 0) < P then inv.slots = P slotsChanged = true end
        end
        -- a disallowed item already in the slot (a script grew the slots, the blacklist changed): out if there is room
        local data = inv.items[P]
        if data and Pocket.refusal(data.name) then
            local i = firstFree(inv.items, normalLast(inv.slots, P), P)
            if i then
                inv.items[P] = nil
                data.slot = i
                inv.items[i] = data
                updates[#updates + 1] = { item = data, inventory = inv.id }
                updates[#updates + 1] = { item = { slot = P }, inventory = inv.id }
                record('pocket_rehome', { item = data.name, count = data.count, metadata = data.metadata, actor = 0, target = inv.id, extra = { fromSlot = P, toSlot = i, reason = 'blocked' } })
            end
        end
    elseif inv.pocket then
        local data = inv.items[P]
        if (inv.slots or 0) > P then
            -- a script grew the slots past the pocket: the index is a normal slot again
            inv.pocket = nil
        elseif data then
            local i = firstFree(inv.items, normalLast(inv.slots, P), P)
            if i then
                inv.items[P] = nil
                data.slot = i
                inv.items[i] = data
                updates[#updates + 1] = { item = data, inventory = inv.id }
                updates[#updates + 1] = { item = { slot = P }, inventory = inv.id }
                record('pocket_rehome', { item = data.name, count = data.count, metadata = data.metadata, actor = 0, target = inv.id, extra = { fromSlot = P, toSlot = i, reason = 'off' } })
                notify(inv.id, 'inform', L('rw_pocket_moved', 'Your pocket item was moved into your inventory'))
                inv.pocket = nil
                if inv.slots == P then inv.slots = P - 1 slotsChanged = true end
            else
                record('pocket_rehome', { item = data.name, count = data.count, metadata = data.metadata, actor = 0, target = inv.id, severity = 1, extra = { fromSlot = P, parked = true, reason = 'full' } })
                notify(inv.id, 'warning', L('rw_pocket_parked', 'The pocket slot is off — make room and move its item out'))
            end
        else
            inv.pocket = nil
            if inv.slots == P then inv.slots = P - 1 slotsChanged = true end
        end
    end

    Pocket.push(inv.id, inv)
    if slotsChanged then
        TriggerClientEvent('ox_inventory:refreshSlotCount', inv.id, { inventoryId = inv.id, slots = inv.slots })
    end
    if #updates > 0 then
        inv.changed = true
        inv:syncSlotsWithClients(updates, true)
        if server.syncInventory then server.syncInventory(inv) end
    end
    return slotsChanged or #updates > 0
end

local function reconcileAll()
    local Inventory = Inv()
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        local inv = src and Inventory(src)
        if inv and inv.player then
            Pocket.reconcile(inv)
        elseif src then
            Pocket.push(src, nil)
        end
    end
end

-- ═════════════════════════════════════════════════════════════
--  ADMIN · pocket.getConfig / pocket.setConfig (+ serverSettings)
-- ═════════════════════════════════════════════════════════════
local function copyList(t) local o = {} for i = 1, #(t or {}) do o[i] = t[i] end return o end

local function publicKeys(cfg)
    return { enabled = cfg.enabled, safeOnDeath = cfg.safeOnDeath, countWeight = cfg.countWeight, blacklist = copyList(cfg.blacklist) }
end

function Pocket.getConfig()
    local ov = {}
    for k, v in pairs(overrides) do ov[k] = type(v) == 'table' and copyList(v) or v end
    return { keys = publicKeys(state.cfg), defaults = publicKeys(Shared.sanitize(rawConf)), overrides = ov, slot = Pocket.index() }
end

local function sameList(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end

---`{ overrides = { enabled?, safeOnDeath?, countWeight?, blacklist? }, clear = { key, … } }`
---→ validated, persisted (only what differs from config.lua), applied to
---every online player and broadcast.
---@param src number
---@param payload table
function Pocket.setConfig(src, payload)
    payload = type(payload) == 'table' and payload or {}
    local merged = {}
    for k, v in pairs(overrides) do merged[k] = v end

    if type(payload.clear) == 'table' then
        for _, k in ipairs(payload.clear) do
            if KEY_TYPES[k] then merged[k] = nil end
        end
    end
    if type(payload.overrides) == 'table' then
        for k, v in pairs(payload.overrides) do
            local t = KEY_TYPES[k]
            if not t then return false, 'bad_payload' end
            if v == '__clear' then
                merged[k] = nil
            elseif type(v) ~= t then
                return false, 'bad_payload'
            else
                merged[k] = k == 'blacklist' and Shared.cleanList(v) or v
            end
        end
    end

    -- keep only what differs from config.lua
    local defaults = Shared.sanitize(rawConf)
    for k, v in pairs(merged) do
        if (k == 'blacklist' and sameList(v, defaults.blacklist)) or (k ~= 'blacklist' and v == defaults[k]) then merged[k] = nil end
    end

    local before = state.cfg
    overrides = merged
    SetResourceKvp(KVP_KEY, json.encode({ version = 1, updatedAt = os.time(), overrides = overrides }))
    recompute()

    local changed = {}
    for k in pairs(KEY_TYPES) do
        local a, b = before[k], state.cfg[k]
        if (k == 'blacklist' and not sameList(a, b)) or (k ~= 'blacklist' and a ~= b) then changed[k] = { old = a, new = b } end
    end

    if next(changed) then
        reconcileAll()
        record('server_settings_edit', { actor = src, extra = { module = 'pocket', changed = changed } })
    end

    local res = Pocket.getConfig()
    res.changed = changed
    return res
end

CreateThread(function()
    local ok, Admin = pcall(require, 'modules.rwadmin.server')
    if not ok or type(Admin) ~= 'table' or type(Admin.register) ~= 'function' then return end
    Admin.register('pocket.getConfig', function() return Pocket.getConfig() end, {})
    Admin.register('pocket.setConfig', function(src, p) return Pocket.setConfig(src, p) end, { write = true, audit = 'server_settings_edit' })
end)

-- ═════════════════════════════════════════════════════════════
--  EXPORTS · client sync
-- ═════════════════════════════════════════════════════════════

---exports.ox_inventory:GetPocketSlot(src) → { slot, item?, enabled, safe, protected } | nil
exports('GetPocketSlot', function(src)
    local inv = Inv()(tonumber(src))
    if not inv or inv.type ~= 'player' then return nil end
    local p = Pocket.slotOf(inv)
    local data = p and inv.items[p]
    return {
        slot = p or Pocket.index(),
        item = data and table.clone(data) or nil,
        enabled = state.cfg.enabled,
        safe = state.cfg.enabled and state.cfg.safeOnDeath,
        protected = Pocket.protectedSlot(inv) ~= nil,
    }
end)

---exports.ox_inventory:IsPocketSafe(src) → true when the pocket holds an item that survives death right now.
exports('IsPocketSafe', function(src)
    local inv = Inv()(tonumber(src))
    return inv ~= nil and Pocket.protectedSlot(inv) ~= nil
end)

exports('GetPocketConfig', function() return publicKeys(state.cfg) end)
exports('SetPocketConfig', function(payload) return Pocket.setConfig(0, type(payload) == 'table' and payload or {}) end)

lib.callback.register('ox_inventory:rwPocketSync', function(source)
    return Pocket.publicState(Inv()(source))
end)

return Pocket
