local Config = lib.require('data.mining')

local pickaxeProp = nil
local isMining = false
local mineToken = 0

local function cleanupMining()
    if pickaxeProp and DoesEntityExist(pickaxeProp) then
        DeleteEntity(pickaxeProp)
    end
    pickaxeProp = nil

    local ped = cache.ped
    if ped and DoesEntityExist(ped) then
        ClearPedTasksImmediately(ped)
    end

    if lib.progressActive and lib.progressActive() then
        pcall(function()
            lib.cancelProgress()
        end)
    end
end

local function forceReleaseMine(token)
    if token and token ~= mineToken then return end
    isMining = false
    cleanupMining()
end

local function startMining(data)
    CreateThread(function()
        if isMining then return end
        if lib.progressActive and lib.progressActive() then
            lib.notify({ title = 'Busy', description = 'Finish your current action first.', type = 'error' })
            return
        end

        local ped = cache.ped

        local hasPickaxe = exports.ox_inventory:Search('count', 'pickaxe') > 0
        if not hasPickaxe then
            lib.notify({
                title = 'Mining',
                description = 'You need a pickaxe to mine here.',
                type = 'error'
            })
            return
        end

        isMining = true
        mineToken = mineToken + 1
        local token = mineToken
        local duration = Config.duration or 8000

        SetTimeout(duration + 4000, function()
            if isMining and mineToken == token then
                forceReleaseMine(token)
                lib.notify({
                    title = 'Mining Interrupted',
                    description = 'Mining timed out. You can try again.',
                    type = 'error',
                })
            end
        end)

        local ok, err = pcall(function()
            local entity = data and data.entity
            if entity and DoesEntityExist(entity) then
                TaskTurnPedToFaceEntity(ped, entity, 800)
                Wait(800)
            end

            lib.requestAnimDict(Config.animDict, 3000)
            lib.requestModel(Config.prop, 3000)

            local coords = GetEntityCoords(ped)
            pickaxeProp = CreateObject(joaat(Config.prop), coords.x, coords.y, coords.z, true, true, false)
            if pickaxeProp and DoesEntityExist(pickaxeProp) then
                AttachEntityToEntity(pickaxeProp, ped, GetPedBoneIndex(ped, 57005), 0.09, 0.03, -0.02, -78.0, 13.0, 28.0, true, true,
                    false, true, 1, true)
            end

            local finished = lib.progressBar({
                duration = duration,
                label = 'Mining...',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                    mouse = false
                },
                anim = {
                    dict = Config.animDict,
                    clip = Config.animName,
                    flag = 49,
                },
            })

            if mineToken ~= token then return end

            if finished then
                TriggerServerEvent('ox_inventory:payoutMining')
            else
                lib.notify({ title = 'Mining', description = 'Cancelled', type = 'warning' })
            end
        end)

        forceReleaseMine(token)

        if not ok then
            lib.notify({ title = 'Mining Failed', description = 'Something went wrong.', type = 'error' })
        end
    end)
end

CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do Wait(100) end

    for _ = 1, 50 do
        if pcall(function() return exports.ox_target.addModel end) then break end
        Wait(100)
    end

    pcall(function()
        exports.ox_target:addModel(Config.models, {
            {
                name = 'mine_rock',
                icon = 'fa-solid fa-hammer',
                label = 'Mine Rock',
                distance = 2.0,
                onSelect = startMining,
                canInteract = function()
                    if isMining or (lib.progressActive and lib.progressActive()) then
                        return false
                    end
                    local playerCoords = GetEntityCoords(cache.ped)
                    for _, zone in pairs(Config.zones) do
                        if #(playerCoords - zone.coords) <= zone.radius then
                            return true
                        end
                    end
                    return false
                end
            }
        })
    end)
end)

CreateThread(function()
    for _, zone in pairs(Config.zones) do
        if zone.blip then
            local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(blip, zone.blip.id)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, zone.blip.scale)
            SetBlipColour(blip, zone.blip.colour)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(zone.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        cleanupMining()
    end
end)
