--  REALWRLD Software® · ox_inventory · Pocket slot · shared
-- ═════════════════════════════════════════════════════════════
--
--  Pure helpers (no natives): the config sanitizer and the blacklist
--  matcher, used by the server module (modules/rwpocket/server.lua),
--  the client relay and the harness. The NUI mirrors `blocked()` in
--  web/src/lib/pocket.ts (same rules: exact names and `PREFIX*`
--  patterns, case-insensitive).
-- ═════════════════════════════════════════════════════════════

local Shared = {}

Shared.DEFAULTS = {
    enabled = false,
    safeOnDeath = true,
    countWeight = true,
    blacklist = { 'money', 'black_money', 'WEAPON_*' },
    graceSeconds = 15,
}
Shared.MAX_BLACKLIST = 100
Shared.NAME_MAX = 64

---A blacklist entry: an item name, or a prefix pattern ending with `*`
---(`WEAPON_*`, `ammo-*`). Trimmed; anything else is dropped.
---@param v any
---@return string?
function Shared.cleanEntry(v)
    if type(v) ~= 'string' then return nil end
    v = v:gsub('^%s+', ''):gsub('%s+$', '')
    if v == '' or #v > Shared.NAME_MAX then return nil end
    if not v:match('^[%w_%-%.]+%*?$') and v ~= '*' then return nil end
    return v
end

---Unique, cleaned, capped entries (first spelling wins, compared lower-case).
---@param list any
---@return string[]
function Shared.cleanList(list)
    local out, seen = {}, {}
    if type(list) ~= 'table' then return out end
    for i = 1, #list do
        local e = Shared.cleanEntry(list[i])
        if e and not seen[e:lower()] then
            seen[e:lower()] = true
            out[#out + 1] = e
            if #out >= Shared.MAX_BLACKLIST then break end
        end
    end
    return out
end

---config.lua `RWInv.PocketSlot` (+ admin overrides) → a complete, typed table.
---@param raw table?
---@return { enabled: boolean, safeOnDeath: boolean, countWeight: boolean, blacklist: string[], graceSeconds: number }
function Shared.sanitize(raw)
    raw = type(raw) == 'table' and raw or {}
    local d = Shared.DEFAULTS
    local function bool(v, def) if type(v) == 'boolean' then return v end return def end
    local grace = tonumber(raw.graceSeconds)
    grace = grace and math.floor(grace) or d.graceSeconds
    if grace < 0 then grace = 0 elseif grace > 300 then grace = 300 end
    return {
        enabled = bool(raw.enabled, d.enabled),
        safeOnDeath = bool(raw.safeOnDeath, d.safeOnDeath),
        countWeight = bool(raw.countWeight, d.countWeight),
        blacklist = type(raw.blacklist) == 'table' and Shared.cleanList(raw.blacklist) or Shared.cleanList(d.blacklist),
        graceSeconds = grace,
    }
end

---Compiles a blacklist into lookup sets: exact names and prefixes (lower-case).
---@param list string[]
---@return { exact: table<string, true>, prefixes: string[], all: boolean }
function Shared.compile(list)
    local c = { exact = {}, prefixes = {}, all = false }
    for i = 1, #(list or {}) do
        local e = tostring(list[i]):lower()
        if e == '*' then
            c.all = true
        elseif e:sub(-1) == '*' then
            c.prefixes[#c.prefixes + 1] = e:sub(1, -2)
        else
            c.exact[e] = true
        end
    end
    return c
end

---@param compiled { exact: table<string, true>, prefixes: string[], all: boolean }
---@param name string
---@return boolean
function Shared.blocked(compiled, name)
    if type(name) ~= 'string' or not compiled then return false end
    if compiled.all then return true end
    local n = name:lower()
    if compiled.exact[n] then return true end
    for i = 1, #compiled.prefixes do
        local p = compiled.prefixes[i]
        if n:sub(1, #p) == p then return true end
    end
    return false
end

return Shared
