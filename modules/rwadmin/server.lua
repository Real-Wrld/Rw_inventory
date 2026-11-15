--  REALWRLD Software® · ox_inventory · Admin Live Config (server)
-- ═════════════════════════════════════════════════════════════
--
--  Lets an admin push their inventory UI settings to every player
--  and lock them ("Save for everyone & lock"). The override is
--  persisted in resource KVP (survives restarts) and broadcast to
--  all clients. Permission is verified SERVER-SIDE so the UI cannot
--  be patched to fake admin rights.
-- ═════════════════════════════════════════════════════════════

if not lib then return end

local KVP_KEY = 'rw:globalConfig'

-- ─── buyer-editable config (parsed once, shared) ────────────
local config = require 'modules.rwconfig.shared'.Get()
local DEBUG  = config.Debug == true
local Log    = require 'modules.rwlogs.server'
local schema = require 'modules.rwadmin.shared'

-- ═════════════════════════════════════════════════════════════
--  PERMISSIONS — one pattern, every framework
-- ═════════════════════════════════════════════════════════════
--
--  "I am admin and it says I have no access" is the single most common
--  ticket, and almost always it is a framework-detection or ordering
--  problem, not a config problem. So the check below is a UNION (OR)
--  of independent sources — ONE source saying yes is enough:
--
--    0. RWInv.IsAdmin(src) override hook in config.lua (if it
--       returns a boolean, that is the final answer).
--    1. ACE object(s) in RWInv.AdminAce            (framework-agnostic)
--    2. Identifiers in RWInv.AdminIdentifiers      (framework-agnostic)
--    3. ACE bridge for every group name in RWInv.AdminGroups:
--         <group> · group.<group> · qbcore.<group> · qbx.<group>
--       (this is what makes txAdmin / add_principal work on any fw)
--    4. The framework's own answer: QBox → QBCore → ESX
--
--  Everything framework-related runs inside pcall — a missing or
--  half-started framework degrades to "no" from THAT source only, it
--  never throws and never poisons the other sources.
--
--  server.cfg recipe (must be present at SERVER START — a resource
--  restart does not re-read aces; paste it in the console to apply
--  immediately):
--     add_ace group.admin rw.admin allow
--     add_principal identifier.license:YOUR_LICENSE group.admin
-- ═════════════════════════════════════════════════════════════

-- Groups: accepts the array form { 'admin', 'god' } AND the hash-set
-- form { admin = true } (buyers copy configs between REALWRLD products).
-- Matched case-insensitively.
local adminGroups, adminGroupList = {}, {}

do
    local raw = type(config.AdminGroups) == 'table' and config.AdminGroups or {}

    local function addGroup(name)
        if type(name) ~= 'string' or name == '' then return end
        name = name:lower()
        if adminGroups[name] then return end
        adminGroups[name] = true
        adminGroupList[#adminGroupList + 1] = name
    end

    for _, g in ipairs(raw) do addGroup(g) end
    for k, v in pairs(raw) do
        if type(k) == 'string' and v == true then addGroup(k) end
    end
end

-- ACE object(s): a string, a list of strings, or false/'' to disable.
local adminAces = {}

do
    local raw = config.AdminAce
    if raw == nil then raw = 'rw.admin' end

    if type(raw) == 'string' then
        if raw ~= '' then adminAces[1] = raw end
    elseif type(raw) == 'table' then
        for _, ace in ipairs(raw) do
            if type(ace) == 'string' and ace ~= '' then adminAces[#adminAces + 1] = ace end
        end
    end
end

-- Identifiers: 'license:…', 'discord:…', 'steam:…', 'fivem:…', 'license2:…'.
-- Normalised so the classic mistakes still match: case, surrounding
-- whitespace and the doubled prefix ('license:license:…').
local adminIdentifiers = {}

local function normaliseIdentifier(id)
    if type(id) ~= 'string' then return end
    id = id:gsub('^%s+', ''):gsub('%s+$', ''):lower()
    if id == '' then return end
    -- 'license:license:abc' → 'license:abc'
    id = id:gsub('^(%a+%d*):%1:', '%1:')
    -- A bare Discord snowflake is unambiguous.
    if id:match('^%d%d%d%d%d%d%d%d%d%d%d%d+$') then id = 'discord:' .. id end
    return id
end

do
    local raw = type(config.AdminIdentifiers) == 'table' and config.AdminIdentifiers or {}
    for _, id in ipairs(raw) do
        local norm = normaliseIdentifier(id)
        if norm then adminIdentifiers[norm] = true end
    end
end

local adminOverride = type(config.IsAdmin) == 'function' and config.IsAdmin or nil

-- ─── framework detection (resolved ONCE, then cached) ───────
--
--  PERFORMANCE — READ THIS BEFORE CHANGING IT.
--  `exports['es_extended']:getSharedObject()` and
--  `exports['qb-core']:GetCoreObject()` are NOT cheap getters: every
--  call crosses the resource boundary and copies the framework's whole
--  object graph (ESX.Players / QBCore.Functions / QBCore.Shared …) into
--  this resource. On a populated server that costs hundreds of ms PER
--  CALL — it showed up in the server profiler as ~367 ms average
--  (809 ms worst) on `rw:requestGlobalConfig`, i.e. more than 80% of
--  ox_inventory's whole server-side self time.
--
--  So the framework object is resolved AT MOST ONCE. While nothing is
--  started yet (server boot) we re-probe every 10 s instead of on every
--  permission check.
--
--  Detection order is QBox → QBCore → ESX. qbx_core `provide`s qb-core,
--  so on a QBox server GetResourceState('qb-core') also reports
--  'started' — QBox has to be tested first or it is mistaken for QBCore.
local fwName, fwObject
local fwNextProbe = 0
local FW_PROBE_INTERVAL_MS = 10000

local function getFramework()
    -- Fast path: already resolved, no cross-resource call at all.
    if fwName then return fwName, fwObject end

    local now = GetGameTimer()
    if now < fwNextProbe then return 'unknown' end
    fwNextProbe = now + FW_PROBE_INTERVAL_MS

    if GetResourceState('qbx_core') == 'started' then
        fwName = 'qbx'
        return fwName
    end

    if GetResourceState('qb-core') == 'started' then
        local ok, QB = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and type(QB) == 'table' then
            fwName, fwObject = 'qb', QB
            return fwName, fwObject
        end
    end

    if GetResourceState('es_extended') == 'started' then
        local ok, ESX = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and type(ESX) == 'table' then
            fwName, fwObject = 'esx', ESX
            return fwName, fwObject
        end
    end

    return 'unknown'
end

-- ─── the framework's own answer ─────────────────────────────
-- Returns:  true  → the framework says admin
--           false → the framework knows the player and says no
--           nil   → no verdict (framework not resolved, player not
--                   loaded in it yet, API missing) — never cached long.
local function frameworkVerdict(src, trace)
    local fw, obj = getFramework()

    if trace then trace[#trace + 1] = ('framework: %s'):format(fw) end

    if fw == 'qbx' then
        local ok, result = pcall(function()
            for i = 1, #adminGroupList do
                if exports.qbx_core:HasPermission(src, adminGroupList[i]) then
                    return adminGroupList[i]
                end
            end
            return false
        end)

        if not ok then
            if trace then trace[#trace + 1] = ('  qbx_core:HasPermission failed: %s'):format(result) end
            return nil
        end

        if trace then trace[#trace + 1] = ('  qbx_core:HasPermission → %s'):format(result and ('yes (%s)'):format(result) or 'no') end
        return result and true or false
    end

    if fw == 'qb' and obj then
        local ok, result = pcall(function()
            local fn = obj.Functions
            local player = fn and fn.GetPlayer and fn.GetPlayer(src)

            if fn and fn.HasPermission then
                for i = 1, #adminGroupList do
                    if fn.HasPermission(src, adminGroupList[i]) then
                        return adminGroupList[i]
                    end
                end
            end

            -- Legacy QBCore stored the permission on the player itself.
            local perm = player and player.PlayerData and player.PlayerData.permission
            if type(perm) == 'string' and adminGroups[perm:lower()] then
                return perm
            end

            -- Player not known to the framework yet: no verdict.
            if not player then return nil end

            return false
        end)

        if not ok then
            if trace then trace[#trace + 1] = ('  QBCore.Functions.HasPermission failed: %s'):format(result) end
            return nil
        end

        if trace then
            trace[#trace + 1] = ('  QBCore.Functions.HasPermission → %s'):format(
                result == nil and 'player not loaded yet' or (result and ('yes (%s)'):format(result) or 'no'))
        end

        if result == nil then return nil end
        return result and true or false
    end

    if fw == 'esx' and obj then
        local ok, verdict, group = pcall(function()
            local xPlayer = obj.GetPlayerFromId and obj.GetPlayerFromId(src)
            if not xPlayer then return nil end

            local g = xPlayer.getGroup and xPlayer.getGroup() or xPlayer.group
            if type(g) ~= 'string' then return false, '?' end

            return adminGroups[g:lower()] == true, g
        end)

        if not ok then
            if trace then trace[#trace + 1] = ('  xPlayer.getGroup failed: %s'):format(verdict) end
            return nil
        end

        if trace then
            trace[#trace + 1] = ('  xPlayer.getGroup → %s'):format(
                verdict == nil and 'player not loaded yet' or ('%s (%s)'):format(verdict and 'yes' or 'no', tostring(group)))
        end

        return verdict
    end

    return nil
end

-- ─── server-side admin check (cannot be faked by the client) ─
-- Returns allowed (boolean) and definitive (boolean): definitive is
-- false when the framework had no verdict, so a "no" that may only be
-- "not loaded yet" is re-checked soon instead of being cached.
local function resolveAdmin(src, trace)
    -- 0. Buyer override hook.
    if adminOverride then
        local ok, result = pcall(adminOverride, src)
        if ok and type(result) == 'boolean' then
            if trace then trace[#trace + 1] = ('RWInv.IsAdmin override → %s'):format(result and 'yes' or 'no') end
            return result, true
        elseif not ok and trace then
            trace[#trace + 1] = ('RWInv.IsAdmin override failed: %s'):format(result)
        end
    end

    -- 1. ACE object(s) — framework-agnostic.
    for i = 1, #adminAces do
        local allowed = IsPlayerAceAllowed(src, adminAces[i])
        if trace then trace[#trace + 1] = ('ace %s → %s'):format(adminAces[i], allowed and 'yes' or 'no') end
        if allowed then return true, true end
    end

    -- 2. Identifiers — framework-agnostic.
    if next(adminIdentifiers) then
        local matched
        for i = 0, GetNumPlayerIdentifiers(src) - 1 do
            local id = normaliseIdentifier(GetPlayerIdentifier(src, i))
            if id and adminIdentifiers[id] then matched = id break end
        end
        if trace then trace[#trace + 1] = ('identifiers → %s'):format(matched and ('yes (%s)'):format(matched) or 'no') end
        if matched then return true, true end
    end

    -- 3. ACE bridge for the group names (txAdmin, add_principal, ESX /
    --    QBCore / QBox / ox_core all expose groups through aces in one
    --    of these spellings).
    for i = 1, #adminGroupList do
        local group = adminGroupList[i]
        local objects = { group, 'group.' .. group, 'qbcore.' .. group, 'qbx.' .. group }

        for j = 1, #objects do
            if IsPlayerAceAllowed(src, objects[j]) then
                if trace then trace[#trace + 1] = ('group ace %s → yes'):format(objects[j]) end
                return true, true
            end
        end
    end

    if trace then trace[#trace + 1] = ('group aces (%s) → no'):format(table.concat(adminGroupList, ', ')) end

    -- 4. The framework's own answer.
    local verdict = frameworkVerdict(src, trace)

    if verdict == true then return true, true end

    return false, verdict == false
end

-- Result cache. Even with the framework object cached, the lookups above
-- are still cross-resource calls (xPlayer.getGroup / HasPermission), and
-- admin rights change about never — so the answer is memoised per
-- player. A "no" that is not definitive (framework not ready, player
-- not loaded in it yet) only lives a few seconds, so an admin who
-- opens the inventory the instant they spawn is not locked out for the
-- full TTL. The entry is dropped when the player leaves and refreshed
-- on (re)login / group change.
local adminCache = {}
local ADMIN_TTL_MS = 30000
local ADMIN_RETRY_MS = 3000

---@param src number|string player server id
---@param refresh? boolean bypass the cache and recompute
local function isAdmin(src, refresh)
    src = tonumber(src)
    if not src or src == 0 then return false end

    local now = GetGameTimer()
    local entry = adminCache[src]

    if not refresh and entry and now < entry.expires then
        return entry.value
    end

    local value, definitive = resolveAdmin(src)
    adminCache[src] = { value = value, expires = now + ((value or definitive) and ADMIN_TTL_MS or ADMIN_RETRY_MS) }

    return value
end

-- Login / group change → recompute on the next check instead of waiting
-- out the TTL.
local function invalidateAdmin(src)
    src = tonumber(src)
    if src then adminCache[src] = nil end
end

AddEventHandler('esx:playerLoaded', function(playerId) invalidateAdmin(playerId) end)
AddEventHandler('esx:setGroup', function(playerId) invalidateAdmin(playerId) end)
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    invalidateAdmin(type(player) == 'table' and player.PlayerData and player.PlayerData.source)
end)
AddEventHandler('QBCore:Server:OnPermissionUpdate', function(playerId) invalidateAdmin(playerId) end)
AddEventHandler('qbx_core:playerLoaded', function(player)
    invalidateAdmin(type(player) == 'table' and (player.PlayerData and player.PlayerData.source or player.source))
end)
AddEventHandler('ox:playerLoaded', function(playerId) invalidateAdmin(playerId) end)

-- ─── diagnostics: `rwinv_access <serverId>` ──────────────
-- Prints every source consulted and its answer, the final verdict and
-- the server.cfg recipe. Server console, or a player holding the
-- `command` ace (txAdmin) / already admin here.
RegisterCommand('rwinv_access', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'command') and not isAdmin(source) then return end

    local target = tonumber(args[1]) or (source ~= 0 and source) or nil

    local function say(line)
        print(('[rw-admin] %s'):format(line))
        if source ~= 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'ox_inventory', line } })
        end
    end

    if not target or target == 0 or not GetPlayerName(target) then
        return say('usage: rwinv_access <serverId>  (player must be online)')
    end

    local trace = {}
    local allowed = resolveAdmin(target, trace)
    invalidateAdmin(target)

    say(('access report for %s (id %s)'):format(GetPlayerName(target), target))
    for i = 1, #trace do say('  ' .. trace[i]) end
    say(('RESULT: %s'):format(allowed and 'ALLOWED' or 'DENIED'))

    if not allowed then
        local ace = adminAces[1] or 'rw.admin'
        say('to grant access without touching the framework, add to server.cfg (needs a server start, or paste both lines in the console now):')
        say(('  add_ace group.admin %s allow'):format(ace))
        for i = 0, GetNumPlayerIdentifiers(target) - 1 do
            local id = GetPlayerIdentifier(target, i)
            if id and (id:find('^license:') or id:find('^discord:') or id:find('^fivem:')) then
                say(('  add_principal identifier.%s group.admin'):format(id))
            end
        end
        say('or list one of those identifiers in RWInv.AdminIdentifiers (config.lua).')
    end
end, false)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterCommand('oxlyninv_access', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'command') and not isAdmin(source) then return end

    local target = tonumber(args[1]) or (source ~= 0 and source) or nil

    local function say(line)
        print(('[rw-admin] %s'):format(line))
        if source ~= 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'ox_inventory', line } })
        end
    end

    if not target or target == 0 or not GetPlayerName(target) then
        return say('usage: rwinv_access <serverId>  (player must be online)')
    end

    local trace = {}
    local allowed = resolveAdmin(target, trace)
    invalidateAdmin(target)

    say(('access report for %s (id %s)'):format(GetPlayerName(target), target))
    for i = 1, #trace do say('  ' .. trace[i]) end
    say(('RESULT: %s'):format(allowed and 'ALLOWED' or 'DENIED'))

    if not allowed then
        local ace = adminAces[1] or 'rw.admin'
        say('to grant access without touching the framework, add to server.cfg (needs a server start, or paste both lines in the console now):')
        say(('  add_ace group.admin %s allow'):format(ace))
        for i = 0, GetNumPlayerIdentifiers(target) - 1 do
            local id = GetPlayerIdentifier(target, i)
            if id and (id:find('^license:') or id:find('^discord:') or id:find('^fivem:')) then
                say(('  add_principal identifier.%s group.admin'):format(id))
            end
        end
        say('or list one of those identifiers in RWInv.AdminIdentifiers (config.lua).')
    end
end, false)
-- ─── override state (cached + persisted) ────────────────────
-- Shape (settings-schema §4.1, V2 format):
--   { v = 2, mode = 'off'|'defaults'|'locked', settings = {...},
--     lockedBy = <identifier string>|nil, lockedName = string|nil, updatedAt = os.time() }
--
-- Exemption rule (D12): EVERY admin is exempt from `locked`. `lockedBy`
-- is informational only (banner) and persists across restarts.
local override = { v = 2, mode = 'off', settings = {}, lockedBy = nil, lockedName = nil, updatedAt = 0 }

-- Whitelist + type-check the incoming settings so a malicious admin
-- payload can't inject arbitrary keys/values. Driven by shared.lua.
local function sanitizeSettings(s)
    return schema.sanitize(s)
end

local function playerIdentifier(src)
    src = tonumber(src)
    if not src or src <= 0 then return src == 0 and 'console' or nil end
    local id = GetPlayerIdentifierByType(src, 'license2') or GetPlayerIdentifierByType(src, 'license')
        or GetPlayerIdentifierByType(src, 'fivem') or GetPlayerIdentifierByType(src, 'discord')
    if not id then
        for i = 0, GetNumPlayerIdentifiers(src) - 1 do
            local raw = GetPlayerIdentifier(src, i)
            if raw and not raw:find('^ip:') then id = raw break end
        end
    end
    return id and normaliseIdentifier(id) or nil
end

local function loadOverride()
    local raw = GetResourceKvpString(KVP_KEY)
    if raw then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            -- Defense-in-depth: re-sanitize on load in case the KVP was
            -- tampered with externally.
            if decoded.v == 2 then
                local mode = decoded.mode
                if mode ~= 'defaults' and mode ~= 'locked' then mode = 'off' end
                override = {
                    v = 2, mode = mode,
                    settings = sanitizeSettings(decoded.settings),
                    lockedBy = type(decoded.lockedBy) == 'string' and decoded.lockedBy or nil,
                    lockedName = type(decoded.lockedName) == 'string' and decoded.lockedName or nil,
                    updatedAt = tonumber(decoded.updatedAt) or 0,
                }
            else
                -- V1 { active, setter, settings } → V2
                override = {
                    v = 2, mode = decoded.active == true and 'locked' or 'off',
                    settings = sanitizeSettings(decoded.settings),
                    lockedBy = nil, lockedName = nil, updatedAt = 0,
                }
            end
        end
    end
    if DEBUG then
        print(('[rw-admin] override loaded (mode=%s)'):format(tostring(override.mode)))
    end
end

local function saveOverride()
    SetResourceKvp(KVP_KEY, json.encode(override))
end

-- AllowUserCustomization = false folds into the same model (§4.3).
local function effectiveMode()
    if override.mode ~= 'off' then return override.mode end
    if config.AllowUserCustomization == false then return 'locked' end
    return 'off'
end

local function effectiveOverride()
    if override.mode == 'off' and config.AllowUserCustomization == false then
        return { v = 2, mode = 'locked', settings = sanitizeSettings(config.Defaults), lockedBy = nil, lockedName = 'config.lua', updatedAt = override.updatedAt }
    end
    return override
end

-- ─── push helpers ───────────────────────────────────────────
local function broadcastOverride()
    -- Sent to ALL clients. Each client merges it into its forced
    -- settings (when locked) and locks/unlocks the editor.
    TriggerClientEvent('rw:globalConfigChanged', -1, effectiveOverride())
end

local function sendStateTo(src)
    TriggerClientEvent('rw:globalConfigState', src, effectiveOverride(), isAdmin(src), playerIdentifier(src))
end

-- ─── net events ─────────────────────────────────────────────
-- Per-source request throttle. The NUI asks for the state on mount, on
-- the initial sync thread and again after a framework login, so bursts
-- of near-identical requests are normal — and a patched client could
-- spam it. Requests inside the window are collapsed into ONE trailing
-- send, so the player still always ends up with the current state.
local lastRequest = {}
local pendingRequest = {}
local REQUEST_COOLDOWN_MS = 500

RegisterNetEvent('rw:requestGlobalConfig', function()
    local src = source
    local now = GetGameTimer()
    local last = lastRequest[src]

    if last and (now - last) < REQUEST_COOLDOWN_MS then
        if pendingRequest[src] then return end
        pendingRequest[src] = true

        SetTimeout(REQUEST_COOLDOWN_MS - (now - last) + 25, function()
            pendingRequest[src] = nil
            -- lastRequest is cleared on drop: don't answer a ghost.
            if not lastRequest[src] then return end
            lastRequest[src] = GetGameTimer()
            sendStateTo(src)
        end)

        return
    end

    lastRequest[src] = now
    sendStateTo(src)
end)

-- Per-source cooldown — blocks net-event spam (DoS) from anyone before
-- the permission lookup even runs. Cheap timestamp gate.
--
-- A throttled ADMIN payload is not dropped: the newest payload is
-- remembered and applied as a trailing save once the cooldown expires.
local lastSave = {}
local pendingSave = {}
local SAVE_COOLDOWN_MS = 750

-- Forward declaration so the trailing timer can call the applier.
local applySave

local function resolveMode(lock, mode)
    if mode == 'defaults' or mode == 'locked' or mode == 'off' then return mode end
    return lock == true and 'locked' or 'off'
end

RegisterNetEvent('rw:saveGlobalConfig', function(settings, lock, mode)
    local src = source
    local now = GetGameTimer()
    mode = resolveMode(lock, mode)

    if lastSave[src] and (now - lastSave[src]) < SAVE_COOLDOWN_MS then
        -- Non-admins are still hard-throttled (probing / spam).
        if not isAdmin(src) then return end

        local hadPending = pendingSave[src] ~= nil
        pendingSave[src] = { settings = settings, mode = mode }
        if hadPending then return end

        local wait = SAVE_COOLDOWN_MS - (now - lastSave[src]) + 25
        SetTimeout(wait, function()
            local queued = pendingSave[src]
            pendingSave[src] = nil
            if not queued then return end
            -- Re-check permission at flush time.
            if not isAdmin(src) then return end
            lastSave[src] = GetGameTimer()
            applySave(src, queued.settings, queued.mode)
        end)
        return
    end

    lastSave[src] = now

    -- fresh check: the cached answer let a demoted admin keep saving for up to 30 s
    if not isAdmin(src, true) then
        if DEBUG then print(('[rw-admin] rejected save from non-admin src %s'):format(src)) end
        -- Re-sync the offender so their UI reflects the true state.
        sendStateTo(src)
        return
    end

    applySave(src, settings, mode)
end)

-- Clear the cooldown timestamp when a player drops, so the tables can't
-- grow unbounded over a long uptime. (The V1 setter-drop block is gone:
-- lockedBy is an identifier, not a server id.)
AddEventHandler('playerDropped', function()
    local src = source
    lastSave[src] = nil
    pendingSave[src] = nil
    lastRequest[src] = nil
    pendingRequest[src] = nil
    adminCache[src] = nil
end)

-- Editor access under lock: admins always pass.
lib.callback.register('ox_inventory:rwEditorAccess', function(src)
    return effectiveMode() ~= 'locked' or isAdmin(src)
end)

-- ═════════════════════════════════════════════════════════════
--  ADMIN API · dispatcher · lock writer  (admin-logs §7, §9, §11)
-- ═════════════════════════════════════════════════════════════
local Admin = {}
Admin.isAdmin = isAdmin
Admin.normaliseIdentifier = normaliseIdentifier
Admin.playerIdentifier = playerIdentifier
Admin.sanitizeSettings = sanitizeSettings

---Single gate used by EVERY admin callback. `write = true` forces a fresh permission lookup.
---@return boolean ok, string? err
function Admin.requireAdmin(src, write)
    src = tonumber(src)
    if not src or src <= 0 then return false, 'no_access' end
    if not isAdmin(src, write == true) then return false, 'no_access' end
    return true
end
server = server or {}
server.isRWAdmin = isAdmin

local handlers = {}

---Registers a dispatcher action. `fn(src, payload) -> result | false, err`.
---`opts.poll = ms`: a polled read (the Live page) — kept out of the per-admin
---call budget but refused (rate_limited) when asked again within `ms`.
function Admin.register(action, fn, opts)
    handlers[action] = { fn = fn, write = opts and opts.write == true, audit = opts and opts.audit, poll = opts and tonumber(opts.poll) or nil }
end

function Admin.has(action) return handlers[action] ~= nil end

---Module-to-module call through the SAME gate + pcall. No network.
function Admin.invoke(src, action, payload)
    local h = handlers[action]
    if not h then return false, 'unknown_action' end
    local ok, err = Admin.requireAdmin(src, h.write)
    if not ok then return false, err end
    local pok, result, herr = pcall(h.fn, src, type(payload) == 'table' and payload or {})
    if not pok then
        lib.print.error(('[rw-admin] %s failed: %s'):format(action, result))
        return false, 'internal'
    end
    if result == false then return false, herr or 'internal' end
    return true, result
end

---Forwards to another action keeping the (false, err) contract.
local function forward(src, action, payload)
    local ok, res = Admin.invoke(src, action, payload)
    if not ok then return false, res end
    return res
end
Admin.forward = forward

function Admin.audit(src, action, extra)
    return Log.record(action, { actor = src, extra = extra })
end

local lastPanelAudit = {}
-- `RWInv.Admin = true/false` (a boolean instead of the block) threw on
-- these reads and took the whole resource down at load.
local panelCfg = type(config.Admin) == 'table' and config.Admin or {}
local PANEL_AUDIT_MS = (tonumber(panelCfg.auditPanelMinutes) or 10) * 60000
local bucket = {}
local pollAt = {}
local CALLS_PER_10S = tonumber(panelCfg.callsPer10s) or 20
local PANEL_ENABLED = panelCfg.panel ~= false

lib.callback.register('ox_inventory:rwAdmin', function(source, action, payload)
    if not PANEL_ENABLED then return false, 'feature_disabled' end
    local h = type(action) == 'string' and handlers[action]
    if not h then return false, 'unknown_action' end
    -- Rate limit BEFORE the admin check: a write action forces a fresh,
    -- uncached ACE / identifier / framework lookup, and any player could
    -- loop it.
    local now = GetGameTimer()
    if h.poll then
        local mine = pollAt[source]
        if not mine then mine = {} pollAt[source] = mine end
        local last = mine[action]
        if last and now - last < h.poll then return false, 'rate_limited' end
        mine[action] = now
    elseif action ~= 'logsSubscribe' then
        local b = bucket[source]
        if not b or now >= b.resetAt then b = { n = 0, resetAt = now + 10000 } bucket[source] = b end
        b.n = b.n + 1
        if b.n > CALLS_PER_10S then return false, 'rate_limited' end
    end
    local ok, err = Admin.requireAdmin(source, h.write)
    if not ok then return false, err end
    local lastAudit = lastPanelAudit[source]
    if not lastAudit or lastAudit + PANEL_AUDIT_MS <= now then
        lastPanelAudit[source] = now
        Log.record('admin_panel', { actor = source })
    end
    return Admin.invoke(source, action, payload)
end)

AddEventHandler('playerDropped', function()
    lastPanelAudit[source] = nil
    bucket[source] = nil
    pollAt[source] = nil
end)

-- ─── lock model (§9) ────────────────────────────────────────
function Admin.lockState(src)
    local keys, textKeys = 0, 0
    for k, v in pairs(override.settings) do
        if k == 'textOverrides' then for _ in pairs(v) do textKeys = textKeys + 1 end else keys = keys + 1 end
    end
    local eff = effectiveOverride()
    local pid = playerIdentifier(src)
    return {
        mode = effectiveMode(),
        fromConfig = override.mode == 'off' and config.AllowUserCustomization == false,
        lockedBy = eff.lockedBy, lockedName = eff.lockedName, updatedAt = override.updatedAt,
        settingsKeys = keys, textKeys = textKeys,
        you = { isAdmin = true, isSetter = override.lockedBy ~= nil and override.lockedBy == pid },
    }
end

---One writer for every lock transition (legacy net event + lockSet).
function Admin.applyLock(src, mode, settings)
    mode = (mode == 'defaults' or mode == 'locked' or mode == 'off') and mode or 'off'
    local prev = override.mode
    override = {
        v = 2, mode = mode,
        settings = mode ~= 'off' and sanitizeSettings(settings) or {},
        lockedBy = mode ~= 'off' and playerIdentifier(src) or nil,
        lockedName = mode ~= 'off' and (src == 0 and 'console' or GetPlayerName(src)) or nil,
        updatedAt = os.time(),
    }
    saveOverride()
    broadcastOverride()
    local keys, textKeys = 0, 0
    for k, v in pairs(override.settings) do
        if k == 'textOverrides' then for _ in pairs(v) do textKeys = textKeys + 1 end else keys = keys + 1 end
    end
    Log.record(mode == 'locked' and 'settings_lock' or mode == 'defaults' and 'settings_apply' or 'settings_unlock',
        { actor = src, extra = { mode = mode, previous = prev, keys = keys, textKeys = textKeys } })
    if DEBUG then print(('[rw-admin] %s set global mode=%s'):format(src, mode)) end
    return Admin.lockState(src)
end

applySave = function(src, settings, mode) return Admin.applyLock(src, mode, settings) end

Admin.register('lockGet', function(src) return Admin.lockState(src) end)
Admin.register('lockSet', function(src, p) return Admin.applyLock(src, p.mode, p.settings) end, { write = true })

-- ─── logs handlers (§8.3) ───────────────────────────────────
Admin.register('logsMeta', function() return Log.meta() end)
Admin.register('logsQuery', function(_, p)
    local res, err = Log.query(p)
    if not res then return false, err end
    return res
end)
Admin.register('logsStats', function() return Log.stats() end)
Admin.register('logsExport', function(src, p)
    local format = p.format == 'json' and 'json' or 'csv'
    local text, rows = Log.export(p.filter, format)
    if not text then return false, rows end
    Log.record('logs_export', { actor = src, extra = { format = format, rows = rows, filter = p.filter } })
    return { format = format, rows = rows, text = text, bytes = #text }
end)
Admin.register('logsSubscribe', function(src, p) return Log.subscribe(src, p.on == true) end)

Admin.register('adminWho', function(src)
    return { source = src, name = GetPlayerName(src), identifier = playerIdentifier(src), isAdmin = true }
end)

-- ─── live feed + players (admin window 3.6) ─────────────────
-- logsSince is polled every ~2 s while the Live page is on screen: out of
-- the call budget, at most one call per 900 ms per admin.
Admin.register('logsSince', function(_, p) return Log.since(p.cursor, p.boot, p.limit) end, { poll = 900 })
Admin.register('playersList', function(_, p)
    local res, err = Log.players(p)
    if not res then return false, err end
    return res
end)
Admin.register('playerGet', function(_, p)
    local res, err = Log.player(p.identifier, p)
    if not res then return false, err end
    return res
end)

-- ─── world: active ground drops (upstream Inventory.Drops) ──
-- Who dropped what is not kept by the inventory: a log sink remembers the
-- `drop` row of every new drop (actor + time) while the drop exists.
local adminCfg = type(config.Admin) == 'table' and config.Admin or {}
local dropMeta, dropMetaN = {}, 0
local DROP_META_MAX = 2000
local InventoryMod

local function inventoryModule()
    if not InventoryMod then
        local ok, mod = pcall(require, 'modules.inventory.server')
        if ok and (type(mod) == 'table' or type(mod) == 'function') then InventoryMod = mod end
    end
    return InventoryMod
end

local function pruneDropMeta(Inv)
    local live = Inv and Inv.Drops or {}
    local n = 0
    for id in pairs(dropMeta) do
        if live[id] == nil then dropMeta[id] = nil else n = n + 1 end
    end
    dropMetaN = n
end

Log.addSink(function(e)
    if e.action ~= 'drop' then return end
    local id = (type(e.extra) == 'table' and e.extra.dropId) or (e.to and e.to.id)
    if type(id) ~= 'string' or dropMeta[id] then return end
    dropMeta[id] = { ts = e.ts, by = e.actor }
    dropMetaN = dropMetaN + 1
    if dropMetaN > DROP_META_MAX then pruneDropMeta(inventoryModule()) end
end)

local function validDropId(id)
    return type(id) == 'string' and #id >= 1 and #id <= 64 and id:match('^[%w_%-]+$') ~= nil
end

local function round2(v) return math.floor((tonumber(v) or 0) * 100 + 0.5) / 100 end

---A drop record (+ its live inventory when loaded) → the row the NUI lists.
local function dropRow(id, rec, inv)
    local counts, order = {}, {}
    local slots, total = 0, 0
    local items = inv and inv.items
    if type(items) == 'table' then
        for _, s in pairs(items) do
            if type(s) == 'table' and s.name then
                local n = tonumber(s.count) or 1
                slots = slots + 1
                total = total + n
                if not counts[s.name] then order[#order + 1] = s.name counts[s.name] = 0 end
                counts[s.name] = counts[s.name] + n
            end
        end
    elseif type(rec.items) == 'table' then
        for name, n in pairs(rec.items) do
            n = tonumber(n) or 1
            slots = slots + 1
            total = total + n
            order[#order + 1] = name
            counts[name] = n
        end
    end
    table.sort(order, function(a, b) if counts[a] ~= counts[b] then return counts[a] > counts[b] end return a < b end)
    local list = {}
    for i = 1, math.min(#order, 8) do list[i] = { name = order[i], count = counts[order[i]] } end
    local c = (inv and inv.coords) or rec.coords
    local opened = 0
    if inv and type(inv.openedBy) == 'table' then for _ in pairs(inv.openedBy) do opened = opened + 1 end end
    local meta = dropMeta[id]
    return {
        id = id,
        label = inv and inv.label or nil,
        coords = c and { x = round2(c.x), y = round2(c.y), z = round2(c.z) } or nil,
        instance = rec.instance,
        model = type(rec.model) == 'string' and rec.model or nil,
        items = list,
        kinds = #order,
        slots = slots,
        total = total,
        by = meta and meta.by or nil,
        createdAt = meta and meta.ts or nil,
        lastUsed = inv and tonumber(inv.time) and inv.time * 1000.0 or nil,
        open = opened,
    }
end

local function dropsMode(src)
    if not Admin.has('drops.getConfig') then return false, false end
    local ok, res = Admin.invoke(src, 'drops.getConfig', {})
    return true, ok and type(res) == 'table' and type(res.keys) == 'table' and res.keys.enabled == true
end

local DROP_SORT = {
    new = function(a, b)
        local x, y = a.createdAt or a.lastUsed or 0, b.createdAt or b.lastUsed or 0
        if x ~= y then return x > y end
        return a.id < b.id
    end,
    old = function(a, b)
        local x, y = a.createdAt or a.lastUsed or 0, b.createdAt or b.lastUsed or 0
        if x ~= y then return x < y end
        return a.id < b.id
    end,
    items = function(a, b)
        if a.total ~= b.total then return a.total > b.total end
        return a.id < b.id
    end,
}

Admin.register('dropsList', function(src, p)
    local Inv = inventoryModule()
    if not Inv or type(Inv.Drops) ~= 'table' then return false, 'internal' end
    local page = math.max(1, math.floor(tonumber(p.page) or 1))
    local pageSize = math.min(200, math.max(1, math.floor(tonumber(p.pageSize) or 100)))
    if (page - 1) * pageSize > 5000 then return false, 'bad_payload' end
    local sort = DROP_SORT[p.sort] and p.sort or 'new'
    local search = type(p.search) == 'string' and p.search:gsub('^%s+', ''):gsub('%s+$', ''):sub(1, 64):lower() or ''
    if search == '' then search = nil end

    local all = {}
    for id, rec in pairs(Inv.Drops) do
        if type(id) == 'string' and type(rec) == 'table' then
            local inv = Inv(id)
            local row = dropRow(id, rec, inv or nil)
            local keep = not search
            if not keep then
                keep = id:lower():find(search, 1, true) ~= nil or (row.label and row.label:lower():find(search, 1, true) ~= nil)
                    or (row.by and row.by.name and row.by.name:lower():find(search, 1, true) ~= nil)
                if not keep then
                    for i = 1, #row.items do if row.items[i].name:lower():find(search, 1, true) then keep = true break end end
                end
            end
            if keep then all[#all + 1] = row end
        end
    end
    table.sort(all, DROP_SORT[sort])
    local rows = {}
    local first = (page - 1) * pageSize + 1
    for i = first, math.min(#all, first + pageSize - 1) do rows[#rows + 1] = all[i] end
    if dropMetaN > DROP_META_MAX / 2 then pruneDropMeta(Inv) end

    local feature, enabled = dropsMode(src)
    return {
        rows = rows, total = #all, page = page, pageSize = pageSize, sort = sort,
        feature = feature, enabled = enabled, teleport = adminCfg.teleport ~= false, now = Log.now(),
    }
end)

Admin.register('dropsTeleport', function(src, p)
    if adminCfg.teleport == false then return false, 'feature_disabled' end
    if not validDropId(p.id) then return false, 'bad_payload' end
    local Inv = inventoryModule()
    if not Inv or type(Inv.Drops) ~= 'table' then return false, 'internal' end
    local rec = Inv.Drops[p.id]
    if not rec then return false, 'not_found' end
    local inv = Inv(p.id)
    local c = (inv and inv.coords) or rec.coords
    if not c or type(c.x) ~= 'number' then return false, 'not_found' end
    local coords = { x = c.x, y = c.y, z = c.z }
    TriggerClientEvent('ox_inventory:rwAdminTeleport', src, coords)
    Log.record('admin_teleport', { actor = src, to = inv or { id = p.id, type = 'drop' }, coords = c, extra = { dropId = p.id, via = 'admin_panel' } })
    return { id = p.id, coords = coords }
end, { write = true })

Admin.register('dropsRemove', function(src, p)
    if not validDropId(p.id) then return false, 'bad_payload' end
    local Inv = inventoryModule()
    if not Inv or type(Inv.Drops) ~= 'table' then return false, 'internal' end
    local rec = Inv.Drops[p.id]
    if not rec then return false, 'not_found' end
    local inv = Inv(p.id)
    local items = {}
    if inv and inv.type == 'drop' then
        items = Log.snapshot(inv)
        Log.record('admin_clear', { actor = src, from = inv, coords = inv.coords, extra = { command = 'admin_panel', dropId = p.id, items = items } })
        Inv.Remove(inv)
    else
        -- a record without its inventory (stale): drop the world prop only
        Log.record('admin_clear', { actor = src, from = { id = p.id, type = 'drop' }, coords = rec.coords, extra = { command = 'admin_panel', dropId = p.id, stale = true } })
        Inv.Drops[p.id] = nil
        TriggerClientEvent('ox_inventory:removeDrop', -1, p.id)
    end
    if dropMeta[p.id] then dropMeta[p.id] = nil dropMetaN = math.max(0, dropMetaN - 1) end
    return { id = p.id, removed = true, items = #items }
end, { write = true })

-- ─── Item Props aliases (§11) — the drops module registers drops.* ──
Admin.register('propMapGet', function(src, p) return forward(src, 'drops.getProps', p) end)
Admin.register('propMapSet', function(src, p)
    local op = p.op
    if op == 'upsert' then return forward(src, 'drops.setProp', { item = p.item, entry = p.entry }) end
    if op == 'delete' then return forward(src, 'drops.deleteProp', { item = p.item }) end
    if op == 'reset' then return forward(src, 'drops.resetProps', { item = p.item }) end
    if op == 'import' then return forward(src, 'drops.importProps', { json = p.json, mode = p.mode == 'replace' and 'replace' or 'merge' }) end
    if op == 'export' then return forward(src, 'drops.exportProps', {}) end
    return false, 'bad_payload'
end, { write = true })

-- ─── exports / diagnostics ──────────────────────────────────
exports('GetGlobalConfig', function() return effectiveOverride() end)
exports('GetForcedSettings', function() return lib.table.deepclone(override.settings) end)
exports('GetSettingsMode', function() return effectiveMode() end)
exports('IsSettingsLocked', function(src) return effectiveMode() == 'locked' and not isAdmin(src) end)
exports('SanitizeRWSettings', function(s) return sanitizeSettings(s) end)
exports('SanitizeOxlynSettings', function(s) return sanitizeSettings(s) end) -- legacy alias (RW rename)
-- Cached lookup (see ADMIN_TTL_MS). Cheap enough to call per request.
exports('IsRWAdmin', function(src) return isAdmin(src) end)
exports('IsOxlynAdmin', function(src) return isAdmin(src) end) -- legacy alias (RW rename)
-- Forces a fresh permission lookup, e.g. right after your admin script
-- promotes someone and you don't want to wait out the cache TTL.
exports('RefreshRWAdmin', function(src) return isAdmin(src, true) end)
exports('RefreshOxlynAdmin', function(src) return isAdmin(src, true) end) -- legacy alias (RW rename)

loadOverride()

return Admin
