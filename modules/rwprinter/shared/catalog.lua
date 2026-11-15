PrinterCatalog = {}

-- Original config values, captured once so the editor can reset to them
local defaultItems = nil
local defaultMaterials = nil
local defaultBattery = nil

-- Callbacks run whenever the catalog changes
local listeners = {}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function notifyChanged()
    if PrinterUtils and PrinterUtils.InvalidateCatalog then
        PrinterUtils.InvalidateCatalog()
    end

    for _, fn in ipairs(listeners) do
        fn()
    end
end

---------------------------------------------------------------------
-- Defaults snapshot
---------------------------------------------------------------------

function PrinterCatalog.Snapshot()
    if defaultItems then return end

    defaultItems     = deepCopy(PrinterConfig.Items or {})
    defaultMaterials = deepCopy(PrinterConfig.MaterialLabels or {})
    defaultBattery   = deepCopy(PrinterConfig.Battery or {})
end

function PrinterCatalog.Defaults()
    PrinterCatalog.Snapshot()
    return deepCopy(defaultItems), deepCopy(defaultMaterials)
end

function PrinterCatalog.DefaultBattery()
    PrinterCatalog.Snapshot()
    return deepCopy(defaultBattery)
end

---------------------------------------------------------------------
-- Battery
---------------------------------------------------------------------

-- { min, max } for each battery setting
PrinterCatalog.BatteryLimits = {
    capacity    = { 1, 1000000 },
    startCharge = { 0, 1000000 },
    maxWatts    = { 1, 1000000 },
    drain       = { 0.05, 50 },
    warnBelow   = { 0, 0.9 },
}

-- Returns the cleaned settings table, or nil + the name of the invalid field
function PrinterCatalog.ValidateBattery(data)
    if type(data) ~= "table" then
        return nil, "capacity"
    end

    local limits = PrinterCatalog.BatteryLimits
    local clean = {}

    for _, key in ipairs({ "capacity", "startCharge", "maxWatts", "drain", "warnBelow" }) do
        local n = tonumber(data[key])
        if not n then
            return nil, key
        end

        if n < limits[key][1] or n > limits[key][2] then
            return nil, key
        end

        if key == "drain" or key == "warnBelow" then
            -- 3 decimal places
            clean[key] = math.floor(n * 1000 + 0.5) / 1000
        else
            clean[key] = math.floor(n + 0.5)
        end
    end

    if clean.startCharge > clean.capacity then
        clean.startCharge = clean.capacity
    end

    return clean
end

function PrinterCatalog.ApplyBattery(data)
    PrinterCatalog.Snapshot()

    local battery = PrinterConfig.Battery
    if not battery or type(data) ~= "table" then
        return
    end

    battery.capacity    = data.capacity    or battery.capacity
    battery.startCharge = data.startCharge or battery.startCharge
    battery.maxWatts    = data.maxWatts    or battery.maxWatts
    battery.drain       = data.drain       or battery.drain
    battery.warnBelow   = data.warnBelow   or battery.warnBelow

    notifyChanged()
end

function PrinterCatalog.ExportBattery()
    local battery = PrinterConfig.Battery or {}

    return {
        enabled     = battery.enabled ~= false,
        item        = battery.item,
        capacity    = battery.capacity or 0,
        startCharge = battery.startCharge or 0,
        maxWatts    = battery.maxWatts or 0,
        drain       = battery.drain or 1.0,
        warnBelow   = battery.warnBelow or 0.2,
    }
end

---------------------------------------------------------------------
-- Change listeners / applying a new catalog
---------------------------------------------------------------------

function PrinterCatalog.OnChange(fn)
    listeners[#listeners + 1] = fn
end

-- Replaces the live PrinterConfig.Items / PrinterConfig.MaterialLabels contents in place
function PrinterCatalog.Apply(items, materials)
    PrinterCatalog.Snapshot()

    local cfgItems = PrinterConfig.Items
    if items and items ~= cfgItems then
        for key in pairs(cfgItems) do
            cfgItems[key] = nil
        end
        for key, value in pairs(items) do
            cfgItems[key] = deepCopy(value)
        end
    end

    local cfgMaterials = PrinterConfig.MaterialLabels
    if not cfgMaterials then
        cfgMaterials = {}
        PrinterConfig.MaterialLabels = cfgMaterials
    end

    if materials and materials ~= cfgMaterials then
        for key in pairs(cfgMaterials) do
            cfgMaterials[key] = nil
        end
        for key, value in pairs(materials) do
            cfgMaterials[key] = value
        end
    end

    notifyChanged()
end

---------------------------------------------------------------------
-- Validation
---------------------------------------------------------------------

PrinterCatalog.Limits = {
    name        = 48,   -- max lengths
    label       = 48,
    prop        = 64,
    image       = 96,
    description = 400,
    time        = { 1, 86400 },   -- { min, max }
    amount      = { 1, 999 },
    power       = { 0, 100000 },
    grade       = { 0, 99 },
    materials   = 12,   -- max number of different materials
    need        = { 1, 9999 },
}

-- Trimmed string, or nil if not a string / empty (numbers are stringified)
local function cleanString(value)
    if type(value) == "number" then
        value = tostring(value)
    end
    if type(value) ~= "string" then
        return nil
    end

    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then
        return nil
    end
    return value
end

local function isString(value)
    return type(value) == "string"
end

-- Optional text field. Returns: text (or nil), ok
local function checkText(value, maxLen)
    value = cleanString(value)
    if value == nil then
        return nil, true
    end
    return value, maxLen >= #value
end

-- Optional number field. Returns: number (or nil), ok
-- NOTE: only the lower bound (range[1]) is enforced here, as in the original.
local function checkNumber(value, range, round)
    if value == nil or value == "" then
        return nil, true
    end

    local n = tonumber(value)
    if not n then
        return nil, false
    end

    if round then
        n = math.floor(n + 0.5)
    end

    return n, n >= range[1]
end

-- Parses the allowed-jobs field (comma-separated string or list).
-- Returns: list (or nil), valid
local function parseJobs(raw)
    local jobs

    local function add(job)
        job = cleanString(job)
        if not job then return true end
        if not isString(job) or #job > 32 then return false end
        jobs[#jobs + 1] = job
        return true
    end

    if type(raw) == "string" then
        jobs = {}
        for part in raw:gmatch("[^,]+") do
            if not add(part) then return nil, false end
        end
    elseif type(raw) == "table" then
        jobs = {}
        for _, part in ipairs(raw) do
            if not add(part) then return nil, false end
        end
    end

    if jobs and #jobs == 0 then
        jobs = nil
    end

    return jobs, true
end

-- Validates a material name / amount pair and adds it to `mats`.
-- Returns false if invalid.
local function addMaterial(mats, itemName, name, need, limits, counter)
    local needValue, needOk = checkNumber(need, limits.need, true)

    local valid = name
        and isString(name)
        and #name <= limits.name
        and needValue
        and needOk

    if not valid then return false end

    -- an item can't require itself
    if name == itemName then return false end

    if not mats[name] then
        counter.count = counter.count + 1
    end
    mats[name] = needValue
    return true
end

-- Validates an item sent from the editor.
-- Returns: name, entry   or   nil, <name of invalid field>
function PrinterCatalog.Validate(data)
    if type(data) ~= "table" then
        return nil, "name"
    end

    local limits = PrinterCatalog.Limits

    local name = cleanString(data.name)
    if not (name and #name <= limits.name and isString(name)) then
        return nil, "name"
    end

    local label, ok = checkText(data.label, limits.label)
    if not ok then return nil, "label" end

    local category = cleanString(data.category)
    local categoryFound = false
    for _, cat in ipairs(PrinterConfig.Categories or {}) do
        if cat.id == category then
            categoryFound = true
            break
        end
    end
    if not categoryFound then return nil, "category" end

    local time, timeOk = checkNumber(data.time, limits.time, true)
    if not time or not timeOk then return nil, "time" end

    local amount, amountOk = checkNumber(data.amount, limits.amount, true)
    if not amountOk then return nil, "amount" end

    local power, powerOk = checkNumber(data.power, limits.power, false)
    if not powerOk then return nil, "power" end

    local prop, propOk = checkText(data.prop, limits.prop)
    if not propOk or (prop and not isString(prop)) then
        return nil, "prop"
    end

    local image, imageOk = checkText(data.image, limits.image)
    if not imageOk or (image and not image:match("^[%w_%-%.]+$")) then
        return nil, "image"
    end

    local description, descriptionOk = checkText(data.description, limits.description)
    if not descriptionOk then return nil, "description" end

    local grade, gradeOk = checkNumber(data.grade, limits.grade, true)
    if not gradeOk then return nil, "grade" end

    local jobs, jobsOk = parseJobs(data.job)
    if not jobsOk then return nil, "job" end

    -- materials: either a list of { name, need } or a { [name] = need } map
    local mats = {}
    local counter = { count = 0 }
    local rawMaterials = data.materials

    if type(rawMaterials) == "table" then
        if rawMaterials[1] ~= nil then
            for _, entry in ipairs(rawMaterials) do
                local isTable = type(entry) == "table"
                local matName = cleanString(isTable and entry.name or nil)
                local need = isTable and entry.need or nil

                if not addMaterial(mats, name, matName, need, limits, counter) then
                    return nil, "materials"
                end
            end
        else
            for key, need in pairs(rawMaterials) do
                local matName = cleanString(key)

                if not addMaterial(mats, name, matName, need, limits, counter) then
                    return nil, "materials"
                end
            end
        end
    end

    if counter.count > limits.materials then
        return nil, "materials"
    end

    local sort, sortOk = checkNumber(data.sort, { -9999, 9999 }, true)
    if not sortOk then return nil, "sort" end

    return name, {
        label       = label or name,
        category    = category,
        time        = time,
        amount      = amount or 1,
        power       = power or 0,
        prop        = prop,
        image       = image,
        description = description,
        job         = jobs,
        grade       = grade,
        materials   = mats,
        enabled     = data.enabled ~= false,
        sort        = sort or 0,
    }
end

-- Returns the cleaned name, or nil if invalid
function PrinterCatalog.ValidName(value)
    local name = cleanString(value)

    if name ~= nil and #name <= PrinterCatalog.Limits.name and isString(name) then
        return name
    end
    return nil
end

---------------------------------------------------------------------
-- Labels / export for the UI
---------------------------------------------------------------------

-- Display name for a material (or printable item)
function PrinterCatalog.MaterialLabel(name)
    local item = PrinterConfig.Items[name]
    if item and item.label then
        return item.label
    end

    return (PrinterConfig.MaterialLabels or {})[name] or name
end

-- Full item list for the editor / UI, sorted by category, sort, time, label
function PrinterCatalog.Export()
    local list = {}

    for name, item in pairs(PrinterConfig.Items) do
        local materials = {}
        for matName, need in pairs(item.materials or {}) do
            materials[#materials + 1] = {
                name  = matName,
                need  = need,
                label = PrinterCatalog.MaterialLabel(matName),
                image = PrinterUtils.GetRawImage(matName),
            }
        end

        table.sort(materials, function(a, b)
            return a.label < b.label
        end)

        local category = item.category or "misc"

        list[#list + 1] = {
            name          = name,
            label         = item.label or name,
            category      = category,
            categoryLabel = PrinterL("cat_" .. category),
            time          = item.time or 60,
            timeLabel     = PrinterUtils.FormatTime(PrinterUtils.GetPrintTime(name)),
            amount        = item.amount or 1,
            power         = item.power or 0,
            powerReal     = PrinterUtils.GetPower(name),
            prop          = item.prop,
            image         = item.image,
            imageUrl      = PrinterUtils.GetImage(name),
            description   = item.description and PrinterL(item.description) or nil,
            job           = PrinterUtils.NormalizeJobs(item.job),
            grade         = item.grade,
            materials     = materials,
            enabled       = item.enabled ~= false,
            sort          = item.sort or 0,
        }
    end

    table.sort(list, function(a, b)
        if a.category ~= b.category then
            return a.category < b.category
        end
        if a.sort ~= b.sort then
            return a.sort < b.sort
        end
        if a.time ~= b.time then
            return a.time < b.time
        end
        return a.label < b.label
    end)

    return list
end

-- Every material known to the config, with how many items use it
function PrinterCatalog.ExportMaterials()
    local seen = {}
    local list = {}

    local function add(name, labelled)
        if seen[name] then return end
        seen[name] = true

        list[#list + 1] = {
            name      = name,
            label     = PrinterCatalog.MaterialLabel(name),
            image     = PrinterUtils.GetRawImage(name),
            usedBy    = 0,
            printable = PrinterConfig.Items[name] ~= nil,
            labelled  = labelled,
        }
    end

    -- materials that have an explicit label
    for name in pairs(PrinterConfig.MaterialLabels or {}) do
        add(name, true)
    end

    -- materials only referenced by recipes
    for _, item in pairs(PrinterConfig.Items) do
        for name in pairs(item.materials or {}) do
            add(name, false)
        end
    end

    -- count how many items use each material
    for _, material in ipairs(list) do
        for _, item in pairs(PrinterConfig.Items) do
            if item.materials and item.materials[material.name] then
                material.usedBy = material.usedBy + 1
            end
        end
    end

    table.sort(list, function(a, b)
        return a.label < b.label
    end)

    return list
end