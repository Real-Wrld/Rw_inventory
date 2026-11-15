-- Storage System Client Module
-- Handles stash prop placement with object_gizmo controls

local placementMode = false
local currentStash = nil
local previewProp = nil
local gizmoActive = false

-- Available stash prop models (3 tiers using GTA safe models)
local STASH_PROPS = {
    small = {
        model = "p_v_43_safe_s",
        label = "Small Safe",
        slots = 50,
        maxWeight = 100000,
        price = 50000
    },
    medium = {
        model = "prop_ld_int_safe_01",
        label = "Medium Safe",
        slots = 75,
        maxWeight = 150000,
        price = 100000
    },
    large = {
        model = "prop_ld_int_safe_01",
        label = "Large Safe",
        slots = 100,
        maxWeight = 200000,
        price = 150000
    },
    upgraded = {
        model = "sf_prop_v_43_safe_s_bk_01a",
        label = "Upgraded Safe",
        slots = 200,
        maxWeight = 500000,
        price = 250000
    }
}

-- Gizmo state
local gizmoState = {
    mode = "move", -- move, rotate, scale
    axis = "all",  -- x, y, z, all
    step = 0.1,    -- movement step
    rotStep = 5.0  -- rotation step in degrees
}

-- Load prop model
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

-- Create preview prop for placement
local function CreatePreviewProp(propType)
    local config = STASH_PROPS[propType]
    if not config then return nil end

    local modelHash = LoadModel(config.model)
    if not modelHash then return nil end

    local ped = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Spawn in front of player
    local spawnPos = coords + vector3(
        math.sin(math.rad(-heading)) * 2.0,
        math.cos(math.rad(-heading)) * 2.0,
        0.0
    )

    local prop = CreateObject(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, false, true, false)

    SetEntityHeading(prop, heading)
    SetEntityAlpha(prop, 200, false) -- Slightly transparent
    SetEntityCollision(prop, false, false)
    FreezeEntityPosition(prop, true)

    SetModelAsNoLongerNeeded(modelHash)

    return prop
end

-- Draw gizmo instructions on screen
local function DrawGizmoInstructions()
    local instructions = {
        "~b~[MOUSE]~w~ Move/Rotate",
        "~b~[SCROLL]~w~ Distance",
        "~b~[E]~w~ Toggle Mode: " .. gizmoState.mode:upper(),
        "~b~[Q]~w~ Toggle Axis: " .. gizmoState.axis:upper(),
        "~b~[ENTER]~w~ Confirm Placement",
        "~b~[BACKSPACE]~w~ Cancel"
    }

    local y = 0.7
    for _, text in ipairs(instructions) do
        SetTextFont(4)
        SetTextScale(0.35, 0.35)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(0.01, y)
        y = y + 0.025
    end
end

-- Handle gizmo input
local function HandleGizmoInput()
    if not previewProp or not DoesEntityExist(previewProp) then return end

    local coords = GetEntityCoords(previewProp)
    local heading = GetEntityHeading(previewProp)

    -- Toggle mode with E
    if IsControlJustPressed(0, 38) then -- E
        if gizmoState.mode == "move" then
            gizmoState.mode = "rotate"
        else
            gizmoState.mode = "move"
        end
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end

    -- Toggle axis with Q
    if IsControlJustPressed(0, 44) then -- Q
        local axes = { "all", "x", "y", "z" }
        local currentIdx = 1
        for i, v in ipairs(axes) do
            if v == gizmoState.axis then
                currentIdx = i
                break
            end
        end
        gizmoState.axis = axes[(currentIdx % #axes) + 1]
        PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end

    -- Scroll for distance
    if IsControlPressed(0, 241) then -- Scroll up
        local forward = GetEntityForwardVector(cache.ped or PlayerPedId())
        SetEntityCoords(previewProp, coords.x + forward.x * 0.1, coords.y + forward.y * 0.1, coords.z)
    end
    if IsControlPressed(0, 242) then -- Scroll down
        local forward = GetEntityForwardVector(cache.ped or PlayerPedId())
        SetEntityCoords(previewProp, coords.x - forward.x * 0.1, coords.y - forward.y * 0.1, coords.z)
    end

    -- WASD for move/rotate based on mode
    if gizmoState.mode == "move" then
        local step = gizmoState.step
        if IsControlPressed(0, 32) then -- W - Forward
            SetEntityCoords(previewProp, coords.x, coords.y + step, coords.z)
        end
        if IsControlPressed(0, 33) then -- S - Back
            SetEntityCoords(previewProp, coords.x, coords.y - step, coords.z)
        end
        if IsControlPressed(0, 34) then -- A - Left
            SetEntityCoords(previewProp, coords.x - step, coords.y, coords.z)
        end
        if IsControlPressed(0, 35) then -- D - Right
            SetEntityCoords(previewProp, coords.x + step, coords.y, coords.z)
        end
        if IsControlPressed(0, 44) then -- Q - Up (when in move mode we override)
            -- Already handled above
        end
        if IsControlPressed(0, 21) then     -- Shift + move for Z axis
            if IsControlPressed(0, 32) then -- W - Up
                SetEntityCoords(previewProp, coords.x, coords.y, coords.z + step)
            end
            if IsControlPressed(0, 33) then -- S - Down
                SetEntityCoords(previewProp, coords.x, coords.y, coords.z - step)
            end
        end
    else                                -- Rotate mode
        local rotStep = gizmoState.rotStep
        if IsControlPressed(0, 34) then -- A - Rotate left
            SetEntityHeading(previewProp, heading - rotStep)
        end
        if IsControlPressed(0, 35) then -- D - Rotate right
            SetEntityHeading(previewProp, heading + rotStep)
        end
    end

    -- Confirm placement with Enter
    if IsControlJustPressed(0, 191) then -- Enter
        return "confirm"
    end

    -- Cancel with Backspace
    if IsControlJustPressed(0, 194) then -- Backspace
        return "cancel"
    end

    return nil
end

-- Start stash placement mode using object_gizmo
local function StartPlacement(stashType, stashId)
    if placementMode then return end

    local config = STASH_PROPS[stashType]
    if not config then
        lib.notify({ title = "Storage", description = "Invalid stash type", type = "error" })
        return
    end

    placementMode = true
    gizmoActive = true

    -- Freeze player movement during placement
    local ped = cache.ped or PlayerPedId()
    FreezeEntityPosition(ped, true)

    -- Create preview prop
    previewProp = CreatePreviewProp(stashType)
    if not previewProp then
        lib.notify({ title = "Storage", description = "Failed to load model", type = "error" })
        placementMode = false
        gizmoActive = false
        return
    end

    currentStash = {
        type = stashType,
        id = stashId or lib.uuid(),
        config = config
    }

    -- Check if object_gizmo is available
    if GetResourceState('object_gizmo') == 'started' then
        -- Use object_gizmo for placement
        lib.notify({
            title = "Storage",
            description = "Use gizmo to position safe, then press ENTER to confirm",
            type =
            "inform",
            duration = 5000
        })

        -- Make prop visible and enable gizmo
        SetEntityAlpha(previewProp, 255, false)
        SetEntityCollision(previewProp, false, false)
        FreezeEntityPosition(previewProp, false)

        -- Start object_gizmo on the prop
        exports['object_gizmo']:useGizmo(previewProp)

        -- Wait for user to confirm placement
        CreateThread(function()
            while placementMode and gizmoActive do
                -- Draw instructions
                SetTextFont(4)
                SetTextScale(0.4, 0.4)
                SetTextColour(255, 255, 255, 255)
                SetTextOutline()
                SetTextEntry("STRING")
                AddTextComponentString("~b~[ENTER]~w~ Confirm | ~b~[BACKSPACE]~w~ Cancel")
                DrawText(0.5, 0.9)

                -- Confirm with Enter
                if IsControlJustPressed(0, 191) then
                    -- Stop gizmo
                    exports['object_gizmo']:exitGizmo()

                    -- Finalize placement
                    local finalCoords = GetEntityCoords(previewProp)
                    local finalHeading = GetEntityHeading(previewProp)
                    local finalRotation = GetEntityRotation(previewProp, 2)

                    -- Make prop solid
                    SetEntityCollision(previewProp, true, true)
                    FreezeEntityPosition(previewProp, true)

                    -- Register with ox_target
                    if GetResourceState('ox_target') == 'started' then
                        exports.ox_target:addLocalEntity(previewProp, {
                            {
                                name = 'open_stash_' .. currentStash.id,
                                icon = 'fas fa-lock-open',
                                label = 'Open ' .. config.label,
                                onSelect = function()
                                    TriggerServerEvent('ox_inventory:openStash', currentStash.id)
                                end
                            }
                        })
                    end

                    -- Save to server with rotation
                    TriggerServerEvent('ox_inventory:saveStash', {
                        id = currentStash.id,
                        type = stashType,
                        coords = { x = finalCoords.x, y = finalCoords.y, z = finalCoords.z },
                        heading = finalHeading,
                        rotation = { x = finalRotation.x, y = finalRotation.y, z = finalRotation.z },
                        slots = config.slots,
                        maxWeight = config.maxWeight,
                        model = config.model
                    })

                    lib.notify({
                        title = "Storage",
                        description = config.label .. " placed successfully!",
                        type =
                        "success"
                    })

                    previewProp = nil
                    placementMode = false
                    gizmoActive = false
                    currentStash = nil
                    -- Unfreeze player
                    FreezeEntityPosition(ped, false)
                    break
                end

                -- Cancel with Backspace
                if IsControlJustPressed(0, 194) then
                    exports['object_gizmo']:exitGizmo()

                    if previewProp and DoesEntityExist(previewProp) then
                        DeleteEntity(previewProp)
                        previewProp = nil
                    end

                    lib.notify({ title = "Storage", description = "Placement cancelled", type = "inform" })

                    placementMode = false
                    gizmoActive = false
                    currentStash = nil
                    -- Unfreeze player
                    FreezeEntityPosition(ped, false)
                    break
                end

                Wait(0)
            end
        end)
    else
        -- Fallback to built-in gizmo if object_gizmo not available
        CreateThread(function()
            while placementMode and gizmoActive do
                DrawGizmoInstructions()

                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 140, true)

                local result = HandleGizmoInput()

                if result == "confirm" then
                    local finalCoords = GetEntityCoords(previewProp)
                    local finalHeading = GetEntityHeading(previewProp)

                    SetEntityAlpha(previewProp, 255, false)
                    SetEntityCollision(previewProp, true, true)

                    if GetResourceState('ox_target') == 'started' then
                        exports.ox_target:addLocalEntity(previewProp, {
                            {
                                name = 'open_stash_' .. currentStash.id,
                                icon = 'fas fa-lock-open',
                                label = 'Open ' .. config.label,
                                onSelect = function()
                                    TriggerServerEvent('ox_inventory:openStash', currentStash.id)
                                end
                            }
                        })
                    end

                    TriggerServerEvent('ox_inventory:saveStash', {
                        id = currentStash.id,
                        type = stashType,
                        coords = { x = finalCoords.x, y = finalCoords.y, z = finalCoords.z },
                        heading = finalHeading,
                        slots = config.slots,
                        maxWeight = config.maxWeight,
                        model = config.model
                    })

                    lib.notify({ title = "Storage", description = config.label .. " placed!", type = "success" })

                    previewProp = nil
                    placementMode = false
                    gizmoActive = false
                    currentStash = nil
                    -- Unfreeze player
                    FreezeEntityPosition(ped, false)
                elseif result == "cancel" then
                    if previewProp and DoesEntityExist(previewProp) then
                        DeleteEntity(previewProp)
                        previewProp = nil
                    end

                    lib.notify({ title = "Storage", description = "Placement cancelled", type = "inform" })

                    placementMode = false
                    gizmoActive = false
                    currentStash = nil
                    -- Unfreeze player
                    FreezeEntityPosition(ped, false)
                end

                Wait(0)
            end
        end)
    end
end

-- Cancel current placement
local function CancelPlacement()
    if previewProp and DoesEntityExist(previewProp) then
        DeleteEntity(previewProp)
        previewProp = nil
    end
    placementMode = false
    gizmoActive = false
    currentStash = nil
    -- Unfreeze player in case placement was active
    local ped = cache.ped or PlayerPedId()
    FreezeEntityPosition(ped, false)
end

-- Spawned stash entities cache
local spawnedStashes = {}

-- Load existing stashes from server
RegisterNetEvent('ox_inventory:loadStashes', function(stashes)
    local playerIdentifier = lib.callback.await('ox_inventory:getPlayerIdentifier', false)

    for _, stash in ipairs(stashes) do
        -- Skip if already spawned
        if spawnedStashes[stash.id] then
            goto continue
        end

        local config = STASH_PROPS[stash.type]
        local modelName = stash.model or (config and config.model) or 'p_v_43_safe_s'
        local modelHash = LoadModel(modelName)

        if modelHash then
            local prop = CreateObject(modelHash, stash.coords.x, stash.coords.y, stash.coords.z, false, true, false)
            SetEntityHeading(prop, stash.heading or 0)

            -- Apply rotation if available
            if stash.rotation then
                SetEntityRotation(prop, stash.rotation.x or 0, stash.rotation.y or 0, stash.rotation.z or 0, 2, true)
            end

            FreezeEntityPosition(prop, true)

            -- Store reference
            spawnedStashes[stash.id] = {
                entity = prop,
                data = stash
            }

            -- Check if this is the player's safe
            local isOwner = stash.owner == playerIdentifier

            -- Register with ox_target
            if GetResourceState('ox_target') == 'started' then
                local targetOptions = {}

                -- Owner options
                if isOwner then
                    targetOptions[#targetOptions + 1] = {
                        name = 'open_stash_' .. stash.id,
                        icon = 'fas fa-lock-open',
                        label = 'Open Safe',
                        onSelect = function()
                            TriggerServerEvent('ox_inventory:openStash', stash.id)
                        end
                    }
                    targetOptions[#targetOptions + 1] = {
                        name = 'settings_stash_' .. stash.id,
                        icon = 'fas fa-cog',
                        label = 'Safe Settings',
                        iconColor = '#9a48d0', -- Purple to match UI theme
                        onSelect = function()
                            -- Get security info and send to UI
                            local securityData = lib.callback.await('ox_inventory:getStashSecurity', false, stash.id)
                            if securityData then
                                SendNUIMessage({
                                    action = 'openStashSettings',
                                    data = securityData
                                })
                            end
                        end
                    }
                    targetOptions[#targetOptions + 1] = {
                        name = 'pickup_stash_' .. stash.id,
                        icon = 'fas fa-dolly',
                        label = 'Pick Up Safe',
                        onSelect = function()
                            -- TODO: Implement pickup logic
                            lib.notify({ title = 'Storage', description = 'Feature coming soon', type = 'inform' })
                        end
                    }
                else
                    -- Non-owner options (robbery)
                    targetOptions[#targetOptions + 1] = {
                        name = 'rob_stash_' .. stash.id,
                        icon = 'fas fa-user-secret',
                        label = 'Rob Safe',
                        onSelect = function()
                            TriggerServerEvent('ox_inventory:robStash', stash.id)
                        end
                    }
                    targetOptions[#targetOptions + 1] = {
                        name = 'inspect_stash_' .. stash.id,
                        icon = 'fas fa-eye',
                        label = 'Inspect Safe',
                        onSelect = function()
                            lib.notify({
                                title = 'Safe Inspection',
                                description = 'This safe belongs to someone else. You could try robbing it...',
                                type = 'inform',
                                duration = 3000
                            })
                        end
                    }
                end

                exports.ox_target:addLocalEntity(prop, targetOptions)
            end

            SetModelAsNoLongerNeeded(modelHash)
        end

        ::continue::
    end
end)

-- Remove stash event
RegisterNetEvent('ox_inventory:removeStash', function(stashId)
    local stashData = spawnedStashes[stashId]
    if stashData and stashData.entity and DoesEntityExist(stashData.entity) then
        -- Remove ox_target
        if GetResourceState('ox_target') == 'started' then
            exports.ox_target:removeLocalEntity(stashData.entity)
        end
        DeleteEntity(stashData.entity)
    end
    spawnedStashes[stashId] = nil
end)

-- Request stashes on spawn
AddEventHandler('playerSpawned', function()
    Wait(2000)
    TriggerServerEvent('ox_inventory:requestStashes')
end)

-- Also request on resource start
CreateThread(function()
    Wait(3000)
    TriggerServerEvent('ox_inventory:requestStashes')
end)

-- Commands
RegisterCommand('placestash', function(source, args)
    local stashType = args[1] or 'small'
    StartPlacement(stashType)
end, false)

-- NUI Callbacks
RegisterNUICallback('startStashPlacement', function(data, cb)
    StartPlacement(data.type, data.id)
    cb('ok')
end)

RegisterNUICallback('cancelStashPlacement', function(data, cb)
    CancelPlacement()
    cb('ok')
end)

-- Purchase storage
RegisterNUICallback('purchaseStorage', function(data, cb)
    local config = STASH_PROPS[data.type]
    if not config then
        cb({ error = 'Invalid type' })
        return
    end

    -- Trigger server event which handles both money deduction and giving the item
    TriggerServerEvent('ox_inventory:purchaseStorage', {
        type = data.type,
        slots = config.slots,
        price = config.price,
        model = config.model
    })

    cb('ok')
end)

-- Safe robbery minigame
RegisterNetEvent('ox_inventory:startSafeRobbery', function(data)
    -- Difficulty settings based on safe type
    local difficulties = {
        small = { inputs = { 'w', 'a', 's', 'd' }, duration = 3000 },
        medium = { inputs = { 'w', 'a', 's', 'd', 'w', 'a' }, duration = 2500 },
        large = { inputs = { 'w', 'a', 's', 'd', 'w', 'a', 's', 'd' }, duration = 2000 }
    }

    local diff = difficulties[data.difficulty] or difficulties.small

    lib.notify({
        title = '🔓 Cracking Safe...',
        description = 'Follow the button prompts!',
        type = 'inform',
        duration = 2000
    })

    Wait(2000)

    -- Use ox_lib skillcheck
    local success = lib.skillCheck(diff.inputs, { 'easy', 'easy', 'medium', 'medium', 'hard', 'hard', 'hard', 'hard' })

    if success then
        -- Show progress bar while "opening" the safe
        local opened = lib.progressBar({
            duration = 5000,
            label = 'Opening safe...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
            },
            anim = {
                dict = 'anim@heists@ornate_bank@grab_cash',
                clip = 'grab'
            }
        })

        if opened then
            lib.callback.await('ox_inventory:completeRobbery', false, data.stashId, true)
        else
            lib.notify({ title = 'Robbery', description = 'You were interrupted!', type = 'error' })
        end
    else
        lib.callback.await('ox_inventory:completeRobbery', false, data.stashId, false)
        lib.notify({ title = 'Robbery Failed', description = 'You failed to crack the safe!', type = 'error' })
    end
end)

-- ============================================
-- STORAGE SECURITY NUI CALLBACKS
-- ============================================

-- Pending stash open after PIN verification
local pendingStashOpen = nil

-- Request stash security info and show PIN modal if needed
local function OpenSecuredStash(stashId, stashLabel)
    local securityData = lib.callback.await('ox_inventory:getStashSecurity', false, stashId)

    if not securityData then
        -- No security, open normally
        return true
    end

    if securityData.hasPin then
        -- Store pending open info
        pendingStashOpen = {
            stashId = stashId,
            stashLabel = stashLabel
        }

        -- Request PIN from UI
        SendNUIMessage({
            action = 'requestStashPin',
            data = {
                stashId = stashId,
                stashLabel = stashLabel or 'Stash',
                attempts = securityData.failedAttempts or 0,
                maxAttempts = securityData.maxAttempts or 3
            }
        })

        return false -- Don't open yet, wait for PIN
    end

    return true -- Can open directly
end

-- NUI Callback: Verify PIN
RegisterNUICallback('verifyStashPin', function(data, cb)
    if not data.stashId or not data.pin then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    local result = lib.callback.await('ox_inventory:verifyStashPin', false, data.stashId, data.pin)

    if result.success then
        -- PIN verified, open the stash
        SendNUIMessage({
            action = 'pinVerifyResult',
            data = { success = true }
        })

        -- Trigger stash open if we have pending data
        if pendingStashOpen and pendingStashOpen.stashId == data.stashId then
            TriggerServerEvent('ox_inventory:openSecuredStash', data.stashId)
            pendingStashOpen = nil
        end
    else
        -- PIN verification failed
        SendNUIMessage({
            action = 'pinVerifyResult',
            data = {
                success = false,
                locked = result.locked,
                lockoutTime = result.lockoutTime,
                attempts = result.attempts
            }
        })
    end

    cb(result)
end)

-- NUI Callback: Set/Change PIN
RegisterNUICallback('setStashPin', function(data, cb)
    if not data.stashId or not data.pin then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('ox_inventory:setStashPin', data.stashId, data.pin)

    -- Result will come via server event
    cb('ok')
end)

-- NUI Callback: Remove PIN
RegisterNUICallback('removeStashPin', function(data, cb)
    if not data.stashId then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('ox_inventory:removeStashPin', data.stashId)
    cb('ok')
end)

-- NUI Callback: Cancel PIN entry
RegisterNUICallback('cancelPinEntry', function(data, cb)
    pendingStashOpen = nil
    cb('ok')
end)

-- NUI Callback: Add shared access
RegisterNUICallback('addSharedAccess', function(data, cb)
    if not data.stashId or not data.targetId then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('ox_inventory:addSharedAccess', data.stashId, data.targetId)
    cb('ok')
end)

-- NUI Callback: Remove shared access
RegisterNUICallback('removeSharedAccess', function(data, cb)
    if not data.stashId or not data.targetId then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('ox_inventory:removeSharedAccess', data.stashId, data.targetId)
    cb('ok')
end)

-- Server events for PIN results
RegisterNetEvent('ox_inventory:pinSetResult', function(success)
    SendNUIMessage({
        action = 'pinSetResult',
        data = { success = success }
    })

    if success then
        lib.notify({
            title = 'Stash Security',
            description = 'PIN has been set successfully',
            type = 'success'
        })
    else
        lib.notify({
            title = 'Stash Security',
            description = 'Failed to set PIN',
            type = 'error'
        })
    end
end)

RegisterNetEvent('ox_inventory:pinRemoveResult', function(success)
    SendNUIMessage({
        action = 'pinRemoveResult',
        data = { success = success }
    })

    if success then
        lib.notify({
            title = 'Stash Security',
            description = 'PIN has been removed',
            type = 'success'
        })
    end
end)

RegisterNetEvent('ox_inventory:sharedAccessResult', function(success, action, userName)
    if action == 'add' then
        if success then
            SendNUIMessage({
                action = 'sharedUserAdded',
                data = {
                    id = tostring(success.id or ''),
                    name = success.name or userName or 'Player',
                    addedAt = os.date('%Y-%m-%d')
                }
            })
            lib.notify({
                title = 'Shared Access',
                description = 'Player added successfully',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Shared Access',
                description = 'Failed to add player',
                type = 'error'
            })
        end
    elseif action == 'remove' then
        if success then
            SendNUIMessage({
                action = 'sharedUserRemoved',
                data = { userId = tostring(success) }
            })
            lib.notify({
                title = 'Shared Access',
                description = 'Player access revoked',
                type = 'success'
            })
        end
    end
end)

-- Open stash settings modal
RegisterNUICallback('openStashSettings', function(data, cb)
    if not data.stashId then
        cb({ success = false })
        return
    end

    local securityData = lib.callback.await('ox_inventory:getStashSecurity', false, data.stashId)

    if securityData then
        SendNUIMessage({
            action = 'openStashSettings',
            data = securityData
        })
    end

    cb('ok')
end)

-- NUI Callback: Move Stash (using object gizmo)
RegisterNUICallback('moveStash', function(data, cb)
    if not data.stashId then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    local stashData = spawnedStashes[data.stashId]
    if not stashData or not stashData.entity or not DoesEntityExist(stashData.entity) then
        lib.notify({
            title = 'Stash',
            description = 'Cannot find stash entity',
            type = 'error'
        })
        cb({ success = false })
        return
    end

    -- Close inventory if open
    TriggerEvent('ox_inventory:closeInventory')

    -- Get current position and rotation
    local entity = stashData.entity
    local currentPos = GetEntityCoords(entity)
    local currentRot = GetEntityRotation(entity, 2)

    lib.notify({
        title = 'Move Stash',
        description = 'Use WASD to move, Q/E to rotate, ENTER to confirm, ESC to cancel',
        type = 'inform',
        duration = 5000
    })

    -- Simple movement controls
    local moving = true
    local newPos = vector3(currentPos.x, currentPos.y, currentPos.z)
    local newRotZ = currentRot.z

    CreateThread(function()
        while moving do
            Wait(0)

            -- Display helper text
            DrawText3D(newPos.x, newPos.y, newPos.z + 1.5,
                '~g~ENTER~s~ Confirm | ~r~ESC~s~ Cancel | ~b~WASD~s~ Move | ~y~Q/E~s~ Rotate')

            -- Movement controls
            local moveSpeed = 0.05
            if IsControlPressed(0, 32) then -- W - Forward
                newPos = newPos + GetEntityForwardVector(PlayerPedId()) * moveSpeed
            end
            if IsControlPressed(0, 33) then -- S - Back
                newPos = newPos - GetEntityForwardVector(PlayerPedId()) * moveSpeed
            end
            if IsControlPressed(0, 34) then -- A - Left
                local right = GetEntityRightVector(PlayerPedId())
                newPos = newPos - right * moveSpeed
            end
            if IsControlPressed(0, 35) then -- D - Right
                local right = GetEntityRightVector(PlayerPedId())
                newPos = newPos + right * moveSpeed
            end
            if IsControlPressed(0, 44) then -- Q - Rotate left
                newRotZ = newRotZ + 1.0
            end
            if IsControlPressed(0, 38) then -- E - Rotate right
                newRotZ = newRotZ - 1.0
            end

            -- Update entity position
            SetEntityCoords(entity, newPos.x, newPos.y, newPos.z, false, false, false, false)
            SetEntityRotation(entity, 0.0, 0.0, newRotZ, 2, true)

            -- Confirm placement
            if IsControlJustPressed(0, 191) then -- ENTER
                moving = false

                -- Save new position to server
                TriggerServerEvent('ox_inventory:updateStashPosition', data.stashId, newPos, newRotZ)

                lib.notify({
                    title = 'Stash Moved',
                    description = 'New position saved',
                    type = 'success'
                })
            end

            -- Cancel
            if IsControlJustPressed(0, 200) then -- ESC
                moving = false
                -- Reset position
                SetEntityCoords(entity, currentPos.x, currentPos.y, currentPos.z, false, false, false, false)
                SetEntityRotation(entity, currentRot.x, currentRot.y, currentRot.z, 2, true)

                lib.notify({
                    title = 'Move Cancelled',
                    description = 'Stash returned to original position',
                    type = 'inform'
                })
            end
        end
    end)

    cb('ok')
end)

-- NUI Callback: Remove Stash
RegisterNUICallback('removeStash', function(data, cb)
    if not data.stashId then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    -- Close inventory if open
    TriggerEvent('ox_inventory:closeInventory')

    -- Trigger server to handle removal (server validates ownership)
    TriggerServerEvent('ox_inventory:deleteStash', data.stashId)

    cb('ok')
end)

-- Helper function for 3D text
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Helper function to get entity right vector
function GetEntityRightVector(entity)
    local fwd = GetEntityForwardVector(entity)
    return vector3(-fwd.y, fwd.x, 0.0)
end

-- ============================================
-- /PSTORAGE COMMAND - Purchase Personal Storage
-- ============================================

-- Purchase storage with bank payment and start placement
local function PurchaseStorageBank(stashType)
    local config = STASH_PROPS[stashType]
    if not config then
        lib.notify({ title = 'Storage', description = 'Invalid storage type', type = 'error' })
        return
    end

    -- Request bank purchase from server
    local success = lib.callback.await('ox_inventory:purchaseStorageBank', false, stashType)
    if success then
        lib.notify({
            title = 'Storage Purchased',
            description = 'Place your ' .. config.label .. ' in the world',
            type = 'success'
        })
        StartPlacement(stashType)
    end
end

-- Register /pstorage command
RegisterCommand('pstorage', function()
    lib.registerContext({
        id = 'storage_purchase_menu',
        title = '🏦 Purchase Personal Storage',
        options = {
            {
                title = '📦 Small Safe - $50,000',
                description = '50 slots | 100kg capacity | Bank Payment',
                icon = 'fas fa-box',
                onSelect = function()
                    PurchaseStorageBank('small')
                end
            },
            {
                title = '🗄️ Medium Safe - $100,000',
                description = '75 slots | 150kg capacity | Bank Payment',
                icon = 'fas fa-archive',
                onSelect = function()
                    PurchaseStorageBank('medium')
                end
            },
            {
                title = '🏰 Large Safe - $150,000',
                description = '100 slots | 200kg capacity | Bank Payment',
                icon = 'fas fa-warehouse',
                onSelect = function()
                    PurchaseStorageBank('large')
                end
            },
        }
    })
    lib.showContext('storage_purchase_menu')
end, false)

-- Exports
exports('startStashPlacement', StartPlacement)
exports('cancelStashPlacement', CancelPlacement)
exports('getStashProps', function() return STASH_PROPS end)
exports('getSpawnedStashes', function() return spawnedStashes end)
exports('openSecuredStash', OpenSecuredStash)

-- ============================================
-- SAFE ITEM EXPORT & PED MERCHANT
-- ============================================

-- Exported function called when using a safe item from inventory
local function placePlayerSafe(data, slot)
    local itemName = data.name
    local stashType = 'small'
    
    if itemName == 'safe_medium' then stashType = 'medium'
    elseif itemName == 'safe_large' then stashType = 'large'
    elseif itemName == 'sf_prop_v_43_safe_s_bk_01a' then stashType = 'xxl'
    end
    
    -- Start placement mode
    StartPlacement(stashType)
end
exports('placePlayerSafe', placePlayerSafe)

-- Spawn Safe Salesman Ped at Legion Square
CreateThread(function()
    -- Wait for game to fully load
    Wait(2000)

    -- Define ped model and location (Legion Square central area)
    local pedModel = `ig_bankman`
    local pedCoords = vector4(153.05, -1025.04, 29.33, 340.0) -- Legion Square
    
    -- Load model
    lib.requestModel(pedModel)
    
    -- Spawn and configure ped
    local salesmanPed = CreatePed(0, pedModel, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, false)
    FreezeEntityPosition(salesmanPed, true)
    SetEntityInvincible(salesmanPed, true)
    SetBlockingOfNonTemporaryEvents(salesmanPed, true)
    TaskStartScenarioInPlace(salesmanPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
    
    -- Add ox_target interaction to open the storage purchase modal
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(salesmanPed, {
            {
                name = 'buy_safes',
                icon = 'fas fa-sack-dollar',
                label = 'Purchase Safes',
                onSelect = function()
                    -- Open the React UI modal
                    SendNUIMessage({
                        action = 'openStorageMenu'
                    })
                    SetNuiFocus(true, true)
                end
            }
        })
    end
end)

return {
    startPlacement = StartPlacement,
    cancelPlacement = CancelPlacement,
    openSecuredStash = OpenSecuredStash,
    purchaseStorageBank = PurchaseStorageBank,
    STASH_PROPS = STASH_PROPS
}
