if not lib then return end

-- ─────────────────────────────────────────────────────────────
--  ox_inventory · ped preview module (Quasar-style)
--    Scripted camera frames the real player ped. Background blur
--    is done via NUI backdrop-filter — NOT via timecycle — so the
--    ped stays crisp while the world behind blurs.
-- ─────────────────────────────────────────────────────────────

local CAM_DISTANCE = 4.4    -- further back so the full body fits comfortably
local CAM_HEIGHT   = 0.35   -- lower than chest → slight upward angle on the ped
local CAM_FOV      = 45.0
local AIM_OFFSET_Z = 0.55   -- aim closer to body centre so head/feet balance

local active = false
local cam    = nil

-- Horizontal screen position (0 = left edge, 1 = right edge) of the gap the
-- NUI keeps free for the ped (`.ped-spacer`), reported by the NUI through
-- `oxlynPedAnchor`. Layouts, docked panels and the fit-to-screen scaling
-- move that gap; the camera slides sideways so the ped stands in it instead
-- of always in the middle of the screen.
local anchorX = 0.5
-- vertical centre of the ped gap on screen (0 top … 1 bottom); 0.5 = the tuned full-body framing
local anchorY = 0.5

local function aspectRatio()
    local ok, ar = pcall(GetAspectRatio, false)
    if ok and type(ar) == 'number' and ar > 0.5 and ar < 5.0 then return ar end
    local w, h = GetActiveScreenResolution()
    if w and h and h > 0 then return w / h end
    return 16 / 9
end

-- Place the camera in front of the ped, shifted along the ped's right axis
-- so the ped lands at `anchorX` on screen. The camera faces the ped, so its
-- own left is the ped's right: moving it towards +x (ped right) makes the
-- ped appear further right. Shift = ndc * distance * tan(hfov / 2).
local function placeCam(ped)
    if not cam then return end
    local ndc = (anchorX - 0.5) * 2.0
    local halfV = math.rad(CAM_FOV) / 2.0
    local tanH = math.tan(halfV) * aspectRatio()
    local shift = ndc * CAM_DISTANCE * tanH
    -- a gap above the screen centre (anchorY < 0.5) lowers camera + aim by the same amount,
    -- so the ped rises on screen without the view angle changing
    local ndcY = (0.5 - anchorY) * 2.0
    local lift = -ndcY * CAM_DISTANCE * math.tan(halfV)
    local camPos = GetOffsetFromEntityInWorldCoords(ped, shift, CAM_DISTANCE, CAM_HEIGHT + lift)
    local aim = GetOffsetFromEntityInWorldCoords(ped, shift, 0.0, AIM_OFFSET_Z + lift)
    SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(cam, aim.x, aim.y, aim.z)
end

-- True between our FreezeEntityPosition(ped, true) and the matching release.
-- Tracked separately from `active` so a preview that never finished starting
-- (or one whose "stop" arrived through a different path) can still be undone —
-- a ped left frozen means a player who simply cannot move.
local frozeByUs = false

-- Is the inventory UI actually open RIGHT NOW? Driven by the two Lua-side
-- events (authoritative), never by the NUI.
--
-- Why this exists: `togglePedPreview` arrives from the NUI, so it is always
-- at least one frame late. The player can open the inventory and USE an item
-- (which closes it) before that message lands — the queued "enabled = true"
-- would then run startPreview() with the inventory already closed, freezing
-- the ped and wiping its tasks *while the item animation is playing*. The
-- player ends up stuck mid-animation with no UI to close.
local uiOpen = false

-- Reject a preview start while the player is mid-action (eating, drinking,
-- bandaging…). `ClearPedTasksImmediately` + `FreezeEntityPosition` would kill
-- the animation, and unfreezing makes GTA report a micro-fall for a few
-- frames, which ox_lib treats as a progress-bar INTERRUPT.
local function playerIsBusy()
    if lib.progressActive() then return true end
    return LocalPlayer.state.invBusy == true
end

---@param immediate boolean? when true, no easing — used on resource stop
local function destroyCam(immediate)
    if cam then
        if IsCamActive(cam) then SetCamActive(cam, false) end
        DestroyCam(cam, false)
        cam = nil
    end
    -- Always tell the engine to render the gameplay cam again.
    -- Without easing on resource stop: the script is about to die,
    -- there's no time to finish a 250ms transition.
    if immediate then
        RenderScriptCams(false, false, 0, true, false)
    else
        RenderScriptCams(false, true, 250, true, true)
    end
end

-- Hard cleanup for resource stop / restart. Runs synchronously and skips
-- easing so the game has no in-flight transition when the script dies.
local function hardCleanup()
    active = false
    uiOpen = false
    frozeByUs = false

    if cam then
        if IsCamActive(cam) then SetCamActive(cam, false) end
        DestroyCam(cam, false)
        cam = nil
    end
    RenderScriptCams(false, false, 0, true, false)
    ClearFocus()

    local ped = PlayerPedId()
    if ped and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        SetPedLodMultiplier(ped, 1.0)
        SetBlockingOfNonTemporaryEvents(ped, false)
        SetPedCanRagdoll(ped, true)
    end
end

local function startPreview()
    if active then return end

    -- The inventory closed before this (NUI-delayed) request reached us —
    -- starting now would freeze the ped with no way to unfreeze it.
    if not uiOpen then return end

    -- Mid-action (item use / progress bar): never touch the ped.
    if playerIsBusy() then return end

    local ped = PlayerPedId()
    if not ped or not DoesEntityExist(ped) then return end

    -- Safety net: never start preview while the player is in a vehicle.
    -- `ClearPedTasksImmediately` would yank them out of the seat and the
    -- camera framing makes no sense anyway. The compact layout in the
    -- NUI already skips firing `togglePedPreview(true)` for glovebox /
    -- trunk inventories, this guards every other path (NPC stash you
    -- open while parked, etc.).
    if IsPedInAnyVehicle(ped, false) then return end

    -- Skip preview when the ped is airborne / falling / ragdolling /
    -- swimming. FreezeEntityPosition below would otherwise kill the
    -- vertical velocity, and when the player closes the inventory the
    -- fall resumes at zero speed (the "fall freeze" bug). We also tell
    -- the NUI to force compact layout for this session so the user
    -- doesn't see a gap in the layout where the ped would have been.
    if IsPedFalling(ped)
        or IsPedInParachuteFreeFall(ped)
        or IsPedRagdoll(ped)
        or IsPedSwimming(ped)
        or IsEntityInAir(ped)
    then
        SendNUIMessage({
            action = 'oxlynForceCompact',
            data = { enabled = true },
        })
        return
    end

    -- Kill ALL active animations / scenarios / secondary tasks BEFORE we
    -- freeze. Any anim playing when the inventory opens (running, idle
    -- variations, scenarios, props) is gone instantly.
    ClearPedTasksImmediately(ped)
    ClearPedSecondaryTask(ped)
    SetPedCanRagdoll(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    frozeByUs = true

    -- Force streaming + HD LOD on the ped so the face texture is crisp
    -- from the new camera angle (otherwise GTA shows the lo-res LOD).
    SetFocusEntity(ped)
    SetPedLodMultiplier(ped, 1000.0)
    SetEntityLodDist(ped, 1000)

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, CAM_FOV)
    placeCam(ped)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 250, true, true)

    active = true
    TriggerEvent('ox_inventory:pedPreviewState', true)
end

local function stopPreview()
    -- NOTE: we deliberately do NOT clear `oxlynForceCompact` here.
    -- This function fires on every toggle of the preview (incl. when
    -- the React layout switches to compact mid-session), and clearing
    -- the flag here would create a feedback loop:
    --   UI compact → ask Lua to stop → Lua clears flag → UI un-compacts
    --   → UI asks Lua to start → Lua refuses (airborne) → flag set true
    --   → UI compact again → loop.
    -- The flag is set / cleared exclusively by client.openInventory()
    -- and client.closeInventory(), once per session.

    local wasActive = active
    active = false

    -- Restore the ped whenever WE are the ones holding it — even if the
    -- preview never fully started. Never touch a ped we didn't freeze, so a
    -- cutscene/another script keeping the player still isn't cancelled here.
    if frozeByUs then
        frozeByUs = false

        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) then
            FreezeEntityPosition(ped, false)
            SetPedLodMultiplier(ped, 1.0)
            SetBlockingOfNonTemporaryEvents(ped, false)
            SetPedCanRagdoll(ped, true)
        end
    end

    if wasActive then
        ClearFocus()
        TriggerEvent('ox_inventory:pedPreviewState', false)
    end

    destroyCam()
end

-- Block movement / combat inputs while the preview cam is locked
CreateThread(function()
    while true do
        if active then
            DisableControlAction(0, 1,  true)
            DisableControlAction(0, 2,  true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 75, true)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- (Anti-blur loop removed — the real source of the desfoque was the
--  TriggerScreenblurFadeIn native, disabled via `inventory:screenblur 0`
--  in init.lua. The loop's `AnimpostfxStopAll()` was also clobbering
--  the GTA pause menu's own postfx, leaving its values transparent.)

RegisterNUICallback('togglePedPreview', function(data, cb)
    if data and type(data.anchorX) == 'number' then anchorX = math.min(0.95, math.max(0.05, data.anchorX)) end
    if data and data.enabled then startPreview() else stopPreview() end
    cb(1)
end)

-- The ped gap moved (layout / panel / fit change while the preview is open).
RegisterNUICallback('rwPedAnchor', function(data, cb)
    if data and type(data.x) == 'number' then
        anchorX = math.min(0.95, math.max(0.05, data.x))
        anchorY = type(data.y) == 'number' and math.min(0.8, math.max(0.2, data.y)) or 0.5
        if active and cam then
            local ped = PlayerPedId()
            if ped and DoesEntityExist(ped) then placeCam(ped) end
        end
    end
    cb(1)
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynPedAnchor', function(data, cb)
    if data and type(data.x) == 'number' then
        anchorX = math.min(0.95, math.max(0.05, data.x))
        anchorY = type(data.y) == 'number' and math.min(0.8, math.max(0.2, data.y)) or 0.5
        if active and cam then
            local ped = PlayerPedId()
            if ped and DoesEntityExist(ped) then placeCam(ped) end
        end
    end
    cb(1)
end)

-- ─── UI open / close (authoritative, fired by client.lua) ────
AddEventHandler('ox_inventory:uiOpen', function()
    uiOpen = true
end)

AddEventHandler('ox_inventory:uiClose', function()
    uiOpen = false
    stopPreview()
end)

-- Safety net: if the preview somehow survives a close (lost NUI message,
-- another resource forcing the inventory shut), unfreeze the ped instead of
-- leaving the player stuck in place forever.
CreateThread(function()
    while true do
        Wait(500)

        if (active or frozeByUs) and not uiOpen then
            stopPreview()
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        hardCleanup()
    end
end)
