--  REALWRLD Software® · ox_inventory · ground drop points · client
-- ═════════════════════════════════════════════════════════════
--
--  One lib.points point per ground drop (the registry is `client.drops`),
--  drawn in ONE of two looks, server-wide:
--
--    • item props  — modules/rwdrops lays every item down as its own
--                    model (RWInv.Features.itemDrops AND the runtime
--                    switch RWInv.Drops.enabled);
--    • classic bag — every drop is ONE black bag, as in V2, whenever item
--                    props are off (config.lua, or an admin flipped the
--                    switch in Settings › Ground drops / Admin › Server).
--                    The model is the drop's own (exports CustomDrop), else
--                    `inventory:dropmodel`, else prop_med_bag_01b — always a
--                    bag, `inventory:dropprops false` no longer means a
--                    marker. Opened like upstream: the inventory key within
--                    1.2 m of the drop (client.lua `inv` keybind).
--
--  Flipping the switch re-creates every point (`client.recreateDrop`, from
--  RWDrops.applyConfig), so drops already on the ground change look too.
--  Nothing either look spawned outlives its point: the bag is created in a
--  thread with a per-point generation, so a point removed / re-created /
--  left while its model streams never gets one.
-- ═════════════════════════════════════════════════════════════

if not lib then return end

local RWDrops = require 'modules.rwdrops.client'
local Utils = require 'modules.utils.client'

local DropPoints = {}

local DEFAULT_BAG = joaat('prop_med_bag_01b')
-- lib.points reads `distance` into the radius at construction only
local BAG_DISTANCE = 30.0

---Instance the player is in. client.lua points it at its own
---`currentInstance` (set before the state bag value is applied).
function DropPoints.instance()
    return client.player:get('instance')
end

local function inInstance(point)
    return not point.instance or point.instance == DropPoints.instance()
end

local function isLive(point)
    return client.drops ~= nil and client.drops[point.invId] == point
end

---@param m any
---@return number?
local function validModel(m)
    if type(m) == 'string' then m = joaat(m) end
    if type(m) == 'number' and IsModelInCdimage(m) and IsModelValid(m) then return m end
end

---The drop's own model, else inventory:dropmodel, else the stock bag.
---@param point CPoint
---@return number
function DropPoints.bagModel(point)
    return validModel(point.model) or validModel(client.dropmodel) or DEFAULT_BAG
end

-- Every bag alive, entity -> point (diagnostics, logout / reload sweep).
local bags = {}

local function deleteBag(point)
    local entity = point.entity
    if not entity then return end

    point.entity = nil
    bags[entity] = nil
    Utils.DeleteEntity(entity)
end

---Classic bag: drop point entered its radius.
---@param point CPoint
local function onEnterBag(point)
    if point.entity or point.bagPending then return end
    if not isLive(point) or not inInstance(point) then return end

    local gen = (point.bagGen or 0) + 1
    point.bagGen = gen
    point.bagPending = true

    -- The model streams in a thread of its own: lib.points calls onEnter
    -- from its loop, which must not stall on (or die with) a request.
    CreateThread(function()
        local model = DropPoints.bagModel(point)
        local ok = pcall(lib.requestModel, model, 5000)

        -- a custom model that never streams: the stock bag instead
        if not ok and model ~= DEFAULT_BAG and point.bagGen == gen then
            model = DEFAULT_BAG
            ok = pcall(lib.requestModel, model, 5000)
        end

        if point.bagGen ~= gen then
            if ok then SetModelAsNoLongerNeeded(model) end
            return
        end

        point.bagPending = nil

        if not ok then return end

        if point.entity or not isLive(point) or not inInstance(point) then
            SetModelAsNoLongerNeeded(model)
            return
        end

        local c = point.coords
        local entity = CreateObject(model, c.x, c.y, c.z, false, true, true)
        SetModelAsNoLongerNeeded(model)

        if not entity or entity == 0 then return end

        PlaceObjectOnGroundProperly(entity)
        FreezeEntityPosition(entity, true)
        SetEntityCollision(entity, false, true)

        point.entity = entity
        bags[entity] = point
    end)
end

---Classic bag: drop point left its radius (or is going away).
---@param point CPoint
local function onExitBag(point)
    point.bagGen = (point.bagGen or 0) + 1
    point.bagPending = nil
    deleteBag(point)
end

---Create the point of a drop in the current look.
---@param dropId string
---@param data table drop record (or the old point on a re-create)
---@param fresh? boolean true only for a drop created right now (its props tumble)
---@return CPoint
function DropPoints.create(dropId, data, fresh)
    local props = RWDrops.enabled == true

    local point = lib.points.new({
        coords = data.coords,
        distance = props and RWDrops.renderDistance or BAG_DISTANCE,
        invId = dropId,
        instance = data.instance,
        model = data.model,
    })

    -- the item map and the creation time ride along in both looks, so a
    -- switch can rebuild the other one without waiting for the server
    point.items = data.items
    point.oxCreated = fresh and GetGameTimer() or data.oxCreated or 0

    if props then
        point.onEnter = RWDrops.onEnter
        point.onExit = RWDrops.onExit
    else
        point.onEnter = onEnterBag
        point.onExit = onExitBag
    end

    client.drops[dropId] = point

    return point
end

---Take a point off the map: its props or its bag go with it (idempotent;
---the point stays in `client.drops` — callers drop the entry themselves).
---@param point CPoint
function DropPoints.remove(point)
    RWDrops.remove(point)
    onExitBag(point)
    point:remove()
end

---Re-create a drop point in the current look (the switch flipped, or the
---item props' render distance changed — the radius is fixed at creation).
---@param dropId string
function DropPoints.recreate(dropId)
    local p = client.drops and client.drops[dropId]
    if not p then return end

    DropPoints.remove(p)
    DropPoints.create(dropId, p)
end

---Every drop from the server (player loaded): replaces the registry.
---@param drops table<string, table>
function DropPoints.load(drops)
    RWDrops.clearAll()

    if client.drops and client.drops ~= drops then
        for _, point in pairs(client.drops) do
            if type(point) == 'table' and point.remove then DropPoints.remove(point) end
        end
    end

    client.drops = drops

    for dropId, data in pairs(drops) do
        DropPoints.create(dropId, data)
    end
end

---Bags alive on this client (harness / diagnostics).
---@return number
function DropPoints.bagCount()
    local n = 0
    for entity in pairs(bags) do
        if DoesEntityExist(entity) then n = n + 1 else bags[entity] = nil end
    end
    return n
end

client.recreateDrop = DropPoints.recreate

return DropPoints
