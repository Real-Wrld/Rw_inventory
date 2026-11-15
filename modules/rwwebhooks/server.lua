--  REALWRLD Software® · ox_inventory · Discord webhooks (server)
-- ═════════════════════════════════════════════════════════════
--
--  Routes log rows (modules/rwlogs) to Discord webhooks
--  (design/admin-logs.md §6). Seeds come from config.lua
--  (RWInv.Webhooks.seeds), admin edits live in KVP
--  `rw:webhooks` and win over the seeds. Full URLs never leave the
--  server: every payload returned to the NUI carries `urlMasked`.
-- ═════════════════════════════════════════════════════════════

if not lib then return end

local config = require 'modules.rwconfig.shared'.Get()
local cfg = type(config.Webhooks) == 'table' and config.Webhooks or {}
local Log = require 'modules.rwlogs.server'
local Admin = require 'modules.rwadmin.server'

local KVP_KEY = 'rw:webhooks'
local MAX_WEBHOOKS = 25

local Webhook = {}

-- ─── limits (live via server settings, §10.2) ───────────────
local limits = {}

local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end

function Webhook.refreshLimits()
    local S = server and server.RWSettings
    local function get(path, fallback, lo, hi)
        local v = S and S.get(path)
        if v == nil then v = tonumber(cfg[path:match('%.(.+)$')]) end
        if v == nil then v = fallback end
        return clamp(tonumber(v) or fallback, lo, hi)
    end
    limits.ratePerSecond = get('webhooks.ratePerSecond', 2, 1, 5)
    limits.globalRatePerSecond = get('webhooks.globalRatePerSecond', 8, 1, 20)
    limits.maxQueue = math.floor(get('webhooks.maxQueue', 200, 20, 2000))
    limits.flushMs = math.floor(get('webhooks.flushMs', 1500, 500, 10000))
    return limits
end
Webhook.refreshLimits()
Webhook.limits = limits

-- ─── helpers ────────────────────────────────────────────────
local URL_PATTERN = '^https://(discord%.com|discordapp%.com|ptb%.discord%.com|canary%.discord%.com)/api/webhooks/%d+/[%w%-_]+$'

local function validUrl(url)
    if type(url) ~= 'string' or url == '' then return false end
    for _, host in ipairs({ 'discord%.com', 'discordapp%.com', 'ptb%.discord%.com', 'canary%.discord%.com' }) do
        if url:match('^https://' .. host .. '/api/webhooks/%d+/[%w%-_]+$') then return true end
    end
    return false
end

function Webhook.maskUrl(url)
    if type(url) ~= 'string' or url == '' then return '' end
    local base = url:gsub('^(https://[^/]+)/api/webhooks/.*$', '%1/api/webhooks/...')
    return base .. '/****' .. url:sub(-4)
end

local function capStr(v, n)
    if type(v) ~= 'string' then return nil end
    v = v:gsub('^%s+', ''):gsub('%s+$', '')
    if v == '' then return nil end
    return v:sub(1, n)
end

local function globToPattern(glob)
    local p = glob:gsub('%%', '%%%%'):gsub('%.', '%%.'):gsub('%-', '%%-'):gsub('%*', '.*')
    return '^' .. p:lower() .. '$'
end

local function newStats()
    return { sent = 0, failed = 0, queued = 0, dropped = 0, lastStatus = nil, lastError = nil, lastSentAt = nil, autoDisabled = false, consecutiveFailures = 0 }
end

local function eventValid(e)
    return e == '*' or Log.ACTIONS[e] ~= nil or Log.ALIASES[e] ~= nil
end

---Sanitises an input record over an existing one. Returns record | nil, err.
local function sanitizeWebhook(input, existing)
    if type(input) ~= 'table' then return nil, 'bad_payload' end
    local out = {}
    local id = capStr(input.id, 32) or (existing and existing.id)
    if not id or not id:match('^[a-z0-9_%-]+$') then return nil, 'bad_payload' end
    out.id = id
    out.name = capStr(input.name, 48) or (existing and existing.name) or id
    out.seed = existing and existing.seed == true or input.seed == true
    -- events
    local events = {}
    local src = type(input.events) == 'table' and input.events or (existing and existing.events) or { '*' }
    for i = 1, math.min(#src, 64) do
        local e = src[i]
        if type(e) == 'string' and eventValid(e) then events[#events + 1] = e end
    end
    if #events == 0 then events = { '*' } end
    out.events = events
    -- items
    local items = {}
    local isrc = type(input.items) == 'table' and input.items or (existing and existing.items) or {}
    for i = 1, math.min(#isrc, 128) do
        local it = capStr(isrc[i], 64)
        if it and it:match('^[%w_%-%*%.]+$') then items[#items + 1] = it end
    end
    out.items = items
    out.minCount = math.max(math.floor(tonumber(input.minCount) or (existing and existing.minCount) or 0), 0)
    -- players
    local players = {}
    local psrc = type(input.players) == 'table' and input.players or (existing and existing.players) or {}
    for i = 1, math.min(#psrc, 128) do
        local p = Admin.normaliseIdentifier(psrc[i])
        if p and (p:match('^license:') or p:match('^license2:') or p:match('^discord:') or p:match('^steam:') or p:match('^fivem:')) then players[#players + 1] = p end
    end
    out.players = players
    local sev = tonumber(input.severityMin)
    if sev == nil then sev = existing and existing.severityMin or 0 end
    out.severityMin = clamp(math.floor(sev), 0, 3)
    local color = tonumber(input.color)
    if input.color == nil and existing then color = existing.color end
    if color ~= nil then out.color = clamp(math.floor(color), 0, 0xFFFFFF) end
    if input.mention == false or input.mention == '' then out.mention = nil else out.mention = capStr(input.mention, 64) or (existing and existing.mention) end
    out.username = capStr(input.username, 32) or (existing and existing.username) or 'ox_inventory'
    if input.avatar == false or input.avatar == '' then out.avatar = nil else
        local av = capStr(input.avatar, 256) or (existing and existing.avatar)
        out.avatar = (av and av:match('^https://')) and av or nil
    end
    -- url: non-empty must validate; empty keeps stored
    if type(input.url) == 'string' and input.url ~= '' then
        if not validUrl(input.url) then return nil, 'invalid_url' end
        out.url = input.url
    else
        out.url = existing and existing.url or nil
    end
    local enabled = input.enabled
    if enabled == nil then enabled = existing and existing.enabled or false end
    out.enabled = enabled == true and out.url ~= nil
    out.stats = existing and existing.stats or newStats()
    return out
end
Webhook.sanitize = sanitizeWebhook

-- ─── store: seeds + KVP overrides ───────────────────────────
local seeds = {}     -- [id] = record
local seedOrder = {}
local store = { v = 1, overrides = {}, deleted = {} }
local effective = {} -- array of records (with url), rebuilt on change
local queues = {}    -- [id] = { items, timer, nextAllowedAt, inFlight }

local function loadSeeds()
    seeds, seedOrder = {}, {}
    local list = type(cfg.seeds) == 'table' and cfg.seeds or {}
    for i = 1, #list do
        local s = list[i]
        if type(s) == 'table' then
            local rec = sanitizeWebhook({ id = s.id, name = s.name, enabled = s.enabled, url = s.url, events = s.events, items = s.items,
                minCount = s.minCount, players = s.players, severityMin = s.severityMin, color = s.color, mention = s.mention,
                username = s.username, avatar = s.avatar, seed = true })
            if rec then rec.seed = true seeds[rec.id] = rec seedOrder[#seedOrder + 1] = rec.id end
        end
    end
    local legacy = GetConvar('inventory:webhook', '')
    if legacy ~= '' and validUrl(legacy) and not seeds.legacy then
        local rec = sanitizeWebhook({ id = 'legacy', name = 'Legacy (inventory:webhook convar)', enabled = false, url = legacy, events = { '*' }, severityMin = 1, seed = true })
        if rec then rec.seed = true seeds.legacy = rec seedOrder[#seedOrder + 1] = 'legacy' end
    end
end

local function loadStore()
    store = { v = 1, overrides = {}, deleted = {} }
    local raw = GetResourceKvpString(KVP_KEY)
    if not raw then return end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then return end
    if type(decoded.deleted) == 'table' then
        for id, v in pairs(decoded.deleted) do if v == true and type(id) == 'string' then store.deleted[id] = true end end
    end
    if type(decoded.overrides) == 'table' then
        local n = 0
        for id, rec in pairs(decoded.overrides) do
            if n >= MAX_WEBHOOKS then break end
            if type(rec) == 'table' then
                rec.id = rec.id or id
                local clean = sanitizeWebhook(rec, seeds[id])
                if clean then
                    clean.seed = seeds[id] ~= nil
                    clean.stats = newStats()
                    store.overrides[clean.id] = clean
                    n = n + 1
                end
            end
        end
    end
end

local function saveStore()
    local out = { v = 1, overrides = {}, deleted = store.deleted }
    for id, rec in pairs(store.overrides) do
        out.overrides[id] = {
            id = rec.id, name = rec.name, enabled = rec.enabled, url = rec.url, events = rec.events, items = rec.items,
            minCount = rec.minCount, players = rec.players, severityMin = rec.severityMin, color = rec.color,
            mention = rec.mention, username = rec.username, avatar = rec.avatar,
        }
    end
    SetResourceKvp(KVP_KEY, json.encode(out))
end

local function compile(w)
    local set, all = {}, false
    for _, e in ipairs(w.events) do
        if e == '*' then all = true
        elseif Log.ACTIONS[e] then set[e] = true
        elseif Log.ALIASES[e] then
            for _, k in ipairs(Log.ALIASES[e]) do set[k] = true end
            if e == 'receive' then w._receive = true end
        end
    end
    w._all = all
    w._eventSet = set
    local pats, exact = {}, {}
    for _, it in ipairs(w.items) do
        if it:find('*', 1, true) then pats[#pats + 1] = globToPattern(it) else exact[it:lower()] = true end
    end
    w._itemPats, w._itemExact = pats, exact
    local ps = {}
    for _, p in ipairs(w.players) do ps[p] = true end
    w._playerSet = ps
    if not queues[w.id] then queues[w.id] = { items = {}, timer = false, nextAllowedAt = 0, inFlight = false } end
    w.stats = w.stats or newStats()
end

local function rebuild()
    effective = {}
    local prevStats = {}
    for _, w in ipairs(effective) do prevStats[w.id] = w.stats end
    for _, id in ipairs(seedOrder) do
        if not store.deleted[id] then
            local seed = seeds[id]
            local ov = store.overrides[id]
            local rec = ov and lib.table.deepclone(ov) or lib.table.deepclone(seed)
            if ov and not ov.url then rec.url = seed.url end
            rec.seed = true
            rec.enabled = rec.enabled == true and rec.url ~= nil
            effective[#effective + 1] = rec
        end
    end
    local extra = {}
    for id, ov in pairs(store.overrides) do
        if not seeds[id] then extra[#extra + 1] = id end
    end
    table.sort(extra)
    for _, id in ipairs(extra) do
        local rec = lib.table.deepclone(store.overrides[id])
        rec.seed = false
        effective[#effective + 1] = rec
    end
    for _, w in ipairs(effective) do
        w.stats = Webhook._stats and Webhook._stats[w.id] or newStats()
        Webhook._stats = Webhook._stats or {}
        Webhook._stats[w.id] = w.stats
        compile(w)
    end
end

local function find(id)
    for _, w in ipairs(effective) do if w.id == id then return w end end
end

local function publicRecord(w)
    local q = queues[w.id]
    local stats = w.stats
    stats.queued = q and #q.items or 0
    return {
        id = w.id, name = w.name, enabled = w.enabled, events = w.events, items = w.items, minCount = w.minCount,
        players = w.players, severityMin = w.severityMin, color = w.color, mention = w.mention, username = w.username,
        avatar = w.avatar, seed = w.seed == true, hasUrl = w.url ~= nil, urlMasked = Webhook.maskUrl(w.url),
        stats = {
            sent = stats.sent, failed = stats.failed, queued = stats.queued, dropped = stats.dropped, lastStatus = stats.lastStatus,
            lastError = stats.lastError, lastSentAt = stats.lastSentAt, autoDisabled = stats.autoDisabled, consecutiveFailures = stats.consecutiveFailures,
        },
    }
end

function Webhook.list()
    local out = {}
    for i, w in ipairs(effective) do out[i] = publicRecord(w) end
    return out
end

-- ─── embeds (§6.5) ──────────────────────────────────────────
local COLORS = {
    movement = 0x5865F2, give = 0x57F287, drop = 0xFEE75C, pickup = 0xFEE75C, buy = 0x3BA55D, sell = 0x3BA55D, craft = 0xEB459E,
    use = 0x99AAB5, open = 0x99AAB5, open_player = 0xED4245, inspect = 0xED4245, weapon = 0xE67E22, admin = 0xED4245,
    settings = 0x9B59B6, system = 0x95A5A6, exploit = 0xFF0000, decay = 0x99AAB5, metadata = 0x99AAB5, durability = 0x99AAB5, clothing = 0x1ABC9C,
}
if type(cfg.colors) == 'table' then for k, v in pairs(cfg.colors) do if type(v) == 'number' then COLORS[k] = v end end end

local SEVERITY_LABEL = { [0] = 'info', [1] = 'notice', [2] = 'warning', [3] = 'critical' }
local ICON = { give = '🎁', drop = '⬇️', pickup = '⬆️', buy = '🛒', sell = '💰', craft = '🛠️', exploit = '🚨', admin_give = '🛡️', admin_remove = '🛡️',
    admin_clear = '🛡️', admin_confiscate = '🛡️', admin_return = '🛡️', settings_lock = '🔒', settings_unlock = '🔓', settings_apply = '📌', open_player = '🔍', inspect = '🔍' }

local function aliasOf(action)
    local def = Log.ACTIONS[action]
    return def and def[3] or nil
end

local function actionLabel(action)
    local key = 'ui.admin.action.' .. action
    local ok, v = pcall(locale, key)
    if ok and type(v) == 'string' and v ~= key then return v end
    return action
end

local function nameOf(id)
    if not id then return nil end
    if id.resource then return id.resource end
    return id.name or (id.source and tostring(id.source)) or '?'
end

local function trunc(s, n)
    s = tostring(s)
    if #s > n then return s:sub(1, n - 1) .. '…' end
    return s
end

local FIELD_KEYS = { serial = 'Serial', durability = 'Durability', ammo = 'Ammo' }
local EXTRA_FIELDS = { shop = 'Shop', benchId = 'Bench', component = 'Component', command = 'Command', resource = 'Resource', reason = 'Reason' }

function Webhook.embed(entry, w)
    local action = entry.action
    local title = trunc(('%s %s'):format(ICON[action] or '•', actionLabel(action)), 256)
    local desc = {}
    local a, t = entry.actor, entry.target
    if a or t then
        local line = a and ('**%s** (%s)'):format(nameOf(a), a.source or a.resource or '-') or ''
        if t then line = line .. (' → **%s** (%s)'):format(nameOf(t), t.source or '-') end
        desc[#desc + 1] = line
    end
    if entry.item then desc[#desc + 1] = ('**%s× %s**'):format(entry.count or 1, entry.item) end
    if entry.from or entry.to then
        local f, to = entry.from, entry.to
        local fs = f and ('%s (%s:%s)'):format(f.label or f.id, f.type, f.id) or '—'
        local ts = to and ('%s (%s:%s)'):format(to.label or to.id, to.type, to.id) or '—'
        desc[#desc + 1] = fs .. ' → ' .. ts
    end
    local fields = {}
    local meta = entry.metadata or {}
    for k, label in pairs(FIELD_KEYS) do
        if meta[k] ~= nil then fields[#fields + 1] = { name = label, value = trunc(meta[k], 1024), inline = true } end
    end
    local extra = entry.extra or {}
    if extra.totalPrice then
        fields[#fields + 1] = { name = 'Price', value = trunc(('%s %s · %s'):format(extra.totalPrice, extra.currency or '', extra.payment or ''), 1024), inline = true }
    end
    local used = { totalPrice = true, currency = true, payment = true }
    for k, label in pairs(EXTRA_FIELDS) do
        if extra[k] ~= nil and #fields < 22 then fields[#fields + 1] = { name = label, value = trunc(extra[k], 1024), inline = true } used[k] = true end
    end
    if entry.coords then fields[#fields + 1] = { name = 'Coords', value = ('%s, %s, %s'):format(entry.coords.x, entry.coords.y, entry.coords.z), inline = true } end
    if a and a.job then fields[#fields + 1] = { name = 'Job', value = trunc(a.job, 1024), inline = true } end
    if a and a.identifiers and (a.identifiers.license or a.identifiers.discord) then
        fields[#fields + 1] = { name = 'Identifiers', value = trunc(('%s · %s'):format(a.identifiers.license2 or a.identifiers.license or '-', a.identifiers.discord or '-'), 1024), inline = false }
    end
    local rest = {}
    local keys = {}
    for k in pairs(extra) do if not used[k] then keys[#keys + 1] = tostring(k) end end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local v = extra[k]
        if type(v) == 'table' then local ok, js = pcall(json.encode, v) v = ok and js or '?' end
        rest[#rest + 1] = ('%s: %s'):format(k, tostring(v))
    end
    if #rest > 0 and #fields < 25 then fields[#fields + 1] = { name = 'Extra', value = trunc(table.concat(rest, '\n'), 1000), inline = false } end
    while #fields > 25 do table.remove(fields) end
    local project = GetConvar('sv_projectName', 'server'):gsub('%^%d', '')
    local embed = {
        title = title,
        description = trunc(table.concat(desc, '\n'), 4096),
        fields = fields,
        footer = { text = ('#%s · %s · sev %s'):format(entry.uid, project, SEVERITY_LABEL[entry.severity] or entry.severity) },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', entry.ts // 1000),
        color = (w and w.color) or COLORS[action] or COLORS[aliasOf(action) or ''] or 0x2F3136,
    }
    if entry.item and type(cfg.itemImages) == 'string' and cfg.itemImages:match('^https?://') then
        embed.thumbnail = { url = ('%s/%s.png'):format(cfg.itemImages, entry.item) }
    end
    return embed
end

local function embedSize(e)
    local n = #(e.title or '') + #(e.description or '') + #(e.footer and e.footer.text or '')
    for _, f in ipairs(e.fields or {}) do n = n + #f.name + #tostring(f.value) end
    return n
end

-- ─── queue + rate limit (§6.4) ──────────────────────────────
local globalTokens = { n = 0, resetAt = 0 }

local function globalAllowed(now)
    if now >= globalTokens.resetAt then globalTokens = { n = 0, resetAt = now + 1000 } end
    if globalTokens.n >= limits.globalRatePerSecond then return false end
    globalTokens.n = globalTokens.n + 1
    return true
end

local flush

local function arm(w, ms)
    local q = queues[w.id]
    if q.timer then return end
    q.timer = true
    SetTimeout(ms, function() q.timer = false flush(w) end)
end

local function post(w, body, cb)
    PerformHttpRequest(w.url, cb, 'POST', json.encode(body), { ['Content-Type'] = 'application/json' })
end

local function retryAfter(headers)
    if type(headers) ~= 'table' then return nil end
    local v = headers['Retry-After'] or headers['retry-after'] or headers['x-ratelimit-reset-after'] or headers['X-RateLimit-Reset-After']
    return tonumber(v)
end

local function fail(w, batch, status, retry)
    local st = w.stats
    st.consecutiveFailures = st.consecutiveFailures + 1
    st.failed = st.failed + #batch
    st.lastStatus = status
    st.lastError = 'HTTP ' .. tostring(status)
    if retry then
        local q = queues[w.id]
        for i = #batch, 1, -1 do table.insert(q.items, 1, batch[i]) end
    end
    if st.consecutiveFailures >= 5 and not st.autoDisabled then
        st.autoDisabled = true
        lib.print.warn(('[rw-webhooks] webhook %s auto-disabled after %d failures (%s)'):format(w.id, st.consecutiveFailures, st.lastError))
        Log.record('webhook_error', { extra = { id = w.id, status = status, error = st.lastError } })
    end
end

flush = function(w)
    -- A timer armed on an OLD record (rebuild() replaces them on every
    -- edit) kept posting the queue to the old URL after a disable, a
    -- delete or a URL rotation. Always flush the CURRENT record.
    local cur = find(w.id)
    if not cur then queues[w.id] = nil return end
    w = cur
    local q = queues[w.id]
    if not q or #q.items == 0 then return end
    if not w.enabled or not w.url or w.stats.autoDisabled then q.items = {} return end
    local now = GetGameTimer()
    if q.inFlight then arm(w, 250) return end
    if now < q.nextAllowedAt then arm(w, q.nextAllowedAt - now) return end
    if not globalAllowed(now) then arm(w, 300) return end
    local raw = { retried = q.retried }
    q.retried = nil
    local embeds, size = {}, 0
    while #q.items > 0 and #embeds < 10 do
        local entry = q.items[1]
        local e = Webhook.embed(entry, w)
        local s = embedSize(e)
        if #embeds > 0 and size + s > 5800 then break end
        table.remove(q.items, 1)
        embeds[#embeds + 1] = e
        raw[#raw + 1] = entry
        size = size + s
    end
    local body = { username = w.username or 'ox_inventory', content = w.mention, allowed_mentions = { parse = { 'roles', 'users', 'everyone' } }, embeds = embeds }
    if w.avatar then body.avatar_url = w.avatar end
    q.inFlight = true
    q.nextAllowedAt = now + math.floor(1000 / limits.ratePerSecond)
    post(w, body, function(status, _, headers)
        q.inFlight = false
        status = tonumber(status) or 0
        local st = w.stats
        st.lastStatus = status
        if status >= 200 and status < 300 then
            st.sent = st.sent + #raw
            st.consecutiveFailures = 0
            st.lastError = nil
            st.lastSentAt = os.time()
        elseif status == 429 then
            local secs = retryAfter(headers) or 2
            q.nextAllowedAt = GetGameTimer() + math.ceil(secs * 1000) + 250
            for i = #raw, 1, -1 do table.insert(q.items, 1, raw[i]) end
        elseif status == 401 or status == 403 or status == 404 then
            fail(w, raw, status, false)
        else
            -- other 4xx/5xx/0: retried once, then dropped
            local wasRetry = raw.retried == true
            fail(w, raw, status, not wasRetry)
            q.retried = (not wasRetry) and true or nil
        end
        if #q.items > 0 then arm(w, math.max(limits.flushMs, q.nextAllowedAt - GetGameTimer())) end
    end)
end

local function enqueue(w, entry)
    local q = queues[w.id]
    q.items[#q.items + 1] = entry
    if #q.items > limits.maxQueue then
        table.remove(q.items, 1)
        w.stats.dropped = w.stats.dropped + 1
    end
    if #q.items >= 10 then flush(w) else arm(w, limits.flushMs) end
end

-- ─── router (§6.3) ──────────────────────────────────────────
local function matchesItem(w, item)
    if #w.items == 0 then return true end
    if not item then return false end
    local lower = item:lower()
    if w._itemExact[lower] then return true end
    for i = 1, #w._itemPats do if lower:match(w._itemPats[i]) then return true end end
    return false
end

local function idInSet(id, set)
    local ids = id and id.identifiers
    if not ids then return false end
    for _, v in pairs(ids) do
        if type(v) == 'string' and set[v:lower()] then return true end
    end
    return false
end

function Webhook.matches(w, entry)
    if not w.enabled or not w.url or w.stats.autoDisabled then return false end
    if entry.severity < w.severityMin then return false end
    local viaReceive = false
    if not w._all then
        if not w._eventSet[entry.action] then return false end
        if entry.action == 'give' and w._receive and not w._eventSet.__give_direct then viaReceive = true end
    end
    if not matchesItem(w, entry.item) then return false end
    if w.minCount > 0 and (entry.count or 0) < w.minCount then return false end
    if #w.players > 0 then
        if viaReceive then
            if not idInSet(entry.target, w._playerSet) then return false end
        else
            if not (idInSet(entry.actor, w._playerSet) or idInSet(entry.target, w._playerSet)) then return false end
        end
    end
    return true
end

function Webhook.route(entry)
    for i = 1, #effective do
        local w = effective[i]
        if Webhook.matches(w, entry) then enqueue(w, entry) end
    end
end

-- 'receive' alias: when a webhook lists both 'give' and 'receive', players
-- are checked on either side; when only 'receive', target only.
local function markDirectGive(w)
    for _, e in ipairs(w.events) do if e == 'give' or e == 'movement' or e == '*' then w._eventSet.__give_direct = true end end
end

local originalRebuild = rebuild
rebuild = function()
    originalRebuild()
    for _, w in ipairs(effective) do markDirectGive(w) end
end

Log.addSink(function(entry) Webhook.route(entry) end)

-- ─── admin handlers ─────────────────────────────────────────
local function newId()
    local chars = '0123456789abcdefghijklmnopqrstuvwxyz'
    local out = {}
    for i = 1, 8 do local k = math.random(1, 36) out[i] = chars:sub(k, k) end
    return 'wh_' .. table.concat(out)
end

Admin.register('webhooksGet', function()
    local actions = {}
    for k in pairs(Log.ACTIONS) do actions[#actions + 1] = k end
    table.sort(actions)
    return { webhooks = Webhook.list(), limits = { max = MAX_WEBHOOKS, ratePerSecond = limits.ratePerSecond, maxQueue = limits.maxQueue }, actions = actions }
end)

Admin.register('webhooksSet', function(src, p)
    local op = p.op
    local id = capStr(p.id, 32) or (type(p.webhook) == 'table' and capStr(p.webhook.id, 32))
    if op == 'upsert' then
        local input = type(p.webhook) == 'table' and p.webhook or nil
        if not input then return false, 'bad_payload' end
        local existing = id and (store.overrides[id] or seeds[id]) or nil
        local isNew = existing == nil
        if isNew then
            if #effective >= MAX_WEBHOOKS then return false, 'too_many' end
            input.id = id or newId()
            id = input.id
        end
        local rec, err = sanitizeWebhook(input, existing)
        if not rec then return false, err end
        local urlChanged = type(input.url) == 'string' and input.url ~= '' and input.url ~= (existing and existing.url)
        rec.seed = seeds[id] ~= nil
        store.overrides[id] = rec
        store.deleted[id] = nil
        if urlChanged and Webhook._stats and Webhook._stats[id] then
            Webhook._stats[id].autoDisabled = false
            Webhook._stats[id].consecutiveFailures = 0
        end
        saveStore()
        rebuild()
        Log.record('webhook_edit', { actor = src, extra = { id = id, op = isNew and 'create' or 'update', urlChanged = urlChanged } })
        return { webhooks = Webhook.list() }
    end
    if not id then return false, 'bad_payload' end
    local w = find(id)
    if op == 'delete' then
        if not w then return false, 'not_found' end
        if seeds[id] then
            store.deleted[id] = true
        end
        store.overrides[id] = nil
        saveStore()
        rebuild()
        Log.record('webhook_edit', { actor = src, extra = { id = id, op = 'delete', urlChanged = false } })
        return { webhooks = Webhook.list() }
    end
    if op == 'enable' or op == 'disable' then
        if not w then return false, 'not_found' end
        local existing = store.overrides[id] or seeds[id]
        local rec = sanitizeWebhook({ id = id, enabled = op == 'enable' }, existing)
        if not rec then return false, 'bad_payload' end
        if op == 'enable' and not rec.url then return false, 'invalid_url' end
        rec.seed = seeds[id] ~= nil
        store.overrides[id] = rec
        if op == 'enable' and Webhook._stats and Webhook._stats[id] then
            Webhook._stats[id].autoDisabled = false
            Webhook._stats[id].consecutiveFailures = 0
        end
        saveStore()
        rebuild()
        Log.record('webhook_edit', { actor = src, extra = { id = id, op = op, urlChanged = false } })
        return { webhooks = Webhook.list() }
    end
    if op == 'reset' then
        if not seeds[id] then return false, 'not_found' end
        store.overrides[id] = nil
        store.deleted[id] = nil
        saveStore()
        rebuild()
        Log.record('webhook_edit', { actor = src, extra = { id = id, op = 'update', urlChanged = false, reset = true } })
        return { webhooks = Webhook.list() }
    end
    return false, 'bad_payload'
end, { write = true })

Admin.register('webhooksTest', function(src, p)
    local id = capStr(p.id, 32)
    local w = id and find(id)
    if not w or not w.url then return false, 'not_found' end
    local q = queues[w.id]
    local now = GetGameTimer()
    if q and now < q.nextAllowedAt then Wait(q.nextAllowedAt - now) end
    local body = {
        username = w.username or 'ox_inventory',
        embeds = { {
            title = 'ox_inventory · webhook test',
            description = ('Sent by **%s** (%s) from the admin panel'):format(GetPlayerName(src) or 'console', src),
            color = 0x57F287,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', os.time()),
        } },
    }
    if w.avatar then body.avatar_url = w.avatar end
    local p2 = promise.new()
    PerformHttpRequest(w.url, function(status) p2:resolve(tonumber(status) or 0) end, 'POST', json.encode(body), { ['Content-Type'] = 'application/json' })
    local status = Citizen.Await(p2)
    if q then q.nextAllowedAt = GetGameTimer() + math.floor(1000 / limits.ratePerSecond) end
    w.stats.lastStatus = status
    Log.record('webhook_test', { actor = src, extra = { id = id, status = status } })
    return { ok = status >= 200 and status < 300, status = status }
end, { write = true })

-- ─── boot ───────────────────────────────────────────────────
loadSeeds()
loadStore()
rebuild()

function Webhook.effective() return effective end
function Webhook.queue(id) return queues[id] end
function Webhook.reload() loadSeeds() loadStore() rebuild() end

server = server or {}
server.Webhook = Webhook

return Webhook
