if not lib then return end

local defaultSections = {
    clothing = false,
    character = false,
    hud = false,
}

local defaultAccentColor = {
    r = 32,
    g = 201,
    b = 151,
}

local defaultCustomization = {
    enabled = true,
    accentColor = true,
    hudStyle = true,
    weightStyle = true,
    imageSize = true,
    visibility = true,
    weaponAimAnim = true,
    weaponEquipAnim = true,
}

local function clampColorValue(val)
    local num = tonumber(val) or val
    if not num then num = 0 end
    if num < 0 then return 0 end
    if num > 255 then return 255 end
    return math.floor(num)
end

function GetInventorySections()
    if type(RWInventoryConfig) == 'table' and type(RWInventoryConfig.sections) == 'table' then
        return {
            clothing = RWInventoryConfig.sections.clothing == true,
            character = RWInventoryConfig.sections.character == true,
            hud = RWInventoryConfig.sections.hud == true,
        }
    end

    return defaultSections
end

function GetDefaultAccentColor()
    local accentConfig = type(RWInventoryConfig) == 'table' and RWInventoryConfig.accentColor or nil
    local r, g, b

    if type(accentConfig) == 'table' then
        r = clampColorValue(accentConfig.r or accentConfig[1])
        g = clampColorValue(accentConfig.g or accentConfig[2])
        b = clampColorValue(accentConfig.b or accentConfig[3])
    else
        r = defaultAccentColor.r
        g = defaultAccentColor.g
        b = defaultAccentColor.b
    end

    return {
        r = r,
        g = g,
        b = b,
        hex = string.format('#%02X%02X%02X', r, g, b),
    }
end

function GetInventoryCustomization()
    local customConfig = type(RWInventoryConfig) == 'table' and RWInventoryConfig.customization or nil
    local result = {}

    for key, value in pairs(defaultCustomization) do
        if type(customConfig) == 'table' and customConfig[key] ~= nil then
            result[key] = customConfig[key] == true
        else
            result[key] = value
        end
    end

    return result
end

exports('getInventoryConfig', function()
    return RWInventoryConfig
end)

exports('getInventorySections', GetInventorySections)
exports('getInventoryCustomization', GetInventoryCustomization)
exports('getDefaultAccentColor', GetDefaultAccentColor)
