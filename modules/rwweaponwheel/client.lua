if not lib then return end

-- ═════════════════════════════════════════════════════════════
--  REALWRLD Software® · ox_inventory Redesign
--  Native GTA weapon wheel  ·  optional (RWInv.WeaponWheel)
-- ═════════════════════════════════════════════════════════════
--
--  Stock ox_inventory keeps the ped holding ONE weapon (the one the
--  inventory equipped) and blocks the GTA weapon wheel outright, so
--  weapons can only be drawn from the hotbar keys or the inventory UI.
--
--  With `RWInv.WeaponWheel.enabled = true` this module hands the ped
--  a zero-ammo "ghost" copy of every weapon in the player's inventory.
--  The ghosts make the weapons show up on the native wheel (and on the
--  mouse-wheel quick switch). When the player picks one, the selection
--  is caught the same frame, the hand is put back the way the inventory
--  left it, and the weapon is equipped through the normal `useSlot`
--  path — so ammo, durability, attachments, tints, holster/draw
--  animations, server validation and every other inventory rule stay
--  exactly as they are. Picking "fists" holsters the current weapon.
--
--  The inventory remains the single source of truth: ghosts carry no
--  ammo, are never fired, are re-reconciled after every inventory
--  change / equip / holster, and are removed whenever the mode is not
--  active (dead, weaponised vehicle, `inventory:disableweapons`, ...).
--
--  Every hook is a no-op when the option is off, so servers that keep
--  the hotbar see byte-for-byte the stock behaviour.
-- ═════════════════════════════════════════════════════════════

local WeaponWheel = { enabled = false }

local cfg = require('modules.rwconfig.shared').Get().WeaponWheel

if type(cfg) ~= 'table' or not cfg.enabled then
    function WeaponWheel.bind() end
    function WeaponWheel.frame() return false end
    function WeaponWheel.owns() return false end
    function WeaponWheel.blocksHotkey() return false end
    return WeaponWheel
end

local Items = require 'modules.items.client'

WeaponWheel.enabled = true

local options = {
    hotbarWeapons     = cfg.hotbarWeapons == true,
    hotkeyHint        = cfg.hotkeyHint ~= false,
    holsterOnUnarmed  = cfg.holsterOnUnarmed ~= false,
    includeThrowables = cfg.includeThrowables ~= false,
    scrollSwitch      = cfg.scrollSwitch ~= false,
}

local UNARMED = `WEAPON_UNARMED`

-- INPUT_SELECT_WEAPON (the wheel) and the four quick-switch inputs
-- (INPUT_WEAPON_WHEEL_NEXT/PREV, INPUT_SELECT_NEXT/PREV_WEAPON).
local WHEEL_CONTROL = 37
local SCROLL_CONTROLS = { 14, 15, 16, 17 }

-- A selection change is only honoured when the player actually touched
-- the wheel / scroll within this window. Anything else is "game
-- behaviour or another resource" and is left to the stock mismatch
-- logic in client.lua, exactly as before.
local INPUT_WINDOW = 500

-- Set while an equip / holster kicked off by the wheel is in flight so a
-- second selection in the same animation cannot double-fire.
local ACTION_DEBOUNCE = 500

---@type fun(): table? returns client.lua's `currentWeapon`
local getCurrentWeapon = function() return nil end
---@type fun(slot: number)
local useSlot = function() end

---@type table<number, number> weapon hash -> inventory slot
local ghosts = {}
---@type table<number, true> hashes currently handed to the ped by this module
local given = {}
local lastWheelInput = 0
local busyUntil = 0

local GetGameTimer = GetGameTimer
local GetSelectedPedWeapon = GetSelectedPedWeapon
local SetCurrentPedWeapon = SetCurrentPedWeapon
local HasPedGotWeapon = HasPedGotWeapon
local GiveWeaponToPed = GiveWeaponToPed
local RemoveWeaponFromPed = RemoveWeaponFromPed
local DisableControlAction = DisableControlAction
local HudWeaponWheelIgnoreSelection = HudWeaponWheelIgnoreSelection
local IsControlPressed = IsControlPressed
local IsControlJustReleased = IsControlJustReleased
local IsControlJustPressed = IsControlJustPressed

local function isActive()
    return not EnableWeaponWheel
        and PlayerData.loaded == true
        and LocalPlayer.state.canUseWeapons ~= false
end

local function clearGhosts(ped)
    if not next(given) then return end

    local current = getCurrentWeapon()
    local currentHash = current and current.hash

    for hash in pairs(given) do
        if hash ~= currentHash and HasPedGotWeapon(ped, hash, false) then
            RemoveWeaponFromPed(ped, hash)
        end
    end

    given = {}
    ghosts = {}
end

-- Reconcile the ped's weapon set with the inventory: every weapon item
-- that is not the one currently equipped gets a zero-ammo ghost; ghosts
-- whose item is gone are removed. Cheap (one pass over the inventory +
-- one HasPedGotWeapon per weapon) and idempotent, so it is safe to call
-- from several places.
local function sync()
    local ped = cache.ped

    if not isActive() then return clearGhosts(ped) end

    local current = getCurrentWeapon()
    local currentHash = current and current.hash
    local desired = {}

    for slot, item in pairs(PlayerData.inventory) do
        local data = item and item.name and Items[item.name]

        if data and data.weapon and data.hash
            and data.hash ~= currentHash
            and not client.ignoreweapons[data.hash]
            and (options.includeThrowables or not data.throwable)
            and not desired[data.hash]
        then
            desired[data.hash] = slot
        end
    end

    for hash in pairs(given) do
        if not desired[hash] then
            given[hash] = nil

            -- Never touch the weapon the inventory just equipped: its hash
            -- may still be in `given` from before the equip.
            if hash ~= currentHash and HasPedGotWeapon(ped, hash, false) then
                RemoveWeaponFromPed(ped, hash)
            end
        end
    end

    for hash in pairs(desired) do
        if not HasPedGotWeapon(ped, hash, false) then
            -- Zero ammo, not hidden, not forced into the hand. Giving 0
            -- rounds leaves the (shared, per-ammo-type) ammo pool alone.
            GiveWeaponToPed(ped, hash, 0, false, false)
        end

        given[hash] = true
    end

    ghosts = desired
end

local function recentWheelInput()
    return GetGameTimer() - lastWheelInput < INPUT_WINDOW
end

---Wire the module to client.lua's private state. Called once, right
---after `useSlot` is defined.
---@param currentWeaponGetter fun(): table?
---@param useSlotFn fun(slot: number)
function WeaponWheel.bind(currentWeaponGetter, useSlotFn)
    getCurrentWeapon = currentWeaponGetter
    useSlot = useSlotFn
    SetTimeout(0, sync)
end

---True when `hash` is one of this module's ghosts (or fists) AND the
---player just used the wheel — i.e. the selection change belongs to
---this module and the stock "forcibly unequipped" logic must not race
---it. Anything else falls through to the stock behaviour.
---@param hash number
---@return boolean
function WeaponWheel.owns(hash)
    if EnableWeaponWheel then return false end
    if hash ~= UNARMED and not ghosts[hash] then return false end

    return recentWheelInput()
        or IsControlPressed(0, WHEEL_CONTROL)
        or IsControlJustReleased(0, WHEEL_CONTROL)
end

---Hotbar keys 1–5: when the wheel owns weapons, a weapon slot is
---ignored (items still work). Returns true when the key must be swallowed.
---@param slot number
---@return boolean
function WeaponWheel.blocksHotkey(slot)
    if options.hotbarWeapons or EnableWeaponWheel then return false end

    local item = PlayerData.inventory[slot]
    local data = item and item.name and Items[item.name]

    if not data or not data.weapon then return false end

    if options.hotkeyHint then
        lib.notify({ id = 'weapon_wheel_hotkey', type = 'inform', description = locale('weapon_wheel_hotkey') })
    end

    return true
end

---Per-frame hook, called from client.lua's tick while the inventory is
---closed. `allowed` is client.lua's verdict on whether weapons may be
---switched right now (not busy, not using an item, not cuffed, no
---equip animation running).
---
---Returns false when the mode is not active so the caller applies the
---stock behaviour (wheel disabled); true when this module handled the
---wheel for this frame.
---@param allowed boolean
---@return boolean
function WeaponWheel.frame(allowed)
    if EnableWeaponWheel or not PlayerData.loaded then return false end

    local ped = cache.ped
    local now = GetGameTimer()
    local ok = allowed and not PlayerData.dead and now >= busyUntil

    if not ok then
        HudWeaponWheelIgnoreSelection()
        DisableControlAction(0, WHEEL_CONTROL, true)

        for i = 1, #SCROLL_CONTROLS do
            DisableControlAction(0, SCROLL_CONTROLS[i], true)
        end
    elseif not options.scrollSwitch then
        for i = 1, #SCROLL_CONTROLS do
            DisableControlAction(0, SCROLL_CONTROLS[i], true)
        end
    end

    if IsControlPressed(0, WHEEL_CONTROL) or IsControlJustReleased(0, WHEEL_CONTROL) then
        lastWheelInput = now
    elseif options.scrollSwitch and ok then
        for i = 1, #SCROLL_CONTROLS do
            if IsControlJustPressed(0, SCROLL_CONTROLS[i]) then
                lastWheelInput = now
                break
            end
        end
    end

    local current = getCurrentWeapon()
    local expected = current and current.hash or UNARMED
    local selected = GetSelectedPedWeapon(ped)

    if selected == expected then return true end

    -- Not a ghost and not fists: a weapon neither the inventory nor this
    -- module handed out. Stock mismatch logic deals with it.
    if selected ~= UNARMED and not ghosts[selected] then return true end

    -- Selection changed without the player touching the wheel (ragdoll,
    -- scenario, another resource): stock behaviour, untouched.
    if now - lastWheelInput >= INPUT_WINDOW then return true end

    -- Put the hand back the way the inventory left it BEFORE acting, so
    -- the holster / draw animation plays on the right weapon and the
    -- zero-ammo ghost is never the active weapon for more than a frame.
    SetCurrentPedWeapon(ped, expected, true)

    if not ok then return true end

    if selected == UNARMED then
        if not current or not options.holsterOnUnarmed then return true end

        busyUntil = now + ACTION_DEBOUNCE
        local slot = current.slot
        CreateThread(function() useSlot(slot) end)

        return true
    end

    local slot = ghosts[selected]
    local item = PlayerData.inventory[slot]
    local data = item and item.name and Items[item.name]

    if not data or data.hash ~= selected then
        -- The item moved since the last reconcile; refresh and let the
        -- player pick again.
        sync()
        return true
    end

    busyUntil = now + ACTION_DEBOUNCE
    CreateThread(function() useSlot(slot) end)

    return true
end

-- ── Keep the ghosts in step with the inventory ───────────────

-- Equip / holster (fired by Weapon.Equip and Weapon.Disarm).
AddEventHandler('ox_inventory:currentWeapon', function()
    SetTimeout(0, sync)
end)

-- Weapon.Disarm wipes every ped weapon; hand the ghosts back at once
-- (synchronously, so an equip that follows in the same tick already sees
-- them) and again next frame, once client.lua has cleared `currentWeapon`
-- and the holstered weapon itself may return to the wheel.
AddEventHandler('ox_inventory:rwWeaponsCleared', function()
    given = {}
    sync()
    SetTimeout(0, sync)
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
AddEventHandler('ox_inventory:oxlynWeaponsCleared', function()
    given = {}
    sync()
    SetTimeout(0, sync)
end)

-- Inventory contents changed (net events handled in client.lua; the
-- deferred call runs after its handler has applied the update).
AddEventHandler('ox_inventory:updateSlots', function()
    SetTimeout(0, sync)
end)

AddEventHandler('ox_inventory:setPlayerInventory', function()
    SetTimeout(0, sync)
end)

lib.onCache('ped', function()
    given = {}
    SetTimeout(0, sync)
end)

-- Safety net for everything that has no event (weaponised-vehicle
-- toggles, `canUseWeapons`, death, a third-party RemoveAllPedWeapons).
CreateThread(function()
    while true do
        Wait(1000)
        sync()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        clearGhosts(cache.ped)
    end
end)

return WeaponWheel
