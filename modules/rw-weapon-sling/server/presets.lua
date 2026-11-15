local Shared = require 'modules.rw-weapon-sling.shared'

local Presets = {
    global = {},
    personal = {},
}

local function kvpId()
    return GetConvar('rw:uniqueKvpId', SlingConfig.UniqueKvpId or 'real-wrld')
end

local function globalKey()
    return ('%s:%s:global'):format(Shared.KvpNamespace, kvpId())
end

local function personalKey(identifier)
    return ('%s:%s:personal:%s'):format(Shared.KvpNamespace, kvpId(), identifier)
end

local function prefsKey(identifier)
    return ('%s:%s:prefs:%s'):format(Shared.KvpNamespace, kvpId(), identifier)
end

function Presets.loadGlobal()
    local raw = GetResourceKvpString(globalKey())
    if raw and raw ~= '' then
        local ok, parsed = pcall(json.decode, raw)
        if ok and type(parsed) == 'table' then
            Presets.global = parsed
        end
    end
    return Presets.global
end

function Presets.saveGlobal()
    SetResourceKvp(globalKey(), json.encode(Presets.global))
end

function Presets.loadPersonal(identifier)
    if not identifier then return {} end
    if Presets.personal[identifier] then return Presets.personal[identifier] end
    local raw = GetResourceKvpString(personalKey(identifier))
    local data = {}
    if raw and raw ~= '' then
        local ok, parsed = pcall(json.decode, raw)
        if ok and type(parsed) == 'table' then data = parsed end
    end
    Presets.personal[identifier] = data
    return data
end

function Presets.savePersonal(identifier)
    if not identifier then return end
    SetResourceKvp(personalKey(identifier), json.encode(Presets.personal[identifier] or {}))
end

function Presets.loadPrefs(identifier)
    local raw = GetResourceKvpString(prefsKey(identifier))
    if raw and raw ~= '' then
        local ok, parsed = pcall(json.decode, raw)
        if ok and type(parsed) == 'table' then return parsed end
    end
    return { enabled = true, hidden = {} }
end

function Presets.savePrefs(identifier, prefs)
    SetResourceKvp(prefsKey(identifier), json.encode(prefs or { enabled = true, hidden = {} }))
end

function Presets.getTransform(identifier, weaponName, weaponGroup)
    weaponName = Shared.normalizeWeaponName(weaponName)
    if not weaponName then return nil end

    local personal = Presets.loadPersonal(identifier)
    if personal[weaponName] then
        return Shared.cloneTransform(personal[weaponName])
    end

    if Presets.global[weaponName] then
        return Shared.cloneTransform(Presets.global[weaponName])
    end

    local groupDefault = weaponGroup and Shared.GroupDefaults[weaponGroup]
    if groupDefault then
        return Shared.cloneTransform(groupDefault)
    end

    return Shared.cloneTransform(Shared.GroupDefaults[`GROUP_PISTOL`])
end

function Presets.setTransform(identifier, weaponName, transform, scope)
    weaponName = Shared.normalizeWeaponName(weaponName)
    if not weaponName or type(transform) ~= 'table' then return false end

    if scope == 'global' then
        Presets.global[weaponName] = Shared.cloneTransform(transform)
        Presets.saveGlobal()
        return true
    end

    Presets.personal[identifier] = Presets.personal[identifier] or Presets.loadPersonal(identifier)
    Presets.personal[identifier][weaponName] = Shared.cloneTransform(transform)
    Presets.savePersonal(identifier)
    return true
end

function Presets.deleteTransform(identifier, weaponName, scope)
    weaponName = Shared.normalizeWeaponName(weaponName)
    if not weaponName then return false end

    if scope == 'global' then
        Presets.global[weaponName] = nil
        Presets.saveGlobal()
        return true
    end

    Presets.personal[identifier] = Presets.personal[identifier] or Presets.loadPersonal(identifier)
    Presets.personal[identifier][weaponName] = nil
    Presets.savePersonal(identifier)
    return true
end

local function namedKey(identifier)
    return ('%s:%s:named:%s'):format(Shared.KvpNamespace, kvpId(), identifier)
end

function Presets.listNamed(identifier)
    if not identifier then return {} end
    local raw = GetResourceKvpString(namedKey(identifier))
    if raw and raw ~= '' then
        local ok, parsed = pcall(json.decode, raw)
        if ok and type(parsed) == 'table' then return parsed end
    end
    return {}
end

function Presets.saveNamed(identifier, name, transform)
    if not identifier or not name or name == '' or type(transform) ~= 'table' then return nil end
    local list = Presets.listNamed(identifier)
    local id = ('p_%s_%s'):format(GetGameTimer(), math.random(1000, 9999))
    list[#list + 1] = {
        id = id,
        name = name,
        transform = Shared.cloneTransform(transform),
    }
    SetResourceKvp(namedKey(identifier), json.encode(list))
    return list[#list]
end

function Presets.deleteNamed(identifier, presetId)
    if not identifier or not presetId then return false end
    local list = Presets.listNamed(identifier)
    local nextList = {}
    for i = 1, #list do
        if list[i].id ~= presetId then
            nextList[#nextList + 1] = list[i]
        end
    end
    SetResourceKvp(namedKey(identifier), json.encode(nextList))
    return true
end

Presets.loadGlobal()

return Presets
