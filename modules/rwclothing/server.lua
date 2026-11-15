if not lib then return end

-- ═════════════════════════════════════════════════════════════
--  REALWRLD Software® · ox_inventory · Clothing-as-items (server)
-- ═════════════════════════════════════════════════════════════
--
--  Mints / consumes the generic `clothing` item. Appearance values
--  (drawable/texture) can only be read client-side, so the store
--  event trusts the client for the COSMETIC payload — but slot ids
--  are whitelisted, values are type/range-checked, and a per-source
--  cooldown blocks spam. The items are cosmetic-only.
--
--  3.10.6 — nothing is consumed that cannot be worn: before an equip
--  removes the item the client is asked whether the piece fits its ped
--  (`rw:clothing:canApply`); a piece the game still refuses after the
--  apply is refunded once (`rw:clothing:refund`, 10 s window, the exact
--  item that was removed). A full inventory on unequip re-dresses the
--  piece AND tells the player; a successful unequip confirms with
--  `rw:clothing:stored` so the client can save the new look.
-- ═════════════════════════════════════════════════════════════

local VALID_SLOTS = {
    hat = true, glasses = true, ears = true, watch = true,
    mask = true, chain = true, jacket = true, shirt = true,
    armor = true, bag = true, pants = true, shoes = true,
}

-- ─── config (master switch, parsed once and shared) ──────────
local conf = require 'modules.rwconfig.shared'.Get()
-- No block at all (a config.lua from before the feature) = off: without the
-- per-gender "empty" map bare body parts count as garments and could be
-- minted from nothing.
local enabled = type(conf.Clothing) == 'table' and conf.Clothing.enabled ~= false

-- The admin panel's "Clothing enabled" switch (modules/rwserversettings,
-- restart required) lives in this KVP and wins over config.lua.
do
    local raw = GetResourceKvpString('rw:serverSettings')
    local ok, decoded = pcall(json.decode, raw or '')

    -- (an explicit if-chain: an `and` chain answers the boolean false for
    -- a missing or broken KVP, which would read as "switched off")
    if ok and type(decoded) == 'table' and type(decoded.values) == 'table' then
        local v = decoded.values['clothing.enabled']

        if type(v) == 'boolean' then enabled = v end
    end
end

-- The client asks before it draws the rails: the switch must not leave a
-- rail the server refuses.
lib.callback.register('ox_inventory:rwClothingEnabled', function() return enabled end)

if not enabled then return end

local Inventory = require 'modules.inventory.server'
local Log = require 'modules.rwlogs.server'
local Items = require 'modules.items.server'

local function notify(src, kind, key, fallback)
    local text = locale(key)
    if not text or text == key then text = fallback end
    TriggerClientEvent('ox_lib:notify', src, { type = kind, description = text })
end

-- ─── fixed items (RWInv.Clothing.items) ───────────────────
-- An item name that always equips one exact piece, e.g.
--   ['hat_cap_red'] = { slot = 'hat', drawable = 12, texture = 3, female = { drawable = 12, texture = 3 } }
-- Validated once here; bad entries are reported and skipped, entries whose
-- item is missing from data/items.lua too (the item is required so it can
-- carry the "Equip" button, an icon and a label).
local FIXED = {}        -- [itemName] = { slot, male = {d, t}, female = {d, t} }
local FIXED_BY_PIECE = {} -- [slot .. ':' .. drawable .. ':' .. texture] = itemName (either gender)

local function pieceOf(def, fallback)
    if type(def) ~= 'table' then return fallback end
    local d, t = tonumber(def.drawable), tonumber(def.texture or 0)
    if not d or d ~= d or d < 0 or d > 4096 then return nil end
    if not t or t ~= t or t < 0 or t > 4096 then t = 0 end
    return { drawable = math.floor(d), texture = math.floor(t) }
end

do
    local list = type(conf.Clothing) == 'table' and conf.Clothing.items or nil
    if type(list) == 'table' then
        for name, def in pairs(list) do
            local why
            if type(name) ~= 'string' or name == '' then
                why = 'the key must be the item name'
            elseif type(def) ~= 'table' or type(def.slot) ~= 'string' or not VALID_SLOTS[def.slot] then
                why = 'slot must be one of hat, mask, glasses, ears, chain, watch, jacket, shirt, armor, bag, pants, shoes'
            elseif not pieceOf(def) then
                why = 'drawable must be a whole number between 0 and 4096'
            elseif not Items(name) then
                why = ('the item is not defined in data/items.lua - copy the "clothing_%s" block there and rename it to "%s"'):format(def.slot, name)
            end
            if why then
                print(('^3[ox_inventory] RWInv.Clothing.items[%s] ignored: %s^0'):format(tostring(name), why))
            else
                local male = pieceOf(def)
                local female = pieceOf(def.female, male)
                FIXED[name] = { slot = def.slot, male = male, female = female }
                FIXED_BY_PIECE[('%s:%d:%d'):format(def.slot, male.drawable, male.texture)] = name
                FIXED_BY_PIECE[('%s:%d:%d'):format(def.slot, female.drawable, female.texture)] = name
            end
        end
        local n = 0
        for _ in pairs(FIXED) do n = n + 1 end
        if n > 0 then print(('[ox_inventory] clothing: %d fixed item%s configured'):format(n, n == 1 and '' or 's')) end
    end
end

local MALE_HASH = joaat('mp_m_freemode_01')
local function isFemale(src)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and GetEntityModel(ped) ~= MALE_HASH
end

-- The piece a fixed item puts on this player (gender-aware).
local function fixedPiece(name, src)
    local def = FIXED[name]
    if not def then return nil end
    local p = isFemale(src) and def.female or def.male
    return def.slot, p.drawable, p.texture
end

-- ─── anti-spam ───────────────────────────────────────────────
local lastAction = {}
local COOLDOWN_MS = 400

-- Per source AND per action: one shared window dropped the swap store that
-- lands one round-trip after an equip (the replaced piece vanished).
local function throttled(src, action)
    local key = ('%s:%s'):format(src, action or '')
    local now = GetGameTimer()
    if lastAction[key] and (now - lastAction[key]) < COOLDOWN_MS then return true end
    lastAction[key] = now
    return false
end

-- ─── refunds ─────────────────────────────────────────────────
-- The item an equip just consumed, kept for a moment: if the client reports
-- that the game refused to show the piece, it goes back exactly once.
local REFUND_MS = 10000
local pendingRefund = {}

AddEventHandler('playerDropped', function()
    lastAction[source .. ':store'] = nil
    lastAction[source .. ':equip'] = nil
    pendingRefund[source] = nil
end)

-- Pretty label per slot for the item metadata (shown in tooltips and
-- the inventory grid). Kept English-simple — the buyer can relabel by
-- editing here.
local SLOT_LABELS = {
    hat = 'Hat', glasses = 'Glasses', ears = 'Ear piece', watch = 'Watch',
    mask = 'Mask', chain = 'Chain', jacket = 'Jacket', shirt = 'Shirt',
    armor = 'Body armor', bag = 'Bag', pants = 'Pants', shoes = 'Shoes',
}

-- Each slot mints its own TYPED item (clothing_hat, clothing_jacket…)
-- so every piece can carry its own icon (web/images/clothing_<slot>.png)
-- and shop/crafting definitions. The legacy generic `clothing` item is
-- still accepted on equip for pieces minted by older builds.
local ITEM_FOR_SLOT = {}
for slotId in pairs(VALID_SLOTS) do
    ITEM_FOR_SLOT[slotId] = 'clothing_' .. slotId
end

-- ─── strip → mint item ───────────────────────────────────────
RegisterNetEvent('rw:clothing:store', function(slotId, drawable, texture)
    local src = source

    if type(slotId) ~= 'string' or not VALID_SLOTS[slotId] then return end
    drawable = tonumber(drawable)
    texture = tonumber(texture)
    if not drawable or not texture or drawable ~= drawable or texture ~= texture then return end
    if drawable < 0 or drawable > 4096 or texture < 0 or texture > 4096 then return end
    -- whole numbers from here on (%d below refused a float)
    drawable, texture = math.floor(drawable), math.floor(texture)

    -- Throttled = nothing minted: the client already stripped the piece,
    -- so hand it back to the ped instead of losing it (two quick unequips
    -- land inside the window).
    if throttled(src, 'store') then
        TriggerClientEvent('rw:clothing:apply', src, slotId, drawable, texture)
        return
    end

    -- A piece that matches a fixed item goes back as THAT item (no metadata
    -- needed: the item itself says what it is).
    local fixedName = FIXED_BY_PIECE[('%s:%d:%d'):format(slotId, drawable, texture)]
    local itemName = fixedName or ITEM_FOR_SLOT[slotId]
    local metadata = nil
    if not fixedName then
        metadata = {
            type = 'clothing',
            clothingSlot = slotId,
            drawable = drawable,
            texture = texture,
            label = ('%s #%d·%d'):format(SLOT_LABELS[slotId] or slotId, drawable, texture),
            description = ('Slot: %s · Drawable %d · Texture %d'):format(slotId, drawable, texture),
        }
    end

    local ok = Inventory.AddItem(src, itemName, 1, metadata)
    if ok then
        Log.record('clothing_unequip', { item = itemName, count = 1, metadata = metadata, to = Inventory(src), actor = src, extra = { slot = slotId, drawable = drawable, texture = texture, fixed = fixedName ~= nil } })
        -- the client saves the new look only once the item really exists
        TriggerClientEvent('rw:clothing:stored', src, slotId, drawable, texture)
        return
    end

    -- Inventory full (or the item is not defined on this server) → re-dress
    -- the piece so nothing is lost, and say why.
    TriggerClientEvent('rw:clothing:apply', src, slotId, drawable, texture)
    notify(src, 'error', 'rw_clothing_full', 'No room in your inventory for that piece — it stays on')
end)

-- ─── consume item → dress ────────────────────────────────────
RegisterNetEvent('rw:clothing:equip', function(slot)
    local src = source
    if throttled(src, 'equip') then return end

    slot = tonumber(slot)
    if not slot then return end

    local item = Inventory.GetSlot(src, slot)
    if not item then return end

    -- Resolve the piece: a fixed item (RWInv.Clothing.items) carries no
    -- metadata, the piece comes from the config; a minted item carries it.
    local slotId, drawable, texture, fixed = fixedPiece(item.name, src)

    if slotId then
        fixed = true
    else
        local meta = item.metadata
        if type(meta) ~= 'table' or type(meta.clothingSlot) ~= 'string' or not VALID_SLOTS[meta.clothingSlot] then
            return
        end

        -- Accept the typed item for that slot OR the legacy generic item.
        if item.name ~= ITEM_FOR_SLOT[meta.clothingSlot] and item.name ~= 'clothing' then
            return
        end

        slotId = meta.clothingSlot
        drawable = tonumber(meta.drawable)
        texture = tonumber(meta.texture) or 0
        if not drawable then return end
    end

    -- Ask the ped first: a piece this character cannot wear stays an item.
    local fits = lib.callback.await('rw:clothing:canApply', src, slotId, drawable, texture)

    if fits ~= true then
        notify(src, 'error', 'rw_clothing_nofit', 'That piece does not fit your character')
        return
    end

    -- The slot may have changed while the client answered: read it again.
    local now = Inventory.GetSlot(src, slot)
    if not now or now.name ~= item.name then return end

    local removed = Inventory.RemoveItem(src, item.name, 1, nil, slot)
    if not removed then return end

    pendingRefund[src] = { name = item.name, metadata = item.metadata, slot = slotId, expires = GetGameTimer() + REFUND_MS }

    Log.record('clothing_equip', { item = item.name, count = 1, metadata = item.metadata, from = Inventory(src), actor = src, extra = { slot = slotId, drawable = drawable, texture = texture, fixed = fixed or nil } })
    TriggerClientEvent('rw:clothing:apply', src, slotId, drawable, texture)
end)

-- ─── the game refused the piece → the item comes back (once) ──
RegisterNetEvent('rw:clothing:refund', function(slotId)
    local src = source
    local pending = pendingRefund[src]

    if not pending then return end
    pendingRefund[src] = nil

    if type(slotId) ~= 'string' or slotId ~= pending.slot or GetGameTimer() > pending.expires then return end

    local ok = Inventory.AddItem(src, pending.name, 1, pending.metadata)
    Log.record('clothing_refund', { item = pending.name, count = 1, metadata = pending.metadata, to = Inventory(src), actor = src, extra = { slot = slotId, restored = ok and true or false } })

    if ok then
        notify(src, 'inform', 'rw_clothing_refund', 'That piece could not be worn — the item is back in your inventory')
    end
end)
