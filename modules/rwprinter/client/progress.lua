PrinterProgress = {}

local isEmpty = true      -- true when the NUI currently shows no cards/cells
local cachedLabels = nil

local function getLabels()
    if cachedLabels then return cachedLabels end

    cachedLabels = {
        active    = PrinterL("bar_eyebrow"),
        ready     = PrinterL("bar_eyebrow_ready"),
        remaining = PrinterL("bar_remaining"),
        complete  = PrinterL("bar_complete"),
        printing  = PrinterL("bar_printing"),
        collect   = PrinterL("bar_ready"),
        battery   = PrinterL("bar_battery"),
        watts     = PrinterL("bar_watts"),
        nobattery = PrinterL("bar_nobattery"),
    }
    return cachedLabels
end

-- ─────────────────────────────────────────────
-- Position packets
-- ─────────────────────────────────────────────

-- Reused table so per-frame position updates don't allocate
local posPacket = { action = "cardpos", c = {}, e = {} }

-- Flattens a list of slots into { id, x, y, scale, alpha, id, x, y, ... }
local function pack(out, list)
    local n = 0

    for i = 1, #list do
        local item = list[i]
        out[n + 1] = item.id
        out[n + 2] = item.x
        out[n + 3] = item.y
        out[n + 4] = item.scale
        out[n + 5] = item.alpha
        n = n + 5
    end

    -- Trim leftovers from a previous, longer packet
    for i = #out, n + 1, -1 do
        out[i] = nil
    end
end

-- cards = progress bar slots, cells = battery slots
-- moved = positions changed (send light packet), dirty = content changed (send full data)
function PrinterProgress.Render(cards, cells, moved, dirty)
    cells = cells or {}

    if #cards == 0 and #cells == 0 then
        if not isEmpty then
            SendNUIMessage({ action = "cards", cards = {}, cells = {} })
            isEmpty = true
        end
        return
    end

    if isEmpty or dirty then
        isEmpty = false
        SendNUIMessage({
            action = "cards",
            cards  = cards,
            cells  = cells,
            labels = getLabels(),
        })
        return
    end

    if not moved then return end

    pack(posPacket.c, cards)
    pack(posPacket.e, cells)
    SendNUIMessage(posPacket)
end

function PrinterProgress.Clear()
    if isEmpty then return end

    SendNUIMessage({ action = "cards", cards = {}, cells = {} })
    isEmpty = true
end

-- ─────────────────────────────────────────────
-- Line-of-sight occlusion
-- ─────────────────────────────────────────────

local sightCache = {}   -- [key] = { v, blocked, handle, at, last, sx, sy, sz, target }

local occlusionEnabled = PrinterConfig.UI.occlusion
local fadeSpeed = PrinterConfig.UI.occlusionFade or 6.0
local HIT_TOLERANCE = 0.55

local function dist3(x1, y1, z1, x2, y2, z2)
    local dx, dy, dz = x1 - x2, y1 - y2, z1 - z2
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Interprets a shape-test result. (a, b, c) are the hit coordinates, (sx, sy, sz) the ray start,
-- expected = distance from ray start to the target point.
local function isBlocked(status, hit, a, b, c, sx, sy, sz, expected)
    if status ~= 2 then return false end                 -- 2 = result ready
    if hit ~= 1 and hit ~= true then return false end    -- nothing hit

    -- No numeric hit coordinates -> assume blocked
    if type(a) ~= "number" then return true end

    -- Blocked only if the hit is meaningfully before the target
    return dist3(a, b, c, sx, sy, sz) < expected - HIT_TOLERANCE
end

local function getIgnoredVehicle()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh and veh ~= 0 then return veh end
    return 0
end

-- Async occlusion check, returns (fadeValue 0..1, blocked).
-- key = unique id for the thing being checked, mask = shape test flags
function PrinterProgress.Sight(key, x, y, z, mask, now)
    if not occlusionEnabled then
        return 1.0, false
    end

    local c = sightCache[key]
    if not c then
        c = { v = 1.0, blocked = false, handle = nil, at = 0, last = now }
        sightCache[key] = c
    end

    -- Collect pending result
    if c.handle then
        local status, hit, ra, rb, rc = GetShapeTestResult(c.handle)
        if status ~= 1 then
            c.blocked = isBlocked(status, hit, ra, rb, rc, c.sx, c.sy, c.sz, c.target or 0.0)
            c.handle = nil
        elseif now - c.at > 1000 then
            c.handle = nil  -- timed out
        end
    end

    -- Fire a new ray at most every 120ms
    if not c.handle and now - c.at > 120 then
        c.at = now

        local cam = GetFinalRenderedCamCoord()
        local dx, dy, dz = x - cam.x, y - cam.y, z - cam.z
        local d = math.sqrt(dx * dx + dy * dy + dz * dz)

        if d > 0.5 then
            -- Start the ray slightly in front of the camera
            local k = 0.35 / d
            local sx, sy, sz = cam.x + dx * k, cam.y + dy * k, cam.z + dz * k

            c.sx, c.sy, c.sz = sx, sy, sz
            c.target = d - 0.35
            c.handle = StartShapeTestRay(sx, sy, sz, x, y, z, mask, getIgnoredVehicle(), 4)
        end
    end

    -- Fade towards visible / hidden
    local dt = math.min((now - (c.last or now)) / 1000.0, 0.1)
    c.last = now

    local goal = c.blocked and 0.0 or 1.0
    local step = fadeSpeed * dt

    if goal > c.v then
        c.v = math.min(goal, c.v + step)
    elseif goal < c.v then
        c.v = math.max(goal, c.v - step)
    end

    return c.v, c.blocked
end

-- Synchronous one-off occlusion check (used for the interact prompt)
function PrinterProgress.Blocked(x, y, z, mask)
    if not occlusionEnabled then return false end

    local cam = GetFinalRenderedCamCoord()
    local dx, dy, dz = x - cam.x, y - cam.y, z - cam.z
    local d = math.sqrt(dx * dx + dy * dy + dz * dz)

    if d <= 0.5 then return false end

    local k = 0.35 / d
    local sx, sy, sz = cam.x + dx * k, cam.y + dy * k, cam.z + dz * k

    local handle = StartExpensiveSynchronousShapeTestLosProbe(sx, sy, sz, x, y, z, mask, getIgnoredVehicle(), 4)
    local status, hit, ra, rb, rc = GetShapeTestResult(handle)

    return isBlocked(status, hit, ra, rb, rc, sx, sy, sz, d - 0.35)
end

-- Drops cache entries not used for 10s
function PrinterProgress.Prune(now)
    for key, c in pairs(sightCache) do
        if now - c.at > 10000 then
            sightCache[key] = nil
        end
    end
end

-- ─────────────────────────────────────────────
-- Projection / scaling
-- ─────────────────────────────────────────────

function PrinterProgress.Project(x, y, z)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then
        return false, 0, 0
    end
    return true, sx, sy
end

local cardScale = PrinterConfig.UI.cardScale or 0.72
local refDistance = PrinterConfig.UI.cardRefDistance or 3.5
local renderDistance = PrinterConfig.RenderDistance
local fadeLength = math.max(0.01, PrinterConfig.UI.cardFade or 2.5)

-- Card scale shrinks with distance (clamped between 0.28x and 1.35x of base scale)
function PrinterProgress.ScaleFor(dist)
    local scale = cardScale * (refDistance / math.max(dist or refDistance, 0.5))
    return math.min(math.max(scale, cardScale * 0.28), cardScale * 1.35)
end

-- Card alpha fades out over the last `fadeLength` metres before RenderDistance
function PrinterProgress.AlphaFor(dist)
    if dist <= renderDistance - fadeLength then return 1.0 end
    if dist >= renderDistance then return 0.0 end
    return (renderDistance - dist) / fadeLength
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    PrinterProgress.Clear()
end)