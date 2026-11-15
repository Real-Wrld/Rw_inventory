--  REALWRLD Software® · ox_inventory · Log registry (server)
-- ═════════════════════════════════════════════════════════════
--
--  Server-authoritative log of every inventory business event
--  (design/admin-logs.md §2, §4, §5). Rows go to an in-memory ring
--  (instant queries) and to MySQL `ox_inventory_logs` in batches.
--  This module depends on nothing inventory-side: the inventory
--  module hands it a resolver with Log.bindInventory(Inventory).
-- ═════════════════════════════════════════════════════════════

if not lib then return end

local config = require 'modules.rwconfig.shared'.Get()
local cfg = type(config.Logs) == 'table' and config.Logs or {}

local Log = {}
Log.dbOk = false
Log.ready = false
Log.inserted, Log.dropped, Log.failedFlushes = 0, 0, 0
Log.lastDbError = nil

-- The admin server settings (KVP, restart semantics) win over config.lua.
local kvpRing
do
    local raw = GetResourceKvpString('rw:serverSettings')
    local ok, decoded = pcall(json.decode, raw or '')
    if ok and type(decoded) == 'table' and type(decoded.values) == 'table' then kvpRing = tonumber(decoded.values['logs.ringSize']) end
end
local RING_SIZE = math.floor(kvpRing or tonumber(cfg.ringSize) or 2000)
if RING_SIZE < 500 then RING_SIZE = 500 elseif RING_SIZE > 5000 then RING_SIZE = 5000 end
local FLUSH_MS = tonumber(cfg.flushMs) or 2000
local FLUSH_ROWS = tonumber(cfg.flushRows) or 50
local QUEUE_MAX = 5000
local EXTRA_MAX_BYTES = 60000
local SNAPSHOT_CAP = 100
local NAME_MAX, LABEL_MAX = 64, 100
local EXPORT_MAX_ROWS = tonumber(cfg.export and cfg.export.maxRows) or 5000
local EXPORT_MAX_BYTES = 4 * 1024 * 1024

-- ─── action catalogue (§2.3) ─────────────────────────────────
-- key = { level, severity, group }
local ACTIONS = {
    move = { 1, 0, 'movement' }, stack = { 1, 0, 'movement' }, swap = { 1, 0, 'movement' }, reorder = { 3, 0, 'movement' },
    give = { 1, 1, 'movement' }, drop = { 1, 1, 'movement' }, pickup = { 1, 1, 'movement' }, drop_expired = { 1, 0, 'movement' },
    add = { 1, 0, 'movement' }, remove = { 1, 0, 'movement' },
    -- pocket slot (modules/rwpocket): in / out of it, kept on death / clear / confiscation, moved out when turned off
    pocket_in = { 1, 0, 'movement' }, pocket_out = { 1, 0, 'movement' }, pocket_kept = { 1, 1, 'movement' }, pocket_rehome = { 1, 1, 'movement' },
    buy = { 1, 1, 'trade' }, sell = { 1, 1, 'trade' }, craft = { 1, 0, 'trade' },
    use = { 2, 0, 'use' },
    open_stash = { 2, 0, 'open' }, open_trunk = { 2, 0, 'open' }, open_glovebox = { 2, 0, 'open' }, open_drop = { 2, 0, 'open' },
    open_container = { 2, 0, 'open' }, open_dumpster = { 2, 0, 'open' }, open_evidence = { 2, 0, 'open' }, open_shop = { 2, 0, 'open' },
    open_crafting = { 2, 0, 'open' }, open_player = { 1, 2, 'open' }, inspect = { 1, 2, 'open' },
    metadata = { 2, 0, 'item' }, durability = { 2, 0, 'item' }, decay = { 1, 0, 'item' },
    weapon_load = { 2, 0, 'weapon' }, weapon_unload = { 2, 0, 'weapon' }, attach = { 2, 0, 'weapon' }, detach = { 2, 0, 'weapon' },
    throw = { 1, 0, 'weapon' }, ammo = { 3, 0, 'weapon' }, melee = { 3, 0, 'weapon' },
    clothing_unequip = { 2, 0, 'clothing' }, clothing_equip = { 2, 0, 'clothing' },
    admin_give = { 1, 2, 'admin' }, admin_remove = { 1, 2, 'admin' }, admin_set = { 1, 2, 'admin' }, admin_clear = { 1, 2, 'admin' },
    admin_confiscate = { 1, 2, 'admin' }, admin_return = { 1, 2, 'admin' }, admin_view = { 1, 1, 'admin' }, admin_saveinv = { 2, 1, 'admin' },
    evidence_clear = { 1, 2, 'admin' }, admin_teleport = { 1, 1, 'admin' },
    settings_lock = { 1, 3, 'settings' }, settings_unlock = { 1, 2, 'settings' }, settings_apply = { 1, 2, 'settings' },
    webhook_edit = { 1, 3, 'system' }, webhook_test = { 1, 1, 'system' }, webhook_error = { 1, 2, 'system' },
    propmap_edit = { 1, 2, 'system' }, server_settings_edit = { 1, 3, 'system' }, logs_export = { 1, 1, 'system' }, admin_panel = { 2, 0, 'system' },
    exploit = { 1, 3, 'security' },
    player_join = { 2, 0, 'system' },
}
Log.ACTIONS = ACTIONS

local ALIASES = {
    open = { 'open_stash', 'open_trunk', 'open_glovebox', 'open_drop', 'open_container', 'open_dumpster', 'open_evidence', 'open_shop', 'open_crafting', 'open_player' },
    admin = { 'admin_give', 'admin_remove', 'admin_set', 'admin_clear', 'admin_confiscate', 'admin_return', 'admin_view', 'admin_saveinv', 'evidence_clear', 'admin_teleport' },
    weapon = { 'weapon_load', 'weapon_unload', 'attach', 'detach', 'throw', 'ammo', 'melee' },
    settings = { 'settings_lock', 'settings_unlock', 'settings_apply' },
    system = { 'webhook_edit', 'webhook_test', 'webhook_error', 'propmap_edit', 'server_settings_edit', 'logs_export', 'admin_panel' },
    trade = { 'buy', 'sell', 'craft' },
    movement = { 'move', 'stack', 'swap', 'reorder', 'give', 'drop', 'pickup', 'drop_expired', 'add', 'remove', 'pocket_in', 'pocket_out', 'pocket_kept', 'pocket_rehome' },
    pocket = { 'pocket_in', 'pocket_out', 'pocket_kept', 'pocket_rehome' },
    drops = { 'drop', 'pickup', 'drop_expired' },
    security = { 'exploit' },
    clothing = { 'clothing_unequip', 'clothing_equip' },
    receive = { 'give' },
}
Log.ALIASES = ALIASES

-- ─── level ──────────────────────────────────────────────────
function Log.refreshLevel()
    local S = server and server.RWSettings
    local enabled, level
    if S then
        enabled = S.get('logs.enabled')
        level = S.get('logs.level')
    end
    if enabled == nil then enabled = cfg.enabled ~= false end
    if level == nil then level = tonumber(cfg.level) end
    if level == nil then level = tonumber(server and server.loglevel) or tonumber(GetConvar('inventory:loglevel', '1')) or 1 end
    Log.level = enabled and math.floor(level) or 0
    return Log.level
end
Log.refreshLevel()

function Log.enabled(action)
    local def = ACTIONS[action]
    return def ~= nil and def[1] <= Log.level
end

-- ─── state ──────────────────────────────────────────────────
local bootTime = os.time()
local function base36(n)
    local digits = '0123456789abcdefghijklmnopqrstuvwxyz'
    if n == 0 then return '0' end
    local out = {}
    while n > 0 do
        local d = n % 36
        out[#out + 1] = digits:sub(d + 1, d + 1)
        n = n // 36
    end
    return string.reverse(table.concat(out))
end
local BOOT36 = base36(bootTime)
local seq = 0
local ring, head, ringCount = {}, 1, 0
local queue = {}
local flushTimer = nil
local sinks = {}
local warned = {}
local lastDropWarn = 0
local Inventory = nil -- bound resolver

local function warnOnce(key, msg)
    key = tostring(key) -- a nil action indexed the table with nil and threw in the caller
    if warned[key] then return end
    warned[key] = true
    lib.print.warn(msg or ('[rw-logs] unknown log action "%s"'):format(tostring(key)))
end

local function nowMs()
    local ok, micro = pcall(function() return os.microtime() end)
    local sub = 0
    if ok and type(micro) == 'number' then sub = math.floor(micro / 1000) % 1000 end
    local ms = os.time() * 1000.0 + sub   -- float math: fengari (harness) has 32-bit integers; CFX returns an integer
    return math.tointeger(ms) or ms
end
Log.now = nowMs

local function cap(s, n)
    if type(s) ~= 'string' then s = tostring(s) end
    if #s > n then return s:sub(1, n) end
    return s
end

-- ─── identity (§2.5) ────────────────────────────────────────
local identityCache = {}

local function identifiersFor(src)
    return {
        license = GetPlayerIdentifierByType(src, 'license'),
        license2 = GetPlayerIdentifierByType(src, 'license2'),
        discord = GetPlayerIdentifierByType(src, 'discord'),
        steam = GetPlayerIdentifierByType(src, 'steam'),
        fivem = GetPlayerIdentifierByType(src, 'fivem'),
    }
end

function Log.resolvePlayer(src)
    src = tonumber(src)
    if not src or src <= 0 then return { source = src == 0 and 0 or nil, name = src == 0 and 'console' or nil } end
    local c = identityCache[src]
    if not c then c = { identifiers = identifiersFor(src) } identityCache[src] = c end
    local inv = Inventory and Inventory(src)
    local out = { source = src, name = GetPlayerName(src) or c.name, identifiers = c.identifiers }
    if inv and inv.player then
        out.charId = inv.owner and tostring(inv.owner) or nil
        out.job = inv.player.groups and next(inv.player.groups) or nil
        out.name = inv.player.name or out.name
    end
    if out.name then out.name = cap(out.name, NAME_MAX) end
    c.name = out.name
    return out
end

AddEventHandler('playerDropped', function()
    identityCache[source] = nil
end)

local function identity(v)
    local tv = type(v)
    if tv == 'nil' then return nil end
    if tv == 'number' then return Log.resolvePlayer(v) end
    if tv == 'string' then
        local n = tonumber(v)
        if n then return Log.resolvePlayer(n) end
        if v == 'console' then return { source = 0, name = 'console' } end
        return { resource = cap(v, NAME_MAX) }
    end
    if tv == 'table' then
        if v.source or v.name or v.identifiers or v.resource then return v end
        if v.id and v.player then return Log.resolvePlayer(v.id) end
    end
    return nil
end

local function primaryId(id)
    local ids = id and id.identifiers
    if not ids then return nil end
    return ids.license2 or ids.license or ids.fivem or ids.discord
end

local function discordOf(id)
    local ids = id and id.identifiers
    return ids and ids.discord or nil
end

-- ─── refs / metadata / snapshots ────────────────────────────
function Log.bindInventory(mod) Inventory = mod end

---A LOADED inventory only. `Inventory(id)` on a 'trunk…' / 'glove…' /
---'evidence-…' id scans the vehicles, awaits a client callback or creates
---the locker — from inside a logging call.
local function peek(id)
    if not Inventory then return nil end
    if type(Inventory) == 'table' and Inventory.Peek then return Inventory.Peek(id) end
    return Inventory(id)
end

function Log.invRef(inv)
    local t = type(inv)
    if t == 'nil' then return nil end
    if t == 'string' then
        local live = peek(inv)
        if live and live.id then inv = live else return { id = cap(inv, LABEL_MAX), type = inv:match('^(%a+)[:%-]') or 'symbolic' } end
    elseif t == 'number' then
        local live = peek(inv)
        if live and live.id then inv = live else return { id = tostring(inv), type = 'player' } end
    end
    if type(inv) ~= 'table' or inv.id == nil then return nil end
    if not inv.slots and not inv.items and Inventory then
        local live = peek(inv.id)
        if live and live.id then
            return { id = tostring(live.id), type = live.type or inv.type, owner = live.owner or nil, label = live.label and cap(live.label, LABEL_MAX) or nil }
        end
    end
    local id = tostring(inv.id)
    if inv.type == 'shop' and not id:find('^shop:') then id = 'shop:' .. id end
    return {
        id = cap(id, LABEL_MAX),
        type = inv.type or 'unknown',
        owner = inv.owner ~= nil and inv.owner ~= false and tostring(inv.owner) or (inv.owner == false and false or nil),
        label = inv.label and cap(tostring(inv.label), LABEL_MAX) or nil,
    }
end

local TRIM_KEYS = { 'serial', 'durability', 'ammo', 'type', 'label', 'container', 'degrade' }

function Log.trimMetadata(meta)
    if type(meta) ~= 'table' then return nil end
    local out, any = {}, false
    for i = 1, #TRIM_KEYS do
        local k = TRIM_KEYS[i]
        local v = meta[k]
        if v ~= nil and (type(v) == 'string' or type(v) == 'number' or type(v) == 'boolean') then
            out[k] = type(v) == 'string' and cap(v, LABEL_MAX) or v
            any = true
        end
    end
    if type(meta.components) == 'table' then out.components = #meta.components any = true end
    return any and out or nil
end

function Log.snapshot(inv, capN)
    capN = capN or SNAPSHOT_CAP
    local items = {}
    local n = 0
    local src = inv and inv.items
    if type(src) ~= 'table' then return items end
    for slot, v in pairs(src) do
        if n >= capN then items.truncated = true break end
        n = n + 1
        items[#items + 1] = { slot = v.slot or slot, name = v.name, count = v.count, metadata = Log.trimMetadata(v.metadata) }
    end
    return items
end

local function normCoords(c)
    if not c then return nil end
    local x, y, z = c.x, c.y, c.z
    if type(x) ~= 'number' then return nil end
    return { x = math.floor(x * 100 + 0.5) / 100, y = math.floor((y or 0) * 100 + 0.5) / 100, z = math.floor((z or 0) * 100 + 0.5) / 100 }
end

local function keysOf(t)
    local k = {}
    for key in pairs(t) do k[#k + 1] = tostring(key) end
    table.sort(k)
    return k
end

local function capJson(tbl, max)
    local ok, s = pcall(json.encode, tbl)
    if not ok then return json.encode({ error = 'encode' }) end
    if #s > max then s = json.encode({ truncated = true, keys = keysOf(tbl), bytes = #s }) end
    return s
end

-- ─── flush (§4.3) ───────────────────────────────────────────
-- Parameter arrays must not contain holes (nil breaks the msgpack array →
-- oxmysql hand-off), so every nullable column is bound as NULLIF(?, <sentinel>)
-- and the row always carries 33 values. Sentinels: '' for strings, -1 for
-- the source ids, INT_MIN for count, -1e9 for coordinates.
local S_STR, S_SRC, S_INT, S_FLOAT = '', -1, -2147483648, -1000000000
local INSERT = [[INSERT INTO ox_inventory_logs
 (uid, ts, action, severity, item, count, from_id, from_type, from_owner, from_label, to_id, to_type, to_owner, to_label,
  actor_src, actor_name, actor_char, actor_identifier, actor_discord, actor_job, actor_resource,
  target_src, target_name, target_char, target_identifier, target_discord, x, y, z, metadata, actor_ids, target_ids, extra)
 VALUES (?, ?, ?, ?, NULLIF(?, ''), NULLIF(?, -2147483648), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''),
  NULLIF(?, -1), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''),
  NULLIF(?, -1), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, -1000000000), NULLIF(?, -1000000000), NULLIF(?, -1000000000), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''))]]
Log.INSERT = INSERT

local function str(v) if v == nil or v == false then return S_STR end return tostring(v) end
-- NaN / inf / out-of-column values made the driver reject the WHOLE batch,
-- and the batch was retried at the head of the queue forever: one bad row
-- ended database logging for the rest of the uptime.
local INT_MAX = 2147483647
local function num(v, s, lo, hi)
    if type(v) ~= 'number' or v ~= v or v == math.huge or v == -math.huge then return s end
    if lo and v < lo then return lo end
    if hi and v > hi then return hi end
    return v
end

local function rowOf(e)
    local f, t, a, g = e.from, e.to, e.actor, e.target
    return {
        e.uid, e.ts, e.action, num(e.severity, 0, 0, 255), str(e.item), num(e.count, S_INT, -INT_MAX, INT_MAX),
        str(f and f.id), str(f and f.type), str(f and f.owner), str(f and f.label),
        str(t and t.id), str(t and t.type), str(t and t.owner), str(t and t.label),
        num(a and a.source, S_SRC), str(a and a.name), str(a and a.charId), str(primaryId(a)), str(discordOf(a)), str(a and a.job), str(a and a.resource),
        num(g and g.source, S_SRC), str(g and g.name), str(g and g.charId), str(primaryId(g)), str(discordOf(g)),
        num(e.coords and e.coords.x, S_FLOAT), num(e.coords and e.coords.y, S_FLOAT), num(e.coords and e.coords.z, S_FLOAT),
        e.metadata and json.encode(e.metadata) or S_STR, a and a.identifiers and json.encode(a.identifiers) or S_STR,
        g and g.identifiers and json.encode(g.identifiers) or S_STR, e.extra and capJson(e.extra, EXTRA_MAX_BYTES) or S_STR,
    }
end
Log.rowOf = rowOf

local flushGen = 0
local function armFlush(ms)
    if flushTimer then return end
    flushGen = flushGen + 1
    local gen = flushGen
    flushTimer = gen
    SetTimeout(ms or FLUSH_MS, function()
        -- an immediate flush (50 rows) may have run meanwhile: this timer is stale then
        if flushTimer ~= gen then return end
        Log.flush()
    end)
end

local function requeue(batch)
    for i = #batch, 1, -1 do table.insert(queue, 1, batch[i]) end
    while #queue > QUEUE_MAX do table.remove(queue, 1) Log.dropped = Log.dropped + 1 end
end

local function doInsert(rows)
    local ok, err = pcall(MySQL.prepare.await, INSERT, rows)
    return ok, err
end

function Log.flush(sync)
    flushTimer = nil
    if not Log.ready or #queue == 0 then return end
    local batch = queue
    queue = {}
    local rows = {}
    for i = 1, #batch do rows[i] = rowOf(batch[i]) end
    local function run()
        local ok, err = doInsert(rows)
        if ok then
            Log.dbOk = true
            Log.inserted = Log.inserted + #rows
        else
            Log.dbOk = false
            Log.failedFlushes = Log.failedFlushes + 1
            Log.consecutiveFailures = (Log.consecutiveFailures or 0) + 1
            Log.lastDbError = tostring(err)
            if Log.failedFlushes % 10 == 1 then
                lib.print.error(('[rw-logs] insert failed (%s rows kept for retry): %s'):format(#batch, err))
            end
            -- A batch the database keeps refusing (a row it will never
            -- take) is dropped after three tries instead of poisoning
            -- every later flush; a database that is merely down keeps
            -- failing on fresh batches and those are retried as before.
            if Log.consecutiveFailures >= 3 and Log.lastFailedBatch == batch then
                Log.dropped = Log.dropped + #batch
                Log.lastFailedBatch = nil
                lib.print.error(('[rw-logs] %s rows dropped after 3 refused inserts: %s'):format(#batch, err))
            else
                Log.lastFailedBatch = batch
                requeue(batch)
            end
            armFlush(10000)
        end
    end
    if sync then run() else CreateThread(run) end
end

-- ─── record (§2.1) ──────────────────────────────────────────
function Log.record(action, rec)
    local def = ACTIONS[action]
    if not def then warnOnce(action) return nil end
    rec = rec or {}
    if (rec.level or def[1]) > Log.level then return nil end

    -- multi-line form (§2.6b)
    if type(rec.lines) == 'table' and rec.lines[1] then
        local first
        local shopLabel = type(rec.from) == 'table' and rec.from.label or nil
        if action == 'sell' and type(rec.to) == 'table' then shopLabel = rec.to.label end
        for i = 1, #rec.lines do
            local line = rec.lines[i]
            local cnt = tonumber(line.count) or 0
            local e = Log.record(action, {
                item = line.item, count = line.count, metadata = line.metadata,
                from = rec.from, to = rec.to, actor = rec.actor, target = rec.target, coords = rec.coords,
                extra = {
                    shopType = rec.shopType, shopId = rec.shopId, shop = shopLabel,
                    price = (cnt > 0 and line.price) and (line.price // cnt) or line.price, totalPrice = line.price, currency = line.currency,
                    payment = rec.payment, payTo = rec.payTo,
                    basketId = first and first.extra.basketId or nil, lines = #rec.lines, totals = (i == 1) and rec.totals or nil,
                },
            })
            if e and not first then first = e e.extra.basketId = 'B' .. e.uid end
        end
        return first
    end

    local itemName = rec.item
    if type(itemName) == 'table' then itemName = itemName.name end
    if itemName ~= nil then itemName = cap(tostring(itemName), NAME_MAX) end

    local entry = {
        ts = nowMs(),
        action = action,
        severity = rec.severity or def[2],
        item = itemName,
        count = rec.count ~= nil and tonumber(rec.count) or nil,
        metadata = Log.trimMetadata(rec.metadata),
        from = Log.invRef(rec.from),
        to = Log.invRef(rec.to),
        actor = identity(rec.actor),
        target = identity(rec.target),
        coords = normCoords(rec.coords),
        extra = rec.extra,
    }
    if entry.actor == nil and rec.actor == nil then
        local res = GetInvokingResource()
        if res and res ~= (shared and shared.resource) then entry.actor = { resource = res } end
    end

    seq = seq + 1
    entry.seq = seq
    entry.uid = ('%s-%d'):format(BOOT36, seq)

    ring[head] = entry
    head = head % RING_SIZE + 1
    if ringCount < RING_SIZE then ringCount = ringCount + 1 end

    queue[#queue + 1] = entry
    if #queue > QUEUE_MAX then
        table.remove(queue, 1)
        Log.dropped = Log.dropped + 1
        local now = GetGameTimer()
        if now - lastDropWarn > 60000 then
            lastDropWarn = now
            lib.print.warn(('[rw-logs] queue full, dropped %d rows so far'):format(Log.dropped))
        end
    end
    if Log.ready then
        if #queue >= FLUSH_ROWS then Log.flush() else armFlush(FLUSH_MS) end
    end

    for i = 1, #sinks do
        local ok, err = pcall(sinks[i], entry)
        if not ok then lib.print.error(('[rw-logs] sink failed: %s'):format(err)) end
    end
    return entry
end

function Log.addSink(fn) sinks[#sinks + 1] = fn end

-- ─── event bridge (§2.6c) ───────────────────────────────────
local EVENT_ACTION = { drop_pickup = 'pickup', drop_config = 'server_settings_edit', drop_propmap = 'propmap_edit' }

function Log.fromEvent(p)
    if type(p) ~= 'table' then return end
    local action = EVENT_ACTION[p.action] or (ACTIONS[p.action] and p.action)
    if not action then warnOnce(p.action) return nil end
    local extra = p.extra or {}
    if p.action == 'drop_config' then extra.module = 'drops' end
    if p.action == 'drop_pickup' and not extra.dropId then extra.dropId = p.fromInventory end
    local actor = p.source
    if actor == nil then actor = GetInvokingResource() end
    return Log.record(action, {
        item = p.item, count = p.count, metadata = p.metadata,
        from = p.fromInventory and { id = p.fromInventory, type = p.fromType or 'drop' } or nil,
        to = p.toInventory and { id = p.toInventory, type = p.toType or 'player' } or nil,
        actor = actor, coords = p.coords, extra = extra, severity = p.severity,
    })
end

AddEventHandler('ox_inventory:rwLog', function(p) Log.fromEvent(p) end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
AddEventHandler('ox_inventory:oxlynLog', function(p) Log.fromEvent(p) end)

-- ─── ring helpers ───────────────────────────────────────────
local function ringIter()
    -- newest → oldest
    local i = 0
    return function()
        if i >= ringCount then return nil end
        i = i + 1
        local idx = head - i
        if idx < 1 then idx = idx + RING_SIZE end
        return ring[idx]
    end
end

local function ringOldestTs()
    if ringCount == 0 then return math.huge end
    local idx = head - ringCount
    if idx < 1 then idx = idx + RING_SIZE end
    return ring[idx].ts
end

function Log.tail(n)
    n = n or 50
    local out = {}
    for e in ringIter() do
        if #out >= n then break end
        out[#out + 1] = e
    end
    return out
end

-- ─── filter sanitiser (§4.5) ────────────────────────────────
local function escapeLike(s)
    return (s:gsub('[\\%%_]', function(c) return '\\' .. c end))
end

local function strField(v, max)
    if type(v) ~= 'string' then return nil end
    v = v:gsub('^%s+', ''):gsub('%s+$', '')
    if v == '' then return nil end
    return cap(v, max)
end

local function intField(v)
    v = tonumber(v)
    if not v then return nil end
    return math.floor(v)
end

local function expandActions(list)
    local set, out, receive = {}, {}, false
    for i = 1, #list do
        local a = list[i]
        if a == 'receive' then
            receive = true
            if not set.give then set.give = true out[#out + 1] = 'give' end
        elseif ACTIONS[a] then
            if not set[a] then set[a] = true out[#out + 1] = a end
        elseif ALIASES[a] then
            for _, k in ipairs(ALIASES[a]) do if not set[k] then set[k] = true out[#out + 1] = k end end
        else
            return nil
        end
    end
    return out, set, receive
end
Log.expandActions = expandActions

function Log.sanitizeFilter(f)
    if type(f) ~= 'table' then f = {} end
    local out = {}
    local now = nowMs()
    out.to = intField(f.to) or now
    out.from = intField(f.from) or (out.to - 86400000)
    if out.from > out.to then out.from, out.to = out.to, out.from end
    local hf, ht = intField(f.hourFrom), intField(f.hourTo)
    if hf and ht and hf >= 0 and hf <= 23 and ht >= 0 and ht <= 23 then out.hourFrom, out.hourTo = hf, ht end
    if f.actions ~= nil then
        if type(f.actions) ~= 'table' then return nil, 'bad_payload' end
        if #f.actions > 64 then return nil, 'too_many' end
        if #f.actions > 0 then
            local list, set, receive = expandActions(f.actions)
            if not list then return nil, 'bad_payload' end
            out.actions, out.actionSet, out.receive = list, set, receive
        end
    end
    local sev = intField(f.severityMin)
    if sev and sev > 0 then out.severityMin = math.min(sev, 3) end
    if f.items ~= nil then
        if type(f.items) ~= 'table' then return nil, 'bad_payload' end
        if #f.items > 64 then return nil, 'too_many' end
        local exact, globs = {}, {}
        for i = 1, #f.items do
            local it = strField(f.items[i], NAME_MAX)
            if it then
                if it:sub(-1) == '*' then globs[#globs + 1] = it:sub(1, -2) else exact[#exact + 1] = it end
            end
        end
        if #exact > 0 or #globs > 0 then out.items = { exact = exact, globs = globs } end
    end
    out.actorSearch = strField(f.actorSearch, NAME_MAX)
    out.targetSearch = strField(f.targetSearch, NAME_MAX)
    out.playerSearch = strField(f.playerSearch, NAME_MAX)
    if out.receive and out.playerSearch then out.targetSearch = out.targetSearch or out.playerSearch out.playerSearch = nil end
    out.inventoryId = strField(f.inventoryId, LABEL_MAX)
    -- exact primary identifier (actor OR target) — the Players page timeline
    out.identifier = strField(f.identifier, NAME_MAX)
    out.text = strField(f.text, NAME_MAX)
    if out.text and (out.to - out.from) > 31 * 86400000.0 then return nil, 'bad_payload' end
    out.page = math.max(intField(f.page) or 1, 1)
    out.pageSize = math.min(math.max(intField(f.pageSize) or 50, 1), 100)
    out.sort = f.sort == 'ts_asc' and 'ts_asc' or 'ts_desc'
    out.source = (f.source == 'ring' or f.source == 'db') and f.source or 'auto'
    if (out.page - 1) * out.pageSize > 5000 then return nil, 'bad_payload' end
    return out
end

-- ─── ring predicate ─────────────────────────────────────────
local function idMatches(id, s, num)
    if not id then return false end
    local sl = s:lower()
    if id.name and id.name:lower():find(sl, 1, true) then return true end
    local pid = primaryId(id)
    if pid and pid:lower():find(sl, 1, true) then return true end
    if id.charId and tostring(id.charId):lower():find(sl, 1, true) then return true end
    if id.identifiers and id.identifiers.discord == s then return true end
    if num and id.source == num then return true end
    return false
end

local function compilePredicate(f)
    local checks = {}
    checks[#checks + 1] = function(e) return e.ts >= f.from and e.ts <= f.to end
    if f.hourFrom then
        checks[#checks + 1] = function(e)
            local h = tonumber(os.date('%H', e.ts // 1000))
            if f.hourFrom <= f.hourTo then return h >= f.hourFrom and h <= f.hourTo end
            return h >= f.hourFrom or h <= f.hourTo
        end
    end
    if f.actionSet then checks[#checks + 1] = function(e) return f.actionSet[e.action] == true end end
    if f.severityMin then checks[#checks + 1] = function(e) return e.severity >= f.severityMin end end
    if f.items then
        local exact = {}
        for _, n in ipairs(f.items.exact) do exact[n:lower()] = true end
        local globs = {}
        for _, g in ipairs(f.items.globs) do globs[#globs + 1] = g:lower() end
        checks[#checks + 1] = function(e)
            if not e.item then return false end
            local n = e.item:lower()
            if exact[n] then return true end
            for i = 1, #globs do if n:sub(1, #globs[i]) == globs[i] then return true end end
            return false
        end
    end
    if f.actorSearch then local s, num = f.actorSearch, tonumber(f.actorSearch) checks[#checks + 1] = function(e) return idMatches(e.actor, s, num) end end
    if f.targetSearch then local s, num = f.targetSearch, tonumber(f.targetSearch) checks[#checks + 1] = function(e) return idMatches(e.target, s, num) end end
    if f.playerSearch then local s, num = f.playerSearch, tonumber(f.playerSearch) checks[#checks + 1] = function(e) return idMatches(e.actor, s, num) or idMatches(e.target, s, num) end end
    if f.inventoryId then
        local id = f.inventoryId
        checks[#checks + 1] = function(e) return (e.from and e.from.id == id) or (e.to and e.to.id == id) end
    end
    if f.identifier then
        local pid = f.identifier
        checks[#checks + 1] = function(e) return primaryId(e.actor) == pid or primaryId(e.target) == pid end
    end
    if f.text then
        local s = f.text:lower()
        checks[#checks + 1] = function(e)
            if e.item and e.item:lower():find(s, 1, true) then return true end
            if e.from and e.from.label and e.from.label:lower():find(s, 1, true) then return true end
            if e.to and e.to.label and e.to.label:lower():find(s, 1, true) then return true end
            if e.extra then local ok, js = pcall(json.encode, e.extra) if ok and js:lower():find(s, 1, true) then return true end end
            return false
        end
    end
    return function(e)
        for i = 1, #checks do if not checks[i](e) then return false end end
        return true
    end
end
Log.compilePredicate = compilePredicate

local function queryRing(f)
    local pred = compilePredicate(f)
    local matches = {}
    for e in ringIter() do
        if pred(e) then matches[#matches + 1] = e end
    end
    if f.sort == 'ts_asc' then
        local rev = {}
        for i = #matches, 1, -1 do rev[#rev + 1] = matches[i] end
        matches = rev
    end
    local rows = {}
    local startI = (f.page - 1) * f.pageSize + 1
    for i = startI, math.min(#matches, startI + f.pageSize - 1) do rows[#rows + 1] = matches[i] end
    return rows, #matches
end

-- ─── SQL builder (§4.5) ─────────────────────────────────────
local SELECT_COLS = 'id, uid, ts, action, severity, item, count, from_id, from_type, from_owner, from_label, to_id, to_type, to_owner, to_label, actor_src, actor_name, actor_char, actor_identifier, actor_discord, actor_job, actor_resource, target_src, target_name, target_char, target_identifier, target_discord, x, y, z, metadata, actor_ids, target_ids, extra'

local function placeholders(n)
    local t = {}
    for i = 1, n do t[i] = '?' end
    return table.concat(t, ',')
end

local function identityClause(prefix, s, params)
    local like = '%' .. escapeLike(s) .. '%'
    local num = tonumber(s)
    local sql = ('(%s_name LIKE ? ESCAPE \'\\\\\' OR %s_identifier LIKE ? ESCAPE \'\\\\\' OR %s_char LIKE ? ESCAPE \'\\\\\' OR %s_discord = ?'):format(prefix, prefix, prefix, prefix)
    params[#params + 1] = like
    params[#params + 1] = like
    params[#params + 1] = like
    params[#params + 1] = 'discord:' .. s
    if num and num == math.floor(num) then
        sql = sql .. (' OR %s_src = ?'):format(prefix)
        params[#params + 1] = num
    end
    return sql .. ')'
end

function Log.buildWhere(f)
    local where = { 'ts >= ? AND ts <= ?' }
    local params = { f.from, f.to }
    if f.hourFrom then
        where[#where + 1] = 'AND HOUR(FROM_UNIXTIME(ts / 1000)) BETWEEN ? AND ?'
        params[#params + 1] = f.hourFrom
        params[#params + 1] = f.hourTo
    end
    if f.actions then
        where[#where + 1] = 'AND action IN (' .. placeholders(#f.actions) .. ')'
        for i = 1, #f.actions do params[#params + 1] = f.actions[i] end
    end
    if f.severityMin then
        where[#where + 1] = 'AND severity >= ?'
        params[#params + 1] = f.severityMin
    end
    if f.items then
        local parts = {}
        if #f.items.exact > 0 then
            parts[#parts + 1] = 'item IN (' .. placeholders(#f.items.exact) .. ')'
            for i = 1, #f.items.exact do params[#params + 1] = f.items.exact[i] end
        end
        for i = 1, #f.items.globs do
            parts[#parts + 1] = 'item LIKE ? ESCAPE \'\\\\\''
            params[#params + 1] = escapeLike(f.items.globs[i]) .. '%'
        end
        where[#where + 1] = 'AND (' .. table.concat(parts, ' OR ') .. ')'
    end
    if f.actorSearch then where[#where + 1] = 'AND ' .. identityClause('actor', f.actorSearch, params) end
    if f.targetSearch then where[#where + 1] = 'AND ' .. identityClause('target', f.targetSearch, params) end
    if f.playerSearch then
        local a = identityClause('actor', f.playerSearch, params)
        local t = identityClause('target', f.playerSearch, params)
        where[#where + 1] = 'AND (' .. a .. ' OR ' .. t .. ')'
    end
    if f.inventoryId then
        where[#where + 1] = 'AND (from_id = ? OR to_id = ?)'
        params[#params + 1] = f.inventoryId
        params[#params + 1] = f.inventoryId
    end
    if f.identifier then
        where[#where + 1] = 'AND (actor_identifier = ? OR target_identifier = ?)'
        params[#params + 1] = f.identifier
        params[#params + 1] = f.identifier
    end
    if f.text then
        local like = '%' .. escapeLike(f.text) .. '%'
        where[#where + 1] = 'AND (item LIKE ? ESCAPE \'\\\\\' OR from_label LIKE ? ESCAPE \'\\\\\' OR to_label LIKE ? ESCAPE \'\\\\\' OR extra LIKE ? ESCAPE \'\\\\\')'
        for _ = 1, 4 do params[#params + 1] = like end
    end
    return table.concat(where, ' '), params
end

local function hydrate(r)
    local function dec(s) if type(s) ~= 'string' or s == '' then return nil end local ok, v = pcall(json.decode, s) return ok and v or nil end
    local e = {
        id = r.id, uid = r.uid, ts = tonumber(r.ts), action = r.action, severity = tonumber(r.severity) or 0,
        item = r.item, count = r.count,
        metadata = dec(r.metadata), extra = dec(r.extra),
    }
    if r.from_id then e.from = { id = r.from_id, type = r.from_type, owner = r.from_owner, label = r.from_label } end
    if r.to_id then e.to = { id = r.to_id, type = r.to_type, owner = r.to_owner, label = r.to_label } end
    if r.actor_src or r.actor_name or r.actor_resource or r.actor_identifier then
        e.actor = { source = r.actor_src, name = r.actor_name, charId = r.actor_char, job = r.actor_job, resource = r.actor_resource, identifiers = dec(r.actor_ids) }
    end
    if r.target_src or r.target_name or r.target_identifier then
        e.target = { source = r.target_src, name = r.target_name, charId = r.target_char, identifiers = dec(r.target_ids) }
    end
    if r.x then e.coords = { x = r.x, y = r.y, z = r.z } end
    return e
end

-- Query caches keyed by the request (time bounds in ms included): every
-- distinct request added an entry that was never hit again, so they are
-- wiped past a size instead of growing for the whole uptime.
local cacheSizes = setmetatable({}, { __mode = 'k' })
local CACHE_MAX = 200
local function cacheInsert(cache, key, value)
    local n = (cacheSizes[cache] or 0) + 1
    if n > CACHE_MAX then
        table.wipe(cache)
        n = 1
    end
    cacheSizes[cache] = n
    cache[key] = value
end

local countCache = {}

local function queryDb(f)
    local whereSql, params = Log.buildWhere(f)
    local dir = f.sort == 'ts_asc' and 'ASC' or 'DESC'
    local sql = ('SELECT %s FROM ox_inventory_logs WHERE %s ORDER BY ts %s, id %s LIMIT ? OFFSET ?'):format(SELECT_COLS, whereSql, dir, dir)
    local qp = {}
    for i = 1, #params do qp[i] = params[i] end
    qp[#qp + 1] = f.pageSize
    qp[#qp + 1] = (f.page - 1) * f.pageSize
    local ok, rows = pcall(MySQL.query.await, sql, qp)
    if not ok then Log.dbOk = false Log.lastDbError = tostring(rows) return nil, 'db_unavailable' end
    local out = {}
    for i = 1, #(rows or {}) do out[i] = hydrate(rows[i]) end
    local keyParts = {}
    for i = 1, #params do keyParts[i] = tostring(params[i]) end
    local key = whereSql .. '|' .. table.concat(keyParts, '\1')
    local c = countCache[key]
    local now = GetGameTimer()
    local total
    if c and c.at + 10000 > now then
        total = c.total
    else
        local okc, n = pcall(MySQL.scalar.await, 'SELECT COUNT(*) FROM ox_inventory_logs WHERE ' .. whereSql, params)
        total = okc and tonumber(n) or #out
        cacheInsert(countCache, key, { at = now, total = total })
    end
    return out, total
end

function Log.query(filter)
    local t0 = GetGameTimer()
    local f, err = Log.sanitizeFilter(filter)
    if not f then return nil, err end
    local useRing
    if f.source == 'ring' then useRing = true
    elseif f.source == 'db' then useRing = false
    else useRing = (not f.text) and f.from >= ringOldestTs() end
    local partial = false
    if not useRing and not Log.dbOk then useRing = true partial = true end
    local rows, total
    if useRing then
        rows, total = queryRing(f)
    else
        rows, total = queryDb(f)
        if not rows then
            if f.source == 'db' then return nil, total end
            rows, total = queryRing(f)
            partial = true
        end
    end
    return { rows = rows, total = total, page = f.page, pageSize = f.pageSize, source = useRing and 'ring' or 'db', partial = partial, tookMs = GetGameTimer() - t0 }
end

-- ─── stats (§4.6) ───────────────────────────────────────────
local statsCache = nil

local function retentionDays()
    local S = server and server.RWSettings
    local v = S and S.get('logs.retentionDays')
    if v == nil then v = tonumber(cfg.retentionDays) end
    if v == nil then v = 30 end
    return math.floor(v)
end

local function ringStats(now)
    local d24, d7 = now - 86400000.0, now - 7 * 86400000.0
    local byAction = { ['24h'] = {}, ['7d'] = {} }
    local items, actors = {}, {}
    local buckets = {}
    local sev = { 0, 0, 0, 0 }
    for e in ringIter() do
        if e.ts >= d7 then
            byAction['7d'][e.action] = (byAction['7d'][e.action] or 0) + 1
            if e.item then
                local it = items[e.item] or { item = e.item, count = 0, rows = 0 }
                it.rows = it.rows + 1
                it.count = it.count + (e.count or 0)
                items[e.item] = it
            end
            local pid = primaryId(e.actor)
            if pid then
                local a = actors[pid] or { identifier = pid, name = e.actor.name, rows = 0 }
                a.rows = a.rows + 1
                actors[pid] = a
            end
        end
        if e.ts >= d24 then
            byAction['24h'][e.action] = (byAction['24h'][e.action] or 0) + 1
            sev[e.severity + 1] = sev[e.severity + 1] + 1
            local b = math.floor((e.ts - d24) / 3600000)
            if b < 0 then b = 0 elseif b > 23 then b = 23 end
            buckets[e.action] = buckets[e.action] or {}
            buckets[e.action][b] = (buckets[e.action][b] or 0) + 1
        end
    end
    return byAction, items, actors, buckets, sev
end

local function topN(map, key, n)
    local arr = {}
    for _, v in pairs(map) do arr[#arr + 1] = v end
    table.sort(arr, function(a, b) return a[key] > b[key] end)
    local out = {}
    for i = 1, math.min(n, #arr) do out[i] = arr[i] end
    return out
end

local function sparklineFrom(buckets, byAction24)
    local names = {}
    for a in pairs(byAction24) do names[#names + 1] = a end
    table.sort(names, function(a, b) return byAction24[a] > byAction24[b] end)
    local series = {}
    local other = nil
    for i, a in ipairs(names) do
        local arr = {}
        for b = 0, 23 do arr[b + 1] = buckets[a] and buckets[a][b] or 0 end
        if i <= 6 then
            series[a] = arr
        else
            other = other or {}
            for b = 1, 24 do other[b] = (other[b] or 0) + arr[b] end
        end
    end
    if other then series.other = other end
    return series
end

function Log.stats()
    local now = nowMs()
    if statsCache and statsCache.at + 30000 > GetGameTimer() then return statsCache.data end
    local byAction, items, actors, buckets, sev
    local partial = false
    if Log.dbOk then
        local d24, d7 = now - 86400000, now - 7 * 86400000
        local ok, r24 = pcall(MySQL.query.await, 'SELECT action, COUNT(*) c FROM ox_inventory_logs WHERE ts >= ? GROUP BY action', { d24 })
        local ok2, r7 = pcall(MySQL.query.await, 'SELECT action, COUNT(*) c FROM ox_inventory_logs WHERE ts >= ? GROUP BY action', { d7 })
        local ok3, ri = pcall(MySQL.query.await, 'SELECT item, COUNT(*) rows, SUM(count) c FROM ox_inventory_logs WHERE ts >= ? AND item IS NOT NULL GROUP BY item ORDER BY c DESC LIMIT 10', { d7 })
        local ok4, ra = pcall(MySQL.query.await, 'SELECT actor_identifier, MAX(actor_name) name, COUNT(*) rows FROM ox_inventory_logs WHERE ts >= ? AND actor_identifier IS NOT NULL GROUP BY actor_identifier ORDER BY rows DESC LIMIT 10', { d7 })
        local ok5, rb = pcall(MySQL.query.await, 'SELECT action, FLOOR((ts - ?) / 3600000) b, COUNT(*) c FROM ox_inventory_logs WHERE ts >= ? GROUP BY action, b', { d24, d24 })
        local ok6, rs = pcall(MySQL.query.await, 'SELECT severity, COUNT(*) c FROM ox_inventory_logs WHERE ts >= ? GROUP BY severity', { d24 })
        if ok and ok2 and ok3 and ok4 and ok5 and ok6 and type(r24) == 'table' and type(r7) == 'table' then
            byAction = { ['24h'] = {}, ['7d'] = {} }
            for _, r in ipairs(r24) do byAction['24h'][r.action] = tonumber(r.c) or 0 end
            for _, r in ipairs(r7) do byAction['7d'][r.action] = tonumber(r.c) or 0 end
            items, actors = {}, {}
            for _, r in ipairs(ri or {}) do items[r.item] = { item = r.item, count = tonumber(r.c) or 0, rows = tonumber(r.rows) or 0 } end
            for _, r in ipairs(ra or {}) do actors[r.actor_identifier] = { identifier = r.actor_identifier, name = r.name, rows = tonumber(r.rows) or 0 } end
            buckets = {}
            for _, r in ipairs(rb or {}) do
                local b = math.floor(tonumber(r.b) or 0)
                if b >= 0 and b <= 23 then buckets[r.action] = buckets[r.action] or {} buckets[r.action][b] = tonumber(r.c) or 0 end
            end
            sev = { 0, 0, 0, 0 }
            for _, r in ipairs(rs or {}) do local s = tonumber(r.severity) or 0 if s >= 0 and s <= 3 then sev[s + 1] = tonumber(r.c) or 0 end end
        else
            partial = true
        end
    else
        partial = true
    end
    if partial then byAction, items, actors, buckets, sev = ringStats(now) end
    local data = {
        generatedAt = now,
        partial = partial,
        byAction = byAction,
        topItems = topN(items, 'count', 10),
        topActors = topN(actors, 'rows', 10),
        sparkline = { bucketMs = 3600000, from = now - 86400000, actions = sparklineFrom(buckets, byAction['24h']) },
        severity24h = sev,
        db = {
            ok = Log.dbOk, inserted = Log.inserted, queued = #queue, dropped = Log.dropped, failedFlushes = Log.failedFlushes,
            lastError = Log.lastDbError, ringSize = ringCount, ringSpanMs = ringCount > 0 and (now - ringOldestTs()) or 0,
            retentionDays = retentionDays(), level = Log.level,
        },
    }
    statsCache = { at = GetGameTimer(), data = data }
    return data
end

-- ─── export (§4.7) ──────────────────────────────────────────
local CSV_HEADER = 'uid,id,ts,iso,action,severity,item,count,from_id,from_type,from_owner,from_label,to_id,to_type,to_owner,to_label,actor_src,actor_name,actor_char,actor_identifier,actor_discord,actor_job,actor_resource,target_src,target_name,target_char,target_identifier,target_discord,x,y,z,metadata,extra'

local function csvField(v)
    if v == nil or v == false then return '' end
    local s = type(v) == 'table' and json.encode(v) or tostring(v)
    if s:find('[,"\r\n]') then s = '"' .. s:gsub('"', '""') .. '"' end
    return s
end
Log.csvField = csvField

local function isoOf(ts) return os.date('!%Y-%m-%dT%H:%M:%SZ', ts // 1000) end

function Log.export(filter, format)
    filter = type(filter) == 'table' and filter or {}
    local f = {}
    for k, v in pairs(filter) do f[k] = v end
    f.page = 1
    f.pageSize = EXPORT_MAX_ROWS
    local san, err = Log.sanitizeFilter(f)
    if not san then return nil, err end
    san.pageSize = EXPORT_MAX_ROWS
    local rows, total
    local useRing = san.source == 'ring' or not Log.dbOk or (san.source == 'auto' and not san.text and san.from >= ringOldestTs())
    if useRing then rows, total = queryRing(san) else
        rows, total = queryDb(san)
        if not rows then rows, total = queryRing(san) end
    end
    local text
    if format == 'json' then
        text = json.encode({ exportedAt = nowMs(), filter = filter, rows = rows })
    else
        local lines = { CSV_HEADER }
        for i = 1, #rows do
            local e = rows[i]
            local a, g, fr, to = e.actor, e.target, e.from, e.to
            local cols = {
                e.uid, e.id, e.ts, isoOf(e.ts), e.action, e.severity, e.item, e.count,
                fr and fr.id, fr and fr.type, fr and fr.owner, fr and fr.label, to and to.id, to and to.type, to and to.owner, to and to.label,
                a and a.source, a and a.name, a and a.charId, primaryId(a), discordOf(a), a and a.job, a and a.resource,
                g and g.source, g and g.name, g and g.charId, primaryId(g), discordOf(g),
                e.coords and e.coords.x, e.coords and e.coords.y, e.coords and e.coords.z,
                e.metadata, e.extra,
            }
            local parts = {}
            for c = 1, 33 do parts[c] = csvField(cols[c]) end
            lines[#lines + 1] = table.concat(parts, ',')
        end
        text = table.concat(lines, '\r\n') .. '\r\n'
    end
    if #text > EXPORT_MAX_BYTES then return nil, 'export_too_large' end
    return text, #rows
end

-- ─── retention (§4.4) ───────────────────────────────────────
function Log.prune(days)
    days = days or retentionDays()
    if not Log.dbOk or days <= 0 then return 0 end
    local cutoff = (os.time() - days * 86400) * 1000.0
    local total = 0
    local ok, n
    repeat
        local res
        ok, res = pcall(MySQL.update.await, 'DELETE FROM ox_inventory_logs WHERE ts < ? LIMIT 5000', { cutoff })
        n = ok and tonumber(res) or 0
        total = total + n
        if ok and n >= 5000 then Wait(250) end
    until not ok or n < 5000
    local S = server and server.RWSettings
    local maxRows = S and S.get('logs.maxRows')
    if maxRows == nil then maxRows = tonumber(cfg.maxRows) or 0 end
    if ok and maxRows > 0 then
        repeat
            local res
            ok, res = pcall(MySQL.update.await, 'DELETE FROM ox_inventory_logs WHERE id < (SELECT id FROM (SELECT id FROM ox_inventory_logs ORDER BY id DESC LIMIT 1 OFFSET ?) t) LIMIT 5000', { math.floor(maxRows) })
            n = ok and tonumber(res) or 0
            total = total + n
            if ok and n >= 5000 then Wait(250) end
        until not ok or n < 5000
    end
    if total > 0 then lib.print.info(('[rw-logs] pruned %d rows older than %d days'):format(total, days)) end
    return total
end

lib.cron.new('17 4 * * *', function() Log.prune() end)

-- ─── live tail (§5) ─────────────────────────────────────────
local subscribers = {}
local tailBuffer = {}
local tailTimer = false

local function flushTail()
    tailTimer = false
    if #tailBuffer == 0 then return end
    local batch = tailBuffer
    tailBuffer = {}
    if #batch > 50 then
        local trimmed = {}
        for i = #batch - 49, #batch do trimmed[#trimmed + 1] = batch[i] end
        batch = trimmed
    end
    local now = GetGameTimer()
    for src, lease in pairs(subscribers) do
        if lease < now or not (server and server.isRWAdmin and server.isRWAdmin(src)) then
            subscribers[src] = nil
        else
            TriggerClientEvent('ox_inventory:rwAdminTail', src, batch)
        end
    end
end

Log.addSink(function(entry)
    if next(subscribers) == nil then return end
    tailBuffer[#tailBuffer + 1] = entry
    if not tailTimer then tailTimer = true SetTimeout(1000, flushTail) end
end)

function Log.subscribe(src, on)
    src = tonumber(src)
    if not src then return false end
    if on then subscribers[src] = GetGameTimer() + 300000 else subscribers[src] = nil end
    return { on = on == true, leaseMs = 300000 }
end

AddEventHandler('playerDropped', function() subscribers[source] = nil end)

-- ─── live feed cursor (admin «Live» page) ───────────────────
-- Polled every ~2 s while the page is on screen. The ring is the source
-- (it always holds the newest rows); the cursor is the per-boot sequence
-- number, so a restart (new BOOT36) or a cursor from the future resets.
local SINCE_MAX = 100

---@return { boot: string, cursor: number, rows: table[], gap: boolean, reset: boolean }
function Log.since(cursor, boot, limit)
    limit = math.floor(tonumber(limit) or 50)
    if limit < 1 then limit = 1 elseif limit > SINCE_MAX then limit = SINCE_MAX end
    cursor = tonumber(cursor)
    cursor = cursor and math.floor(cursor) or nil
    local reset = cursor == nil or cursor < 0 or boot ~= BOOT36 or cursor > seq
    local rows, gap = {}, false
    if reset then
        for e in ringIter() do
            if #rows >= limit then break end
            rows[#rows + 1] = e
        end
    else
        local last
        local reached = false
        for e in ringIter() do
            if e.seq <= cursor then reached = true break end
            if #rows >= limit then gap = true break end
            rows[#rows + 1] = e
            last = e
        end
        -- the ring wrapped past the cursor: rows between were overwritten
        if not gap and not reached and last and last.seq > cursor + 1 then gap = true end
    end
    return { boot = BOOT36, cursor = seq, rows = rows, gap = gap, reset = reset }
end

-- ─── players seen in the logs (admin «Players» page) ────────
local PLAYERS_TTL_MS = 5000
local playersCache = {}
local profileCache = {}

local function clampInt(v, lo, hi, def)
    v = tonumber(v)
    if not v then return def end
    v = math.floor(v)
    if v < lo then return lo elseif v > hi then return hi end
    return v
end

---primary identifier → server id of every connected player
function Log.onlineIndex()
    local out = {}
    local list = GetPlayers()
    for i = 1, #list do
        local src = tonumber(list[i])
        if src then
            local c = identityCache[src]
            if not c then c = { identifiers = identifiersFor(src) } identityCache[src] = c end
            local pid = primaryId(c)
            if pid then out[pid] = src end
        end
    end
    return out
end

local function validIdentifier(s)
    return type(s) == 'string' and #s >= 3 and #s <= NAME_MAX and s:match('^[%w_%-%.]+:[%w_%-%.]+$') ~= nil
end
Log.validIdentifier = validIdentifier

local function playersFromRing(fromTs, search)
    local map, list = {}, {}
    local s = search and search:lower() or nil
    for e in ringIter() do
        if e.ts < fromTs then break end
        local a = e.actor
        local pid = primaryId(a)
        if pid then
            local p = map[pid]
            if not p then
                -- newest row first: this is the latest name / source / character
                p = { identifier = pid, name = a.name, lastSeen = e.ts, firstSeen = e.ts, events = 0, serverId = a.source, charId = a.charId, job = a.job }
                map[pid] = p
                list[#list + 1] = p
            end
            p.events = p.events + 1
            p.firstSeen = e.ts
        end
    end
    if not s then return list end
    local out = {}
    for i = 1, #list do
        local p = list[i]
        if (p.name and p.name:lower():find(s, 1, true)) or p.identifier:lower():find(s, 1, true)
            or (p.charId and tostring(p.charId):lower():find(s, 1, true)) then
            out[#out + 1] = p
        end
    end
    return out
end

local SORTERS = {
    recent = function(a, b) if a.lastSeen ~= b.lastSeen then return a.lastSeen > b.lastSeen end return a.identifier < b.identifier end,
    events = function(a, b) if a.events ~= b.events then return a.events > b.events end return a.lastSeen > b.lastSeen end,
    name = function(a, b)
        local x, y = (a.name or ''):lower(), (b.name or ''):lower()
        if x ~= y then return x < y end
        return a.identifier < b.identifier
    end,
}

---Paginated list of the players seen as ACTOR in the window (MySQL when up, the ring otherwise).
function Log.players(p)
    p = type(p) == 'table' and p or {}
    local days = clampInt(p.days, 1, 90, 30)
    local page = clampInt(p.page, 1, 100000, 1)
    local pageSize = clampInt(p.pageSize, 1, 100, 50)
    if (page - 1) * pageSize > 5000 then return nil, 'bad_payload' end
    local sort = (p.sort == 'events' or p.sort == 'name') and p.sort or 'recent'
    local search = strField(p.search, NAME_MAX)
    local t0 = GetGameTimer()
    local now = nowMs()
    local fromTs = now - days * 86400000.0

    local key = table.concat({ days, page, pageSize, sort, search or '', p.source == 'ring' and 'r' or 'a' }, '|')
    local hit = playersCache[key]
    local rows, total, source, partial
    if hit and hit.at + PLAYERS_TTL_MS > t0 then
        rows, total, source, partial = hit.rows, hit.total, hit.source, hit.partial
    else
        partial = false
        if Log.dbOk and p.source ~= 'ring' then
            local where = { 'ts >= ? AND actor_identifier IS NOT NULL' }
            local params = { fromTs }
            if search then
                local like = '%' .. escapeLike(search) .. '%'
                where[#where + 1] = 'AND (actor_name LIKE ? ESCAPE \'\\\\\' OR actor_identifier LIKE ? ESCAPE \'\\\\\' OR actor_char LIKE ? ESCAPE \'\\\\\')'
                params[#params + 1] = like
                params[#params + 1] = like
                params[#params + 1] = like
            end
            local whereSql = table.concat(where, ' ')
            local order = sort == 'events' and 'n DESC, last DESC' or sort == 'name' and 'name ASC, id ASC' or 'last DESC, id ASC'
            local qp = {}
            for i = 1, #params do qp[i] = params[i] end
            qp[#qp + 1] = pageSize
            qp[#qp + 1] = (page - 1) * pageSize
            local ok, res = pcall(MySQL.query.await,
                ('SELECT actor_identifier id, MAX(actor_name) name, MAX(ts) last, MIN(ts) first, COUNT(*) n, MAX(actor_src) src FROM ox_inventory_logs WHERE %s GROUP BY actor_identifier ORDER BY %s LIMIT ? OFFSET ?'):format(whereSql, order), qp)
            local okc, n = pcall(MySQL.scalar.await, 'SELECT COUNT(DISTINCT actor_identifier) FROM ox_inventory_logs WHERE ' .. whereSql, params)
            if ok and type(res) == 'table' then
                rows = {}
                for i = 1, #res do
                    local r = res[i]
                    rows[i] = { identifier = r.id, name = r.name, lastSeen = tonumber(r.last), firstSeen = tonumber(r.first), events = tonumber(r.n) or 0, serverId = tonumber(r.src) }
                end
                total = okc and tonumber(n) or #rows
                source = 'db'
            else
                if not ok then Log.dbOk = false Log.lastDbError = tostring(res) end
                partial = true
            end
        end
        if not rows then
            local all = playersFromRing(fromTs, search)
            table.sort(all, SORTERS[sort])
            total = #all
            rows = {}
            local first = (page - 1) * pageSize + 1
            for i = first, math.min(#all, first + pageSize - 1) do rows[#rows + 1] = all[i] end
            source = 'ring'
            partial = partial or Log.dbOk == false
        end
        cacheInsert(playersCache, key, { at = t0, rows = rows, total = total, source = source, partial = partial })
    end

    -- online state is live (never cached): dot + current name / server id
    local online = Log.onlineIndex()
    local out = {}
    for i = 1, #rows do
        local r = rows[i]
        local src = online[r.identifier]
        out[i] = {
            identifier = r.identifier, name = (src and GetPlayerName(src)) or r.name, lastSeen = r.lastSeen, firstSeen = r.firstSeen,
            events = r.events, online = src ~= nil, serverId = src or r.serverId, charId = r.charId, job = r.job,
        }
    end
    return { rows = out, total = total, page = page, pageSize = pageSize, days = days, sort = sort, source = source, partial = partial, tookMs = GetGameTimer() - t0 }
end

local function dayStart(now)
    local t = os.date('*t', math.floor(now / 1000))
    t.hour, t.min, t.sec = 0, 0, 0
    return os.time(t) * 1000.0
end

local function emptyProfile(identifier, days)
    return { identifier = identifier, events = 0, days = days, counts = {}, received = { rows = 0, qty = 0 } }
end

local function profileFromRing(identifier, fromTs, dailyFrom)
    local prof = emptyProfile(identifier)
    local daily = { 0, 0, 0, 0, 0, 0, 0 }
    local found = false
    for e in ringIter() do
        local asActor = primaryId(e.actor) == identifier
        local asTarget = not asActor and primaryId(e.target) == identifier
        if asActor or asTarget then
            local who = asActor and e.actor or e.target
            if not found then
                found = true
                prof.name, prof.serverId, prof.charId, prof.job, prof.identifiers, prof.lastSeen = who.name, who.source, who.charId, who.job, who.identifiers, e.ts
            end
            prof.firstSeen = e.ts
            if e.ts >= dailyFrom then
                local d = math.floor((e.ts - dailyFrom) / 86400000) + 1
                if d >= 1 and d <= 7 then daily[d] = daily[d] + 1 end
            end
            if e.ts >= fromTs then
                prof.events = prof.events + 1
                if asActor then
                    local c = prof.counts[e.action] or { rows = 0, qty = 0 }
                    c.rows = c.rows + 1
                    c.qty = c.qty + (tonumber(e.count) or 0)
                    prof.counts[e.action] = c
                elseif e.action == 'give' then
                    prof.received.rows = prof.received.rows + 1
                    prof.received.qty = prof.received.qty + (tonumber(e.count) or 0)
                end
            end
        end
    end
    return found and prof or nil, daily
end

local function profileFromDb(identifier, fromTs, dailyFrom)
    local q = MySQL.query.await
    local ok1, id = pcall(q, 'SELECT actor_name name, actor_src src, actor_char ch, actor_job job, actor_ids ids, ts FROM ox_inventory_logs WHERE actor_identifier = ? ORDER BY ts DESC LIMIT 1', { identifier })
    if not ok1 then return nil, nil, id end
    local row = type(id) == 'table' and id[1] or nil
    if not row then
        local okT, t = pcall(q, 'SELECT target_name name, target_src src, target_char ch, target_ids ids, ts FROM ox_inventory_logs WHERE target_identifier = ? ORDER BY ts DESC LIMIT 1', { identifier })
        if not okT then return nil, nil, t end
        row = type(t) == 'table' and t[1] or nil
    end
    if not row then return false end
    local prof = emptyProfile(identifier)
    local okIds, ids = pcall(json.decode, type(row.ids) == 'string' and row.ids or '')
    prof.name, prof.serverId, prof.charId, prof.job, prof.lastSeen = row.name, tonumber(row.src), row.ch, row.job, tonumber(row.ts)
    prof.identifiers = okIds and type(ids) == 'table' and ids or nil
    local okF, first = pcall(MySQL.scalar.await, 'SELECT MIN(ts) FROM ox_inventory_logs WHERE actor_identifier = ? OR target_identifier = ?', { identifier, identifier })
    prof.firstSeen = okF and tonumber(first) or prof.lastSeen
    local okC, counts = pcall(q, 'SELECT action, COUNT(*) c, COALESCE(SUM(count), 0) q FROM ox_inventory_logs WHERE actor_identifier = ? AND ts >= ? GROUP BY action', { identifier, fromTs })
    local okR, recv = pcall(q, 'SELECT COUNT(*) c, COALESCE(SUM(count), 0) q FROM ox_inventory_logs WHERE target_identifier = ? AND action = \'give\' AND ts >= ?', { identifier, fromTs })
    local okT2, tgt = pcall(MySQL.scalar.await, 'SELECT COUNT(*) FROM ox_inventory_logs WHERE target_identifier = ? AND (actor_identifier IS NULL OR actor_identifier <> ?) AND ts >= ?', { identifier, identifier, fromTs })
    local okD, days = pcall(q, 'SELECT FLOOR((ts - ?) / 86400000) d, COUNT(*) c FROM ox_inventory_logs WHERE ts >= ? AND (actor_identifier = ? OR target_identifier = ?) GROUP BY d', { dailyFrom, dailyFrom, identifier, identifier })
    if not (okC and okR and okD) then return nil, nil, 'query' end
    local events = 0
    for _, r in ipairs(counts or {}) do
        local n = tonumber(r.c) or 0
        prof.counts[r.action] = { rows = n, qty = tonumber(r.q) or 0 }
        events = events + n
    end
    local rr = type(recv) == 'table' and recv[1] or nil
    if rr then prof.received = { rows = tonumber(rr.c) or 0, qty = tonumber(rr.q) or 0 } end
    prof.events = events + (okT2 and tonumber(tgt) or 0)
    local daily = { 0, 0, 0, 0, 0, 0, 0 }
    for _, r in ipairs(days or {}) do
        local d = math.floor(tonumber(r.d) or -1) + 1
        if d >= 1 and d <= 7 then daily[d] = tonumber(r.c) or 0 end
    end
    return prof, daily
end

---One player: identity, counters over `days`, 7 calendar days (server time) of activity.
function Log.player(identifier, p)
    if not validIdentifier(identifier) then return nil, 'bad_payload' end
    p = type(p) == 'table' and p or {}
    local days = clampInt(p.days, 1, 90, 30)
    local t0 = GetGameTimer()
    local key = identifier .. '|' .. days .. '|' .. (p.source == 'ring' and 'r' or 'a')
    local hit = profileCache[key]
    local prof
    if hit and hit.at + PLAYERS_TTL_MS > t0 then
        prof = lib.table.deepclone(hit.prof)
    else
        local now = nowMs()
        local fromTs = now - days * 86400000.0
        local dailyFrom = dayStart(now) - 6 * 86400000.0
        local daily, partial, source = nil, false, 'ring'
        if Log.dbOk and p.source ~= 'ring' then
            local res, d, err = profileFromDb(identifier, fromTs, dailyFrom)
            if res == nil then
                Log.lastDbError = tostring(err)
                partial = true
            elseif res then
                prof, daily, source = res, d, 'db'
            end
        end
        -- not in the table (yet: rows are flushed every few seconds) → the ring
        if not prof then
            prof, daily = profileFromRing(identifier, fromTs, dailyFrom)
            source = 'ring'
        end
        if not prof then
            prof = emptyProfile(identifier)
            daily = { 0, 0, 0, 0, 0, 0, 0 }
            prof.missing = true
        end
        prof.days = days
        prof.daily = { from = dailyFrom, bucketMs = 86400000, values = daily }
        prof.source = source
        prof.partial = partial or (source == 'ring' and Log.dbOk == false)
        cacheInsert(profileCache, key, { at = t0, prof = lib.table.deepclone(prof) })
    end

    local src = Log.onlineIndex()[identifier]
    prof.online = src ~= nil
    if src then
        prof.serverId = src
        prof.name = GetPlayerName(src) or prof.name
    end
    if prof.missing and not src then return nil, 'not_found' end
    prof.missing = nil
    return prof
end

-- ─── meta for the UI ────────────────────────────────────────
function Log.meta()
    local actions = {}
    for key, def in pairs(ACTIONS) do actions[#actions + 1] = { key = key, level = def[1], severity = def[2], group = def[3] } end
    table.sort(actions, function(a, b) return a.key < b.key end)
    local tz = 0
    do
        local t = os.time()
        local utc = os.date('!*t', t)
        local loc = os.date('*t', t)
        utc.isdst = loc.isdst
        tz = math.floor((os.time(loc) - os.time(utc)) / 60)
    end
    return {
        actions = actions, aliases = ALIASES, level = Log.level, retentionDays = retentionDays(),
        ringSize = RING_SIZE, dbOk = Log.dbOk, serverTime = nowMs(), tzOffsetMin = tz,
    }
end

-- ─── DB bootstrap (§4.2) ────────────────────────────────────
local DDL = [[CREATE TABLE IF NOT EXISTS ox_inventory_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uid VARCHAR(24) NOT NULL,
  ts BIGINT UNSIGNED NOT NULL,
  action VARCHAR(32) NOT NULL,
  severity TINYINT UNSIGNED NOT NULL DEFAULT 0,
  item VARCHAR(64) NULL,
  count INT NULL,
  from_id VARCHAR(100) NULL,
  from_type VARCHAR(20) NULL,
  from_owner VARCHAR(60) NULL,
  from_label VARCHAR(100) NULL,
  to_id VARCHAR(100) NULL,
  to_type VARCHAR(20) NULL,
  to_owner VARCHAR(60) NULL,
  to_label VARCHAR(100) NULL,
  actor_src SMALLINT UNSIGNED NULL,
  actor_name VARCHAR(64) NULL,
  actor_char VARCHAR(60) NULL,
  actor_identifier VARCHAR(64) NULL,
  actor_discord VARCHAR(32) NULL,
  actor_job VARCHAR(40) NULL,
  actor_resource VARCHAR(64) NULL,
  target_src SMALLINT UNSIGNED NULL,
  target_name VARCHAR(64) NULL,
  target_char VARCHAR(60) NULL,
  target_identifier VARCHAR(64) NULL,
  target_discord VARCHAR(32) NULL,
  x FLOAT NULL,
  y FLOAT NULL,
  z FLOAT NULL,
  metadata TEXT NULL,
  actor_ids TEXT NULL,
  target_ids TEXT NULL,
  extra TEXT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_uid (uid),
  KEY idx_ts (ts),
  KEY idx_action_ts (action, ts),
  KEY idx_item_ts (item, ts),
  KEY idx_actor_ts (actor_identifier, ts),
  KEY idx_target_ts (target_identifier, ts),
  KEY idx_actor_src_ts (actor_src, ts),
  KEY idx_from (from_id(60)),
  KEY idx_to (to_id(60)),
  KEY idx_severity_ts (severity, ts)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]]
Log.DDL = DDL

local function awaitDb()
    local r = MySQL and MySQL.ready
    if type(r) == 'table' and type(r.await) == 'function' then r.await() end
end

Citizen.CreateThreadNow(function()
    awaitDb()
    local ok = pcall(MySQL.scalar.await, 'SELECT 1 FROM ox_inventory_logs LIMIT 1')
    if not ok then
        local created = pcall(MySQL.query.await, DDL)
        if not created then
            lib.print.error('[rw-logs] could not create ox_inventory_logs — run docs/ox_inventory_logs.sql manually; logs stay in memory')
        end
        ok = created
    end
    Log.dbOk = ok
    Log.ready = true
    if ok and #queue > 0 then Log.flush() end
    SetTimeout(60000, function() Log.prune() end)
end)

-- Forced flushes on shutdown / restart.
AddEventHandler('txAdmin:events:serverShuttingDown', function() Log.flush() end)
AddEventHandler('txAdmin:events:scheduledRestart', function(data)
    if type(data) == 'table' and tonumber(data.secondsRemaining) == 60 then Log.flush() end
end)
AddEventHandler('onResourceStop', function(res)
    if res ~= (shared and shared.resource or GetCurrentResourceName()) then return end
    Log.flush(true)
end)

-- Test/inspection helpers (no game use).
function Log._state() return { queue = #queue, ring = ringCount, seq = seq, ringSize = RING_SIZE } end

server = server or {}
server.Log = Log

return Log
