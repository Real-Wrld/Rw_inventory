if not lib then return end

local Shared = require 'modules.rw-weapon-sling.shared'
local Presets = require 'modules.rw-weapon-sling.server.presets'
local Items = require 'modules.items.server'

local SlingServer = {}

local function getIdentifier(source)
    local inv = exports.ox_inventory:GetInventory(source)
    if inv and inv.owner then return inv.owner end
    return GetPlayerIdentifierByType(source, 'license') or ('player:%s'):format(source)
end

local function discordIdentifier(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:find('discord:') then return id end
    end
end

function SlingServer.isAdmin(source)
    local admin = SlingConfig.Admin and SlingConfig.Admin.Global
    if not admin or not admin.enabled then return false end

    if IsPlayerAceAllowed(source, 'ox_inventory.admin') then return true end
    if IsPlayerAceAllowed(source, 'group.admin') then return true end

    local player = exports.qbx_core:GetPlayer(source)
    if player and player.PlayerData then
        local group = player.PlayerData.group
        if group == 'admin' or group == 'god' then return true end
    end

    local commandName = SlingConfig.Command and SlingConfig.Command.name or 'sling'
    if IsPlayerAceAllowed(source, 'command.' .. commandName) then return true end
    if admin.ace and IsPlayerAceAllowed(source, admin.ace) then return true end

    local presetCommand = SlingConfig.Presets and SlingConfig.Presets.command or 'slingpreset'
    if IsPlayerAceAllowed(source, 'command.' .. presetCommand) then return true end

    local discord = discordIdentifier(source)
    if discord and type(admin.players) == 'table' then
        for i = 1, #admin.players do
            if admin.players[i] == discord then return true end
        end
    end

    return false
end

local function syncAllPlayers()
    for _, playerId in ipairs(GetPlayers()) do
        SlingServer.syncPlayer(tonumber(playerId))
    end
end

local function buildAdminWeaponCatalog(identifier)
    local weapons = {}
    local seen = {}
    local weaponsData = lib.load('data.weapons') or {}
    local catalog = weaponsData.Weapons or {}

    for name, def in pairs(catalog) do
        local weaponName = Shared.normalizeWeaponName(name)
        if weaponName and not seen[weaponName] and not (SlingConfig.Blacklist and SlingConfig.Blacklist[weaponName]) then
            seen[weaponName] = true
            local group = weaponGroupFor(name)
            local transform = Presets.getTransform(identifier, weaponName, group)
            if Presets.global[weaponName] then
                transform = Shared.cloneTransform(Presets.global[weaponName])
            end
            weapons[#weapons + 1] = {
                slot = 0,
                name = weaponName,
                label = def.label or weaponName,
                enabled = true,
                transform = transform,
                metadata = {},
                group = group,
                catalog = true,
            }
        end
    end

    for weaponName, def in pairs(SlingConfig.Weapons or {}) do
        weaponName = Shared.normalizeWeaponName(weaponName)
        if weaponName and not seen[weaponName] and not (SlingConfig.Blacklist and SlingConfig.Blacklist[weaponName]) then
            seen[weaponName] = true
            local group = weaponGroupFor(weaponName)
            local transform = Presets.global[weaponName] and Shared.cloneTransform(Presets.global[weaponName])
                or Presets.getTransform(identifier, weaponName, group)
            weapons[#weapons + 1] = {
                slot = 0,
                name = weaponName,
                label = weaponName,
                enabled = true,
                transform = transform,
                metadata = {},
                group = group,
                catalog = true,
            }
        end
    end

    table.sort(weapons, function(a, b)
        return (a.label or a.name) < (b.label or b.name)
    end)

    return weapons
end

local function weaponGroupFor(itemName)
    local item = Items(itemName)
    return Shared.inferWeaponGroup(item)
end

local function isWeaponEntry(item)
    if not item or not item.name then return false end
    local itemData = Items(item.name)
    return (itemData and itemData.weapon) or Shared.isWeaponItem(item)
end

function SlingServer.buildPayload(source)
    local inventory = exports.ox_inventory:GetInventoryItems(source)
    if not inventory then return { enabled = true, slings = {} } end

    local identifier = getIdentifier(source)
    local prefs = Presets.loadPrefs(identifier)
    local slings = {}
    local equipped = exports.ox_inventory:GetCurrentWeapon(source)
    local equippedSlot = equipped and equipped.slot

    for slot, item in pairs(inventory) do
        if isWeaponEntry(item) then
            local weaponName = Shared.normalizeWeaponName(item.name)
            if weaponName and not (SlingConfig.Blacklist and SlingConfig.Blacklist[weaponName]) then
                if slot ~= equippedSlot and not (prefs.hidden and prefs.hidden[weaponName]) then
                    local group = weaponGroupFor(item.name)
                    local transform = Presets.getTransform(identifier, weaponName, group)
                    if item.metadata and item.metadata.sling then
                        transform = Shared.mergeTransform(transform, item.metadata.sling)
                    end
                    slings[#slings + 1] = {
                        slot = slot,
                        name = weaponName,
                        label = item.label or weaponName,
                        group = group,
                        transform = transform,
                        metadata = {
                            components = item.metadata and item.metadata.components or {},
                            tint = item.metadata and item.metadata.tint,
                            specialAmmo = item.metadata and item.metadata.specialAmmo,
                        },
                    }
                end
            end
        end
    end

    table.sort(slings, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
    local maxVisible = SlingConfig.MaxVisibleSlings or 4
    while #slings > maxVisible do slings[#slings] = nil end

    return {
        enabled = prefs.enabled ~= false,
        slings = slings,
    }
end

function SlingServer.syncPlayer(source)
    local payload = SlingServer.buildPayload(source)
    Player(source).state:set('rwSlings', payload, true)
    return payload
end

lib.callback.register('rw-inventory:sling:canOpenEditor', function(source, adminMode)
    if adminMode == true then
        return SlingServer.isAdmin(source)
    end
    return true
end)

lib.callback.register('rw-inventory:sling:getEditorData', function(source, adminEditor)
    local identifier = getIdentifier(source)
    local prefs = Presets.loadPrefs(identifier)
    local isAdmin = SlingServer.isAdmin(source)

    if adminEditor == true and not isAdmin then
        return nil
    end

    local weapons = {}

    if adminEditor == true then
        weapons = buildAdminWeaponCatalog(identifier)
    else
        local inventory = exports.ox_inventory:GetInventoryItems(source)
        if inventory then
            for slot, item in pairs(inventory) do
                if isWeaponEntry(item) then
                    local weaponName = Shared.normalizeWeaponName(item.name)
                    if weaponName and not (SlingConfig.Blacklist and SlingConfig.Blacklist[weaponName]) then
                        local group = weaponGroupFor(item.name)
                        local transform = Presets.getTransform(identifier, weaponName, group)
                        if Presets.global[weaponName] then
                            transform = Shared.mergeTransform(transform, Presets.global[weaponName])
                        end
                        if item.metadata and item.metadata.sling then
                            transform = Shared.mergeTransform(transform, item.metadata.sling)
                        end
                        weapons[#weapons + 1] = {
                            slot = slot,
                            name = weaponName,
                            label = item.label or weaponName,
                            enabled = not (prefs.hidden and prefs.hidden[weaponName]),
                            transform = transform,
                            metadata = item.metadata or {},
                        }
                    end
                end
            end
            table.sort(weapons, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
        end
    end

    return {
        weapons = weapons,
        bones = Shared.Bones,
        typePresets = Shared.typePresetsForNui(),
        namedPresets = Presets.listNamed(identifier),
        isAdmin = isAdmin,
        enabled = prefs.enabled ~= false,
        isPreset = adminEditor == true,
    }
end)

lib.callback.register('rw-inventory:sling:saveTransform', function(source, data)
    if type(data) ~= 'table' or not data.weaponName or type(data.transform) ~= 'table' then
        return false, 'invalid_data'
    end

    local identifier = getIdentifier(source)
    local scope = data.scope == 'global' and 'global' or 'personal'
    if scope == 'global' and not SlingServer.isAdmin(source) then
        return false, 'no_permission'
    end

    Presets.setTransform(identifier, data.weaponName, data.transform, scope)
    if scope == 'global' then
        syncAllPlayers()
    else
        SlingServer.syncPlayer(source)
    end
    return true
end)

lib.callback.register('rw-inventory:sling:resetTransform', function(source, data)
    if type(data) ~= 'table' or not data.weaponName then return false end
    local identifier = getIdentifier(source)
    local scope = data.scope == 'global' and 'global' or 'personal'
    if scope == 'global' and not SlingServer.isAdmin(source) then
        return false, 'no_permission'
    end
    Presets.deleteTransform(identifier, data.weaponName, scope)
    if scope == 'global' then
        syncAllPlayers()
    else
        SlingServer.syncPlayer(source)
    end
    return true
end)

lib.callback.register('rw-inventory:sling:setWeaponEnabled', function(source, weaponName, enabled)
    local identifier = getIdentifier(source)
    local prefs = Presets.loadPrefs(identifier)
    prefs.hidden = prefs.hidden or {}
    weaponName = Shared.normalizeWeaponName(weaponName)
    if not weaponName then return false end
    if enabled then
        prefs.hidden[weaponName] = nil
    else
        prefs.hidden[weaponName] = true
    end
    Presets.savePrefs(identifier, prefs)
    SlingServer.syncPlayer(source)
    return true
end)

lib.callback.register('rw-inventory:sling:setEnabled', function(source, enabled)
    local identifier = getIdentifier(source)
    local prefs = Presets.loadPrefs(identifier)
    prefs.enabled = enabled == true
    Presets.savePrefs(identifier, prefs)
    SlingServer.syncPlayer(source)
    return true
end)

lib.callback.register('rw-inventory:sling:listNamedPresets', function(source)
    return Presets.listNamed(getIdentifier(source))
end)

lib.callback.register('rw-inventory:sling:saveNamedPreset', function(source, data)
    if type(data) ~= 'table' or not data.name or type(data.transform) ~= 'table' then return nil end
    return Presets.saveNamed(getIdentifier(source), data.name, data.transform)
end)

lib.callback.register('rw-inventory:sling:deleteNamedPreset', function(source, presetId)
    return Presets.deleteNamed(getIdentifier(source), presetId) == true
end)

RegisterNetEvent('rw-inventory:sling:requestSync', function()
    SlingServer.syncPlayer(source)
end)

local function scheduleSync(playerId)
    if not playerId then return end
    SetTimeout(75, function()
        if GetPlayerPing(playerId) > 0 then
            SlingServer.syncPlayer(playerId)
        end
    end)
end

CreateThread(function()
    while not shared.ready do Wait(100) end
    exports.ox_inventory:registerHook('swapItems', function(payload)
        scheduleSync(payload.source)
    end)
end)

AddEventHandler('ox_inventory:usedItem', function(playerId, itemName, metadata)
    local itemData = Items(itemName)
    if isWeaponEntry({ name = itemName, weapon = itemData and itemData.weapon }) then
        scheduleSync(playerId)
    end
end)

AddEventHandler('ox_inventory:setPlayerInventory', function(player)
    if type(player) == 'table' and player.source then
        scheduleSync(player.source)
    end
end)

exports('SlingSyncPlayer', SlingServer.syncPlayer)
exports('SlingIsAdmin', SlingServer.isAdmin)
exports('SlingGetTransform', function(source, weaponName)
    return Presets.getTransform(getIdentifier(source), weaponName, weaponGroupFor(weaponName))
end)

return SlingServer
