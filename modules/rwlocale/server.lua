--  REALWRLD Software® · ox_inventory · locale loader (server)
-- ═════════════════════════════════════════════════════════════
--
--  Serves the nested `ui` block of a language to a client:
--    callback `ox_inventory:rwLocale(lang)` → { locale, ui, languages }
--  Files are read once per language (LoadResourceFile + json.decode)
--  and `<lang>.ui` is deep-merged over `en.ui`, so a partially
--  translated file still yields every key.
-- ═════════════════════════════════════════════════════════════

if not lib then return end

local Locale = require 'modules.rwlocale.shared'
local conf = require 'modules.rwconfig.shared'.Get()

local KNOWN = {
    'en', 'pt', 'es', 'fr', 'de', 'it', 'lt', 'pl', 'nl', 'ru', 'tr',
    'ar', 'cs', 'da', 'el', 'et', 'fi', 'hr', 'hu', 'id', 'ja', 'ko', 'no', 'pt-br', 'ro', 'sl', 'sr', 'sv', 'zh-cn', 'zh-tw',
}

local languages -- [{ code, name, ui = bool }]

local function listLanguages()
    if languages then return languages end
    languages = {}
    for _, code in ipairs(KNOWN) do
        local f = Locale.read(code)
        if f then
            languages[#languages + 1] = { code = code, name = f.language or code, ui = f.ui ~= nil }
        end
    end
    return languages
end

---@param source number
---@param lang string? player choice ('auto' / nil = server default)
---@return { locale: string, ui: table, languages: table }
-- The merged "ui" block is ~100 KB: built once per language, and a client
-- may ask for it at most once a second.
local uiByLang = {}
local lastAsk = {}

AddEventHandler('playerDropped', function() lastAsk[source] = nil end)

lib.callback.register('ox_inventory:rwLocale', function(source, lang)
    local now = GetGameTimer()

    if source and source > 0 then
        if lastAsk[source] and now - lastAsk[source] < 1000 then return end
        lastAsk[source] = now
    end

    local chosen = Locale.select(lang, conf.Locale)
    local entry = uiByLang[chosen]

    if not entry then
        local ui, resolved = Locale.ui(chosen)
        entry = { ui = ui, resolved = resolved }
        uiByLang[chosen] = entry
    end

    return { locale = entry.resolved, ui = entry.ui, languages = listLanguages() }
end)

exports('GetUiLocale', function(lang)
    local ui, resolved = Locale.ui(Locale.select(lang, conf.Locale))
    return ui, resolved
end)

return Locale
