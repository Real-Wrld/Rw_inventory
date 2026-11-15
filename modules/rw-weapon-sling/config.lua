local resourceName = GetCurrentResourceName()
local configPath = resourceName == 'ox_inventory'
    and 'modules/rw-weapon-sling/config.json'
    or 'config.json'

local DEFAULT_CONFIG = {
    Debug = false,
    Locale = 'en',
    UniqueKvpId = 'real-wrld',
    MaxVisibleSlings = 4,
    UseWeaponAttachments = true,
    UseHolsteredModels = true,
    HideWhenEquipped = true,
    HideInVehicle = true,
    Command = { name = 'sling', description = 'Open the Advanced Weapon Sling Editor (admin)', permission = 'admin' },
    Presets = { command = 'slingpreset', permission = 'admin', aliasOf = 'sling' },
    Admin = { Global = { enabled = true, players = {}, ace = 'rw-inventory.sling.admin' } },
    Bones = {},
    Weapons = {},
    Blacklist = {},
}

local content = LoadResourceFile(resourceName, configPath)
SlingConfig = DEFAULT_CONFIG

if content then
    local ok, parsed = pcall(json.decode, content)
    if ok and type(parsed) == 'table' then
        SlingConfig = parsed
    else
    end
else
end

local function mergeDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            target[k] = v
        elseif type(v) == 'table' and type(target[k]) == 'table' then
            mergeDefaults(target[k], v)
        end
    end
end

mergeDefaults(SlingConfig, DEFAULT_CONFIG)

function SlingDebug(...)
    if not SlingConfig.Debug then return end
    local parts = { ... }
end

return SlingConfig
