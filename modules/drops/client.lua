-- Ground Pickup System
-- Advanced 3D neon text, item models, ox_target, E key binding, and loot modal integration
-- Replaces the old ground inventory system

if not lib then return end

local Drops = {}
local ActiveDrops = {} -- { [dropId] = { point, targetId, entity, items, fadeAlpha } }
local Utils = require 'modules.utils.client'

-- Configuration
local Config = {
    renderDistance = 12.0,
    interactDistance = 2.5,
    modelSpawnDistance = 20.0,
    lookAngle = 42.0,

    fadeSpeed = 0.1,
    textScale = 0.32,
    labelOffset = 0.1,

    accent = { r = 186, g = 130, b = 255 },
    textPrimary = { r = 245, g = 245, b = 250 },
    textMuted = { r = 190, g = 190, b = 200 },
    keyAccent = { r = 154, g = 72, b = 208 },

    rotationSpeed = 18.0,
    bobHeight = 0.02,
    bobSpeed = 1.6,
    modelFloatHeight = 0.05,

    groundGlowEnabled = true,
    groundGlowHeight = -0.95,
}

-- Fade alpha tracking per drop
local FadeAlphas = {}

-- Active rendering state
local isRendering = false
local nearestDrop = nil -- Track nearest drop for E key pickup

-- ============================================================================
-- 3D Text Rendering
-- ============================================================================

local function RotationToDirection(rotation)
    local rotX = math.rad(rotation.x)
    local rotZ = math.rad(rotation.z)
    local cosX = math.abs(math.cos(rotX))

    return vector3(-math.sin(rotZ) * cosX, math.cos(rotZ) * cosX, math.sin(rotX))
end

---@param coords vector3
---@param maxAngle number
---@return boolean
local function IsPlayerFacingCoords(coords, maxAngle)
    local camCoords = GetGameplayCamCoords()
    local camRot = GetGameplayCamRot(2)
    local forward = RotationToDirection(camRot)
    local toTarget = coords - camCoords
    local distance = #toTarget

    if distance < 0.15 then return true end

    toTarget = toTarget / distance
    local dot = forward.x * toTarget.x + forward.y * toTarget.y + forward.z * toTarget.z
    local angle = math.deg(math.acos(math.max(-1.0, math.min(1.0, dot))))

    return angle <= maxAngle
end

---@param coords vector3
---@param x number
---@param y number
---@param z number
---@return number
local function GetDropGroundZ(x, y, z)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
    if found then return groundZ end
    return z + Config.groundGlowHeight
end

---@param coords vector3
---@param text string
---@param scale number
---@param colour table
---@param alpha number
---@param yOffset number
local function DrawWorldTextLine(coords, text, scale, colour, alpha, yOffset)
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(colour.r, colour.g, colour.b, math.floor(alpha))
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    SetDrawOrigin(coords.x, coords.y, coords.z + yOffset, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

---@param anchor vector3
---@param prompt string
---@param itemLabel string
---@param itemCount number
---@param alpha number
---@param distance number
local function DrawDropLabel(anchor, prompt, itemLabel, itemCount, alpha, distance)
    if not IsPlayerFacingCoords(anchor, Config.lookAngle) then return end

    local distanceScale = math.max(0.45, 1.0 - (distance / Config.renderDistance) * 0.35)
    local baseScale = Config.textScale * distanceScale
    local label = itemCount > 1 and ('%s  x%s'):format(itemLabel, itemCount) or itemLabel

    if distance <= Config.interactDistance then
        DrawWorldTextLine(anchor, prompt, baseScale * 0.95, Config.keyAccent, alpha, Config.labelOffset + 0.08)
        DrawWorldTextLine(anchor, label, baseScale * 0.82, Config.textMuted, alpha * 0.92, Config.labelOffset)
    else
        DrawWorldTextLine(anchor, label, baseScale * 0.88, Config.textPrimary, alpha * 0.85, Config.labelOffset + 0.04)
    end
end

---Draw ground glow circle (on actual ground level)
---@param coords vector3
---@param alpha number
local function DrawGroundGlow(coords, alpha)
    if not Config.groundGlowEnabled then return end

    local glowAlpha = math.floor(alpha * 0.5)

    -- Get ground Z position
    local groundZ = coords.z + Config.groundGlowHeight

    -- Draw pulsating ground marker
    local pulse = (math.sin(GetGameTimer() / 400.0) + 1) / 2 -- 0-1 pulse
    local size = 0.4 + (pulse * 0.15)

    DrawMarker(25, coords.x, coords.y, groundZ,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        size, size, 0.04,
        Config.accent.r, Config.accent.g, Config.accent.b, glowAlpha,
        false, false, 2, false, nil, nil, false)
end

-- ============================================================================
-- Model Management
-- ============================================================================

---Resolve a prop table (or first entry in a prop list) to a model hash
---@param prop table|nil
---@return number|nil
local function ResolvePropModel(prop)
    if not prop then return nil end

    if prop[1] and type(prop[1]) == 'table' then
        prop = prop[1]
    end

    if not prop.model then return nil end

    local model = type(prop.model) == 'number' and prop.model or joaat(prop.model)
    if IsModelValid(model) then
        return model
    end

    return nil
end

---@param itemName string
---@return table|nil
local function GetItemData(itemName)
    if not itemName then return nil end

    local item = exports.ox_inventory:Items(itemName)
    if item then return item end

    local upperName = itemName:upper()
    item = exports.ox_inventory:Items(upperName)
    if item then return item end

    return exports.ox_inventory:Items(itemName:lower())
end

---@param itemName string
---@param item table|nil
---@return number|nil
local function GetWeaponDropModel(itemName, item)
    local weaponHash

    if item and item.hash then
        weaponHash = item.hash
    else
        local normalized = itemName:upper()
        if normalized:sub(1, 7) == 'WEAPON_' then
            weaponHash = joaat(normalized)
        end
    end

    if not weaponHash then return nil end

    local model = GetWeapontypeModel(weaponHash)
    if model and model ~= 0 and IsModelValid(model) then
        return model
    end

    return nil
end

---Get item model hash for a specific item (bag prop only when no item model exists)
---@param itemName string
---@return number|nil hash
local function GetItemModel(itemName)
    if not itemName then return nil end

    local item = GetItemData(itemName)
    if not item then return nil end

    local weaponModel = GetWeaponDropModel(itemName, item)
    if weaponModel then
        return weaponModel
    end

    if item.model then
        local model = type(item.model) == 'number' and item.model or joaat(item.model)
        if IsModelValid(model) then
            return model
        end
    end

    local propModel = ResolvePropModel(item.prop) or ResolvePropModel(item.client and item.client.prop)
    if propModel then
        return propModel
    end

    local fallback = client and client.dropmodel
    if fallback and IsModelValid(fallback) then
        return fallback
    end

    return nil
end

---@param itemName string|nil
---@return boolean
local function CanSpawnDropModel(itemName)
    return itemName ~= nil and GetItemModel(itemName) ~= nil
end

---@param drop table
---@return vector3
local function GetDropAnchorCoords(drop)
    if drop.entity and DoesEntityExist(drop.entity) then
        local entityCoords = GetEntityCoords(drop.entity)
        return vector3(entityCoords.x, entityCoords.y, entityCoords.z + 0.08)
    end

    local groundZ = GetDropGroundZ(drop.coords.x, drop.coords.y, drop.coords.z)
    return vector3(drop.coords.x, drop.coords.y, groundZ + Config.modelFloatHeight)
end

---Spawn item prop with rotation effect (only if item has a model)
---@param dropId string
---@param coords vector3
---@param itemName string
---@return number? entity
local function SpawnItemProp(dropId, coords, itemName)
    local model = GetItemModel(itemName)

    -- Don't spawn prop if item has no model
    if not model then
        return nil
    end

    lib.requestModel(model, 5000)
    if not HasModelLoaded(model) then
        return nil
    end

    local groundZ = GetDropGroundZ(coords.x, coords.y, coords.z) + Config.modelFloatHeight
    local entity = CreateObject(model, coords.x, coords.y, groundZ, false, true, true)

    SetModelAsNoLongerNeeded(model)
    PlaceObjectOnGroundProperly(entity)
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, false)
    SetEntityAlpha(entity, 0, false)

    local item = GetItemData(itemName)
    local isWeaponProp = item and (item.weapon or itemName:upper():sub(1, 7) == 'WEAPON_')
    if isWeaponProp then
        SetEntityRotation(entity, 90.0, 0.0, math.random(0, 359) + 0.0, 2, true)
    end

    local baseCoords = GetEntityCoords(entity)
    local baseZ = baseCoords.z

    -- Start rotation and bobbing thread for this entity
    CreateThread(function()
        local heading = 0.0
        local time = 0.0
        local currentAlpha = 0

        while DoesEntityExist(entity) and ActiveDrops[dropId] do
            Wait(0)

            -- Rotation (skip for weapon props so they stay grounded)
            if not isWeaponProp then
                heading = heading + (Config.rotationSpeed * GetFrameTime())
                if heading >= 360.0 then heading = 0.0 end
                SetEntityHeading(entity, heading)
            end

            -- Bobbing
            time = time + (Config.bobSpeed * GetFrameTime())
            local bobOffset = isWeaponProp and 0.0 or (math.sin(time * math.pi) * Config.bobHeight)
            SetEntityCoords(entity, baseCoords.x, baseCoords.y, baseZ + bobOffset, false, false, false, false)

            -- Fade in/out based on visibility
            local drop = ActiveDrops[dropId]
            local targetAlpha = (drop and drop.visible) and 255 or 0

            if currentAlpha < targetAlpha then
                currentAlpha = math.min(currentAlpha + 20, targetAlpha)
            elseif currentAlpha > targetAlpha then
                currentAlpha = math.max(currentAlpha - 20, targetAlpha)
            end

            SetEntityAlpha(entity, math.floor(currentAlpha), false)
        end

        -- Cleanup
        if DoesEntityExist(entity) then
            Utils.DeleteEntity(entity)
        end
    end)

    return entity
end

-- ============================================================================
-- ox_target Integration
-- ============================================================================

---Create ox_target zone for drop pickup
---@param dropId string
---@param coords vector3
local function CreateTargetZone(dropId, coords)
    if not exports.ox_target then return nil end

    local groundZ = coords.z + Config.groundGlowHeight
    local targetCoords = vector3(coords.x, coords.y, groundZ)

    local options = {
        {
            icon = 'fas fa-hand-sparkles',
            label = 'Pick up',
            distance = Config.interactDistance,
            onSelect = function()
                TriggerEvent('ox_inventory:openGroundLoot', dropId)
            end,
        }
    }

    return exports.ox_target:addSphereZone({
        coords = targetCoords,
        radius = Config.interactDistance,
        options = options,
        debug = false,
    })
end

---Remove ox_target zone
---@param targetId number
local function RemoveTargetZone(targetId)
    if targetId and exports.ox_target then
        exports.ox_target:removeZone(targetId)
    end
end

-- ============================================================================
-- Drop Lifecycle
-- ============================================================================

---Create a new ground drop with 3D text and model
---@param dropId string
---@param data table { coords, items, instance, model }
function Drops.Create(dropId, data)
    if ActiveDrops[dropId] then
        Drops.Remove(dropId)
    end

    local coords = data.coords
    local instance = data.instance

    -- REALWRLD Item Drop Physics owns ground-drop visuals + pickup while it runs;
    -- keep only the registry record so this module's exports stay consistent.
    if GetResourceState('oxlyn_itemdrops') == 'started' then
        ActiveDrops[dropId] = { coords = coords, instance = instance }
        return
    end

    -- Get primary item for display
    local primaryItemName = nil
    local primaryItemLabel = 'Items'
    local itemCount = 0

    if data.items then
        for slot, item in pairs(data.items) do
            if item and item.name then
                if not primaryItemName then
                    primaryItemName = item.name
                    primaryItemLabel = item.label or item.name
                end
                itemCount = itemCount + 1
            end
        end
    end

    if not primaryItemName then
        CreateThread(function()
            local items = lib.callback.await('ox_inventory:getGroundItems', false, dropId)
            local drop = ActiveDrops[dropId]
            if not drop or not items then return end

            local count = 0
            local firstName, firstLabel

            for _, item in pairs(items) do
                if item and item.name then
                    count += 1
                    if not firstName then
                        firstName = item.name
                        firstLabel = item.label or item.name
                    end
                end
            end

            if firstName then
                drop.primaryItem = firstName
                drop.primaryLabel = firstLabel
                drop.itemCount = count
                drop.hasModel = CanSpawnDropModel(firstName)
            end
        end)
    end

    -- Create target zone
    local targetId = CreateTargetZone(dropId, coords)

    -- Create drop record
    ActiveDrops[dropId] = {
        coords = coords,
        instance = instance,
        targetId = targetId,
        entity = nil,
        primaryItem = primaryItemName,
        primaryLabel = primaryItemLabel,
        itemCount = itemCount,
        fadeAlpha = 0,
        visible = false,
        hasModel = CanSpawnDropModel(primaryItemName),
    }

    FadeAlphas[dropId] = 0

    -- Start global render loop if not running
    if not isRendering then
        Drops.StartRenderLoop()
    end
end

---Remove a ground drop
---@param dropId string
function Drops.Remove(dropId)
    local drop = ActiveDrops[dropId]
    if not drop then return end

    -- Remove target zone
    if drop.targetId then
        RemoveTargetZone(drop.targetId)
    end

    -- Entity cleanup handled by its own thread
    drop.visible = false

    ActiveDrops[dropId] = nil
    FadeAlphas[dropId] = nil
end

---Get items in a drop
---@param dropId string
---@return table?
function Drops.GetItems(dropId)
    return lib.callback.await('ox_inventory:getGroundItems', false, dropId)
end

-- ============================================================================
-- Render Loop
-- ============================================================================

---Start the main render loop
function Drops.StartRenderLoop()
    if isRendering then return end
    isRendering = true

    CreateThread(function()
        while isRendering and next(ActiveDrops) do
            local playerCoords = GetEntityCoords(cache.ped)
            local currentInstance = 0

            -- Track nearest drop for E key
            local closestDrop = nil
            local closestDistance = Config.interactDistance

            for dropId, drop in pairs(ActiveDrops) do
                -- Check instance
                if not drop.instance or drop.instance == currentInstance then
                    local distance = #(playerCoords - drop.coords)

                    -- Track nearest for E key
                    if distance <= closestDistance then
                        closestDistance = distance
                        closestDrop = dropId
                    end

                    -- Visibility check
                    local shouldBeVisible = distance <= Config.renderDistance
                    drop.visible = shouldBeVisible

                    -- Spawn/despawn model (only if item has a model)
                    if distance <= Config.modelSpawnDistance then
                        if not drop.entity and drop.primaryItem and drop.hasModel then
                            drop.entity = SpawnItemProp(dropId, drop.coords, drop.primaryItem)
                        end
                    else
                        if drop.entity and DoesEntityExist(drop.entity) then
                            Utils.DeleteEntity(drop.entity)
                            drop.entity = nil
                        end
                    end

                    -- Smooth fade
                    local targetAlpha = shouldBeVisible and 255 or 0
                    local currentAlpha = FadeAlphas[dropId] or 0

                    if currentAlpha < targetAlpha then
                        currentAlpha = math.min(currentAlpha + (Config.fadeSpeed * 255), targetAlpha)
                    elseif currentAlpha > targetAlpha then
                        currentAlpha = math.max(currentAlpha - (Config.fadeSpeed * 255), targetAlpha)
                    end

                    FadeAlphas[dropId] = currentAlpha

                    -- Draw label + subtle ground ring when visible
                    if currentAlpha > 0 then
                        local anchor = GetDropAnchorCoords(drop)
                        local showPrompt = dropId == closestDrop

                        DrawDropLabel(
                            anchor,
                            '[E]  Pick up',
                            drop.primaryLabel or 'Item',
                            drop.itemCount or 1,
                            currentAlpha,
                            distance
                        )

                        if IsPlayerFacingCoords(anchor, Config.lookAngle) then
                            DrawGroundGlow(drop.coords, currentAlpha * 0.65)
                        end
                    end
                end
            end

            -- Update nearest drop for E key handler
            nearestDrop = closestDrop

            Wait(0)
        end

        isRendering = false
        nearestDrop = nil
    end)
end

---Stop the render loop
function Drops.StopRenderLoop()
    isRendering = false
end

-- ============================================================================
-- E Key Binding
-- ============================================================================

-- ============================================================================
-- E Key Binding
-- ============================================================================

-- Register E key for pickup
lib.addKeybind({
    name = 'ground_pickup',
    description = 'Pick up ground items',
    defaultKey = 'E',
    onPressed = function()
        if nearestDrop then
            TriggerEvent('ox_inventory:openGroundLoot', nearestDrop)
        end
    end,
})

-- ============================================================================
-- Event Handlers
-- ============================================================================

-- Handle ground loot pickup via loot modal
RegisterNetEvent('ox_inventory:openGroundLoot', function(dropId)
    -- RealWrld merge: oxlyn_itemdrops owns ground pickup (instant [E]).
    -- The legacy loot modal must not open over it (focus fight / ghost modal).
    if GetResourceState('oxlyn_itemdrops') == 'started' then return end
    local items = Drops.GetItems(dropId)

    if items and next(items) then
        -- Open loot modal with ground items
        SendNUIMessage({
            action = 'openGroundLoot',
            data = {
                dropId = dropId,
                items = items,
            }
        })
        SetNuiFocus(true, true)
    else
        lib.notify({
            title = 'Empty',
            description = 'Nothing here to pick up',
            type = 'inform',
            duration = 2000,
        })
    end
end)

-- NUI Callbacks for ground pickup
RegisterNUICallback('takeGroundItem', function(data, cb)
    local success = lib.callback.await('ox_inventory:takeGroundItem', false, data.dropId, data.slot)
    cb({ success = success })
end)

RegisterNUICallback('takeAllGroundItems', function(data, cb)
    local success = lib.callback.await('ox_inventory:takeAllGroundItems', false, data.dropId)
    cb({ success = success })
end)

RegisterNUICallback('closeGroundLoot', function(_, cb)
    SetNuiFocus(false, false)
    cb(1)
end)

-- Export module
exports('GetDrops', function() return ActiveDrops end)

return Drops
