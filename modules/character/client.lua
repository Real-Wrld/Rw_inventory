--[[
    Virtual ped mirror — scripted camera (ox_inventory safe).

    Dark void studio with neon rim lighting. No MRPD interior / mugshot wall.
    CRITICAL: Never teleport/freeze/hide the REAL player ped.
    CRITICAL: Never ClonePed while seated.

    Studio Z must stay at -150 with the tuned CAM_* framing below.
    Moving Z deeper (e.g. -240) to "hide under-map" just loses the ped;
    backdrop is handled by far-clip + a black DrawPoly plane behind the clone.
]]

local isOpen = false
local opening = false
local previewPed = nil
local previewCam = nil
local heading = 180.0
local seatWatchdog = nil
local studioLightsActive = false

--- Proven working void depth — do NOT lower this to chase scenery.
local STUDIO_COORDS = vector3(0.0, 0.0, -150.0)

--- Ped HARD LEFT. Pull back + aim slightly lower so full body (shoes) fit in frame.
-- Ped pulled back for full-body framing; aim further +X so silhouette sits
-- under Hat/Chain (stage center), not drifting toward the inventory panel.
local CAM_OFFSET = vector3(0.0, -4.2, 0.18)
local CAM_AIM_OFFSET = vector3(2.08, 0.0, -0.08)
local CAM_FOV = 40.0

local HUD_COLOUR_PAUSE_ALT = 117

local function isPinkFrogAddonRunning()
    return GetResourceState('pinkFrog_inventoryAddon') == 'started'
end

local function resetFrontendState()
    SetFrontendActive(false)
    ReplaceHudColourWithRgba(HUD_COLOUR_PAUSE_ALT, 0, 0, 0, 186)
    SetMouseCursorVisibleInMenus(true)
end

local function syncPedAppearance(clone, source)
    if GetEntityModel(clone) == `mp_m_freemode_01` or GetEntityModel(clone) == `mp_f_freemode_01` then
        SetPedDefaultComponentVariation(clone)
    end

    for i = 0, 11 do
        SetPedComponentVariation(clone, i, GetPedDrawableVariation(source, i), GetPedTextureVariation(source, i),
            GetPedPaletteVariation(source, i))
    end

    for i = 0, 7 do
        local prop = GetPedPropIndex(source, i)
        if prop ~= -1 then
            SetPedPropIndex(clone, i, prop, GetPedPropTextureIndex(source, i), true)
        else
            ClearPedProp(clone, i)
        end
    end

    if HasPedHeadBlendFinished(source) then
        local shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix =
            GetPedHeadBlendData(source)
        SetPedHeadBlendData(clone, shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix,
            skinMix, thirdMix, false)
    end
end

local function prepareStudio()
    RequestCollisionAtCoord(STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z)
    NetworkOverrideClockTime(0, 0, 0)
    SetArtificialLightsState(true)
    -- Soft void — never use NG_blackout (it crushed ped albedo to invisible)
    ClearTimecycleModifier()
    SetTimecycleModifier('cinema')
    SetTimecycleModifierStrength(0.12)
    studioLightsActive = true
end

local function clearStudio()
    if studioLightsActive then
        ClearTimecycleModifier()
        SetArtificialLightsState(false)
        studioLightsActive = false
    end
end

local function destroyPreviewPed()
    if previewPed and DoesEntityExist(previewPed) then
        SetEntityAsMissionEntity(previewPed, true, true)
        DeleteEntity(previewPed)
    end
    previewPed = nil
end

local function destroyPreviewCam()
    if previewCam and DoesCamExist(previewCam) then
        SetCamActive(previewCam, false)
        RenderScriptCams(false, false, 0, 1, 0)
        DestroyCam(previewCam, false)
    end
    previewCam = nil
end

local function stopSeatWatchdog()
    seatWatchdog = nil
end

local function startSeatWatchdog(realCoords, realHeading, realVehicle, realSeat)
    local token = {}
    seatWatchdog = token

    CreateThread(function()
        while isOpen and seatWatchdog == token do
            local playerPed = cache.ped
            if playerPed and DoesEntityExist(playerPed) then
                local coords = GetEntityCoords(playerPed)
                if #(coords - STUDIO_COORDS) < 25.0 then
                    if realVehicle and realVehicle ~= 0 and DoesEntityExist(realVehicle) and type(realSeat) == 'number' then
                        TaskWarpPedIntoVehicle(playerPed, realVehicle, realSeat)
                    else
                        SetEntityCoordsNoOffset(playerPed, realCoords.x, realCoords.y, realCoords.z, false, false, false)
                        SetEntityHeading(playerPed, realHeading)
                    end
                elseif realVehicle and realVehicle ~= 0 and DoesEntityExist(realVehicle) and type(realSeat) == 'number' then
                    if not IsPedInVehicle(playerPed, realVehicle, false) then
                        TaskWarpPedIntoVehicle(playerPed, realVehicle, realSeat)
                    end
                end
            end

            Wait(100)
        end
    end)
end

local function CloseCharacterPanel()
    if not isOpen and not previewPed and not previewCam then
        resetFrontendState()
        return
    end

    isOpen = false
    opening = false
    stopSeatWatchdog()
    destroyPreviewCam()
    destroyPreviewPed()
    clearStudio()
    resetFrontendState()

    local playerPed = cache.ped
    if playerPed and DoesEntityExist(playerPed) and not IsPedInAnyVehicle(playerPed, false) then
        SetEntityVelocity(playerPed, 0.0, 0.0, 0.0)
    end
end

local function createPreviewPed(playerPed, model)
    local inVehicle = IsPedInAnyVehicle(playerPed, false)

    if inVehicle then
        local ped = CreatePed(26, model, STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z, heading, false, false)
        if ped and ped ~= 0 then
            SetEntityVisible(ped, false, false)
        end
        return ped
    end

    local clone = ClonePed(playerPed, false, false, true)
    if clone and clone ~= 0 and DoesEntityExist(clone) then
        SetEntityCoordsNoOffset(clone, STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z, false, false, false)
        SetEntityVisible(clone, false, false)
        return clone
    end

    local ped = CreatePed(26, model, STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z, heading, false, false)
    if ped and ped ~= 0 then
        SetEntityVisible(ped, false, false)
    end
    return ped
end

local function getPedSeatInVehicle(ped, vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    for seat = -1, maxSeats - 1 do
        if GetPedInVehicleSeat(vehicle, seat) == ped then
            return seat
        end
    end
    return nil
end

local function setupPreviewPed(playerPed)
    SetEntityCoordsNoOffset(previewPed, STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z, false, false, false)
    SetEntityHeading(previewPed, heading)
    SetEntityAsMissionEntity(previewPed, true, true)
    SetEntityInvincible(previewPed, true)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    FreezeEntityPosition(previewPed, true)
    SetEntityCollision(previewPed, false, false)
    SetPedCanRagdoll(previewPed, false)
    SetEntityLodDist(previewPed, 1000)
    syncPedAppearance(previewPed, playerPed)
    SetEntityAlpha(previewPed, 255, false)
    ResetEntityAlpha(previewPed)
    SetEntityVisible(previewPed, true, false)
end

local function setupPreviewCam()
    local camPos = STUDIO_COORDS + CAM_OFFSET
    local aimPos = STUDIO_COORDS + CAM_AIM_OFFSET

    previewCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(previewCam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(previewCam, aimPos.x, aimPos.y, aimPos.z)
    SetCamFov(previewCam, CAM_FOV)
    SetCamNearClip(previewCam, 0.05)
    -- Ped ~4m away; walls sit ~6–7m — keep far clip past the studio box, not the city.
    SetCamFarClip(previewCam, 18.0)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, false, 0, 1, 0)
end

--- Wide black studio box — cam aims hard +X for left-ped framing, so the right
--- edge of the frustum used to miss a narrow back wall and show under-map gray.
local function drawStudioBackdrop()
    local yBack = STUDIO_COORDS.y + 2.4
    local yFront = STUDIO_COORDS.y - 2.5
    local x0 = STUDIO_COORDS.x - 14.0
    local x1 = STUDIO_COORDS.x + 22.0
    local z0 = STUDIO_COORDS.z - 3.0
    local z1 = STUDIO_COORDS.z + 7.0

    -- Back wall (camera looks +Y)
    DrawPoly(x0, yBack, z0, x1, yBack, z0, x1, yBack, z1, 0, 0, 0, 255)
    DrawPoly(x0, yBack, z0, x1, yBack, z1, x0, yBack, z1, 0, 0, 0, 255)
    -- Floor
    DrawPoly(x0, yFront, z0, x1, yFront, z0, x1, yBack, z0, 0, 0, 0, 255)
    DrawPoly(x0, yFront, z0, x1, yBack, z0, x0, yBack, z0, 0, 0, 0, 255)
    -- Ceiling
    DrawPoly(x0, yFront, z1, x1, yBack, z1, x1, yFront, z1, 0, 0, 0, 255)
    DrawPoly(x0, yFront, z1, x0, yBack, z1, x1, yBack, z1, 0, 0, 0, 255)
    -- Right wall (covers the inventory-side gap in the screenshot)
    DrawPoly(x1, yFront, z0, x1, yBack, z0, x1, yBack, z1, 0, 0, 0, 255)
    DrawPoly(x1, yFront, z0, x1, yBack, z1, x1, yFront, z1, 0, 0, 0, 255)
    -- Left wall
    DrawPoly(x0, yFront, z0, x0, yBack, z1, x0, yBack, z0, 0, 0, 0, 255)
    DrawPoly(x0, yFront, z0, x0, yFront, z1, x0, yBack, z1, 0, 0, 0, 255)
end

local function SyncCharacterAppearance()
    if not isOpen or not previewPed or not DoesEntityExist(previewPed) then return end
    local playerPed = cache.ped
    if not playerPed or not DoesEntityExist(playerPed) then return end
    syncPedAppearance(previewPed, playerPed)
end

local function OpenCharacterPanel()
    if isOpen or opening then return end
    opening = true

    destroyPreviewPed()
    destroyPreviewCam()

    local playerPed = cache.ped
    if not playerPed or not DoesEntityExist(playerPed) then
        opening = false
        return
    end

    local realCoords = GetEntityCoords(playerPed)
    local realHeading = GetEntityHeading(playerPed)
    local realVehicle = cache.vehicle
    local realSeat = cache.seat
    if (not realVehicle or realVehicle == 0) and IsPedInAnyVehicle(playerPed, false) then
        realVehicle = GetVehiclePedIsIn(playerPed, false)
        realSeat = getPedSeatInVehicle(playerPed, realVehicle)
    end

    resetFrontendState()
    prepareStudio()

    local model = GetEntityModel(playerPed)
    lib.requestModel(model, 5000)

    previewPed = createPreviewPed(playerPed, model)
    SetModelAsNoLongerNeeded(model)

    if not previewPed or previewPed == 0 or not DoesEntityExist(previewPed) then
        opening = false
        clearStudio()
        return
    end

    local after = GetEntityCoords(playerPed)
    if #(after - realCoords) > 0.25 then
        if realVehicle and realVehicle ~= 0 and DoesEntityExist(realVehicle) and type(realSeat) == 'number' then
            TaskWarpPedIntoVehicle(playerPed, realVehicle, realSeat)
        else
            SetEntityCoordsNoOffset(playerPed, realCoords.x, realCoords.y, realCoords.z, false, false, false)
            SetEntityHeading(playerPed, realHeading)
        end
    end

    setupPreviewPed(playerPed)
    setupPreviewCam()

    isOpen = true
    opening = false
    startSeatWatchdog(realCoords, realHeading, realVehicle, realSeat)

    CreateThread(function()
        while isOpen do
            if previewPed and DoesEntityExist(previewPed) then
                SetEntityHeading(previewPed, heading)
                local c = GetEntityCoords(previewPed)
                if #(c - STUDIO_COORDS) > 1.0 then
                    SetEntityCoordsNoOffset(previewPed, STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z, false, false, false)
                end

                drawStudioBackdrop()

                -- Bright key/fill so ped reads through the UI hole
                DrawLightWithRange(STUDIO_COORDS.x - 1.2, STUDIO_COORDS.y + 1.2, STUDIO_COORDS.z + 1.4, 255, 248, 235, 10.0, 12.0)
                DrawLightWithRange(STUDIO_COORDS.x + 1.5, STUDIO_COORDS.y + 0.4, STUDIO_COORDS.z + 0.6, 230, 200, 120, 8.0, 7.0)
                DrawLightWithRange(STUDIO_COORDS.x, STUDIO_COORDS.y - 1.0, STUDIO_COORDS.z + 0.35, 180, 210, 255, 7.0, 5.0)
                DrawLightWithRange(STUDIO_COORDS.x, STUDIO_COORDS.y + 0.2, STUDIO_COORDS.z + 2.0, 255, 255, 250, 6.0, 4.0)
            end

            if previewCam and DoesCamExist(previewCam) then
                if not IsCamActive(previewCam) then
                    SetCamActive(previewCam, true)
                    RenderScriptCams(true, false, 0, 1, 0)
                end
            end

            Wait(0)
        end
    end)
end

-- RealWrld merge: the Creator V4 UI draws the inventory ped itself
-- (pedpreview). The legacy clone-ped studio (black backdrop + void ped)
-- must not open over it. Flip to true to restore the studio.
local STUDIO_ENABLED = false
local function openWithBackdrop()
    if not STUDIO_ENABLED then return end
    OpenCharacterPanel()
    if client.screenblur then
        TriggerScreenblurFadeOut(0)
    end
end

local function closeWithBackdrop()
    CloseCharacterPanel()
end

AddEventHandler('pinkFrog:startClonedPedByOx', function()
    if isPinkFrogAddonRunning() then return end
    openWithBackdrop()
end)

AddEventHandler('pinkFrog:removeClonedPedFromOxInventory', function()
    if isPinkFrogAddonRunning() then return end
    closeWithBackdrop()
end)

RegisterNetEvent('pinkFrog_syncClonePed', function(open)
    if isPinkFrogAddonRunning() then return end
    if open then
        openWithBackdrop()
    else
        closeWithBackdrop()
    end
end)

exports('openCharacterPanel', openWithBackdrop)
exports('closeCharacterPanel', closeWithBackdrop)
exports('syncCharacterAppearance', SyncCharacterAppearance)

RegisterNUICallback('rotateCharacter', function(data, cb)
    if previewPed and DoesEntityExist(previewPed) and data.value then
        heading = heading + (data.value * 5.0)
        if heading > 360.0 then heading = heading - 360.0 end
        if heading < 0.0 then heading = heading + 360.0 end
        SetEntityHeading(previewPed, heading)
    end
    cb(1)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CloseCharacterPanel()
end)

return {
    open = openWithBackdrop,
    close = closeWithBackdrop,
    sync = SyncCharacterAppearance,
    isOpen = function() return isOpen end,
}
