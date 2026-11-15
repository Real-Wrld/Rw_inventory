--  REALWRLD Software® · ox_inventory V3 · settings sanitizer schema (v4)
--
--  `keys` mirrors web/src/lib/settings/schema.ts (every FORCEABLE player
--  setting); `legacyKeys` are the V2/V3 names older configs, KVPs and
--  clients still send — they are validated and passed through unchanged,
--  and the NUI maps them onto the v4 keys (web/src/lib/settings/legacy.ts).
--  `web/tools/check-schema-parity.mjs` fails the web build when a key /
--  option / range here differs from the TS schema.
--
--  Consumed by modules/rwadmin/server.lua (`sanitizeSettings`):
--    enum   → value must be in `values` (after `legacyValues` mapping)
--    bool   → boolean
--    number → number, clamped to [min,max]; math.floor when `int`;
--             the string 'auto' accepted when `auto = true`
--    color  → '#rrggbb' (lower-cased) | preset id | 'auto' | 'inherit'
--    colors → { [tier] = '#rrggbb' } for the listed tiers only
--    texts  → { [key] = string|false } (V2 rule, bounded)
-- ═════════════════════════════════════════════════════════════

local ACCENTS = { 'red', 'rose', 'orange', 'gold', 'yellow', 'lime', 'green', 'emerald', 'teal', 'cyan', 'sky', 'blue', 'indigo', 'purple', 'fuchsia', 'pink', 'silver' }
local TIERS = { 'common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic' }

local function enum(...) return { type = 'enum', values = { ... } } end
local function bool() return { type = 'bool' } end
local function num(min, max, opts)
    local t = { type = 'number', min = min, max = max }
    if opts then for k, v in pairs(opts) do t[k] = v end end
    return t
end
local function color(opts)
    local t = { type = 'color' }
    if opts then for k, v in pairs(opts) do t[k] = v end end
    return t
end

local M = {
    version = 4,
    keys = {
        -- ── style ──
        palette        = enum('vanguard', 'tactical', 'neon', 'minimal', 'luxe', 'graphite', 'obsidian', 'midnight', 'slate', 'forest', 'wine', 'ocean', 'sand-dark', 'ivory', 'arctic', 'paper'),
        skin           = enum('glass', 'tactical', 'neon', 'minimal', 'luxe', 'refined', 'frosted', 'panels'),
        accent         = color({ presets = ACCENTS }),   -- preset ids are turned into their hex by the NUI
        corner         = enum('sharp', 'soft', 'round'),
        density        = enum('cozy', 'regular', 'large'),
        uiScale        = num(0.5, 2.0),                   -- server range stays wider than the UI range (0.8–1.3)
        rarity         = enum('wash', 'edge', 'both', 'glow', 'bar', 'dot', 'off'),
        rarityColors   = { type = 'colors', tiers = TIERS },
        material       = enum('solid', 'glass', 'liquid', 'clear'),
        surfaceAlpha   = num(20, 100),
        slotStyle      = enum('glass', 'sharp', 'notched', 'frame', 'minimal', 'outline', 'inset', 'squircle'),
        badges         = enum('auto', 'classic', 'eft', 'minimal', 'bold'),
        iconShape      = enum('hex', 'shield', 'diamond', 'beveled', 'circle', 'square', 'pentagon', 'gem', 'squircle', 'octagon', 'star', 'triangle', 'drop', 'leaf', 'ticket', 'ring', 'none'),
        iconPack       = enum('fa', 'line', 'duo', 'fill', 'thin'),
        font           = enum('inter', 'condensed', 'tech', 'rounded', 'poppins', 'montserrat', 'manrope', 'space', 'rajdhani', 'barlow', 'exo', 'roboto'),

        -- ── layout ──
        layout         = enum('showcase', 'classic', 'tarkov', 'grid', 'wings', 'sidebar', 'deck', 'ledger'),
        pedView        = bool(),
        shopView       = enum('store', 'split'),
        cols           = num(5, 7, { int = true }),
        reveal         = enum('scan', 'fade', 'pop', 'off'),
        tilt           = enum('off', 'subtle', 'medium', 'strong', 'extreme'),
        parallax       = bool(),
        entrance       = enum('fade', 'rise', 'slide', 'zoom', 'flip'),
        clothingRails  = bool(),
        labels         = enum('always', 'hover', 'off'),
        counts         = bool(),
        durability     = enum('bar', 'ring', 'off'),
        infoTrigger    = enum('hover', 'alt', 'click'),
        infoDelay      = num(0, 600),
        header         = enum('banner', 'card', 'minimal', 'pills', 'off'),
        titleStyle     = enum('icon', 'mark', 'plain', 'underline', 'bracket', 'badge', 'tab', 'split', 'outline', 'index'),
        weightStyle    = enum('segments', 'solid', 'dial', 'bar', 'pill', 'text', 'off', 'ticks', 'battery', 'arc', 'dots', 'heat', 'stat'),
        weightPercent  = bool(),
        searchBar      = bool(),
        pocketPos      = enum('hotbar', 'top'),

        -- ── hud ──
        dockLabels     = bool(),
        dockStyle      = enum('classic', 'pill', 'tiles'),
        hotbarStyle    = enum('inline', 'floating', 'both'),
        hotbarAlways   = bool(),
        notifyEnabled  = bool(),
        notifyPosition = enum('top-left', 'top-center', 'top-right', 'bottom-left', 'bottom-center', 'bottom-right'),
        notifyDuration = num(1000, 8000),

        -- ── effects ──
        motion          = enum('full', 'reduced', 'off'),
        hoverFx         = enum('lift', 'glow', 'scale', 'none'),
        bgBlur          = enum('off', 'vehicle', 'always'),
        bgDim           = num(0, 60),
        sounds          = bool(),
        soundVolume     = num(0, 100),
        cursorEffect    = enum('ribbon', 'sparkles', 'comet', 'dots', 'ring-pulse', 'glow-orb', 'embers', 'snow', 'bubbles', 'pixel-trail', 'crosshair', 'halo-follow', 'confetti-burst', 'magnetic-dust', 'ink', 'aurora', 'none'),
        cursorColorMode = enum('accent', 'white', 'custom', 'rainbow'),
        cursorColor     = color(),
        cursorDensity   = num(0, 100),

        -- ── ground drops (drops module contract names) ──
        pickupStyle      = enum('arc', 'minimal', 'ring', 'tag', 'card', 'dot'),
        pickupScale      = num(0.7, 1.4),
        pickupName       = bool(),
        pickupCount      = bool(),
        pickupKeyHint    = bool(),
        pickupAnchor     = enum('world', 'screen'),
        pickupAccentMode = enum('theme', 'rarity', 'custom'),
        pickupAccent     = color({ inherit = true }),
        pickupMarker     = enum('ring', 'dot', 'diamond', 'beam', 'none'),
        pickupRingColor  = color({ inherit = true }),

        -- ── language ──
        language       = enum('auto', 'en', 'pt', 'es', 'fr', 'de', 'it', 'lt', 'pl', 'nl', 'ru', 'tr'),
    },

    -- V2 / V3 keys still accepted (mixed-version servers, old KVPs, config.lua)
    legacyKeys = {
        theme         = enum('glass', 'obsidian', 'arctic', 'midnight', 'graphite', 'emerald', 'rose-quartz', 'amber-sand', 'ocean', 'lavender', 'carbon', 'ivory', 'forest', 'crimson-night', 'cyber-teal', 'mono-light', 'sunset', 'slate', 'nord', 'custom', 'tactical', 'neon', 'minimal', 'luxe'),
        accentColor   = color({ presets = ACCENTS, auto = true }),
        viewStyle     = enum('modern', 'compact'),
        rarityStyle   = enum('wash', 'glow-soft', 'glow-strong', 'gradient-wash', 'corner-tag', 'top-bar', 'bottom-bar', 'ribbon', 'halo', 'dotted-frame', 'badge-pill', 'holo-shimmer', 'pulse', 'border-gradient', 'inner-fade', 'outline', 'both', 'off'),
        labelMode     = enum('on', 'hover', 'off'),
        animMode      = enum('full', 'reduced'),
        clothingPanel = bool(),
        playerInfo    = enum('full', 'minimal', 'hidden'),
        tipTrigger    = enum('hover', 'alt', 'off'),
        tipDelay      = num(0, 1200),
        gridCell      = enum('auto', 'compact', 'regular', 'large'),
        gridCols      = num(4, 8, { int = true }),
        radius        = num(0, 24, { auto = true }),
        showHotbar    = bool(),
        cursorTrail   = bool(),
        rarityCommon    = color({ auto = true }),
        rarityUncommon  = color({ auto = true }),
        rarityRare      = color({ auto = true }),
        rarityEpic      = color({ auto = true }),
        rarityLegendary = color({ auto = true }),
        rarityMythic    = color({ auto = true }),
        textOverrides = { type = 'texts', maxEntries = 128, maxKey = 64, maxValue = 200 },
        tarkovPed     = bool(),
        playerCard    = enum('full', 'compact', 'off'),   -- 3.1 name of `header`
        badgeStyle    = enum('auto', 'classic', 'eft', 'minimal', 'bold'),   -- V2 names of 3.3 keys
        fontStyle     = enum('default', 'condensed', 'tech', 'rounded'),
        revealFx      = enum('scan', 'fade', 'pop', 'off'),
        worldDim      = bool(),
        compactMode   = bool(),
        tarkovMode    = bool(),
    },

    -- old option id → current option id (v4 keys: same map as LEGACY_VALUES in
    -- web/src/lib/settings/legacy.ts; legacy keys: their V3 renames)
    legacyValues = {
        layout = { ['sidebar-left'] = 'classic', ['sidebar-right'] = 'classic', ['bottom-dock'] = 'classic', ['top-dock'] = 'classic', ['split-wide'] = 'classic', ['center-stack'] = 'classic', ['minimal-floating'] = 'classic', compact = 'classic', perspective = 'showcase' },
        weightStyle = { ring = 'dial', minimal = 'text' },
        header = { full = 'banner' },
        cursorEffect = { sparkle = 'sparkles', ring = 'ring-pulse' },
        cursorColorMode = { accent2 = 'accent' },
        theme = { aurora = 'lavender', ember = 'sunset', mono = 'mono-light', aurora_dark = 'midnight' },
        rarityStyle = { ['edge-glow'] = 'glow-soft', ['left-stripe'] = 'top-bar', ['corner-dot'] = 'badge-pill', ['soft-halo'] = 'halo', frame = 'dotted-frame', ['label-tint'] = 'bottom-bar', ['count-tint'] = 'badge-pill', radial = 'inner-fade' },
    },
}

local function inList(list, v)
    for i = 1, #list do if list[i] == v then return true end end
    return false
end

local function sanitizeOne(key, def, v, out)
    local t = def.type
    if t == 'bool' then
        if type(v) == 'boolean' then out[key] = v end
    elseif t == 'enum' then
        if type(v) == 'string' then
            local map = M.legacyValues[key]
            v = map and map[v] or v
            if inList(def.values, v) then out[key] = v end
        end
    elseif t == 'number' then
        if type(v) == 'number' and v == v then
            if v < def.min then v = def.min elseif v > def.max then v = def.max end
            out[key] = def.int and math.floor(v) or v
        elseif v == 'auto' and def.auto then
            out[key] = v
        end
    elseif t == 'color' then
        if type(v) == 'string' then
            local lower = v:lower()
            if lower:match('^#%x%x%x%x%x%x$') or (def.presets and inList(def.presets, lower))
                or (def.auto and lower == 'auto') or (def.inherit and lower == 'inherit') then
                out[key] = lower
            end
        end
    elseif t == 'colors' then
        if type(v) == 'table' then
            local colors = {}
            for i = 1, #def.tiers do
                local c = v[def.tiers[i]]
                if type(c) == 'string' and c:match('^#%x%x%x%x%x%x$') then colors[def.tiers[i]] = c:lower() end
            end
            out[key] = colors
        end
    elseif t == 'texts' then
        if type(v) == 'table' then
            local texts, n = {}, 0
            for k, tv in pairs(v) do
                if n >= def.maxEntries then break end
                if type(k) == 'string' and #k <= def.maxKey then
                    if tv == false then texts[k] = false n = n + 1
                    elseif type(tv) == 'string' and #tv <= def.maxValue then texts[k] = tv n = n + 1 end
                end
            end
            out[key] = texts
        end
    end
end

---Whitelists + type-checks a settings payload (v4 keys and the accepted
---legacy keys). Output never contains unknown keys.
---@param s any
---@return table
function M.sanitize(s)
    local out = {}
    if type(s) ~= 'table' then return out end
    for key, def in pairs(M.keys) do
        if s[key] ~= nil then sanitizeOne(key, def, s[key], out) end
    end
    for key, def in pairs(M.legacyKeys) do
        if s[key] ~= nil and out[key] == nil then sanitizeOne(key, def, s[key], out) end
    end
    return out
end

return M
