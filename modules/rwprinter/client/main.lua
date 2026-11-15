ClientPrinters = {}   -- [printerId] = { data = <server printer table>, obj = <entity>, lastState = <string> }
PrinterPaused = false

local uiOpen = false
local currentPrinterId = nil

-- Server time sync (seconds), anchored to a local GetGameTimer() value
local serverTimeBase = 0
local localTimeBase = 0

local propHash
local propLoaded = false
local cachedUiData = nil

-- ─────────────────────────────────────────────
-- Time sync
-- ─────────────────────────────────────────────

local function getServerNow(now)
    if serverTimeBase == 0 then return 0 end
    return serverTimeBase + math.floor(((now or GetGameTimer()) - localTimeBase) / 1000)
end

local function syncServerTime(serverNow)
    if not serverNow then return end
    serverTimeBase = serverNow
    localTimeBase = GetGameTimer()
end

-- ─────────────────────────────────────────────
-- Printer state helpers
-- ─────────────────────────────────────────────

-- "printing" | "ready" | "idle"
local function getState(printer)
    if printer.queue and #printer.queue > 0 then return "printing" end
    if printer.output and #printer.output > 0 then return "ready" end
    return "idle"
end

-- 0.0 - 1.0 progress of the first job in queue
local function getProgress(printer, serverNow)
    local job = printer.queue and printer.queue[1]

    if not (job and job.startedAt and job.finishesAt and serverNow > 0) then
        return 0.0
    end

    local duration = job.finishesAt - job.startedAt
    if duration <= 0 then return 1.0 end

    return math.min(math.max((serverNow - job.startedAt) / duration, 0.0), 1.0)
end

local function getThemeRgb(printer)
    return PrinterUtils.GetTheme(printer.theme).rgb
end

-- ─────────────────────────────────────────────
-- Printer prop spawn / despawn
-- ─────────────────────────────────────────────

local function ensurePropModel()
    if propLoaded then return true end

    propHash = joaat(PrinterConfig.PropModel)
    if not (IsModelInCdimage(propHash) and IsModelValid(propHash)) then
        return false
    end

    RequestModel(propHash)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(propHash) and GetGameTimer() < deadline do
        Wait(20)
    end

    propLoaded = HasModelLoaded(propHash)
    return propLoaded
end

local function spawnPrinter(entry)
    if entry.obj and DoesEntityExist(entry.obj) then return end
    if not ensurePropModel() then return end

    local coords = entry.data.coords
    local obj = CreateObjectNoOffset(propHash, coords.x, coords.y, coords.z, false, false, false)

    SetEntityHeading(obj, entry.data.heading or 0.0)
    SetEntityAsMissionEntity(obj, true, true)

    if PrinterConfig.Physics.static then
        FreezeEntityPosition(obj, true)
        SetEntityHasGravity(obj, false)
        SetEntityInvincible(obj, true)
        SetEntityCanBeDamaged(obj, false)
        SetEntityRecordsCollisions(obj, false)
        SetEntityProofs(obj, true, true, true, false, true, true, false, true)
    end

    SetEntityCollision(obj, not PrinterConfig.Physics.noCollision, true)

    entry.obj = obj
    PrinterHead.Ensure(entry.data.id, entry.data)
end

local function despawnPrinter(entry)
    if entry.obj and DoesEntityExist(entry.obj) then
        DeleteEntity(entry.obj)
    end
    entry.obj = nil

    if entry.data then
        PrinterHead.Remove(entry.data.id)
    end
end

local function forgetPrinter(id)
    local entry = ClientPrinters[id]
    if not entry then return end

    despawnPrinter(entry)
    ClientPrinters[id] = nil
    PrintFX.Forget(id)
    PrinterHead.Remove(id)
end

local function setPrinterData(printer)
    ClientPrinters[printer.id] = ClientPrinters[printer.id] or {}
    ClientPrinters[printer.id].data = printer
end

-- ─────────────────────────────────────────────
-- NUI payload
-- ─────────────────────────────────────────────

-- NUI field name -> locale key
local LOCALE_KEYS = {
    title = "ui_title", subtitle = "ui_subtitle", close = "ui_close", search = "ui_search",

    navItems = "nav_items", navItemsSub = "nav_items_sub",
    navQueue = "nav_queue", navQueueSub = "nav_queue_sub",
    navSettings = "nav_settings", navSettingsSub = "nav_settings_sub",
    navBattery = "nav_battery", navBatterySub = "nav_battery_sub",

    stateOnline = "state_online", stateOnlineSub = "state_online_sub",
    stateBusy = "state_busy", stateBusySub = "state_busy_sub",
    stateReady = "state_ready", stateReadySub = "state_ready_sub",

    itemsTitle = "ui_items_title", itemsSub = "ui_items_sub",
    time = "ui_time", output = "ui_output", materials = "ui_materials", print = "ui_print",
    selectItem = "ui_select_item", selectItemSub = "ui_select_item_sub",
    noResults = "ui_no_results", noMaterials = "no_materials", noAccessJob = "no_access_job",

    batteryTitle = "ui_battery_title", batterySub = "ui_battery_sub",
    batteryLeft = "ui_battery_left", batteryEmpty = "ui_battery_empty",
    batteryEmptyS = "ui_battery_emptys", batterySwap = "ui_battery_swap",
    batteryHave = "ui_battery_have", batteryNone = "ui_battery_none",
    batteryFull = "ui_battery_full", batteryPrints = "ui_battery_prints",
    batterySwapped = "ui_battery_swapped", batteryWarn = "ui_battery_warn",
    batteryStop = "ui_battery_stop",
    power = "ui_power", powerDraw = "ui_power_draw",

    queueTitle = "ui_queue_title", queueSub = "ui_queue_sub",
    queueEmpty = "ui_queue_empty", queueEmptySub = "ui_queue_empty_sub",
    queueActive = "ui_queue_active", queueWaiting = "ui_queue_waiting",
    queuePosition = "ui_queue_position", queueStarts = "ui_queue_starts",
    queueCancel = "ui_queue_cancel", queueClear = "ui_queue_clear",
    queueRemaining = "ui_queue_remaining", queueTotal = "ui_queue_total",
    queueFull = "queue_is_full",

    trayTitle = "ui_tray_title", traySub = "ui_tray_sub", trayEmpty = "ui_tray_empty",
    trayFull = "output_is_full",
    collect = "ui_collect", collectAll = "ui_collect_all",
    selectJob = "ui_select_job", selectJobSub = "ui_select_job_sub",

    printing = "printing", complete = "print_complete",
    barRemaining = "bar_remaining", barComplete = "bar_complete",

    settingsTitle = "ui_settings_title", settingsSub = "ui_settings_sub",
    setAccess = "ui_set_access", setAccessSub = "ui_set_access_sub",
    setTheme = "ui_set_theme", setThemeSub = "ui_set_theme_sub",
    setRemove = "ui_set_remove", setRemoveSub = "ui_set_remove_sub",

    accessTitle = "ui_access_title", accessSub = "ui_access_sub",
    accessOwner = "ui_access_owner", accessList = "ui_access_list",
    accessNone = "ui_access_none", accessNearby = "ui_access_nearby",
    accessNoNear = "ui_access_no_near", accessHint = "ui_access_hint",
    accessAdd = "ui_access_add", accessRevoke = "ui_access_revoke",

    themeTitle = "ui_theme_title", themeSub = "ui_theme_sub",

    removeTitle = "ui_remove_title", removeSub = "ui_remove_sub",
    removeWarn = "ui_remove_warn", removeTray = "ui_remove_tray",
    removeBusy = "ui_remove_busy", removeConfirm = "ui_remove_confirm",
    ownerOnly = "ui_owner_only",
}

local function buildUiData()
    if cachedUiData then return cachedUiData end

    local data = {
        items      = PrinterUtils.BuildItemList(),
        categories = PrinterUtils.BuildCategoryList(),
        themes     = PrinterUtils.BuildThemeList(),
    }

    local battery = PrinterConfig.Battery
    if battery and battery.enabled then
        data.battery = {
            item      = battery.item,
            itemLabel = PrinterL("battery_item"),
            itemImage = PrinterUtils.GetRawImage(battery.item),
            capacity  = battery.capacity,
            maxWatts  = battery.maxWatts,
            warnBelow = battery.warnBelow,
        }
    end

    data.limits = {
        maxPerOrder = PrinterConfig.Queue.maxPerOrder,
        maxJobs     = PrinterConfig.Queue.maxJobs,
        maxOutput   = PrinterConfig.Queue.maxOutput,
        maxFriends  = PrinterConfig.Access.maxFriends,
    }

    data.ui = {
        animSpeed  = PrinterConfig.UI.animSpeed,
        notifyTime = PrinterConfig.UI.notifyTime,
    }

    local locale = {}
    for field, key in pairs(LOCALE_KEYS) do
        locale[field] = PrinterL(key)
    end
    data.locale = locale

    cachedUiData = data
    return data
end

PrinterCatalog.OnChange(function()
    cachedUiData = nil
    if uiOpen then
        SendNUIMessage({
            action     = "catalog",
            items      = PrinterUtils.BuildItemList(),
            categories = PrinterUtils.BuildCategoryList(),
        })
    end
end)

-- ─────────────────────────────────────────────
-- UI open / close
-- ─────────────────────────────────────────────

function PrinterCloseUI()
    if not uiOpen then return end

    local previousId = currentPrinterId
    uiOpen = false
    currentPrinterId = nil

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })

    if previousId then
        TriggerServerEvent("rwprinter:server:closeUI", previousId)
    end
end

-- ─────────────────────────────────────────────
-- Server -> Client events
-- ─────────────────────────────────────────────

RegisterNetEvent("rwprinter:client:openUI", function(data)
    if uiOpen or PrinterEditorOpen then return end

    uiOpen = true
    currentPrinterId = data.printer.id
    syncServerTime(data.serverNow)
    setPrinterData(data.printer)

    SetNuiFocus(true, true)

    local payload = { action = "open" }
    for k, v in pairs(buildUiData()) do payload[k] = v end
    for k, v in pairs(data) do payload[k] = v end

    SendNUIMessage(payload)
end)

RegisterNetEvent("rwprinter:client:refresh", function(data)
    if not (uiOpen and currentPrinterId == data.printer.id) then return end

    syncServerTime(data.serverNow)
    setPrinterData(data.printer)

    data.action = "refresh"
    SendNUIMessage(data)
end)

RegisterNetEvent("rwprinter:client:syncAll", function(printers, serverNow, catalogData)
    syncServerTime(serverNow)

    if type(catalogData) == "table" then
        PrinterCatalog.Apply(catalogData.items, catalogData.materials)
        if catalogData.battery then
            PrinterCatalog.ApplyBattery(catalogData.battery)
        end
    end

    local seen = {}
    for _, printer in ipairs(printers) do
        seen[printer.id] = true
    end

    for id in pairs(ClientPrinters) do
        if not seen[id] then forgetPrinter(id) end
    end

    for _, printer in ipairs(printers) do
        setPrinterData(printer)
    end
end)

RegisterNetEvent("rwprinter:client:updatePrinter", function(printer)
    setPrinterData(printer)
end)

RegisterNetEvent("rwprinter:client:catalog", function(items, materials, battery)
    if type(items) ~= "table" then return end

    PrinterCatalog.Apply(items, materials)
    if type(battery) == "table" then
        PrinterCatalog.ApplyBattery(battery)
    end
end)

RegisterNetEvent("rwprinter:client:removePrinter", function(id)
    if uiOpen and currentPrinterId == id then
        PrinterCloseUI()
    end
    forgetPrinter(id)
end)

-- ─────────────────────────────────────────────
-- NUI callbacks
-- ─────────────────────────────────────────────

-- Builds a callback that forwards to a server event as (event, printerId, data.value, data.extra)
local function makeServerCallback(event, closeAfter)
    return function(data, cb)
        if currentPrinterId then
            TriggerServerEvent(event, currentPrinterId, data and data.value, data and data.extra)
        end
        if closeAfter then PrinterCloseUI() end
        cb({ ok = true })
    end
end

RegisterNUICallback("close", function(_, cb)
    PrinterCloseUI()
    cb({ ok = true })
end)

RegisterNUICallback("enqueue", function(data, cb)
    if currentPrinterId and data and data.item then
        TriggerServerEvent("rwprinter:server:enqueue", currentPrinterId, data.item, data.qty or 1)
    end
    cb({ ok = true })
end)

RegisterNUICallback("cancelJob", function(data, cb)
    if currentPrinterId and data and data.uid then
        TriggerServerEvent("rwprinter:server:cancelJob", currentPrinterId, data.uid)
    end
    cb({ ok = true })
end)

RegisterNUICallback("clearQueue", makeServerCallback("rwprinter:server:clearQueue"))

RegisterNUICallback("collect", function(data, cb)
    if currentPrinterId then
        TriggerServerEvent("rwprinter:server:collect", currentPrinterId, data and data.uid)
    end
    cb({ ok = true })
end)

RegisterNUICallback("swapBattery", function(_, cb)
    if currentPrinterId then
        TriggerServerEvent("rwprinter:server:swapBattery", currentPrinterId)
    end
    cb({ ok = true })
end)

RegisterNUICallback("setTheme", function(data, cb)
    if currentPrinterId and data and data.theme then
        TriggerServerEvent("rwprinter:server:setTheme", currentPrinterId, data.theme)
    end
    cb({ ok = true })
end)

RegisterNUICallback("grantAccess", function(data, cb)
    if currentPrinterId and data and data.src then
        TriggerServerEvent("rwprinter:server:grantAccess", currentPrinterId, data.src)
    end
    cb({ ok = true })
end)

RegisterNUICallback("revokeAccess", function(data, cb)
    if currentPrinterId and data and data.id then
        TriggerServerEvent("rwprinter:server:revokeAccess", currentPrinterId, data.id)
    end
    cb({ ok = true })
end)

RegisterNUICallback("refresh", function(_, cb)
    if currentPrinterId then
        TriggerServerEvent("rwprinter:server:refresh", currentPrinterId)
    end
    cb({ ok = true })
end)

RegisterNUICallback("pickup", function(_, cb)
    if currentPrinterId then
        TriggerServerEvent("rwprinter:server:pickup", currentPrinterId)
    end
    PrinterCloseUI()
    cb({ ok = true })
end)

-- ─────────────────────────────────────────────
-- Proximity thread: spawn / despawn printer props
-- ─────────────────────────────────────────────

CreateThread(function()
    local activeDistSq = PrinterConfig.ActiveDistance ^ 2

    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local anyNear = false

        for _, entry in pairs(ClientPrinters) do
            local c = entry.data.coords
            local distSq = PrinterUtils.DistSq(playerCoords.x, playerCoords.y, playerCoords.z, c.x, c.y, c.z)

            if distSq < activeDistSq then
                anyNear = true
                spawnPrinter(entry)
            elseif entry.obj then
                despawnPrinter(entry)
            end
        end

        Wait(anyNear and 1000 or 2500)
    end
end)

-- ─────────────────────────────────────────────
-- Main render thread (FX, head animation, progress bars, battery bars, prompt)
-- ─────────────────────────────────────────────

CreateThread(function()
    local progressItems, batteryItems = {}, {}   -- lists handed to PrinterProgress.Render
    local progressPool, batteryPool = {}, {}     -- reusable slot tables
    local nextPromptAt = 0
    local nextDataAt = 0

    local function getSlot(pool, index)
        local slot = pool[index]
        if not slot then
            slot = {}
            pool[index] = slot
        end
        return slot
    end

    local activeDistSq   = PrinterConfig.ActiveDistance * PrinterConfig.ActiveDistance
    local renderDist     = PrinterConfig.RenderDistance
    local renderDistSq   = renderDist * renderDist
    local fxDist         = renderDist + 4.0
    local fxDistSq       = fxDist * fxDist
    local barHeight      = PrinterConfig.PrintVisual.barHeight or 1.75
    local batteryDrop    = PrinterConfig.UI.batteryDrop or 78

    local soundCfg       = PrinterConfig.PrintVisual.sound
    local soundEnabled   = (soundCfg and soundCfg.enabled) or false
    local soundDistance  = (soundCfg and soundCfg.distance) or 12.0

    local occlusionMask  = PrinterConfig.UI.occlusionMask or 15
    local promptOcclusion = PrinterConfig.UI.promptOcclusion
    local promptZ        = (PrinterConfig.PrintVisual.bedOffset.z or 0.37) + 0.75
    local maxWatts       = (PrinterConfig.Battery and PrinterConfig.Battery.maxWatts) or 0
    local interactDist   = PrinterConfig.InteractDistance
    local interactNear   = interactDist + 2.0
    local interactKey    = PrinterConfig.Keys.interact
    local EPS            = 1.2e-4

    while true do
        local wait = 500
        local now = GetGameTimer()

        local dataTick = nextDataAt <= now
        if dataTick then
            nextDataAt = now + 125
            PrinterProgress.Prune(now)
        end

        -- NOTE: the decompiler mangled this expression; this is the intended meaning
        local canShow = not (uiOpen or PrinterPlacement.active or PrinterEditorOpen or PrinterPaused)

        local playerCoords = GetEntityCoords(PlayerPedId())
        local px, py, pz = playerCoords.x, playerCoords.y, playerCoords.z

        local nearestId, nearestDist = nil, math.huge
        local soundId, soundBest = nil, math.huge
        local soundX, soundY, soundHeading = 0.0, 0.0, 0.0
        local progressCount, batteryCount = 0, 0
        local moved, dirty = false, false
        local serverNow = getServerNow(now)

        for id, entry in pairs(ClientPrinters) do
            local data = entry.data
            local pc = data.coords
            local distSq = PrinterUtils.DistSq(px, py, pz, pc.x, pc.y, pc.z)

            if activeDistSq > distSq then
                local state = getState(data)
                local dist = math.sqrt(distSq)
                local inRender = renderDistSq > distSq

                if state ~= entry.lastState then
                    if state == "idle" then PrintFX.Clear(id) end
                    entry.lastState = state
                    dirty = true
                end

                if canShow and inRender and nearestDist > dist then
                    nearestId, nearestDist = id, dist
                end

                local progress = 0.0
                if state ~= "idle" then
                    progress = (state == "ready") and 1.0 or getProgress(data, serverNow)
                end

                if inRender then
                    PrinterHead.Update(id, data, state == "printing", now)
                    wait = 0
                end

                -- Print FX (particles/glow on the bed)
                local bedX, bedY, bedHeading
                if state ~= "idle" and fxDistSq > distSq then
                    wait = 0
                    bedX, bedY, bedHeading = PrintFX.BedWorld(pc, data.heading)
                    PrintFX.Draw(data, state, progress, getThemeRgb(data), dist, now, bedX, bedY, bedHeading)

                    if soundEnabled and state == "printing" and soundDistance > dist and soundBest > dist then
                        soundId, soundBest = id, dist
                        soundX, soundY, soundHeading = bedX, bedY, bedHeading
                    end
                end

                local showProgress = canShow and inRender and state ~= "idle"
                local showBattery = canShow and inRender and data.batteryMax and data.batteryMax > 0

                if showProgress or showBattery then
                    wait = 0

                    if not bedX then
                        bedX, bedY, bedHeading = PrintFX.BedWorld(pc, data.heading)
                    end

                    local onScreen, sx, sy = PrinterProgress.Project(bedX, bedY, pc.z + barHeight)
                    if onScreen then
                        local scale = PrinterProgress.ScaleFor(dist)
                        local alpha = PrinterProgress.AlphaFor(dist)
                            * PrinterProgress.Sight(id, bedX, bedY, pc.z + barHeight, occlusionMask, now)

                        -- PrinterProgress bar slot
                        if showProgress then
                            progressCount = progressCount + 1
                            local slot = getSlot(progressPool, progressCount)
                            local idChanged = slot.id ~= id

                            if idChanged then
                                dirty = true
                            elseif math.abs((slot.x or -9) - sx) > EPS
                                or math.abs((slot.y or -9) - sy) > EPS
                                or math.abs((slot.alpha or -9) - alpha) > 0.004 then
                                moved = true
                            end

                            slot.id, slot.x, slot.y = id, sx, sy
                            slot.scale, slot.alpha = scale, alpha

                            if dataTick or idChanged then
                                local job = data.queue and data.queue[1]

                                local remain = 0
                                if job and job.finishesAt and serverNow > 0 then
                                    remain = math.max(0, job.finishesAt - serverNow)
                                end

                                local itemName = (job and job.item)
                                    or (data.output and data.output[1] and data.output[1].item)
                                local cfgItem = itemName and PrinterConfig.Items[itemName]
                                local label = (cfgItem and cfgItem.label) or itemName

                                local queued = data.queue and #data.queue or 0
                                local blocked = data.blocked == "battery"

                                if math.abs((slot.pct or -9) - progress) > 8.0e-4
                                    or slot.state ~= state
                                    or slot.remain ~= remain
                                    or slot.item ~= label
                                    or slot.queued ~= queued
                                    or slot.blocked ~= blocked then
                                    dirty = true
                                end

                                slot.pct, slot.state, slot.item = progress, state, label
                                slot.remain, slot.queued, slot.blocked = remain, queued, blocked
                            end

                            progressItems[progressCount] = slot
                        end

                        -- Battery bar slot
                        if showBattery then
                            batteryCount = batteryCount + 1
                            local slot = getSlot(batteryPool, batteryCount)
                            local idChanged = slot.id ~= id

                            if idChanged then
                                dirty = true
                            elseif math.abs((slot.x or -9) - sx) > EPS
                                or math.abs((slot.y or -9) - sy) > EPS
                                or math.abs((slot.alpha or -9) - alpha) > 0.004 then
                                moved = true
                            end

                            slot.id, slot.x, slot.y = id, sx, sy
                            slot.scale, slot.alpha = scale, alpha
                            slot.drop = batteryDrop

                            if dataTick or idChanged then
                                local job = (state == "printing") and data.queue[1] or nil

                                -- Wh consumed so far by the running job
                                local usedWh = job and ((job.power or 0) * progress) or 0
                                local remainingWh = math.max(0, (data.battery or 0) - usedWh)
                                local level = remainingWh / data.batteryMax

                                local watts = 0
                                if job then
                                    watts = PrinterUtils.GetDraw(job.item, progress, math.sin(now / 700.0)) or 0
                                end

                                local blocked = data.blocked == "battery"

                                if math.abs((slot.level or -9) - level) > 0.002
                                    or slot.watts ~= watts
                                    or slot.blocked ~= blocked then
                                    dirty = true
                                end

                                slot.level = level
                                slot.wh = math.floor(remainingWh + 0.5)
                                slot.max = data.batteryMax
                                slot.watts = watts
                                slot.maxWatts = maxWatts
                                slot.blocked = blocked
                            end

                            batteryItems[batteryCount] = slot
                        end
                    end
                end
            end
        end

        -- Trim stale slots
        if #progressItems ~= progressCount or #batteryItems ~= batteryCount then
            dirty = true
        end
        for i = progressCount + 1, #progressItems do progressItems[i] = nil end
        for i = batteryCount + 1, #batteryItems do batteryItems[i] = nil end

        PrintFX.Sound(soundId, soundBest, soundX, soundY, soundHeading, now)

        if interactNear > nearestDist then wait = 0 end

        if canShow then
            PrinterProgress.Render(progressItems, batteryItems, moved, dirty)

            -- Interaction prompt
            local canPrompt = nearestId ~= nil and interactDist > nearestDist

            if canPrompt and promptOcclusion then
                local entry = ClientPrinters[nearestId]
                local coords = entry and entry.data.coords
                if coords then
                    local bx, by = PrintFX.BedWorld(coords, entry.data.heading)
                    local _, occluded = PrinterProgress.Sight(-nearestId, bx, by, coords.z + promptZ, 1, now)
                    canPrompt = not occluded
                end
            end

            if canPrompt then
                PrinterTextUI.Show("E", PrinterL("access_printer"))

                if nextPromptAt < now and IsDisabledControlJustPressed(0, interactKey) then
                    nextPromptAt = now + 600

                    local entry = ClientPrinters[nearestId]
                    local coords = entry and entry.data.coords
                    local allowed = true

                    if coords and promptOcclusion then
                        local bx, by = PrintFX.BedWorld(coords, entry.data.heading)
                        allowed = not PrinterProgress.Blocked(bx, by, coords.z + promptZ, 1)
                    end

                    if allowed then
                        TriggerServerEvent("rwprinter:server:openUI", nearestId)
                    end
                end
            else
                PrinterTextUI.Hide()
            end
        else
            PrinterProgress.Clear()
            PrinterTextUI.Hide()
        end

        Wait(wait)
    end
end)

-- ─────────────────────────────────────────────
-- Pause menu tracking
-- ─────────────────────────────────────────────

CreateThread(function()
    if PrinterConfig.UI.hideOnPause == false then return end

    while true do
        local paused = IsPauseMenuActive() or GetPauseMenuState() ~= 0

        if paused ~= PrinterPaused then
            PrinterPaused = paused
            SendNUIMessage({ action = "paused", on = paused })
        end

        Wait(150)
    end
end)

-- ─────────────────────────────────────────────
-- /printerdebug  (collision / raycast diagnostics)
-- ─────────────────────────────────────────────

RegisterCommand("printerdebug", function()
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)

    -- Nearest known printer
    local nearest, nearestDist = nil, math.huge
    for _, entry in pairs(ClientPrinters) do
        local c = entry.data.coords
        local d = #(pCoords - vector3(c.x, c.y, c.z))
        if d < nearestDist then
            nearest, nearestDist = entry, d
        end
    end

    if not nearest then
        print("^3[3dprinter] nenhuma impressora conhecida pelo cliente^0")
        return
    end

    print("^5--- rwprinter ---^0")
    print(("  impressora #%s a %.2f m"):format(nearest.data.id, nearestDist))
    print(("  estado: %s | fila: %s | tabuleiro: %s | tema: %s"):format(
        getState(nearest.data),
        #(nearest.data.queue or {}),
        #(nearest.data.output or {}),
        tostring(nearest.data.theme)
    ))
    print(("  objeto criado: %s"):format(tostring(nearest.obj ~= nil)))
    print(("  peca na cama: %s"):format(PrintFX.Debug(nearest.data.id)))

    if not (nearest.obj and DoesEntityExist(nearest.obj)) then
        print("^1  o objeto nao existe -- o modelo nao carregou^0")
        return
    end

    print(("  modelo: %s  |  estatico: %s"):format(
        GetEntityModel(nearest.obj),
        tostring(IsEntityStatic(nearest.obj))
    ))
    print(("  colisao carregada a volta: %s"):format(tostring(HasCollisionLoadedAroundEntity(nearest.obj))))
    print(("  colisao desativada na entidade: %s"):format(tostring(GetEntityCollisionDisabled(nearest.obj))))

    -- Shoots a LOS ray from the player at an entity and reports whether it hits
    local function rayTest(entity, label, ignoreEntity)
        local from = vector3(pCoords.x, pCoords.y, pCoords.z + 0.6)
        local ec = GetEntityCoords(entity)
        local to = vector3(ec.x, ec.y, ec.z + 0.6)

        local handle = StartShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, -1, ignoreEntity, 7)

        local status, hit, hitEntity = 1, false, 0
        local deadline = GetGameTimer() + 1000
        repeat
            Wait(0)
            status, hit, _, _, hitEntity = GetShapeTestResult(handle)
            if status ~= 1 then break end
        until deadline < GetGameTimer()

        if hit and hitEntity == entity then
            print(("^2  %s: raycast ACERTOU^0"):format(label))
            return true
        elseif hit then
            print(("^3  %s: acertou noutra entidade (%s)^0"):format(label, hitEntity))
        else
            print(("^1  %s: ATRAVESSOU^0"):format(label))
        end
        return false
    end

    -- Self-test: ray straight down to the ground
    local selfHandle = StartShapeTestLosProbe(
        pCoords.x, pCoords.y, pCoords.z + 0.5,
        pCoords.x, pCoords.y, pCoords.z - 3.0,
        -1, ped, 7
    )
    local selfStatus, selfHit = 1, false
    local selfDeadline = GetGameTimer() + 1000
    repeat
        Wait(0)
        selfStatus, selfHit = GetShapeTestResult(selfHandle)
        if selfStatus ~= 1 then break end
    until selfDeadline < GetGameTimer()

    print(("  auto-teste (raio para o chao): %s"):format(
        selfHit and "^2OK, o diagnostico funciona^0" or "^1FALHOU -- ignora o resto^0"
    ))

    rayTest(nearest.obj, "impressora", ped)

    -- Control: spawn a vanilla barrel and run the same test
    local barrelHash = joaat("prop_barrel_02a")
    RequestModel(barrelHash)
    local loadDeadline = GetGameTimer() + 3000
    while not HasModelLoaded(barrelHash) and GetGameTimer() < loadDeadline do
        Wait(10)
    end

    if not HasModelLoaded(barrelHash) then
        print("^3  controlo: nao consegui carregar prop_barrel_02a^0")
        return
    end

    local fwd = GetEntityForwardVector(ped)
    local barrel = CreateObject(
        barrelHash,
        pCoords.x + fwd.x * 2.0,
        pCoords.y + fwd.y * 2.0,
        pCoords.z - 0.9,
        false, false, false
    )

    FreezeEntityPosition(barrel, true)
    SetEntityHasGravity(barrel, false)
    SetEntityInvincible(barrel, true)
    SetEntityCanBeDamaged(barrel, false)
    SetEntityRecordsCollisions(barrel, false)
    SetEntityProofs(barrel, true, true, true, false, true, true, false, true)
    SetEntityCollision(barrel, true, true)

    Wait(250)
    rayTest(barrel, "controlo (barril vanilla, mesmo codigo)", ped)

    DeleteEntity(barrel)
    SetModelAsNoLongerNeeded(barrelHash)

    print("^5  --> se o controlo acertou e a impressora nao, a falha esta no .ydr^0")
    print("^5  --> se ambos atravessaram, a falha esta no codigo de criacao^0")
end, false)

-- ─────────────────────────────────────────────
-- Startup sync / cleanup
-- ─────────────────────────────────────────────

CreateThread(function()
    Wait(2000)
    TriggerServerEvent("rwprinter:server:requestSync")
end)

AddEventHandler("onClientResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(2000)
    TriggerServerEvent("rwprinter:server:requestSync")
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for id in pairs(ClientPrinters) do
        forgetPrinter(id)
    end

    if uiOpen then
        SetNuiFocus(false, false)
    end
end)