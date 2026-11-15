PrinterPlacement = { active = false }

local ghost = nil            -- preview entity
local heading = 0.0
local distance = 2.0         -- how far in front of the player the ghost sits
local heightOffset = 0.0     -- manual vertical offset
local isValid = false
local invalidReason = nil    -- locale key
local propHash = nil
local smoothPos = nil        -- smoothed ghost position
local cfg = nil              -- PrinterConfig.Placement

CreateThread(function()
    Wait(100)
    cfg = PrinterConfig.Placement
    distance = cfg.startDistance
end)

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function loadModel()
    propHash = joaat(PrinterConfig.PropModel)

    if not (IsModelInCdimage(propHash) and IsModelValid(propHash)) then
        print(("^1[rwprinter] Modelo %s nao encontrado. O stream/ esta a ser carregado?^0")
            :format(PrinterConfig.PropModel))
        return false
    end

    RequestModel(propHash)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(propHash) and GetGameTimer() < deadline do
        Wait(10)
    end

    return HasModelLoaded(propHash)
end

local function getCamDirection()
    local rot = GetGameplayCamRot(2)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local c = math.cos(x)

    return vector3(-math.sin(z) * c, math.cos(z) * c, math.sin(x))
end

-- Returns hit(bool), endCoords(vector3|nil)
local function raycast(from, to, flags, ignoreEntity)
    local handle = StartExpensiveSynchronousShapeTestLosProbe(
        from.x, from.y, from.z,
        to.x, to.y, to.z,
        flags, ignoreEntity or 0, 4
    )

    local _, hit, endCoords = GetShapeTestResult(handle)
    if hit and endCoords then
        return true, vector3(endCoords.x, endCoords.y, endCoords.z)
    end

    return false, nil
end

-- Returns foundGround(bool), z
local function findGroundZ(pos, ignoreEntity)
    local hit, hitPos = raycast(
        vector3(pos.x, pos.y, pos.z + 1.2),
        vector3(pos.x, pos.y, pos.z - 12.0),
        17, ignoreEntity
    )
    if hit then return true, hitPos.z end

    for _, offset in ipairs({ 2.0, 10.0, 40.0 }) do
        local found, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + offset, false)
        if found then return true, z end
    end

    return false, pos.z
end

-- Where the ghost wants to be (camera ray, clamped, wall-checked, snapped to ground)
-- Returns hasSurface(bool), position(vector3)
local function computeTarget()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local origin = vector3(pedCoords.x, pedCoords.y, pedCoords.z + 0.55)

    local dir = getCamDirection()
    local camPos = GetGameplayCamCoord()
    local reach = #(camPos - origin) + distance + 2.0

    local hit, hitPos = raycast(camPos, camPos + dir * reach, 19, ped)

    local target
    local hitSurface = nil

    if hit then
        if distance >= #(hitPos - origin) then
            target = hitPos
            hitSurface = true
        else
            target = origin + dir * distance
        end
    else
        target = origin + dir * distance
    end

    -- Enforce minimum distance along the horizontal look direction
    local minDist = cfg.minDistance or 1.0
    local flat = vector3(dir.x, dir.y, 0.0)
    local flatLen = #flat
    if flatLen > 0.01 then
        flat = flat / flatLen
        local rel = target - origin
        local along = rel.x * flat.x + rel.y * flat.y
        if minDist > along then
            target = target + flat * (minDist - along)
            hitSurface = false
        end
    end

    -- Don't let the ghost go through walls
    if cfg.blockThroughWalls ~= false and not hitSurface then
        local toTarget = target - origin
        local len = #toTarget
        if len > 0.1 then
            local wallHit, wallPos = raycast(origin, target, 19, ped)
            if wallHit then
                local wallDist = #(wallPos - origin)
                local tolerance = cfg.wallTolerance or 0.6
                if wallDist < len - tolerance then
                    target = origin + (toTarget / len) * math.max(wallDist - 0.1, 0.5)
                end
            end
        end
    end

    local hasGround, groundZ = findGroundZ(target, ped)
    return hasGround, vector3(target.x, target.y, groundZ)
end

-- Returns canPlace(bool), position(vector3), reasonLocaleKey|nil
local function validate()
    local hasSurface, pos = computeTarget()
    local final = vector3(pos.x, pos.y, pos.z + heightOffset)

    local pedCoords = GetEntityCoords(PlayerPedId())
    if #(pedCoords - final) > cfg.maxDistance + 0.5 then
        return false, final, "place_too_far"
    end

    if cfg.blockOnWater and GetInteriorAtCoords(final.x, final.y, final.z) == 0 then
        local hasWater, waterZ = GetWaterHeight(final.x, final.y, final.z)
        if hasWater and waterZ and final.z <= waterZ + 0.5 then
            return false, final, "place_on_water"
        end
    end

    for _, entry in pairs(ClientPrinters or {}) do
        local coords = entry.data and entry.data.coords
        if coords and #(final - vector3(coords.x, coords.y, coords.z)) < cfg.minSpacing then
            return false, final, "place_too_close"
        end
    end

    if not hasSurface and cfg.requireSurface == true then
        return false, final, "place_blocked"
    end

    return true, final, nil
end

-- ─────────────────────────────────────────────
-- Start / Stop
-- ─────────────────────────────────────────────

function PrinterPlacement.Start()
    if PrinterPlacement.active then return end

    if not loadModel() then
        PrinterFramework.Notify(PrinterL("place_model_missing"), "error")
        return
    end

    PrinterPlacement.active = true
    distance = cfg.startDistance
    heightOffset = 0.0
    smoothPos = nil
    invalidReason = nil

    if cfg.faceCamera == false then
        heading = GetEntityHeading(PlayerPedId())
    else
        heading = (GetGameplayCamRot(2).z + 180.0) % 360.0
    end

    local _, pos = validate()
    smoothPos = pos

    ghost = CreateObjectNoOffset(propHash, pos.x, pos.y, pos.z, false, false, false)
    SetEntityAlpha(ghost, cfg.ghostAlpha, false)
    SetEntityCollision(ghost, false, false)
    SetEntityInvincible(ghost, true)
    FreezeEntityPosition(ghost, true)
    SetEntityHeading(ghost, heading)
    SetEntityDrawOutline(ghost, true)

    SendNUIMessage({
        action = "placement",
        show = true,
        hints = {
            { key = "LMB / E",   label = PrinterL("place_confirm") },
            { key = "Scroll",    label = PrinterL("place_rotate") },
            { key = "↑ ↓",       label = PrinterL("place_height") },
            { key = "← →",       label = PrinterL("place_distance") },
            { key = "G",         label = PrinterL("place_snap") },
            { key = "BACKSPACE", label = PrinterL("place_cancel") },
        },
    })

    CreateThread(PrinterPlacement.Loop)
end

function PrinterPlacement.Stop(silent)
    if not PrinterPlacement.active then return end
    PrinterPlacement.active = false

    if ghost and DoesEntityExist(ghost) then
        SetEntityDrawOutline(ghost, false)
        DeleteEntity(ghost)
    end
    ghost = nil
    smoothPos = nil

    SetModelAsNoLongerNeeded(propHash)
    SendNUIMessage({ action = "placement", show = false })

    if not silent then
        PrinterFramework.Notify(PrinterL("place_cancelled"), "info")
    end
end

-- ─────────────────────────────────────────────
-- Main loop
-- ─────────────────────────────────────────────

-- Controls blocked while placing (attack, aim, melee, weapon wheel, etc.)
local BLOCKED_CONTROLS = { 24, 25, 44, 37, 47, 264, 257, 140, 141, 142, 241, 242, 45 }

function PrinterPlacement.Loop()
    while PrinterPlacement.active do
        local ok, pos, reason = validate()
        isValid = ok
        invalidReason = reason

        -- Smooth ghost movement
        if smoothPos then
            local t = math.min(1.0, GetFrameTime() * 18.0)
            smoothPos = smoothPos + (pos - smoothPos) * t
        else
            smoothPos = pos
        end

        if ghost and DoesEntityExist(ghost) then
            SetEntityCoordsNoOffset(ghost, smoothPos.x, smoothPos.y, smoothPos.z, false, false, false)
            SetEntityHeading(ghost, heading)

            local color = (isValid and cfg.outlineValid) or cfg.outlineInvalid
            SetEntityDrawOutlineColor(color[1], color[2], color[3], 255)
        end

        -- Block gameplay controls
        for _, control in ipairs(BLOCKED_CONTROLS) do
            DisableControlAction(0, control, true)
        end
        for _, control in pairs(PrinterConfig.Keys) do
            DisableControlAction(0, control, true)
        end

        -- Rotate (scroll wheel = step, keys = continuous)
        if IsDisabledControlJustPressed(0, 241) then
            heading = (heading + cfg.rotationStep) % 360.0
        elseif IsDisabledControlJustPressed(0, 242) then
            heading = (heading - cfg.rotationStep) % 360.0
        end

        if IsDisabledControlPressed(0, PrinterConfig.Keys.rotateLeft) then
            heading = (heading + cfg.rotationStep * 0.6) % 360.0
        elseif IsDisabledControlPressed(0, PrinterConfig.Keys.rotateRight) then
            heading = (heading - cfg.rotationStep * 0.6) % 360.0
        end

        -- Height
        if IsDisabledControlPressed(0, PrinterConfig.Keys.raise) then
            heightOffset = math.min(heightOffset + cfg.heightStep, cfg.maxHeight)
        elseif IsDisabledControlPressed(0, PrinterConfig.Keys.lower) then
            heightOffset = math.max(heightOffset - cfg.heightStep, cfg.minHeight)
        end

        -- Distance
        if IsDisabledControlPressed(0, PrinterConfig.Keys.further) then
            distance = math.min(distance + 0.03, cfg.maxDistance)
        elseif IsDisabledControlPressed(0, PrinterConfig.Keys.nearer) then
            distance = math.max(distance - 0.03, cfg.minDistance or 1.0)
        end

        -- Snap back to ground
        if IsDisabledControlJustPressed(0, PrinterConfig.Keys.snapGround) then
            heightOffset = 0.0
        end

        -- Confirm (place key or left mouse)
        if IsDisabledControlJustPressed(0, PrinterConfig.Keys.place) or IsDisabledControlJustPressed(0, 24) then
            if isValid then
                TriggerServerEvent("rwprinter:server:place", {
                    x = smoothPos.x,
                    y = smoothPos.y,
                    z = smoothPos.z,
                }, heading)
                PrinterPlacement.Stop(true)
            else
                PrinterFramework.Notify(PrinterL(invalidReason or "place_not_ready"), "error")
            end
        end

        -- Cancel
        if IsDisabledControlJustPressed(0, PrinterConfig.Keys.cancel) then
            PrinterPlacement.Stop(false)
        end

        Wait(0)
    end
end

-- ─────────────────────────────────────────────
-- Entry points
-- ─────────────────────────────────────────────

RegisterNetEvent("rwprinter:client:startPlacement", function()
    PrinterPlacement.Start()
end)

exports("usePrinter", function()
    PrinterPlacement.Start()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if ghost and DoesEntityExist(ghost) then
        DeleteEntity(ghost)
    end
end)