-- Client-side Forge Model Spawning
-- Spawns custom forge models at defined locations with ox_target

if not lib then return end

local ForgeConfig = lib.load('data.forgelocations')
local Utils = require 'modules.utils.client'

if not ForgeConfig then
    return
end

local SpawnedForges = {}
local ForgeBlips = {}
local ForgeLights = {}
local ForgePtfx = {}

-- ============================================================================
-- MODEL LOADING
-- ============================================================================

---Load a model with timeout
---@param model string|number Model name or hash
---@return boolean success
local function LoadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model

    if not IsModelValid(hash) then
        return false
    end

    if HasModelLoaded(hash) then
        return true
    end

    RequestModel(hash)

    local timeout = 5000
    local startTime = GetGameTimer()

    while not HasModelLoaded(hash) do
        Wait(10)
        if GetGameTimer() - startTime > timeout then
            return false
        end
    end

    return true
end

-- ============================================================================
-- FORGE SPAWNING
-- ============================================================================

---Spawn a forge at location
---@param location table Location data from config
---@return number|nil handle Entity handle or nil on failure
local function SpawnForge(location)
    local modelName = ForgeConfig.model or 'prop_tool_bench02'

    if not LoadModel(modelName) then
        modelName = 'prop_tool_bench02'
        if not LoadModel(modelName) then
            return nil
        end
    end

    local hash = joaat(modelName)
    local coords = location.coords

    -- Create the object
    local forge = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)

    if not DoesEntityExist(forge) then
        return nil
    end

    -- Set heading
    SetEntityHeading(forge, coords.w or 0.0)

    -- Ground snap if enabled
    if ForgeConfig.visual and ForgeConfig.visual.useGroundSnap then
        PlaceObjectOnGroundProperly(forge)
    end

    -- Freeze in place
    FreezeEntityPosition(forge, true)
    SetEntityCollision(forge, true, true)

    -- Set as mission entity so it doesn't despawn
    SetEntityAsMissionEntity(forge, true, true)


    return forge
end

---Create blip for forge location
---@param location table Location data
---@return number|nil blipHandle
local function CreateForgeBlip(location)
    if not location.blip then return nil end

    local blipData = location.blip
    local coords = location.coords

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, blipData.sprite or 110)
    SetBlipDisplay(blip, blipData.display or 4)
    SetBlipScale(blip, blipData.scale or 0.8)
    SetBlipColour(blip, blipData.color or 47)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(location.label or '3D Printer')
    EndTextCommandSetBlipName(blip)

    return blip
end

---Create ox_target zone for forge
---@param location table Location data
---@param forgeHandle number Entity handle
local function CreateForgeTarget(location, forgeHandle)
    local interaction = ForgeConfig.interaction or {}

    exports.ox_target:addLocalEntity(forgeHandle, {
        {
            name = 'forge_' .. location.id,
            icon = interaction.targetIcon or 'fas fa-hammer',
            label = interaction.targetLabel or 'Open Forge',
            distance = interaction.distance or 2.5,
            canInteract = function()
                -- Check level requirement if any
                if location.levelRequired then
                    local craftingData = lib.callback.await('ox_inventory:getCraftingData', false)
                    if not craftingData or (craftingData.level or 1) < location.levelRequired then
                        return false
                    end
                end
                return true
            end,
            onSelect = function()
                -- Open crafting bench with tier restrictions if any
                TriggerEvent('ox_inventory:openForge', location.id, location.allowedTiers)
            end,
        },
    })
end

---Add visual effects (light + particles)
---@param location table Location data
---@param forgeHandle number Entity handle
local function AddForgeEffects(location, forgeHandle)
    local visual = ForgeConfig.visual
    if not visual then return end

    local coords = GetEntityCoords(forgeHandle)

    -- Light effect
    if visual.light and visual.light.enabled then
        local lightColor = visual.light.color or { r = 255, g = 150, b = 50 }
        -- Store light data for rendering in thread
        ForgeLights[location.id] = {
            coords = coords,
            color = lightColor,
            intensity = visual.light.intensity or 2.0,
            range = visual.light.range or 5.0,
        }
    end

    -- Particle effect
    if visual.ptfx and visual.ptfx.enabled then
        local dict = visual.ptfx.dict or 'core'
        local name = visual.ptfx.name or 'fire_wrecked_car'
        local scale = visual.ptfx.scale or 0.3

        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do
            Wait(10)
        end

        UseParticleFxAsset(dict)
        local ptfx = StartParticleFxLoopedAtCoord(name, coords.x, coords.y, coords.z + 0.5, 0.0, 0.0, 0.0, scale, false,
            false, false, false)
        ForgePtfx[location.id] = ptfx
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

---Initialize all forge locations
local function InitializeForges()
    if not ForgeConfig.locations then
        return
    end

    -- Avoid duplicate blips/props if start + playerLoaded both fire
    if next(ForgeBlips) or next(SpawnedForges) then
        return
    end

    for _, location in ipairs(ForgeConfig.locations) do
        -- Blips always — even if the prop model fails to stream/spawn
        local blip = CreateForgeBlip(location)
        if blip then
            ForgeBlips[location.id] = blip
        end

        local forgeHandle = SpawnForge(location)

        if forgeHandle then
            SpawnedForges[location.id] = forgeHandle
            CreateForgeTarget(location, forgeHandle)
            AddForgeEffects(location, forgeHandle)
        else
            -- Fallback: sphere zone at coords so forge still opens without a prop
            local interaction = ForgeConfig.interaction or {}
            local c = location.coords
            exports.ox_target:addSphereZone({
                coords = vec3(c.x, c.y, c.z),
                radius = interaction.distance or 2.5,
                debug = false,
                options = {
                    {
                        name = 'forge_' .. location.id,
                        icon = interaction.targetIcon or 'fas fa-hammer',
                        label = interaction.targetLabel or 'Open Forge',
                        distance = interaction.distance or 2.5,
                        canInteract = function()
                            if location.levelRequired then
                                local craftingData = lib.callback.await('ox_inventory:getCraftingData', false)
                                if not craftingData or (craftingData.level or 1) < location.levelRequired then
                                    return false
                                end
                            end
                            return true
                        end,
                        onSelect = function()
                            TriggerEvent('ox_inventory:openForge', location.id, location.allowedTiers)
                        end,
                    },
                },
            })
        end
    end
end

---Cleanup all spawned forges
local function CleanupForges()
    -- Remove targets and delete entities
    for id, handle in pairs(SpawnedForges) do
        exports.ox_target:removeLocalEntity(handle)
        if DoesEntityExist(handle) then
            DeleteEntity(handle)
        end
    end

    -- Remove blips
    for _, blip in pairs(ForgeBlips) do
        RemoveBlip(blip)
    end

    -- Stop particles
    for _, ptfx in pairs(ForgePtfx) do
        StopParticleFxLooped(ptfx, false)
    end

    SpawnedForges = {}
    ForgeBlips = {}
    ForgeLights = {}
    ForgePtfx = {}
end

-- ============================================================================
-- RENDERING LIGHTS
-- ============================================================================

CreateThread(function()
    while true do
        local sleep = 500
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, light in pairs(ForgeLights) do
            local dist = #(playerCoords - light.coords)

            if dist < 12.0 then
                sleep = 100
                DrawLightWithRange(
                    light.coords.x, light.coords.y, light.coords.z + 1.0,
                    light.color.r, light.color.g, light.color.b,
                    light.range, light.intensity
                )
            elseif dist < 35.0 then
                sleep = math.min(sleep, 250)
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Open forge event
RegisterNetEvent('ox_inventory:openForge', function(forgeId, allowedTiers)
    -- Find the matching crafting bench and open it
    TriggerEvent('ox_inventory:openCrafting', forgeId, allowedTiers)
end)

-- Initialize when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(1000) -- Wait for everything to load
        InitializeForges()
    end
end)

-- Player loaded
AddEventHandler('ox_inventory:playerLoaded', function()
    Wait(2000) -- Wait for world to load
    InitializeForges()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CleanupForges()
    end
end)

-- Export for manual spawning
exports('SpawnForge', SpawnForge)
exports('CleanupForges', CleanupForges)
