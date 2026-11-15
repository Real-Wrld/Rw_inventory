if not lib then return end

local VehicleKeys = {}
local Utils = require 'modules.utils.client'
local Config = require 'shared.vehiclekeysconfig'
local Inventory = require 'modules.inventory.client'

-- Framework / Player Data Access
local function GetPlayerJob()
    -- Attempt to get job from Qbox/QBCore/OX
    if PlayerData and PlayerData.job then return PlayerData.job end
    if GetResourceState('qbx_core') == 'started' then
        -- Qbox doesn't use GetCoreObject, rely on exports or globals if needed later
        -- For now, fallback to other methods or check specific Qbox exports if available
        if exports.qbx_core.GetPlayerData then
            return exports.qbx_core:GetPlayerData().job
        end
    end
    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore and QBCore.Functions then return QBCore.Functions.GetPlayerData().job end
    end
    -- Fallback for OX groups if 'job' structure isn't standard
    if PlayerData and PlayerData.groups then return PlayerData.groups end
    return nil
end

local function IsOnDuty()
    if PlayerData and PlayerData.job and PlayerData.job.onduty ~= nil then return PlayerData.job.onduty end

    -- Qbox: use pcall to safely check export
    if GetResourceState('qbx_core') == 'started' then
        local success, data = pcall(function()
            return exports.qbx_core:GetPlayerData()
        end)
        if success and data and data.job then
            return data.job.onduty
        end
    end

    -- QBCore legacy
    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        return QBCore.Functions.GetPlayerData().job.onduty
    end

    return LocalPlayer.state.onDuty ~= false
end

-------------------------------------------------------------------------------
-- Helper Functions
-------------------------------------------------------------------------------

local function AreKeysJobShared(vehicle)
    if not vehicle then return false end
    if not Config.sharedKeys then return false end

    -- Try to resolve groups/job
    local jobData = GetPlayerJob()                                          -- Could be {name='police', ...} or {police=1, ...}
    local isGroupTable = (type(jobData) == 'table' and jobData.name == nil) -- standard OX groups table {police=1}

    for jobName, jobConfig in pairs(Config.sharedKeys) do
        local hasJob = false
        if isGroupTable then
            hasJob = (jobData[jobName] and jobData[jobName] > 0)
        elseif jobData and jobData.name == jobName then
            hasJob = true
        end

        if hasJob then
            if jobConfig.requireOnduty and not IsOnDuty() then
                -- fail
            else
                local model = GetEntityModel(vehicle)
                local class = GetVehicleClass(vehicle)

                if jobConfig.vehicles and jobConfig.vehicles[model] then return true end
                if jobConfig.classes and jobConfig.classes[class] then return true end
            end
        end
    end
    return false
end

local alertSend = false
local function SendPoliceAlertAttempt(crime, vehicle)
    if alertSend then return end
    alertSend = true

    local hours = GetClockHours()
    local hoursOffset = (24 + hours - Config.policeAlertNightStartHour) % 24
    local chance = hoursOffset > Config.policeAlertNightDuration
        and Config.policeAlertChance
        or Config.policeNightAlertChance

    if math.random() <= chance then
        if Config.alertPolice then
            Config.alertPolice(crime, vehicle)
        else
            TriggerServerEvent('police:server:policeAlert', 'Vehicle Theft: ' .. crime)
        end
    end

    SetTimeout(Config.alertCooldown, function()
        alertSend = false
    end)
end

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------

-- Check if player has keys (Exported)
-- Checks both legacy carkeys and new keyfob system
local keyGraceUntil = {} -- [plate] = GetGameTimer() expiry

---@param plate string
---@param durationMs number|nil
function VehicleKeys.GrantKeyGrace(plate, durationMs)
    if not plate or plate == '' then return end
    plate = plate:gsub('%s+', '')
    keyGraceUntil[plate] = GetGameTimer() + (durationMs or 10000)
end

exports('GrantVehicleKeyGrace', VehicleKeys.GrantKeyGrace)

---ox_inventory Search('slots') returns an array of slot items. Defend against nested { name = {...} } shapes.
local function iterKeyItems(searchResult)
    if not searchResult then return end
    if searchResult[1] and searchResult[1].name then
        return ipairs(searchResult)
    end
    -- Nested by item name, or sparse slot map
    local list = {}
    for _, v in pairs(searchResult) do
        if type(v) == 'table' then
            if v.name and v.metadata ~= nil then
                list[#list + 1] = v
            elseif v[1] then
                for i = 1, #v do
                    list[#list + 1] = v[i]
                end
            end
        end
    end
    local i = 0
    return function()
        i = i + 1
        local item = list[i]
        if item then return i, item end
    end
end

local function plateMatches(stored, plate)
    if type(stored) ~= 'string' then return false end
    return stored:gsub('%s+', '') == plate
end

function VehicleKeys.HasKeys(vehicle)
    if not vehicle then vehicle = cache.vehicle end
    if not vehicle then return false end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then return false end
    plate = plate:gsub('%s+', '')

    local grace = keyGraceUntil[plate]
    if grace and GetGameTimer() < grace then
        return true
    end

    if not PlayerData.loaded or not PlayerData.inventory then return false end

    -- Session unlock from successful hijack/hotwire (survives inventory sync lag)
    local state = Entity(vehicle).state
    if state.keysList then
        -- reserved for session-based sharing
    end
    if state.rwKeyHolders then
        local sid = cache.serverId or GetPlayerServerId(PlayerId())
        if state.rwKeyHolders[tostring(sid)] or state.rwKeyHolders[sid] then
            return true
        end
    end

    local keyfobs = Inventory.Search('slots', 'keyfob')
    if keyfobs then
        for _, item in iterKeyItems(keyfobs) do
            if item.metadata and item.metadata.plates then
                for _, p in ipairs(item.metadata.plates) do
                    if plateMatches(p, plate) then
                        return true
                    end
                end
            end
        end
    end

    local items = Inventory.Search('slots', 'carkeys')
    if items then
        for _, item in iterKeyItems(items) do
            if item.metadata and plateMatches(item.metadata.plate, plate) then
                return true
            end
        end
    end

    local vehicleKeys = Inventory.Search('slots', 'vehiclekeys')
    if vehicleKeys then
        for _, item in iterKeyItems(vehicleKeys) do
            if item.metadata and plateMatches(item.metadata.plate, plate) then
                return true
            end
        end
    end

    return false
end

-- Toggle Vehicle Lock
function VehicleKeys.ToggleLock(vehicle)
    if not vehicle then
        vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.lockDistance, true)
    end

    if not vehicle then
        Utils.Notify({ title = 'Vehicle', description = 'No vehicle nearby', type = 'error' })
        return
    end

    if VehicleKeys.HasKeys(vehicle) or AreKeysJobShared(vehicle) then
        local lockStatus = GetVehicleDoorLockStatus(vehicle)
        local newStatus = (lockStatus == 1) and 2 or 1

        lib.requestAnimDict(Config.anim.dict)
        TaskPlayAnim(cache.ped, Config.anim.dict, Config.anim.clip, 8.0, 8.0, -1, 48, 1, false, false, false)
        PlaySoundFromEntity(-1, "Remote_Control_Fob", vehicle, "PI_Menu_Sounds", true, 0)

        SetVehicleDoorsLocked(vehicle, newStatus)
        Entity(vehicle).state:set('doorslockstate', newStatus, true)

        SetVehicleLights(vehicle, 2)
        Wait(250)
        SetVehicleLights(vehicle, 1)
        Wait(200)
        SetVehicleLights(vehicle, 0)

        Utils.Notify({
            title = 'Vehicle',
            description = (newStatus == 2) and 'Vehicle Locked' or 'Vehicle Unlocked',
            type = (newStatus == 2) and 'success' or 'info',
            icon = (newStatus == 2) and 'lock' or 'lock-open'
        })
    else
        Utils.Notify({ title = 'Vehicle', description = 'You do not have the keys for this vehicle', type = 'error' })
    end
end

-- NPC Key Theft
local isTakingKeys = false
local function StealKeysFromDeadDriver(vehicle)
    if isTakingKeys then return end
    local driver = GetPedInVehicleSeat(vehicle, -1)
    if driver == 0 or not IsEntityDead(driver) or IsPedAPlayer(driver) then return end

    isTakingKeys = true
    if lib.progressCircle({
            duration = 2500,
            label = 'Searching body for keys...',
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true },
        }) then
        local plate = GetVehicleNumberPlateText(vehicle)
        TriggerServerEvent('RW-Inventory:vehiclekeys:giveKeys', plate:gsub('%s+', ''))
        Utils.Notify({ title = 'Vehicle', description = 'You found the keys!', type = 'success' })
    end
    isTakingKeys = false
end

local isHotwiring = false


local function Hotwire(vehicle)
    if isHotwiring then return end
    if GetIsVehicleEngineRunning(vehicle) then return end

    isHotwiring = true
    lib.requestAnimDict(Config.hotwire.anim.dict)
    TaskPlayAnim(cache.ped, Config.hotwire.anim.dict, Config.hotwire.anim.clip, 3.0, 3.0, -1, 16, 0, false, false, false)

    local success = lib.skillCheck(Config.skillCheck.difficulty, Config.skillCheck.inputs)
    StopAnimTask(cache.ped, Config.hotwire.anim.dict, Config.hotwire.anim.clip, 1.0)

    if success then
        Utils.Notify({ title = 'Hotwire', description = 'Hotwire successful!', type = 'success' })
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleEngineOn(vehicle, true, false, true)
        SetVehicleDoorsLocked(vehicle, 1)
        Entity(vehicle).state:set('doorslockstate', 1, true)
        -- Give keys on successful hotwire
        local plate = GetVehicleNumberPlateText(vehicle)
        plate = plate and plate:gsub('%s+', '') or ''
        VehicleKeys.GrantKeyGrace(plate, 60000)
        TriggerServerEvent('RW-Inventory:vehiclekeys:giveKeys', plate)
    else
        Utils.Notify({ title = 'Hotwire', description = 'Hotwire failed!', type = 'error' })
        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, 10000)
        SendPoliceAlertAttempt('carjack', vehicle)
    end
    isHotwiring = false
end

local function OnEnteringDriverSeat()
    local vehicle = cache.vehicle
    if not vehicle then return end

    local hasKeys = VehicleKeys.HasKeys(vehicle) or AreKeysJobShared(vehicle)

    -- With keys: always allow start — turn engine on when sitting down
    if hasKeys then
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        return
    end

    StealKeysFromDeadDriver(vehicle)
    if VehicleKeys.HasKeys(vehicle) then
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        return
    end

    -- NPC was pulled out (alive or dead) and left the engine running — grant keys.
    if GetIsVehicleEngineRunning(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        plate = plate and plate:gsub('%s+', '') or ''
        if plate ~= '' then
            VehicleKeys.GrantKeyGrace(plate, 60000)
            TriggerServerEvent('RW-Inventory:vehiclekeys:giveKeys', plate)
        end
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        return
    end

    Utils.Notify({ title = 'Vehicle', description = 'You do not have a key for this vehicle.', type = 'error' })
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleEngineOn(vehicle, false, true, true)

    CreateThread(function()
        while cache.seat == -1 and DoesEntityExist(vehicle) do
            if VehicleKeys.HasKeys(vehicle) or AreKeysJobShared(vehicle) then
                SetVehicleEngineOn(vehicle, true, true, false)
                break
            end
            if GetIsVehicleEngineRunning(vehicle) then
                break
            end
            SetVehicleEngineOn(vehicle, false, true, true)
            DisableControlAction(0, 71, true)
            DisableControlAction(0, 429, true)
            Wait(0)
        end
    end)
end

-- Validation Loop — only seed lock state for untouched ambient cars.
-- Never overwrite an explicit unlock (doorslockstate == 1) or re-lock mid-entry after hijack.
CreateThread(function()
    while true do
        local vehicle = GetVehiclePedIsTryingToEnter(cache.ped)
        if vehicle ~= 0 then
            local state = Entity(vehicle).state
            if state.doorslockstate == nil then
                local driver = GetPedInVehicleSeat(vehicle, -1)
                if not IsPedAPlayer(driver) and not VehicleKeys.HasKeys(vehicle) then
                    if math.random() > 0.3 then
                        SetVehicleDoorsLocked(vehicle, 2)
                        state:set('doorslockstate', 2, true)
                    else
                        state:set('doorslockstate', 1, true)
                    end
                elseif VehicleKeys.HasKeys(vehicle) then
                    SetVehicleDoorsLocked(vehicle, 1)
                    state:set('doorslockstate', 1, true)
                end
            end
        end
        Wait(500)
    end
end)

-- Lockpicking
local isLockpicking = false
function VehicleKeys.LockpickDoor(isAdvanced)
    if isLockpicking then return end
    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 3.0, true)
    if not vehicle then return end

    if GetVehicleDoorLockStatus(vehicle) < 2 then
        Utils.Notify({ description = 'Vehicle is already unlocked', type = 'error' })
        return
    end

    isLockpicking = true
    lib.requestAnimDict(Config.lockpick.anim.dict)
    TaskPlayAnim(cache.ped, Config.lockpick.anim.dict, Config.lockpick.anim.clip, 3.0, 3.0, -1, 16, 0, false, false,
        false)

    local difficulty = isAdvanced and Config.skillCheck.difficulty or { 'easy', 'medium', 'medium' }
    local inputs = isAdvanced and { '1', '2', '3', '4' } or Config.skillCheck.inputs
    local success = lib.skillCheck(difficulty, inputs)
    StopAnimTask(cache.ped, Config.lockpick.anim.dict, Config.lockpick.anim.clip, 1.0)

    if success then
        Utils.Notify({ title = 'Lockpick', description = 'Vehicle unlocked!', type = 'success' })
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        Entity(vehicle).state:set('doorslockstate', 1, true)
        SetVehicleAlarm(vehicle, false)
        Entity(vehicle).state:set('doorslockstate', 1, true)
        -- Give keys on successful lockpick
        local plate = GetVehicleNumberPlateText(vehicle)
        plate = plate and plate:gsub('%s+', '') or ''
        VehicleKeys.GrantKeyGrace(plate, 60000)
        TriggerServerEvent('RW-Inventory:vehiclekeys:giveKeys', plate)
    else
        Utils.Notify({ title = 'Lockpick', description = 'Lockpick failed!', type = 'error' })
        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, 10000)
        SendPoliceAlertAttempt('carjack', vehicle)

        -- Chance to break lockpick
        local breakChance = isAdvanced and 0.1 or 0.3 -- Example values, ideally from config
        if math.random() < breakChance then
            Utils.Notify({ description = 'Your lockpick broke!', type = 'error' })
            TriggerServerEvent('RW-Inventory:vehiclekeys:breakLockpick', isAdvanced and 'advancedlockpick' or 'lockpick')
        end
    end
    isLockpicking = false
end

-- Keybinds & Exports
local function ToggleEngine()
    local vehicle = cache.vehicle
    if not vehicle or cache.seat ~= -1 then return end

    local engineRunning = GetIsVehicleEngineRunning(vehicle)
    if not engineRunning and not VehicleKeys.HasKeys(vehicle) and not AreKeysJobShared(vehicle) then
        Hotwire(vehicle)
        return
    end
    SetVehicleEngineOn(vehicle, not engineRunning, false, true)
end

lib.onCache('seat', function(seat)
    if seat == -1 then
        Wait(100)
        OnEnteringDriverSeat()
    end
end)

-- One-time keybind hint per session
local hasShownKeybindHint = false

lib.onCache('vehicle', function(vehicle)
    if vehicle and not hasShownKeybindHint then
        hasShownKeybindHint = true
        lib.notify({
            title = 'Vehicle Controls',
            description = '**G** - Toggle Engine  |  **;** - Lock/Unlock',
            type = 'inform',
            icon = 'car',
            duration = 5000,
        })
    end

    if not vehicle and Config.keepEngineOnWhenAbandoned and cache.vehicle then
        SetVehicleKeepEngineOnWhenAbandoned(cache.vehicle, true)
    end
end)

lib.addKeybind({
    name = 'togglelocks',
    description = 'Toggle vehicle locks',
    defaultKey = 'SEMICOLON',
    onPressed = function()
        VehicleKeys.ToggleLock()
    end
})
lib.addKeybind({
    name = 'toggleengine',
    description = 'Toggle vehicle engine',
    defaultKey = 'G',
    onPressed = function()
        ToggleEngine()
    end
})

-- Engine toggle command
RegisterCommand('engine', function()
    ToggleEngine()
end, false)

exports('HasKeys', VehicleKeys.HasKeys)
exports('ToggleLock', VehicleKeys.ToggleLock)
exports('LockpickDoor', VehicleKeys.LockpickDoor)
exports('UseLockpick', function() VehicleKeys.LockpickDoor(false) end)
exports('UseAdvancedLockpick', function() VehicleKeys.LockpickDoor(true) end)

-- Auto Helmet Logic
local helmetsDisabled = true

RegisterCommand('nohelmet', function()
    helmetsDisabled = not helmetsDisabled
    local msg = helmetsDisabled and 'Auto bike helmet disabled.' or 'Auto bike helmet enabled.'
    Utils.Notify({ description = msg, type = 'info' })
end, false)

CreateThread(function()
    while true do
        local wait = 500

        if helmetsDisabled then
            local ped = cache.ped
            if ped and IsPedOnAnyBike(ped) then
                wait = 100
                SetPedHelmet(ped, false)
                RemovePedHelmet(ped, true)
                ClearPedProp(ped, 0)
            end
        end

        Wait(wait)
    end
end)

-- Legacy/Compatibility Events
-- These allow other scripts (like vehicle spawners) to give keys using standard events

local function GiveKeys(plate)
    if not plate then return end
    if type(plate) == 'string' then
        TriggerServerEvent('RW-Inventory:vehiclekeys:giveKeys', plate:gsub('%s+', ''))
        Utils.Notify({ title = 'Keys', description = 'You received keys for the vehicle', type = 'success', icon = 'key' })
    end
end

RegisterNetEvent('qb-vehiclekeys:client:AddKeys', GiveKeys)
RegisterNetEvent('vehiclekeys:client:SetOwner', GiveKeys)
RegisterNetEvent('qbx_vehiclekeys:client:AddKeys', GiveKeys)

-- Engine Toggle Compatibility
RegisterNetEvent('qb-vehiclekeys:client:ToggleEngine', ToggleEngine)
RegisterNetEvent('vehiclekeys:client:ToggleEngine', ToggleEngine)
RegisterNetEvent('qbx_vehiclekeys:client:ToggleEngine', ToggleEngine)
RegisterNetEvent('qs-vehiclekeys:client:ToggleEngine', ToggleEngine)
RegisterNetEvent('mk_vehiclekeys:client:ToggleEngine', ToggleEngine)

-- Give Keys to Nearby Player Compatibility
-- Map standard "GiveKeys" events to our command logic
local function ProxyGiveKeys(id)
    ExecuteCommand('givekeys ' .. (id or ''))
end

RegisterNetEvent('qb-vehiclekeys:client:GiveKeys', ProxyGiveKeys)
RegisterNetEvent('vehiclekeys:client:GiveKeys', ProxyGiveKeys)
RegisterNetEvent('qbx_vehiclekeys:client:GiveKeys', ProxyGiveKeys)
RegisterNetEvent('qs-vehiclekeys:client:GiveKeys', ProxyGiveKeys)
RegisterNetEvent('mk_vehiclekeys:client:GiveKeys', ProxyGiveKeys)

-- NUI Callbacks for keyfob context menu
RegisterNUICallback('getKeyfobPlates', function(_, cb)
    local result = lib.callback.await('ox_inventory:getKeyfobPlates', false)
    cb(result or { plates = {} })
end)

RegisterNUICallback('removeKeyfobPlate', function(data, cb)
    if not data or not data.plate then
        cb({ success = false, reason = 'invalid_plate' })
        return
    end

    local success, reason = lib.callback.await('ox_inventory:removeKeyfobPlate', false, data.plate)
    cb({ success = success, reason = reason })
end)

-- ==========================================
-- Spawned Vehicle Detection & Tracker Blips
-- Keys persist in metadata; tooltip only shows spawned vehicles
-- ==========================================

local ownedPlatesCache = {}
local ownedPlatesCacheAt = 0

local function RefreshOwnedPlatesCache()
    local now = GetGameTimer()
    if now - ownedPlatesCacheAt < 2500 then return end
    ownedPlatesCacheAt = now

    local result = lib.callback.await('ox_inventory:getKeyfobPlates', false)
    if not result or not result.plates or #result.plates == 0 then
        ownedPlatesCache = {}
        return
    end

    local owned = lib.callback.await('ox_inventory:filterOwnedPlates', false, result.plates) or {}
    ownedPlatesCache = {}

    for _, plate in ipairs(owned) do
        ownedPlatesCache[plate:gsub('%s+', '')] = true
    end
end

---@param vehicle number
---@param plate string
---@return boolean
local function IsPlayerOwnedVehicleEntity(vehicle, plate)
    if not DoesEntityExist(vehicle) then return false end

    local state = Entity(vehicle).state
    if state.vehicleid then return true end

    if not ownedPlatesCache[plate] then return false end

    local popType = GetEntityPopulationType(vehicle)
    if popType == 2 or popType == 3 or popType == 4 or popType == 5 then
        return false
    end

    return true
end

---Check if a PLAYER-OWNED vehicle with this plate exists in the world
---Filters out NPC/civilian traffic to avoid false matches from GTA's plate reuse
---@param targetPlate string The plate to search for
---@return boolean exists Whether a vehicle with this plate is spawned
---@return number|nil vehicle The vehicle entity if found
local function IsVehicleSpawned(targetPlate)
    if not targetPlate then return false, nil end
    targetPlate = targetPlate:gsub('%s+', '')

    RefreshOwnedPlatesCache()

    if not ownedPlatesCache[targetPlate] then
        return false, nil
    end

    local vehicles = GetGamePool('CVehicle')

    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local plate = GetVehicleNumberPlateText(vehicle)
            if plate then
                plate = plate:gsub('%s+', '')
                if plate == targetPlate then
                    local driver = GetPedInVehicleSeat(vehicle, -1)
                    local isNpcDriver = driver ~= 0 and not IsPedAPlayer(driver)

                    if isNpcDriver then
                        goto continue
                    end

                    if IsPlayerOwnedVehicleEntity(vehicle, plate) then
                        return true, vehicle
                    end
                end
            end
        end

        ::continue::
    end

    return false, nil
end

exports('IsVehicleSpawned', IsVehicleSpawned)

---Get all plates from keyfob that have vehicles currently spawned nearby
---@param maxDistance number?
---@return table spawnedPlates Array of plates for nearby spawned vehicles
---@return number totalPlates Total number of plates on keyfob
local function GetSpawnedKeyfobPlates(maxDistance)
    maxDistance = maxDistance or 120.0

    local result = lib.callback.await('ox_inventory:getKeyfobPlates', false)
    if not result or not result.plates or #result.plates == 0 then
        return {}, 0
    end

    local playerCoords = GetEntityCoords(cache.ped)
    local spawnedPlates = {}

    for _, plate in ipairs(result.plates) do
        local isSpawned, vehicle = IsVehicleSpawned(plate)
        if isSpawned and vehicle then
            local distance = #(GetEntityCoords(vehicle) - playerCoords)
            if distance <= maxDistance then
                spawnedPlates[#spawnedPlates + 1] = plate
            end
        end
    end

    return spawnedPlates, #result.plates
end

-- NUI Callback: Get only spawned plates for tooltip display
RegisterNUICallback('getSpawnedPlates', function(_, cb)
    local spawnedPlates, totalPlates = GetSpawnedKeyfobPlates()
    cb({
        spawnedPlates = spawnedPlates,
        totalPlates = totalPlates
    })
end)

-- ==========================================
-- Owned Vehicle Tracker Blips
-- Shows white blips (ID 825) for spawned owned vehicles
-- ==========================================

local activeVehicleBlip = nil
local activeVehicleBlipEntity = nil

local function ClearVehicleBlip()
    if activeVehicleBlip and DoesBlipExist(activeVehicleBlip) then
        RemoveBlip(activeVehicleBlip)
    end

    activeVehicleBlip = nil
    activeVehicleBlipEntity = nil
end

---Show a single tracker blip for the closest spawned personal vehicle
local function UpdateVehicleBlips()
    RefreshOwnedPlatesCache()

    local result = lib.callback.await('ox_inventory:getKeyfobPlates', false)
    if not result or not result.plates or #result.plates == 0 then
        ClearVehicleBlip()
        return
    end

    local playerCoords = GetEntityCoords(cache.ped)
    local closestPlate, closestVehicle, closestDistance = nil, nil, math.huge

    for _, plate in ipairs(result.plates) do
        local normalized = plate:gsub('%s+', '')
        if ownedPlatesCache[normalized] then
            local isSpawned, vehicle = IsVehicleSpawned(normalized)
            if isSpawned and vehicle then
                local distance = #(GetEntityCoords(vehicle) - playerCoords)
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlate = normalized
                    closestVehicle = vehicle
                end
            end
        end
    end

    if not closestVehicle then
        ClearVehicleBlip()
        return
    end

    if activeVehicleBlip and DoesBlipExist(activeVehicleBlip) then
        local blipEntity = GetBlipInfoIdEntityIndex(activeVehicleBlip)
        if blipEntity == closestVehicle and DoesEntityExist(blipEntity) then
            return
        end

        ClearVehicleBlip()
    end

    local blip = AddBlipForEntity(closestVehicle)
    SetBlipSprite(blip, 825)
    SetBlipColour(blip, 0)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(closestPlate or 'My Vehicle')
    EndTextCommandSetBlipName(blip)

    activeVehicleBlip = blip
    activeVehicleBlipEntity = closestVehicle
end

-- Blip update loop (every 3 seconds)
CreateThread(function()
    while true do
        Wait(3000)
        if cache.ped and DoesEntityExist(cache.ped) then
            UpdateVehicleBlips()
        end
    end
end)

-- Clean up blips when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ClearVehicleBlip()
    end
end)

return VehicleKeys
