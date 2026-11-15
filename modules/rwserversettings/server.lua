--  REALWRLD Software® · ox_inventory · Server-scope settings (server)
-- ═════════════════════════════════════════════════════════════
--
--  Typed, admin-editable server settings for logs / webhooks / shop
--  sell / clothing (design/admin-logs.md §10). KVP `rw:serverSettings`
--  holds only values that differ from config.lua; effective value =
--  KVP → config.lua → schema default. Drops server keys are owned by
--  modules/rwdrops (forwarded through Admin.invoke).
-- ═════════════════════════════════════════════════════════════

if not lib then return end

local config = require 'modules.rwconfig.shared'.Get()
local Log = require 'modules.rwlogs.server'
local Admin = require 'modules.rwadmin.server'

local KVP_KEY = 'rw:serverSettings'
local Settings = {}

local function cfgPath(...)
    local v = config
    for _, k in ipairs({ ... }) do
        if type(v) ~= 'table' then return nil end
        v = v[k]
    end
    return v
end

-- path, type, default, min, max, step, options, restart, group, live
local SCHEMA = {
    { path = 'logs.enabled', type = 'bool', default = true, cfg = { 'Logs', 'enabled' }, group = 'logs', live = 'logs' },
    { path = 'logs.level', type = 'int', default = 2, min = 0, max = 3, step = 1, cfg = { 'Logs', 'level' }, group = 'logs', live = 'logs' },
    { path = 'logs.retentionDays', type = 'int', default = 30, min = 0, max = 3650, step = 1, cfg = { 'Logs', 'retentionDays' }, group = 'logs' },
    { path = 'logs.maxRows', type = 'int', default = 0, min = 0, max = 50000000, step = 1000, cfg = { 'Logs', 'maxRows' }, group = 'logs' },
    { path = 'logs.ringSize', type = 'int', default = 2000, min = 500, max = 5000, step = 100, cfg = { 'Logs', 'ringSize' }, group = 'logs', restart = true },
    { path = 'webhooks.ratePerSecond', type = 'number', default = 2, min = 1, max = 5, step = 0.5, cfg = { 'Webhooks', 'ratePerSecond' }, group = 'webhooks', live = 'webhooks' },
    { path = 'webhooks.globalRatePerSecond', type = 'number', default = 8, min = 1, max = 20, step = 1, cfg = { 'Webhooks', 'globalRatePerSecond' }, group = 'webhooks', live = 'webhooks' },
    { path = 'webhooks.maxQueue', type = 'int', default = 200, min = 20, max = 2000, step = 10, cfg = { 'Webhooks', 'maxQueue' }, group = 'webhooks', live = 'webhooks' },
    { path = 'webhooks.flushMs', type = 'int', default = 1500, min = 500, max = 10000, step = 100, cfg = { 'Webhooks', 'flushMs' }, group = 'webhooks', live = 'webhooks' },
    { path = 'shop.sellEnabled', type = 'bool', default = false, cfg = { 'Shop', 'sell', 'enabled' }, group = 'shop' },
    { path = 'shop.sellRate', type = 'number', default = 0.5, min = 0, max = 1, step = 0.05, cfg = { 'Shop', 'sell', 'rate' }, group = 'shop' },
    { path = 'shop.sellPayTo', type = 'enum', default = 'cash', options = { 'cash', 'bank' }, cfg = { 'Shop', 'sell', 'payTo' }, group = 'shop' },
    { path = 'shop.sellDurabilityScaled', type = 'bool', default = true, cfg = { 'Shop', 'sell', 'durabilityScaled' }, group = 'shop' },
    { path = 'clothing.enabled', type = 'bool', default = true, cfg = { 'Clothing', 'enabled' }, group = 'clothing', restart = true },
}
local BY_PATH = {}
for _, f in ipairs(SCHEMA) do BY_PATH[f.path] = f end
Settings.SCHEMA = SCHEMA

local EDITOR_KEY_MAP = {
    dropsEnabled = 'drops:enabled', dropsMode = 'drops:mode', dropsPhysics = 'drops:physics', dropsKeepPhysics = 'drops:keepPhysics',
    dropsMaxProps = 'drops:maxProps', dropsScatterRadius = 'drops:scatterRadius', dropsRenderDistance = 'drops:renderDistance',
    dropsPromptDistance = 'drops:promptDistance', dropsLifetimeMin = 'drops:lifetimeMinutes', dropsWeaponProps = 'drops:weaponProps',
    logRetentionDays = 'logs.retentionDays',
}
Settings.EDITOR_KEY_MAP = EDITOR_KEY_MAP

local values = {}   -- overrides only
-- JSON `null` never survives json.decode (nil keys vanish), so the NUI
-- clears an override with `clear: [path, ...]`; internally that is this sentinel.
Settings.CLEAR = setmetatable({}, { __tostring = function() return 'CLEAR' end })

local function configDefault(f)
    local v = cfgPath(table.unpack(f.cfg))
    if v == nil then return f.default end
    return v
end

---Validates a value against a field. Returns value | nil, err.
local function coerce(f, v)
    if f.type == 'bool' then
        if type(v) ~= 'boolean' then return nil, 'bad_payload' end
        return v
    elseif f.type == 'int' or f.type == 'number' then
        v = tonumber(v)
        if v == nil or v ~= v then return nil, 'bad_payload' end
        if f.type == 'int' then v = math.floor(v) end
        if f.min and v < f.min then return nil, 'bad_payload' end
        if f.max and v > f.max then return nil, 'bad_payload' end
        return v
    elseif f.type == 'enum' then
        for _, o in ipairs(f.options) do if o == v then return v end end
        return nil, 'bad_payload'
    end
    return nil, 'bad_payload'
end

local function load()
    values = {}
    local raw = GetResourceKvpString(KVP_KEY)
    if not raw then return end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' or type(decoded.values) ~= 'table' then return end
    for path, v in pairs(decoded.values) do
        local f = BY_PATH[path]
        if f then
            local cv = coerce(f, v)
            if cv ~= nil then values[path] = cv end
        end
    end
end

local function save()
    SetResourceKvp(KVP_KEY, json.encode({ v = 1, values = values }))
end

function Settings.get(path)
    local f = BY_PATH[path]
    if not f then return nil end
    local v = values[path]
    if v ~= nil then return v end
    return configDefault(f)
end

function Settings.overrides()
    local out = {}
    for k, v in pairs(values) do out[k] = v end
    return out
end

local function applyLive(groups)
    if groups.logs and Log.refreshLevel then Log.refreshLevel() end
    if groups.webhooks and server and server.Webhook and server.Webhook.refreshLimits then server.Webhook.refreshLimits() end
end

local function publicSchema()
    local out = {}
    for i, f in ipairs(SCHEMA) do
        out[i] = { path = f.path, type = f.type, default = configDefault(f), min = f.min, max = f.max, step = f.step, options = f.options, restart = f.restart == true, group = f.group, live = f.live ~= nil }
    end
    return out
end

local function currentValues()
    local out = {}
    for _, f in ipairs(SCHEMA) do out[f.path] = Settings.get(f.path) end
    return out
end

local function restartList()
    local out = {}
    for _, f in ipairs(SCHEMA) do
        if f.restart and values[f.path] ~= nil then out[#out + 1] = f.path end
    end
    return out
end

local function dropsConfig(src)
    if not Admin.has('drops.getConfig') then return nil end
    local ok, res = Admin.invoke(src, 'drops.getConfig', {})
    return ok and res or nil
end

-- Pocket slot keys are owned by modules/rwpocket (pocket.getConfig / pocket.setConfig).
local function pocketConfig(src)
    if not Admin.has('pocket.getConfig') then return nil end
    local ok, res = Admin.invoke(src, 'pocket.getConfig', {})
    return ok and res or nil
end

local function getResult(src)
    return { schema = publicSchema(), values = currentValues(), overrides = Settings.overrides(), restartRequired = restartList(), drops = dropsConfig(src), pocket = pocketConfig(src) }
end

---Applies { [path] = value|json.null } overrides. Returns changed[], restart[] | nil, err.
function Settings.set(src, input)
    if type(input) ~= 'table' then return nil, 'bad_payload' end
    local changes = {}
    for path, v in pairs(input) do
        local f = BY_PATH[path]
        if not f then return nil, 'bad_payload' end
        if v == nil or v == Settings.CLEAR then
            changes[#changes + 1] = { f = f, clear = true }
        else
            local cv, err = coerce(f, v)
            if cv == nil then return nil, err end
            changes[#changes + 1] = { f = f, value = cv }
        end
    end
    local changed, restart, live = {}, {}, {}
    local audit = {}
    for _, c in ipairs(changes) do
        local f = c.f
        local old = Settings.get(f.path)
        if c.clear then values[f.path] = nil
        elseif c.value == configDefault(f) then values[f.path] = nil
        else values[f.path] = c.value end
        local new = Settings.get(f.path)
        if old ~= new then
            changed[#changed + 1] = f.path
            audit[f.path] = { old = old, new = new }
            if f.restart then restart[#restart + 1] = f.path end
            if f.live then live[f.live] = true end
        end
    end
    if #changed > 0 then
        save()
        applyLive(live)
        Log.record('server_settings_edit', { actor = src, extra = { module = 'server', changed = audit } })
    end
    return changed, restart
end

Admin.register('serverSettingsGet', function(src) return getResult(src) end)
Admin.register('settings.get', function(src) return getResult(src) end)

local function setHandler(src, p)
    local input = {}
    if type(p.values) == 'table' then for k, v in pairs(p.values) do input[k] = v end end
    if type(p.clear) == 'table' then for _, k in ipairs(p.clear) do if type(k) == 'string' then input[k] = Settings.CLEAR end end end
    local dropsOverrides = type(p.drops) == 'table' and p.drops or nil
    -- JSON null never reaches Lua: cleared drops keys travel as `dropsClear = { key, ... }`
    -- and are forwarded as `clear` next to `overrides` (drops.setConfig contract, WP4).
    local dropsClear = nil
    if type(p.dropsClear) == 'table' and p.dropsClear[1] then
        dropsClear = {}
        for _, k in ipairs(p.dropsClear) do if type(k) == 'string' then dropsClear[#dropsClear + 1] = k end end
        dropsOverrides = dropsOverrides or {}
    end
    if type(p.settings) == 'table' then
        for k, v in pairs(p.settings) do
            local target = EDITOR_KEY_MAP[k]
            if not target then return false, 'bad_payload' end
            local dropKey = target:match('^drops:(.+)$')
            if dropKey then
                dropsOverrides = dropsOverrides or {}
                dropsOverrides[dropKey] = v
            else
                input[target] = v
            end
        end
    end
    -- pocket slot: { pocket = { enabled?, safeOnDeath?, countWeight?, blacklist? }, pocketClear = { key, … } }
    local pocketOverrides = type(p.pocket) == 'table' and p.pocket or nil
    local pocketClear = nil
    if type(p.pocketClear) == 'table' and p.pocketClear[1] then
        pocketClear = {}
        for _, k in ipairs(p.pocketClear) do if type(k) == 'string' then pocketClear[#pocketClear + 1] = k end end
    end
    local changed, restart = Settings.set(src, input)
    if not changed then return false, restart end
    if pocketOverrides or pocketClear then
        if not Admin.has('pocket.setConfig') then return false, 'feature_disabled' end
        local ok, res = Admin.invoke(src, 'pocket.setConfig', { overrides = pocketOverrides, clear = pocketClear })
        if not ok then return false, res end
        for k in pairs(type(res) == 'table' and res.changed or {}) do changed[#changed + 1] = 'pocket:' .. k end
    end
    if dropsOverrides then
        if not Admin.has('drops.setConfig') then return false, 'feature_disabled' end
        local ok, err = Admin.invoke(src, 'drops.setConfig', { overrides = dropsOverrides, clear = dropsClear })
        if not ok then return false, err end
        for k in pairs(dropsOverrides) do changed[#changed + 1] = 'drops:' .. k end
        for _, k in ipairs(dropsClear or {}) do changed[#changed + 1] = 'drops:' .. k end
    end
    local res = getResult(src)
    res.changed = changed
    res.restartRequired = restart
    for _, p2 in ipairs(restartList()) do
        local seen = false
        for _, r in ipairs(res.restartRequired) do if r == p2 then seen = true break end end
        if not seen then res.restartRequired[#res.restartRequired + 1] = p2 end
    end
    return res
end

Admin.register('serverSettingsSet', setHandler, { write = true })
Admin.register('settings.set', setHandler, { write = true })

load()
applyLive({ logs = true, webhooks = true })

server = server or {}
server.RWSettings = Settings

return Settings
