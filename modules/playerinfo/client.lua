if not lib then return end

-- ─────────────────────────────────────────────────────────────
--  ox_inventory · playerinfo module
--  Detects bank balance from active framework and pushes via NUI
-- ─────────────────────────────────────────────────────────────

local PlayerInfo = {}
local lastBank = -1
local lastId = -1
-- V3: name / job ride the same payload (hud-shop.md §2.3)
local hudCfg = (require 'modules.rwconfig.shared'.Get().Hud) or {}
local lastSig = ''

-- Latest registered ped-headshot handle. Kept alive so the transparent
-- texture stays available to NUI for the duration of the session; we
-- unregister the previous one only when re-registering, to avoid the
-- in-game texture being reclaimed mid-use.
local headshotHandle = nil
local headshotTxd = nil

-- Handle that has been registered but not yet confirmed ready by the
-- polling thread. Tracked separately so a resource stop during the
-- ~3 s generation window can still release it (the thread dies with the
-- Lua state, the engine-side registration does not).
local headshotPending = nil

-- Monotonic id of the newest headshot request. Generation takes
-- 500-1500 ms, so re-opening the inventory inside that window starts a
-- SECOND generation while the first is still polling: `headshotHandle`
-- is still nil at that point (it is only assigned once the poll
-- succeeds), so the release guard below cannot see the in-flight handle.
-- Both threads then took the success branch and both assigned
-- `headshotHandle` — the loser's handle was never unregistered and
-- small and fixed: once exhausted, RegisterPedheadshotTransparent
-- answers 0 and the avatar silently stops updating.
local headshotSeq = 0

local function safeCall(fn)
    local ok, result = pcall(fn)
    if ok then return result end
    return nil
end

-- ─────────────────────────────────────────────────────────────
--  Framework object — resolved ONCE, then cached.
--
--  `getSharedObject()` / `GetCoreObject()` copy the framework's whole
--  object graph across the resource boundary on EVERY call. detectBank()
--  runs on each `esx:setPlayerData` / `SetPlayerData` event (which fire
--  constantly), so calling them per lookup was burning client frame time
--  for nothing. Resolved once; re-probed every 10 s only while no
--  framework has started yet.
-- ─────────────────────────────────────────────────────────────
local fwKind, fwObject
local fwNextProbe = 0
local FW_PROBE_INTERVAL_MS = 10000

local function getFramework()
    if fwKind then return fwKind, fwObject end

    local now = GetGameTimer()
    if now < fwNextProbe then return nil end
    fwNextProbe = now + FW_PROBE_INTERVAL_MS

    if GetResourceState('es_extended') == 'started' then
        local ESX = safeCall(function() return exports['es_extended']:getSharedObject() end)
        if ESX then
            fwKind, fwObject = 'esx', ESX
            return fwKind, fwObject
        end
    end

    if GetResourceState('qbx_core') == 'started' then
        fwKind = 'qbx'
        return fwKind
    end

    if GetResourceState('qb-core') == 'started' then
        local QBCore = safeCall(function() return exports['qb-core']:GetCoreObject() end)
        if QBCore then
            fwKind, fwObject = 'qb', QBCore
            return fwKind, fwObject
        end
    end

    return nil
end

---@return number
local function detectBank()
    local kind, obj = getFramework()

    -- ESX Legacy / es_extended (also covers esx_addonaccount, which
    -- exposes the same `accounts` list on the player data).
    if kind == 'esx' and obj then
        local pd = safeCall(function() return obj.GetPlayerData() end)
        if pd and pd.accounts then
            for _, acc in ipairs(pd.accounts) do
                if acc.name == 'bank' then return tonumber(acc.money) or 0 end
            end
        end

    -- qbx_core (Qbox)
    elseif kind == 'qbx' then
        local pd = safeCall(function() return exports.qbx_core:GetPlayerData() end)
        if pd and pd.money and pd.money.bank ~= nil then
            return tonumber(pd.money.bank) or 0
        end

    -- qb-core
    elseif kind == 'qb' and obj then
        local pd = safeCall(function() return obj.Functions.GetPlayerData() end)
        if pd and pd.money and pd.money.bank ~= nil then
            return tonumber(pd.money.bank) or 0
        end
    end

    return 0
end

---Generates a transparent-background headshot of the local ped and
---sends its in-game texture dictionary name to the UI. The UI then
---renders it via the FiveM-special `nui-img://<txd>/<txd>` scheme.
---
---Polls for ~3s for readiness — generation is async on the engine side
---and usually completes within 500–1500 ms. Re-registers each call to
---pick up outfit/skin changes (the previous handle is released first).
function PlayerInfo.sendHeadshot()
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end

    -- Release the previous handle before requesting a new one. We
    -- DON'T release the new handle on inventory close — the NUI keeps
    -- the texture URL cached and re-uses it on next open.
    if headshotHandle then
        UnregisterPedheadshot(headshotHandle)
        headshotHandle = nil
        headshotTxd = nil
    end

    local handle = RegisterPedheadshotTransparent(ped)
    if not handle or handle == 0 then return end

    headshotPending = handle

    -- Bumped only after a successful register, so a failed register can
    -- never orphan a generation that is still legitimately in flight.
    headshotSeq = headshotSeq + 1
    local seq = headshotSeq

    CreateThread(function()
        local attempts = 0
        while not IsPedheadshotReady(handle) and attempts < 60 do
            Wait(50)
            attempts = attempts + 1
        end

        if IsPedheadshotReady(handle) and IsPedheadshotValid(handle) then
            -- A newer request was started while we polled: it owns the
            -- avatar now. Free our slot instead of leaking it, and don't
            -- publish a txd that is about to be replaced.
            if seq ~= headshotSeq then
                if headshotPending == handle then headshotPending = nil end
                return UnregisterPedheadshot(handle)
            end

            if headshotPending == handle then headshotPending = nil end
            headshotHandle = handle
            headshotTxd = GetPedheadshotTxdString(handle)
            SendNUIMessage({
                action = 'setPlayerHeadshot',
                data = { txd = headshotTxd },
            })
        else
            -- Generation failed / timed out — release the handle.
            if headshotPending == handle then headshotPending = nil end
            UnregisterPedheadshot(handle)
        end
    end)
end

---Highest-grade group of the local player (ties by name), mapped through
---RWInv.Hud.jobLabels. Returns nil when the player has no shown group.
---@return string? job, string? label, number? grade, string? gradeLabel
local function resolveJob()
    local groups = PlayerData and PlayerData.groups
    if type(groups) ~= 'table' then return end

    local ignore = hudCfg.ignoreGroups or { none = true, unemployed = true }
    local best, bestGrade

    for name, grade in pairs(groups) do
        if not ignore[name] then
            grade = tonumber(grade) or 0
            if not best or grade > bestGrade or (grade == bestGrade and name < best) then
                best, bestGrade = name, grade
            end
        end
    end

    if not best then return end

    local entry = hudCfg.jobLabels and hudCfg.jobLabels[best]
    local label = entry and entry.label or (hudCfg.jobLabelFallback == 'hide' and '' or best)
    local gradeLabel = entry and entry.grades and entry.grades[bestGrade] or ''

    return best, label, bestGrade, gradeLabel
end

PlayerInfo.resolveJob = resolveJob

---Sends current player info to the UI
---@param force boolean?
---@param bankOverride number? balance already carried by the framework event
---       that triggered this send — avoids re-copying the whole player-data
---       table across the resource boundary for a value we were just handed.
function PlayerInfo.send(force, bankOverride)
    -- 0 is truthy in Lua, so a zero balance still wins over detectBank().
    local bank = bankOverride or detectBank()
    local id = GetPlayerServerId(PlayerId())
    local name = PlayerData and PlayerData.name or nil
    local job, jobLabel, grade, gradeLabel = resolveJob()
    local sig = (name or '') .. '|' .. (job or '') .. '|' .. (grade or '')

    if not force and bank == lastBank and id == lastId and sig == lastSig then return end

    lastBank = bank
    lastId = id
    lastSig = sig

    SendNUIMessage({
        action = 'setPlayerInfo',
        data = { bank = bank, id = id, name = name, job = job, jobLabel = jobLabel, grade = grade, gradeLabel = gradeLabel }
    })

    -- Refresh headshot on every forced send (i.e. inventory open) so
    -- outfit / character-creator changes get picked up automatically.
    if force then
        PlayerInfo.sendHeadshot()
    end
end

---Bank balance out of an ESX `accounts` array, or nil when it isn't the shape
---detectBank() reads (the caller then falls back to detectBank()).
---@return number?
local function bankFromAccounts(accounts)
    if type(accounts) ~= 'table' then return end

    for i = 1, #accounts do
        local acc = accounts[i]
        if type(acc) == 'table' and acc.name == 'bank' then
            return tonumber(acc.money) or 0
        end
    end
end

---Bank balance out of a qb/qbx player-data payload, or nil when it isn't the
---expected shape (the caller then falls back to detectBank()).
---@return number?
local function bankFromPlayerData(pd)
    if type(pd) ~= 'table' then return end

    local money = pd.money

    if type(money) == 'table' then return tonumber(money.bank) end
end

-- Send when relevant data changes. These events are fired by the
-- frameworks across the network (server → client), so each one must
-- be registered with RegisterNetEvent before AddEventHandler — otherwise
-- FiveM logs "event was not safe for net" the first time it fires.
--
-- Each handler reads the balance out of the payload the framework just
-- delivered instead of calling detectBank(), which crosses the resource
-- boundary and msgpack-copies the ENTIRE player-data table (accounts, job,
-- gang, charinfo, metadata) to read one number. These events are frequent:
-- esx:setAccountMoney fires for cash and black_money on every purchase,
-- salary and fine — none of which can move the bank — and SetPlayerData
-- fires on every metadata write (hunger/thirst/stress scripts).
-- Any unexpected payload shape falls through to detectBank() unchanged.
RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
    -- es_extended mutates the account table before firing, so `account.money`
    -- is already the new balance.
    if getFramework() == 'esx' and type(account) == 'table' and type(account.name) == 'string' then
        if account.name == 'bank' then
            return PlayerInfo.send(nil, tonumber(account.money) or 0)
        end

        -- Not the bank: nothing the UI shows can have changed. Re-assert the
        -- known balance so send() short-circuits without a boundary crossing.
        if lastBank >= 0 then return PlayerInfo.send(nil, lastBank) end
    end

    PlayerInfo.send()
end)

RegisterNetEvent('esx:setPlayerData')
AddEventHandler('esx:setPlayerData', function(key, value)
    if key ~= 'accounts' then return end

    -- ESX.SetPlayerData assigns PlayerData[key] = value BEFORE firing, so
    -- `value` IS the accounts table detectBank() would fetch back.
    if getFramework() == 'esx' then
        local bank = bankFromAccounts(value)
        if bank then return PlayerInfo.send(nil, bank) end
    end

    PlayerInfo.send()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData')
AddEventHandler('QBCore:Player:SetPlayerData', function(pd)
    local kind = getFramework()

    if kind == 'qb' or kind == 'qbx' then
        local bank = bankFromPlayerData(pd)
        if bank then return PlayerInfo.send(nil, bank) end
    end

    PlayerInfo.send()
end)

RegisterNetEvent('qbx_core:client:setPlayerData')
AddEventHandler('qbx_core:client:setPlayerData', function(pd)
    local kind = getFramework()

    if kind == 'qb' or kind == 'qbx' then
        local bank = bankFromPlayerData(pd)
        if bank then return PlayerInfo.send(nil, bank) end
    end

    PlayerInfo.send()
end)

-- Release the engine-side pedheadshot when the resource stops/restarts.
-- Each registration holds a render target + TXD in a small process-wide
-- pool; a restart drops our Lua state but NOT the registration, so
-- without this every restart burned one slot for the rest of the game
-- session (and starved other resources that need headshots too).
-- Same idiom as modules/pedpreview/client.lua.
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if headshotPending and headshotPending ~= headshotHandle then
        UnregisterPedheadshot(headshotPending)
    end

    headshotPending = nil

    if headshotHandle then
        UnregisterPedheadshot(headshotHandle)
        headshotHandle = nil
        headshotTxd = nil
    end
end)

return PlayerInfo
