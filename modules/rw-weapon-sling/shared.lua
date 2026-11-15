---@class RwWeaponSling
RwWeaponSling = RwWeaponSling or {}

RwWeaponSling.KvpNamespace = 'rw_weapon_sling_v1'

RwWeaponSling.Bones = {
    back = {
        id = 24816,
        label = 'Back',
        offset = { x = 0.10, y = -0.16, z = -0.02 },
        rotation = { x = 0.0, y = 165.0, z = 0.0 },
    },
    chest = {
        id = 24818,
        label = 'Chest',
        offset = { x = 0.14, y = 0.20, z = 0.04 },
        rotation = { x = 180.0, y = 0.0, z = 0.0 },
    },
    front = {
        id = 24818,
        label = 'Front sling',
        offset = { x = -0.12, y = 0.18, z = 0.05 },
        rotation = { x = 0.0, y = 0.0, z = 180.0 },
    },
    hip_right = {
        id = 51826,
        label = 'Right Hip',
        offset = { x = 0.04, y = 0.10, z = 0.14 },
        rotation = { x = -90.0, y = 0.0, z = 0.0 },
    },
    hip_left = {
        id = 58271,
        label = 'Left Hip',
        offset = { x = -0.04, y = 0.10, z = 0.14 },
        rotation = { x = -90.0, y = 0.0, z = 180.0 },
    },
}

RwWeaponSling.TypePresets = {
    { id = 'pistol', label = 'Pistol', group = `GROUP_PISTOL` },
    { id = 'smg', label = 'SMG', group = `GROUP_SMG` },
    { id = 'rifle', label = 'Rifle', group = `GROUP_RIFLE` },
    { id = 'shotgun', label = 'Shotgun', group = `GROUP_SHOTGUN` },
    { id = 'sniper', label = 'Sniper', group = `GROUP_SNIPER` },
    { id = 'mg', label = 'LMG', group = `GROUP_MG` },
    { id = 'melee', label = 'Melee', group = `GROUP_MELEE` },
}

RwWeaponSling.GroupDefaults = {
    [`GROUP_PISTOL`] = {
        bone = 'hip_right',
        offset = { x = 0.04, y = 0.10, z = 0.14 },
        rotation = { x = -90.0, y = 0.0, z = 0.0 },
    },
    [`GROUP_SMG`] = {
        bone = 'front',
        offset = { x = -0.12, y = 0.18, z = 0.05 },
        rotation = { x = 0.0, y = 0.0, z = 180.0 },
    },
    [`GROUP_RIFLE`] = {
        bone = 'back',
        offset = { x = 0.10, y = -0.16, z = -0.02 },
        rotation = { x = 0.0, y = 165.0, z = 0.0 },
    },
    [`GROUP_MG`] = {
        bone = 'back',
        offset = { x = 0.08, y = -0.18, z = 0.0 },
        rotation = { x = 0.0, y = 165.0, z = 5.0 },
    },
    [`GROUP_SHOTGUN`] = {
        bone = 'back',
        offset = { x = 0.1, y = -0.14, z = 0.02 },
        rotation = { x = 0.0, y = 165.0, z = 0.0 },
    },
    [`GROUP_SNIPER`] = {
        bone = 'back',
        offset = { x = 0.06, y = -0.2, z = 0.0 },
        rotation = { x = 0.0, y = 165.0, z = 0.0 },
    },
    [`GROUP_MELEE`] = {
        bone = 'back',
        offset = { x = 0.12, y = -0.12, z = 0.0 },
        rotation = { x = 0.0, y = 90.0, z = 180.0 },
    },
}

---@param item table?
---@return boolean
function RwWeaponSling.isWeaponItem(item)
    if not item or not item.name then return false end
    if item.weapon then return true end
    local name = item.name:upper()
    return name:find('^WEAPON_', 1) ~= nil
end

function RwWeaponSling.normalizeWeaponName(name)
    if not name or name == '' then return nil end

    -- Inventory keys are already canonical: stock WEAPON_PISTOL or Khan WEAPON_ascia.
    -- Never force full :upper() — that breaks mixed-case meta spawn names.
    if name:sub(1, 7):upper() == 'WEAPON_' then
        return name
    end

    local lower = name:lower()
    if lower:sub(1, 7) == 'weapon_' then
        return 'WEAPON_' .. name:sub(8)
    end

    return ('WEAPON_%s'):format(name)
end

function RwWeaponSling.cloneTransform(transform)
    if not transform then return nil end
    return {
        bone = transform.bone,
        offset = {
            x = transform.offset and transform.offset.x or 0.0,
            y = transform.offset and transform.offset.y or 0.0,
            z = transform.offset and transform.offset.z or 0.0,
        },
        rotation = {
            x = transform.rotation and transform.rotation.x or 0.0,
            y = transform.rotation and transform.rotation.y or 0.0,
            z = transform.rotation and transform.rotation.z or 0.0,
        },
        holsteredModel = transform.holsteredModel,
        model = transform.model,
    }
end

function RwWeaponSling.mergeTransform(base, override)
    if not override then return RwWeaponSling.cloneTransform(base) end
    local out = RwWeaponSling.cloneTransform(base) or {
        bone = 'back',
        offset = { x = 0.0, y = 0.0, z = 0.0 },
        rotation = { x = 0.0, y = 0.0, z = 0.0 },
    }
    if override.bone then out.bone = override.bone end
    if override.offset then
        out.offset.x = override.offset.x or out.offset.x
        out.offset.y = override.offset.y or out.offset.y
        out.offset.z = override.offset.z or out.offset.z
    end
    if override.rotation then
        out.rotation.x = override.rotation.x or out.rotation.x
        out.rotation.y = override.rotation.y or out.rotation.y
        out.rotation.z = override.rotation.z or out.rotation.z
    end
    if override.model then out.model = override.model end
    if override.holsteredModel then out.holsteredModel = override.holsteredModel end
    return out
end

function RwWeaponSling.boneDefaultTransform(boneKey)
    local bone = RwWeaponSling.Bones[boneKey] or RwWeaponSling.Bones.back
    local key = RwWeaponSling.Bones[boneKey] and boneKey or 'back'
    return {
        bone = key,
        offset = {
            x = bone.offset and bone.offset.x or 0.0,
            y = bone.offset and bone.offset.y or 0.0,
            z = bone.offset and bone.offset.z or 0.0,
        },
        rotation = {
            x = bone.rotation and bone.rotation.x or 0.0,
            y = bone.rotation and bone.rotation.y or 0.0,
            z = bone.rotation and bone.rotation.z or 0.0,
        },
    }
end

function RwWeaponSling.typePresetsForNui()
    local list = {}
    for i = 1, #RwWeaponSling.TypePresets do
        local preset = RwWeaponSling.TypePresets[i]
        list[#list + 1] = {
            id = preset.id,
            label = preset.label,
            transform = RwWeaponSling.cloneTransform(RwWeaponSling.GroupDefaults[preset.group]),
        }
    end
    return list
end

function RwWeaponSling.boneId(boneKey)
    local bone = RwWeaponSling.Bones[boneKey]
    return bone and bone.id or RwWeaponSling.Bones.back.id
end

--- Infer weapon group on server where natives are unavailable.
---@param item table?
function RwWeaponSling.inferWeaponGroup(item)
    if not item or not item.name then return `GROUP_PISTOL` end
    local name = item.name:upper()
    if name:find('SNIPER') then return `GROUP_SNIPER` end
    if name:find('SHOTGUN') or name:find('MUSKET') then return `GROUP_SHOTGUN` end
    if name:find('MG') or name:find('MINIGUN') or name:find('GUSENBERG') then return `GROUP_MG` end
    if name:find('RIFLE') or name:find('CARBINE') or name:find('MARKSMAN') or name:find('TACTICALRIFLE') or name:find('BATTLE') then
        return `GROUP_RIFLE`
    end
    if name:find('SMG') or name:find('PDW') or name:find('TEC') or name:find('MICRO') then return `GROUP_SMG` end
    if not item.ammoname and item.weapon then return `GROUP_MELEE` end
    local ammo = tostring(item.ammoname or ''):lower()
    if ammo:find('rifle') or ammo:find('sniper') then return `GROUP_RIFLE` end
    if ammo:find('shotgun') then return `GROUP_SHOTGUN` end
    if ammo:find('smg') or ammo:find('pdw') then return `GROUP_SMG` end
    return `GROUP_PISTOL`
end

return RwWeaponSling
