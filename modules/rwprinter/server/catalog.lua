PrinterCatalogServer = {}
PrinterCatalogReady = false

local ITEMS_TABLE     = "rw_3dprinter_items"
local MATERIALS_TABLE = "rw_3dprinter_materials"
local SETTINGS_TABLE  = "rw_3dprinter_settings"
local SEEDED_KEY      = "seeded"

-- ─────────────────────────────────────────────
-- Row <-> table conversion
-- ─────────────────────────────────────────────

local function safeDecode(raw, fallback)
    if type(raw) ~= "string" or raw == "" then
        return fallback
    end

    local ok, value = pcall(json.decode, raw)
    if ok and type(value) == "table" then
        return value
    end
    return fallback
end

local function rowToItem(row)
    local job = safeDecode(row.job, nil)
    if job and #job == 0 then
        job = nil
    end

    local enabled = row.enabled
    if enabled == nil then enabled = true end
    enabled = not (enabled == 0 or enabled == false)

    return {
        label       = row.label,
        category    = row.category,
        time        = row.time,
        amount      = row.amount,
        power       = row.power,
        prop        = row.prop,
        image       = row.image,
        description = row.description,
        job         = job,
        grade       = row.grade,
        materials   = safeDecode(row.materials, {}),
        enabled     = enabled,
        sort        = row.sort or 0,
    }
end

local UPSERT_ITEM = ([[
    INSERT INTO `%s`
        (name, label, category, time, amount, power, prop, image, description,
         job, grade, materials, enabled, sort)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
        label = VALUES(label), category = VALUES(category), time = VALUES(time),
        amount = VALUES(amount), power = VALUES(power), prop = VALUES(prop),
        image = VALUES(image), description = VALUES(description), job = VALUES(job),
        grade = VALUES(grade), materials = VALUES(materials),
        enabled = VALUES(enabled), sort = VALUES(sort)
]]):format(ITEMS_TABLE)

local UPSERT_MATERIAL = ([[
    INSERT INTO `%s` (name, label) VALUES (?, ?)
    ON DUPLICATE KEY UPDATE label = VALUES(label)
]]):format(MATERIALS_TABLE)

local UPSERT_SETTING = ([[
    INSERT INTO `%s` (`k`, `v`) VALUES (?, ?)
    ON DUPLICATE KEY UPDATE `v` = VALUES(`v`)
]]):format(SETTINGS_TABLE)

local function itemToParams(name, item)
    local jobs = PrinterUtils.NormalizeJobs(item.job)

    return {
        name,
        item.label or name,
        item.category or "misc",
        item.time or 60,
        item.amount or 1,
        item.power or 0,
        item.prop,
        item.image,
        item.description,
        jobs and json.encode(jobs) or nil,
        item.grade,
        json.encode(item.materials or {}),
        (item.enabled ~= false) and 1 or 0,
        item.sort or 0,
    }
end

-- ─────────────────────────────────────────────
-- DB access (all no-ops when persistence is off / schema not ready)
-- ─────────────────────────────────────────────

local function persistenceActive()
    return (PrinterConfig.Persistence and CatalogSchemaReady) and true or false
end

local function saveItemRow(name, item)
    if not persistenceActive() then return end
    MySQL.update.await(UPSERT_ITEM, itemToParams(name, item))
end

local function deleteItemRow(name)
    if not persistenceActive() then return end
    MySQL.update.await(("DELETE FROM `%s` WHERE name = ?"):format(ITEMS_TABLE), { name })
end

local function saveMaterialRow(name, label)
    if not persistenceActive() then return end
    MySQL.update.await(UPSERT_MATERIAL, { name, label })
end

local function deleteMaterialRow(name)
    if not persistenceActive() then return end
    MySQL.update.await(("DELETE FROM `%s` WHERE name = ?"):format(MATERIALS_TABLE), { name })
end

local function clearAllRows()
    if not persistenceActive() then return end
    MySQL.update.await(("DELETE FROM `%s`"):format(ITEMS_TABLE))
    MySQL.update.await(("DELETE FROM `%s`"):format(MATERIALS_TABLE))
    MySQL.update.await(("DELETE FROM `%s`"):format(SETTINGS_TABLE))
end

local function saveSetting(key, value)
    if not persistenceActive() then return end
    MySQL.update.await(UPSERT_SETTING, { key, json.encode(value) })
end

local function loadSetting(key)
    if not persistenceActive() then return nil end

    local raw = MySQL.scalar.await(("SELECT `v` FROM `%s` WHERE `k` = ?"):format(SETTINGS_TABLE), { key })
    return safeDecode(raw, nil)
end

local function markSeeded()
    saveSetting(SEEDED_KEY, {
        at      = os.time(),
        version = GetResourceMetadata(GetCurrentResourceName(), "version", 0),
    })
end

-- Writes a full catalog to the DB
local function seedAll(items, materials)
    for name, item in pairs(items) do
        saveItemRow(name, item)
    end
    for name, label in pairs(materials) do
        saveMaterialRow(name, label)
    end
    markSeeded()
end

-- Adds config defaults that are missing from the DB catalog; returns how many items were added
local function mergeMissingDefaults(items, materials)
    local defItems, defMaterials = PrinterCatalog.Defaults()
    local added = 0

    for name, def in pairs(defItems) do
        if not items[name] then
            items[name] = def
            saveItemRow(name, def)
            added = added + 1
        end
    end

    for name, def in pairs(defMaterials) do
        if not materials[name] then
            materials[name] = def
            saveMaterialRow(name, def)
        end
    end

    markSeeded()
    return added
end

-- Returns items, materials (or nil if the DB has no items yet)
local function loadFromDb()
    local itemRows = MySQL.query.await(("SELECT * FROM `%s`"):format(ITEMS_TABLE)) or {}
    if #itemRows == 0 then
        return nil
    end

    local items = {}
    for _, row in ipairs(itemRows) do
        if row.name then
            items[row.name] = rowToItem(row)
        end
    end

    local materials = {}
    local materialRows = MySQL.query.await(("SELECT * FROM `%s`"):format(MATERIALS_TABLE)) or {}
    for _, row in ipairs(materialRows) do
        if row.name then
            materials[row.name] = row.label or row.name
        end
    end

    return items, materials
end

-- ─────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────

-- Sends the catalog to a player (or everyone when target is nil)
function PrinterCatalogServer.Broadcast(target)
    TriggerClientEvent(
        "rwprinter:client:catalog",
        target or -1,
        PrinterConfig.Items,
        PrinterConfig.MaterialLabels or {},
        PrinterCatalog.ExportBattery()
    )
end

function PrinterCatalogServer.SaveBattery(data)
    PrinterCatalog.ApplyBattery(data)
    saveSetting("battery", PrinterCatalog.ExportBattery())

    -- Clamp stored charge on existing printers to the new capacity
    local capacity = PrinterConfig.Battery.capacity or 0
    for _, printer in pairs(PrinterGetAllPrinters()) do
        if capacity < (printer.battery or 0) then
            printer.battery = capacity
            printer.dirty = true
        end
    end

    PrinterCatalogServer.Broadcast()
    return true
end

function PrinterCatalogServer.Save(name, item)
    PrinterConfig.Items[name] = item
    saveItemRow(name, item)
    PrinterCatalog.Apply(PrinterConfig.Items, PrinterConfig.MaterialLabels)
    PrinterCatalogServer.Broadcast()
    PrinterUtils.Debug(("catalogo: item %s guardado"):format(name))
    return true
end

function PrinterCatalogServer.Remove(name)
    if not PrinterConfig.Items[name] then return false end

    PrinterConfig.Items[name] = nil
    deleteItemRow(name)
    PrinterCatalog.Apply(PrinterConfig.Items, PrinterConfig.MaterialLabels)
    PrinterCatalogServer.Broadcast()
    PrinterUtils.Debug(("catalogo: item %s apagado"):format(name))
    return true
end

function PrinterCatalogServer.SaveMaterial(name, label)
    PrinterConfig.MaterialLabels = PrinterConfig.MaterialLabels or {}
    PrinterConfig.MaterialLabels[name] = label
    saveMaterialRow(name, label)
    PrinterCatalog.Apply(PrinterConfig.Items, PrinterConfig.MaterialLabels)
    PrinterCatalogServer.Broadcast()
    return true
end

function PrinterCatalogServer.RemoveMaterial(name)
    if not (PrinterConfig.MaterialLabels and PrinterConfig.MaterialLabels[name]) then
        return false
    end

    PrinterConfig.MaterialLabels[name] = nil
    deleteMaterialRow(name)
    PrinterCatalog.Apply(PrinterConfig.Items, PrinterConfig.MaterialLabels)
    PrinterCatalogServer.Broadcast()
    return true
end

-- Wipes the DB catalog and restores everything from config
function PrinterCatalogServer.Reset()
    local items, materials = PrinterCatalog.Defaults()

    clearAllRows()
    seedAll(items, materials)

    PrinterCatalog.Apply(items, materials)
    PrinterCatalog.ApplyBattery(PrinterCatalog.DefaultBattery())
    PrinterCatalogServer.Broadcast()

    PrinterUtils.Debug("catalogo: reposto a partir do config")
    return true
end

-- ─────────────────────────────────────────────
-- Startup
-- ─────────────────────────────────────────────

CreateThread(function()
    PrinterCatalog.Snapshot()

    -- No persistence: just use config
    if not PrinterConfig.Persistence then
        PrinterCatalog.Apply(PrinterCatalog.Defaults())
        PrinterCatalogReady = true
        return
    end

    -- Wait for the DB schema check (up to ~30s)
    local tries = 0
    while not (PrinterSchemaReady and CatalogSchemaReady ~= nil) and tries < 300 do
        Wait(100)
        tries = tries + 1
    end

    if not PrinterSchemaReady then
        print("^1[rwprinter] Catalogo: base de dados nao ficou pronta; a usar o config.^0")
        PrinterCatalog.Apply(PrinterCatalog.Defaults())
        PrinterCatalogReady = true
        return
    end

    if not CatalogSchemaReady then
        PrinterCatalog.Apply(PrinterCatalog.Defaults())
        PrinterCatalogReady = true
        PrinterCatalogServer.Broadcast()
        return
    end

    local ok, err = pcall(function()
        local battery = loadSetting("battery")
        if battery then
            PrinterCatalog.ApplyBattery(battery)
        end

        local items, materials = loadFromDb()

        if not items then
            -- First run: seed DB from config
            items, materials = PrinterCatalog.Defaults()
            seedAll(items, materials)
            saveSetting("battery", PrinterCatalog.ExportBattery())

            local count = 0
            for _ in pairs(items) do count = count + 1 end
            print(("^2[rwprinter] Catalogo semeado a partir do config (%d itens).^0"):format(count))
        elseif not loadSetting(SEEDED_KEY) then
            -- Pre-existing DB from 1.0.0: add missing config defaults, keep edits
            local added = mergeMissingDefaults(items, materials)
            print(("^3[rwprinter] Catalogo migrado da 1.0.0: %d itens do config repostos, os editados ficaram.^0"):format(added))
        end

        PrinterCatalog.Apply(items, materials)
    end)

    if not ok then
        print(("^1[rwprinter] Catalogo: falha a ler a base (%s); a usar o config.^0"):format(err))
        PrinterCatalog.Apply(PrinterCatalog.Defaults())
    end

    PrinterCatalogReady = true
    PrinterCatalogServer.Broadcast()
end)