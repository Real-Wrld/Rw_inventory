-- c_place.lua  –  Item placement mode for bablo-throwitems

if GetCurrentResourceName() ~= "bablo-throwitems" then
    error("Resource name must be 'bablo-throwitems'")
    return
end

-- ─── State ────────────────────────────────────────────────────────────────────

local placingActive   = false   -- is placement mode running?
local ghostProp       = nil     -- semi-transparent preview object (alpha 150)
local solidProp       = nil     -- opaque hand-attached preview object
local placementYaw    = 0.0     -- current Z-rotation chosen by player
local placeDistance   = 2.0     -- forward distance for ghost placement
local placementValid  = false   -- is the current position within min/max range?

-- ─── Shared helpers (inventory close, item-by-slot lookup) ────────────────────

function CloseInventory()
    local inv = Config.Inventory
    if inv == "ox_inventory" then
        pcall(function() exports.ox_inventory:closeInventory() end)
    elseif inv == "qb-inventory" then
        TriggerEvent("qb-inventory:client:closeinv")
    elseif inv == "ps-inventory" then
        TriggerEvent("ps-inventory:client:closeinv")
    elseif inv == "qs-inventory" then
        pcall(function() exports["qs-inventory"]:CloseInventory() end)
    elseif inv == "tgiann-inventory" then
        pcall(function() exports["tgiann-inventory"]:CloseInventory() end)
    elseif inv == "origen_inventory" then
        pcall(function() exports.origen_inventory:CloseInventory() end)
    elseif inv == "codem-inventory" then
        pcall(function() exports["codem-inventory"]:CloseInventory() end)
    elseif inv == "core_inventory" then
        pcall(function() exports.core_inventory:CloseInventory() end)
    end
end

-- Returns itemName, slotNumber for the given slot index, or nil, nil
function GetItemBySlot(slotIndex)
    local inv = Config.Inventory
    if inv == "ox_inventory" then
        local items = exports.ox_inventory:GetPlayerItems()
        if items then
            for _, item in pairs(items) do
                if item.slot == slotIndex then
                    return item.name, item.slot
                end
            end
        end

    elseif inv == "qb-inventory" then
        local qb  = exports["qb-core"]:GetCoreObject()
        local data = qb.Functions.GetPlayerData()
        if data and data.items and data.items[slotIndex] then
            local item = data.items[slotIndex]
            return item.name, item.slot
        end

    elseif inv == "ps-inventory" then
        local item = exports["ps-inventory"]:GetItemBySlot(slotIndex)
        if item then return item.name, item.slot end

    elseif inv == "qs-inventory" then
        local item = exports["qs-inventory"]:GetItemBySlot(slotIndex)
        if item then return item.name, item.slot end
    end

    return nil, nil
end

-- ─── Model loading ────────────────────────────────────────────────────────────

function RequestModelSync(modelHash)
    if type(modelHash) == "string" then
        modelHash = GetHashKey(modelHash)
    end
    if not IsModelValid(modelHash) then return false end

    RequestModel(modelHash)
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 200 do
        Wait(0)
        attempts = attempts + 1
    end
    return HasModelLoaded(modelHash)
end

-- ─── Prop config lookup ───────────────────────────────────────────────────────

-- Returns propModel, handPos, handRot for an item name.
-- Falls back to Config.DefaultProp when no entry exists.
function GetThrowPropConfig(itemName)
    if itemName then
        local lower = itemName:lower()
        for key, value in pairs(Config.ThrowProps) do
            if key:lower() == lower then
                if type(value) == "table" then
                    local prop = value.prop or Config.DefaultProp
                    return prop, value.pos, value.rot
                end
                return value, nil, nil
            end
        end
    end
    return Config.DefaultProp, nil, nil
end

-- ─── Camera / raycast helpers ─────────────────────────────────────────────────

-- Converts Euler rotation (degrees) to a forward direction vector
function EulerToForwardVector(rot)
    local radZ = math.pi / 180 * rot.z
    local radX = math.pi / 180 * rot.x
    local cosX = math.abs(math.cos(radX))
    return vector3(-math.sin(radZ) * cosX, math.cos(radZ) * cosX, math.sin(radX))
end

-- Returns the spawn origin (either gameplay cam position or hand bone position + offset)
function GetThrowOrigin(ped)
    if GetFollowPedCamViewMode() == 4 then
        return GetGameplayCamCoord()
    end
    local bonePos = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
    local forward = EulerToForwardVector(GetGameplayCamRot(2))
    return vector3(
        bonePos.x + forward.x * 0.22,
        bonePos.y + forward.y * 0.22,
        bonePos.z + forward.z * 0.22
    )
end

-- Casts a ray from origin in the camera forward direction, returns hit, coords, normal, entity
function CastPlacementRay(ped, maxDistance)
    local origin  = GetThrowOrigin(ped)
    local forward = EulerToForwardVector(GetGameplayCamRot(2))
    local target  = origin + forward * maxDistance

    local rayHandle = StartShapeTestLosProbe(
        origin.x, origin.y, origin.z,
        target.x, target.y, target.z,
        273, ped, 7
    )
    local _, hitFlag, hitCoords, hitNormal, hitEntity = GetShapeTestResult(rayHandle)
    return hitFlag == 1, hitCoords, hitNormal, hitEntity
end

-- Returns the ghost prop's desired world position, surface normal, and whether it hit
function ResolvePlacementPosition(ped)
    local maxDist = Config.PlaceMaxDistance or 5.0
    local rayHit, hitCoords, hitNormal, _ = CastPlacementRay(ped, maxDist)

    if rayHit then
        return hitCoords, hitNormal, true
    end

    -- No ray hit: project forward and snap to ground
    local origin  = GetThrowOrigin(ped)
    local forward = EulerToForwardVector(GetGameplayCamRot(2))
    local projected = origin + forward * placeDistance

    local groundFound, groundZ = GetGroundZFor_3dCoord(
        projected.x, projected.y, projected.z + 2.0, false)
    if groundFound then
        projected = vector3(projected.x, projected.y, groundZ)
    end

    return projected, vector3(0.0, 0.0, 1.0), false
end

-- ─── Hand bone helper ─────────────────────────────────────────────────────────

function GetRightHandBoneIndex(ped)
    return GetPedBoneIndex(ped, 57005)
end

-- Attaches a prop to the player's right hand using configured or default offsets
function AttachPropToHand(prop, ped, handPos, handRot)
    if not prop or not DoesEntityExist(prop) then return end

    local boneIndex = GetRightHandBoneIndex(ped)
    local pos = handPos or Config.ThrowDefaultHandPos
    local rot = handRot or Config.ThrowDefaultHandRot

    AttachEntityToEntity(
        prop, ped, boneIndex,
        pos.x, pos.y, pos.z,
        rot.x, rot.y, rot.z,
        true, true, false, true, 1, true
    )
end

-- ─── Animation helpers ────────────────────────────────────────────────────────

function LoadAnimDict(dict)
    if not dict then return false end
    RequestAnimDict(dict)
    local attempts = 0
    while not HasAnimDictLoaded(dict) and attempts < 50 do
        Wait(10)
        attempts = attempts + 1
    end
    return HasAnimDictLoaded(dict)
end

-- Plays a placement animation (crouch or standing) if configured
function PlayPlaceAnimation(ped, animKey)
    local anims = Config.PlaceAnimations
    if not anims then return end

    local animData = anims[animKey] or anims.standing
    if not animData or not animData.dict or not animData.anim then return end

    if LoadAnimDict(animData.dict) then
        TaskPlayAnim(ped, animData.dict, animData.anim, 8.0, 8.0, 1250, 48, 0, false, false, false)
        Wait(1000)
    end
end

-- Detects whether the ped is crouching/on the ground based on hip bone height vs placement Z
function DetectPosture(ped, placedCoords)
    local hipBoneIndex = GetPedBoneIndex(ped, 11816)
    local hipWorldPos  = GetWorldPositionOfEntityBone(ped, hipBoneIndex)
    if hipWorldPos.z - placedCoords.z > 0.5 then
        return "ground"
    end
    return "standing"
end

-- ─── Cancel / cleanup ─────────────────────────────────────────────────────────

function CancelPlacement()
    placingActive  = false
    placementValid = false
    HideTextUI()
    LocalPlayer.state:set("intThrowState", false, true)

    if ghostProp and DoesEntityExist(ghostProp) then DeleteEntity(ghostProp) end
    ghostProp = nil
    if solidProp and DoesEntityExist(solidProp) then DeleteEntity(solidProp) end
    solidProp = nil
end

-- ─── Rotation input ───────────────────────────────────────────────────────────

function HandleRotationInput()
    local step = Config.PlaceRotationStep or 5.0
    DisableControlAction(0, 15, true)
    DisableControlAction(0, 16, true)

    if IsDisabledControlJustPressed(0, 15) then
        placementYaw = (placementYaw + step) % 360.0
    end
    if IsDisabledControlJustPressed(0, 16) then
        placementYaw = (placementYaw - step) % 360.0
        if placementYaw < 0.0 then placementYaw = placementYaw + 360.0 end
    end
end

-- ─── Main placement thread ────────────────────────────────────────────────────

function StartPlacementMode(itemName, slotIndex, propModel, handPos, handRot)
    if placingActive then return end

    CloseInventory()
    LocalPlayer.state:set("intThrowState", true, true)
    Wait(0)
    Wait(0)

    local ped = PlayerPedId()

    if IsEntityDead(ped) then
        Framework:Notify("You cannot place items while dead!", "error")
        CancelPlacement()
        return
    end
    if IsPedInAnyVehicle(ped, false) then
        Framework:Notify("You cannot place items while in a vehicle!", "error")
        CancelPlacement()
        return
    end

    -- Load the prop model (fall back to DefaultProp)
    local modelHash = GetHashKey(propModel)
    if not RequestModelSync(modelHash) then
        modelHash = GetHashKey(Config.DefaultProp)
        if not RequestModelSync(modelHash) then
            Framework:Notify("Failed to load placement model!", "error")
            CancelPlacement()
            return
        end
    end

    placingActive  = true
    placementYaw   = GetEntityHeading(ped)
    placeDistance  = 2.0

    local spawnPos = GetEntityCoords(ped)

    -- Create solid hand-attached prop
    solidProp = CreateObject(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, false, true, false)
    if solidProp and DoesEntityExist(solidProp) then
        SetEntityCollision(solidProp, false, false)
        AttachPropToHand(solidProp, ped, handPos, handRot)
    end

    -- Create semi-transparent ghost preview prop
    ghostProp = CreateObject(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, false, true, false)
    if ghostProp and DoesEntityExist(ghostProp) then
        SetEntityCollision(ghostProp, false, false)
        SetEntityAlpha(ghostProp, 150, false)
    end

    SetModelAsNoLongerNeeded(modelHash)
    ShowTextUI("place", Translate("PLACE_TEXT_UI"))

    CreateThread(function()
        while true do
            if not placingActive then break end
            if not ghostProp then break end
            if not DoesEntityExist(ghostProp) then break end

            Wait(0)

            local currentPed = PlayerPedId()
            if not DoesEntityExist(currentPed) or IsEntityDead(currentPed) then
                CancelPlacement()
                break
            end

            HandleRotationInput()
            DisableControlAction(0, 73, true)  -- block Enter

            -- Resolve position
            local targetPos, surfaceNormal, rayHit = ResolvePlacementPosition(currentPed)
            local pedCoords = GetEntityCoords(currentPed)
            local dist = #(pedCoords - targetPos)

            local maxDist = Config.PlaceMaxDistance or 5.0
            local minDist = Config.PlaceMinDistance or 0.5

            if dist < minDist then
                placementValid = false
            elseif dist > maxDist then
                placementValid = false
            else
                placementValid = true
            end

            -- Position and orient the ghost prop
            if ghostProp and DoesEntityExist(ghostProp) then
                SetEntityCoordsNoOffset(ghostProp, targetPos.x, targetPos.y, targetPos.z, false, false, false)

                if rayHit and surfaceNormal then
                    -- Tilt to match surface normal
                    local pitchDeg  = math.max(-80.0, math.min(80.0,  math.deg(math.asin( surfaceNormal.y))))
                    local rollDeg   = math.max(-80.0, math.min(80.0, -math.deg(math.asin( surfaceNormal.x))))
                    SetEntityRotation(ghostProp, pitchDeg, rollDeg, placementYaw, 2, true)
                else
                    PlaceObjectOnGroundProperly(ghostProp)
                    SetEntityHeading(ghostProp, placementYaw)
                end

                SetEntityAlpha(ghostProp, placementValid and 150 or 100, false)
            end

            -- Confirm placement (E / enter)
            if IsControlJustReleased(0, 38) and placementValid then
                local finalCoords = GetEntityCoords(ghostProp)
                local finalRot    = GetEntityRotation(ghostProp, 2)

                if ghostProp and DoesEntityExist(ghostProp) then DeleteEntity(ghostProp) ghostProp = nil end
                if solidProp and DoesEntityExist(solidProp) then DeleteEntity(solidProp) solidProp = nil end

                local posture = DetectPosture(currentPed, finalCoords)
                PlayPlaceAnimation(currentPed, posture)

                TriggerServerEvent("bablo-throwitems:place:finalize",
                    itemName, slotIndex, propModel, finalCoords, finalRot)

                placingActive  = false
                placementValid = false
                HideTextUI()
                LocalPlayer.state:set("intThrowState", false, true)
                break

            -- Give to nearby player (E when placement invalid)
            elseif IsControlJustReleased(0, 38) and not placementValid then
                local origin  = GetThrowOrigin(currentPed)
                local forward = EulerToForwardVector(GetGameplayCamRot(2))
                local giveDist = Config.PlaceGiveDistance or 3.0
                local endPos  = origin + forward * giveDist

                local rayHandle = StartShapeTestLosProbe(
                    origin.x, origin.y, origin.z,
                    endPos.x, endPos.y, endPos.z,
                    -1, currentPed, 7
                )
                local _, hitFlag, _, _, hitEntity = GetShapeTestResult(rayHandle)

                if hitFlag == 1 and hitEntity and DoesEntityExist(hitEntity)
                    and IsEntityAPed(hitEntity) and IsPedAPlayer(hitEntity) then
                    local playerIndex = NetworkGetPlayerIndexFromPed(hitEntity)
                    if playerIndex ~= -1 then
                        local targetServerId = GetPlayerServerId(playerIndex)
                        PlayPlaceAnimation(currentPed, "give")
                        TriggerServerEvent("bablo-throwitems:place:giveItem", itemName, slotIndex, targetServerId)
                        CancelPlacement()
                        break
                    end
                end

            -- Cancel (backspace / B)
            elseif IsDisabledControlJustReleased(0, 73, true) then
                CancelPlacement()
                break
            end
        end

        -- Final cleanup if loop exited without explicit cleanup
        if ghostProp and DoesEntityExist(ghostProp) then DeleteEntity(ghostProp) ghostProp = nil end
        if solidProp and DoesEntityExist(solidProp) then DeleteEntity(solidProp) solidProp = nil end
    end)
end

-- ─── Export: placeItem ────────────────────────────────────────────────────────

exports("placeItem", function(itemData, propOverride)
    if placingActive then return end
    if not itemData then return end

    local itemName, slotIndex

    if type(itemData) == "table" and itemData.name and itemData.slot then
        itemName  = itemData.name
        slotIndex = itemData.slot
    else
        local slotArg = (type(itemData) == "table" and itemData.slot) or itemData
        if not slotArg then return end
        itemName, slotIndex = GetItemBySlot(slotArg)
    end

    if not itemName then
        Framework:Notify("No item found in that slot!", "error")
        return
    end

    if Config.BlacklistedItems and Config.BlacklistedItems[itemName] then
        Framework:Notify("You cannot place this item!", "error")
        return
    end

    local propModel, handPos, handRot = GetThrowPropConfig(itemName)
    if propOverride then propModel = propOverride end

    CreateThread(function()
        StartPlacementMode(itemName, slotIndex, propModel, handPos, handRot)
    end)
end)

-- ─── Commands ─────────────────────────────────────────────────────────────────

RegisterCommand("cancelplace", function()
    CancelPlacement()
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CancelPlacement()
end)
