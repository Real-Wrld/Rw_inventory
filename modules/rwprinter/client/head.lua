PrinterHead = {}

local headCfg            -- PrinterConfig.Head, assigned after config loads
local heads = {}         -- [printerId] = { obj, x, last, checkedAt }
local modelHash
local modelLoaded = false
local rotCache = {}      -- [heading] = { cos, sin }

CreateThread(function()
    Wait(100)
    headCfg = PrinterConfig.Head
end)

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function ensureModel()
    if modelLoaded then return true end
    if not (headCfg and headCfg.enabled) then return false end

    modelHash = joaat(headCfg.model)

    if not (IsModelInCdimage(modelHash) and IsModelValid(modelHash)) then
        print(("^1[rwprinter] Modelo da cabeca (%s) nao encontrado. O stream/ tem o prop_3dprinter_head.ydr?^0")
            :format(headCfg.model))
        return false
    end

    RequestModel(modelHash)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(modelHash) and GetGameTimer() < deadline do
        Wait(20)
    end

    modelLoaded = HasModelLoaded(modelHash)
    return modelLoaded
end

-- Rotate local (x, y) offset by heading (degrees)
local function rotateOffset(heading, x, y)
    heading = heading or 0.0

    local rot = rotCache[heading]
    if not rot then
        local rad = math.rad(heading)
        rot = { math.cos(rad), math.sin(rad) }
        rotCache[heading] = rot
    end

    return x * rot[1] - y * rot[2],
           x * rot[2] + y * rot[1]
end

-- Smooth triangle-wave easing, returns -1..1
local function sway(time, period)
    local t = (time % period) / period
    local u = (t < 0.5) and (t * 4.0 - 1.0) or (3.0 - t * 4.0)
    return 1.5 * u - 0.5 * u * u * u
end

-- ─────────────────────────────────────────────
-- API
-- ─────────────────────────────────────────────

function PrinterHead.Ensure(id, printer)
    if not (headCfg and headCfg.enabled) then return end

    local existing = heads[id]
    if existing and DoesEntityExist(existing.obj) then return end

    if not ensureModel() then return end

    local coords = printer.coords
    local ox, oy = rotateOffset(printer.heading, headCfg.offset.x, headCfg.offset.y)

    local obj = CreateObjectNoOffset(
        modelHash,
        coords.x + ox,
        coords.y + oy,
        coords.z + headCfg.offset.z,
        false, false, false
    )

    SetEntityHeading(obj, printer.heading or 0.0)
    SetEntityAsMissionEntity(obj, true, true)
    FreezeEntityPosition(obj, true)
    SetEntityHasGravity(obj, false)
    SetEntityInvincible(obj, true)
    SetEntityCanBeDamaged(obj, false)
    SetEntityCollision(obj, false, false)

    heads[id] = {
        obj       = obj,
        x         = 0.0,
        last      = GetGameTimer(),
        checkedAt = 0,
    }
end

function PrinterHead.Remove(id)
    local head = heads[id]
    if not head then return end

    if head.obj and DoesEntityExist(head.obj) then
        DeleteEntity(head.obj)
    end

    heads[id] = nil
end

function PrinterHead.Update(id, printer, active, now)
    if not (headCfg and headCfg.enabled) then return end

    local head = heads[id]
    if not (head and head.obj) then return end

    now = now or GetGameTimer()

    -- Target X offset: sweep while printing, rest at 0 otherwise
    local target = 0.0
    if active then
        target = sway(now / 1000.0, headCfg.period or 2.2) * (headCfg.travel or 0.2)
    end

    -- Already at rest, nothing to move
    if not active and math.abs(head.x - target) < 8.0e-4 then
        head.last = now
        return
    end

    -- Periodic entity validity check
    if now > (head.checkedAt or 0) + 500 then
        head.checkedAt = now
        if not DoesEntityExist(head.obj) then return end
    end

    -- Smooth towards target
    local dt    = math.min((now - (head.last or now)) / 1000.0, 0.1)
    head.last   = now
    local alpha = math.min(1.0, dt * (headCfg.returnSpeed or 6.0))
    head.x      = head.x + (target - head.x) * alpha

    local coords = printer.coords
    local ox, oy = rotateOffset(printer.heading, headCfg.offset.x + head.x, headCfg.offset.y)

    SetEntityCoordsNoOffset(
        head.obj,
        coords.x + ox,
        coords.y + oy,
        coords.z + headCfg.offset.z,
        false, false, false
    )
end

-- ─────────────────────────────────────────────
-- Cleanup
-- ─────────────────────────────────────────────

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for id in pairs(heads) do
        PrinterHead.Remove(id)
    end
end)