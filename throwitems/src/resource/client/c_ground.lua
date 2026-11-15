-- c_ground.lua  –  Ground item rendering and pickup for bablo-throwitems

if GetCurrentResourceName() ~= "bablo-throwitems" then
    error("Resource name must be 'bablo-throwitems'")
    return
end

-- ─── Translate helper (fallback when Translate global is missing) ─────────────

if not Translate then
    function Translate(key)
        if Locales then
            local locale = Config.Locale or "en-US"
            local dict   = Locales[locale]
            return dict and dict[key]
        end
    end
end

-- ─── State ────────────────────────────────────────────────────────────────────

-- groundItems: [serverId/itemId] = { handle, coords, label, zoneId, groundId, settling }
local groundItems     = {}
local pickupBusy      = false   -- prevents double-pickup animation
local closestItem     = nil     -- currently highlighted ground item data table

-- DUI handles
local dotDuiHandle    = nil     -- small dot sprite DUI
local cardDuiHandle   = nil     -- pickup-label card DUI
local duiReady        = false   -- true once both DUIs are initialised

-- DUI texture names
local DOT_TXD         = "bablo_dot_txd"
local DOT_TEX         = "bablo_dot_tex"
local CARD_TXD        = "bablo_card_txd"
local CARD_TEX        = "bablo_card_tex"

-- Card visibility / fade state
local cardVisible     = false
local lastCardLabel   = ""
local cardAlpha       = 255.0   -- current card alpha (255 = opaque, fades in when approaching)
local dotAlpha        = 0.0     -- dot alpha (fades in when approaching)
local ALPHA_STEP      = 18.0    -- how fast alpha changes per tick

-- ─── DUI initialisation ───────────────────────────────────────────────────────

CreateThread(function()
    -- Dot DUI (small white circle shown at item location)
    local dotDui    = CreateDui("nui://bablo-throwitems/dui/dot.html", 256, 256)
    dotDuiHandle    = dotDui
    local dotHandle = GetDuiHandle(dotDui)
    local dotTxd    = CreateRuntimeTxd(DOT_TXD)
    CreateRuntimeTextureFromDuiHandle(dotTxd, DOT_TEX, dotHandle)

    -- Card DUI (item name / pickup prompt)
    local cardDui    = CreateDui("nui://bablo-throwitems/dui/index.html", 768, 256)
    cardDuiHandle    = cardDui
    local cardHandle = GetDuiHandle(cardDui)
    local cardTxd    = CreateRuntimeTxd(CARD_TXD)
    CreateRuntimeTextureFromDuiHandle(cardTxd, CARD_TEX, cardHandle)

    duiReady = true
end)

-- ─── Card DUI messaging ───────────────────────────────────────────────────────

function ShowPickupCard(itemLabel)
    if not duiReady or not cardDuiHandle then return end

    local label = itemLabel or ""
    if cardVisible and lastCardLabel == label then return end  -- no change

    local pickupText = Translate("PICKUP_ITEM")
    local display    = (pickupText and label ~= "") and pickupText:format(label) or label

    SendDuiMessage(cardDuiHandle, json.encode({
        action  = "pickup-dui",
        visible = true,
        label   = display,
    }))

    cardVisible   = true
    lastCardLabel = label
end

function HidePickupCard()
    if not duiReady or not cardDuiHandle then return end
    if not cardVisible then return end

    SendDuiMessage(cardDuiHandle, json.encode({
        action  = "pickup-dui",
        visible = false,
        label   = "",
    }))

    cardVisible   = false
    lastCardLabel = ""
end

-- ─── Sprite drawing ───────────────────────────────────────────────────────────

-- Draws the pickup card (wide sprite) at the item's world position
function DrawPickupCardSprite(worldPos, alpha)
    if not duiReady then return end
    local alphaInt = math.floor(alpha or 255)
    if alphaInt <= 0 then return end

    local renderZ = worldPos.z + 0.05
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, renderZ)
    if not onScreen then return end

    local camPos  = GetGameplayCamCoords()
    local camDist = #(camPos - vector3(worldPos.x, worldPos.y, renderZ))
    local scale   = math.min(1.5, math.max(0.5, (1.0 / camDist) * 3.0))
    local aspect  = GetAspectRatio(false)
    local size    = 0.16 * scale

    DrawSprite(CARD_TXD, CARD_TEX,
        screenX, screenY,
        size, (size / 3.0) * aspect,
        0.0, 255, 255, 255, alphaInt)
end

-- Draws the small dot sprite at the item's world position
function DrawDotSprite(worldPos, alpha)
    if not duiReady then return end
    local alphaInt = math.floor(alpha or 255)
    if alphaInt <= 0 then return end

    local renderZ = worldPos.z + 0.05
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, renderZ)
    if not onScreen then return end

    local camPos  = GetGameplayCamCoords()
    local camDist = #(camPos - vector3(worldPos.x, worldPos.y, renderZ))
    local scale   = math.min(1.5, math.max(0.35, (1.0 / camDist) * 3.0))
    local aspect  = GetAspectRatio(false)
    local size    = 0.035 * scale

    DrawSprite(DOT_TXD, DOT_TEX,
        screenX, screenY,
        size, size * aspect,
        0.0, 255, 255, 255, alphaInt)
end

-- ─── Model loading ────────────────────────────────────────────────────────────

function RequestGroundModel(model)
    if type(model) == "string" then model = GetHashKey(model) end
    if not IsModelValid(model) then return false end

    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and not (attempts >= 100) do
        Wait(10)
        attempts = attempts + 1
    end
    return HasModelLoaded(model)
end

-- ─── Pickup animation ─────────────────────────────────────────────────────────

function PickupGroundItem(groundId)
    if pickupBusy then return end
    pickupBusy = true

    local ped      = PlayerPedId()
    local ANIM_DICT = "pickup_object"
    local ANIM_CLIP = "pickup_low"

    RequestAnimDict(ANIM_DICT)
    local attempts = 0
    while not HasAnimDictLoaded(ANIM_DICT) and attempts < 50 do
        Wait(10)
        attempts = attempts + 1
    end

    if HasAnimDictLoaded(ANIM_DICT) then
        TaskPlayAnim(ped, ANIM_DICT, ANIM_CLIP, 2.0, 2.0, 1000, 0, 0, false, false, false)
        Wait(800)
    end

    TriggerServerEvent("bablo-throwitems:ground:pickup", groundId)
    Wait(500)
    pickupBusy = false
end

-- ─── Ground item sync ─────────────────────────────────────────────────────────

-- Synchronises the local groundItems table with the server's authoritative list.
-- Removes items no longer present, adds new ones with prop spawning.
function SyncGroundItems(serverList)
    -- Build lookup of IDs the server knows about
    local activeIds = {}
    for _, item in ipairs(serverList) do
        activeIds[item.id] = true
    end

    -- Remove stale local items
    for id, data in pairs(groundItems) do
        if not activeIds[id] then
            if data.zoneId then
                Target:removeTargetZone(data.zoneId)
            end
            if data.handle and DoesEntityExist(data.handle) then
                DeleteEntity(data.handle)
            end
            groundItems[id] = nil
        end
    end

    -- Spawn new items
    for _, item in ipairs(serverList) do
        if not groundItems[item.id] then
            -- Resolve model hash
            local modelHash = item.propModel
            if type(modelHash) == "string" then modelHash = GetHashKey(modelHash) end

            if not RequestGroundModel(modelHash) then
                modelHash = GetHashKey(Config.DefaultProp)
                RequestGroundModel(modelHash)
            end

            -- Snap Z to ground
            local spawnZ        = item.coords.z
            local groundFound, groundZ = GetGroundZFor_3dCoord(
                item.coords.x, item.coords.y, item.coords.z + 1.0, false)
            if groundFound then spawnZ = groundZ end

            local spawnCoords = vector3(item.coords.x, item.coords.y, spawnZ)

            local entity = CreateObject(modelHash,
                spawnCoords.x, spawnCoords.y, spawnCoords.z,
                false, true, false)

            if entity and DoesEntityExist(entity) then
                SetEntityAsMissionEntity(entity, true, true)
                SetModelAsNoLongerNeeded(modelHash)

                -- Build display label
                local label = item.label or item.itemName or ""
                if item.amount and item.amount > 1 then
                    label = label .. " x" .. item.amount
                end

                local groundId = item.id

                if item.frozen then
                    -- Frozen items: set exact rotation, freeze, no collision
                    if item.rotation then
                        SetEntityRotation(entity,
                            item.rotation.x, item.rotation.y, item.rotation.z, 2, true)
                    end
                    FreezeEntityPosition(entity, true)
                    SetEntityCollision(entity, false, false)

                    groundItems[item.id] = {
                        handle   = entity,
                        coords   = spawnCoords,
                        label    = label,
                        zoneId   = nil,
                        groundId = groundId,
                        settling = false,
                    }

                    -- Attach target zone if using target interact
                    if Config.Interact == "target" then
                        local pickupLabel = Translate("PICKUP_ITEM")
                        local zoneLabel   = (pickupLabel and label ~= "")
                            and pickupLabel:format(label)
                            or ("Pick up " .. label)

                        local zoneId = Target:addTargetZone(spawnCoords, 0.5, {
                            label      = zoneLabel,
                            icon       = "fas fa-hand",
                            distance   = Config.GroundPickupDistance,
                            action     = function()
                                PickupGroundItem(groundId)
                            end,
                            canInteract = function()
                                return not IsPedInAnyVehicle(PlayerPedId(), false)
                            end,
                        })

                        groundItems[item.id].zoneId = zoneId
                    end

                else
                    -- Non-frozen: let physics settle, then freeze after 2.5 s
                    SetEntityDynamic(entity, true)
                    SetEntityCollision(entity, true, true)
                    FreezeEntityPosition(entity, false)
                    ApplyForceToEntity(entity, 1,
                        math.random() * 0.6 - 0.3,
                        math.random() * 0.6 - 0.3,
                        math.random() * 1.0 + 0.5,
                        0.0, 0.0, 0.0, 0, false, true, true, false, true)

                    groundItems[item.id] = {
                        handle   = entity,
                        coords   = spawnCoords,
                        label    = label,
                        zoneId   = nil,
                        groundId = groundId,
                        settling = true,
                    }

                    -- After physics settles, freeze and add target zone
                    local capturedEntity  = entity
                    local capturedId      = item.id
                    local capturedGround  = groundId

                    CreateThread(function()
                        Wait(2500)
                        if not capturedEntity or not DoesEntityExist(capturedEntity) then return end
                        local entry = groundItems[capturedId]
                        if not entry then return end

                        FreezeEntityPosition(capturedEntity, true)
                        SetEntityDynamic(capturedEntity, false)
                        local settledCoords = GetEntityCoords(capturedEntity)
                        entry.coords   = settledCoords
                        entry.settling = false
                        SetEntityCollision(capturedEntity, false, false)

                        if Config.Interact == "target" then
                            local entryLabel  = (entry and entry.label) or ""
                            local pickupLabel = Translate("PICKUP_ITEM")
                            local zoneLabel   = (pickupLabel and entryLabel ~= "")
                                and pickupLabel:format(entryLabel)
                                or ("Pick up " .. entryLabel)

                            local zoneId = Target:addTargetZone(settledCoords, 0.5, {
                                label      = zoneLabel,
                                icon       = "fas fa-hand",
                                distance   = Config.GroundPickupDistance,
                                action     = function()
                                    PickupGroundItem(capturedGround)
                                end,
                                canInteract = function()
                                    return not IsPedInAnyVehicle(PlayerPedId(), false)
                                end,
                            })
                            entry.zoneId = zoneId
                        end
                    end)
                end
            end
        end
    end
end

-- ─── Net event: server → client sync ─────────────────────────────────────────

RegisterNetEvent("bablo-throwitems:ground:sync")
AddEventHandler("bablo-throwitems:ground:sync", function(list)
    SyncGroundItems(list)
end)

-- ─── Exports ─────────────────────────────────────────────────────────────────

exports("GetGroundItems", function()
    local result = {}
    for id, data in pairs(groundItems) do
        result[#result + 1] = {
            id       = data.groundId or id,
            handle   = data.handle,
            coords   = data.coords,
            label    = data.label,
            settling = data.settling,
        }
    end
    return result
end)

exports("GetClosestGroundItem", function(originCoords, maxDist)
    local origin = originCoords
        and vector3(originCoords.x, originCoords.y, originCoords.z)
        or GetEntityCoords(PlayerPedId())

    maxDist = tonumber(maxDist) or 10.0

    local bestItem, bestDist = nil, maxDist

    for id, data in pairs(groundItems) do
        if data.handle and DoesEntityExist(data.handle) then
            local dist = #(data.coords - origin)
            if dist <= bestDist then
                bestItem = {
                    id       = data.groundId or id,
                    handle   = data.handle,
                    coords   = data.coords,
                    label    = data.label,
                    settling = data.settling,
                }
                bestDist = dist
            end
        end
    end

    return bestItem, bestDist
end)

-- ─── Initial sync request ─────────────────────────────────────────────────────

CreateThread(function()
    Wait(2000)
    TriggerServerEvent("bablo-throwitems:ground:requestSync")
end)

-- ─── Render / proximity loop (non-target interact only) ───────────────────────

CreateThread(function()
    if Config.Interact == "target" then return end

    -- Wait for DUI
    while not duiReady do Wait(100) end

    local RENDER_DIST   = Config.GroundRenderDistance or 5.0
    local MAX_VISIBLE   = Config.GroundMaxVisible or 5
    local PICKUP_DIST   = Config.GroundPickupDistance

    while true do
        local waitMs = 500
        local hasAny = false
        for _ in pairs(groundItems) do hasAny = true break end

        if not hasAny then
            HidePickupCard()
            closestItem = nil
            cardAlpha   = 255.0
            dotAlpha    = 0.0
            Wait(waitMs)
        else

        local pedCoords = GetEntityCoords(PlayerPedId())

        -- Collect nearby items, sorted by distance
        local nearby = {}
        for id, data in pairs(groundItems) do
            if data.handle and DoesEntityExist(data.handle) then
                local dist = #(pedCoords - data.coords)
                if dist <= RENDER_DIST then
                    nearby[#nearby + 1] = { id = id, data = data, dist = dist }
                end
            end
        end

        if #nearby > 0 then
            waitMs = 0

            table.sort(nearby, function(a, b) return a.dist < b.dist end)

            -- Trim to MAX_VISIBLE
            for i = #nearby, MAX_VISIBLE + 1, -1 do nearby[i] = nil end

            local closest = nearby[1]

            if closest.dist <= PICKUP_DIST then
                -- Fade card in, dot out
                dotAlpha  = math.min(255.0, dotAlpha + ALPHA_STEP)
                cardAlpha = math.max(0.0,   cardAlpha - ALPHA_STEP)

                ShowPickupCard(closest.data.label)
                DrawPickupCardSprite(closest.data.coords, dotAlpha)

                if cardAlpha > 0 then
                    DrawDotSprite(closest.data.coords, cardAlpha)
                end

                if not IsPedInAnyVehicle(PlayerPedId(), false) then
                    closestItem = closest.data
                    if IsControlJustPressed(0, 38) and not pickupBusy then
                        PickupGroundItem(closestItem.groundId)
                    end
                else
                    closestItem = nil
                end
            else
                -- Too far: fade dot in, card out
                dotAlpha  = math.max(0.0,   dotAlpha - ALPHA_STEP)
                cardAlpha = math.min(255.0, cardAlpha + ALPHA_STEP)

                if dotAlpha > 0 then
                    DrawPickupCardSprite(closest.data.coords, dotAlpha)
                end
                DrawDotSprite(closest.data.coords, cardAlpha)

                if dotAlpha <= 0 then HidePickupCard() end
                closestItem = nil
            end

            -- Draw dot for remaining visible items
            for i = 2, #nearby do
                DrawDotSprite(nearby[i].data.coords)
            end
        else
            HidePickupCard()
            closestItem = nil
            cardAlpha   = 255.0
            dotAlpha    = 0.0
        end

        end
        Wait(waitMs)
    end
end)

-- ─── Cleanup on resource stop ─────────────────────────────────────────────────

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if dotDuiHandle  then DestroyDui(dotDuiHandle)  dotDuiHandle  = nil end
    if cardDuiHandle then DestroyDui(cardDuiHandle) cardDuiHandle = nil end

    for _, data in pairs(groundItems) do
        if data.zoneId then Target:removeTargetZone(data.zoneId) end
        if data.handle and DoesEntityExist(data.handle) then
            DeleteEntity(data.handle)
        end
    end
    groundItems = {}
end)
