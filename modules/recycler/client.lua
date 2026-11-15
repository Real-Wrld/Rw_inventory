if not lib then return end

local Config = lib.load('data.recycler')
if not Config then return end

local SpawnedRecyclers = {}
local RecyclerBlips = {}
local currentRecycler = nil
local isUiOpen = false
local isRecycling = false

local function sendRecyclerNUI(payload)
    SendNUIMessage({
        action = 'recyclerForward',
        data = payload,
    })
end

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelValid(hash) then return false end
    if HasModelLoaded(hash) then return true end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then return false end
        Wait(10)
    end

    return true
end

local function createBlip(location)
    if not Config.enableBlips or not location.blip then return end

    local coords = location.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.blip.sprite or 365)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.blip.scale or 0.7)
    SetBlipColour(blip, Config.blip.color or 25)
    SetBlipAsShortRange(blip, Config.blip.shortRange ~= false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.blip.name or 'Recycler')
    EndTextCommandSetBlipName(blip)

    return blip
end

local function spawnRecycler(location, index)
    local modelName = Config.model or 'sm_ex_shredder'
    if not loadModel(modelName) then return nil end

    local coords = location.coords
    local prop = CreateObject(joaat(modelName), coords.x, coords.y, coords.z, false, false, false)
    if not DoesEntityExist(prop) then return nil end

    SetEntityHeading(prop, coords.w or 0.0)
    PlaceObjectOnGroundProperly(prop)
    FreezeEntityPosition(prop, true)
    SetEntityCollision(prop, true, true)
    SetEntityAsMissionEntity(prop, true, true)

    exports.ox_target:addLocalEntity(prop, {
        {
            name = 'recycler_' .. (location.id or index),
            icon = Config.target.icon or 'fas fa-recycle',
            label = Config.target.label or 'Use Recycler',
            distance = Config.target.distance or 3.0,
            onSelect = function()
                TriggerEvent('ox_inventory:recycler:open', index)
            end,
        },
    })

    return prop
end

local function cleanupRecyclers()
    for id, handle in pairs(SpawnedRecyclers) do
        exports.ox_target:removeLocalEntity(handle)
        if DoesEntityExist(handle) then
            DeleteEntity(handle)
        end
    end

    for _, blip in pairs(RecyclerBlips) do
        RemoveBlip(blip)
    end

    SpawnedRecyclers = {}
    RecyclerBlips = {}
end

local function initializeRecyclers()
    if next(SpawnedRecyclers) or next(RecyclerBlips) then return end
    if not Config.locations then return end

    for index, location in ipairs(Config.locations) do
        if location.enabled ~= false then
            local blip = createBlip(location)
            if blip then RecyclerBlips[location.id or index] = blip end

            local handle = spawnRecycler(location, index)
            if handle then
                SpawnedRecyclers[location.id or index] = handle
            else
                local c = location.coords
                exports.ox_target:addSphereZone({
                    coords = vec3(c.x, c.y, c.z),
                    radius = Config.target.distance or 3.0,
                    debug = false,
                    options = {
                        {
                            name = 'recycler_zone_' .. index,
                            icon = Config.target.icon or 'fas fa-recycle',
                            label = Config.target.label or 'Use Recycler',
                            onSelect = function()
                                TriggerEvent('ox_inventory:recycler:open', index)
                            end,
                        },
                    },
                })
            end
        end
    end
end

local function closeRecyclerUI()
    if not isUiOpen then return end

    isUiOpen = false
    SetNuiFocus(false, false)
    sendRecyclerNUI({ action = 'closeRecycler' })
    SendNUIMessage({ action = 'recyclerBridge', bridgeAction = 'close' })
end

local function openRecyclerUI(index)
    if isUiOpen then return end
    TriggerServerEvent('ox_inventory:recycler:checkAvailability', index)
end

RegisterNetEvent('ox_inventory:recycler:availability', function(index, available, reason)
    if not available then
        if reason == 'busy' then
            lib.notify({ title = 'Recycler', description = 'Recycler is currently in use', type = 'error' })
        end
        return
    end

    currentRecycler = index
    isUiOpen = true

    TriggerServerEvent('ox_inventory:recycler:getRecipes')

    CreateThread(function()
        Wait(100)
        TriggerServerEvent('ox_inventory:recycler:getInventory')
        TriggerServerEvent('ox_inventory:recycler:getCollectedOutputs', index)
        TriggerServerEvent('ox_inventory:recycler:requestStateSync', index)
    end)

    SetNuiFocus(true, true)

    local imagePath = client.imagepath or 'nui://ox_inventory/web/images'
    if not imagePath:match('/$') then
        imagePath = imagePath .. '/'
    end

    SendNUIMessage({
        action = 'recyclerBridge',
        bridgeAction = 'open',
    })

    sendRecyclerNUI({
        action = 'openRecycler',
        recyclerIndex = index,
        config = {
            maxItems = Config.maxItemsPerRecycle,
            baseTime = Config.recycleTime,
            timePerItem = Config.recycleTimePerItem,
            maxTime = Config.maxRecycleTime,
            sounds = Config.recyclingSound,
            imagePath = imagePath,
        },
        translations = Config.translations or {},
    })
end)

RegisterNetEvent('ox_inventory:recycler:open', function(index)
    openRecyclerUI(index)
end)

RegisterNetEvent('ox_inventory:recycler:receiveRecipes', function(recipes)
    sendRecyclerNUI({ action = 'receiveRecipes', recipes = recipes })
end)

RegisterNetEvent('ox_inventory:recycler:receiveInventory', function(inventory)
    sendRecyclerNUI({ action = 'receiveInventory', inventory = inventory })
end)

RegisterNetEvent('ox_inventory:recycler:receiveCollectedOutputs', function(outputs)
    sendRecyclerNUI({ action = 'receiveCollectedOutputs', outputs = outputs })
end)

RegisterNetEvent('ox_inventory:recycler:startProcess', function(time)
    isRecycling = true
    sendRecyclerNUI({ action = 'startRecyclingProcess', time = time })
end)

RegisterNetEvent('ox_inventory:recycler:complete', function(success, items)
    isRecycling = false
    sendRecyclerNUI({ action = 'recyclingComplete', success = success, items = items or {} })
    TriggerServerEvent('ox_inventory:recycler:getInventory')
    if currentRecycler then
        TriggerServerEvent('ox_inventory:recycler:getCollectedOutputs', currentRecycler)
    end
end)

RegisterNetEvent('ox_inventory:recycler:queueUpdated', function(recyclerIndex, queue)
    if isUiOpen then
        sendRecyclerNUI({ action = 'updateQueue', queue = queue })
    end
end)

RegisterNetEvent('ox_inventory:recycler:updateCollectedOutputs', function(recyclerIndex, outputs)
    if isUiOpen and currentRecycler == recyclerIndex then
        sendRecyclerNUI({ action = 'updateCollectedOutputs', recyclerIndex = recyclerIndex, outputs = outputs })
    end
end)

RegisterNetEvent('ox_inventory:recycler:progress', function(data)
    if isUiOpen and currentRecycler == data.recyclerIndex then
        sendRecyclerNUI({
            action = 'recyclingProgress',
            progress = data.progress,
            timeLeft = data.timeLeft,
        })
    end
end)

RegisterNetEvent('ox_inventory:recycler:fullStateSync', function(state)
    if isUiOpen then
        sendRecyclerNUI({ action = 'fullStateSync', state = state })
    end
end)

RegisterNetEvent('ox_inventory:recycler:recyclerCancelled', function(recyclerIndex)
    isRecycling = false
    sendRecyclerNUI({ action = 'recyclerCancelled', recyclerIndex = recyclerIndex })
end)

RegisterNUICallback('closeUI', function(_, cb)
    closeRecyclerUI()
    cb('ok')
end)

RegisterNUICallback('startRecycling', function(_, cb)
    if currentRecycler then
        TriggerServerEvent('ox_inventory:recycler:start', currentRecycler)
    end
    cb('ok')
end)

RegisterNUICallback('cancelRecycling', function(_, cb)
    if currentRecycler then
        isRecycling = false
        TriggerServerEvent('ox_inventory:recycler:cancel', currentRecycler)
    end
    cb('ok')
end)

RegisterNUICallback('collectItem', function(data, cb)
    if currentRecycler and data.item and data.count then
        TriggerServerEvent('ox_inventory:recycler:collectItem', currentRecycler, data.item, data.count)
    end
    cb('ok')
end)

RegisterNUICallback('collectAllItems', function(_, cb)
    if currentRecycler then
        TriggerServerEvent('ox_inventory:recycler:collectAll', currentRecycler)
    end
    cb('ok')
end)

RegisterNUICallback('getCollectedOutputs', function(_, cb)
    if currentRecycler then
        TriggerServerEvent('ox_inventory:recycler:getCollectedOutputs', currentRecycler)
    end
    cb('ok')
end)

RegisterNUICallback('addItemToQueue', function(data, cb)
    if currentRecycler and data.item and data.count then
        TriggerServerEvent('ox_inventory:recycler:addToQueue', currentRecycler, data.item, data.count)
    end
    cb('ok')
end)

RegisterNUICallback('removeItemFromQueue', function(data, cb)
    if currentRecycler and data.index ~= nil then
        TriggerServerEvent('ox_inventory:recycler:removeFromQueue', currentRecycler, data.index)
    end
    cb('ok')
end)

RegisterNUICallback('clearQueue', function(_, cb)
    if currentRecycler then
        TriggerServerEvent('ox_inventory:recycler:clearQueue', currentRecycler)
    end
    cb('ok')
end)

RegisterNUICallback('getInventory', function(_, cb)
    TriggerServerEvent('ox_inventory:recycler:getInventory')
    cb('ok')
end)

RegisterNUICallback('requestStateSync', function(data, cb)
    TriggerServerEvent('ox_inventory:recycler:requestStateSync', data and data.recyclerIndex or currentRecycler)
    cb('ok')
end)

CreateThread(function()
    while true do
        local sleep = 1000

        if Config.locations and not Config.useTarget then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            for index, location in ipairs(Config.locations) do
                if location.enabled ~= false and location.marker ~= false then
                    local dist = #(coords - vec3(location.coords.x, location.coords.y, location.coords.z))
                    if dist < 10.0 then
                        sleep = 0
                        local marker = Config.marker or {}
                        local color = marker.color or { r = 0, g = 255, b = 0, a = 100 }
                        DrawMarker(
                            marker.type or 1,
                            location.coords.x, location.coords.y, location.coords.z - 0.95,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            1.0, 1.0, 0.5,
                            color.r or 0, color.g or 255, color.b or 0, color.a or 100,
                            marker.bobUpAndDown or false, marker.faceCamera or false, 2, marker.rotate or false,
                            nil, nil, false
                        )

                        if dist < 2.0 and not isUiOpen and IsControlJustPressed(0, 38) then
                            openRecyclerUI(index)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(1000)
        initializeRecyclers()
    end
end)

AddEventHandler('ox_inventory:playerLoaded', function()
    Wait(2000)
    initializeRecyclers()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        cleanupRecyclers()
    end
end)

exports('OpenRecycler', openRecyclerUI)
