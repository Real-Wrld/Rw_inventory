local Shared = require 'modules.rw-weapon-sling.shared'
local Items = require 'modules.items.client'

local Props = {}
local active = {}
local previewObject

local function loadWeaponAsset(hash)
    if not hash or hash == 0 then return false end
    RequestWeaponAsset(hash, 31, 0)
    local timeout = GetGameTimer() + 8000
    while not HasWeaponAssetLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end
    return HasWeaponAssetLoaded(hash)
end

local function weaponHashForName(weaponName)
    local normalized = Shared.normalizeWeaponName(weaponName) or weaponName
    local item = Items(normalized) or Items(normalized:lower()) or Items(weaponName)
    if item and item.hash then return item.hash end
    return joaat(normalized)
end

local function createWeaponEntity(weaponHash, coords)
    if not weaponHash or weaponHash == 0 then return nil end

    if loadWeaponAsset(weaponHash) then
        local object = CreateWeaponObject(weaponHash, 50, coords.x, coords.y, coords.z, true, 1.0, 0)
        if object and object ~= 0 then
            return object
        end
        object = CreateWeaponObject(weaponHash, 0, coords.x, coords.y, coords.z, true, 1.0, 0)
        if object and object ~= 0 then
            return object
        end
    end

    return nil
end

local function applyComponentsToObject(object, weaponHash, metadata)
    if not SlingConfig.UseWeaponAttachments or not metadata or not metadata.components then return end
    for i = 1, #metadata.components do
        local componentItem = Items(metadata.components[i])
        local components = componentItem and componentItem.client and componentItem.client.component
        if components then
            for j = 1, #components do
                local component = components[j]
                if DoesWeaponTakeWeaponComponent(weaponHash, component) then
                    local model = GetWeaponComponentTypeModel(component)
                    if model and model ~= 0 then
                        lib.requestModel(model, 500)
                    end
                    GiveWeaponComponentToWeaponObject(object, component)
                    if model and model ~= 0 then
                        SetModelAsNoLongerNeeded(model)
                    end
                end
            end
        end
    end

    if metadata.tint then
        SetWeaponObjectTintIndex(object, metadata.tint)
    end
end

function Props.destroyEntry(entry)
    if not entry then return end
    if entry.object and DoesEntityExist(entry.object) then
        DeleteEntity(entry.object)
    end
    if entry.hash then
        RemoveWeaponAsset(entry.hash)
    end
end

function Props.destroyAll()
    for id, entry in pairs(active) do
        Props.destroyEntry(entry)
        active[id] = nil
    end
end

function Props.destroyPreview()
    if previewObject and DoesEntityExist(previewObject) then
        DeleteEntity(previewObject)
    end
    previewObject = nil
end

local function attachObject(object, ped, transform)
    local boneKey = transform.bone or 'back'
    local boneId = Shared.boneId(boneKey)
    local offset = transform.offset or {}
    local rotation = transform.rotation or {}
    AttachEntityToEntity(
        object,
        ped,
        GetPedBoneIndex(ped, boneId),
        offset.x or 0.0,
        offset.y or 0.0,
        offset.z or 0.0,
        rotation.x or 0.0,
        rotation.y or 0.0,
        rotation.z or 0.0,
        false,
        false,
        false,
        false,
        2,
        true
    )
end

function Props.spawnAttached(ped, slingData)
    local weaponName = slingData.name
    local weaponHash = weaponHashForName(weaponName)
    if not weaponHash or weaponHash == 0 then return nil end

    local coords = GetEntityCoords(ped)
    local object = createWeaponEntity(weaponHash, coords)
    if not object then
        if SlingConfig.Debug then
            print(('[rw-sling] CreateWeaponObject failed for %s (hash %s)'):format(weaponName, weaponHash))
        end
        RemoveWeaponAsset(weaponHash)
        return nil
    end

    SetEntityCollision(object, false, false)
    SetEntityCompletelyDisableCollision(object, true, true)
    SetEntityCanBeDamaged(object, false)
    SetEntityInvincible(object, true)
    FreezeEntityPosition(object, true)

    applyComponentsToObject(object, weaponHash, slingData.metadata)
    attachObject(object, ped, slingData.transform or {})

    return {
        object = object,
        hash = weaponHash,
        name = weaponName,
        slot = slingData.slot,
    }
end

function Props.refreshLocal(ped, payload)
    Props.destroyAll()
    if not payload or payload.enabled == false or not payload.slings then return end
    if SlingConfig.HideInVehicle and cache.vehicle then return end

    for i = 1, #payload.slings do
        local sling = payload.slings[i]
        local entry = Props.spawnAttached(ped, sling)
        if entry then
            active[('%s:%s'):format(sling.slot, sling.name)] = entry
        end
    end
end

function Props.updatePreview(ped, weaponName, transform, metadata)
    Props.destroyPreview()
    local entry = Props.spawnAttached(ped, {
        name = weaponName,
        transform = transform,
        metadata = metadata or {},
    })
    previewObject = entry and entry.object or nil
    return previewObject ~= nil
end

function Props.updatePreviewTransform(ped, transform)
    if not previewObject or not DoesEntityExist(previewObject) then return end
    DetachEntity(previewObject, true, true)
    attachObject(previewObject, ped, transform)
end

return Props
