

-- ═══════════════════════════════════════════════════════════════════════════
--  REALWRLD · 3D PRINTER SYSTEM
--  config/config.lua — everything you can change without touching the code
-- ═══════════════════════════════════════════════════════════════════════════
--
--  The printable items live in their own file: config/items.lua
--
--  Most of this can also be changed IN GAME with /printeradmin (admins only).
--  Once you edit the catalogue or the battery in that console the database
--  becomes the source of truth and this file stops being read for those
--  values — until you press "Restore defaults" in the console, which loads
--  config/items.lua again and throws away the in-game edits.
--
-- ═══════════════════════════════════════════════════════════════════════════

PrinterConfig = {}

-- ═══════════════════════════════════════════════════════════════════════════
--  GENERAL
-- ═══════════════════════════════════════════════════════════════════════════

--- PrinterFramework. 'auto' detects it for you.
--- Force one with: 'esx' · 'qb' · 'qbox' · 'standalone'
---
--- Standalone works: printers are owned by the player's license and job locks
--- simply never match. Everything else behaves the same.
PrinterConfig.Framework = 'auto'

--- PrinterInventory. 'auto' detects it for you.
--- Force one with:
---   'ox'     ox_inventory
---   'ak47'   ak47_inventory (detected BEFORE ox: its ox compat layer can
---            claim the ox_inventory resource name without the ox exports)
---   'qb'     qb-inventory / ps-inventory
---   'qs'     qs-inventory (Quasar)
---   'codem'  codem-inventory
---   'origen' origen_inventory
---   'tgiann' tgiann-inventory
---   'core'   core_inventory
---   'esx'    the framework's own inventory
---
--- Anything not on that list: open bridge/custom.lua and fill in the four
--- functions there, then set this to 'custom'. That file is OPEN IN BOTH
--- EDITIONS, escrow included, and nothing else in the resource changes.
---
--- You can also define just ONE of those four and leave this on 'auto': what
--- you define overrides the detected inventory, function by function. Useful
--- when a fork answers differently on a single export.
-- HOSTED BUILD (modules/rwprinter inside ox_inventory): forced to 'ox'.
-- The 'auto' probe reads GetResourceState('ox_inventory'), which cannot be
-- trusted from inside ox_inventory itself while it is still starting, and
-- the framework fallback would pick the QB bridge on a Qbox server.
PrinterConfig.Inventory = 'ox'

--- Notifications. 'auto' uses whatever notification script you already run.
--- Force one with:
---   'builtin'  this resource's own toast (no dependency, always available)
---   'ox_lib' · 'okok' · 'mythic' · 't-notify' · 'brutal' · 'wasabi'
---   'esx'    · 'qb'
---   'custom' your own function — see below
---
--- For 'custom', define a global NotifyCustom(message, kind) in any shared
--- file. `kind` is 'info' | 'success' | 'error' | 'warning'. Example:
---
---   function NotifyCustom(message, kind)
---       exports['my-notify']:Send(message, kind, 5000)
---   end
PrinterConfig.Notify = 'auto'

--- Language. There must be a matching locales/<locale>.lua file.
--- Shipped: 'en' (English), 'pt' (Portuguese) and 'fr' (French).
---
--- A key missing from a translation falls back to English, never to the raw
--- key -- so a half-finished locale is usable rather than broken.
PrinterConfig.Locale = 'en'

--- Save printers to the database so they survive a server restart.
---
--- With this off the resource still works, but printers, their queues and
--- everything edited in /printeradmin last only until the next restart.
--- Requires oxmysql. The tables are created automatically on first start.
PrinterConfig.Persistence = true

--- Print extra information to the server console. Leave off in production.
PrinterConfig.Debug = false

-- ═══════════════════════════════════════════════════════════════════════════
--  PROP AND ITEM
-- ═══════════════════════════════════════════════════════════════════════════

--- The printer model. It ships inside this resource, in stream/.
PrinterConfig.PropModel = 'prop_3dprinter_01'

--- The inventory item a player needs in order to place a printer.
--- Add it to your inventory's item list — the README has a ready-made entry
--- for ox_inventory, QBCore and ESX.
--- Renomeaste o item na tua items list? Aceita uma LISTA de nomes, e o
--- servidor tira o primeiro que o jogador tenha mesmo:
---
---   PrinterConfig.PrinterItem = { '3dprinter', 'printer_3d', 'weapon_printer' }
---
--- O PRIMEIRO da lista e o canonico: e o que /giveprinter da e o que volta ao
--- inventario quando a maquina e levantada.
---
--- Se o nome aqui nao for o nome na tua items list, o jogador usa o item, a
--- colocacao abre, e o servidor nao encontra nada para tirar. A consola do
--- servidor diz exactamente isso quando acontece.
PrinterConfig.PrinterItem = '3dprinter'

--- How many printers one player may have placed at the same time.
--- 0 = no limit.
PrinterConfig.MaxPrintersPerPlayer = 3

--- Only the owner (and the friends they authorise) can use a printer.
--- Friends are managed by the owner in the printer's own Settings tab.
---
--- Off: anyone who walks up to a printer can use it.
PrinterConfig.OwnerOnly = true

--- Give the item back when the owner picks a printer up.
PrinterConfig.ReturnItemOnPickup = true

-- ═══════════════════════════════════════════════════════════════════════════
--  PLACEMENT
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Using the item opens a ghost preview the player moves around and drops.
-- The server checks the distance again before it accepts the position, so a
-- modified client cannot place a printer across the map.

PrinterConfig.Placement = {
    --- How far from the player the printer can be placed, in metres.
    --- Distances here are measured from the PLAYER, never from the camera:
    --- in third person the camera sits several metres behind the ped, so a
    --- camera-relative reach put the ghost behind the player's back.
    maxDistance     = 6.0,
    --- Starting reach, in metres. The ghost lands on whatever surface you are
    --- looking at; this is the furthest it will go while you aim past it.
    startDistance   = 3.2,
    --- Closest the ghost can be pulled in, in metres. Below ~1 m it ends up
    --- inside the player.
    minDistance     = 1.0,
    --- Start the printer facing the player instead of facing the same way the
    --- player is. true = you see the front of the machine while placing it.
    faceCamera      = true,
    --- Degrees turned per scroll tick.
    rotationStep    = 2.5,
    --- Metres moved per height tick.
    heightStep      = 0.02,
    --- Height limits relative to the ground, in metres. The lower bound is
    --- generous on purpose: it is what lets a printer be dropped onto a floor
    --- the engine did not report, or sunk into an uneven one.
    minHeight       = -2.0,
    maxHeight       = 3.0,
    --- Refuse a spot with a wall between the player and the ghost. Obstacles
    --- the player is AIMING AT are never treated as walls, so the printer can
    --- be pushed right up against a crate, a counter or a fence.
    blockThroughWalls = true,
    --- How far in front of the target an obstacle has to be before it counts
    --- as a wall, in metres. Raise it to make placing near clutter easier.
    wallTolerance   = 0.6,
    --- Demand that the engine finds a surface under the printer. Left false so
    --- interiors, thin platforms and boat decks — where the ground query comes
    --- back empty even though the floor is right there — still accept a
    --- printer; the player levels it with the height keys.
    requireSurface  = false,
    --- Ghost transparency, 0-255.
    ghostAlpha      = 160,
    --- Outline colours {r, g, b} for a valid and an invalid spot.
    outlineValid    = { 0, 200, 130 },
    outlineInvalid  = { 220, 60, 60 },
    --- Refuse to place on water.
    blockOnWater    = true,
    --- Minimum distance between two printers, in metres.
    minSpacing      = 2.2,
}

--- Keys used while placing. These are FiveM control ids.
--- Reference: https://docs.fivem.net/docs/game-references/controls/
PrinterConfig.Keys = {
    place       = 38,   -- E
    cancel      = 177,  -- BACKSPACE
    rotateLeft  = 44,   -- Q
    rotateRight = 46,   -- overwritten below, see the note
    raise       = 172,  -- ARROW UP
    lower       = 173,  -- ARROW DOWN
    nearer      = 174,  -- ARROW LEFT
    further     = 175,  -- ARROW RIGHT
    snapGround  = 47,   -- G
    interact    = 38,   -- E
}
-- Rotating also works with the mouse wheel, which is the main way to do it.
-- Q and R are the alternative for laptop players.
PrinterConfig.Keys.rotateRight = 45 -- R (46 is E, which already confirms)

-- ═══════════════════════════════════════════════════════════════════════════
--  INTERACTION
-- ═══════════════════════════════════════════════════════════════════════════

--- Distance at which the [E] prompt appears, measured from the BASE of the
--- prop. The printer is 1.77 m wide, so 0.88 m from its centre to the surface:
--- anything under 2.0 only shows the prompt with the player touching it.
PrinterConfig.InteractDistance = 2.3

--- Distance at which the 3D progress card is drawn. Past this it fades out.
PrinterConfig.RenderDistance = 11.0

--- Distance at which the resource wakes up and starts its per-frame loop.
--- Beyond this the loop sleeps, so a city full of printers costs nothing.
PrinterConfig.ActiveDistance = 30.0

--- RESERVED: ox_target / qb-target integration is not implemented yet.
--- The built-in prompt is always used, whatever this says.
PrinterConfig.TargetSystem = 'none'

-- ═══════════════════════════════════════════════════════════════════════════
--  PRINTING
-- ═══════════════════════════════════════════════════════════════════════════

--- Require the materials listed on each item in config/items.lua.
--- Off: printing is free and the recipes are only shown, never charged.
PrinterConfig.RequireMaterials = true

--- Global time multiplier. 0.5 = half the time, 2.0 = double.
--- Applies on top of every item's own `time`.
PrinterConfig.TimeMultiplier = 1.0

--- Printing runs on the server, so it keeps going while the owner is offline.
--- This value is here for reference; setting it to false changes nothing
--- today.
PrinterConfig.PrintWhileOffline = true

--- How much of the materials come back when a job is cancelled, 0.0 to 1.0.
---
--- A job that has NOT started yet is always refunded in full: nothing was
--- spent on it. This ratio only applies to the one being printed.
PrinterConfig.CancelRefundRatio = 0.5

-- ═══════════════════════════════════════════════════════════════════════════
--  PRINT QUEUE
-- ═══════════════════════════════════════════════════════════════════════════

PrinterConfig.Queue = {
    --- How many jobs fit in one printer's queue, counting the one printing.
    maxJobs      = 8,

    --- How many units can be ordered at once from the item panel.
    --- Each unit takes its own place in the queue.
    maxPerOrder  = 5,

    --- How many finished prints wait on the tray. When it fills up the queue
    --- pauses until someone collects — better than throwing output away.
    maxOutput    = 12,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  SHARED ACCESS
-- ═══════════════════════════════════════════════════════════════════════════

PrinterConfig.Access = {
    --- How many friends an owner may authorise per printer.
    maxFriends      = 8,

    --- How far away a player can be and still appear in the "add friend"
    --- list, in metres. 0 = every player online.
    ---
    --- Keeping this small forces the two players to actually be standing
    --- together, which is the point.
    pickRange       = 12.0,

    --- Let an authorised friend pick the printer up as well.
    friendsCanPickup = false,

    --- Let an authorised friend change the colour theme.
    friendsCanTheme  = false,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  BATTERY AND POWER DRAW
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Printers run on a battery. Every item costs energy (its `power`, in watt
-- hours) and a machine only starts a job it has the charge to finish — so a
-- print never dies halfway through. When the charge is short the queue stops
-- and says so, until someone swaps a battery in.
--
-- Everything in this block is editable in game: /printeradmin → Battery.

PrinterConfig.Battery = {
    enabled = true,

    --- Global drain multiplier.
    ---
    --- Scales EVERY item at once, so you do not have to touch them one by one.
    --- 1.0 is the catalogue as written, 1.25 burns a quarter faster, 0.5 makes
    --- a battery last twice as long. This is the value to tune when batteries
    --- last too long or too little on your server.
    drain = 1.25,

    --- The inventory item consumed when swapping a battery in.
    item = '3dprinter_battery',

    --- How much energy one battery holds, in watt hours.
    capacity = 600,

    --- Charge of a NEWLY PLACED printer, in watt hours.
    ---
    --- Zero: it comes out of the box empty and prints nothing until someone
    --- puts a battery in. That is the sane default — the battery is its own
    --- item, and a printer that spawned full could be recharged for free by
    --- picking it up and dropping it again.
    ---
    --- The trade: charge left in a printer is lost when it is picked up. The
    --- charge lives in the placed machine, not in the inventory item.
    startCharge = 0,

    --- How many recent jobs are kept for the Battery tab's history.
    logSize = 12,

    --- Peak power of the machine, in watts. This is only the denominator on
    --- the gauge ("392/600 W") and enters no calculation — it is the scale
    --- that tells a player whether what is running draws a lot or a little.
    ---
    --- The highest peak in the default catalogue is body armour, at roughly
    --- 512 W while heating. Raise this if you raise the costs.
    maxWatts = 600,

    --- Below this fraction the interface and the world display warn.
    warnBelow = 0.2,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  PROP PHYSICS
-- ═══════════════════════════════════════════════════════════════════════════

PrinterConfig.Physics = {
    --- Blocks players and vehicles, but never moves and never takes damage.
    --- Turn off only if you want the prop to be pushable.
    static      = true,
    --- Let players walk through the prop (useful while testing).
    noCollision = false,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  COLOUR THEMES
-- ═══════════════════════════════════════════════════════════════════════════
--
-- The owner picks a theme in their printer's own Settings tab and the choice
-- is saved to the database. The colour paints the interface, the [E] prompt,
-- the progress card and the light of the printing animation.
--
--   id      key stored in the database
--   label   name shown in the interface
--   accent  main colour (hex)
--   rgb     the same colour as {r, g, b}, used by the in-game lights
--
-- Add your own by appending a line. Keep the ids unique and lowercase.

PrinterConfig.Themes = {
    { id = 'crimson', label = 'Crimson', accent = '#e5352f', rgb = { 229,  53,  47 } },
    { id = 'ember',   label = 'Ember',   accent = '#f97316', rgb = { 249, 115,  22 } },
    { id = 'amber',   label = 'Amber',   accent = '#f5b301', rgb = { 245, 179,   1 } },
    { id = 'lime',    label = 'Lime',    accent = '#84cc16', rgb = { 132, 204,  22 } },
    { id = 'emerald', label = 'Emerald', accent = '#22c55e', rgb = {  34, 197,  94 } },
    { id = 'cyan',    label = 'Cyan',    accent = '#22d3ee', rgb = {  34, 211, 238 } },
    { id = 'azure',   label = 'Azure',   accent = '#3b82f6', rgb = {  59, 130, 246 } },
    { id = 'violet',  label = 'Violet',  accent = '#8b5cf6', rgb = { 139,  92, 246 } },
    { id = 'magenta', label = 'Magenta', accent = '#ec4899', rgb = { 236,  72, 153 } },
    { id = 'mono',    label = 'Mono',    accent = '#e7e9ee', rgb = { 231, 233, 238 } },
}

--- Theme applied to a newly placed printer.
PrinterConfig.DefaultTheme = 'crimson'

-- ═══════════════════════════════════════════════════════════════════════════
--  WORKING EFFECTS
-- ═══════════════════════════════════════════════════════════════════════════
--
-- The body of the printer is a single mesh with no skeleton, so its parts
-- cannot animate on their own. What it gets instead: a light on the bed (the
-- theme colour while printing, green when the piece is done), an extruder head
-- that slides along the rails, electrical sparks, the item itself
-- materialising on the bed, and a looping machine sound.
--
-- All of it is drawn with natives and skipped entirely when the machine is out
-- of view, so it costs nothing when nobody is looking at it.

PrinterConfig.PrintVisual = {
    enabled = true,

    --- Position of the print bed, in metres, relative to the prop's origin.
    --- Measured on the model: 26% of its height, off centre because the spool
    --- holder stretches the bounding box to one side.
    ---
    --- Three things use it: the light comes from here, the sparks jump from
    --- here, and the progress card floats above it — centred on the machine
    --- rather than on the model's origin.
    bedOffset = { x = -0.227, y = -0.292, z = 0.366 },

    -- ───────────────────────────────────────────────────────────── light ──
    --- Glow on the bed. Uses the printer's theme colour while it works and
    --- turns green when the piece is ready.
    light      = true,
    lightRange = 2.2,

    --- The "ready" colour {r, g, b}. Deliberately fixed: "this one is done"
    --- has to read the same on every machine, whatever theme it wears.
    readyColor = { 53, 208, 141 },

    --- The glow of a finished piece nobody has collected yet. It breathes,
    --- carries a wide halo, and the piece floats slowly. This is the only
    --- signal readable from a distance without looking at the card.
    ready = {
        enabled  = true,
        --- Seconds for one full breath.
        period   = 2.0,
        --- Range of the light's core, in metres (minimum and maximum).
        minRange = 0.55,
        maxRange = 1.35,
        --- Range of the wide halo, and how strong it is against the core.
        haloRange = 3.0,
        haloPower = 0.35,
        --- How far the piece bobs up and down, in metres.
        bob      = 0.022,

        --- The flash at the exact moment a piece finishes: duration in ms and
        --- range in metres. It is the one moment the machine speaks, and it
        --- reads apart from the steady glow that follows.
        popTime  = 620,
        popRange = 5.0,
        --- Particle burst at that same moment.
        popBurst = 6,
    },

    --- Blinking when the machine stops for lack of charge. Red, slow and
    --- irregular: it reads as a fault, not as work in progress.
    dead = {
        enabled = true,
        color   = { 235, 70, 60 },
        period  = 1.3,
        range   = 1.8,
    },

    --- If false, the working light uses `color` instead of the theme colour.
    useTheme   = true,
    color      = { 60, 140, 255 },

    -- ──────────────────────────────────────────────────────────── sparks ──
    sparks = {
        enabled = true,

        --- Particle effect. The default pair is the arc from a fuse box —
        --- the closest thing in the game to a short circuit. Alternatives
        --- from the same dictionary: 'ent_dst_elec_fire_sp',
        --- 'ent_ray_prologue_elec_crackle'.
        dict  = 'core',
        name  = 'ent_sht_electrical_box',
        scale = 0.42,

        --- Gap between bursts, in ms. Picked at random between the two so it
        --- never falls into a metronome rhythm.
        minDelay = 900,
        maxDelay = 2800,

        --- Only fires with the player inside this distance, in metres. This is
        --- what keeps the effect cheap: in a city full of printers only the
        --- one in front of the player costs anything.
        distance = 14.0,

        --- Particles per burst (1 up to this number). One reads as a glitch;
        --- a handful reads as an arc.
        burst = 3,

        --- How far the head travels across the bed, in metres. Sparks jump
        --- from wherever it is at that instant, not from a fixed point.
        sweep = 0.09,

        --- A warm point of light following the head — the filament melting.
        head = true,

        --- Short flash where the spark lands: duration in ms, range in
        --- metres. It is what makes the arc read at night.
        flashTime  = 150,
        flashRange = 1.6,

        --- Offset of the sparks from the bed, in metres, and the random
        --- spread around that point.
        offset = { x = 0.0, y = 0.0, z = 0.12 },
        spread = 0.06,
    },

    -- ────────────────────────────────────────────── the piece being made ──
    --- The item appears on the bed, turning slowly, and gains substance as
    --- the print advances. Non-weapon items need a `prop` in items.lua;
    --- weapons need none, they are built from the weapon hash.
    preview = {
        enabled = true,

        --- Fine adjustment against the point the sparks come from.
        ---
        --- A prop's origin is its centre, so at zero half the piece sits
        --- inside the plate. The z lifts it enough to rest on top. Tune it
        --- live with:  /printerpreview <x> <y> <z>
        offset = { x = 0.0, y = 0.0, z = 0.13 },

        --- How far the piece rises from the bed between 0% and 100%, in
        --- metres.
        rise = 0.05,

        --- Degrees per second. Negative spins the other way.
        spin = 42.0,

        --- Fixed tilt of the piece, in degrees. A weapon lying down reads
        --- better than one standing on end.
        pitch = 12.0,
        roll  = 0.0,

        --- Starting transparency, 0 to 255. The game only accepts multiples
        --- of 51 (0, 51, 102, 153, 204, 255), so the piece gains substance in
        --- steps — which at this scale reads as layers appearing.
        ---
        --- 102 is the practical minimum: at zero the piece is invisible for
        --- the first 17% of the job and looks broken, and the engine may
        --- discard a fully transparent entity.
        minAlpha = 102,

        --- Scale for weapons, so they sit on the bed instead of appearing at
        --- full size. Only applies to WEAPON_* items: CreateWeaponObject
        --- takes a scale and CreateObject does not.
        weaponScale = 0.56,

        --- Scale for pieces that are NOT weapons (armour, lockpick).
        ---
        --- GTA has no native to scale a prop, so this is done through the
        --- entity matrix — shrinking its basis vectors shrinks the model. It
        --- works on most builds but is not guaranteed: if a piece does not
        --- change size, set this to 1.0 and pick a smaller model in
        --- config/items.lua instead.
        propScale = 0.56,
    },

    -- ────────────────────────────────────────────────────────────── sound ──
    sound = {
        enabled = true,

        --- OWN FILE, looping from the start of a print to the end.
        ---
        --- Path relative to web/dist. The file lives in web/public/sounds/
        --- and the build copies it into dist — it must be listed in the
        --- fxmanifest's files{} block, or the interface gets a 404 and stays
        --- silent.
        ---
        --- It plays through the interface, not the game's audio engine, so it
        --- is NOT positional: it does not turn with the camera. The volume
        --- follows the distance instead, which at this scale sounds the same.
        --- Set to nil to fall back to the native sound below.
        file   = 'sounds/printersound.ogg',

        --- Maximum volume, 0.0 to 1.0. This is the volume standing next to
        --- the machine; it falls off with distance from there.
        volume = 0.30,

        --- Native game sound, used only when `file` is nil. Try pairs in game
        --- with /printersound <soundSet> <name> before putting them here.
        soundSet = 'DLC_HEIST_FLEECA_SOUNDSET',
        name     = 'Drill_Loop',

        --- Range of the sound, in metres. Full volume up to 35% of this,
        --- falling to nothing at the edge.
        distance = 12.0,

        --- A short crack alongside each spark.
        ---
        --- Off by default because a wrong sound name raises no error: it just
        --- stays silent, and there is no way to tell a bad name from a bug.
        --- Find a pair with /printersound, put it here and switch it on.
        --- One to try: DLC_HEIST_FLEECA_SOUNDSET / Drill_Pin_Break
        spark = {
            enabled  = false,
            soundSet = nil,
            name     = nil,
            distance = 8.0,
        },
    },

    --- How high above the base of the prop the 3D progress card floats.
    --- The prop is 1.40 m tall; 1.75 leaves the card just above it.
    barHeight = 1.75,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  MOVING EXTRUDER HEAD
-- ═══════════════════════════════════════════════════════════════════════════
--
-- The model carries no skeleton and no animation, so the only way to move the
-- head is for it to be its own entity. The model ships split into two props
-- and the head slides along the rails while a job runs.

PrinterConfig.Head = {
    enabled = true,
    model   = 'prop_3dprinter_head',

    --- Resting position of the head, in metres, relative to the prop origin.
    offset  = { x = 0.128, y = 0.206, z = 0.733 },

    --- Travel in X to each side, in metres. X only: the rails run that way
    --- and belong to the body, so moving in Y would take the head off them.
    ---
    --- The black tube and the blue filament are part of the head prop so they
    --- stay attached to it. In exchange, their fixed ends (the base of the
    --- tube, the entry into the spool) move the same amount — which is why
    --- the travel is about three quarters of the space available. Raise it to
    --- 0.206 for the full sweep if you do not mind those ends swaying.
    travel  = 0.148,

    --- Seconds for one full pass there and back. Lower is faster; under
    --- about 1.2 it starts to look nervous.
    period  = 1.8,

    --- How quickly it returns to the centre when a print ends.
    returnSpeed = 6.0,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  ITEM IMAGES
-- ═══════════════════════════════════════════════════════════════════════════

--- Base path for item images. Change it to match your inventory.
---   ox_inventory     -> 'nui://ox_inventory/web/images/'
---   qb-inventory     -> 'nui://qb-inventory/html/images/'
---   ps-inventory     -> 'nui://ps-inventory/html/images/'
---   qs-inventory     -> 'nui://qs-inventory/html/images/'
---   codem-inventory  -> 'nui://codem-inventory/html/itemimages/'
---   origen_inventory -> 'nui://origen_inventory/html/images/'
---   tgiann-inventory -> 'nui://tgiann-inventory/html/itemimages/'
PrinterConfig.ImagePath = 'nui://ox_inventory/web/images/'

--- Extension of those image files.
PrinterConfig.ImageExtension = '.png'

--- Readable names for materials that are not printable themselves.
---
--- The interface only knows the items in config/items.lua. Raw materials that
--- come from elsewhere (ore, fabric, fuel) have no label there and would show
--- the bare inventory key in the "Required items" list. Add yours here;
--- anything missing keeps showing its key.
---
--- You can also add and edit these in game: /printeradmin → Materials.
---
--- An item with no image in your inventory's image folder falls back to a
--- drawn cube rather than a broken icon.
PrinterConfig.MaterialLabels = {
    ['petrol']     = 'Petrol',
    ['metais']     = 'Metal',
    ['iron']       = 'Iron',
    ['ferros']     = 'Iron',
    ['scrapmetal'] = 'Scrap Metal',
    ['tecido']     = 'Fabric',
    ['tubos']      = 'Pipe',
    ['copper']     = 'Copper',
    ['adamantite_ore'] = 'Adamantite Ore',
    ['aluminum'] = 'Aluminum',
    ['amethyst'] = 'Amethyst',
    ['arcane_crystal'] = 'Arcane Crystal',
    ['arcane_dust'] = 'Arcane Dust',
    ['carbon_fiber'] = 'Carbon Fiber',
    ['cloth'] = 'Cloth',
    ['cobalt_ore'] = 'Cobalt Ore',
    ['dark_glass'] = 'Dark Glass',
    ['diamond'] = 'Diamond',
    ['electronics'] = 'Electronics',
    ['emerald'] = 'Emerald',
    ['emp_grenade'] = 'Emp Grenade',
    ['fishing_line'] = 'Fishing Line',
    ['fishing_rod'] = 'Fishing Rod',
    ['gold_band'] = 'Gold Band',
    ['hacking_device'] = 'Hacking Device',
    ['infernal_dust'] = 'Infernal Dust',
    ['leather'] = 'Leather',
    ['master_lockpick'] = 'Master Lockpick',
    ['master_weapon_parts'] = 'Master Weapon Parts',
    ['mithril_ore'] = 'Mithril Ore',
    ['onyx'] = 'Onyx',
    ['plastic'] = 'Plastic',
    ['refined_gem'] = 'Refined Gem',
    ['refined_mithril'] = 'Refined Mithril',
    ['reinforced_handle'] = 'Reinforced Handle',
    ['rubber'] = 'Rubber',
    ['ruby'] = 'Ruby',
    ['rune_core'] = 'Rune Core',
    ['runite_ore'] = 'Runite Ore',
    ['sapphire'] = 'Sapphire',
    ['shadow_silk'] = 'Shadow Silk',
    ['steel'] = 'Steel',
    ['steel_pickaxe'] = 'Steel Pickaxe',
    ['titanium_alloy'] = 'Titanium Alloy',
    ['tool_parts'] = 'Tool Parts',
}

-- ═══════════════════════════════════════════════════════════════════════════
--  ADMINISTRATION
-- ═══════════════════════════════════════════════════════════════════════════

--- Groups allowed to use the admin commands and the console.
---
--- Checked three ways, any one of which is enough:
---   • the server console (always allowed)
---   • the ACE permission  rwprinter.<group>
---   • your framework's own group system
---
--- To grant it with ACE, put this in server.cfg:
---   add_ace group.admin rwprinter.admin allow
PrinterConfig.AdminGroups = { 'admin', 'superadmin', 'god', 'owner' }

--- Command names. Change them if they clash with another resource.
PrinterConfig.Commands = {
    givePrinter = 'giveprinter',   -- /giveprinter [id] [amount]
    removeAll   = 'clearprinters', -- /clearprinters
    reloadCfg   = 'reloadprinters',
    editor      = 'printeradmin',  -- /printeradmin: the admin console
}

-- ═══════════════════════════════════════════════════════════════════════════
--  EDITABLE CATALOGUE
-- ═══════════════════════════════════════════════════════════════════════════
--
-- /printeradmin (admins only) opens a console with every printer on the map
-- and the catalogue of printable items. What you edit there is stored in
-- tables created automatically on first start and seeded from
-- config/items.lua.
--
-- From that point on the database is the source of truth: editing
-- config/items.lua has no effect in game until you press "Restore defaults"
-- in the console — which also throws away the in-game edits.
--
-- With PrinterConfig.Persistence off the console still works, but what you edit
-- lasts only until the next restart.

-- ═══════════════════════════════════════════════════════════════════════════
--  INTERFACE
-- ═══════════════════════════════════════════════════════════════════════════

PrinterConfig.UI = {
    --- Animation duration, in ms. Keep it low so nothing feels sluggish.
    animSpeed    = 200,

    --- Use the built-in toast instead of the framework's notifications.
    --- PrinterConfig.Notify above is the finer control; this stays for backwards
    --- compatibility.
    useOwnNotify = true,

    --- How long a notification stays on screen, in ms.
    notifyTime   = 4000,

    --- Where the [E] prompt sits:
    --- 'bottom-center' | 'right-center' | 'top-center'
    textUIPos    = 'bottom-center',

    --- Colour of the admin console. Deliberately different from the printer
    --- themes, so it is obvious at a glance that you are in the console and
    --- not in a machine.
    ---
    --- Each admin can also pick their own colour and density inside the
    --- console; that choice is saved on their own client.
    editorAccent = '#f0a12b',

    --- Hide everything this resource draws while the pause menu (ESC), the
    --- map or the settings are open.
    ---
    --- That menu is drawn by the game; the progress card, the [E] prompt and
    --- the panels are HTML on top of everything the game draws. Without this
    --- they sit over the map.
    hideOnPause = true,

    --- Size of the 3D progress card at the reference distance below. Outside
    --- it the card scales by the inverse of the distance, so it keeps the
    --- same size relative to the machine — as if it were attached to it.
    cardScale    = 0.72,

    --- Distance, in metres, at which the card is exactly cardScale.
    --- Closer it grows (up to 1.35x), further it shrinks (down to 0.28x).
    cardRefDistance = 3.5,

    --- How far below the card the battery display sits, in pixels INSIDE the
    --- already-scaled space — so the spacing follows perspective anyway.
    ---
    --- Both are centred on the same anchor, so the value is
    ---   half the card (191/2) + gap (14) + half the pill (40/2).
    --- Redo the arithmetic if you change the card's height.
    batteryDrop  = 130,

    --- Metres before PrinterConfig.RenderDistance where the card starts to fade, so
    --- it does not vanish all at once.
    cardFade     = 2.5,

    --- Where the progress card sits: 'world' follows the machine in 3D,
    --- 'bottom' pins it to the bottom of the screen like a HUD.
    progressMode = 'world',

    --- The card and the battery display are HTML on top of the game: they
    --- have no depth of their own. Without this they paint over whatever is
    --- in front of them — the player, a car, a wall — and the hologram starts
    --- to look like a sticker on the screen.
    occlusion     = true,

    --- What counts as an obstacle for the card. Sum of:
    ---   1 map (walls, floors)   2 vehicles   4 people   8 ragdolls
    --- 16 (objects) is left out on purpose: the printer is itself an object
    --- and would always hide its own card.
    occlusionMask = 15,

    --- Fade speed, per second. Too high and the card blinks every time the
    --- player's shoulder crosses in front of it.
    ---
    --- 6.0 gives 167 ms. The stylesheet already adds a 220 ms opacity
    --- transition on top (.pcard / .pcell), so what you see is a little
    --- slower than the arithmetic — the two add up. Raise this value before
    --- touching the CSS if you want a sharper cut.
    occlusionFade = 6.0,

    --- Hide the [E] prompt and lock the key when there is a wall in between.
    --- This test only looks at map geometry, so the player's own body never
    --- swallows the prompt.
    promptOcclusion = true,
}

