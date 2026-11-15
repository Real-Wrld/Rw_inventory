--  REALWRLD Software® · ox_inventory · locale loader (shared)
-- ═════════════════════════════════════════════════════════════
--
--  Reads the nested `ui` block of `locales/<lang>.json` for the NUI
--  (design: maps/i18n.md §5). ox_lib keeps handling the flat keys for
--  `locale()`; this module only serves the page.
-- ═════════════════════════════════════════════════════════════

local Locale = {}

local cache = {}        -- lang -> { ui = table|nil, language = string|nil } | false (file missing)
local LANG_RE = '^[%a][%w%-]*$'

---Deep merge `over` onto a copy of `base` (strings replace, tables recurse).
---@param base table
---@param over table?
---@return table
function Locale.merge(base, over)
    local out = {}
    for k, v in pairs(base) do
        out[k] = type(v) == 'table' and Locale.merge(v, nil) or v
    end
    if type(over) == 'table' then
        for k, v in pairs(over) do
            if type(v) == 'table' and type(out[k]) == 'table' then
                out[k] = Locale.merge(out[k], v)
            elseif type(v) == 'table' then
                out[k] = Locale.merge(v, nil)
            elseif v ~= nil then
                out[k] = v
            end
        end
    end
    return out
end

---@param lang string
---@return boolean
function Locale.validLang(lang)
    return type(lang) == 'string' and #lang >= 2 and #lang <= 12 and lang:match(LANG_RE) ~= nil
end

---Read `locales/<lang>.json` once per language. A file without a `ui`
---block (or an invalid file) yields `{ ui = nil }`, never an error.
---@param lang string
---@return { ui: table?, language: string? }|false
function Locale.read(lang)
    if not Locale.validLang(lang) then return false end
    local c = cache[lang]
    if c ~= nil then return c end

    local raw = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(lang))
    -- a miss is not cached: every random code a client sent grew the table for good
    if not raw then return false end

    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then
        cache[lang] = { ui = nil, language = nil, broken = true }
        return cache[lang]
    end

    cache[lang] = {
        ui = type(data.ui) == 'table' and data.ui or nil,
        language = type(data.language) == 'string' and data.language or nil,
    }
    return cache[lang]
end

---@param lang string
---@return boolean
function Locale.exists(lang)
    return Locale.read(lang) ~= false
end

---Effective `ui` block for a language: `en` deep-merged with `<lang>`.
---@param lang string
---@return table ui, string resolvedLang
function Locale.ui(lang)
    local en = Locale.read('en')
    local base = en and en.ui or {}
    if lang == 'en' or not Locale.validLang(lang) then return Locale.merge(base, nil), 'en' end
    local f = Locale.read(lang)
    if not f then return Locale.merge(base, nil), 'en' end
    return Locale.merge(base, f.ui), lang
end

---Selection chain: player choice → RWInv.Locale → ox:locale convar → en.
---@param requested string? player choice (nil / 'auto' = none)
---@param configLocale string? RWInv.Locale
---@return string lang
function Locale.select(requested, configLocale)
    if Locale.validLang(requested) and requested ~= 'auto' and Locale.exists(requested) then return requested end
    if Locale.validLang(configLocale) and configLocale ~= 'auto' and Locale.exists(configLocale) then return configLocale end
    local convar = GetConvar('ox:locale', 'en')
    if Locale.validLang(convar) and Locale.exists(convar) then return convar end
    return 'en'
end

---Forget cached files (admin reload).
function Locale.reset()
    cache = {}
end

return Locale
