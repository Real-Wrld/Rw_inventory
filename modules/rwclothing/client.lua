if not lib then return end

-- ═════════════════════════════════════════════════════════════
--  REALWRLD Software® · ox_inventory · Clothing-as-items (client)
-- ═════════════════════════════════════════════════════════════
--
--  Optional system (RWInv.Clothing.enabled + per-player setting).
--  While the 3D character preview is visible, the NUI renders two
--  rails of CLOTHING SLOTS flanking the ped. Clicking an equipped
--  slot strips that piece from the ped and stores it as a `clothing`
--  ITEM (metadata carries component/drawable/texture); using the
--  item ("Equip" button, the Use action or its hotbar key) puts it
--  back on.
--
--  The ped in the middle IS the player's exact ped — equipping and
--  unequipping updates it live.
--
--  3.10.6 — a piece is never lost any more:
--    · the server asks this side whether the piece FITS this ped
--      (`rw:clothing:canApply`) BEFORE it consumes the item; a
--      male jacket on a female ped, or an addon drawable this server
--      does not stream, used to be consumed and never shown;
--    · after `apply` the ped is read back; a piece the game refused
--      is refunded by the server (`rw:clothing:refund`, one shot);
--    · every change is handed to the appearance script
--      (RWInv.Clothing.persist: illenium-appearance, fivem-appearance
--      or esx_skin, auto-detected) so a respawn, a relog or a job
--      outfit no longer re-dresses the saved look over a piece that
--      lives in the inventory now — the "randomly lost clothing".
-- ═════════════════════════════════════════════════════════════

-- ─── slot map ────────────────────────────────────────────────
-- prop  = true → GTA ped PROP (hats, glasses…), index = prop slot
-- prop  = nil  → ped COMPONENT, index = component slot
local SLOTS = {
    hat     = { prop = true, index = 0 },
    glasses = { prop = true, index = 1 },
    ears    = { prop = true, index = 2 },
    watch   = { prop = true, index = 6 },
    mask    = { index = 1 },
    chain   = { index = 7 },
    jacket  = { index = 11 },
    shirt   = { index = 8 },
    armor   = { index = 9 },
    bag     = { index = 5 },
    pants   = { index = 4 },
    shoes   = { index = 6 },
}

-- Stable order for the UI rails (head-to-toe, left rail then right).
local SLOT_ORDER = {
    'hat', 'mask', 'glasses', 'ears', 'chain', 'watch',
    'jacket', 'shirt', 'armor', 'bag', 'pants', 'shoes',
}

-- skinchanger / esx_skin key pairs per slot (drawable key, texture key)
local SKIN_KEYS = {
    hat = { 'helmet_1', 'helmet_2' }, glasses = { 'glasses_1', 'glasses_2' }, ears = { 'ears_1', 'ears_2' },
    watch = { 'watches_1', 'watches_2' }, mask = { 'mask_1', 'mask_2' }, chain = { 'chain_1', 'chain_2' },
    jacket = { 'torso_1', 'torso_2' }, shirt = { 'tshirt_1', 'tshirt_2' }, armor = { 'bproof_1', 'bproof_2' },
    bag = { 'bags_1', 'bags_2' }, pants = { 'pants_1', 'pants_2' }, shoes = { 'shoes_1', 'shoes_2' },
}

-- ─── config ──────────────────────────────────────────────────
-- Off until config.lua has a Clothing block (mirrors the server: no block,
-- no per-gender "empty" map, no clothing).
local cfg = { enabled = false, empty = {}, persist = 'auto', onChange = nil }
do
    -- Shared, parse-once accessor. lib.load('config') re-read, re-compiled and
    -- re-executed the whole ~87 KB config file on top of the copy this side
    -- had already built in modules/items/shared.lua.
    local ok, conf = pcall(function() return require 'modules.rwconfig.shared'.Get() end)
    if ok and type(conf) == 'table' and type(conf.Clothing) == 'table' then
        cfg.enabled = conf.Clothing.enabled ~= false
        cfg.empty = type(conf.Clothing.empty) == 'table' and conf.Clothing.empty or {}
        if conf.Clothing.persist ~= nil then cfg.persist = conf.Clothing.persist end
        if type(conf.Clothing.onChange) == 'function' then cfg.onChange = conf.Clothing.onChange end
    end
end

-- The server has the last word (the admin switch): ask once the player is
-- in and fold the rails if it says no.
if cfg.enabled then
    CreateThread(function()
        while not PlayerData or not PlayerData.loaded do Wait(500) end
        local on = lib.callback.await('ox_inventory:rwClothingEnabled', false)
        if on == false then cfg.enabled = false end
    end)
end

-- "Empty" drawable for a component on the local ped. Freemode males
-- and females use different naked drawables; anything unmapped
-- falls back to 0.
local MALE_HASH = `mp_m_freemode_01`

local function emptyDrawable(slotId)
    local ped = PlayerPedId()
    local gender = GetEntityModel(ped) == MALE_HASH and 'male' or 'female'
    local map = type(cfg.empty[gender]) == 'table' and cfg.empty[gender] or {}
    local v = tonumber(map[slotId])
    return v or 0
end

-- ─── state ───────────────────────────────────────────────────
---What the ped wears in a slot right now.
---@return number drawable, number texture, boolean equipped
local function current(slotId)
    local def = SLOTS[slotId]
    local ped = PlayerPedId()
    if def.prop then
        local drawable = GetPedPropIndex(ped, def.index)
        local equipped = drawable ~= -1
        return drawable, equipped and GetPedPropTextureIndex(ped, def.index) or 0, equipped
    end
    local drawable = GetPedDrawableVariation(ped, def.index)
    return drawable, GetPedTextureVariation(ped, def.index), drawable ~= emptyDrawable(slotId)
end

---@return table[] one entry per slot: { id, equipped, drawable, texture }
local function getState()
    local out = {}
    for _, id in ipairs(SLOT_ORDER) do
        local drawable, texture, equipped = current(id)
        out[#out + 1] = { id = id, equipped = equipped, drawable = drawable, texture = texture }
    end
    return out
end

local function pushState()
    SendNUIMessage({
        action = 'oxlynClothing',
        data = { enabled = cfg.enabled, slots = getState() },
    })
end

-- ─── does this piece exist on this ped? ──────────────────────
---A drawable / texture pair the game can show on the local ped. A piece
---minted on another model (the other sex), or from an addon pack this
---server does not stream, fails here — and is then never consumed.
---@param slotId string
---@param drawable number
---@param texture number
---@return boolean
local function pieceFits(slotId, drawable, texture)
    local def = SLOTS[slotId]
    if not def then return false end
    drawable, texture = tonumber(drawable), tonumber(texture) or 0
    if not drawable or drawable < 0 or texture < 0 then return false end
    local ped = PlayerPedId()
    if def.prop then
        if drawable >= GetNumberOfPedPropDrawableVariations(ped, def.index) then return false end
        return texture < math.max(1, GetNumberOfPedPropTextureVariations(ped, def.index, drawable))
    end
    return IsPedComponentVariationValid(ped, def.index, drawable, texture)
end

lib.callback.register('rw:clothing:canApply', function(slotId, drawable, texture)
    if not cfg.enabled then return false end
    return pieceFits(slotId, drawable, texture)
end)

-- ─── apply / strip ───────────────────────────────────────────
---@return boolean shown the ped really wears it now
local function applyPiece(slotId, drawable, texture)
    local def = SLOTS[slotId]
    if not def then return false end
    local ped = PlayerPedId()
    if def.prop then
        SetPedPropIndex(ped, def.index, drawable, texture, true)
        return GetPedPropIndex(ped, def.index) == drawable
    end
    SetPedComponentVariation(ped, def.index, drawable, texture, 0)
    return GetPedDrawableVariation(ped, def.index) == drawable
end

local function stripPiece(slotId)
    local def = SLOTS[slotId]
    if not def then return end
    local ped = PlayerPedId()
    if def.prop then
        ClearPedProp(ped, def.index)
    else
        SetPedComponentVariation(ped, def.index, emptyDrawable(slotId), 0, 0)
    end
end

-- ─── persistence (the appearance script learns about the change) ──
local function started(res) return GetResourceState(res) == 'started' end

---Which appearance script keeps the look, per config (auto = the first one running).
---@return string|false
local function persistTarget()
    local p = cfg.persist
    if p == false or p == 'off' or p == 'none' then return false end
    if p == 'auto' or p == nil or p == true then
        if started('illenium-appearance') then return 'illenium-appearance' end
        if started('fivem-appearance') then return 'fivem-appearance' end
        if started('esx_skin') and started('skinchanger') then return 'esx_skin' end
        return false
    end
    return tostring(p)
end

local pendingSave = 0

---Hands the ped's current look to the appearance script, debounced: a
---swap (strip + apply) saves once, 1.2 s after the last change.
local function persist()
    local target = persistTarget()
    if not target then return end
    pendingSave += 1
    local tick = pendingSave
    SetTimeout(1200, function()
        if tick ~= pendingSave then return end
        local ped = PlayerPedId()
        local ok, err = pcall(function()
            if target == 'illenium-appearance' then
                local appearance = exports['illenium-appearance']:getPedAppearance(ped)
                if type(appearance) == 'table' then TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance) end
            elseif target == 'fivem-appearance' then
                local appearance = exports['fivem-appearance']:getPedAppearance(ped)
                if type(appearance) == 'table' then TriggerServerEvent('fivem-appearance:save', appearance) end
            elseif target == 'esx_skin' then
                -- skinchanger keeps its own copy of the skin: patch the twelve
                -- clothing pairs from the ped and save that (esx_skin:save)
                TriggerEvent('skinchanger:getSkin', function(skin)
                    if type(skin) ~= 'table' then return end
                    for id, keys in pairs(SKIN_KEYS) do
                        local def = SLOTS[id]
                        if def.prop then
                            local d = GetPedPropIndex(ped, def.index)
                            skin[keys[1]] = d
                            skin[keys[2]] = d ~= -1 and GetPedPropTextureIndex(ped, def.index) or 0
                        else
                            skin[keys[1]] = GetPedDrawableVariation(ped, def.index)
                            skin[keys[2]] = GetPedTextureVariation(ped, def.index)
                        end
                    end
                    TriggerServerEvent('esx_skin:save', skin)
                end)
            else
                -- an unknown name: only the config hook below can save it
                return
            end
        end)
        if not ok then lib.print.warn(('clothing: could not save the look through %s: %s'):format(target, err)) end
    end)
end

---Runs after every confirmed change (equipped = the piece is on the ped
---now; false = it went into the inventory): the config hook, then the
---appearance script.
local function changed(slotId, drawable, texture, equipped)
    if cfg.onChange then
        local ok, err = pcall(cfg.onChange, slotId, drawable, texture, equipped)
        if not ok then lib.print.warn(('clothing: RWInv.Clothing.onChange failed: %s'):format(err)) end
    end
    persist()
end

-- ─── NUI: state request + unequip click ──────────────────────
RegisterNUICallback('rwClothingState', function(_, cb)
    cb({ enabled = cfg.enabled, slots = cfg.enabled and getState() or {} })
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynClothingState', function(_, cb)
    cb({ enabled = cfg.enabled, slots = cfg.enabled and getState() or {} })
end)

RegisterNUICallback('rwClothingUnequip', function(data, cb)
    if not cfg.enabled then return cb({ ok = false }) end
    local slotId = type(data) == 'table' and data.slot or nil
    local def = slotId and SLOTS[slotId]
    if not def then return cb({ ok = false }) end

    local drawable, texture, equipped = current(slotId)
    if not equipped then return cb({ ok = false }) end

    -- Strip first (instant visual feedback on the 3D ped), then ask the
    -- server to mint the item. If the inventory is full the server
    -- fires `rw:clothing:apply` back and the piece re-appears;
    -- `rw:clothing:stored` confirms the item exists (then the look is saved).
    stripPiece(slotId)
    TriggerServerEvent('rw:clothing:store', slotId, drawable, texture)
    pushState()
    cb({ ok = true })
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynClothingUnequip', function(data, cb)
    if not cfg.enabled then return cb({ ok = false }) end
    local slotId = type(data) == 'table' and data.slot or nil
    local def = slotId and SLOTS[slotId]
    if not def then return cb({ ok = false }) end

    local drawable, texture, equipped = current(slotId)
    if not equipped then return cb({ ok = false }) end

    -- Strip first (instant visual feedback on the 3D ped), then ask the
    -- server to mint the item. If the inventory is full the server
    -- fires `rw:clothing:apply` back and the piece re-appears;
    -- `rw:clothing:stored` confirms the item exists (then the look is saved).
    stripPiece(slotId)
    TriggerServerEvent('rw:clothing:store', slotId, drawable, texture)
    pushState()
    cb({ ok = true })
end)

-- ─── equip (item button / Use / hotbar key → server → apply) ──
-- Fired by the clothing items' "Equip" context button (slot number) and,
-- since 3.10.6, by the Use action and the hotbar keys through the items'
-- `client.event` (data/items.lua): then the first argument is the item data
-- table with `slot` in it.
AddEventHandler('rw:clothing:equipRequest', function(data)
    if not cfg.enabled then return end
    local slot = type(data) == 'table' and tonumber(data.slot) or tonumber(data)
    if not slot then return end
    TriggerServerEvent('rw:clothing:equip', slot)
end)

-- Fired when the player DRAGS a clothing item from the inventory onto
-- its matching rail slot (ClothingPanel drop target).
RegisterNUICallback('rwClothingEquip', function(data, cb)
    if not cfg.enabled then return cb({ ok = false }) end
    local slot = type(data) == 'table' and tonumber(data.slot) or nil
    if not slot then return cb({ ok = false }) end
    TriggerServerEvent('rw:clothing:equip', slot)
    cb({ ok = true })
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynClothingEquip', function(data, cb)
    if not cfg.enabled then return cb({ ok = false }) end
    local slot = type(data) == 'table' and tonumber(data.slot) or nil
    if not slot then return cb({ ok = false }) end
    TriggerServerEvent('rw:clothing:equip', slot)
    cb({ ok = true })
end)

-- Server validated + consumed the item → dress the ped. If something
-- was already worn in that slot, it goes back to the inventory first
-- (swap behaviour). A piece the game refuses to show is refunded.
RegisterNetEvent('rw:clothing:apply', function(slotId, drawable, texture)
    local def = SLOTS[slotId]
    if not def then return end

    -- A piece this ped cannot show: ask for the item back and touch nothing
    -- (the worn piece stays on; storing it first would have duplicated it).
    if not pieceFits(slotId, drawable, texture) then
        TriggerServerEvent('rw:clothing:refund', slotId)
        pushState()
        return
    end

    local curDrawable, curTexture, wasEquipped = current(slotId)

    if wasEquipped and (curDrawable ~= drawable or curTexture ~= texture) then
        TriggerServerEvent('rw:clothing:store', slotId, curDrawable, curTexture)
    end

    local shown = applyPiece(slotId, drawable, texture)

    if not shown then
        -- The game still refused it: the worn piece is an item now (stored
        -- above), so take it off the ped, and get the new item back.
        if wasEquipped then stripPiece(slotId) end
        pushState()
        TriggerServerEvent('rw:clothing:refund', slotId)
        return
    end

    pushState()
    changed(slotId, drawable, texture, true)
end)

-- The server minted the item for a stripped piece: the look changed for good.
RegisterNetEvent('rw:clothing:stored', function(slotId, drawable, texture)
    if not SLOTS[slotId] then return end
    changed(slotId, drawable, texture, false)
end)
