--  REALWRLD Software® · ox_inventory · Admin Live Config (client)
-- ═════════════════════════════════════════════════════════════
--
--  Relay only — every permission check happens server-side.
--    • Receives the forced-settings state (mode off|defaults|locked)
--      + this player's admin flag and forwards them to the NUI.
--    • Forwards the admin's lock/apply/unlock request to the server.
--    • Relays the admin panel callbacks (`oxlynAdmin`) to the single
--      server dispatcher `ox_inventory:rwAdmin`.
-- ═════════════════════════════════════════════════════════════

if not lib then return end

local config = require 'modules.rwconfig.shared'.Get()

-- Cached so we can re-push to the NUI if it (re)mounts.
local cachedOverride = { v = 2, mode = 'off', settings = {}, updatedAt = 0 }
local cachedIsAdmin  = false
local cachedIdentifier = nil

local function pushToNui()
    local mode = cachedOverride.mode or 'off'
    local isSetter = cachedOverride.lockedBy ~= nil and cachedOverride.lockedBy == cachedIdentifier

    SendNUIMessage({
        action = 'oxlynGlobalConfig',
        data = {
            -- legacy mirror (one release): active = locked
            override = { active = mode == 'locked', setter = nil, settings = cachedOverride.settings or {} },
            server   = cachedOverride,
            mode     = mode,
            isAdmin  = cachedIsAdmin,
            isSetter = isSetter,
            locked   = mode == 'locked' and not cachedIsAdmin,
        },
    })
end

-- ─── server → client ────────────────────────────────────────
RegisterNetEvent('rw:globalConfigChanged', function(override)
    if type(override) == 'table' then
        cachedOverride = override
        pushToNui()
    end
end)

RegisterNetEvent('rw:globalConfigState', function(override, isAdmin, identifier)
    if type(override) == 'table' then cachedOverride = override end
    cachedIsAdmin = isAdmin == true
    if type(identifier) == 'string' then cachedIdentifier = identifier end
    if client then client.rwIsAdmin = cachedIsAdmin end
    pushToNui()
end)

-- ─── NUI → server ───────────────────────────────────────────
RegisterNUICallback('rwRequestGlobalConfig', function(_, cb)
    cb(1)
    TriggerServerEvent('rw:requestGlobalConfig')
    pushToNui()
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynRequestGlobalConfig', function(_, cb)
    cb(1)
    TriggerServerEvent('rw:requestGlobalConfig')
    pushToNui()
end)

-- { mode: 'off'|'defaults'|'locked', settings } — legacy { lock, settings } accepted.
RegisterNUICallback('rwSaveGlobalConfig', function(data, cb)
    cb(1)
    if type(data) ~= 'table' then return end
    local mode = data.mode
    if mode ~= 'off' and mode ~= 'defaults' and mode ~= 'locked' then mode = data.lock == true and 'locked' or 'off' end
    TriggerServerEvent('rw:saveGlobalConfig', data.settings, mode == 'locked', mode)
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynSaveGlobalConfig', function(data, cb)
    cb(1)
    if type(data) ~= 'table' then return end
    local mode = data.mode
    if mode ~= 'off' and mode ~= 'defaults' and mode ~= 'locked' then mode = data.lock == true and 'locked' or 'off' end
    TriggerServerEvent('rw:saveGlobalConfig', data.settings, mode == 'locked', mode)
end)

-- ─── editor open helper (settings-schema §4.5) ──────────────
local editorCfg = type(config.Editor) == 'table' and config.Editor or {}
local lastEditorOpen = 0

local function openEditor(tab)
    if not (client and client.uiLoaded) then return end
    local now = GetGameTimer()
    if now - lastEditorOpen < 300 then return end
    lastEditorOpen = now

    local allowed = lib.callback.await('ox_inventory:rwEditorAccess', false)
    if not allowed then
        return lib.notify({ id = 'rw_editor_locked', type = 'error', description = locale('rw_editor_locked') })
    end
    if client.player and not client.player:get('invOpen') then
        if client.openInventory then client.openInventory() end
        local deadline = GetGameTimer() + 1000
        repeat Wait(50) until client.player:get('invOpen') or GetGameTimer() > deadline
        if not client.player:get('invOpen') then return end
    end
    SendNUIMessage({ action = 'oxlynOpenEditor', data = { tab = tab } })
end

if editorCfg.command ~= false then
    RegisterCommand(editorCfg.command or 'invsettings', function() openEditor() end, false)
    -- straight into on-screen text editing (Settings › Texts › Edit on screen)
    RegisterCommand(editorCfg.textsCommand or 'invtexts', function() openEditor('texts') end, false)
end

RegisterNUICallback('rwEditorState', function(data, cb)
    cb(1)
    local open = type(data) == 'table' and data.open == true
    if client then
        client.invEditor = open -- read by the per-frame tick in client.lua (no state-bag lookup there)
        if client.player then client.player:set('invEditor', open) end
    end
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynEditorState', function(data, cb)
    cb(1)
    local open = type(data) == 'table' and data.open == true
    if client then
        client.invEditor = open -- read by the per-frame tick in client.lua (no state-bag lookup there)
        if client.player then client.player:set('invEditor', open) end
    end
end)

-- ─── admin panel relay (admin-logs §8.1) ────────────────────
local ADMIN_ACTIONS = {
    'logsQuery', 'logsStats', 'logsExport', 'logsSubscribe', 'logsMeta',
    'webhooksGet', 'webhooksSet', 'webhooksTest',
    'propMapGet', 'propMapSet',
    'lockGet', 'lockSet',
    'serverSettingsGet', 'serverSettingsSet',
    'adminWho',
    'logsSince', 'playersList', 'playerGet',
    'dropsList', 'dropsTeleport', 'dropsRemove',
}

-- The server knows where a drop is, only the client can name the place:
-- street (+ crossing), zone label and the distance from the admin.
local function placeOf(x, y, z)
    local street, zone
    local ok, s1, s2 = pcall(GetStreetNameAtCoord, x, y, z)
    if ok and s1 and s1 ~= 0 then
        street = GetStreetNameFromHashKey(s1)
        if s2 and s2 ~= 0 then
            local cross = GetStreetNameFromHashKey(s2)
            if cross and cross ~= '' then street = ('%s / %s'):format(street, cross) end
        end
    end
    local okZ, code = pcall(GetNameOfZone, x, y, z)
    if okZ and type(code) == 'string' and code ~= '' then
        local label = GetLabelText(code)
        zone = (label and label ~= 'NULL' and label ~= '') and label or code
    end
    return street ~= '' and street or nil, zone
end

local AUGMENT = {
    dropsList = function(result)
        if type(result) ~= 'table' or type(result.rows) ~= 'table' then return result end
        local me = GetEntityCoords(PlayerPedId())
        for i = 1, #result.rows do
            local r = result.rows[i]
            local c = type(r) == 'table' and r.coords
            if type(c) == 'table' and tonumber(c.x) and tonumber(c.y) then
                local x, y, z = c.x + 0.0, c.y + 0.0, (tonumber(c.z) or 0) + 0.0
                r.street, r.zone = placeOf(x, y, z)
                r.distance = math.floor(#(me - vector3(x, y, z)) * 10 + 0.5) / 10
            end
        end
        return result
    end,
}

local function adminCall(action, data, cb)
    local ok, result = lib.callback.await('ox_inventory:rwAdmin', false, action, type(data) == 'table' and data or {})
    if ok then
        local fix = AUGMENT[action]
        if fix then
            local fine, fixed = pcall(fix, result)
            if fine then result = fixed end
        end
        cb({ ok = true, data = result })
    else
        cb({ ok = false, error = result or 'internal' })
    end
end

-- Teleport to a ground drop (admin window › Drops). Sent by the server only
-- after dropsTeleport passed the admin + RWInv.Admin.teleport checks.
RegisterNetEvent('ox_inventory:rwAdminTeleport', function(coords)
    if type(coords) ~= 'table' then return end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not (x and y and z) then return end
    local ped = PlayerPedId()
    -- stand next to the drop, not on top of its props
    x = x + 0.9
    RequestCollisionAtCoord(x, y, z)
    SetEntityCoords(ped, x, y, z + 0.4, false, false, false, false)
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNetEvent('ox_inventory:oxlynAdminTeleport', function(coords)
    if type(coords) ~= 'table' then return end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not (x and y and z) then return end
    local ped = PlayerPedId()
    -- stand next to the drop, not on top of its props
    x = x + 0.9
    RequestCollisionAtCoord(x, y, z)
    SetEntityCoords(ped, x, y, z + 0.4, false, false, false, false)
end)

for i = 1, #ADMIN_ACTIONS do
    local action = ADMIN_ACTIONS[i]
    RegisterNUICallback('rwAdmin:' .. action, function(data, cb) adminCall(action, data, cb) end)
    RegisterNUICallback('oxlynAdmin:' .. action, function(data, cb) adminCall(action, data, cb) end) -- legacy alias (RW rename)
end

-- Generic passthrough: { action, payload } (dotted drops.* names, settings.* aliases).
RegisterNUICallback('rwAdmin', function(data, cb)
    if type(data) ~= 'table' or type(data.action) ~= 'string' then return cb({ ok = false, error = 'bad_payload' }) end
    adminCall(data.action, data.payload, cb)
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynAdmin', function(data, cb)
    if type(data) ~= 'table' or type(data.action) ~= 'string' then return cb({ ok = false, error = 'bad_payload' }) end
    adminCall(data.action, data.payload, cb)
end)

-- Live tail relay (§5)
RegisterNetEvent('ox_inventory:rwAdminTail', function(batch)
    if type(batch) == 'table' then SendNUIMessage({ action = 'oxlynAdminLogTail', data = batch }) end
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNetEvent('ox_inventory:oxlynAdminTail', function(batch)
    if type(batch) == 'table' then SendNUIMessage({ action = 'oxlynAdminLogTail', data = batch }) end
end)

-- "Open the logs" command (RWInv.Admin.command, default 'invlogs'):
-- opens the full-screen admin window (NUI `oxlynOpenAdmin`). Same focus
-- model as the editor: the window lives inside the inventory NUI, so the
-- inventory is opened first (it owns SetNuiFocus); when this command had
-- to open it, closing the window closes the inventory again.
local adminCfg = type(config.Admin) == 'table' and config.Admin or {}
local ADMIN_TABS = { overview = true, live = true, logs = true, players = true, webhooks = true, drops = true, props = true, lock = true, server = true }

local function openAdminWindow(tab)
    if not (client and client.uiLoaded) then return end
    local now = GetGameTimer()
    if now - lastEditorOpen < 300 then return end
    lastEditorOpen = now

    -- server-side check (admin rights + RWInv.Admin.panel), never trust the cache alone
    local ok, err = lib.callback.await('ox_inventory:rwAdmin', false, 'adminWho', {})
    if not ok then
        local key = err == 'feature_disabled' and 'rw_admin_disabled' or 'rw_admin_no_access'
        return lib.notify({ id = 'rw_admin_denied', type = 'error', description = locale(key) })
    end

    local openedHere = false
    if client.player and not client.player:get('invOpen') then
        if client.openInventory then client.openInventory() end
        local deadline = GetGameTimer() + 1000
        repeat Wait(50) until client.player:get('invOpen') or GetGameTimer() > deadline
        if not client.player:get('invOpen') then return end
        openedHere = true
    end
    SendNUIMessage({ action = 'oxlynOpenAdmin', data = { tab = ADMIN_TABS[tab] and tab or 'logs', closeInventoryOnExit = openedHere } })
end

if adminCfg.command ~= false then
    RegisterCommand(adminCfg.command or 'invlogs', function(_, args) openAdminWindow(args and args[1]) end, false)
end

-- ─── initial sync ───────────────────────────────────────────
CreateThread(function()
    while not (client and client.uiLoaded) do Wait(100) end
    Wait(250)
    TriggerServerEvent('rw:requestGlobalConfig')
end)

-- Re-request after a framework login (admin status may resolve late).
RegisterNetEvent('esx:playerLoaded', function()
    SetTimeout(3000, function() TriggerServerEvent('rw:requestGlobalConfig') end)
end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetTimeout(3000, function() TriggerServerEvent('rw:requestGlobalConfig') end)
end)
