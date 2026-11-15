local printers = {}      -- [id] = printer
local openViewers = {}  -- [printerId] = { [src] = true }
local nextId = 1        -- only used when PrinterConfig.Persistence is off

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function now()
    return os.time()
end

local function decodeJson(value)
    if type(value) ~= "string" or value == "" then
        return {}
    end

    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == "table" then
        return decoded
    end
    return {}
end

local function countOwned(identifier)
    local count = 0
    for _, printer in pairs(printers) do
        if printer.owner == identifier then
            count = count + 1
        end
    end
    return count
end

local function isOwner(src, printer)
    return printer.owner == PrinterFramework.GetIdentifier(src)
end

-- Owner, friend with access, or admin (if PrinterConfig.OwnerOnly is on)
local function canUse(src, printer)
    if not PrinterConfig.OwnerOnly then
        return true
    end

    local identifier = PrinterFramework.GetIdentifier(src)
    if printer.owner == identifier then
        return true
    end

    for _, entry in ipairs(printer.access or {}) do
        if entry.id == identifier then
            return true
        end
    end

    return PrinterFramework.IsAdmin(src)
end

local function canPickup(src, printer)
    if isOwner(src, printer) or PrinterFramework.IsAdmin(src) then
        return true
    end
    if PrinterConfig.Access.friendsCanPickup then
        return canUse(src, printer)
    end
    return false
end

local function canTheme(src, printer)
    if isOwner(src, printer) or PrinterFramework.IsAdmin(src) then
        return true
    end
    if PrinterConfig.Access.friendsCanTheme then
        return canUse(src, printer)
    end
    return false
end

local function canManage(src, printer)
    return isOwner(src, printer) or PrinterFramework.IsAdmin(src)
end

local function batteryCapacity()
    return (PrinterConfig.Battery and PrinterConfig.Battery.capacity) or 0
end

-- Prepends an entry to the battery log and trims it to the configured size
local function addLog(printer, entry)
    entry.at = now()
    table.insert(printer.log, 1, entry)

    local maxSize = (PrinterConfig.Battery and PrinterConfig.Battery.logSize) or 12
    while #printer.log > maxSize do
        table.remove(printer.log)
    end
end

-- Job restriction check for an item
local function canPrintItem(src, itemName)
    local item = PrinterConfig.Items[itemName]
    if not item then
        return false
    end

    local jobs = PrinterUtils.NormalizeJobs(item.job)
    if not jobs then
        return true
    end

    local job, grade = PrinterFramework.GetJob(src)
    for _, allowedJob in ipairs(jobs) do
        if allowedJob == job then
            if item.grade and grade < item.grade then
                return false
            end
            return true
        end
    end

    return false
end

local function isNearPrinter(src, printer)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return false
    end

    local pos = GetEntityCoords(ped)
    local distSq = PrinterUtils.DistSq(
        pos.x, pos.y, pos.z,
        printer.coords.x, printer.coords.y, printer.coords.z
    )

    return distSq <= (PrinterConfig.InteractDistance + 4.0) ^ 2
end

-- Returns the printer if it exists and the player is near it
local function getNearbyPrinter(src, printerId)
    local printer = printers[printerId]
    if printer and isNearPrinter(src, printer) then
        return printer
    end
    return nil
end

---------------------------------------------------------------------
-- Serialisation / broadcasting
---------------------------------------------------------------------

-- Client-safe view of a printer
local function publicPrinter(printer, includeLog)
    local queue = {}
    for i, job in ipairs(printer.queue) do
        queue[i] = {
            uid        = job.uid,
            item       = job.item,
            amount     = job.amount,
            dur        = job.dur,
            power      = job.power,
            startedAt  = job.startedAt,
            finishesAt = job.finishesAt,
        }
    end

    local output = {}
    for i, entry in ipairs(printer.output) do
        output[i] = {
            uid    = entry.uid,
            item   = entry.item,
            amount = entry.amount,
        }
    end

    local log
    if includeLog then
        log = {}
        for i, entry in ipairs(printer.log) do
            log[i] = {
                item = entry.item,
                wh   = entry.wh,
                at   = entry.at,
                swap = entry.swap,
            }
        end
    end

    return {
        id         = printer.id,
        owner      = printer.owner,
        ownerName  = printer.ownerName,
        coords     = printer.coords,
        heading    = printer.heading,
        theme      = printer.theme,
        queue      = queue,
        output     = output,
        maxQueue   = PrinterConfig.Queue.maxJobs,
        maxOutput  = PrinterConfig.Queue.maxOutput,
        battery    = printer.battery,
        batteryMax = batteryCapacity(),
        blocked    = printer.blocked,
        log        = log,
    }
end

local function broadcastPrinter(printer, target)
    TriggerClientEvent("rwprinter:client:updatePrinter", target or -1, publicPrinter(printer))
end

local function broadcastRemoved(printerId, target)
    TriggerClientEvent("rwprinter:client:removePrinter", target or -1, printerId)
end

-- How many of each required material (and the battery item) the player has
local function buildCounts(src)
    local counts = {}

    for _, item in pairs(PrinterConfig.Items) do
        for material in pairs(item.materials or {}) do
            if counts[material] == nil then
                counts[material] = PrinterInventory.GetCount(src, material)
            end
        end
    end

    if PrinterConfig.Battery and PrinterConfig.Battery.enabled then
        local batteryItem = PrinterConfig.Battery.item
        if counts[batteryItem] == nil then
            counts[batteryItem] = PrinterInventory.GetCount(src, batteryItem)
        end
    end

    return counts
end

-- Returns: friends with access, nearby players who could be given access
local function buildFriends(src, printer)
    local friends = {}
    for i, entry in ipairs(printer.access or {}) do
        friends[i] = { id = entry.id, name = entry.name }
    end

    local nearby = {}

    if canManage(src, printer) then
        local range = PrinterConfig.Access.pickRange or 0.0

        local known = { [printer.owner] = true }
        for _, entry in ipairs(printer.access or {}) do
            known[entry.id] = true
        end

        for _, playerId in ipairs(GetPlayers()) do
            local target = tonumber(playerId)
            if target and target ~= src then
                local eligible = true

                if range > 0 then
                    local ped = GetPlayerPed(target)
                    local pos = ped and ped ~= 0 and GetEntityCoords(ped)
                    if pos then
                        local distSq = PrinterUtils.DistSq(
                            pos.x, pos.y, pos.z,
                            printer.coords.x, printer.coords.y, printer.coords.z
                        )
                        eligible = distSq <= range ^ 2
                    end
                end

                if eligible and not known[PrinterFramework.GetIdentifier(target)] then
                    nearby[#nearby + 1] = {
                        src  = target,
                        name = PrinterFramework.GetName(target),
                    }
                end
            end
        end
    end

    return friends, nearby
end

local function buildUIState(src, printer)
    local friends, nearby = buildFriends(src, printer)
    local job, grade = PrinterFramework.GetJob(src)

    return {
        printer    = publicPrinter(printer, true),
        counts     = buildCounts(src),
        job        = job,
        grade      = grade,
        isOwner    = isOwner(src, printer),
        canManage  = canManage(src, printer),
        canTheme   = canTheme(src, printer),
        canPickup  = canPickup(src, printer),
        friends    = friends,
        nearby     = nearby,
        maxFriends = PrinterConfig.Access.maxFriends,
        serverNow  = now(),
    }
end

-- Refresh the UI of everyone who has this printer open
local function pushToViewers(printer)
    local viewers = openViewers[printer.id]
    if not viewers then return end

    for viewerSrc in pairs(viewers) do
        if GetPlayerName(viewerSrc) then
            TriggerClientEvent("rwprinter:client:refresh", viewerSrc, buildUIState(viewerSrc, printer))
        else
            viewers[viewerSrc] = nil
        end
    end
end

local function markChanged(printer)
    printer.dirty = true
    broadcastPrinter(printer)
    pushToViewers(printer)
end

---------------------------------------------------------------------
-- Persistence
---------------------------------------------------------------------

local function insertPrinter(printer, cb)
    if not PrinterConfig.Persistence then
        printer.id = nextId
        nextId = nextId + 1
        return cb(printer.id)
    end

    MySQL.insert([[
        INSERT INTO rw_3dprinters
            (owner, owner_name, x, y, z, heading, state, theme,
             queue, output, access, log, battery)
        VALUES (?, ?, ?, ?, ?, ?, 'idle', ?, '[]', '[]', '[]', '[]', ?)
    ]], {
        printer.owner,
        printer.ownerName,
        printer.coords.x,
        printer.coords.y,
        printer.coords.z,
        printer.heading,
        printer.theme,
        printer.battery,
    }, cb)
end

local function savePrinter(printer)
    if not PrinterConfig.Persistence then return end

    printer.dirty = false

    local state = "idle"
    if #printer.queue > 0 then
        state = "printing"
    elseif #printer.output > 0 then
        state = "ready"
    end

    MySQL.update([[
        UPDATE rw_3dprinters
        SET queue = ?, output = ?, access = ?, theme = ?, state = ?,
            battery = ?, log = ?
        WHERE id = ?
    ]], {
        json.encode(printer.queue),
        json.encode(printer.output),
        json.encode(printer.access),
        printer.theme,
        state,
        printer.battery,
        json.encode(printer.log),
        printer.id,
    })
end

local function deletePrinter(printerId)
    if not PrinterConfig.Persistence then return end

    MySQL.update("DELETE FROM rw_3dprinters WHERE id = ?", { printerId })
end

-- Periodically flush changed printers to the database
CreateThread(function()
    while true do
        Wait(10000)
        for _, printer in pairs(printers) do
            if printer.dirty then
                savePrinter(printer)
            end
        end
    end
end)

-- Removes a printer everywhere (memory, viewers, DB, clients)
local function removePrinter(printerId)
    printers[printerId] = nil
    openViewers[printerId] = nil
    deletePrinter(printerId)
    broadcastRemoved(printerId)
end

---------------------------------------------------------------------
-- Print queue logic
---------------------------------------------------------------------

-- Tries to start the next job. Returns true if anything changed.
local function advanceQueue(printer)
    local job = printer.queue[1]

    if not job then
        if printer.blocked then
            printer.blocked = nil
            return true
        end
        return false
    end

    -- already running
    if job.startedAt then
        return false
    end

    -- output tray full
    if #printer.output >= PrinterConfig.Queue.maxOutput then
        if printer.blocked == "output" then
            return false
        end
        printer.blocked = "output"
        return true
    end

    -- not enough battery
    if PrinterConfig.Battery and PrinterConfig.Battery.enabled then
        local power = job.power or 0
        if power > 0 and power > printer.battery then
            if printer.blocked == "battery" then
                return false
            end
            printer.blocked = "battery"
            return true
        end
    end

    printer.blocked = nil
    job.startedAt = now()
    job.finishesAt = job.startedAt + job.dur
    return true
end

-- Moves the finished first job into the output tray
local function completeJob(printer)
    local job = table.remove(printer.queue, 1)
    if not job then return end

    local power = job.power or 0
    if power > 0 then
        printer.battery = math.max(0, printer.battery - power)
        addLog(printer, { item = job.item, wh = power })
    end

    printer.seq = (printer.seq or 0) + 1
    printer.output[#printer.output + 1] = {
        uid    = printer.seq,
        item   = job.item,
        amount = job.amount,
        doneAt = now(),
    }

    PrinterUtils.Debug(("impressora %s concluiu %s"):format(printer.id, job.item))
end

-- Main tick: finish jobs whose time is up and start the next ones
CreateThread(function()
    while true do
        Wait(1000)
        local t = now()

        for _, printer in pairs(printers) do
            local changed = false

            local job = printer.queue[1]
            if job and job.finishesAt and t >= job.finishesAt then
                completeJob(printer)
                changed = true
            end

            if advanceQueue(printer) then
                changed = true
            end

            if changed then
                markChanged(printer)
            end
        end
    end
end)

-- After a restart, completes whatever finished while the server was down
local function catchUp(printer)
    while true do
        local job = printer.queue[1]
        if not job or not job.finishesAt then break end
        if now() < job.finishesAt then break end
        if #printer.output >= PrinterConfig.Queue.maxOutput then break end

        completeJob(printer)
    end

    advanceQueue(printer)
    printer.dirty = true
end

---------------------------------------------------------------------
-- Load printers from the database on start
---------------------------------------------------------------------

CreateThread(function()
    if not PrinterConfig.Persistence then return end

    local waited = 0
    while not PrinterSchemaReady and waited < 300 do
        Wait(100)
        waited = waited + 1
    end

    if not PrinterSchemaReady then
        print("^1[rwprinter] Base de dados nao ficou pronta; nada foi carregado.^0")
        return
    end

    local rows = MySQL.query.await("SELECT * FROM rw_3dprinters") or {}

    for _, row in ipairs(rows) do
        local printer = {
            id        = row.id,
            owner     = row.owner,
            ownerName = row.owner_name,
            coords    = { x = row.x, y = row.y, z = row.z },
            heading   = row.heading,
            theme     = PrinterUtils.GetTheme(row.theme).id,
            queue     = decodeJson(row.queue),
            output    = decodeJson(row.output),
            access    = decodeJson(row.access),
            log       = decodeJson(row.log),
            battery   = row.battery or batteryCapacity(),
            seq       = 0,
        }

        -- Migrate old single-job rows into the queue / output
        if #printer.queue == 0 and #printer.output == 0 and row.item then
            if row.state == "ready" then
                printer.output[1] = {
                    uid    = 1,
                    item   = row.item,
                    amount = row.amount or 1,
                    doneAt = now(),
                }
            elseif row.state == "printing" and row.finishes_at then
                printer.queue[1] = {
                    uid        = 1,
                    item       = row.item,
                    amount     = row.amount or 1,
                    dur        = math.max(1, row.finishes_at - (row.started_at or row.finishes_at)),
                    startedAt  = row.started_at,
                    finishesAt = row.finishes_at,
                }
            end
        end

        -- Keep the uid counter above every existing uid
        for _, job in ipairs(printer.queue) do
            printer.seq = math.max(printer.seq, job.uid or 0)
        end
        for _, entry in ipairs(printer.output) do
            printer.seq = math.max(printer.seq, entry.uid or 0)
        end

        catchUp(printer)
        printers[row.id] = printer
    end

    print(("^2[rwprinter] %s impressoras carregadas.^0"):format(#rows))
end)

---------------------------------------------------------------------
-- Client sync
---------------------------------------------------------------------

RegisterNetEvent("rwprinter:server:requestSync", function()
    local src = source

    local list = {}
    for _, printer in pairs(printers) do
        list[#list + 1] = publicPrinter(printer)
    end

    TriggerClientEvent("rwprinter:client:syncAll", src, list, now(), {
        items     = PrinterConfig.Items,
        materials = PrinterConfig.MaterialLabels or {},
        battery   = PrinterCatalog.ExportBattery(),
    })
end)

---------------------------------------------------------------------
-- Placing a printer
---------------------------------------------------------------------

local placeHintShown = false

-- Diagnostic output for when taking the printer item from the player fails
function PrinterReportPlaceItemFailure(src)
    local configured = PrinterUtils.PrinterItems()

    local carrying = {}
    for _, name in ipairs(configured) do
        carrying[#carrying + 1] = ("%s = %s"):format(name, PrinterInventory.GetCount(src, name))
    end

    print(("^1[rwprinter] Could not take the printer item from player %s.^0"):format(src))
    print(("^1[rwprinter]   inventory detected : %s^0"):format(PrinterInventory.name or "unknown"))
    print(("^1[rwprinter]   PrinterConfig.PrinterItem : %s^0"):format(table.concat(configured, ", ")))
    print(("^1[rwprinter]   player is carrying : %s^0"):format(table.concat(carrying, "   ")))

    if placeHintShown then return end
    placeHintShown = true

    print("^3[rwprinter]   If the count is 0 but the player can SEE the item in their^0")
    print("^3[rwprinter]   bag, the name in PrinterConfig.PrinterItem is not the name in your^0")
    print("^3[rwprinter]   inventory's items list. PrinterConfig.PrinterItem accepts a LIST:^0")
    print("^3[rwprinter]     PrinterConfig.PrinterItem = { '3dprinter', 'your_item_name' }^0")
end

RegisterNetEvent("rwprinter:server:place", function(coords, heading)
    local src = source

    if type(coords) ~= "table" or not (coords.x and coords.y and coords.z) then
        return
    end

    local identifier = PrinterFramework.GetIdentifier(src)
    if not identifier then return end

    -- per-player limit
    if PrinterConfig.MaxPrintersPerPlayer > 0 and countOwned(identifier) >= PrinterConfig.MaxPrintersPerPlayer then
        return PrinterFramework.Notify(src, PrinterL("limit_reached", PrinterConfig.MaxPrintersPerPlayer), "error")
    end

    -- player must be close to the target position
    local pos = GetEntityCoords(GetPlayerPed(src))
    local distSq = PrinterUtils.DistSq(pos.x, pos.y, pos.z, coords.x, coords.y, coords.z)
    if distSq > (PrinterConfig.Placement.maxDistance + 3.0) ^ 2 then
        PrinterUtils.Debug(("place rejeitado: %s longe demais"):format(src))
        return
    end

    -- not too close to another printer
    for _, other in pairs(printers) do
        local d = PrinterUtils.DistSq(
            other.coords.x, other.coords.y, other.coords.z,
            coords.x, coords.y, coords.z
        )
        if d < PrinterConfig.Placement.minSpacing ^ 2 then
            return PrinterFramework.Notify(src, PrinterL("place_too_close"), "error")
        end
    end

    -- take one printer item
    local takenItem
    for _, itemName in ipairs(PrinterUtils.PrinterItems()) do
        if PrinterInventory.GetCount(src, itemName) > 0 and PrinterInventory.RemoveItem(src, itemName, 1) then
            takenItem = itemName
            break
        end
    end

    if not takenItem then
        PrinterReportPlaceItemFailure(src)
        return PrinterFramework.Notify(src, PrinterL("place_no_item", PrinterUtils.PrinterItem()), "error")
    end

    local printer = {
        owner     = identifier,
        ownerName = PrinterFramework.GetName(src),
        coords    = { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 },
        heading   = (heading or 0.0) + 0.0,
        theme     = PrinterUtils.GetTheme(PrinterConfig.DefaultTheme).id,
        queue     = {},
        output    = {},
        access    = {},
        log       = {},
        battery   = (PrinterConfig.Battery and PrinterConfig.Battery.startCharge) or 0,
        seq       = 0,
    }

    insertPrinter(printer, function(newId)
        if not newId then
            -- insert failed: give the item back
            PrinterInventory.AddItem(src, takenItem, 1)
            return
        end

        printer.id = newId
        printers[newId] = printer
        broadcastPrinter(printer)
        PrinterFramework.Notify(src, PrinterL("placed"), "success")
    end)
end)

---------------------------------------------------------------------
-- Print jobs
---------------------------------------------------------------------

RegisterNetEvent("rwprinter:server:enqueue", function(printerId, itemName, amount)
    local src = source

    local printer = getNearbyPrinter(src, printerId)
    if not printer then return end

    if not canUse(src, printer) then
        return PrinterFramework.Notify(src, PrinterL("no_access"), "error")
    end

    local item = PrinterConfig.Items[itemName]
    if not item or item.enabled == false then
        return PrinterFramework.Notify(src, PrinterL("unknown_item"), "error")
    end

    if not canPrintItem(src, itemName) then
        return PrinterFramework.Notify(src, PrinterL("no_access_job"), "error")
    end

    amount = math.floor(tonumber(amount) or 1)
    amount = math.max(1, math.min(amount, PrinterConfig.Queue.maxPerOrder))

    local freeSlots = PrinterConfig.Queue.maxJobs - #printer.queue
    if freeSlots <= 0 then
        return PrinterFramework.Notify(src, PrinterL("queue_is_full", PrinterConfig.Queue.maxJobs), "error")
    end
    amount = math.min(amount, freeSlots)

    local queued = 0
    for _ = 1, amount do
        if not PrinterInventory.HasMaterials(src, item.materials) then break end
        if not PrinterInventory.TakeMaterials(src, item.materials) then break end

        -- snapshot of the materials used, for refunds
        local materials = {}
        for name, qty in pairs(item.materials or {}) do
            materials[name] = qty
        end

        printer.seq = (printer.seq or 0) + 1
        printer.queue[#printer.queue + 1] = {
            uid       = printer.seq,
            item      = itemName,
            amount    = item.amount or 1,
            dur       = PrinterUtils.GetPrintTime(itemName),
            power     = PrinterUtils.GetPower(itemName),
            materials = materials,
            by        = PrinterFramework.GetName(src),
        }

        queued = queued + 1
    end

    if queued == 0 then
        return PrinterFramework.Notify(src, PrinterL("no_materials"), "error")
    end

    advanceQueue(printer)
    markChanged(printer)

    local label = item.label or itemName
    if queued == 1 then
        PrinterFramework.Notify(src, PrinterL("print_started", label), "success")
    else
        PrinterFramework.Notify(src, PrinterL("print_queued", queued, label), "success")
    end

    if amount > queued then
        PrinterFramework.Notify(src, PrinterL("no_materials"), "warning")
    end
end)

-- Gives materials back for a cancelled job.
-- `partial` = the job had already started, so only a fraction is refunded.
local function refundMaterials(src, job, partial)
    local materials = job.materials or (PrinterConfig.Items[job.item] or {}).materials
    if not materials then return end

    local ratio = 1.0
    if partial then
        ratio = PrinterConfig.CancelRefundRatio or 0.0
    end

    PrinterInventory.RefundMaterials(src, materials, ratio)
end

RegisterNetEvent("rwprinter:server:cancelJob", function(printerId, jobUid)
    local src = source

    local printer = getNearbyPrinter(src, printerId)
    if not printer then return end

    if not canUse(src, printer) then
        return PrinterFramework.Notify(src, PrinterL("no_access"), "error")
    end

    for index, job in ipairs(printer.queue) do
        if job.uid == jobUid then
            table.remove(printer.queue, index)
            refundMaterials(src, job, job.startedAt ~= nil)
            advanceQueue(printer)
            markChanged(printer)
            return PrinterFramework.Notify(src, PrinterL("print_cancelled"), "info")
        end
    end
end)

RegisterNetEvent("rwprinter:server:clearQueue", function(printerId)
    local src = source

    local printer = getNearbyPrinter(src, printerId)
    if not printer then return end

    if not canUse(src, printer) then
        return PrinterFramework.Notify(src, PrinterL("no_access"), "error")
    end

    if #printer.queue == 0 then return end

    for _, job in ipairs(printer.queue) do
        refundMaterials(src, job, job.startedAt ~= nil)
    end

    printer.queue = {}
    advanceQueue(printer)
    markChanged(printer)
    PrinterFramework.Notify(src, PrinterL("print_cancelled"), "info")
end)

---------------------------------------------------------------------
-- Collecting output
---------------------------------------------------------------------

-- collectUid == nil -> collect everything; otherwise only that output entry
RegisterNetEvent("rwprinter:server:collect", function(printerId, collectUid)
    local src = source

    local printer = getNearbyPrinter(src, printerId)
    if not printer then return end

    if not canUse(src, printer) then
        return PrinterFramework.Notify(src, PrinterL("no_access"), "error")
    end

    if #printer.output == 0 then
        return PrinterFramework.Notify(src, PrinterL("nothing_to_collect"), "error")
    end

    local collected = {}
    local remaining = {}
    local skipped = false -- something couldn't be carried

    for _, entry in ipairs(printer.output) do
        local wanted = (collectUid == nil) or (entry.uid == collectUid)

        if wanted then
            if PrinterInventory.CanCarry(src, entry.item, entry.amount)
                and PrinterInventory.AddItem(src, entry.item, entry.amount) then
                collected[#collected + 1] = entry
            else
                skipped = true
                remaining[#remaining + 1] = entry
            end
        else
            remaining[#remaining + 1] = entry
        end
    end

    printer.output = remaining

    if #collected == 0 then
        local itemName = (remaining[1] and remaining[1].item) or PrinterUtils.PrinterItem()
        local reason = PrinterInventory.WhyAddFailed(itemName)
        return PrinterFramework.Notify(src, PrinterL(reason, itemName), "error")
    end

    advanceQueue(printer)
    markChanged(printer)

    if #collected == 1 then
        local def = PrinterConfig.Items[collected[1].item]
        PrinterFramework.Notify(src, PrinterL("collected", collected[1].amount, (def and def.label) or collected[1].item), "success")
    else
        local total = 0
        for _, entry in ipairs(collected) do
            total = total + entry.amount
        end
        PrinterFramework.Notify(src, PrinterL("collected_multi", total), "success")
    end

    if skipped then
        PrinterFramework.Notify(src, PrinterL("no_space"), "warning")
    end
end)

---------------------------------------------------------------------
-- Battery / theme
---------------------------------------------------------------------

RegisterNetEvent("rwprinter:server:swapBattery", function(printerId)
    local src = source

    local printer = getNearbyPrinter(src, printerId)
    if not printer then return end

    if not (PrinterConfig.Battery and PrinterConfig.Battery.enabled) then return end

    if not canUse(src, printer) then
        return PrinterFramework.Notify(src, PrinterL("no_access"), "error")
    end

    if printer.battery >= batteryCapacity() then
        return PrinterFramework.Notify(src, PrinterL("battery_full"), "error")
    end

    if not PrinterInventory.RemoveItem(src, PrinterConfig.Battery.item, 1) then
        return PrinterFramework.Notify(src, PrinterL("battery_missing"), "error")
    end

    printer.battery = batteryCapacity()
    addLog(printer, { swap = true, wh = printer.battery })
    advanceQueue(printer)
    markChanged(printer)

    PrinterFramework.Notify(src, PrinterL("battery_swapped"), "success")
end)

RegisterNetEvent("rwprinter:server:setTheme", function(printerId, themeId)
    local src = source

    local printer = getNearbyPrinter(src, printerId)
    if not printer then return end

    if not canTheme(src, printer) then
        return PrinterFramework.Notify(src, PrinterL("ui_owner_only"), "error")
    end

    local theme = PrinterUtils.GetTheme(themeId)
    -- ignore unknown themes (GetTheme falls back to a default) and no-op changes
    if theme.id ~= themeId or theme.id == printer.theme then
        return
    end

    printer.theme = theme.id
    markChanged(printer)
    PrinterFramework.Notify(src, PrinterL("theme_changed", theme.label), "success")
end)

---------------------------------------------------------------------
-- Friends / access
---------------------------------------------------------------------

RegisterNetEvent("rwprinter:server:grantAccess", function(printerId, targetId)
    local src = source

    local printer = getNearbyPrinter(src, printerId)
    if not printer then return end

    if not canManage(src, printer) then
        return PrinterFramework.Notify(src, PrinterL("ui_owner_only"), "error")
    end

    local target = tonumber(targetId)
    if not target or not GetPlayerName(target) then
        return PrinterFramework.Notify(src, PrinterL("friend_not_found"), "error")
    end

    if target == src then
        return PrinterFramework.Notify(src, PrinterL("friend_self"), "error")
    end

    -- target must be near the printer, or within pickRange of it
    if not isNearPrinter(target, printer) then
        local range = PrinterConfig.Access.pickRange or 0.0
        if range > 0 then
            local ped = GetPlayerPed(target)
            local pos = ped and ped ~= 0 and GetEntityCoords(ped)

            local inRange = false
            if pos then
                local distSq = PrinterUtils.DistSq(
                    pos.x, pos.y, pos.z,
                    printer.coords.x, printer.coords.y, printer.coords.z
                )
                inRange = distSq <= range ^ 2
            end

            if not inRange then
                return PrinterFramework.Notify(src, PrinterL("friend_not_found"), "error")
            end
        end
    end

    local targetIdentifier = PrinterFramework.GetIdentifier(target)
    if not targetIdentifier then
        return PrinterFramework.Notify(src, PrinterL("friend_not_found"), "error")
    end

    if targetIdentifier == printer.owner then
        return PrinterFramework.Notify(src, PrinterL("friend_exists"), "error")
    end

    for _, entry in ipairs(printer.access) do
        if entry.id == targetIdentifier then
            return PrinterFramework.Notify(src, PrinterL("friend_exists"), "error")
        end
    end

    if #printer.access >= PrinterConfig.Access.maxFriends then
        return PrinterFramework.Notify(src, PrinterL("friend_limit", PrinterConfig.Access.maxFriends), "error")
    end

    local targetName = PrinterFramework.GetName(target)
    printer.access[#printer.access + 1] = { id = targetIdentifier, name = targetName }

    markChanged(printer)
    PrinterFramework.Notify(src, PrinterL("friend_added", targetName), "success")
end)

RegisterNetEvent("rwprinter:server:revokeAccess", function(printerId, friendId)
    local src = source

    local printer = getNearbyPrinter(src, printerId)
    if not printer then return end

    if not canManage(src, printer) then
        return PrinterFramework.Notify(src, PrinterL("ui_owner_only"), "error")
    end

    for index, entry in ipairs(printer.access) do
        if entry.id == friendId then
            table.remove(printer.access, index)
            markChanged(printer)
            return PrinterFramework.Notify(src, PrinterL("friend_removed", entry.name or "?"), "info")
        end
    end
end)

---------------------------------------------------------------------
-- Pickup
---------------------------------------------------------------------

RegisterNetEvent("rwprinter:server:pickup", function(printerId)
    local src = source

    local printer = getNearbyPrinter(src, printerId)
    if not printer then return end

    if not canPickup(src, printer) then
        return PrinterFramework.Notify(src, PrinterL("not_owner"), "error")
    end

    -- refund queued jobs
    for _, job in ipairs(printer.queue) do
        refundMaterials(src, job, job.startedAt ~= nil)
    end

    -- hand over finished prints
    for _, entry in ipairs(printer.output) do
        PrinterInventory.AddItem(src, entry.item, entry.amount)
    end

    if PrinterConfig.ReturnItemOnPickup then
        PrinterInventory.AddItem(src, PrinterUtils.PrinterItem(), 1)
    end

    removePrinter(printerId)
    PrinterFramework.Notify(src, PrinterL("picked_up"), "success")
end)

---------------------------------------------------------------------
-- UI open / close / refresh
---------------------------------------------------------------------

RegisterNetEvent("rwprinter:server:openUI", function(printerId)
    local src = source

    local printer = getNearbyPrinter(src, printerId)
    if not printer then return end

    if not canUse(src, printer) then
        return PrinterFramework.Notify(src, PrinterL("no_access"), "error")
    end

    openViewers[printerId] = openViewers[printerId] or {}
    openViewers[printerId][src] = true

    TriggerClientEvent("rwprinter:client:openUI", src, buildUIState(src, printer))
end)

RegisterNetEvent("rwprinter:server:closeUI", function(printerId)
    local src = source

    if openViewers[printerId] then
        openViewers[printerId][src] = nil
    end
end)

RegisterNetEvent("rwprinter:server:refresh", function(printerId)
    local src = source

    local printer = getNearbyPrinter(src, printerId)
    if not printer then return end

    if not canUse(src, printer) then return end

    TriggerClientEvent("rwprinter:client:refresh", src, buildUIState(src, printer))
end)

---------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------

AddEventHandler("playerDropped", function()
    local src = source
    for _, viewers in pairs(openViewers) do
        viewers[src] = nil
    end
end)

-- Flush unsaved printers when the resource stops
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, printer in pairs(printers) do
        if printer.dirty then
            savePrinter(printer)
        end
    end
end)

---------------------------------------------------------------------
-- Exports / public API
---------------------------------------------------------------------

exports("GetPrinters", function()
    local result = {}
    for id, printer in pairs(printers) do
        result[id] = publicPrinter(printer, true)
    end
    return result
end)

exports("GetPrinter", function(printerId)
    local printer = printers[printerId]
    return printer and publicPrinter(printer, true) or nil
end)

exports("RemovePrinter", function(printerId)
    if not printers[printerId] then
        return false
    end

    removePrinter(printerId)
    return true
end)

function PrinterGetAllPrinters()
    return printers
end

PrinterOps = {
    Public = publicPrinter,

    Get = function(printerId)
        return printers[printerId]
    end,

    Remove = function(printerId)
        if not printers[printerId] then
            return false
        end

        removePrinter(printerId)
        return true
    end,

    ClearQueue = function(printerId)
        local printer = printers[printerId]
        if not printer then
            return false
        end

        printer.queue = {}
        printer.blocked = nil
        markChanged(printer)
        return true
    end,

    Refill = function(printerId)
        local printer = printers[printerId]
        if not printer then
            return false
        end

        printer.battery = batteryCapacity()
        addLog(printer, { swap = true, wh = printer.battery })
        advanceQueue(printer)
        markChanged(printer)
        return true
    end,
}

function PrinterClearAllPrinters()
    local count = 0
    for printerId in pairs(printers) do
        removePrinter(printerId)
        count = count + 1
    end
    return count
end