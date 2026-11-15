--  REALWRLD Software® · ox_inventory Redesign
--  Server-side configuration
-- ═════════════════════════════════════════════════════════════
--
--  This file is EDITABLE — it ships outside the Cfx.re escrow
--  bundle, so any change you make here is preserved across resource
--  updates as long as the key names below stay the same.
--
--  Every option is documented inline. After changing values you must:
--
--     1. Save this file.
--     2. `restart ox_inventory` in the server console.
-- ═════════════════════════════════════════════════════════════

RWInv = {}

-- ─────────────────────────────────────────────────────────────
-- VISUAL FEATURES — global on/off switches.
-- ─────────────────────────────────────────────────────────────
RWInv.Features = {
    rarity          = true,   -- per-item rarity tier wash
    rarityShine     = true,   -- shimmer animation on epic+ items
    revealAnimation = true,   -- scan-line wipe when opening stash/shop/etc.
    slotAnimations  = true,   -- receive / lose / count-bump animations
    pedPreview      = true,   -- 3D scripted-cam ped between columns
    playerHeadshot  = true,   -- transparent FiveM ped portrait avatar
    cursorTrail     = true,   -- glowing particle trail on cursor
    notifications   = true,   -- item add / remove notification toasts
    searchBar       = true,   -- live item search/filter bar (player panel)
    sounds          = true,   -- synthesized UI sounds (open/close/drag/drop)
    worldDim        = true,   -- allow the "Dim world" setting (vignette)
    itemDrops       = true,   -- Item Drop Physics: drops lie on the ground as real props (restart; false = always the classic bag)
    tabOpensStorage = true,   -- the inventory key (default TAB/F2) opens the glovebox inside a vehicle and the trunk when you stand at a boot; false = upstream (only the secondary key K does that)
}

-- ─────────────────────────────────────────────────────────────
-- DEFAULTS — initial state for fresh clients.
-- These apply ONLY when the client has nothing saved in localStorage.
-- Once a client changes a setting in the in-game dialog, their
-- localStorage takes over and these defaults are ignored.
-- ─────────────────────────────────────────────────────────────
RWInv.Defaults = {
    -- Layout template shown to fresh clients:
    --   'showcase' — 3D ped preview between two tilted columns (default)
    --   'classic'  — flat classic ox_inventory layout
    --   'tarkov'   — dense seamless grid, items render at physical size
    --   'grid'     — polished TILE grid: visible cells, items at physical
    --                size with name plates and integrated durability
    layout      = 'showcase',

    -- Theme skin: 'glass' | 'tactical' | 'neon' | 'minimal' | 'luxe'
    theme       = 'glass',

    -- 'red' | 'rose' | 'orange' | 'gold' | 'yellow' | 'lime' | 'green'
    -- | 'emerald' | 'teal' | 'cyan' | 'sky' | 'blue' | 'indigo'
    -- | 'purple' | 'fuchsia' | 'pink' | 'silver'
    accentColor = 'red',

    -- 'hex' | 'shield' | 'diamond' | 'beveled' | 'circle' | 'square'
    -- | 'pentagon' | 'gem'
    iconShape   = 'hex',

    cursorTrail = true,
    sounds      = true,     -- synthesized UI sounds
    worldDim    = false,    -- darken the game world behind the inventory
    uiScale     = 1.0,      -- 0.85 – 1.15
    rarityStyle = 'wash',   -- 'wash' | 'outline' | 'both' | 'off'
    gridCols    = 5,        -- 5 | 6 | 7 columns (classic layouts)
    searchBar   = true,     -- live item search bar

    slotStyle   = 'glass',  -- 'glass' | 'sharp' | 'notched' | 'frame' | 'minimal'
    fontStyle   = 'default',-- 'default' | 'condensed' | 'tech' | 'rounded'
    labelMode   = 'on',     -- 'on' | 'hover' | 'off' — item name visibility
    showHotbar  = true,     -- show the 5 quick-slots panel inside the inventory
    animMode    = 'full',   -- 'full' | 'reduced' — reduced kills entrance/idle animations
    weightStyle = 'segments', -- 'segments' | 'solid' | 'dial' | 'bar' | 'pill' | 'text' | 'off'
                            -- | 'ticks' | 'battery' | 'arc' | 'dots' | 'heat' | 'stat' ('minimal' = 'text')
    badgeStyle  = 'auto',   -- 'auto' | 'classic' | 'eft' | 'minimal' | 'bold' — count/name positions
    viewStyle   = 'modern', -- 'modern' (3D character, any template) | 'compact' (flat)
    clothingPanel = true,   -- clothing slots around the 3D character (needs RWInv.Clothing.enabled)
    revealFx    = 'scan',   -- 'scan' | 'fade' | 'pop' | 'off' — loot reveal animation
    playerInfo  = 'full',   -- 'full' | 'minimal' | 'hidden' — player card above the inventory

    -- Where the item notifications (+item / −item / used / equipped) show up.
    -- 'top-left' | 'top-center' | 'top-right'
    -- | 'bottom-left' | 'bottom-center' | 'bottom-right'
    -- Players can change it in-game (gear icon → Notification position) unless
    -- an admin locks it with "Save this for everyone & lock".
    notifyPosition = 'bottom-right',

    -- Legacy keys (older builds) — still honoured, mapped onto `layout`:
    -- compactMode = false,
    -- tarkovMode  = false,
}

-- ─────────────────────────────────────────────────────────────
-- V3 KEYS — every setting the Live Editor exposes can be seeded here too
-- (same rule: only fills a fresh client's empty localStorage). The full
-- catalogue lives in web/src/lib/settingsSchema.ts; the server-side
-- mirror (accepted keys, options and ranges) is modules/rwadmin/shared.lua.
-- A few examples — uncomment to seed:
--   theme          = 'obsidian',    -- 19 V3 themes: glass obsidian arctic midnight graphite emerald
--                                   -- rose-quartz amber-sand ocean lavender carbon ivory forest
--                                   -- crimson-night cyber-teal mono-light sunset slate nord | custom
--                                   -- (+ classic V2 skins: tactical neon minimal luxe)
--   accentColor    = 'auto',        -- 'auto' = the theme's own accent, or a preset id / '#rrggbb'
--   slotStyle      = 'glass-soft',  -- glass glass-soft glass-strong gradient-diagonal gradient-radial
--                                   -- outline-glow frosted-tile minimal-flat duotone inner-bevel (+ V2 ids)
--   rarityStyle    = 'glow-soft',   -- wash glow-soft glow-strong gradient-wash corner-tag top-bar bottom-bar
--                                   -- ribbon halo dotted-frame badge-pill holo-shimmer pulse border-gradient inner-fade
--   layout         = 'sidebar-right', -- + sidebar-left bottom-dock top-dock split-wide center-stack minimal-floating
--   hoverFx        = 'glow',        -- lift glow scale underline none
--   openAnim       = 'fade',        -- rise fade scale slide-left slide-right unfold
--   notifyAnim     = 'pop',         -- slide fade pop flip stack drop
--   animSpeed      = 1.0,           -- 0.5 – 1.5 (duration multiplier)
--   uiScale        = 1.0,           -- 0.70 – 1.50 (root font-size, no CSS zoom)
--   invAnchor      = 'center',      -- 9 anchors: top-left … bottom-right (+ invOffsetX/Y px)
--   hotbarAnchor   = 'bottom-center', notifyPosition = 'bottom-right',
--   cursorEffect   = 'ribbon',      -- ribbon sparkle comet dots ring none
--   bgBlur         = 'off',         -- off | vehicle | always — background blur behind the inventory
--                                   -- (see REMOVE-BLUR.md; 'vehicle' is the schema default)
--   language       = 'auto',

-- SERVER-WIDE FORCING — done IN-GAME by an admin from the Live Editor's
-- Admin tab (three modes: off | defaults = pushed once to everyone |
-- locked = everyone gets the admin look, SETTINGS hidden for non-admins).
-- The in-game override persists across restarts (KVP rw:globalConfig).
-- RWInv.AllowUserCustomization = false below equals "locked from config".

-- ─────────────────────────────────────────────────────────────
-- TARKOV MODE TUNING
-- ─────────────────────────────────────────────────────────────
RWInv.Tarkov = {
    cellSize     = '6vh',
    columns      = 7,
    affectHotbar = false,
}

-- ═════════════════════════════════════════════════════════════
-- ITEM DROP PHYSICS  ·  optional, built in (no add-on needed)
-- ═════════════════════════════════════════════════════════════
-- Dropped items lie on the ground as REAL props (the item's own model,
-- weapons as their w_* model, everything without a model in ONE bag),
-- fall with physics and can be picked up one by one with a key.
-- Master switch: RWInv.Features.itemDrops (restart). Everything
-- below is the SERVER default; admins change it in-game
-- (Settings › Admin › Server › Item drops), the change is saved and
-- broadcast without a restart. Per-item models: data/itemProps.lua.
RWInv.Drops = {
    enabled        = true,      -- runtime switch: true = item props, false = every drop is ONE black bag (V2 look, inventory:dropmodel);
                                -- admins flip it in-game (Settings › Ground drops, or Admin › Server), no restart
    mode           = 'scatter', -- 'scatter' (a prop per item ≤ maxProps) | 'item' (heaviest item only) | 'bag' (one bag)
    maxProps       = 6,         -- 1–12   most props one drop shows (scatter)
    stackCopies    = 3,         -- 1–6    copies for stacked items (scatter): 3 bottles = 3 props
    stackMaxCount  = 10,        -- 1–999  above this a stack shows ONE prop (250 cash is a pile, not 250 objects)
    scatterRadius  = 0.45,      -- 0–3.0  metres around the drop point

    physics        = true,      -- props fall and tumble when the drop is created
    keepPhysics    = true,      -- and stay dynamic afterwards (kickable)
    settleMs       = 2500,      -- 300–10000 give up waiting for a prop to settle
    placeOnGround  = true,      -- non-physics props are snapped to the ground
    dropInFrontPhysicsOnly = true, -- true = only a drop created in front of you tumbles; drops you walk up to are placed statically

    renderDistance = 30.0,      -- 5–120  props exist inside this range
    ringDistance   = 12.0,      -- 1–renderDistance  markers show inside this range
    promptDistance = 2.2,       -- 0.5–ringDistance  the pickup tag shows inside this range
    maxPrompts     = 24,        -- 4–48   markers drawn at once (nearest first)
    maxTotalProps  = 60,        -- 6–200  props one client keeps alive at once

    key            = 'E',       -- default key (players rebind in FiveM › Settings › Key Bindings)
    pickupMode     = 'take',    -- 'take' = the key takes the aimed item | 'open' = the key opens the drop
    target         = true,      -- ox_target on dropped props: 'Pick up' / 'Open drop' (needs ox_target started)

    weaponProps    = true,      -- weapons lie as their own w_* model
    bagModel       = 'prop_med_bag_01b',            -- the shared bag (old name: fallbackModel — still accepted)
    weaponRotation = { pitch = 0.0, roll = 90.0 },  -- lay w_* models on their side

    -- 0 = ground drops vanish with `inventory:cleartime` (5 min idle,
    -- upstream default). 1–1440 = idle lifetime in minutes for ground
    -- drops only; every pickup resets the idle clock.
    lifetimeMinutes = 0,
}

-- ═════════════════════════════════════════════════════════════
-- POCKET SLOT  ·  optional, OFF by default
-- ═════════════════════════════════════════════════════════════
-- One extra slot in every player's inventory that holds ONE item (one
-- stack: any amount of a stackable item, 1 of the others). It is slot
-- `inventory:slots` + 1 (51 with the default 50), saved with the rest of
-- the inventory — turning it on moves nothing. Players drag items in and
-- out like any slot; automatic placement (pickups, shops, give, scripts'
-- AddItem without a slot) never uses it.
--
-- safeOnDeath = true: the item in the pocket is NOT lost on death —
--   ClearInventory / ConfiscateInventory / CreateDropFromPlayer keep it,
--   RemoveItem cannot take it while the player is dead (framework death
--   state + graceSeconds after the revive) and other players cannot take
--   it from a dead player. Other death scripts: exports.ox_inventory:
--   IsPocketSafe(src) / GetPocketSlot(src) (docs/POCKET_SLOT.md).
--
-- These are the defaults: admins change them in-game (Settings › World ›
-- Pocket slot, or the admin window › Server). Saved server-side, applied
-- to everyone at once. Turning it OFF never deletes an item: a player's
-- pocket item moves into a free slot (or stays, drain-only, until they
-- make room). Every move in / out and every kept item is logged
-- (pocket_in / pocket_out / pocket_kept / pocket_rehome).
RWInv.PocketSlot = {
    enabled     = false,    -- the whole system (false = nothing changes for anyone)
    safeOnDeath = true,     -- the pocket's item survives death (and ClearInventory / confiscation)
    countWeight = true,     -- false = the pocket's item weighs nothing for the carry limit
    -- items that can never go in the pocket: exact names, or a prefix with * ('WEAPON_*', 'ammo-*').
    -- Containers (backpacks, bags with slots) are always refused — they would carry their contents past death.
    blacklist   = { 'money', 'black_money', 'WEAPON_*' },
    graceSeconds = 15,      -- 0–300: the pocket stays protected this long after a revive (respawn scripts wipe right after it)
    -- isDead = function(src) return exports['my-ambulance']:IsDead(src) end, -- optional: your own death state (return true / false)
}

-- ─────────────────────────────────────────────────────────────
-- ACCESS CONTROL
-- ─────────────────────────────────────────────────────────────
RWInv.AllowUserCustomization = true   -- false = locked mode from config (Defaults become the look)
RWInv.Debug = false

-- ─────────────────────────────────────────────────────────────
-- LIVE EDITOR — how players open the settings panel besides the
-- SETTINGS button in the inventory (modules/rwadmin/client.lua).
-- ─────────────────────────────────────────────────────────────
RWInv.Editor = {
    command = 'invsettings',   -- chat command (opens the inventory first when closed)
    textsCommand = 'invtexts', -- chat command that opens straight into on-screen text editing (Settings › Texts)
    keybind = true,            -- registers the ox_lib keybind 'inv_settings' (no default key)
}

-- ═════════════════════════════════════════════════════════════
-- HUD · player card, panel headers, give picker
-- ═════════════════════════════════════════════════════════════
RWInv.Hud = {
    jobLabels = {                       -- group id → display label (+ optional per-grade labels)
        police    = { label = 'LSPD', grades = { [0] = 'Cadet', [1] = 'Officer', [2] = 'Sergeant' } },
        ambulance = { label = 'EMS' },
    },
    jobLabelFallback = 'name',          -- 'name' = show the raw group id when unmapped · 'hide' = show nothing
    ignoreGroups = { none = true, unemployed = true },
    panelDistance = true,               -- distance chip in the right panel header (one small NUI message per 0.5 m)
    givePicker = true,                  -- GIVE opens a target list over the inventory (name · server ID · distance, nearest first)
                                        -- even when one player is near; nothing is handed over until you pick (3.10.6).
                                        -- false = the old automatic give to the closest player / passenger.
    giveRange = 3.0,                    -- metres searched for give targets
}

-- ═════════════════════════════════════════════════════════════
-- ITEM INFO CARD · which metadata becomes a row
-- ═════════════════════════════════════════════════════════════
RWInv.ItemInfo = {
    -- metadata keys NEVER shown as raw rows (the built-in rows are separate)
    hiddenMetadata = { 'container', 'size', 'image', 'imageurl', 'weight', 'bag', 'degrade', 'clothingSlot', 'drawable', 'texture',
                       'durability', 'label', 'description', 'type', 'specialAmmo' },
    -- friendly labels for raw keys and for built-ins (false hides that built-in row)
    labels = { registered = 'Registered to', serial = 'Serial', weapontint = 'Tint', ammo = 'Ammo', components = 'Attachments',
               quality = 'Quality', owner = 'Owner' },
    showRawKeys = false,   -- true: every remaining string/number/boolean metadata key becomes a row
    maxRows = 8,           -- cap for the metadata rows combined
}

-- ═════════════════════════════════════════════════════════════
-- GTA WEAPON WHEEL  ·  optional
-- ═════════════════════════════════════════════════════════════
-- By default weapons are drawn from the inventory HOTBAR (keys 1–5 /
-- the inventory UI) and the native GTA weapon wheel is blocked.
--
-- Set `enabled = true` to use the NATIVE GTA WEAPON WHEEL instead:
-- every weapon in the player's inventory is listed on the wheel
-- (hold TAB / LB, or mouse-wheel quick switch), picking one equips it
-- and picking the fists holsters. The inventory stays in charge —
-- ammo, durability, attachments, tints, draw/holster animations and
-- server validation are exactly the same as with the hotbar; the wheel
-- is only another way to choose the weapon. The weapons the wheel
-- shows carry no ammo of their own until equipped, so nothing can be
-- fired without going through the inventory.
--
-- No UI rebuild needed. Applies after `restart ox_inventory`.
-- ═════════════════════════════════════════════════════════════
RWInv.WeaponWheel = {
    enabled = false,

    -- false → hotbar keys 1–5 IGNORE weapon slots while the wheel is on
    --         (non-weapon items on the hotbar keep working)
    -- true  → both the wheel and the hotbar keys equip weapons
    hotbarWeapons = false,

    -- Show a small notification when a blocked hotbar key is pressed on
    -- a weapon ("Use the weapon wheel to equip weapons").
    hotkeyHint = true,

    -- Selecting the fists on the wheel holsters the current weapon.
    -- false → the wheel can only switch weapons; holster from the
    --         inventory as before.
    holsterOnUnarmed = true,

    -- Throwables (grenades, molotovs, …) appear on the wheel too.
    includeThrowables = true,

    -- Mouse-wheel quick switch (next/previous weapon without opening
    -- the wheel). false → only the wheel itself switches weapons.
    scrollSwitch = true,
}

-- ═════════════════════════════════════════════════════════════
-- SHOPS  ·  basket checkout
-- ═════════════════════════════════════════════════════════════
-- Stock ox_inventory sells by DRAG AND DROP: you drag an item out of
-- the shop grid and it is bought one drag at a time.
--
-- With `mode = 'basket'` the shop panel becomes a storefront instead:
-- the player clicks items to add them to a BASKET, adjusts quantities,
-- sees the running total, and pays ONCE — with CASH or with the BANK.
-- Nothing leaves the shop until the checkout succeeds, and the whole
-- basket is charged and delivered in a single server-side operation
-- (all of it, or none of it).
--
-- Works on every framework ox_inventory supports. Cash is the `money`
-- item ox already uses; the bank is read from the framework account
-- (see `bankAccount` below), or from your own banking resource via the
-- two hooks at the bottom.
-- ═════════════════════════════════════════════════════════════
RWInv.Shop = {
    -- 'basket'  — storefront + basket + checkout (default)
    -- 'classic' — stock ox_inventory drag-and-drop buying
    mode = 'basket',

    -- Payment methods offered at checkout. Turning both off falls back
    -- to cash (a shop the player cannot pay at would be pointless).
    cash = true,
    bank = true,

    -- The framework account used for "Pay with Bank".
    --   ESX     xPlayer.getAccount(<name>)
    --   QBCore  Player.PlayerData.money[<name>]
    --   QBox    same as QBCore
    --   ox_core the character's personal account
    --   ND      player.getData(<name>)
    -- Leave as 'bank' unless your framework renames it.
    bankAccount = 'bank',

    -- The bank button only pays for items priced in ordinary money.
    -- Shop slots with a custom `currency` (black_money, markedbills,
    -- casino chips…) are always paid from the inventory, because the
    -- bank does not hold them. Such a basket disables the bank button
    -- and says why.

    -- Quantity stepper on each basket line. false → the line just shows
    -- how many are in it; clicking the item in the shop adds more, and
    -- the line can still be removed.
    quantity = true,

    -- Hard cap per basket line. Shop stock still wins when it is lower.
    maxPerLine = 100,

    -- ── Selling (optional) ───────────────────────────────────
    sell = {
        enabled = false,          -- master switch; each shop still needs `allowSell = true` in data/shops.lua
        rate = 0.5,               -- default sell price = floor(basePrice × rate) unless the row has `sellPrice`
        payTo = 'cash',           -- 'cash' (money item) | 'bank' (framework account / CreditBank hook)
        restock = true,           -- sold items go back into the shop's stock (rows with `count` only; memory only, resets on restart)
        durabilityScaled = true,  -- price × durability% for items that carry durability
        CreditBank = nil,         -- function(source, amount, reason) -> boolean   (mirrors ChargeBank)
    },
    -- true = also show the framework/ox_lib notification for basket results (the shop shows them inline)
    nativeNotify = false,

    -- ── Custom banking resource ──────────────────────────────
    -- Set BOTH to plug in a bank that is not the framework account
    -- (Renewed-Banking, okokBanking, tgg-banking, your own…). When
    -- GetBankBalance is nil the framework account above is used; when
    -- it returns nil the bank button is hidden for that player.
    --
    --   RWInv.Shop.GetBankBalance = function(source)
    --       return exports.my_bank:GetBalance(source)   -- number
    --   end
    --
    --   RWInv.Shop.ChargeBank = function(source, amount, reason)
    --       return exports.my_bank:Withdraw(source, amount) == true
    --   end
    --
    -- ChargeBank MUST return true only when the money really left the
    -- account — the items are handed over on the strength of that
    -- boolean, and a false return cancels the whole purchase.
    GetBankBalance = nil,
    ChargeBank = nil,
}

-- ═════════════════════════════════════════════════════════════
-- CLOTHING AS ITEMS  ·  optional
-- ═════════════════════════════════════════════════════════════
-- When enabled, the inventory shows CLOTHING SLOTS flanking the 3D
-- character (hat, mask, glasses, ears, chain, watch, jacket, shirt,
-- armor, bag, pants, shoes). Clicking an equipped slot strips that
-- piece from the ped and stores it as a `clothing` ITEM; the item's
-- "Equip" context button puts it back on. The character in the middle
-- is the player's EXACT ped and updates live on equip/unequip.
--
-- Players can additionally hide the rails per-client via the in-game
-- settings ("Clothing slots" toggle). Setting `enabled = false` here
-- kills the whole system server-wide (no items, no rails).
--
-- `empty` = the drawable considered "not wearing anything" for each
-- component, per freemode gender. Adjust to your clothing packs.
--
-- `items` (optional) = FIXED clothing items: an item name that always
-- equips one exact piece ("hat_cap_red" = hat drawable 12, texture 3).
-- Sell them in shops, put them in loot, give them with /giveitem; the
-- "Equip" button puts that piece on, and unequipping a piece that matches
-- a fixed item gives THAT item back (not a generic clothing_hat).
--   slot      hat | mask | glasses | ears | chain | watch | jacket | shirt
--             | armor | bag | pants | shoes
--   drawable  the drawable (component/prop index) of the piece
--   texture   its texture index (default 0)
--   female    optional { drawable, texture } used when the ped is the
--             female freemode model (clothing packs differ per gender)
-- Each item must ALSO exist in data/items.lua: copy the `clothing_hat`
-- block there, rename it and change the label/weight. A fixed item that
-- is missing from data/items.lua is reported in the server console on
-- start and ignored.
-- ═════════════════════════════════════════════════════════════
RWInv.Clothing = {
    enabled = true,

    -- 3.10.6 · keep the look in your appearance script after every equip / unequip, so a
    -- respawn, a relog or a job outfit never re-dresses the saved outfit over a piece that
    -- is an item now ("randomly lost clothing"):
    --   'auto'                 the first one running of illenium-appearance, fivem-appearance,
    --                          esx_skin (with skinchanger)
    --   'illenium-appearance'  / 'fivem-appearance' / 'esx_skin'   that one, always
    --   false                  never (your own script can use onChange below)
    persist = 'auto',
    -- Client-side hook after every confirmed change (another appearance script, a wardrobe…):
    --   onChange = function(slotId, drawable, texture, equipped) end
    -- slotId = hat/mask/glasses/ears/chain/watch/jacket/shirt/armor/bag/pants/shoes;
    -- equipped = true when the piece is on the ped now, false when it went into the inventory.
    onChange = nil,

    items = {
        -- ['hat_cap_red']   = { slot = 'hat',    drawable = 12, texture = 3 },
        -- ['mask_bandana']  = { slot = 'mask',   drawable = 51, texture = 0, female = { drawable = 51, texture = 0 } },
        -- ['jacket_leather']= { slot = 'jacket', drawable = 4,  texture = 2, female = { drawable = 3, texture = 2 } },
    },

    empty = {
        male = {
            mask = 0, chain = 0, jacket = 15, shirt = 15,
            armor = 0, bag = 0, pants = 21, shoes = 34,
        },
        female = {
            mask = 0, chain = 0, jacket = 15, shirt = 14,
            armor = 0, bag = 0, pants = 17, shoes = 35,
        },
    },
}

-- ═════════════════════════════════════════════════════════════
-- ADMIN LIVE CONFIG — "Save for everyone & lock" (in-game)
-- ═════════════════════════════════════════════════════════════
-- Players whose framework group is in this list get an extra option
-- inside the in-game settings (gear) dialog: a "Save this for
-- everyone & lock" toggle. When enabled, the admin's current
-- settings (accent, icon shape, Tarkov layout, compact, cursor
-- trail) are pushed to EVERY client and their settings dialog is
-- locked. Disable it to return to per-player configuration.
--
-- The override is persisted server-side (resource KVP) so it
-- survives restarts. It overrides RWInv.ForceSettings while
-- active.
--
-- Permission is verified SERVER-SIDE — a player cannot fake admin
-- status by patching the UI.
--
-- HOW ACCESS IS DECIDED — a union (OR) of independent sources; ONE
-- source saying yes is enough, and every framework call is wrapped in
-- pcall so a missing/half-started framework can never break the rest:
--
--   1. ACE           RWInv.AdminAce (works on ANY framework, and
--                    on a pure txAdmin server with no framework at all)
--   2. Identifiers   RWInv.AdminIdentifiers (emergency path — needs
--                    nothing but this file)
--   3. Group aces    for every name in RWInv.AdminGroups the aces
--                    `<group>` · `group.<group>` · `qbcore.<group>` ·
--                    `qbx.<group>` are tested (txAdmin / add_principal)
--   4. Framework     QBox → QBCore → ESX, in that order:
--                    QBox  exports.qbx_core:HasPermission(src, group)
--                    QBCore QBCore.Functions.HasPermission(src, group)
--                           (+ legacy PlayerData.permission)
--                    ESX   xPlayer.getGroup() (or xPlayer.group)
--
-- server.cfg recipe (any framework):
--     add_ace group.admin rw.admin allow
--     add_principal identifier.license:YOUR_LICENSE group.admin
--
--   ⚠ `add_ace` lines are read at SERVER START only — a resource
--     restart is not enough. To apply right now, paste both lines in
--     the server console.
--   ⚠ The `license:` prefix is written ONCE. (A doubled prefix in
--     AdminIdentifiers below is tolerated and fixed automatically.)
--
-- "It says I have no access": run `rwinv_access <serverId>` in the
-- server console (or as a player holding the txAdmin `command` ace).
-- It prints every source consulted, the verdict and the exact lines
-- to paste for that player.
-- ═════════════════════════════════════════════════════════════

-- Framework group / permission names. Array form or hash-set form
-- ({ admin = true }) — both accepted, case-insensitive.
RWInv.AdminGroups = { 'admin', 'superadmin', 'god' }

-- ACE object. A string, a list of strings, or false to disable.
RWInv.AdminAce    = 'rw.admin'

-- Identifiers that are ALWAYS admin here, whatever the framework says.
-- 'license:…' | 'discord:…' | 'steam:…' | 'fivem:…' | 'license2:…'
RWInv.AdminIdentifiers = {
    -- 'license:0123456789abcdef0123456789abcdef01234567',
    -- 'discord:123456789012345678',
}

-- Optional override hook for custom permission systems. When it
-- returns a boolean that IS the final answer (every source above is
-- skipped); return nil to fall through to the normal checks.
-- Example (custom admin resource):
--   RWInv.IsAdmin = function(src)
--       return exports.my_admin:IsStaff(src) == true
--   end
RWInv.IsAdmin = nil

-- ═════════════════════════════════════════════════════════════
-- ADMIN PANEL · LOG REGISTRY · WEBHOOKS
-- ═════════════════════════════════════════════════════════════
-- Everything an admin edits in-game (webhooks, prop map, server
-- settings, lock) is persisted server-side in KVP and wins over the
-- values below. The values here are the SEEDS / defaults.
RWInv.Admin = {
    panel = true,             -- master switch for the in-game admin tab (false: every panel callback answers feature_disabled; /rwinv_access still works)
    command = 'invlogs',      -- chat command that opens the full-screen admin window on Logs (/invlogs overview|live|players|webhooks|drops|props|lock|server; false = none)
    auditPanelMinutes = 10,   -- one 'admin_panel' row per admin per N minutes
    callsPer10s = 20,         -- per-admin rate limit of panel callbacks (the Live page's polling is not counted)
    teleport = true,          -- admins may teleport to a ground drop from the admin window (Drops page); every teleport is logged
}

RWInv.Logs = {
    enabled = true,
    level = 2,                -- 0 off · 1 movements/trade/admin/security · 2 + access/use/weapon/metadata · 3 + per-shot ammo, melee, reorders
    retentionDays = 30,       -- 0 = keep forever (daily prune 04:17)
    maxRows = 0,              -- 0 = no cap
    ringSize = 2000,          -- in-memory instant queries (restart to change)
    flushMs = 2000,           -- batch insert every N ms …
    flushRows = 50,           -- … or when N rows are waiting
    export = {
        maxRows = 5000,
        toDisk = false,       -- also write logs_export/<ts>.csv inside the resource (needs write access; escrow builds: unverified)
    },
}

RWInv.Webhooks = {
    ratePerSecond = 2,        -- per webhook, 1..5 (Discord allows ~5/2s)
    globalRatePerSecond = 8,  -- across all webhooks
    maxQueue = 200,           -- per webhook; oldest entries are dropped beyond this
    flushMs = 1500,           -- batch several entries into one message (<= 10 embeds)
    itemImages = false,       -- public base URL for item thumbnails in embeds, e.g. 'https://cdn.example.com/items' ; false = no thumbnails
    colors = {},              -- per action/alias override, e.g. { give = 0x57F287, admin = 0xED4245 }
    seeds = {
        --     id = 'all', name = 'All movements', enabled = false,
        --     events = { '*' },           -- or { 'give', 'drop', 'pickup', 'buy', 'admin', 'weapon', 'receive' }
        --     items = {},                 -- or { 'WEAPON_*', 'money' }
        --     minCount = 0, players = {}, severityMin = 0,
        --     color = nil, mention = nil, username = 'ox_inventory', avatar = nil,
        --     id = 'weapons', name = 'Weapons only', enabled = true, url = '…',
        --     events = { 'give', 'drop', 'pickup', 'buy', 'sell', 'attach', 'detach', 'admin' },
        --     items = { 'WEAPON_*' }, severityMin = 1, color = 0xED4245,
    },
}

-- ═════════════════════════════════════════════════════════════
-- MAGAZINE SYSTEM (carregadores)  ·  optional
-- ═════════════════════════════════════════════════════════════
-- When enabled, weapons reload by consuming a single MAGAZINE item
-- (one full clip) instead of loose rounds. There is a DIFFERENT
-- magazine per ammo type (pistol mag ≠ rifle mag, etc.) — never one
-- universal magazine.
--
-- How it works:
--   • Each ammo type below is mapped to a magazine item.
--   • Every weapon that uses that ammo type automatically switches to
--     consuming its mapped magazine when reloading.
--   • Using ONE magazine fills the weapon to its clip capacity.
--
-- SETUP:
--   1. Set `enabled = true`.
--   2. Make sure each magazine item listed below ALSO exists in
--      data/items.lua (examples are added there for you).
--   3. `restart ox_inventory`.
--
-- Ammo types NOT listed here keep using loose rounds as normal, so you
-- can mix (e.g. magazines for pistols/rifles, loose shells for shotguns).
--
-- NOTE: while enabled, weapons no longer reload from loose `ammo-x`
-- items — so sell/give the MAGAZINE items (mag_pistol, mag_rifle, ...)
-- through your shops/crafting instead of loose ammo. Weapons that share
-- an ammo type share the same magazine (GTA's ammo model).
-- ═════════════════════════════════════════════════════════════
RWInv.MagazineSystem = {
    enabled = false,

    -- [ammo type used by the weapon] = magazine item name
    magazines = {
        ['ammo-9']         = 'mag_pistol',
        ['ammo-45']        = 'mag_pistol',
        ['ammo-38']        = 'mag_pistol',
        ['ammo-22']        = 'mag_pistol',
        ['ammo-rifle']     = 'mag_rifle',
        ['ammo-rifle2']    = 'mag_rifle',
        ['ammo-sniper']    = 'mag_sniper',
        ['ammo-heavysniper'] = 'mag_sniper',
        ['ammo-shotgun']   = 'mag_shotgun',
        ['ammo-mg']        = 'mag_mg',
        -- Add / change mappings as you like. Any ammo type left out
        -- keeps using loose rounds.
    },
}

-- ═════════════════════════════════════════════════════════════
-- LOCALE / TRANSLATIONS
-- ═════════════════════════════════════════════════════════════
--
-- Pick the active language. Resolved at every heartbeat — change
-- the value, restart the resource, and the UI re-translates.
--
-- Available out of the box: 'en' | 'pt' | 'es' | 'fr' | 'de' | 'it'
-- Add new languages by appending to RWInv.Translations below.
-- ═════════════════════════════════════════════════════════════
RWInv.Locale = 'en'

RWInv.Translations = {

    -- ─────────────────────────────────────────────────────────
    -- ENGLISH
    -- ─────────────────────────────────────────────────────────
    en = {
        -- Main inventory chrome
        inventory_title          = 'INVENTORY',
        player_name_fallback     = 'PLAYER',
        close_label_top          = 'Close',
        close_label_bottom       = 'Inventory',

        -- Control bar buttons
        btn_use                  = 'USE',
        btn_give                 = 'GIVE',
        btn_info                 = 'INFO',
        btn_settings             = 'SETTINGS',
        btn_close                = 'CLOSE',
        btn_use_title            = 'Use',
        btn_give_title           = 'Give',
        btn_info_title           = 'Controls',
        btn_settings_title       = 'Settings',
        btn_close_title          = 'Close inventory',

        -- Settings dialog
        settings_title           = 'Inventory settings',
        settings_section_layout  = 'Layout',
        settings_section_effects = 'Effects',
        settings_section_appearance = 'Appearance',
        settings_compact_label   = 'Compact mode',
        settings_compact_hint    = 'Hide ped preview, classic ox_inventory layout.',
        settings_tarkov_label    = 'Tarkov layout',
        settings_tarkov_hint     = 'Items render at their physical size in a dense grid.',
        settings_cursor_label    = 'Cursor trail',
        settings_cursor_hint     = 'Glowing particle trail that follows your cursor.',
        settings_accent_label    = 'Accent color',
        settings_shape_label     = 'Icon shape',
        settings_footer          = 'Settings saved locally on this client.',
        settings_section_admin   = 'Administration',
        settings_admin_label     = 'Save this for everyone & lock',
        settings_admin_hint      = 'Apply your current settings to every player and lock their configuration. Uncheck to restore per-player settings.',
        settings_admin_saved     = 'Global configuration saved & locked for everyone',
        settings_admin_cleared   = 'Per-player configuration restored',

        -- Section headers (right inventory titles)
        section_player_title     = 'POCKETS',
        section_player_subtitle  = 'Items on your character',
        section_drop_title       = 'DROP',
        section_drop_subtitle    = 'Store necessary assets',
        section_newdrop_title    = 'NEW DROP',
        section_newdrop_subtitle = 'Drop items here',
        section_container_title  = 'CONTAINER',
        section_container_subtitle = 'Stored items',
        section_stash_title      = 'STASH',
        section_stash_subtitle   = 'Stored items',
        section_crafting_title   = 'CRAFTING',
        section_crafting_subtitle = 'Craftable items',
        section_shop_title       = 'SHOP',
        section_shop_subtitle    = 'Items for sale',
        section_trunk_title      = 'TRUNK',
        section_trunk_subtitle   = 'Vehicle storage',
        section_glovebox_title   = 'GLOVEBOX',
        section_glovebox_subtitle = 'Vehicle storage',
        section_otherplayer_title = 'POCKETS',
        section_otherplayer_subtitle = 'Other player',
        section_inspect_title    = 'INSPECT',
        section_inspect_subtitle = 'Inspected inventory',

        -- Empty drop hint
        empty_drop_title         = 'This drop is empty',
        empty_drop_subtitle      = 'Drag items here to store them',

        -- License overlay
        license_badge            = 'OXLYN',
        license_title            = 'License signature missing',
        license_body             = 'This build of <strong>ox_inventory — OXLYN Redesign</strong> requires the encrypted gatekeeper file (<code>oxlynsoftware.lua</code>) to be present and loaded. The UI is locked until a valid handshake is received.',
        license_check_1          = 'Confirm the resource was downloaded from your authorised Keymaster account.',
        license_check_2          = 'Confirm <code>oxlynsoftware.lua</code> is listed in <code>client_scripts</code> in <code>fxmanifest.lua</code>.',
        license_check_3          = 'Confirm the file is <strong>not</strong> in <code>escrow_ignore</code> (it must stay encrypted).',
        license_check_4          = 'Restart the entire server (escrow assets only re-key on a full restart).',
        license_footer           = 'oxlynsoftware.com · all rights reserved',

        -- Hotbar section
        hotbar_title             = 'HOTBAR',
        hotbar_subtitle          = 'Quickly equip your items',
        slots_used               = 'Slots used',

        -- Search bar
        search_placeholder       = 'Search items...',
        search_matches           = 'found',
        search_clear             = 'Clear search',

        -- Settings v3 — templates
        settings_section_template = 'Inventory template',
        settings_template_label  = 'Layout template',
        tpl_showcase             = 'Showcase',
        tpl_showcase_hint        = '3D character preview between the two panels.',
        tpl_classic              = 'Classic',
        tpl_classic_hint         = 'Flat classic layout, controls in the middle.',
        tpl_tarkov               = 'Tarkov',
        tpl_tarkov_hint          = 'Dense grid — items render at their physical size.',
        tpl_grid                 = 'Grid',
        tpl_grid_hint            = 'Polished tile grid — visible cells, items at physical size with name plates.',
        settings_view_label      = 'View style',
        settings_view_hint       = 'Modern shows the 3D character with ANY template; Compact is the flat classic view.',
        view_modern              = 'Modern',
        view_compact             = 'Compact',

        -- Settings v3 — themes
        settings_theme_label     = 'Theme',
        theme_glass              = 'Glass',
        theme_tactical           = 'Tactical',
        theme_neon               = 'Neon',
        theme_minimal            = 'Minimal',
        theme_luxe               = 'Luxe',

        -- Settings v3 — appearance extras
        settings_rarity_label    = 'Rarity style',
        rarity_style_wash        = 'Wash',
        rarity_style_outline     = 'Outline',
        rarity_style_both        = 'Both',
        rarity_style_off         = 'Off',
        settings_cols_label      = 'Grid columns',
        settings_cols_hint       = 'Columns per inventory panel (classic layouts).',
        settings_scale_label     = 'UI scale',

        -- Settings v4 — slot / typography / labels
        inventory_subtitle       = 'Personal equipment',
        settings_slot_style_label = 'Slot style',
        slot_style_glass         = 'Glass',
        slot_style_sharp         = 'Sharp',
        slot_style_notched       = 'Notched',
        slot_style_frame         = 'Frame',
        slot_style_minimal       = 'Minimal',
        settings_font_label      = 'Typography',
        font_style_default       = 'Default',
        font_style_condensed     = 'Condensed',
        font_style_tech          = 'Tech',
        font_style_rounded       = 'Rounded',
        settings_labels_label    = 'Item labels',
        settings_labels_hint     = 'Show item names always, on hover only, or never.',
        labels_on                = 'Always',
        labels_hover             = 'Hover',
        labels_off               = 'Hidden',

        -- Settings v5 — tabbed editor + live preview + text editor
        tab_style                = 'Style',
        tab_display              = 'Display',
        tab_texts                = 'Texts',
        preview_title            = 'LIVE PREVIEW',
        preview_note             = 'Updates instantly with every change.',
        settings_hotbar_label    = 'Show hotbar section',
        settings_hotbar_hint     = 'The 5 quick-slots panel inside the inventory.',
        settings_anim_label      = 'Animations',
        settings_anim_hint       = 'Reduced mode disables entrances and idle loops.',
        anim_full                = 'Full',
        anim_reduced             = 'Reduced',
        texts_intro              = 'Rewrite or hide any UI text — changes apply instantly, no config needed. The eye hides a text completely.',
        texts_locked             = 'Texts are currently locked by a server admin.',
        texts_reset_all          = 'Reset all texts to default',
        txtgrp_header            = 'Header',
        txtgrp_hotbar            = 'Hotbar',
        txtgrp_buttons           = 'Buttons',
        txtgrp_search            = 'Search',
        txtgrp_sections          = 'Panel titles',
        txtgrp_rarity            = 'Rarity names',
        txtgrp_misc              = 'Miscellaneous',

        -- Settings v6 — custom accent / weight styles / badge layouts / tarkov ped
        accent_custom            = 'Custom color',
        settings_weight_label    = 'Weight bar style',
        weight_segments          = 'Segments',
        weight_solid             = 'Solid',
        weight_dial              = 'Dial',
        weight_minimal           = 'Minimal',
        settings_badge_label     = 'Badge layout',
        settings_badge_hint      = 'Where the item count and name sit inside each slot.',
        badge_auto               = 'Auto',
        badge_classic            = 'Classic',
        badge_eft                = 'EFT',
        badge_minimal            = 'Minimal',
        badge_bold               = 'Bold',

        -- Item notification anchor (v11)
        settings_notifypos_label = 'Notification position',
        settings_notifypos_hint  = 'Where the +item / -item toasts appear on screen.',
        notifypos_top_left       = 'Top left',
        notifypos_top_center     = 'Top center',
        notifypos_top_right      = 'Top right',
        notifypos_bottom_left    = 'Bottom left',
        notifypos_bottom_center  = 'Bottom center',
        notifypos_bottom_right   = 'Bottom right',
        settings_tarkovped_label = 'Tarkov: 3D character view',
        settings_tarkovped_hint  = 'Show the Showcase-style 3D character between the Tarkov grids.',

        -- Clothing-as-items (v7)
        settings_clothing_label  = 'Clothing slots',
        settings_clothing_hint   = 'Equipment slots around your character — unequip pieces into items, equip them back.',
        clothing_unequip         = 'Click to unequip',
        txtgrp_clothing          = 'Clothing slots',
        clothing_hat             = 'Hat',
        clothing_mask            = 'Mask',
        clothing_glasses         = 'Glasses',
        clothing_ears            = 'Ears',
        clothing_chain           = 'Chain',
        clothing_watch           = 'Watch',
        clothing_jacket          = 'Jacket',
        clothing_shirt           = 'Shirt',
        clothing_armor           = 'Armor',
        clothing_bag             = 'Bag',
        clothing_pants           = 'Pants',
        clothing_shoes           = 'Shoes',

        -- Loot reveal animation (v8)
        settings_reveal_label    = 'Loot reveal animation',
        settings_reveal_hint     = 'How items appear when opening a stash, shop or drop.',
        reveal_scan              = 'Scan',
        reveal_fade              = 'Fade',
        reveal_pop               = 'Pop',
        reveal_off               = 'Off',
        ctx_rotate               = 'Rotate',
        settings_playerinfo_label = 'Player info',
        settings_playerinfo_hint = 'The avatar / name / money card above your inventory.',
        playerinfo_full          = 'Full',
        playerinfo_minimal       = 'Minimal',
        playerinfo_hidden        = 'Hidden',

        -- Settings v3 — effects & systems
        settings_sounds_label    = 'Interface sounds',
        settings_sounds_hint     = 'Subtle open / close / pickup / drop sound effects.',
        settings_dim_label       = 'Dim world',
        settings_dim_hint        = 'Darken the game world behind the inventory.',
        settings_section_systems = 'Systems',
        settings_search_label    = 'Search bar',
        settings_search_hint     = 'Live item filter — matching items stay lit, the rest fade.',

        -- Rarity tier names (tooltip chip)
        rarity_common            = 'COMMON',
        rarity_uncommon          = 'UNCOMMON',
        rarity_rare              = 'RARE',
        rarity_epic              = 'EPIC',
        rarity_legendary         = 'LEGENDARY',
        rarity_mythic            = 'MYTHIC',
    },

    -- ─────────────────────────────────────────────────────────
    -- PORTUGUESE
    -- ─────────────────────────────────────────────────────────
    pt = {
        inventory_title          = 'INVENTÁRIO',
        player_name_fallback     = 'JOGADOR',
        close_label_top          = 'Fechar',
        close_label_bottom       = 'Inventário',

        btn_use                  = 'USAR',
        btn_give                 = 'DAR',
        btn_info                 = 'INFO',
        btn_settings             = 'OPÇÕES',
        btn_close                = 'FECHAR',
        btn_use_title            = 'Usar',
        btn_give_title           = 'Dar',
        btn_info_title           = 'Controlos',
        btn_settings_title       = 'Opções',
        btn_close_title          = 'Fechar inventário',

        settings_title           = 'Opções do inventário',
        settings_section_layout  = 'Layout',
        settings_section_effects = 'Efeitos',
        settings_section_appearance = 'Aparência',
        settings_compact_label   = 'Modo compacto',
        settings_compact_hint    = 'Esconde o ped 3D, usa o layout clássico do ox_inventory.',
        settings_tarkov_label    = 'Layout Tarkov',
        settings_tarkov_hint     = 'Itens são exibidos com tamanho físico numa grelha densa.',
        settings_cursor_label    = 'Rasto do cursor',
        settings_cursor_hint     = 'Rasto de partículas brilhantes que segue o cursor.',
        settings_accent_label    = 'Cor de destaque',
        settings_shape_label     = 'Forma dos ícones',
        settings_footer          = 'Opções guardadas localmente neste cliente.',
        settings_section_admin   = 'Administração',
        settings_admin_label     = 'Guardar para todos & bloquear',
        settings_admin_hint      = 'Aplica as tuas definições atuais a todos os jogadores e bloqueia a configuração deles. Desmarca para repor a configuração por jogador.',
        settings_admin_saved     = 'Configuração global guardada & bloqueada para todos',
        settings_admin_cleared   = 'Configuração por jogador reposta',

        section_player_title     = 'BOLSOS',
        section_player_subtitle  = 'Itens no teu personagem',
        section_drop_title       = 'DROP',
        section_drop_subtitle    = 'Guarda items necessários',
        section_newdrop_title    = 'NOVO DROP',
        section_newdrop_subtitle = 'Larga items aqui',
        section_container_title  = 'CONTENTOR',
        section_container_subtitle = 'Itens guardados',
        section_stash_title      = 'ARMAZÉM',
        section_stash_subtitle   = 'Itens guardados',
        section_crafting_title   = 'CRAFTING',
        section_crafting_subtitle = 'Itens craftáveis',
        section_shop_title       = 'LOJA',
        section_shop_subtitle    = 'Itens à venda',
        section_trunk_title      = 'MALA',
        section_trunk_subtitle   = 'Storage do veículo',
        section_glovebox_title   = 'PORTA-LUVAS',
        section_glovebox_subtitle = 'Storage do veículo',
        section_otherplayer_title = 'BOLSOS',
        section_otherplayer_subtitle = 'Outro jogador',
        section_inspect_title    = 'INSPECCIONAR',
        section_inspect_subtitle = 'Inventário inspeccionado',

        empty_drop_title         = 'Este drop está vazio',
        empty_drop_subtitle      = 'Arrasta items para guardar',

        license_badge            = 'OXLYN',
        license_title            = 'Assinatura de licença em falta',
        license_body             = 'Esta build de <strong>ox_inventory — OXLYN Redesign</strong> requer o ficheiro gatekeeper encriptado (<code>oxlynsoftware.lua</code>) presente e carregado. A UI está bloqueada até receber um handshake válido.',
        license_check_1          = 'Confirma que o resource foi descarregado da tua conta Keymaster autorizada.',
        license_check_2          = 'Confirma que <code>oxlynsoftware.lua</code> está listado em <code>client_scripts</code> no <code>fxmanifest.lua</code>.',
        license_check_3          = 'Confirma que o ficheiro <strong>não</strong> está em <code>escrow_ignore</code> (tem de ficar encriptado).',
        license_check_4          = 'Reinicia o servidor inteiro (escrow assets só re-keyam num restart completo).',
        license_footer           = 'oxlynsoftware.com · todos os direitos reservados',

        -- Secção hotbar
        hotbar_title             = 'HOTBAR',
        hotbar_subtitle          = 'Equipa itens rapidamente',
        slots_used               = 'Slots usados',

        -- Barra de pesquisa
        search_placeholder       = 'Pesquisar itens...',
        search_matches           = 'encontrados',
        search_clear             = 'Limpar pesquisa',

        -- Definições v3 — templates
        settings_section_template = 'Template do inventário',
        settings_template_label  = 'Template de layout',
        tpl_showcase             = 'Showcase',
        tpl_showcase_hint        = 'Preview 3D do personagem entre os dois painéis.',
        tpl_classic              = 'Clássico',
        tpl_classic_hint         = 'Layout clássico plano, controlos ao centro.',
        tpl_tarkov               = 'Tarkov',
        tpl_tarkov_hint          = 'Grelha densa — itens no seu tamanho físico.',
        tpl_grid                 = 'Grelha',
        tpl_grid_hint            = 'Grelha de células polida — células visíveis, itens em tamanho físico com placa de nome.',
        settings_view_label      = 'Estilo de vista',
        settings_view_hint       = 'Modern mostra o personagem 3D com QUALQUER template; Compact é a vista plana clássica.',
        view_modern              = 'Modern',
        view_compact             = 'Compact',

        -- Definições v3 — temas
        settings_theme_label     = 'Tema',
        theme_glass              = 'Glass',
        theme_tactical           = 'Tático',
        theme_neon               = 'Neon',
        theme_minimal            = 'Minimal',
        theme_luxe               = 'Luxe',

        -- Definições v3 — aparência
        settings_rarity_label    = 'Estilo de raridade',
        rarity_style_wash        = 'Gradiente',
        rarity_style_outline     = 'Contorno',
        rarity_style_both        = 'Ambos',
        rarity_style_off         = 'Desligado',
        settings_cols_label      = 'Colunas da grelha',
        settings_cols_hint       = 'Colunas por painel de inventário (layouts clássicos).',
        settings_scale_label     = 'Escala da UI',

        -- Definições v4 — slots / tipografia / labels
        inventory_subtitle       = 'Equipamento pessoal',
        settings_slot_style_label = 'Estilo dos slots',
        slot_style_glass         = 'Vidro',
        slot_style_sharp         = 'Reto',
        slot_style_notched       = 'Chanfrado',
        slot_style_frame         = 'Moldura',
        slot_style_minimal       = 'Minimal',
        settings_font_label      = 'Tipografia',
        font_style_default       = 'Padrão',
        font_style_condensed     = 'Condensada',
        font_style_tech          = 'Tech',
        font_style_rounded       = 'Arredondada',
        settings_labels_label    = 'Nomes dos itens',
        settings_labels_hint     = 'Mostrar nomes sempre, só ao passar o rato, ou nunca.',
        labels_on                = 'Sempre',
        labels_hover             = 'Hover',
        labels_off               = 'Ocultos',

        -- Definições v5 — editor com tabs + preview + editor de textos
        tab_style                = 'Estilo',
        tab_display              = 'Interface',
        tab_texts                = 'Textos',
        preview_title            = 'PREVIEW AO VIVO',
        preview_note             = 'Atualiza instantaneamente a cada alteração.',
        settings_hotbar_label    = 'Mostrar secção hotbar',
        settings_hotbar_hint     = 'O painel dos 5 quick-slots dentro do inventário.',
        settings_anim_label      = 'Animações',
        settings_anim_hint       = 'O modo reduzido desativa entradas e loops de idle.',
        anim_full                = 'Completas',
        anim_reduced             = 'Reduzidas',
        texts_intro              = 'Reescreve ou esconde qualquer texto da UI — aplica-se instantaneamente, sem config. O olho esconde o texto por completo.',
        texts_locked             = 'Os textos estão bloqueados por um admin do servidor.',
        texts_reset_all          = 'Repor todos os textos por defeito',
        txtgrp_header            = 'Cabeçalho',
        txtgrp_hotbar            = 'Hotbar',
        txtgrp_buttons           = 'Botões',
        txtgrp_search            = 'Pesquisa',
        txtgrp_sections          = 'Títulos dos painéis',
        txtgrp_rarity            = 'Nomes de raridade',
        txtgrp_misc              = 'Diversos',

        -- Definições v6 — cor custom / weight styles / badges / tarkov ped
        accent_custom            = 'Cor personalizada',
        settings_weight_label    = 'Estilo da barra de peso',
        weight_segments          = 'Segmentos',
        weight_solid             = 'Sólida',
        weight_dial              = 'Mostrador',
        weight_minimal           = 'Minimal',
        settings_badge_label     = 'Layout dos badges',
        settings_badge_hint      = 'Onde ficam a contagem e o nome dentro de cada slot.',
        badge_auto               = 'Auto',
        badge_classic            = 'Clássico',
        badge_eft                = 'EFT',
        badge_minimal            = 'Minimal',
        badge_bold               = 'Bold',

        -- Item notification anchor (v11)
        settings_notifypos_label = 'Posição das notificações',
        settings_notifypos_hint  = 'Onde aparecem os avisos de +item / -item no ecrã.',
        notifypos_top_left       = 'Topo esquerda',
        notifypos_top_center     = 'Topo centro',
        notifypos_top_right      = 'Topo direita',
        notifypos_bottom_left    = 'Fundo esquerda',
        notifypos_bottom_center  = 'Fundo centro',
        notifypos_bottom_right   = 'Fundo direita',
        settings_tarkovped_label = 'Tarkov: personagem 3D',
        settings_tarkovped_hint  = 'Mostra o personagem 3D estilo Showcase entre as grelhas Tarkov.',

        -- Clothing como itens (v7)
        settings_clothing_label  = 'Slots de roupa',
        settings_clothing_hint   = 'Slots de equipamento à volta do personagem — despe peças para itens e veste-as de volta.',
        clothing_unequip         = 'Clica para despir',
        txtgrp_clothing          = 'Slots de roupa',
        clothing_hat             = 'Chapéu',
        clothing_mask            = 'Máscara',
        clothing_glasses         = 'Óculos',
        clothing_ears            = 'Orelhas',
        clothing_chain           = 'Corrente',
        clothing_watch           = 'Relógio',
        clothing_jacket          = 'Casaco',
        clothing_shirt           = 'Camisa',
        clothing_armor           = 'Colete',
        clothing_bag             = 'Mochila',
        clothing_pants           = 'Calças',
        clothing_shoes           = 'Sapatos',

        -- Animação de loot (v8)
        settings_reveal_label    = 'Animação de aparição do loot',
        settings_reveal_hint     = 'Como os itens aparecem ao abrir um stash, loja ou drop.',
        reveal_scan              = 'Scan',
        reveal_fade              = 'Fade',
        reveal_pop               = 'Pop',
        reveal_off               = 'Desligada',
        ctx_rotate               = 'Rodar',
        settings_playerinfo_label = 'Info do jogador',
        settings_playerinfo_hint = 'O cartão de avatar / nome / dinheiro acima do inventário.',
        playerinfo_full          = 'Completa',
        playerinfo_minimal       = 'Mínima',
        playerinfo_hidden        = 'Oculta',

        -- Definições v3 — efeitos & sistemas
        settings_sounds_label    = 'Sons da interface',
        settings_sounds_hint     = 'Efeitos subtis de abrir / fechar / pegar / largar.',
        settings_dim_label       = 'Escurecer mundo',
        settings_dim_hint        = 'Escurece o mundo do jogo atrás do inventário.',
        settings_section_systems = 'Sistemas',
        settings_search_label    = 'Barra de pesquisa',
        settings_search_hint     = 'Filtro em tempo real — itens correspondentes ficam acesos, o resto esbate.',

        -- Nomes de raridade (chip do tooltip)
        rarity_common            = 'COMUM',
        rarity_uncommon          = 'INCOMUM',
        rarity_rare              = 'RARO',
        rarity_epic              = 'ÉPICO',
        rarity_legendary         = 'LENDÁRIO',
        rarity_mythic            = 'MÍTICO',
    },

    -- ─────────────────────────────────────────────────────────
    -- SPANISH
    -- ─────────────────────────────────────────────────────────
    es = {
        inventory_title          = 'INVENTARIO',
        player_name_fallback     = 'JUGADOR',
        close_label_top          = 'Cerrar',
        close_label_bottom       = 'Inventario',

        btn_use                  = 'USAR',
        btn_give                 = 'DAR',
        btn_info                 = 'INFO',
        btn_settings             = 'AJUSTES',
        btn_close                = 'CERRAR',
        btn_use_title            = 'Usar',
        btn_give_title           = 'Dar',
        btn_info_title           = 'Controles',
        btn_settings_title       = 'Ajustes',
        btn_close_title          = 'Cerrar inventario',

        settings_title           = 'Ajustes del inventario',
        settings_section_layout  = 'Diseño',
        settings_section_effects = 'Efectos',
        settings_section_appearance = 'Apariencia',
        settings_compact_label   = 'Modo compacto',
        settings_compact_hint    = 'Oculta la vista del ped, usa el diseño clásico de ox_inventory.',
        settings_tarkov_label    = 'Diseño Tarkov',
        settings_tarkov_hint     = 'Los objetos se muestran a tamaño físico en una cuadrícula densa.',
        settings_cursor_label    = 'Estela del cursor',
        settings_cursor_hint     = 'Estela de partículas que sigue al cursor.',
        settings_accent_label    = 'Color de acento',
        settings_shape_label     = 'Forma de los iconos',
        settings_footer          = 'Ajustes guardados localmente en este cliente.',

        section_player_title     = 'BOLSILLOS',
        section_player_subtitle  = 'Objetos en tu personaje',
        section_drop_title       = 'DROP',
        section_drop_subtitle    = 'Guarda objetos necesarios',
        section_newdrop_title    = 'NUEVO DROP',
        section_newdrop_subtitle = 'Suelta objetos aquí',
        section_container_title  = 'CONTENEDOR',
        section_container_subtitle = 'Objetos guardados',
        section_stash_title      = 'ALMACÉN',
        section_stash_subtitle   = 'Objetos guardados',
        section_crafting_title   = 'FABRICACIÓN',
        section_crafting_subtitle = 'Objetos fabricables',
        section_shop_title       = 'TIENDA',
        section_shop_subtitle    = 'Objetos en venta',
        section_trunk_title      = 'MALETERO',
        section_trunk_subtitle   = 'Almacén del vehículo',
        section_glovebox_title   = 'GUANTERA',
        section_glovebox_subtitle = 'Almacén del vehículo',
        section_otherplayer_title = 'BOLSILLOS',
        section_otherplayer_subtitle = 'Otro jugador',
        section_inspect_title    = 'INSPECCIONAR',
        section_inspect_subtitle = 'Inventario inspeccionado',

        empty_drop_title         = 'Este drop está vacío',
        empty_drop_subtitle      = 'Arrastra objetos para guardarlos',

        license_badge            = 'OXLYN',
        license_title            = 'Firma de licencia ausente',
        license_body             = 'Esta build de <strong>ox_inventory — OXLYN Redesign</strong> requiere el archivo gatekeeper encriptado (<code>oxlynsoftware.lua</code>) presente y cargado. La UI está bloqueada hasta recibir un handshake válido.',
        license_check_1          = 'Confirma que el recurso se descargó de tu cuenta Keymaster autorizada.',
        license_check_2          = 'Confirma que <code>oxlynsoftware.lua</code> está en <code>client_scripts</code> en <code>fxmanifest.lua</code>.',
        license_check_3          = 'Confirma que el archivo <strong>no</strong> está en <code>escrow_ignore</code>.',
        license_check_4          = 'Reinicia todo el servidor (los assets escrow solo se re-keyan en un reinicio completo).',
        license_footer           = 'oxlynsoftware.com · todos los derechos reservados',

        hotbar_title             = 'HOTBAR',
        hotbar_subtitle          = 'Equipa objetos rápidamente',
        slots_used               = 'Slots usados',

        search_placeholder       = 'Buscar objetos...',
        search_matches           = 'encontrados',
        search_clear             = 'Limpiar búsqueda',

        settings_section_template = 'Plantilla del inventario',
        settings_template_label  = 'Plantilla de diseño',
        tpl_showcase             = 'Showcase',
        tpl_showcase_hint        = 'Vista 3D del personaje entre los dos paneles.',
        tpl_classic              = 'Clásico',
        tpl_classic_hint         = 'Diseño clásico plano, controles en el centro.',
        tpl_tarkov               = 'Tarkov',
        tpl_tarkov_hint          = 'Cuadrícula densa — objetos a su tamaño físico.',
        tpl_grid                 = 'Cuadrícula',
        tpl_grid_hint            = 'Cuadrícula de celdas pulida — celdas visibles, objetos a tamaño físico con placa de nombre.',
        settings_view_label      = 'Estilo de vista',
        settings_view_hint       = 'Modern muestra el personaje 3D con CUALQUIER plantilla; Compact es la vista plana clásica.',
        view_modern              = 'Modern',
        view_compact             = 'Compact',

        settings_theme_label     = 'Tema',
        theme_glass              = 'Glass',
        theme_tactical           = 'Táctico',
        theme_neon               = 'Neón',
        theme_minimal            = 'Minimal',
        theme_luxe               = 'Luxe',

        settings_rarity_label    = 'Estilo de rareza',
        rarity_style_wash        = 'Degradado',
        rarity_style_outline     = 'Contorno',
        rarity_style_both        = 'Ambos',
        rarity_style_off         = 'Apagado',
        settings_cols_label      = 'Columnas de la cuadrícula',
        settings_cols_hint       = 'Columnas por panel de inventario (diseños clásicos).',
        settings_scale_label     = 'Escala de la interfaz',

        inventory_subtitle       = 'Equipo personal',
        settings_slot_style_label = 'Estilo de casillas',
        slot_style_glass         = 'Cristal',
        slot_style_sharp         = 'Recto',
        slot_style_notched       = 'Biselado',
        slot_style_frame         = 'Marco',
        slot_style_minimal       = 'Minimal',
        settings_font_label      = 'Tipografía',
        font_style_default       = 'Estándar',
        font_style_condensed     = 'Condensada',
        font_style_tech          = 'Tech',
        font_style_rounded       = 'Redondeada',
        settings_labels_label    = 'Nombres de objetos',
        settings_labels_hint     = 'Mostrar nombres siempre, solo al pasar el ratón, o nunca.',
        labels_on                = 'Siempre',
        labels_hover             = 'Hover',
        labels_off               = 'Ocultos',

        tab_style                = 'Estilo',
        tab_display              = 'Interfaz',
        tab_texts                = 'Textos',
        preview_title            = 'VISTA PREVIA',
        preview_note             = 'Se actualiza al instante con cada cambio.',
        settings_hotbar_label    = 'Mostrar sección hotbar',
        settings_hotbar_hint     = 'El panel de 5 quick-slots dentro del inventario.',
        settings_anim_label      = 'Animaciones',
        settings_anim_hint       = 'El modo reducido desactiva entradas y bucles de idle.',
        anim_full                = 'Completas',
        anim_reduced             = 'Reducidas',
        texts_intro              = 'Reescribe u oculta cualquier texto de la UI — se aplica al instante, sin config. El ojo oculta el texto por completo.',
        texts_locked             = 'Los textos están bloqueados por un admin del servidor.',
        texts_reset_all          = 'Restablecer todos los textos',
        txtgrp_header            = 'Cabecera',
        txtgrp_hotbar            = 'Hotbar',
        txtgrp_buttons           = 'Botones',
        txtgrp_search            = 'Búsqueda',
        txtgrp_sections          = 'Títulos de paneles',
        txtgrp_rarity            = 'Nombres de rareza',
        txtgrp_misc              = 'Varios',

        accent_custom            = 'Color personalizado',
        settings_weight_label    = 'Estilo de la barra de peso',
        weight_segments          = 'Segmentos',
        weight_solid             = 'Sólida',
        weight_dial              = 'Indicador',
        weight_minimal           = 'Minimal',
        settings_badge_label     = 'Diseño de insignias',
        settings_badge_hint      = 'Dónde se colocan la cantidad y el nombre en cada casilla.',
        badge_auto               = 'Auto',
        badge_classic            = 'Clásico',
        badge_eft                = 'EFT',
        badge_minimal            = 'Minimal',
        badge_bold               = 'Bold',

        -- Item notification anchor (v11)
        settings_notifypos_label = 'Posición de las notificaciones',
        settings_notifypos_hint  = 'Dónde aparecen los avisos de +objeto / -objeto en pantalla.',
        notifypos_top_left       = 'Arriba izq.',
        notifypos_top_center     = 'Arriba centro',
        notifypos_top_right      = 'Arriba der.',
        notifypos_bottom_left    = 'Abajo izq.',
        notifypos_bottom_center  = 'Abajo centro',
        notifypos_bottom_right   = 'Abajo der.',
        settings_tarkovped_label = 'Tarkov: personaje 3D',
        settings_tarkovped_hint  = 'Muestra el personaje 3D estilo Showcase entre las cuadrículas Tarkov.',

        settings_clothing_label  = 'Casillas de ropa',
        settings_clothing_hint   = 'Casillas de equipo alrededor del personaje — quita piezas como objetos y vuelve a ponértelas.',
        clothing_unequip         = 'Clic para quitar',
        txtgrp_clothing          = 'Casillas de ropa',
        clothing_hat             = 'Sombrero',
        clothing_mask            = 'Máscara',
        clothing_glasses         = 'Gafas',
        clothing_ears            = 'Orejas',
        clothing_chain           = 'Cadena',
        clothing_watch           = 'Reloj',
        clothing_jacket          = 'Chaqueta',
        clothing_shirt           = 'Camisa',
        clothing_armor           = 'Chaleco',
        clothing_bag             = 'Mochila',
        clothing_pants           = 'Pantalones',
        clothing_shoes           = 'Zapatos',

        settings_reveal_label    = 'Animación de aparición del loot',
        settings_reveal_hint     = 'Cómo aparecen los objetos al abrir un alijo, tienda o drop.',
        reveal_scan              = 'Scan',
        reveal_fade              = 'Fade',
        reveal_pop               = 'Pop',
        reveal_off               = 'Apagada',
        ctx_rotate               = 'Rotar',
        settings_playerinfo_label = 'Info del jugador',
        settings_playerinfo_hint = 'La tarjeta de avatar / nombre / dinero sobre el inventario.',
        playerinfo_full          = 'Completa',
        playerinfo_minimal       = 'Mínima',
        playerinfo_hidden        = 'Oculta',

        settings_sounds_label    = 'Sonidos de interfaz',
        settings_sounds_hint     = 'Efectos sutiles de abrir / cerrar / coger / soltar.',
        settings_dim_label       = 'Oscurecer mundo',
        settings_dim_hint        = 'Oscurece el mundo del juego detrás del inventario.',
        settings_section_systems = 'Sistemas',
        settings_search_label    = 'Barra de búsqueda',
        settings_search_hint     = 'Filtro en vivo — los objetos coincidentes permanecen iluminados.',

        rarity_common            = 'COMÚN',
        rarity_uncommon          = 'POCO COMÚN',
        rarity_rare              = 'RARO',
        rarity_epic              = 'ÉPICO',
        rarity_legendary         = 'LEGENDARIO',
        rarity_mythic            = 'MÍTICO',
    },

    -- ─────────────────────────────────────────────────────────
    -- FRENCH
    -- ─────────────────────────────────────────────────────────
    fr = {
        inventory_title          = 'INVENTAIRE',
        player_name_fallback     = 'JOUEUR',
        close_label_top          = 'Fermer',
        close_label_bottom       = 'Inventaire',

        btn_use                  = 'UTILISER',
        btn_give                 = 'DONNER',
        btn_info                 = 'INFO',
        btn_settings             = 'OPTIONS',
        btn_close                = 'FERMER',
        btn_use_title            = 'Utiliser',
        btn_give_title           = 'Donner',
        btn_info_title           = 'Contrôles',
        btn_settings_title       = 'Options',
        btn_close_title          = 'Fermer l\'inventaire',

        settings_title           = 'Options de l\'inventaire',
        settings_section_layout  = 'Mise en page',
        settings_section_effects = 'Effets',
        settings_section_appearance = 'Apparence',
        settings_compact_label   = 'Mode compact',
        settings_compact_hint    = 'Cache l\'aperçu du ped, utilise la mise en page classique d\'ox_inventory.',
        settings_tarkov_label    = 'Mise en page Tarkov',
        settings_tarkov_hint     = 'Les objets s\'affichent à leur taille physique dans une grille dense.',
        settings_cursor_label    = 'Traînée de curseur',
        settings_cursor_hint     = 'Traînée de particules brillantes qui suit votre curseur.',
        settings_accent_label    = 'Couleur d\'accent',
        settings_shape_label     = 'Forme des icônes',
        settings_footer          = 'Options sauvegardées localement sur ce client.',

        section_player_title     = 'POCHES',
        section_player_subtitle  = 'Objets sur votre personnage',
        section_drop_title       = 'DROP',
        section_drop_subtitle    = 'Stockez des objets',
        section_newdrop_title    = 'NOUVEAU DROP',
        section_newdrop_subtitle = 'Déposez des objets ici',
        section_container_title  = 'CONTENEUR',
        section_container_subtitle = 'Objets stockés',
        section_stash_title      = 'CACHE',
        section_stash_subtitle   = 'Objets stockés',
        section_crafting_title   = 'FABRICATION',
        section_crafting_subtitle = 'Objets à fabriquer',
        section_shop_title       = 'BOUTIQUE',
        section_shop_subtitle    = 'Objets en vente',
        section_trunk_title      = 'COFFRE',
        section_trunk_subtitle   = 'Stockage du véhicule',
        section_glovebox_title   = 'BOÎTE À GANTS',
        section_glovebox_subtitle = 'Stockage du véhicule',
        section_otherplayer_title = 'POCHES',
        section_otherplayer_subtitle = 'Autre joueur',
        section_inspect_title    = 'INSPECTER',
        section_inspect_subtitle = 'Inventaire inspecté',

        empty_drop_title         = 'Ce drop est vide',
        empty_drop_subtitle      = 'Glissez des objets ici pour les stocker',

        license_badge            = 'OXLYN',
        license_title            = 'Signature de licence manquante',
        license_body             = 'Cette build de <strong>ox_inventory — OXLYN Redesign</strong> nécessite le fichier gatekeeper crypté (<code>oxlynsoftware.lua</code>) présent et chargé.',
        license_check_1          = 'Confirmez que la ressource a été téléchargée depuis votre compte Keymaster autorisé.',
        license_check_2          = 'Confirmez que <code>oxlynsoftware.lua</code> est listé dans <code>client_scripts</code>.',
        license_check_3          = 'Confirmez que le fichier <strong>n\'est pas</strong> dans <code>escrow_ignore</code>.',
        license_check_4          = 'Redémarrez le serveur entier.',
        license_footer           = 'oxlynsoftware.com · tous droits réservés',

        hotbar_title             = 'HOTBAR',
        hotbar_subtitle          = 'Équipez vos objets rapidement',
        slots_used               = 'Emplacements utilisés',

        search_placeholder       = 'Rechercher des objets...',
        search_matches           = 'trouvés',
        search_clear             = 'Effacer la recherche',

        settings_section_template = 'Modèle d\'inventaire',
        settings_template_label  = 'Modèle de disposition',
        tpl_showcase             = 'Showcase',
        tpl_showcase_hint        = 'Aperçu 3D du personnage entre les deux panneaux.',
        tpl_classic              = 'Classique',
        tpl_classic_hint         = 'Disposition classique plate, contrôles au centre.',
        tpl_tarkov               = 'Tarkov',
        tpl_tarkov_hint          = 'Grille dense — objets à leur taille physique.',
        tpl_grid                 = 'Grille',
        tpl_grid_hint            = 'Grille de cases raffinée — cases visibles, objets à taille physique avec plaque de nom.',
        settings_view_label      = 'Style de vue',
        settings_view_hint       = 'Modern affiche le personnage 3D avec N\'IMPORTE quel modèle ; Compact est la vue plate classique.',
        view_modern              = 'Modern',
        view_compact             = 'Compact',

        settings_theme_label     = 'Thème',
        theme_glass              = 'Glass',
        theme_tactical           = 'Tactique',
        theme_neon               = 'Néon',
        theme_minimal            = 'Minimal',
        theme_luxe               = 'Luxe',

        settings_rarity_label    = 'Style de rareté',
        rarity_style_wash        = 'Dégradé',
        rarity_style_outline     = 'Contour',
        rarity_style_both        = 'Les deux',
        rarity_style_off         = 'Désactivé',
        settings_cols_label      = 'Colonnes de la grille',
        settings_cols_hint       = 'Colonnes par panneau (dispositions classiques).',
        settings_scale_label     = 'Échelle de l\'interface',

        inventory_subtitle       = 'Équipement personnel',
        settings_slot_style_label = 'Style des cases',
        slot_style_glass         = 'Verre',
        slot_style_sharp         = 'Droit',
        slot_style_notched       = 'Chanfreiné',
        slot_style_frame         = 'Cadre',
        slot_style_minimal       = 'Minimal',
        settings_font_label      = 'Typographie',
        font_style_default       = 'Standard',
        font_style_condensed     = 'Condensée',
        font_style_tech          = 'Tech',
        font_style_rounded       = 'Arrondie',
        settings_labels_label    = 'Noms des objets',
        settings_labels_hint     = 'Afficher les noms toujours, au survol, ou jamais.',
        labels_on                = 'Toujours',
        labels_hover             = 'Survol',
        labels_off               = 'Masqués',

        tab_style                = 'Style',
        tab_display              = 'Interface',
        tab_texts                = 'Textes',
        preview_title            = 'APERÇU EN DIRECT',
        preview_note             = 'Se met à jour instantanément à chaque changement.',
        settings_hotbar_label    = 'Afficher la section hotbar',
        settings_hotbar_hint     = 'Le panneau des 5 quick-slots dans l\'inventaire.',
        settings_anim_label      = 'Animations',
        settings_anim_hint       = 'Le mode réduit désactive les entrées et les boucles d\'inactivité.',
        anim_full                = 'Complètes',
        anim_reduced             = 'Réduites',
        texts_intro              = 'Réécrivez ou masquez n\'importe quel texte de l\'UI — appliqué instantanément, sans config. L\'œil masque le texte complètement.',
        texts_locked             = 'Les textes sont verrouillés par un admin du serveur.',
        texts_reset_all          = 'Réinitialiser tous les textes',
        txtgrp_header            = 'En-tête',
        txtgrp_hotbar            = 'Hotbar',
        txtgrp_buttons           = 'Boutons',
        txtgrp_search            = 'Recherche',
        txtgrp_sections          = 'Titres des panneaux',
        txtgrp_rarity            = 'Noms de rareté',
        txtgrp_misc              = 'Divers',

        accent_custom            = 'Couleur personnalisée',
        settings_weight_label    = 'Style de la barre de poids',
        weight_segments          = 'Segments',
        weight_solid             = 'Pleine',
        weight_dial              = 'Cadran',
        weight_minimal           = 'Minimal',
        settings_badge_label     = 'Disposition des badges',
        settings_badge_hint      = 'Où se placent la quantité et le nom dans chaque case.',
        badge_auto               = 'Auto',
        badge_classic            = 'Classique',
        badge_eft                = 'EFT',
        badge_minimal            = 'Minimal',
        badge_bold               = 'Bold',

        -- Item notification anchor (v11)
        settings_notifypos_label = 'Position des notifications',
        settings_notifypos_hint  = 'Où apparaissent les notifications +objet / -objet à l’écran.',
        notifypos_top_left       = 'Haut gauche',
        notifypos_top_center     = 'Haut centre',
        notifypos_top_right      = 'Haut droite',
        notifypos_bottom_left    = 'Bas gauche',
        notifypos_bottom_center  = 'Bas centre',
        notifypos_bottom_right   = 'Bas droite',
        settings_tarkovped_label = 'Tarkov : personnage 3D',
        settings_tarkovped_hint  = 'Affiche le personnage 3D style Showcase entre les grilles Tarkov.',

        settings_clothing_label  = 'Emplacements de vêtements',
        settings_clothing_hint   = 'Emplacements d\'équipement autour du personnage — retirez des pièces en objets et remettez-les.',
        clothing_unequip         = 'Cliquez pour retirer',
        txtgrp_clothing          = 'Emplacements de vêtements',
        clothing_hat             = 'Chapeau',
        clothing_mask            = 'Masque',
        clothing_glasses         = 'Lunettes',
        clothing_ears            = 'Oreilles',
        clothing_chain           = 'Chaîne',
        clothing_watch           = 'Montre',
        clothing_jacket          = 'Veste',
        clothing_shirt           = 'Chemise',
        clothing_armor           = 'Gilet',
        clothing_bag             = 'Sac',
        clothing_pants           = 'Pantalon',
        clothing_shoes           = 'Chaussures',

        settings_reveal_label    = 'Animation d\'apparition du loot',
        settings_reveal_hint     = 'Comment les objets apparaissent à l\'ouverture d\'un coffre, magasin ou drop.',
        reveal_scan              = 'Scan',
        reveal_fade              = 'Fondu',
        reveal_pop               = 'Pop',
        reveal_off               = 'Désactivée',
        ctx_rotate               = 'Pivoter',
        settings_playerinfo_label = 'Infos du joueur',
        settings_playerinfo_hint = 'La carte avatar / nom / argent au-dessus de l\'inventaire.',
        playerinfo_full          = 'Complète',
        playerinfo_minimal       = 'Minimale',
        playerinfo_hidden        = 'Masquée',

        settings_sounds_label    = 'Sons d\'interface',
        settings_sounds_hint     = 'Effets discrets d\'ouverture / fermeture / prise / dépôt.',
        settings_dim_label       = 'Assombrir le monde',
        settings_dim_hint        = 'Assombrit le monde du jeu derrière l\'inventaire.',
        settings_section_systems = 'Systèmes',
        settings_search_label    = 'Barre de recherche',
        settings_search_hint     = 'Filtre en direct — les objets correspondants restent allumés.',

        rarity_common            = 'COMMUN',
        rarity_uncommon          = 'PEU COMMUN',
        rarity_rare              = 'RARE',
        rarity_epic              = 'ÉPIQUE',
        rarity_legendary         = 'LÉGENDAIRE',
        rarity_mythic            = 'MYTHIQUE',
    },

    -- ─────────────────────────────────────────────────────────
    -- GERMAN
    -- ─────────────────────────────────────────────────────────
    de = {
        inventory_title          = 'INVENTAR',
        player_name_fallback     = 'SPIELER',
        close_label_top          = 'Schließen',
        close_label_bottom       = 'Inventar',

        btn_use                  = 'NUTZEN',
        btn_give                 = 'GEBEN',
        btn_info                 = 'INFO',
        btn_settings             = 'OPTIONEN',
        btn_close                = 'SCHLIESSEN',
        btn_use_title            = 'Nutzen',
        btn_give_title           = 'Geben',
        btn_info_title           = 'Steuerung',
        btn_settings_title       = 'Optionen',
        btn_close_title          = 'Inventar schließen',

        settings_title           = 'Inventar-Einstellungen',
        settings_section_layout  = 'Layout',
        settings_section_effects = 'Effekte',
        settings_section_appearance = 'Aussehen',
        settings_compact_label   = 'Kompaktmodus',
        settings_compact_hint    = 'Versteckt Ped-Vorschau, klassisches ox_inventory-Layout.',
        settings_tarkov_label    = 'Tarkov-Layout',
        settings_tarkov_hint     = 'Items werden in physischer Größe in dichtem Raster gezeigt.',
        settings_cursor_label    = 'Cursor-Spur',
        settings_cursor_hint     = 'Leuchtende Partikelspur, die dem Cursor folgt.',
        settings_accent_label    = 'Akzentfarbe',
        settings_shape_label     = 'Symbolform',
        settings_footer          = 'Einstellungen lokal auf diesem Client gespeichert.',

        section_player_title     = 'TASCHEN',
        section_player_subtitle  = 'Gegenstände an deinem Charakter',
        section_drop_title       = 'DROP',
        section_drop_subtitle    = 'Lagere Gegenstände',
        section_newdrop_title    = 'NEUER DROP',
        section_newdrop_subtitle = 'Lege Gegenstände hier ab',
        section_container_title  = 'CONTAINER',
        section_container_subtitle = 'Gelagerte Gegenstände',
        section_stash_title      = 'LAGER',
        section_stash_subtitle   = 'Gelagerte Gegenstände',
        section_crafting_title   = 'CRAFTING',
        section_crafting_subtitle = 'Herstellbare Gegenstände',
        section_shop_title       = 'SHOP',
        section_shop_subtitle    = 'Gegenstände zum Verkauf',
        section_trunk_title      = 'KOFFERRAUM',
        section_trunk_subtitle   = 'Fahrzeugstauraum',
        section_glovebox_title   = 'HANDSCHUHFACH',
        section_glovebox_subtitle = 'Fahrzeugstauraum',
        section_otherplayer_title = 'TASCHEN',
        section_otherplayer_subtitle = 'Anderer Spieler',
        section_inspect_title    = 'INSPIZIEREN',
        section_inspect_subtitle = 'Inspiziertes Inventar',

        empty_drop_title         = 'Dieser Drop ist leer',
        empty_drop_subtitle      = 'Ziehe Gegenstände hierher',

        license_badge            = 'OXLYN',
        license_title            = 'Lizenzsignatur fehlt',
        license_body             = 'Diese Build von <strong>ox_inventory — OXLYN Redesign</strong> benötigt die verschlüsselte Gatekeeper-Datei (<code>oxlynsoftware.lua</code>).',
        license_check_1          = 'Bestätige, dass die Ressource aus deinem autorisierten Keymaster-Konto geladen wurde.',
        license_check_2          = 'Bestätige, dass <code>oxlynsoftware.lua</code> in <code>client_scripts</code> gelistet ist.',
        license_check_3          = 'Bestätige, dass die Datei <strong>nicht</strong> in <code>escrow_ignore</code> steht.',
        license_check_4          = 'Starte den gesamten Server neu.',
        license_footer           = 'oxlynsoftware.com · alle Rechte vorbehalten',

        hotbar_title             = 'HOTBAR',
        hotbar_subtitle          = 'Gegenstände schnell ausrüsten',
        slots_used               = 'Belegte Slots',

        search_placeholder       = 'Gegenstände suchen...',
        search_matches           = 'gefunden',
        search_clear             = 'Suche löschen',

        settings_section_template = 'Inventar-Vorlage',
        settings_template_label  = 'Layout-Vorlage',
        tpl_showcase             = 'Showcase',
        tpl_showcase_hint        = '3D-Charaktervorschau zwischen den beiden Panels.',
        tpl_classic              = 'Klassisch',
        tpl_classic_hint         = 'Flaches klassisches Layout, Steuerung in der Mitte.',
        tpl_tarkov               = 'Tarkov',
        tpl_tarkov_hint          = 'Dichtes Raster — Gegenstände in physischer Größe.',
        tpl_grid                 = 'Raster',
        tpl_grid_hint            = 'Poliertes Kachel-Raster — sichtbare Zellen, Gegenstände in physischer Größe mit Namensschild.',
        settings_view_label      = 'Ansichtsstil',
        settings_view_hint       = 'Modern zeigt den 3D-Charakter mit JEDER Vorlage; Compact ist die flache klassische Ansicht.',
        view_modern              = 'Modern',
        view_compact             = 'Compact',

        settings_theme_label     = 'Design',
        theme_glass              = 'Glass',
        theme_tactical           = 'Taktisch',
        theme_neon               = 'Neon',
        theme_minimal            = 'Minimal',
        theme_luxe               = 'Luxe',

        settings_rarity_label    = 'Seltenheits-Stil',
        rarity_style_wash        = 'Verlauf',
        rarity_style_outline     = 'Umriss',
        rarity_style_both        = 'Beides',
        rarity_style_off         = 'Aus',
        settings_cols_label      = 'Raster-Spalten',
        settings_cols_hint       = 'Spalten pro Inventar-Panel (klassische Layouts).',
        settings_scale_label     = 'UI-Skalierung',

        inventory_subtitle       = 'Persönliche Ausrüstung',
        settings_slot_style_label = 'Slot-Stil',
        slot_style_glass         = 'Glas',
        slot_style_sharp         = 'Eckig',
        slot_style_notched       = 'Gefast',
        slot_style_frame         = 'Rahmen',
        slot_style_minimal       = 'Minimal',
        settings_font_label      = 'Typografie',
        font_style_default       = 'Standard',
        font_style_condensed     = 'Kondensiert',
        font_style_tech          = 'Tech',
        font_style_rounded       = 'Rund',
        settings_labels_label    = 'Gegenstandsnamen',
        settings_labels_hint     = 'Namen immer, nur beim Hover, oder nie anzeigen.',
        labels_on                = 'Immer',
        labels_hover             = 'Hover',
        labels_off               = 'Versteckt',

        tab_style                = 'Stil',
        tab_display              = 'Anzeige',
        tab_texts                = 'Texte',
        preview_title            = 'LIVE-VORSCHAU',
        preview_note             = 'Aktualisiert sich sofort bei jeder Änderung.',
        settings_hotbar_label    = 'Hotbar-Bereich anzeigen',
        settings_hotbar_hint     = 'Das Panel der 5 Quick-Slots im Inventar.',
        settings_anim_label      = 'Animationen',
        settings_anim_hint       = 'Der reduzierte Modus deaktiviert Einblendungen und Idle-Loops.',
        anim_full                = 'Voll',
        anim_reduced             = 'Reduziert',
        texts_intro              = 'Beliebige UI-Texte umschreiben oder ausblenden — sofort wirksam, ohne Config. Das Auge blendet den Text komplett aus.',
        texts_locked             = 'Die Texte sind derzeit von einem Server-Admin gesperrt.',
        texts_reset_all          = 'Alle Texte zurücksetzen',
        txtgrp_header            = 'Kopfzeile',
        txtgrp_hotbar            = 'Hotbar',
        txtgrp_buttons           = 'Buttons',
        txtgrp_search            = 'Suche',
        txtgrp_sections          = 'Panel-Titel',
        txtgrp_rarity            = 'Seltenheitsnamen',
        txtgrp_misc              = 'Sonstiges',

        accent_custom            = 'Eigene Farbe',
        settings_weight_label    = 'Gewichtsanzeige-Stil',
        weight_segments          = 'Segmente',
        weight_solid             = 'Durchgehend',
        weight_dial              = 'Anzeige',
        weight_minimal           = 'Minimal',
        settings_badge_label     = 'Badge-Layout',
        settings_badge_hint      = 'Wo Anzahl und Name in jedem Slot sitzen.',
        badge_auto               = 'Auto',
        badge_classic            = 'Klassisch',
        badge_eft                = 'EFT',
        badge_minimal            = 'Minimal',
        badge_bold               = 'Bold',

        -- Item notification anchor (v11)
        settings_notifypos_label = 'Position der Benachrichtigungen',
        settings_notifypos_hint  = 'Wo die +Item / -Item Hinweise auf dem Bildschirm erscheinen.',
        notifypos_top_left       = 'Oben links',
        notifypos_top_center     = 'Oben mitte',
        notifypos_top_right      = 'Oben rechts',
        notifypos_bottom_left    = 'Unten links',
        notifypos_bottom_center  = 'Unten mitte',
        notifypos_bottom_right   = 'Unten rechts',
        settings_tarkovped_label = 'Tarkov: 3D-Charakter',
        settings_tarkovped_hint  = 'Zeigt den 3D-Charakter im Showcase-Stil zwischen den Tarkov-Rastern.',

        settings_clothing_label  = 'Kleidungs-Slots',
        settings_clothing_hint   = 'Ausrüstungs-Slots um den Charakter — Teile als Items ablegen und wieder anziehen.',
        clothing_unequip         = 'Klicken zum Ausziehen',
        txtgrp_clothing          = 'Kleidungs-Slots',
        clothing_hat             = 'Hut',
        clothing_mask            = 'Maske',
        clothing_glasses         = 'Brille',
        clothing_ears            = 'Ohren',
        clothing_chain           = 'Kette',
        clothing_watch           = 'Uhr',
        clothing_jacket          = 'Jacke',
        clothing_shirt           = 'Hemd',
        clothing_armor           = 'Weste',
        clothing_bag             = 'Tasche',
        clothing_pants           = 'Hose',
        clothing_shoes           = 'Schuhe',

        settings_reveal_label    = 'Loot-Erscheinungsanimation',
        settings_reveal_hint     = 'Wie Gegenstände beim Öffnen von Stash, Shop oder Drop erscheinen.',
        reveal_scan              = 'Scan',
        reveal_fade              = 'Einblenden',
        reveal_pop               = 'Pop',
        reveal_off               = 'Aus',
        ctx_rotate               = 'Drehen',
        settings_playerinfo_label = 'Spieler-Info',
        settings_playerinfo_hint = 'Die Avatar- / Namens- / Geld-Karte über dem Inventar.',
        playerinfo_full          = 'Voll',
        playerinfo_minimal       = 'Minimal',
        playerinfo_hidden        = 'Versteckt',

        settings_sounds_label    = 'Interface-Sounds',
        settings_sounds_hint     = 'Dezente Öffnen- / Schließen- / Aufnehmen- / Ablegen-Sounds.',
        settings_dim_label       = 'Welt abdunkeln',
        settings_dim_hint        = 'Dunkelt die Spielwelt hinter dem Inventar ab.',
        settings_section_systems = 'Systeme',
        settings_search_label    = 'Suchleiste',
        settings_search_hint     = 'Live-Filter — passende Gegenstände bleiben hell.',

        rarity_common            = 'GEWÖHNLICH',
        rarity_uncommon          = 'UNGEWÖHNLICH',
        rarity_rare              = 'SELTEN',
        rarity_epic              = 'EPISCH',
        rarity_legendary         = 'LEGENDÄR',
        rarity_mythic            = 'MYTHISCH',
    },

    -- ─────────────────────────────────────────────────────────
    -- ITALIAN
    -- ─────────────────────────────────────────────────────────
    it = {
        inventory_title          = 'INVENTARIO',
        player_name_fallback     = 'GIOCATORE',
        close_label_top          = 'Chiudi',
        close_label_bottom       = 'Inventario',

        btn_use                  = 'USA',
        btn_give                 = 'DAI',
        btn_info                 = 'INFO',
        btn_settings             = 'OPZIONI',
        btn_close                = 'CHIUDI',
        btn_use_title            = 'Usa',
        btn_give_title           = 'Dai',
        btn_info_title           = 'Controlli',
        btn_settings_title       = 'Opzioni',
        btn_close_title          = 'Chiudi inventario',

        settings_title           = 'Opzioni inventario',
        settings_section_layout  = 'Layout',
        settings_section_effects = 'Effetti',
        settings_section_appearance = 'Aspetto',
        settings_compact_label   = 'Modalità compatta',
        settings_compact_hint    = 'Nasconde l\'anteprima del ped, layout classico di ox_inventory.',
        settings_tarkov_label    = 'Layout Tarkov',
        settings_tarkov_hint     = 'Gli oggetti hanno dimensioni fisiche in una griglia densa.',
        settings_cursor_label    = 'Scia del cursore',
        settings_cursor_hint     = 'Scia di particelle luminose che segue il cursore.',
        settings_accent_label    = 'Colore accento',
        settings_shape_label     = 'Forma icone',
        settings_footer          = 'Opzioni salvate localmente su questo client.',

        section_player_title     = 'TASCHE',
        section_player_subtitle  = 'Oggetti sul tuo personaggio',
        section_drop_title       = 'DROP',
        section_drop_subtitle    = 'Conserva oggetti',
        section_newdrop_title    = 'NUOVO DROP',
        section_newdrop_subtitle = 'Lascia oggetti qui',
        section_container_title  = 'CONTENITORE',
        section_container_subtitle = 'Oggetti conservati',
        section_stash_title      = 'DEPOSITO',
        section_stash_subtitle   = 'Oggetti conservati',
        section_crafting_title   = 'CRAFTING',
        section_crafting_subtitle = 'Oggetti craftabili',
        section_shop_title       = 'NEGOZIO',
        section_shop_subtitle    = 'Oggetti in vendita',
        section_trunk_title      = 'BAGAGLIAIO',
        section_trunk_subtitle   = 'Spazio del veicolo',
        section_glovebox_title   = 'CRUSCOTTO',
        section_glovebox_subtitle = 'Spazio del veicolo',
        section_otherplayer_title = 'TASCHE',
        section_otherplayer_subtitle = 'Altro giocatore',
        section_inspect_title    = 'ISPEZIONA',
        section_inspect_subtitle = 'Inventario ispezionato',

        empty_drop_title         = 'Questo drop è vuoto',
        empty_drop_subtitle      = 'Trascina oggetti qui per conservarli',

        license_badge            = 'OXLYN',
        license_title            = 'Firma licenza mancante',
        license_body             = 'Questa build di <strong>ox_inventory — OXLYN Redesign</strong> richiede il file gatekeeper criptato (<code>oxlynsoftware.lua</code>).',
        license_check_1          = 'Conferma che la risorsa sia stata scaricata dal tuo account Keymaster autorizzato.',
        license_check_2          = 'Conferma che <code>oxlynsoftware.lua</code> sia in <code>client_scripts</code>.',
        license_check_3          = 'Conferma che il file <strong>non</strong> sia in <code>escrow_ignore</code>.',
        license_check_4          = 'Riavvia l\'intero server.',
        license_footer           = 'oxlynsoftware.com · tutti i diritti riservati',

        hotbar_title             = 'HOTBAR',
        hotbar_subtitle          = 'Equipaggia gli oggetti rapidamente',
        slots_used               = 'Slot usati',

        search_placeholder       = 'Cerca oggetti...',
        search_matches           = 'trovati',
        search_clear             = 'Cancella ricerca',

        settings_section_template = 'Modello inventario',
        settings_template_label  = 'Modello di layout',
        tpl_showcase             = 'Showcase',
        tpl_showcase_hint        = 'Anteprima 3D del personaggio tra i due pannelli.',
        tpl_classic              = 'Classico',
        tpl_classic_hint         = 'Layout classico piatto, controlli al centro.',
        tpl_tarkov               = 'Tarkov',
        tpl_tarkov_hint          = 'Griglia densa — oggetti a dimensione fisica.',
        tpl_grid                 = 'Griglia',
        tpl_grid_hint            = 'Griglia di celle rifinita — celle visibili, oggetti a dimensione fisica con targhetta.',
        settings_view_label      = 'Stile di vista',
        settings_view_hint       = 'Modern mostra il personaggio 3D con QUALSIASI modello; Compact è la vista piatta classica.',
        view_modern              = 'Modern',
        view_compact             = 'Compact',

        settings_theme_label     = 'Tema',
        theme_glass              = 'Glass',
        theme_tactical           = 'Tattico',
        theme_neon               = 'Neon',
        theme_minimal            = 'Minimal',
        theme_luxe               = 'Luxe',

        settings_rarity_label    = 'Stile rarità',
        rarity_style_wash        = 'Sfumatura',
        rarity_style_outline     = 'Contorno',
        rarity_style_both        = 'Entrambi',
        rarity_style_off         = 'Spento',
        settings_cols_label      = 'Colonne griglia',
        settings_cols_hint       = 'Colonne per pannello (layout classici).',
        settings_scale_label     = 'Scala interfaccia',

        inventory_subtitle       = 'Equipaggiamento personale',
        settings_slot_style_label = 'Stile caselle',
        slot_style_glass         = 'Vetro',
        slot_style_sharp         = 'Netto',
        slot_style_notched       = 'Smussato',
        slot_style_frame         = 'Cornice',
        slot_style_minimal       = 'Minimal',
        settings_font_label      = 'Tipografia',
        font_style_default       = 'Standard',
        font_style_condensed     = 'Condensata',
        font_style_tech          = 'Tech',
        font_style_rounded       = 'Arrotondata',
        settings_labels_label    = 'Nomi degli oggetti',
        settings_labels_hint     = 'Mostra i nomi sempre, solo al passaggio, o mai.',
        labels_on                = 'Sempre',
        labels_hover             = 'Hover',
        labels_off               = 'Nascosti',

        tab_style                = 'Stile',
        tab_display              = 'Interfaccia',
        tab_texts                = 'Testi',
        preview_title            = 'ANTEPRIMA LIVE',
        preview_note             = 'Si aggiorna istantaneamente ad ogni modifica.',
        settings_hotbar_label    = 'Mostra sezione hotbar',
        settings_hotbar_hint     = 'Il pannello dei 5 quick-slot nell\'inventario.',
        settings_anim_label      = 'Animazioni',
        settings_anim_hint       = 'La modalità ridotta disattiva ingressi e loop di idle.',
        anim_full                = 'Complete',
        anim_reduced             = 'Ridotte',
        texts_intro              = 'Riscrivi o nascondi qualsiasi testo della UI — si applica all\'istante, senza config. L\'occhio nasconde il testo del tutto.',
        texts_locked             = 'I testi sono bloccati da un admin del server.',
        texts_reset_all          = 'Ripristina tutti i testi',
        txtgrp_header            = 'Intestazione',
        txtgrp_hotbar            = 'Hotbar',
        txtgrp_buttons           = 'Pulsanti',
        txtgrp_search            = 'Ricerca',
        txtgrp_sections          = 'Titoli dei pannelli',
        txtgrp_rarity            = 'Nomi di rarità',
        txtgrp_misc              = 'Varie',

        accent_custom            = 'Colore personalizzato',
        settings_weight_label    = 'Stile della barra del peso',
        weight_segments          = 'Segmenti',
        weight_solid             = 'Piena',
        weight_dial              = 'Quadrante',
        weight_minimal           = 'Minimal',
        settings_badge_label     = 'Layout dei badge',
        settings_badge_hint      = 'Dove si trovano quantità e nome in ogni casella.',
        badge_auto               = 'Auto',
        badge_classic            = 'Classico',
        badge_eft                = 'EFT',
        badge_minimal            = 'Minimal',
        badge_bold               = 'Bold',

        -- Item notification anchor (v11)
        settings_notifypos_label = 'Posizione delle notifiche',
        settings_notifypos_hint  = 'Dove appaiono gli avvisi +oggetto / -oggetto sullo schermo.',
        notifypos_top_left       = 'In alto a sx',
        notifypos_top_center     = 'In alto al centro',
        notifypos_top_right      = 'In alto a dx',
        notifypos_bottom_left    = 'In basso a sx',
        notifypos_bottom_center  = 'In basso al centro',
        notifypos_bottom_right   = 'In basso a dx',
        settings_tarkovped_label = 'Tarkov: personaggio 3D',
        settings_tarkovped_hint  = 'Mostra il personaggio 3D stile Showcase tra le griglie Tarkov.',

        settings_clothing_label  = 'Slot abbigliamento',
        settings_clothing_hint   = 'Slot di equipaggiamento attorno al personaggio — togli i capi come oggetti e rimettili.',
        clothing_unequip         = 'Clicca per togliere',
        txtgrp_clothing          = 'Slot abbigliamento',
        clothing_hat             = 'Cappello',
        clothing_mask            = 'Maschera',
        clothing_glasses         = 'Occhiali',
        clothing_ears            = 'Orecchie',
        clothing_chain           = 'Catena',
        clothing_watch           = 'Orologio',
        clothing_jacket          = 'Giacca',
        clothing_shirt           = 'Camicia',
        clothing_armor           = 'Giubbotto',
        clothing_bag             = 'Zaino',
        clothing_pants           = 'Pantaloni',
        clothing_shoes           = 'Scarpe',

        settings_reveal_label    = 'Animazione comparsa loot',
        settings_reveal_hint     = 'Come compaiono gli oggetti aprendo uno stash, negozio o drop.',
        reveal_scan              = 'Scan',
        reveal_fade              = 'Dissolvenza',
        reveal_pop               = 'Pop',
        reveal_off               = 'Spenta',
        ctx_rotate               = 'Ruota',
        settings_playerinfo_label = 'Info giocatore',
        settings_playerinfo_hint = 'La scheda avatar / nome / denaro sopra l\'inventario.',
        playerinfo_full          = 'Completa',
        playerinfo_minimal       = 'Minima',
        playerinfo_hidden        = 'Nascosta',

        settings_sounds_label    = 'Suoni interfaccia',
        settings_sounds_hint     = 'Effetti discreti di apertura / chiusura / presa / rilascio.',
        settings_dim_label       = 'Oscura mondo',
        settings_dim_hint        = 'Oscura il mondo di gioco dietro l\'inventario.',
        settings_section_systems = 'Sistemi',
        settings_search_label    = 'Barra di ricerca',
        settings_search_hint     = 'Filtro in tempo reale — gli oggetti corrispondenti restano accesi.',

        rarity_common            = 'COMUNE',
        rarity_uncommon          = 'NON COMUNE',
        rarity_rare              = 'RARO',
        rarity_epic              = 'EPICO',
        rarity_legendary         = 'LEGGENDARIO',
        rarity_mythic            = 'MITICO',
    },

    -- ─────────────────────────────────────────────────────────
    -- Add your own language by copying any block above and
    -- translating the values. Then set RWInv.Locale = 'xx'.
    -- ─────────────────────────────────────────────────────────
}

return RWInv
