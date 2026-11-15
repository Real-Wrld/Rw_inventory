-- Store Theft Client Module
-- Handles ox_target zones, theft interactions, and police dispatch

if not lib then return end


local TheftConfig = lib.load('data.theft')

-- Debug: Check if config loaded
if not TheftConfig then
    return
end


local isStealing = false
local lastGlobalTheft = 0

-- Helper function to draw 3D text
local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)

    local factor = string.len(text) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 100)
    ClearDrawOrigin()
end

-- Perform the theft action
local function PerformTheft(storeType, storeName, zoneLabel, coords, zoneLootChances)
    if isStealing then
        lib.notify({
            title = 'Please Wait',
            description = 'Already in progress...',
            type = 'error',
            duration = 2000,
        })
        return
    end

    isStealing = true

    -- Create unique location hash
    local locationHash = string.format('%s_%s_%s', storeType, storeName, tostring(coords))

    -- Get ped and preload animation
    local ped = PlayerPedId()
    local animDict = TheftConfig.settings.animation.dict
    local animClip = TheftConfig.settings.animation.anim

    -- Request and wait for animation dict to load
    lib.requestAnimDict(animDict)

    -- Show progress bar and play animation
    local success = lib.progressBar({
        duration = TheftConfig.settings.duration,
        label = TheftConfig.settings.messages.stealing,
        useWhileDead = false,
        canCancel = false, -- Prevent cancellation
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = animDict,
            clip = animClip,
            flag = 49, -- Upper body animation
        },
    })

    -- Clear animation after progress bar
    ClearPedTasks(ped)

    -- Get street name for police alert
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash) or 'Unknown Location'

    if success then
        -- Call server to process theft
        local result = lib.callback.await('ox_inventory:storeTheft', 5000, storeType, locationHash, storeName, coords,
            streetName, zoneLootChances)

        if result then
            if result.success then
                lastGlobalTheft = GetGameTimer()

                if result.found then
                    -- ONLY show loot window UI for blueprints
                    if result.isBlueprint then
                        SendNUIMessage({
                            action = 'showScavengeLoot',
                            data = {
                                item = result.item,
                                label = result.label or result.item,
                                count = result.count or 1,
                                isBlueprint = result.isBlueprint or false,
                                xpGained = result.xpGained or 0,
                            }
                        })
                        PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                    else
                        -- Standard notification for regular items
                        lib.notify({
                            title = 'Item Found',
                            description = string.format('Found %sx %s', result.count, result.label or result.item),
                            type = 'success',
                            duration = 3000,
                            icon = 'hand'
                        })
                        PlaySoundFrontend(-1, 'ROBBERY_MONEY_TOTAL', 'HUD_FRONTEND_CUSTOM_SOUNDSET', true)
                    end
                else
                    -- Show "Nothing Found" loot window UI instead of notification
                    SendNUIMessage({
                        action = 'showScavengeLoot',
                        data = {
                            nothingFound = true,
                            message = result.message or 'Nothing useful here...',
                        }
                    })
                    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                end
                -- Police alerts are silent for the thief — dispatch systems get the ping server-side.
            else
                if result.error == 'cooldown' then
                    lib.notify({
                        title = 'Recently Searched',
                        description = string.format('%s (%ds remaining)', result.message, result.remaining),
                        type = 'error',
                        duration = 3000,
                    })
                elseif result.error == 'inventory_full' then
                    lib.notify({
                        title = 'Inventory Full',
                        description = result.message,
                        type = 'error',
                        duration = 3000,
                    })
                elseif result.error == 'config_error' or result.error == 'invalid_store' then
                    lib.notify({
                        title = 'System Error',
                        description = result.message or 'Server configuration error',
                        type = 'error',
                        duration = 3000,
                    })
                else
                    -- Generic error
                    lib.notify({
                        title = 'Error',
                        description = result.message or 'Something went wrong',
                        type = 'error',
                        duration = 3000,
                    })
                end
            end
        else
            -- Server returned nil - show error
            lib.notify({
                title = 'Error',
                description = 'Failed to search this location (no server response)',
                type = 'error',
                duration = 3000,
            })
        end
    else
        lib.notify({
            title = 'Interrupted',
            description = 'Search was interrupted',
            type = 'error',
            duration = 2000,
        })
    end

    isStealing = false
end


-- Proximity-based ox_target zones (avoids registering ~87 permanent zones citywide)
local activeTheftZones = {} -- [zoneName] = zoneId
local STORE_ACTIVATION_DIST = 45.0

local function removeTheftZone(zoneName)
    local zoneId = activeTheftZones[zoneName]
    if not zoneId then return end
    pcall(function()
        exports.ox_target:removeZone(zoneId)
    end)
    activeTheftZones[zoneName] = nil
end

local function ensureTheftZone(storeType, storeIndex, store, zoneIndex, zone)
    local zoneName = string.format('theft_%s_%d_%d', storeType, storeIndex, zoneIndex)
    if activeTheftZones[zoneName] then return end

    local zoneCoords = zone.coords or (store.center + zone.offset)
    local ok, zoneId = pcall(function()
        return exports.ox_target:addBoxZone({
            name = zoneName,
            coords = vec3(zoneCoords.x, zoneCoords.y, zoneCoords.z),
            size = zone.size,
            rotation = zone.heading,
            debug = false,
            options = {
                {
                    name = zoneName,
                    icon = zone.icon,
                    label = zone.label,
                    onSelect = function()
                        PerformTheft(storeType, store.name, zone.label, zoneCoords, zone.lootChances)
                    end,
                    distance = 2.5,
                },
            },
        })
    end)

    if ok and zoneId then
        activeTheftZones[zoneName] = zoneId
    end
end

local function syncTheftZonesNearPlayer()
    if GetResourceState('ox_target') ~= 'started' then return end

    local ped = cache.ped or PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local wanted = {}

    local function processStoreType(storeType, cfg)
        if not cfg or not cfg.locations or not cfg.zones then return end
        for storeIndex, store in ipairs(cfg.locations) do
            local dist = #(playerCoords - store.center)
            if dist <= STORE_ACTIVATION_DIST then
                for zoneIndex, zone in ipairs(cfg.zones) do
                    local zoneName = string.format('theft_%s_%d_%d', storeType, storeIndex, zoneIndex)
                    wanted[zoneName] = true
                    ensureTheftZone(storeType, storeIndex, store, zoneIndex, zone)
                end
            end
        end
    end

    processStoreType('general_store', TheftConfig.general_store)
    processStoreType('digital_den', TheftConfig.digital_den)
    processStoreType('xero_gas', TheftConfig.xero_gas)
    processStoreType('supermarket', TheftConfig.supermarket)

    for zoneName in pairs(activeTheftZones) do
        if not wanted[zoneName] then
            removeTheftZone(zoneName)
        end
    end
end

CreateThread(function()
    Wait(1500)
    while true do
        syncTheftZonesNearPlayer()
        Wait(2000)
    end
end)

-- Client event for police alert (fallback if no dispatch system like cd_dispatch)
RegisterNetEvent('ox_inventory:policeAlert', function(data)
    -- Check if player is police and show alert
    local playerJob = nil

    if GetResourceState('qbx_core') == 'started' then
        local player = exports.qbx_core:GetPlayerData()
        if player then playerJob = player.job and player.job.name end
    elseif GetResourceState('qb-core') == 'started' then
        local player = exports['qb-core']:GetPlayerData()
        if player then playerJob = player.job and player.job.name end
    end

    if playerJob == 'police' or playerJob == 'lspd' or playerJob == 'bcso' or playerJob == 'sasp' then
        lib.notify({
            title = '🚨 Dispatch Alert',
            description = data.message .. ' at ' .. data.storeName,
            type = 'error',
            duration = 8000,
        })

        -- Add blip with route
        local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(blip, 431)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 1.0)
        SetBlipRoute(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(data.message)
        EndTextCommandSetBlipName(blip)

        -- Remove blip after 60 seconds
        SetTimeout(60000, function()
            RemoveBlip(blip)
        end)
    end
end)

return {}
