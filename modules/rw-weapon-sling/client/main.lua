if not lib then return end

local Shared = require 'modules.rw-weapon-sling.shared'
local Props = require 'modules.rw-weapon-sling.client.props'
local Remote = require 'modules.rw-weapon-sling.client.sync'
local EditorCam = require 'modules.rw-weapon-sling.client.camera'
local Studio = require 'modules.rw-weapon-sling.client.studio'
local CharacterPreview = require 'modules.character.client'

local Sling = {
    editorOpen = false,
    selectedWeapon = nil,
    selectedTransform = nil,
    selectedMetadata = nil,
    isPreset = false,
}

local notifyFn

local function notify(type, text)
    if notifyFn then
        notifyFn(type, text)
        return
    end
    lib.notify({
        title = 'RW-Inventory Sling',
        description = text,
        type = type or 'inform',
    })
end

local function refreshLocal()
    local payload = LocalPlayer.state.rwSlings
    Props.refreshLocal(cache.ped, payload)
end

local function requestSync()
    TriggerServerEvent('rw-inventory:sling:requestSync')
end

function Sling.forceRefresh()
    requestSync()
    refreshLocal()
end

local function formatBonesForNui()
    local bones = {}
    for key, bone in pairs(Shared.Bones) do
        if type(bone) == 'table' then
            bones[key] = {
                id = bone.id,
                label = bone.label or key,
                offset = bone.offset,
                rotation = bone.rotation,
            }
        elseif type(bone) == 'number' then
            bones[key] = {
                id = bone,
                label = key:gsub('_', ' '),
            }
        end
    end
    return bones
end

local function normalizeTransformForNui(transform)
    transform = transform or {}
    local offset = transform.offset or {}
    local rotation = transform.rotation or {}
    return {
        bone = transform.bone or 'back',
        offset = {
            x = offset.x or 0.0,
            y = offset.y or 0.0,
            z = offset.z or 0.0,
        },
        rotation = {
            x = rotation.x or 0.0,
            y = rotation.y or 0.0,
            z = rotation.z or 0.0,
        },
    }
end

local function formatWeaponsForNui(weapons)
    local formatted = {}
    if type(weapons) ~= 'table' then return formatted end

    for i = 1, #weapons do
        local weapon = weapons[i]
        if weapon and weapon.name then
            formatted[#formatted + 1] = {
                slot = weapon.slot or 0,
                name = weapon.name,
                label = weapon.label or weapon.name,
                enabled = weapon.enabled ~= false,
                transform = normalizeTransformForNui(weapon.transform),
                metadata = weapon.metadata or {},
            }
        end
    end

    return formatted
end

local function closeEditor()
    if not Sling.editorOpen then return end
    Sling.editorOpen = false
    Sling.selectedWeapon = nil
    Sling.selectedTransform = nil
    Sling.selectedMetadata = nil
    Props.destroyPreview()
    EditorCam.stop()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeSlingEditor' })
    requestSync()
end

local function previewPed()
    return Studio.ensurePed() or Studio.getPed() or cache.ped
end

local function openEditor(adminEditor)
    if Sling.editorOpen then return end

    local canOpen = lib.callback.await('rw-inventory:sling:canOpenEditor', false, adminEditor == true)
    if not canOpen then
        notify('error', locale('sling.error.no_permission') or 'You do not have permission to use the Advanced Weapon Sling Editor.')
        return
    end

    local data = lib.callback.await('rw-inventory:sling:getEditorData', false, adminEditor == true)
    if not data then
        notify('error', locale('sling.error.load_failed') or 'Could not open the Advanced Weapon Sling Editor.')
        return
    end

    local weapons = formatWeaponsForNui(data.weapons)
    if #weapons == 0 then
        notify('error', adminEditor and 'No weapons in catalog.' or 'Put weapons in your inventory first, or use /sling admin for the full catalog.')
        return
    end

    if LocalPlayer.state.invOpen then
        exports.ox_inventory:closeInventory()
        Wait(200)
    end

    CharacterPreview.close()
    Wait(100)

    Sling.editorOpen = true
    Sling.isPreset = adminEditor == true

    Props.destroyAll()
    if not EditorCam.start() then
        Sling.editorOpen = false
        notify('error', 'Could not start sling preview studio.')
        return
    end
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openSlingEditor',
        data = {
            weapons = weapons,
            bones = formatBonesForNui(),
            typePresets = Shared.typePresetsForNui(),
            namedPresets = lib.callback.await('rw-inventory:sling:listNamedPresets', false) or {},
            isAdmin = data.isAdmin == true,
            enabled = data.enabled ~= false,
            isPreset = Sling.isPreset,
            brand = 'RW-Inventory',
        },
    })
end

function Sling.startConfiguration(isPreset)
    openEditor(isPreset ~= false)
end

function Sling.startPositioning(selectData)
    openEditor(true)
    if type(selectData) == 'table' and selectData.weaponName then
        Wait(200)
        SendNUIMessage({
            action = 'slingSelectWeapon',
            data = { weaponName = Shared.normalizeWeaponName(selectData.weaponName) },
        })
    end
end

local function selectWeaponForEdit(weaponName, transform, metadata)
    Sling.selectedWeapon = weaponName
    Sling.selectedTransform = Shared.cloneTransform(transform)
    Sling.selectedMetadata = metadata or {}
    local ped = previewPed()
    local ok = Props.updatePreview(ped, weaponName, Sling.selectedTransform, Sling.selectedMetadata)
    if not ok and SlingConfig.Debug then
        print(('[rw-sling] Failed to preview weapon %s on ped %s'):format(weaponName, ped))
    end
end

RegisterNUICallback('slingEditor:close', function(_, cb)
    closeEditor()
    cb(1)
end)

RegisterNUICallback('slingEditor:selectWeapon', function(data, cb)
    if not data or not data.weaponName then cb(0) return end
    selectWeaponForEdit(data.weaponName, normalizeTransformForNui(data.transform), data.metadata or {})
    cb(1)
end)

RegisterNUICallback('slingEditor:updateTransform', function(data, cb)
    if not Sling.selectedWeapon or type(data) ~= 'table' or type(data.transform) ~= 'table' then
        cb(0)
        return
    end
    Sling.selectedTransform = Shared.mergeTransform(Sling.selectedTransform, data.transform)
    Props.updatePreviewTransform(previewPed(), Sling.selectedTransform)
    cb(1)
end)

RegisterNUICallback('slingEditor:rotate', function(data, cb)
    if data and data.value then
        Studio.rotate(data.value * 5.0)
    end
    cb(1)
end)

RegisterNUICallback('slingEditor:save', function(data, cb)
    if not data or not data.weaponName or not data.transform then cb(0) return end
    local ok = lib.callback.await('rw-inventory:sling:saveTransform', false, {
        weaponName = data.weaponName,
        transform = data.transform,
        scope = data.scope == 'global' and 'global' or 'personal',
    })
    if ok then
        notify('success', locale('sling.success.saved') or 'Sling position saved.')
        requestSync()
    else
        notify('error', locale('sling.error.save_failed') or 'Could not save sling position.')
    end
    cb(ok and 1 or 0)
end)

RegisterNUICallback('slingEditor:reset', function(data, cb)
    if not data or not data.weaponName then cb(0) return end
    local ok = lib.callback.await('rw-inventory:sling:resetTransform', false, {
        weaponName = data.weaponName,
        scope = data.scope == 'global' and 'global' or 'personal',
    })
    if ok then
        notify('inform', locale('sling.success.reset') or 'Sling position reset.')
        requestSync()
    end
    cb(ok and 1 or 0)
end)

RegisterNUICallback('slingEditor:toggleWeapon', function(data, cb)
    if not data or not data.weaponName then cb(0) return end
    local ok = lib.callback.await('rw-inventory:sling:setWeaponEnabled', false, data.weaponName, data.enabled == true)
    if ok then requestSync() end
    cb(ok and 1 or 0)
end)

RegisterNUICallback('slingEditor:setEnabled', function(data, cb)
    local ok = lib.callback.await('rw-inventory:sling:setEnabled', false, data and data.enabled == true)
    if ok then requestSync() end
    cb(ok and 1 or 0)
end)

RegisterNUICallback('slingEditor:saveNamedPreset', function(data, cb)
    if not data or not data.name or not data.transform then cb(nil) return end
    local saved = lib.callback.await('rw-inventory:sling:saveNamedPreset', false, {
        name = data.name,
        transform = data.transform,
    })
    cb(saved or false)
end)

RegisterNUICallback('slingEditor:deleteNamedPreset', function(data, cb)
    local ok = lib.callback.await('rw-inventory:sling:deleteNamedPreset', false, data and data.id)
    cb(ok and 1 or 0)
end)

RegisterNUICallback('slingEditor:listNamedPresets', function(_, cb)
    cb(lib.callback.await('rw-inventory:sling:listNamedPresets', false) or {})
end)

AddStateBagChangeHandler('rwSlings', ('player:%s'):format(cache.serverId), function(_, _, value)
    if Sling.editorOpen then return end
    Props.refreshLocal(cache.ped, value)
end)

AddEventHandler('ox_inventory:currentWeapon', function(weapon)
    if SlingConfig.HideWhenEquipped == false then return end
    requestSync()
end)

AddEventHandler('ox_inventory:updateInventory', function()
    if Sling.editorOpen then return end
    requestSync()
end)

RegisterNetEvent('ox_inventory:disarm', function()
    requestSync()
end)

RegisterNetEvent('ox_inventory:clearWeapons', function()
    Props.destroyAll()
    requestSync()
end)

lib.onCache('vehicle', function()
    if SlingConfig.HideInVehicle then
        Props.destroyAll()
        if not cache.vehicle then
            refreshLocal()
        end
    end
end)

lib.onCache('ped', function()
    requestSync()
end)

CreateThread(function()
    repeat Wait(500) until NetworkIsPlayerActive(PlayerId())
    Wait(1500)
    requestSync()
end)

RegisterNetEvent('ox_inventory:setPlayerInventory', function()
    SetTimeout(500, requestSync)
end)

RegisterCommand(SlingConfig.Command and SlingConfig.Command.name or 'sling', function(_, args)
    local adminMode = args[1] == 'admin' or args[1] == 'presets'
    openEditor(adminMode)
end, false)

TriggerEvent('chat:addSuggestion', '/' .. (SlingConfig.Command and SlingConfig.Command.name or 'sling'), SlingConfig.Command and SlingConfig.Command.description or 'Weapon sling editor — use /sling admin for global presets')

local presetCommand = SlingConfig.Presets and SlingConfig.Presets.command or 'slingpreset'
RegisterCommand(presetCommand, function()
    openEditor(true)
end, false)

TriggerEvent('chat:addSuggestion', '/' .. presetCommand, 'Admin global weapon sling presets')

RegisterNetEvent('rw-inventory:sling:forceRefresh', Sling.forceRefresh)

exports('StartConfiguration', Sling.startConfiguration)
exports('StartPositioning', Sling.startPositioning)
exports('forceRefresh', Sling.forceRefresh)
exports('customNotify', function(fn)
    notifyFn = fn
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    closeEditor()
    EditorCam.stop()
    Props.destroyAll()
    Remote.clearAll()
end)

return Sling
