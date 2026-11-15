PrinterEditorOpen = false

local PREFS_KEY = "rwprinter:editorPrefs"
local HEX_PATTERN = "^#%x%x%x%x%x%x$"

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function validHex(value)
    if type(value) == "string" and value:match(HEX_PATTERN) then
        return value
    end
    return nil
end

local function loadPrefs()
    local raw = GetResourceKvpString(PREFS_KEY)
    if type(raw) ~= "string" or raw == "" then return nil end

    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= "table" then return nil end

    return {
        accent  = validHex(data.accent),
        custom  = validHex(data.custom),
        density = data.density == "compact" and "compact" or "cozy",
    }
end

-- NUI field name -> locale key
local LOCALE_KEYS = {
    title = "editor_title", subtitle = "editor_sub", admin = "editor_admin",
    close = "ui_close", search = "ui_search",

    navPrinters = "nav_printers", navPrintersSub = "nav_printers_sub",
    navCatalog = "nav_catalog", navCatalogSub = "nav_catalog_sub",
    navMaterials = "nav_materials", navMaterialsSub = "nav_materials_sub",
    navBattery = "nav_battery",

    footPrinters = "ed_foot_printers", footPrinting = "ed_foot_printing",
    printersTitle = "ed_printers_title", printersSub = "ed_printers_sub",

    filterAll = "ui_all", filterPrinting = "ed_state_printing",
    filterReady = "ed_state_ready", filterIdle = "ed_state_idle",
    filterBlocked = "ed_state_blocked",

    noPrinters = "ed_no_printers", noPrintersSub = "ed_no_printers_sub",
    selectPrinter = "ed_select_printer", selectPrinterSub = "ed_select_printer_sub",

    owner = "ui_access_owner", printerId = "ed_printer_id", away = "ed_away",
    battery = "nav_battery", queue = "nav_queue", tray = "ui_tray_title",
    access = "ed_access", accessNone = "ui_access_none",
    log = "ed_log", logNone = "ui_battery_empty", theme = "ui_set_theme",

    printing = "printing", complete = "print_complete",
    barRemaining = "bar_remaining", barComplete = "bar_complete",
    queueStarts = "ui_queue_starts", queueActive = "ui_queue_active",
    power = "ui_power", swapped = "ui_battery_swapped",

    teleport = "ed_teleport", clearQueue = "ui_queue_clear", refill = "ed_refill",
    deletePrinter = "ed_delete_printer", deleteConfirm = "ed_delete_confirm",
    cancel = "place_cancel",

    catalogTitle = "ed_catalog_title", catalogSub = "ed_catalog_sub",
    newItem = "ed_new_item", newItemSub = "ed_new_item_sub",
    selectItem = "ed_select_item", selectItemSub = "ed_select_item_sub",

    name = "ed_name", nameHint = "ed_name_hint", label = "ed_label",
    category = "ed_category", description = "ed_description",
    time = "ed_time", timeHint = "ed_time_hint", amount = "ed_amount",
    powerWh = "ed_power", powerHint = "ed_power_hint",
    prop = "ed_prop", propHint = "ed_prop_hint",
    image = "ed_image", imageHint = "ed_image_hint",
    job = "ed_job", jobHint = "ed_job_hint", grade = "ed_grade",

    materials = "ui_materials", materialsNone = "ed_materials_none",
    addMaterial = "ed_add_material", materialName = "ed_material_name",
    need = "ed_need", enabled = "ed_enabled", enabledHint = "ed_enabled_hint",
    disabled = "ed_disabled",

    save = "ed_save", saveNew = "ed_save_new",
    deleteItem = "ed_delete_item", deleteItemConfirm = "ed_delete_item_confirm",
    unsaved = "ed_unsaved",
    invalidName = "ed_invalid_name", invalidTime = "ed_invalid_time",
    invalidMats = "ed_invalid_mats",

    reset = "ed_reset", resetSub = "ed_reset_sub", resetConfirm = "ed_reset_confirm",
    noPersist = "ed_no_persist",

    section = "ed_section", sectionIdentity = "ed_section_identity",
    sectionProduction = "ed_section_production", sectionAccess = "ed_section_access",

    materialsTitle = "ed_materials_title", materialsSub = "ed_materials_sub",
    newMaterial = "ed_new_material",
    selectMaterial = "ed_select_material", selectMaterialSub = "ed_select_material_sub",
    usedBy = "ed_used_by", unused = "ed_unused", printable = "ed_printable",
    deleteMaterial = "ed_delete_material", materialHint = "ed_material_hint",
    materialNameHint = "ed_material_name_hint",
    removeMaterial = "ed_remove_material", addMaterialHint = "ed_add_material_hint",
    noResults = "ui_no_results",

    batTitle = "ed_bat_title", batSub = "ed_bat_sub",
    batCapacity = "ed_bat_capacity", batCapacityHint = "ed_bat_capacity_hint",
    batStart = "ed_bat_startCharge", batStartHint = "ed_bat_start_hint",
    batDrain = "ed_bat_drain", batDrainHint = "ed_bat_drain_hint",
    batMaxWatts = "ed_bat_maxWatts", batMaxWattsHint = "ed_bat_maxwatts_hint",
    batWarn = "ed_bat_warnBelow", batWarnHint = "ed_bat_warn_hint",
    batPreview = "ed_bat_preview", batPrintsOf = "ed_bat_prints_of",
    batEffective = "ed_bat_effective", batItem = "battery_item",
    batSettings = "ed_bat_settings",
    batSelect = "ed_bat_select", batSelectSub = "ed_bat_select_sub",
    batItemSection = "ed_bat_item_section", batPowerHint = "ed_bat_power_hint",
    batPerBattery = "ed_bat_per_battery", batAvgWatts = "ed_bat_avg_watts",
    batFree = "ed_bat_free", batItemNote = "ed_bat_item_note",

    timeShort = "ui_time", appearance = "ed_appearance",
    themeConsole = "ed_theme_console", customColour = "ed_custom_colour",
    density = "ed_density", densityCozy = "ed_density_cozy",
    densityCompact = "ed_density_compact",

    searchPrinters = "ed_search_printers", searchItems = "ed_search_items",
    searchMaterials = "ed_search_materials",
}

local function buildLocale()
    local out = {}
    for field, key in pairs(LOCALE_KEYS) do
        out[field] = PrinterL(key)
    end
    return out
end

local function getPlayerCoords()
    local c = GetEntityCoords(PlayerPedId())
    return { x = c.x, y = c.y, z = c.z }
end

local function closeEditor()
    if not PrinterEditorOpen then return end
    PrinterEditorOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "editor:close" })
end

-- ─────────────────────────────────────────────
-- Command
-- ─────────────────────────────────────────────

local commandName = (PrinterConfig.Commands and PrinterConfig.Commands.editor) or "printeradmin"

RegisterCommand(commandName, function()
    TriggerServerEvent("rwprinter:server:editor:open")
end, false)

-- ─────────────────────────────────────────────
-- Server -> Client events
-- ─────────────────────────────────────────────

RegisterNetEvent("rwprinter:client:editor:open", function(data)
    if type(data) ~= "table" then return end

    if PrinterCloseUI then PrinterCloseUI() end

    PrinterEditorOpen = true
    SetNuiFocus(true, true)

    data.action         = "editor"
    data.locale         = buildLocale()
    data.me             = getPlayerCoords()
    data.accent         = (PrinterConfig.UI and PrinterConfig.UI.editorAccent) or nil
    data.imagePath      = PrinterConfig.ImagePath or ""
    data.imageExt       = PrinterConfig.ImageExtension or ".png"
    data.limits         = PrinterCatalog.Limits
    data.maxQueue       = PrinterConfig.Queue.maxJobs
    data.maxOutput      = PrinterConfig.Queue.maxOutput
    data.timeMultiplier = PrinterConfig.TimeMultiplier or 1.0
    data.prefs          = loadPrefs()
    data.batteryImage   = PrinterUtils.GetRawImage((PrinterConfig.Battery or {}).item or "")

    SendNUIMessage(data)
end)

RegisterNetEvent("rwprinter:client:editor:inspect", function(data)
    if not PrinterEditorOpen or type(data) ~= "table" then return end
    data.action = "editor:inspect"
    SendNUIMessage(data)
end)

-- ─────────────────────────────────────────────
-- Local events
-- ─────────────────────────────────────────────

AddEventHandler("rwprinter:client:updatePrinter", function(printer)
    if PrinterEditorOpen and type(printer) == "table" then
        SendNUIMessage({ action = "editor:printer", printer = printer })
    end
end)

AddEventHandler("rwprinter:client:removePrinter", function(id)
    if PrinterEditorOpen then
        SendNUIMessage({ action = "editor:removed", id = id })
    end
end)

PrinterCatalog.OnChange(function()
    if not PrinterEditorOpen then return end
    SendNUIMessage({
        action    = "editor:catalog",
        catalog   = PrinterCatalog.Export(),
        materials = PrinterCatalog.ExportMaterials(),
        battery   = PrinterCatalog.ExportBattery(),
    })
end)

-- ─────────────────────────────────────────────
-- NUI callbacks
-- ─────────────────────────────────────────────

RegisterNUICallback("editor:close", function(_, cb)
    closeEditor()
    cb({ ok = true })
end)

RegisterNUICallback("editor:inspect", function(data, cb)
    if PrinterEditorOpen and data and data.id then
        TriggerServerEvent("rwprinter:server:editor:inspect", data.id)
    end
    cb({ ok = true })
end)

RegisterNUICallback("editor:teleport", function(data, cb)
    cb({ ok = true })
    if not (PrinterEditorOpen and data and data.x) then return end

    closeEditor()
    SetEntityCoords(PlayerPedId(), data.x + 0.0, data.y + 0.0, data.z + 1.0, false, false, false, false)
end)

RegisterNUICallback("editor:printer", function(data, cb)
    if PrinterEditorOpen and data and data.action and data.id then
        TriggerServerEvent("rwprinter:server:editor:printer", data.action, data.id)
    end
    cb({ ok = true })
end)

RegisterNUICallback("editor:item", function(data, cb)
    if PrinterEditorOpen and data and data.action then
        TriggerServerEvent("rwprinter:server:editor:item", data.action, data.item)
    end
    cb({ ok = true })
end)

RegisterNUICallback("editor:material", function(data, cb)
    if PrinterEditorOpen and data and data.action and data.name then
        TriggerServerEvent("rwprinter:server:editor:material", data.action, data.name, data.label)
    end
    cb({ ok = true })
end)

RegisterNUICallback("editor:prefs", function(data, cb)
    if type(data) == "table" then
        SetResourceKvp(PREFS_KEY, json.encode({
            accent  = validHex(data.accent),
            custom  = validHex(data.custom),
            density = data.density == "compact" and "compact" or "cozy",
        }))
    end
    cb({ ok = true })
end)

RegisterNUICallback("editor:battery", function(data, cb)
    if PrinterEditorOpen and type(data) == "table" then
        TriggerServerEvent("rwprinter:server:editor:battery", data)
    end
    cb({ ok = true })
end)

RegisterNUICallback("editor:reset", function(_, cb)
    if PrinterEditorOpen then
        TriggerServerEvent("rwprinter:server:editor:reset")
    end
    cb({ ok = true })
end)

-- ─────────────────────────────────────────────
-- Cleanup
-- ─────────────────────────────────────────────

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if PrinterEditorOpen then
        SetNuiFocus(false, false)
    end
end)