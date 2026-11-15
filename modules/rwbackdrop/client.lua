if not lib then return end

-- ═════════════════════════════════════════════════════════════
--  REALWRLD · ox_inventory · background blur (player setting `bgBlur`)
--
--  Readability over busy scenes (inside vehicles, bright streets). Uses
--  the GAME's own screen blur (TriggerScreenblurFadeIn) — the NUI can
--  never blur what is behind it: CSS backdrop-filter paints black in the
--  FiveM browser.
--
--    off      never
--    vehicle  while the player sits in a vehicle, or the open container
--             is a glovebox / trunk            (default)
--    always   every time the inventory is open
--
--  The screen blur also blurs the player ped, so it is lifted whenever
--  the showcase character (ped preview camera) is on screen.
--  The server convar `inventory:screenblur true` still forces the blur
--  for everyone (upstream behaviour, handled in client.lua).
-- ═════════════════════════════════════════════════════════════

local KVP_KEY = 'oxinv_bgblur'
local MODES = { off = true, vehicle = true, always = true }

local mode = GetResourceKvpString(KVP_KEY)
if not MODES[mode] then mode = 'vehicle' end

local uiOpen = false
local rightType = nil
local pedPreview = false
local blurred = false
local pending = 0 -- generation counter for the delayed evaluation

local function wantBlur()
    if not uiOpen or mode == 'off' or pedPreview then return false end
    if mode == 'always' then return true end
    -- vehicle
    if rightType == 'glovebox' or rightType == 'trunk' then return true end
    local ped = cache.ped or PlayerPedId()
    return ped ~= 0 and IsPedInAnyVehicle(ped, false)
end

local function apply()
    local want = wantBlur()
    if want == blurred then return end
    blurred = want

    if IsScreenblurFadeRunning() then DisableScreenblurFade() end

    if want then
        TriggerScreenblurFadeIn(180)
    else
        TriggerScreenblurFadeOut(150)
    end
end

-- The ped preview starts one NUI round-trip after the inventory opens: wait
-- a moment before blurring so the showcase character is never blurred and
-- then un-blurred (a visible flash).
local function evaluateSoon(delay)
    pending += 1
    local gen = pending
    SetTimeout(delay or 140, function()
        if gen == pending then apply() end
    end)
end

AddEventHandler('ox_inventory:uiOpen', function(invType)
    uiOpen = true
    rightType = invType
    evaluateSoon()
end)

AddEventHandler('ox_inventory:uiClose', function()
    uiOpen = false
    rightType = nil
    pending += 1
    apply()
end)

AddEventHandler('ox_inventory:pedPreviewState', function(on)
    pedPreview = on == true
    if uiOpen then apply() end
end)

-- NUI setting (Settings › Effects › Background)
RegisterNUICallback('rwBackdrop', function(data, cb)
    local m = type(data) == 'table' and data.blur
    if MODES[m] and m ~= mode then
        mode = m
        SetResourceKvp(KVP_KEY, m)
        if uiOpen then apply() end
    end
    cb(1)
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynBackdrop', function(data, cb)
    local m = type(data) == 'table' and data.blur
    if MODES[m] and m ~= mode then
        mode = m
        SetResourceKvp(KVP_KEY, m)
        if uiOpen then apply() end
    end
    cb(1)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= cache.resource then return end
    if blurred then
        if IsScreenblurFadeRunning() then DisableScreenblurFade() end
        TriggerScreenblurFadeOut(0)
    end
end)
