PrinterUtils = {}

local locale = PrinterConfig.Locale or "en"

---------------------------------------------------------------------
-- Localisation
---------------------------------------------------------------------

-- PrinterL("key", ...) -> localised string, falling back to English, then the key.
-- Extra arguments are passed to string.format.
function PrinterL(key, ...)
    local strings = PrinterLocales[locale] or PrinterLocales.en or {}

    local text = strings[key]
    if not text and PrinterLocales.en then
        text = PrinterLocales.en[key]
    end

    if not text then
        return key
    end

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, text, ...)
        if ok then
            return formatted
        end
    end

    return text
end

---------------------------------------------------------------------
-- Time / power
---------------------------------------------------------------------

function PrinterUtils.FormatTime(seconds)
    seconds = math.max(0, math.floor(seconds or 0))

    if seconds < 60 then
        return PrinterL("time_seconds", seconds)
    elseif seconds < 3600 then
        return PrinterL("time_minutes", math.floor(seconds / 60), seconds % 60)
    end

    return PrinterL("time_hours", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
end

-- Battery energy (Wh) a print of this item consumes
function PrinterUtils.GetPower(itemName)
    if not (PrinterConfig.Battery and PrinterConfig.Battery.enabled) then
        return 0
    end

    local item = PrinterConfig.Items[itemName]
    local power = (item and item.power) or 0
    if power <= 0 then
        return 0
    end

    return math.floor(power * (PrinterConfig.Battery.drain or 1.0) + 0.5)
end

local wattsCache = {}

function PrinterUtils.InvalidateCatalog()
    wattsCache = {}
end

-- Average power draw (W) of an item while printing
function PrinterUtils.GetWatts(itemName)
    if not itemName then
        return 0
    end

    local cached = wattsCache[itemName]
    if cached then
        return cached
    end

    local power = PrinterUtils.GetPower(itemName)
    local watts = 0

    if power > 0 then
        local hours = PrinterUtils.GetPrintTime(itemName) / 3600
        if hours > 0 then
            watts = math.floor(power / hours + 0.5)
        end
    end

    wattsCache[itemName] = watts
    return watts
end

-- Instantaneous draw (W) for a given load (0..1), with an optional extra term
function PrinterUtils.GetDraw(itemName, load, extra)
    local watts = PrinterUtils.GetWatts(itemName)
    if watts <= 0 then
        return 0
    end

    local base, spread, falloff = 0.952, 0.6, 0.08
    local x = math.min(math.max(load or 0.0, 0.0), 1.0)

    local factor = base + spread * math.exp(-x / falloff)
    if extra then
        factor = factor + 0.035 * extra
    end

    return math.floor(watts * factor + 0.5)
end

-- Print duration in seconds (never below 1)
function PrinterUtils.GetPrintTime(itemName)
    local item = PrinterConfig.Items[itemName]
    if not item then
        return 0
    end

    return math.max(1, math.floor((item.time or 60) * (PrinterConfig.TimeMultiplier or 1.0)))
end

---------------------------------------------------------------------
-- Images
---------------------------------------------------------------------

function PrinterUtils.GetImage(itemName)
    local item = PrinterConfig.Items[itemName]
    local extension = PrinterConfig.ImageExtension or ".png"

    local file
    if item and item.image then
        file = item.image
        -- add the default extension if the configured name has none
        if not file:match("%.%a+$") then
            file = file .. extension
        end
    else
        file = itemName .. extension
    end

    return (PrinterConfig.ImagePath or "") .. file
end

function PrinterUtils.GetRawImage(name)
    return (PrinterConfig.ImagePath or "") .. name .. (PrinterConfig.ImageExtension or ".png")
end

---------------------------------------------------------------------
-- Misc helpers
---------------------------------------------------------------------

-- Job restriction -> list of job names (or nil for "everyone")
function PrinterUtils.NormalizeJobs(job)
    if not job then
        return nil
    end

    if type(job) == "string" then
        return { job }
    end

    return job
end

function PrinterUtils.Debug(...)
    if not PrinterConfig.Debug then return end

    print(("[rwprinter] %s"):format(table.concat({ ... }, " ")))
end

-- Squared distance between two points
function PrinterUtils.DistSq(x1, y1, z1, x2, y2, z2)
    local dx = x1 - x2
    local dy = y1 - y2
    local dz = z1 - z2
    return dx * dx + dy * dy + dz * dz
end

---------------------------------------------------------------------
-- Themes
---------------------------------------------------------------------

local themesById = nil
local fallbackTheme = nil

-- Returns the theme with this id, or the default theme
function PrinterUtils.GetTheme(themeId)
    if not themesById then
        themesById = {}
        for _, theme in ipairs(PrinterConfig.Themes or {}) do
            themesById[theme.id] = theme
        end

        fallbackTheme = themesById[PrinterConfig.DefaultTheme]
            or (PrinterConfig.Themes or {})[1]
            or {
                id     = "crimson",
                label  = "Crimson",
                accent = "#e5352f",
                rgb    = { 229, 53, 47 },
            }
    end

    return themesById[themeId] or fallbackTheme
end

function PrinterUtils.BuildThemeList()
    local list = {}
    for _, theme in ipairs(PrinterConfig.Themes or {}) do
        list[#list + 1] = {
            id     = theme.id,
            label  = theme.label,
            accent = theme.accent,
        }
    end
    return list
end

---------------------------------------------------------------------
-- UI lists
---------------------------------------------------------------------

-- UI representation of a single printable item
local function buildItem(name, item)
    local materials = {}
    for matName, need in pairs(item.materials or {}) do
        local matItem = PrinterConfig.Items[matName]

        materials[#materials + 1] = {
            name  = matName,
            label = (matItem and matItem.label)
                or (PrinterConfig.MaterialLabels or {})[matName]
                or matName,
            need  = need,
            image = PrinterUtils.GetRawImage(matName),
        }
    end

    table.sort(materials, function(a, b)
        return a.label < b.label
    end)

    local category = item.category or "misc"

    return {
        name          = name,
        label         = item.label or name,
        image         = PrinterUtils.GetImage(name),
        time          = PrinterUtils.GetPrintTime(name),
        timeLabel     = PrinterUtils.FormatTime(PrinterUtils.GetPrintTime(name)),
        amount        = item.amount or 1,
        power         = PrinterUtils.GetPower(name),
        watts         = PrinterUtils.GetWatts(name),
        category      = category,
        categoryLabel = PrinterL("cat_" .. category),
        materials     = materials,
        job           = PrinterUtils.NormalizeJobs(item.job),
        grade         = item.grade,
        description   = item.description and PrinterL(item.description) or nil,
        sort          = item.sort or 0,
    }
end

-- All enabled items, sorted by category, sort, time, label
function PrinterUtils.BuildItemList()
    local list = {}

    for name, item in pairs(PrinterConfig.Items) do
        if item.enabled ~= false then
            list[#list + 1] = buildItem(name, item)
        end
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

function PrinterUtils.BuildCategoryList()
    local list = {
        { id = "all", label = PrinterL("ui_all"), icon = "grid" },
    }

    for _, category in ipairs(PrinterConfig.Categories or {}) do
        list[#list + 1] = {
            id    = category.id,
            label = PrinterL("cat_" .. category.id),
            icon  = category.icon or "box",
        }
    end

    return list
end

---------------------------------------------------------------------
-- Printer item(s)
---------------------------------------------------------------------

-- PrinterConfig.PrinterItem may be a string or a list; always returns a list
function PrinterUtils.PrinterItems()
    local configured = PrinterConfig.PrinterItem

    if type(configured) == "table" then
        local names = {}
        for _, name in ipairs(configured) do
            if type(name) == "string" and name ~= "" then
                names[#names + 1] = name
            end
        end

        if #names > 0 then
            return names
        end
    elseif type(configured) == "string" and configured ~= "" then
        return { configured }
    end

    return { "3dprinter" }
end

-- The primary printer item name
function PrinterUtils.PrinterItem()
    return PrinterUtils.PrinterItems()[1]
end