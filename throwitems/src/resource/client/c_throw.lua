-- c_throw.lua  –  Item throw mode for bablo-throwitems

if GetCurrentResourceName() ~= "bablo-throwitems" then
    error("Resource name must be 'bablo-throwitems'")
    return
end

-- ─── Constants ────────────────────────────────────────────────────────────────

local BALL_MODEL_HASH = -383950123   -- hash of the invisible ball weapon projectile

-- ─── State ────────────────────────────────────────────────────────────────────

local throwingActive    = false   -- is throw mode running?
local handProp          = nil     -- prop attached to player's hand during wind-up
local itemName          = nil     -- current item's name
local slotIndex         = nil     -- current item's inventory slot
local propModelName     = nil     -- model string used for the thrown prop

local customHandPos     = nil     -- per-item hand position override
local customHandRot     = nil     -- per-item hand rotation override

local throwCount        = 0       -- incremented each throw; used to de-duplicate
local otherPlayerProps  = {}      -- [serverId] = { handProp, flyingProp, trackedBall, propModel }
local pendingLandProps  = {}      -- used during onResourceStop cleanup

-- ─── Model loading ────────────────────────────────────────────────────────────

-- Loads a model hash (or string) and returns true/false
function RequestThrowModel(model)
    if type(model) == "string" then model = GetHashKey(model) end
    if not IsModelValid(model) then return false end

    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 200 do
        Wait(0)
        attempts = attempts + 1
    end
    return HasModelLoaded(model)
end

-- Creates an object at pos with collision disabled. Returns the entity or nil.
function CreateThrowProp(propModel, pos, networkSync)
    local hash = GetHashKey(propModel)
    if not RequestThrowModel(hash) then
        hash = GetHashKey(Config.DefaultProp)
        if not RequestThrowModel(hash) then return nil end
    end

    local entity = CreateObject(hash, pos.x, pos.y, pos.z,
        networkSync or false, true, false)
    if entity and DoesEntityExist(entity) then
        SetEntityCollision(entity, false, false)
        SetModelAsNoLongerNeeded(hash)
    end
    return entity
end

-- ─── Hand bone resolution ─────────────────────────────────────────────────────

-- Returns the bone ID for the throwing hand (driver/left = 18905, passenger/right = 57005)
function GetThrowHandBone(ped)
    if not IsPedInAnyVehicle(ped, false) then return 57005 end

    local vehicle = GetVehiclePedIsIn(ped, false)
    local seatIndex = -1
    for i = -1, 3 do
        if GetPedInVehicleSeat(vehicle, i) == ped then
            seatIndex = i
            break
        end
    end
    return (seatIndex == -1 or seatIndex == 1) and 18905 or 57005
end

-- Attaches a prop to the player's hand using the current per-item or default offsets
function AttachThrowPropToHand(prop, ped)
    if not prop or not DoesEntityExist(prop) then return end

    local boneId  = GetThrowHandBone(ped)
    local boneIdx = GetPedBoneIndex(ped, boneId)
    local pos = customHandPos or Config.ThrowDefaultHandPos
    local rot = customHandRot or Config.ThrowDefaultHandRot

    AttachEntityToEntity(
        prop, ped, boneIdx,
        pos.x, pos.y, pos.z,
        rot.x, rot.y, rot.z,
        true, true, false, true, 1, true
    )
end

-- ─── Inventory close ─────────────────────────────────────────────────────────

-- (same multi-inventory logic as c_place.lua – duplicated here to keep files self-contained)
function CloseInventoryForThrow()
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

-- ─── Item-by-slot lookup (throw) ─────────────────────────────────────────────

function GetThrowItemBySlot(slotArg)
    local inv = Config.Inventory
    if inv == "ox_inventory" then
        local items = exports.ox_inventory:GetPlayerItems()
        if items then
            for _, item in pairs(items) do
                if item.slot == slotArg then return item.name, item.slot end
            end
        end

    elseif inv == "qb-inventory" then
        print("qb-inventory")
        local item = exports["qb-inventory"]:GetItemBySlot(slotArg)
        print("item", json.encode(item))
        print("slot", slotArg)
        if item then return item.name, item.slot end

    elseif inv == "ps-inventory" then
        local item = exports["ps-inventory"]:GetItemBySlot(slotArg)
        if item then return item.name, item.slot end

    elseif inv == "qs-inventory" then
        local item = exports["qs-inventory"]:GetItemBySlot(slotArg)
        if item then return item.name, item.slot end
    end

    return nil, nil
end

-- ─── Prop config lookup ───────────────────────────────────────────────────────

-- Returns propModel, handPos, handRot — propOverride bypasses the lookup
function GetThrowPropConfig(name, propOverride)
    if propOverride then return propOverride, nil, nil end

    if name then
        local lower = name:lower()
        for key, value in pairs(Config.ThrowProps) do
            if key:lower() == lower then
                if type(value) == "table" then
                    return value.prop or Config.DefaultProp, value.pos, value.rot
                end
                return value, nil, nil
            end
        end
    end

    return Config.DefaultProp, nil, nil
end

-- ─── State machine: inventory open/close ─────────────────────────────────────

function EnterThrowInventoryState()
    if Config.Inventory == "ox_inventory" then
        pcall(function() exports.ox_inventory:weaponWheel(true) end)
    end
    LocalPlayer.state:set("intThrowState", true, true)
end

function ExitThrowInventoryState()
    if Config.Inventory == "ox_inventory" then
        pcall(function() exports.ox_inventory:weaponWheel(false) end)
    end
    LocalPlayer.state:set("intThrowState", false, true)
end

-- ─── Equip the ball weapon ────────────────────────────────────────────────────

function EquipBallWeapon(ped, ballHash)
    GiveWeaponToPed(ped, ballHash, 1, false, true)
    SetPedAmmo(ped, ballHash, 1)
    SetPedInfiniteAmmoClip(ped, true)
    SetPedInfiniteAmmo(ped, true, ballHash)
    SetCurrentPedWeapon(ped, ballHash, true)
end

-- ─── Cleanup / cancel ────────────────────────────────────────────────────────

-- Resets all throw state for the local player
function CancelThrow(suppressServerEvent)
    local ped       = PlayerPedId()
    local ballHash  = GetHashKey("WEAPON_BALL")

    throwingActive = false
    HideTextUI()
    ExitThrowInventoryState()

    if handProp and DoesEntityExist(handProp) then DeleteEntity(handProp) end
    handProp = nil
    itemName, slotIndex, propModelName = nil, nil, nil
    customHandPos, customHandRot = nil, nil
    otherPlayerProps = {}

    SetPedInfiniteAmmoClip(ped, false)
    SetPedInfiniteAmmo(ped, false, ballHash)
    RemoveAllPedWeapons(ped, true)
    SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
    SetPedCanSwitchWeapon(ped, true)

    if not suppressServerEvent then
        TriggerServerEvent("bablo-throwitems:throw:clearState")
    end
end

-- ─── Nearby flying ball detection ────────────────────────────────────────────

-- Returns the first ball-model CObject near the ped that is stationary on the ground
function FindNearbyLandedBall(ped)
    local origin  = GetEntityCoords(ped)
    local objects = GetGamePool("CObject")

    for _, obj in ipairs(objects) do
        if DoesEntityExist(obj) then
            local model = GetEntityModel(obj)
            if model == BALL_MODEL_HASH then
                local tracked = otherPlayerProps[obj]
                local dist    = #(origin - GetEntityCoords(obj))

                if not tracked and dist < 40.0 then
                    local vel   = GetEntityVelocity(obj)
                    local inAir = IsEntityInAir(obj)
                    if inAir or #vel > 0.001 then
                        return obj
                    end
                end
            end
        end
    end

    return nil
end

-- Returns the first ball-model CObject near the ped that is actively flying
function FindNearbyFlyingBall(ped)
    local origin  = GetEntityCoords(ped)
    local objects = GetGamePool("CObject")

    for _, obj in ipairs(objects) do
        if DoesEntityExist(obj) and GetEntityModel(obj) == BALL_MODEL_HASH then
            local dist = #(origin - GetEntityCoords(obj))
            if dist < 30.0 then
                local vel   = GetEntityVelocity(obj)
                local inAir = IsEntityInAir(obj)
                if inAir and #vel > 5.0 then
                    return obj
                end
            end
        end
    end

    return nil
end

-- ─── Landing monitor ─────────────────────────────────────────────────────────

-- Waits for the ball/prop to land, then fires server events and cleans up entities
function WatchForLanding(ballEntity, flyingPropEntity, currentItemName, currentSlot)
    CreateThread(function()
        while true do
            if not ballEntity or not DoesEntityExist(ballEntity) then break end

            Wait(0)

            local vel   = GetEntityVelocity(ballEntity)
            local inAir = IsEntityInAir(ballEntity)

            if #vel < 0.3 and not inAir then
                Wait(800)

                local landedPos, landedRot

                if flyingPropEntity and DoesEntityExist(flyingPropEntity) then
                    landedPos = GetEntityCoords(flyingPropEntity)
                    landedRot = GetEntityRotation(flyingPropEntity, 2)
                else
                    landedPos = GetEntityCoords(ballEntity)
                    landedRot = vector3(0.0, 0.0, 0.0)
                end

                if flyingPropEntity and DoesEntityExist(flyingPropEntity) then
                    DeleteEntity(flyingPropEntity)
                end
                if DoesEntityExist(ballEntity) then DeleteEntity(ballEntity) end

                TriggerServerEvent("bablo-throwitems:throw:land",
                    currentItemName, landedPos, landedRot, currentSlot)
                TriggerServerEvent("bablo-throwitems:throw:finalize", landedPos, currentSlot)

                HideTextUI()
                break
            end
        end

        -- If loop exited with a flying prop still alive, detach and finalize there
        if flyingPropEntity and DoesEntityExist(flyingPropEntity) then
            local lastPos = GetEntityCoords(flyingPropEntity)
            DetachEntity(flyingPropEntity, true, true)
            DeleteEntity(flyingPropEntity)
            TriggerServerEvent("bablo-throwitems:throw:finalize", lastPos, currentSlot)
        end
    end)
end

-- ─── State bag: throwMode (other players) ────────────────────────────────────

-- Extracts the server ID from a state bag key like "player:12"
local function ParsePlayerStateBagId(bagName)
    if not bagName:find("player:") then return nil end
    return tonumber((bagName:gsub("player:", "")))
end

-- Returns true if the given server ID belongs to the local player
local function IsLocalPlayer(serverId)
    return serverId == GetPlayerServerId(PlayerId())
end

-- Returns the ped entity for a given server ID, or nil
local function GetPedFromServerId(serverId)
    local localPlayer = GetPlayerFromServerId(serverId)
    if localPlayer == -1 then return nil end
    local ped = GetPlayerPed(localPlayer)
    if not DoesEntityExist(ped) then return nil end
    return ped
end

-- Returns true if another player is within sync distance
local function IsWithinSyncDistance(otherPed)
    local myCoords    = GetEntityCoords(PlayerPedId())
    local otherCoords = GetEntityCoords(otherPed)
    return #(myCoords - otherCoords) <= Config.ThrowSyncDistance
end

-- Cleans up any existing props tracked for a server ID
local function CleanOtherPlayerProps(serverId)
    local entry = otherPlayerProps[serverId]
    if not entry then return end

    if entry.handProp and DoesEntityExist(entry.handProp) then
        DeleteEntity(entry.handProp)
    end
    if entry.flyingProp and DoesEntityExist(entry.flyingProp) then
        DeleteEntity(entry.flyingProp)
    end
    otherPlayerProps[serverId] = nil
end

AddStateBagChangeHandler("throwMode", nil, function(bagName, _, newValue)
    local serverId = ParsePlayerStateBagId(bagName)
    if not serverId or IsLocalPlayer(serverId) then return end

    local otherPed = GetPedFromServerId(serverId)
    if not otherPed or not IsWithinSyncDistance(otherPed) then return end

    CleanOtherPlayerProps(serverId)

    if newValue and newValue.propModel then
        local spawnPos = GetEntityCoords(otherPed)
        local prop     = CreateThrowProp(newValue.propModel, spawnPos, false)
        if prop and DoesEntityExist(prop) then
            AttachThrowPropToHand(prop, otherPed)
            otherPlayerProps[serverId] = {
                handProp   = prop,
                propModel  = newValue.propModel,
                flyingProp = nil,
            }
        end
    end
end)

-- ─── State bag: throwData (flying prop sync) ──────────────────────────────────

AddStateBagChangeHandler("throwData", nil, function(bagName, _, newValue)
    local serverId = ParsePlayerStateBagId(bagName)
    if not serverId or IsLocalPlayer(serverId) then return end

    local otherPed = GetPedFromServerId(serverId)
    if not otherPed or not IsWithinSyncDistance(otherPed) then return end

    if not newValue or not newValue.propModel then return end

    -- Remove old hand prop
    local entry = otherPlayerProps[serverId]
    if entry and entry.handProp and DoesEntityExist(entry.handProp) then
        DeleteEntity(entry.handProp)
        entry.handProp = nil
    end

    -- Spawn a flying prop that tracks the ball
    CreateThread(function()
        local propModel = newValue.propModel
        local flyingProp, trackedBall
        local attempts = 0

        Wait(50)
        while attempts < 100 and not trackedBall do
            trackedBall = FindNearbyFlyingBall(otherPed)
            if trackedBall then break end
            Wait(20)
            attempts = attempts + 1
        end

        if not trackedBall then return end

        SetEntityVisible(trackedBall, false, false)

        local ballPos = GetEntityCoords(trackedBall)
        flyingProp    = CreateThrowProp(propModel, ballPos, false)

        if flyingProp and DoesEntityExist(flyingProp) then
            AttachEntityToEntity(
                flyingProp, trackedBall, 0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                false, false, false, false, 0, true
            )

            if otherPlayerProps[serverId] then
                otherPlayerProps[serverId].flyingProp  = flyingProp
                otherPlayerProps[serverId].trackedBall = trackedBall
            else
                otherPlayerProps[serverId] = {
                    flyingProp  = flyingProp,
                    trackedBall = trackedBall,
                    propModel   = propModel,
                }
            end
        end

        -- Watch until ball lands
        local ticks = 0
        while ticks < 500 do
            Wait(20)
            ticks = ticks + 1
            if not trackedBall or not DoesEntityExist(trackedBall) then break end

            local vel   = GetEntityVelocity(trackedBall)
            local inAir = IsEntityInAir(trackedBall)

            if #vel < 0.5 and not inAir then
                Wait(500)
                if flyingProp and DoesEntityExist(flyingProp) then DeleteEntity(flyingProp) end
                if trackedBall and DoesEntityExist(trackedBall) then DeleteEntity(trackedBall) end

                local e = otherPlayerProps[serverId]
                if e then e.flyingProp = nil e.trackedBall = nil end
                break
            end
        end

        -- Timeout cleanup
        if flyingProp and DoesEntityExist(flyingProp) then DeleteEntity(flyingProp) end
        if trackedBall and DoesEntityExist(trackedBall) then DeleteEntity(trackedBall) end

        local e = otherPlayerProps[serverId]
        if e then e.flyingProp = nil e.trackedBall = nil end
    end)
end)

-- ─── Net event: prop landed (from server to all observers) ───────────────────

RegisterNetEvent("bablo-throwitems:throw:propLanded")
AddEventHandler("bablo-throwitems:throw:propLanded", function(ownerServerId)
    if ownerServerId == GetPlayerServerId(PlayerId()) then return end

    local entry = otherPlayerProps[ownerServerId]
    if entry then
        if entry.flyingProp and DoesEntityExist(entry.flyingProp) then
            DeleteEntity(entry.flyingProp)
        end
        if entry.trackedBall and DoesEntityExist(entry.trackedBall) then
            DeleteEntity(entry.trackedBall)
        end
        otherPlayerProps[ownerServerId] = nil
    end
end)

-- ─── Core throw logic ─────────────────────────────────────────────────────────

function StartThrowMode(currentItemName, currentSlot, currentPropModel)
    if throwingActive then return end

    throwCount = throwCount + 1
    local myThrowCount = throwCount

    CloseInventoryForThrow()
    EnterThrowInventoryState()

    local ballHash    = GetHashKey("WEAPON_BALL")
    local propHash    = GetHashKey(currentPropModel)

    -- Pre-load weapon and prop assets
    RequestWeaponAsset(ballHash, 31, 0)
    if IsModelValid(propHash) then RequestModel(propHash) end

    Wait(0) Wait(0)

    local ped = PlayerPedId()

    -- Clean up stale hand prop
    if handProp and DoesEntityExist(handProp) then
        DeleteEntity(handProp)
        handProp = nil
    end

    -- Remove existing weapons and old nearby balls
    RemoveAllPedWeapons(ped, true)
    Wait(0)

    local pedCoords = GetEntityCoords(ped)
    for _, obj in ipairs(GetGamePool("CObject")) do
        if DoesEntityExist(obj) and GetEntityModel(obj) == BALL_MODEL_HASH then
            local dist = #(pedCoords - GetEntityCoords(obj))
            if dist < 30.0 then
                local vel = GetEntityVelocity(obj)
                if #vel < 0.1 and not IsEntityInAir(obj) then
                    SetEntityAsMissionEntity(obj, true, true)
                    DeleteEntity(obj)
                end
            end
        end
    end

    -- Death check
    if IsEntityDead(ped) then
        Framework:Notify("You cannot throw items while dead!", "error")
        ExitThrowInventoryState()
        return
    end

    throwingActive = true
    itemName       = currentItemName
    slotIndex      = currentSlot
    propModelName  = currentPropModel

    TriggerServerEvent("bablo-throwitems:throw:enterMode",
        propModelName, itemName, slotIndex, myThrowCount)

    -- Wait for ball weapon asset
    local assetAttempts = 0
    while not HasWeaponAssetLoaded(ballHash) and assetAttempts < 400 do
        Wait(0)
        assetAttempts = assetAttempts + 1
    end

    if not HasWeaponAssetLoaded(ballHash) then
        throwingActive = false
        ExitThrowInventoryState()
        Framework:Notify("Failed to load throw weapon!", "error")
        TriggerServerEvent("bablo-throwitems:throw:clearState")
        return
    end

    EquipBallWeapon(ped, ballHash)
    SetPedCanSwitchWeapon(ped, false)
    Wait(0)

    -- Spawn hand prop and attach it
    pedCoords = GetEntityCoords(ped)
    handProp  = CreateThrowProp(currentPropModel, pedCoords, false)
    if handProp and DoesEntityExist(handProp) then
        SetEntityVisible(handProp, true, false)
        AttachThrowPropToHand(handProp, ped)
    end

    -- Track which hand side the player is on (to re-attach if they switch)
    local currentHandBone = GetThrowHandBone(ped)

    -- Thread: re-attach hand prop if player switches vehicle seat
    CreateThread(function()
        while throwingActive and handProp and DoesEntityExist(handProp) do
            Wait(100)
            local newBone = GetThrowHandBone(PlayerPedId())
            if newBone ~= currentHandBone then
                currentHandBone = newBone
                DetachEntity(handProp, true, true)
                AttachThrowPropToHand(handProp, PlayerPedId())
            end
        end
    end)

    ShowTextUI("throw", Translate("THROW_TEXT_UI"))

    -- Thread: keep controls disabled and ammo at 1
    CreateThread(function()
        while throwingActive do
            Wait(0)
            DisableControlAction(0, 37,  true)   -- weapon select left
            DisableControlAction(0, 157, true)
            DisableControlAction(0, 158, true)
            DisableControlAction(0, 159, true)
            DisableControlAction(0, 160, true)
            DisableControlAction(0, 164, true)
            DisableControlAction(0, 165, true)

            local currentPed = PlayerPedId()
            if GetAmmoInPedWeapon(currentPed, ballHash) < 1 then
                SetPedAmmo(currentPed, ballHash, 1)
            end
        end
    end)

    -- Thread: detect throw and transition to flight tracking
    CreateThread(function()
        local tracking    = false
        local ballEntity  = nil
        local flyingProp  = nil
        local shootTimer  = 0

        while throwingActive do
            Wait(0)
            if not throwingActive then break end

            local currentPed = PlayerPedId()
            if not DoesEntityExist(currentPed) or IsEntityDead(currentPed) then
                CancelThrow()
                break
            end

            -- Hide weapon entity model
            local weaponEntity = GetCurrentPedWeaponEntityIndex(currentPed)
            if weaponEntity and DoesEntityExist(weaponEntity) and IsEntityVisible(weaponEntity) then
                SetEntityVisible(weaponEntity, false, false)
            end

            -- Cancel button
            if IsControlJustPressed(0, 73) then
                HideTextUI()
                CancelThrow()
                break
            end

            if not tracking then
                local _, currentWeapon = GetCurrentPedWeapon(currentPed)
                if currentWeapon == ballHash and IsPedShooting(currentPed) then
                    shootTimer = GetGameTimer()
                    HideTextUI()
                end

                if shootTimer > 0 then
                    local elapsed = GetGameTimer() - shootTimer
                    ballEntity    = FindNearbyLandedBall(currentPed)

                    if ballEntity then
                        -- Ball found: scale down velocity, hide it, spawn flying prop
                        tracking = true
                        otherPlayerProps[ballEntity] = true

                        local vel = GetEntityVelocity(ballEntity)
                        SetEntityVelocity(ballEntity,
                            vel.x * 0.7, vel.y * 0.7, vel.z * 0.7)
                        SetEntityVisible(ballEntity, false, false)

                        if handProp and DoesEntityExist(handProp) then
                            DeleteEntity(handProp)
                            handProp = nil
                        end

                        local ballPos = GetEntityCoords(ballEntity)
                        TriggerServerEvent("bablo-throwitems:throw:sync",
                            propModelName, ballPos, vel)

                        flyingProp = CreateThrowProp(propModelName, ballPos, false)
                        if flyingProp and DoesEntityExist(flyingProp) then
                            AttachEntityToEntity(
                                flyingProp, ballEntity, 0,
                                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                false, false, false, false, 0, true
                            )
                        end

                        throwingActive = false
                        ExitThrowInventoryState()
                        SetPedInfiniteAmmoClip(currentPed, false)
                        SetPedInfiniteAmmo(currentPed, false, ballHash)
                        SetPedCanSwitchWeapon(currentPed, true)
                        RemoveWeaponFromPed(currentPed, ballHash)
                        SetCurrentPedWeapon(currentPed, GetHashKey("WEAPON_UNARMED"), true)

                        WatchForLanding(ballEntity, flyingProp, propModelName, myThrowCount)

                        itemName, slotIndex, propModelName = nil, nil, nil
                        break

                    elseif elapsed >= 1500 then
                        -- Timeout: ball never spawned, treat as landed at feet
                        local footPos = GetEntityCoords(currentPed)

                        -- Clean nearby stale balls
                        for _, obj in ipairs(GetGamePool("CObject")) do
                            if DoesEntityExist(obj) and GetEntityModel(obj) == BALL_MODEL_HASH then
                                if #(footPos - GetEntityCoords(obj)) < 30.0 then
                                    SetEntityAsMissionEntity(obj, true, true)
                                    DeleteEntity(obj)
                                end
                            end
                        end

                        if handProp and DoesEntityExist(handProp) then
                            DeleteEntity(handProp)
                            handProp = nil
                        end

                        TriggerServerEvent("bablo-throwitems:throw:land",
                            propModelName, footPos, vector3(0, 0, 0), myThrowCount)
                        TriggerServerEvent("bablo-throwitems:throw:finalize", footPos, myThrowCount)
                        CancelThrow(true)  -- suppress clearState — already handled
                        break
                    end
                end
            end
        end

        -- Hand prop cleanup
        if handProp and DoesEntityExist(handProp) then
            DeleteEntity(handProp)
            handProp = nil
        end
    end)
end

-- ─── Export: throwItem ────────────────────────────────────────────────────────

exports("throwItem", function(itemData, propOverride)
    if throwingActive then return end
    if not itemData then return end

    local currentItemName, currentSlot

    if type(itemData) == "table" and itemData.name and itemData.slot then
        currentItemName = itemData.name
        currentSlot     = itemData.slot
        if not propOverride then propOverride = itemData.propOverride end
    else
        local slotArg = (type(itemData) == "table" and itemData.slot) or itemData
        if not slotArg then return end
        currentItemName, currentSlot = GetThrowItemBySlot(slotArg)
    end

    if not currentItemName then
        Framework:Notify("No item found in that slot!", "error")
        return
    end

    if Config.BlacklistedItems and Config.BlacklistedItems[currentItemName] then
        Framework:Notify("You cannot throw this item!", "error")
        return
    end

    local propModel, handPos, handRot = GetThrowPropConfig(currentItemName, propOverride)
    customHandPos = handPos
    customHandRot = handRot

    CreateThread(function()
        StartThrowMode(currentItemName, currentSlot, propModel)
    end)
end)

-- ─── Commands & events ───────────────────────────────────────────────────────

RegisterCommand("cancelthrow", function()
    CancelThrow()
    HideTextUI()
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CancelThrow()

    for _, entry in pairs(otherPlayerProps) do
        if entry.handProp and DoesEntityExist(entry.handProp) then
            DeleteEntity(entry.handProp)
        end
        if entry.flyingProp and DoesEntityExist(entry.flyingProp) then
            DeleteEntity(entry.flyingProp)
        end
    end
    otherPlayerProps = {}

    for _, entry in ipairs(pendingLandProps) do
        if entry.prop and DoesEntityExist(entry.prop) then DeleteEntity(entry.prop) end
    end
    pendingLandProps = {}
end)
