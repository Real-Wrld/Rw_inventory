-- Ramp Placement System
-- Allows players to place ramps in the world using prop_mp_ramp_03_tu

local RAMP_MODEL = 'prop_mp_ramp_03_tu'
local RAMP_LIFETIME = 10 * 60 * 1000    -- 10 minutes in milliseconds
local RAMP_WARNING_TIME = 1 * 60 * 1000 -- Warning 1 minute before deletion

local placingRamp = false
local rampPreview = nil
local placedRamps = {} -- Track placed ramps for cleanup and auto-delete

-- Load model helper
local function LoadModel(modelName)
    local hash = joaat(modelName)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    return HasModelLoaded(hash) and hash or nil
end

-- Draw 3D text helper
local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Schedule ramp auto-delete
local function ScheduleRampDeletion(rampEntity)
    local rampId = rampEntity

    -- Store ramp info
    placedRamps[rampId] = {
        entity = rampEntity,
        placedAt = GetGameTimer(),
        coords = GetEntityCoords(rampEntity),
    }

    -- Warning notification 1 minute before deletion
    SetTimeout(RAMP_LIFETIME - RAMP_WARNING_TIME, function()
        if placedRamps[rampId] and DoesEntityExist(placedRamps[rampId].entity) then
            lib.notify({
                title = 'Ramp Warning',
                description = 'Your ramp will disappear in 1 minute!',
                type = 'warning',
                duration = 5000,
            })
        end
    end)

    -- Auto-delete after lifetime
    SetTimeout(RAMP_LIFETIME, function()
        if placedRamps[rampId] then
            local rampData = placedRamps[rampId]
            if DoesEntityExist(rampData.entity) then
                -- Fade out effect
                local alpha = 255
                CreateThread(function()
                    while alpha > 0 do
                        alpha = alpha - 15
                        if DoesEntityExist(rampData.entity) then
                            SetEntityAlpha(rampData.entity, math.max(0, alpha), false)
                        end
                        Wait(50)
                    end

                    if DoesEntityExist(rampData.entity) then
                        DeleteEntity(rampData.entity)
                    end

                    lib.notify({
                        title = 'Ramp Expired',
                        description = 'Your ramp has disappeared after 10 minutes.',
                        type = 'inform',
                        duration = 4000,
                    })
                end)
            end
            placedRamps[rampId] = nil
        end
    end)

end

-- Place ramp export (called when item is used)
exports('placeRamp', function(data, slot)
    if placingRamp then
        lib.notify({ title = 'Ramp', description = 'Already placing a ramp', type = 'error' })
        return
    end

    local ped = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Load model
    local modelHash = LoadModel(RAMP_MODEL)
    if not modelHash then
        lib.notify({ title = 'Ramp', description = 'Failed to load ramp model', type = 'error' })
        return
    end

    -- Spawn preview in front of player
    local spawnPos = coords + vector3(
        math.sin(math.rad(-heading)) * 3.0,
        math.cos(math.rad(-heading)) * 3.0,
        0.0
    )

    rampPreview = CreateObject(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, false, true, false)
    SetEntityAlpha(rampPreview, 200, false)
    SetEntityCollision(rampPreview, false, false)
    FreezeEntityPosition(rampPreview, true)
    SetEntityHeading(rampPreview, heading)

    placingRamp = true

    -- Freeze player movement during placement
    FreezeEntityPosition(ped, true)

    lib.notify({
        title = 'Ramp Placement',
        description = 'Use WASD to move, Q/E to rotate. ENTER to confirm, ESC to cancel.',
        type = 'inform',
        duration = 5000
    })

    -- Placement loop
    CreateThread(function()
        local moveStep = 0.05
        local rotStep = 3.0

        while placingRamp do
            Wait(0)

            if not DoesEntityExist(rampPreview) then
                placingRamp = false
                break
            end

            local rampCoords = GetEntityCoords(rampPreview)
            local rampHeading = GetEntityHeading(rampPreview)

            -- Draw instructions
            DrawText3D(rampCoords.x, rampCoords.y, rampCoords.z + 1.5, '~b~[WASD]~w~ Move | ~b~[Q/E]~w~ Rotate')
            DrawText3D(rampCoords.x, rampCoords.y, rampCoords.z + 1.2, '~g~[ENTER]~w~ Confirm | ~r~[ESC]~w~ Cancel')

            -- Get forward/right vectors for movement
            local fwd = GetEntityForwardVector(rampPreview)
            local right = vector3(-fwd.y, fwd.x, 0.0)

            -- Movement controls
            if IsControlPressed(0, 32) then -- W - Forward
                SetEntityCoords(rampPreview, rampCoords + fwd * moveStep)
            end
            if IsControlPressed(0, 33) then -- S - Backward
                SetEntityCoords(rampPreview, rampCoords - fwd * moveStep)
            end
            if IsControlPressed(0, 34) then -- A - Left
                SetEntityCoords(rampPreview, rampCoords - right * moveStep)
            end
            if IsControlPressed(0, 35) then -- D - Right
                SetEntityCoords(rampPreview, rampCoords + right * moveStep)
            end

            -- Rotation controls
            if IsControlPressed(0, 44) then -- Q - Rotate Left
                SetEntityHeading(rampPreview, rampHeading + rotStep)
            end
            if IsControlPressed(0, 38) then -- E - Rotate Right
                SetEntityHeading(rampPreview, rampHeading - rotStep)
            end

            -- Height adjustment with scroll
            if IsControlPressed(0, 15) then -- Scroll Up
                SetEntityCoords(rampPreview, rampCoords.x, rampCoords.y, rampCoords.z + 0.02)
            end
            if IsControlPressed(0, 14) then -- Scroll Down
                SetEntityCoords(rampPreview, rampCoords.x, rampCoords.y, rampCoords.z - 0.02)
            end

            -- Confirm placement (ENTER)
            if IsControlJustPressed(0, 191) then
                -- Finalize ramp
                local finalCoords = GetEntityCoords(rampPreview)
                local finalHeading = GetEntityHeading(rampPreview)

                -- Remove preview
                DeleteEntity(rampPreview)
                rampPreview = nil

                -- Create permanent ramp
                local finalRamp = CreateObject(modelHash, finalCoords.x, finalCoords.y, finalCoords.z, true, true, false)
                SetEntityHeading(finalRamp, finalHeading)
                SetEntityAlpha(finalRamp, 255, false)
                SetEntityCollision(finalRamp, true, true)
                FreezeEntityPosition(finalRamp, true)
                PlaceObjectOnGroundProperly(finalRamp)

                -- Schedule auto-delete after 10 minutes
                ScheduleRampDeletion(finalRamp)

                -- Remove item from inventory
                TriggerServerEvent('ox_inventory:removeItem', 'ramp', 1, nil, slot)

                lib.notify({
                    title = 'Ramp Placed',
                    description = 'Your ramp has been placed! It will disappear in 10 minutes.',
                    type = 'success'
                })

                placingRamp = false
                -- Unfreeze player
                FreezeEntityPosition(ped, false)
                break
            end

            -- Cancel placement (ESC/Backspace)
            if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then
                if DoesEntityExist(rampPreview) then
                    DeleteEntity(rampPreview)
                    rampPreview = nil
                end

                lib.notify({
                    title = 'Ramp Placement',
                    description = 'Placement cancelled',
                    type = 'error'
                })

                placingRamp = false
                -- Unfreeze player
                FreezeEntityPosition(ped, false)
                break
            end
        end

        SetModelAsNoLongerNeeded(modelHash)
    end)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Clean up preview
    if rampPreview and DoesEntityExist(rampPreview) then
        DeleteEntity(rampPreview)
    end

    -- Clean up all placed ramps
    for id, rampData in pairs(placedRamps) do
        if DoesEntityExist(rampData.entity) then
            DeleteEntity(rampData.entity)
        end
    end
    placedRamps = {}
end)

return {
    RAMP_MODEL = RAMP_MODEL,
    RAMP_LIFETIME = RAMP_LIFETIME,
}
