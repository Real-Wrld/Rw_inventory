--[[
    Sling editor studio — cloned ped + scripted camera (same MRPD lineup as inventory preview).
    Never teleports or freezes the real player ped.
]]

if not lib then return end

local Studio = {
    active = false,
    ped = nil,
    cam = nil,
    heading = 180.0,
    inputThread = nil,
}

local STUDIO_COORDS = vector3(402.95, -996.35, -99.0)
local CAM_OFFSET = vector3(0.0, -2.35, 0.45)
local CAM_AIM_OFFSET = vector3(0.0, 0.0, 0.35)
local CAM_FOV = 38.0

local function prepareStudio()
    local interior = GetInteriorAtCoords(STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z)
    if interior ~= 0 then
        PinInteriorInMemory(interior)
        LoadInterior(interior)
        local timeout = GetGameTimer() + 3000
        while not IsInteriorReady(interior) and GetGameTimer() < timeout do
            Wait(0)
        end
    end
    RequestCollisionAtCoord(STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z)
end

local function syncPedAppearance(clone, source)
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

local function destroyPed()
    if Studio.ped and DoesEntityExist(Studio.ped) then
        SetEntityAsMissionEntity(Studio.ped, true, true)
        DeleteEntity(Studio.ped)
    end
    Studio.ped = nil
end

local function destroyCam()
    if Studio.cam and DoesCamExist(Studio.cam) then
        SetCamActive(Studio.cam, false)
        RenderScriptCams(false, true, 350, true, true)
        DestroyCam(Studio.cam, false)
    end
    Studio.cam = nil
end

local function createStudioPed(playerPed)
    local model = GetEntityModel(playerPed)
    lib.requestModel(model, 5000)

    local clone = CreatePed(26, model, STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z, Studio.heading, false, false)
    SetModelAsNoLongerNeeded(model)
    if not clone or clone == 0 or not DoesEntityExist(clone) then return nil end

    SetEntityCoordsNoOffset(clone, STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z, false, false, false)
    SetEntityHeading(clone, Studio.heading)
    SetEntityAsMissionEntity(clone, true, true)
    SetEntityInvincible(clone, true)
    SetBlockingOfNonTemporaryEvents(clone, true)
    FreezeEntityPosition(clone, true)
    SetEntityCollision(clone, false, false)
    SetPedCanRagdoll(clone, false)
    SetEntityLodDist(clone, 1000)
    SetEntityVisible(clone, true, false)
    SetEntityAlpha(clone, 255, false)
    syncPedAppearance(clone, playerPed)

    return clone
end

local function startInputThread()
    local token = {}
    Studio.inputThread = token

    CreateThread(function()
        while Studio.active and Studio.inputThread == token do
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 35, true) -- D

            if IsDisabledControlPressed(0, 34) then
                Studio.rotate(-2.5)
            elseif IsDisabledControlPressed(0, 35) then
                Studio.rotate(2.5)
            end

            if Studio.ped and DoesEntityExist(Studio.ped) then
                SetEntityVisible(Studio.ped, true, false)
                ResetEntityAlpha(Studio.ped)
                SetEntityHeading(Studio.ped, Studio.heading)
                local c = GetEntityCoords(Studio.ped)
                if #(c - STUDIO_COORDS) > 1.0 then
                    SetEntityCoordsNoOffset(Studio.ped, STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z, false, false, false)
                end
            else
                Studio.ensurePed()
            end

            Wait(0)
        end
    end)
end

function Studio.getPed()
    return Studio.ped
end

function Studio.isActive()
    return Studio.active
end

function Studio.ensurePed()
    if Studio.ped and DoesEntityExist(Studio.ped) then return Studio.ped end
    local playerPed = cache.ped
    if not playerPed or not DoesEntityExist(playerPed) then return nil end
    prepareStudio()
    SetFocusPosAndVel(STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z, 0.0, 0.0, 0.0)
    Studio.ped = createStudioPed(playerPed)
    return Studio.ped
end

function Studio.rotate(delta)
    if not Studio.ped or not DoesEntityExist(Studio.ped) then return end
    Studio.heading = Studio.heading + delta
    if Studio.heading > 360.0 then Studio.heading = Studio.heading - 360.0 end
    if Studio.heading < 0.0 then Studio.heading = Studio.heading + 360.0 end
    SetEntityHeading(Studio.ped, Studio.heading)
end

function Studio.open()
    if Studio.active then
        if not Studio.ped or not DoesEntityExist(Studio.ped) then
            Studio.ensurePed()
        end
        return Studio.ped ~= nil
    end

    local playerPed = cache.ped
    if not playerPed or not DoesEntityExist(playerPed) then return false end

    prepareStudio()
    Studio.heading = 180.0
    Studio.ped = createStudioPed(playerPed)
    if not Studio.ped then return false end

    SetFocusPosAndVel(STUDIO_COORDS.x, STUDIO_COORDS.y, STUDIO_COORDS.z, 0.0, 0.0, 0.0)

    local camPos = STUDIO_COORDS + CAM_OFFSET
    local aimPos = STUDIO_COORDS + CAM_AIM_OFFSET

    Studio.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(Studio.cam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(Studio.cam, aimPos.x, aimPos.y, aimPos.z)
    SetCamFov(Studio.cam, CAM_FOV)
    SetCamNearClip(Studio.cam, 0.05)
    SetCamFarClip(Studio.cam, 25.0)
    SetCamActive(Studio.cam, true)
    RenderScriptCams(true, true, 400, true, true)

    Studio.active = true
    DisplayRadar(false)
    startInputThread()

    return true
end

function Studio.close()
    if not Studio.active then return end
    Studio.active = false
    Studio.inputThread = nil
    destroyCam()
    destroyPed()
    ClearFocus()
    DisplayRadar(true)
end

return Studio
