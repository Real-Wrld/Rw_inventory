-- Returns true if the player is an admin; otherwise notifies them and returns false
local function requireAdmin(src)
    if PrinterFramework.IsAdmin(src) then
        return true
    end

    PrinterFramework.Notify(src, PrinterL("no_permission"), "error")
    return false
end

local function now()
    return os.time()
end

-- Open the editor: send printers, catalog, materials, battery config, etc.
RegisterNetEvent("rwprinter:server:editor:open", function()
    local src = source
    if not requireAdmin(src) then return end

    local printers = {}
    for _, printer in pairs(PrinterGetAllPrinters()) do
        printers[#printers + 1] = PrinterOps.Public(printer)
    end

    TriggerClientEvent("rwprinter:client:editor:open", src, {
        printers      = printers,
        catalog       = PrinterCatalog.Export(),
        materials     = PrinterCatalog.ExportMaterials(),
        battery       = PrinterCatalog.ExportBattery(),
        batteryLimits = PrinterCatalog.BatteryLimits,
        categories    = PrinterUtils.BuildCategoryList(),
        themes        = PrinterUtils.BuildThemeList(),
        serverNow     = now(),
        persistence   = PrinterConfig.Persistence and true or false,
    })
end)

-- Inspect a single printer's access list and log
RegisterNetEvent("rwprinter:server:editor:inspect", function(printerId)
    local src = source
    if not requireAdmin(src) then return end

    local printer = PrinterOps.Get(printerId)
    if not printer then return end

    local access = {}
    for i, entry in ipairs(printer.access or {}) do
        access[i] = { id = entry.id, name = entry.name }
    end

    local log = {}
    for i, entry in ipairs(printer.log or {}) do
        log[i] = {
            item = entry.item,
            wh   = entry.wh,
            at   = entry.at,
            swap = entry.swap,
        }
    end

    TriggerClientEvent("rwprinter:client:editor:inspect", src, {
        id     = printer.id,
        access = access,
        log    = log,
    })
end)

-- Printer actions: delete / clearQueue / refill
RegisterNetEvent("rwprinter:server:editor:printer", function(action, printerId)
    local src = source
    if not requireAdmin(src) then return end

    if not PrinterOps.Get(printerId) then return end

    if action == "delete" then
        PrinterOps.Remove(printerId)
        PrinterFramework.Notify(src, PrinterL("ed_printer_removed", printerId), "success")
    elseif action == "clearQueue" then
        PrinterOps.ClearQueue(printerId)
        PrinterFramework.Notify(src, PrinterL("ed_queue_cleared"), "info")
    elseif action == "refill" then
        PrinterOps.Refill(printerId)
        PrinterFramework.Notify(src, PrinterL("ed_battery_refilled"), "success")
    end
end)

-- PrinterCatalog item actions: save / delete
RegisterNetEvent("rwprinter:server:editor:item", function(action, data)
    local src = source
    if not requireAdmin(src) then return end

    if action == "save" then
        local name, entry = PrinterCatalog.Validate(data)
        if not name then
            -- on failure the second return value is the error key
            return PrinterFramework.Notify(src, PrinterL("ed_invalid", PrinterL("ed_" .. tostring(entry))), "error")
        end

        PrinterCatalogServer.Save(name, entry)
        PrinterFramework.Notify(src, PrinterL("ed_item_saved", entry.label), "success")

    elseif action == "delete" then
        local name = type(data) == "table" and data.name or data
        if type(name) ~= "string" then return end

        if PrinterCatalogServer.Remove(name) then
            PrinterFramework.Notify(src, PrinterL("ed_item_removed", name), "info")
        end
    end
end)

-- Material actions: save / delete
RegisterNetEvent("rwprinter:server:editor:material", function(action, name, label)
    local src = source
    if not requireAdmin(src) then return end

    name = PrinterCatalog.ValidName(name)
    if not name then
        return PrinterFramework.Notify(src, PrinterL("ed_invalid", PrinterL("ed_name")), "error")
    end

    if action == "save" then
        if type(label) ~= "string" then
            label = name
        end

        -- trim whitespace
        label = label:gsub("^%s+", ""):gsub("%s+$", "")
        if label == "" then
            label = name
        end

        if #label > PrinterCatalog.Limits.label then
            return PrinterFramework.Notify(src, PrinterL("ed_invalid", PrinterL("ed_label")), "error")
        end

        PrinterCatalogServer.SaveMaterial(name, label)
        PrinterFramework.Notify(src, PrinterL("ed_material_saved", label), "success")

    elseif action == "delete" then
        if PrinterCatalogServer.RemoveMaterial(name) then
            PrinterFramework.Notify(src, PrinterL("ed_material_removed", name), "info")
        end
    end
end)

-- Save battery settings
RegisterNetEvent("rwprinter:server:editor:battery", function(data)
    local src = source
    if not requireAdmin(src) then return end

    local battery, err = PrinterCatalog.ValidateBattery(data)
    if not battery then
        return PrinterFramework.Notify(src, PrinterL("ed_invalid", PrinterL("ed_bat_" .. tostring(err))), "error")
    end

    PrinterCatalogServer.SaveBattery(battery)
    PrinterFramework.Notify(src, PrinterL("ed_bat_saved"), "success")
end)

-- Reset the catalog to defaults
RegisterNetEvent("rwprinter:server:editor:reset", function()
    local src = source
    if not requireAdmin(src) then return end

    PrinterCatalogServer.Reset()
    PrinterFramework.Notify(src, PrinterL("ed_reset_done"), "success")
end)