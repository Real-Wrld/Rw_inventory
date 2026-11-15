-- s_ground.lua  –  Server-side ground item management for bablo-throwitems

if GetCurrentResourceName() ~= "bablo-throwitems" then
    error("Resource name must be 'bablo-throwitems'")
    return
end

-- Fallback Translate if not already defined
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

-- groundItems[id] = { id, itemName, label, metadata, amount, propModel,
--                     coords, rotation, frozen, timestamp, droppedBy }
local groundItems   = {}
local nextItemId    = 0

-- ─── Helpers ──────────────────────────────────────────────────────────────────

-- Builds a flat array of all ground items (for sync payloads)
local function BuildGroundItemList()
    local list = {}
    for _, item in pairs(groundItems) do
        list[#list + 1] = item
    end
    return list
end

-- Sends the full ground item list to all players within GroundSyncDistance of coords
function SyncGroundToNearby(coords)
    local list    = BuildGroundItemList()
    local players = GetPlayers()

    for _, playerId in pairs(players) do
        local ped = GetPlayerPed(playerId)
        if ped and DoesEntityExist(ped) then
            local dist = #(coords - GetEntityCoords(ped))
            if dist <= Config.GroundSyncDistance then
                TriggerClientEvent("bablo-throwitems:ground:sync", playerId, list)
            end
        end
    end
end

-- Sends the full ground item list to all players
local function BroadcastGroundSync()
    TriggerClientEvent("bablo-throwitems:ground:sync", -1, BuildGroundItemList())
end

-- ─── Create ───────────────────────────────────────────────────────────────────

function CreateGroundItem(data)
    nextItemId = nextItemId + 1

    local item = {
        id        = nextItemId,
        itemName  = data.itemName,
        label     = data.label or data.itemName,
        metadata  = data.metadata,
        amount    = data.amount or 1,
        propModel = data.propModel,
        coords    = data.coords,
        rotation  = data.rotation or vector3(0.0, 0.0, 0.0),
        frozen    = data.frozen or false,
        timestamp = os.time(),
        droppedBy = data.droppedBy,
    }

    groundItems[item.id] = item
    SyncGroundToNearby(item.coords)
    return item.id
end

-- ─── Net events ───────────────────────────────────────────────────────────────

RegisterNetEvent("bablo-throwitems:ground:requestSync")
AddEventHandler("bablo-throwitems:ground:requestSync", function()
    local playerId = source
    TriggerClientEvent("bablo-throwitems:ground:sync", playerId, BuildGroundItemList())
end)

RegisterNetEvent("bablo-throwitems:ground:pickup")
AddEventHandler("bablo-throwitems:ground:pickup", function(groundId)
    local playerId = source
    local item     = groundItems[groundId]
    if not item then return end

    local ped = GetPlayerPed(playerId)
    if not (ped and DoesEntityExist(ped)) then return end

    local dist      = #(GetEntityCoords(ped) - item.coords)
    local maxDist   = Config.GroundPickupDistance + 2.0
    if dist > maxDist then return end

    local added = Inventory:addPlayerItem(
        playerId, item.itemName, item.amount or 1, item.metadata)

    if not added then
        if Framework and Framework.Notify then
            Framework:Notify(playerId, "Could not pick up item!")
        end
        return
    end

    groundItems[groundId] = nil

    if sendWebhook then
        sendWebhook(playerId, "PICKED_UP_ITEM", item.label or item.itemName)
    end

    SyncGroundToNearby(item.coords)
end)

-- ─── Exports ──────────────────────────────────────────────────────────────────

exports("GetGroundItems", function()
    return BuildGroundItemList()
end)

exports("GetGroundItem", function(id)
    return groundItems[id]
end)

exports("GetGroundItemsInRange", function(coords, radius)
    if not coords then return {} end
    local origin  = vector3(coords.x, coords.y, coords.z)
    local maxDist = tonumber(radius) or 10.0
    local result  = {}

    for _, item in pairs(groundItems) do
        if #(item.coords - origin) <= maxDist then
            result[#result + 1] = item
        end
    end

    return result
end)

exports("GetClosestGroundItem", function(coords, radius)
    if not coords then return nil end
    local origin   = vector3(coords.x, coords.y, coords.z)
    local maxDist  = tonumber(radius) or 10.0
    local best, bestDist = nil, maxDist

    for _, item in pairs(groundItems) do
        local dist = #(item.coords - origin)
        if dist <= bestDist then
            best     = item
            bestDist = dist
        end
    end

    return best, bestDist
end)

-- ─── Despawn loop ─────────────────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(60000)

        local now        = os.time()
        local anyExpired = false
        local lastCoords = nil

        for id, item in pairs(groundItems) do
            if now - item.timestamp >= Config.GroundDespawnTime then
                lastCoords      = item.coords
                groundItems[id] = nil
                anyExpired      = true
            end
        end

        if anyExpired then
            BroadcastGroundSync()
        end
    end
end)
