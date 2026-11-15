--  REALWRLD Software® · ox_inventory · locale loader (client)
-- ═════════════════════════════════════════════════════════════
--
--  Pushes the nested `ui` block to the NUI (`oxlynLocale` message):
--    • once the page is ready (after `uiLoaded`) and the player loaded;
--    • again on the `oxlynLocaleSet` NUI callback (the language picker
--      in the settings editor) — the choice is stored client-side in
--      the KVP `oxinv_language` ('auto' = follow the server);
--    • again when ox_lib switches its locale (`ox_lib:setLocale`).
--  The server resolves the chain player → RWInv.Locale → ox:locale → en.
-- ═════════════════════════════════════════════════════════════

if not lib then return end

local KVP = 'oxinv_language'
local current = { locale = nil, ui = nil, languages = nil }
local pushing = false

local function choice()
    local v = GetResourceKvpString(KVP)
    if type(v) == 'string' and v ~= '' then return v end
    return nil
end

local function push()
    if not current.ui then return end
    SendNUIMessage({
        action = 'oxlynLocale',
        data = { locale = current.locale, ui = current.ui, languages = current.languages, choice = choice() or 'auto' },
    })
end

---Fetch the ui block for the player's choice (or the server default) and push it.
---@param lang string?
local function refresh(lang)
    if pushing then return end
    pushing = true

    -- ("false": ox_lib's second argument is a per-event cooldown that answers
    -- nil inside the window: a language picked within 5 s of the last refresh
    -- was saved but never shown; the server throttles instead)
    local data = lib.callback.await('ox_inventory:rwLocale', false, lang or choice())
    pushing = false

    if type(data) ~= 'table' or type(data.ui) ~= 'table' then return false end

    current.locale = data.locale
    current.ui = data.ui
    current.languages = data.languages
    push()
    return true
end

RegisterNUICallback('rwLocaleSet', function(data, cb)
    cb(1)
    local lang = type(data) == 'table' and data.locale or nil
    if type(lang) ~= 'string' or lang == '' or lang == 'auto' then
        DeleteResourceKvp(KVP)
        lang = nil
    elseif not lang:match('^[%a][%w%-]*$') or #lang > 12 then
        return
    else
        SetResourceKvp(KVP, lang)
    end
    refresh(lang)
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynLocaleSet', function(data, cb)
    cb(1)
    local lang = type(data) == 'table' and data.locale or nil
    if type(lang) ~= 'string' or lang == '' or lang == 'auto' then
        DeleteResourceKvp(KVP)
        lang = nil
    elseif not lang:match('^[%a][%w%-]*$') or #lang > 12 then
        return
    else
        SetResourceKvp(KVP, lang)
    end
    refresh(lang)
end)

-- The page asks again when it (re)mounts.
RegisterNUICallback('rwLocaleRequest', function(_, cb)
    cb(1)
    if current.ui then push() else refresh() end
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynLocaleRequest', function(_, cb)
    cb(1)
    if current.ui then push() else refresh() end
end)

AddEventHandler('ox_lib:setLocale', function()
    -- only matters while the player follows the server / ox_lib default
    if not choice() then refresh() end
end)

CreateThread(function()
    while not client.uiLoaded or not PlayerData or not PlayerData.loaded do Wait(500) end

    for _ = 1, 5 do
        if refresh() then return end
        Wait(2000)
    end
end)

exports('getUiLocale', function() return current.locale, current.ui end)
