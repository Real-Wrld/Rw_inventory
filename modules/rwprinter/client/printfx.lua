PrintFX = {}

local cfg = nil   -- PrinterConfig.PrintVisual

CreateThread(function()
    Wait(100)
    cfg = PrinterConfig.PrintVisual
end)

-- Per-printer FX state: [printerId] = {
--   nextSpark, flashUntil, fx, fy, fz,          -- spark scheduling / flash position
--   obj, key, alpha, checkedAt, seen,            -- preview prop
--   wasReady, popUntil                           -- ready-pop animation
-- }
local fxStates = {}

local DEFAULT_SPARK_OFFSET = { x = 0.0, y = 0.0, z = 0.12 }

local releasePreview  -- forward declaration

local function getFx(id)
    local st = fxStates[id]
    if not st then
        st = { nextSpark = 0, flashUntil = 0, fx = 0.0, fy = 0.0, fz = 0.0 }
        fxStates[id] = st
    end
    return st
end

function PrintFX.Forget(id)
    local st = fxStates[id]
    if st and releasePreview then
        releasePreview(st)
    end
    fxStates[id] = nil
end

-- ─────────────────────────────────────────────
-- Math helpers
-- ─────────────────────────────────────────────

local rotCache = {}  -- [heading] = { cos, sin }

local function getRot(heading)
    heading = heading or 0.0

    local rot = rotCache[heading]
    if not rot then
        local rad = math.rad(heading)
        rot = { math.cos(rad), math.sin(rad) }
        rotCache[heading] = rot
    end

    return rot[1], rot[2]
end

local function rotate(heading, x, y)
    local c, s = getRot(heading)
    return x * c - y * s,
           x * s + y * c
end

local pitchCached, pitchCos, pitchSin = nil, 1.0, 0.0

local function getPitch(pitch)
    if pitch ~= pitchCached then
        local rad = math.rad(pitch)
        pitchCos = math.cos(rad)
        pitchSin = math.sin(rad)
        pitchCached = pitch
    end
    return pitchCos, pitchSin
end

-- ─────────────────────────────────────────────
-- World positions
-- ─────────────────────────────────────────────

-- World position of the print bed
function PrintFX.BedWorld(coords, heading)
    if not cfg then
        return coords.x, coords.y, coords.z
    end

    local rx, ry = rotate(heading, cfg.bedOffset.x, cfg.bedOffset.y)
    return coords.x + rx,
           coords.y + ry,
           coords.z + cfg.bedOffset.z
end

-- World position of the spark origin (bed + spark offset)
local function sparkOrigin(printer)
    local sparks = cfg.sparks
    local off = (sparks and sparks.offset) or DEFAULT_SPARK_OFFSET

    local rx, ry = rotate(printer.heading, cfg.bedOffset.x, cfg.bedOffset.y)
    return printer.coords.x + rx + off.x,
           printer.coords.y + ry + off.y,
           printer.coords.z + cfg.bedOffset.z + off.z
end

-- Wandering print-head position used for sparks / light
local function sparkHeadPos(printer, now, ox, oy, oz)
    local sparks = cfg.sparks
    local sweep = (sparks and sparks.sweep) or 0.09
    local t = (now or GetGameTimer()) / 1000.0

    if not ox then
        ox, oy, oz = sparkOrigin(printer)
    end

    local dx, dy = rotate(printer.heading, math.sin(t * 1.7) * sweep, math.cos(t * 1.1) * sweep)
    return ox + dx, oy + dy, oz
end

-- ─────────────────────────────────────────────
-- Particle asset loading
-- ─────────────────────────────────────────────

local ptfxLoaded = false
local ptfxLoading = false

local function ensurePtfx(dict)
    if ptfxLoaded then return true end
    if ptfxLoading then return false end

    ptfxLoading = true
    CreateThread(function()
        RequestNamedPtfxAsset(dict)
        local deadline = GetGameTimer() + 10000
        while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < deadline do
            Wait(50)
        end

        ptfxLoaded = HasNamedPtfxAssetLoaded(dict)
        ptfxLoading = false

        if not ptfxLoaded then
            print(('^3[rwprinter] Nao consegui carregar o ptfx "%s".^0'):format(dict))
        end
    end)

    return false
end

-- ─────────────────────────────────────────────
-- Preview prop / weapon asset management
-- ─────────────────────────────────────────────

local assetState = {}   -- [key] = "wait" | "ok" | "bad"
local refCount = {}     -- [key] = number of live preview objects using it
local releasedAt = {}   -- [key] = timer when refCount hit 0
local weaponCache = {}  -- [name] = bool

local function isWeapon(name)
    if type(name) ~= "string" then return false end

    local cached = weaponCache[name]
    if cached == nil then
        cached = name:upper():sub(1, 7) == "WEAPON_"
        weaponCache[name] = cached
    end
    return cached
end

-- Asset key: weapon name for weapons, otherwise the prop model name
local function resolveKey(name, prop)
    return (isWeapon(name) and name) or prop
end

-- Starts async loading of the asset; returns true only once it's ready
local function requestAsset(name, prop)
    local key = resolveKey(name, prop)
    if not key then return false end

    local current = assetState[key]
    if current == "ok" then return true end
    if current then return false end

    assetState[key] = "wait"

    CreateThread(function()
        local ok = false

        if isWeapon(name) then
            local hash = joaat(name)
            RequestWeaponAsset(hash, 31, 0)
            local deadline = GetGameTimer() + 10000
            while not HasWeaponAssetLoaded(hash) and GetGameTimer() < deadline do
                Wait(50)
            end
            ok = HasWeaponAssetLoaded(hash)
        else
            local hash = joaat(prop)
            if IsModelInCdimage(hash) and IsModelValid(hash) then
                RequestModel(hash)
                local deadline = GetGameTimer() + 10000
                while not HasModelLoaded(hash) and GetGameTimer() < deadline do
                    Wait(50)
                end
                ok = HasModelLoaded(hash)
            end
        end

        assetState[key] = ok and "ok" or "bad"

        if not ok then
            print(('^3[rwprinter] Nao consegui preparar a peca "%s".^0'):format(key))
        end
    end)

    return false
end

local function createPreviewObject(name, prop, x, y, z)
    local preview = cfg.preview
    local obj = nil

    if isWeapon(name) then
        obj = CreateWeaponObject(joaat(name), 0, x, y, z, true, (preview and preview.weaponScale) or 1.0, 0)
    elseif prop then
        obj = CreateObject(joaat(prop), x, y, z, false, false, false)
    end

    if obj and obj ~= 0 and DoesEntityExist(obj) then
        return obj
    end
    return nil
end

releasePreview = function(st)
    if st.obj and DoesEntityExist(st.obj) then
        DeleteEntity(st.obj)
    end

    if st.obj and st.key then
        local count = (refCount[st.key] or 1) - 1
        if count > 0 then
            refCount[st.key] = count
        else
            refCount[st.key] = nil
            releasedAt[st.key] = GetGameTimer()
        end
    end

    st.checkedAt = nil
    st.alpha = -1
    st.key = nil
    st.obj = nil
end

function PrintFX.Clear(id)
    local st = fxStates[id]
    if st then releasePreview(st) end
end

-- Debug string for /printerdebug
function PrintFX.Debug(id)
    local preview = cfg and cfg.preview
    if not (preview and preview.enabled) then
        return "desligada em PrinterConfig.PrintVisual.preview"
    end

    local st = fxStates[id]
    if not st then
        return "a impressora ainda nao foi desenhada"
    end

    if not st.key then
        return "este item nao tem peca (nem prop, nem arma)"
    end

    local status = assetState[st.key]

    if not (st.obj and DoesEntityExist(st.obj)) then
        local label = (status == "ok" and "pronto") or (status == "bad" and "FALHOU") or "a preparar"
        return ("%s -- %s, objecto por criar"):format(st.key, label)
    end

    return ("%s -- objecto %s, alpha %d/255"):format(st.key, st.obj, st.alpha or -1)
end

-- Item currently being printed (or sitting in the output tray)
local function getItemName(printer)
    local job = printer.queue and printer.queue[1]
    if job then return job.item end

    local out = printer.output and printer.output[1]
    return out and out.item or nil
end

-- Draws / updates the floating preview of the item on the bed
local function drawPreview(printer, st, isReady, progress, x, y, z, now)
    local preview = cfg.preview
    if not (preview and preview.enabled) then return end

    now = now or GetGameTimer()
    st.seen = now

    local itemName = getItemName(printer)
    local itemCfg = itemName and PrinterConfig.Items[itemName]
    local prop = itemCfg and itemCfg.prop
    local key = resolveKey(itemName, prop)

    if not key then
        releasePreview(st)
        return
    end

    if st.key ~= key then
        releasePreview(st)
        st.key = key
    end

    local p = math.min(math.max(progress or 0.0, 0.0), 1.0)

    local off = preview.offset or { x = 0.0, y = 0.0, z = 0.0 }
    local px = x + off.x
    local py = y + off.y
    local pz = z + off.z + (preview.rise or 0.0) * p

    -- Gentle bob when finished
    if isReady then
        local ready = cfg.ready
        if ready and ready.enabled and (ready.bob or 0) > 0 then
            local t = (now / 1000.0) * ((2 * math.pi) / (ready.period or 2.0))
            pz = pz + math.sin(t) * ready.bob
        end
    end

    -- Entity validity check every 500ms
    local exists = st.obj ~= nil
    if exists and now > (st.checkedAt or 0) + 500 then
        st.checkedAt = now
        exists = DoesEntityExist(st.obj)
    end

    if not exists then
        if assetState[key] == "bad" then return end
        if not requestAsset(itemName, prop) then return end

        st.obj = createPreviewObject(itemName, prop, px, py, pz)
        if not st.obj then
            assetState[key] = "bad"
            print(('^3[rwprinter] O jogo recusou criar a peca "%s".^0'):format(key))
            return
        end

        refCount[key] = (refCount[key] or 0) + 1
        releasedAt[key] = nil

        SetEntityCollision(st.obj, false, false)
        SetEntityHasGravity(st.obj, false)
        SetEntityInvincible(st.obj, true)
        SetEntityCanBeDamaged(st.obj, false)
        FreezeEntityPosition(st.obj, true)
        SetEntityAsMissionEntity(st.obj, true, true)

        st.alpha = -1
        st.checkedAt = now
    end

    -- Spin
    local spin = ((now / 1000.0) * (preview.spin or 42.0)) % 360.0
    local scale = (isWeapon(itemName) and 1.0) or (preview.propScale or 1.0)

    if scale ~= 1.0 then
        -- Scaled: set the full matrix (yaw spin + pitch + uniform scale)
        local rad = math.rad(spin)
        local c, s = math.cos(rad), math.sin(rad)
        local pc, ps = getPitch(preview.pitch or 0.0)

        SetEntityMatrix(st.obj,
            -s * pc * scale, c * pc * scale, ps * scale,
            c * scale, s * scale, 0.0,
            s * ps * scale, -c * ps * scale, pc * scale,
            px, py, pz)
    else
        SetEntityCoordsNoOffset(st.obj, px, py, pz, false, false, false)
        SetEntityRotation(st.obj, preview.pitch or 0.0, preview.roll or 0.0, spin, 2, false)
    end

    -- Alpha: fades in (stepped in 51s) as the print progresses, full when ready
    local alpha
    if isReady then
        alpha = 255
    else
        local minStep = math.max(1, math.floor((preview.minAlpha or 102) / 51))
        alpha = math.min(5, minStep + math.floor(p * (5 - minStep) + 0.5)) * 51
    end

    if alpha ~= st.alpha then
        SetEntityAlpha(st.obj, alpha, false)
        st.alpha = alpha
    end
end

-- Janitor: drop previews that haven't been drawn lately, unload unused assets
CreateThread(function()
    while true do
        Wait(1500)
        local now = GetGameTimer()

        for _, st in pairs(fxStates) do
            if st.obj and (now - (st.seen or 0)) > 2500 then
                releasePreview(st)
            end
        end

        for key, t in pairs(releasedAt) do
            if now - t > 30000 then
                releasedAt[key] = nil

                if assetState[key] == "ok" then
                    assetState[key] = nil

                    if isWeapon(key) then
                        RemoveWeaponAsset(joaat(key))
                    else
                        SetModelAsNoLongerNeeded(joaat(key))
                    end
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────
-- Sound
-- ─────────────────────────────────────────────

local gameSoundId = nil         -- in-game sound handle
local soundPrinterId = nil      -- printer currently emitting sound
local nuiVolume = -1            -- current NUI audio volume (-1 = not playing)
local lastVolumeSendAt = 0

local function volumeForDistance(dist, soundCfg)
    local range = soundCfg.distance or 12.0
    local inner = range * 0.35
    local base = soundCfg.volume or 0.6

    if dist <= inner then return base end
    if dist >= range then return 0.0 end

    local t = 1.0 - (dist - inner) / (range - inner)
    return base * t * t
end

local function stopNuiAudio()
    if nuiVolume < 0 then return end
    nuiVolume = -1
    SendNUIMessage({ action = "audio", play = false })
end

local function stopGameSound()
    if not gameSoundId then return end
    StopSound(gameSoundId)
    ReleaseSoundId(gameSoundId)
    gameSoundId = nil
end

local function stopAllSounds()
    stopGameSound()
    stopNuiAudio()
    soundPrinterId = nil
end

-- id = printer to play sound for (nil to stop), dist = distance to it, x/y/z = sound position
function PrintFX.Sound(id, dist, x, y, z, now)
    local soundCfg = cfg and cfg.sound
    if not (soundCfg and soundCfg.enabled) then
        id = nil
    end

    -- Mode 1: custom audio file played through the NUI
    if soundCfg and soundCfg.file then
        stopGameSound()

        if not id then
            soundPrinterId = nil
            stopNuiAudio()
            return
        end

        local volume = math.floor(volumeForDistance(dist or 0.0, soundCfg) * 100 + 0.5) / 100

        if soundPrinterId ~= id or nuiVolume < 0 then
            soundPrinterId = id
            nuiVolume = volume
            lastVolumeSendAt = now or GetGameTimer()
            SendNUIMessage({ action = "audio", play = true, src = soundCfg.file, volume = volume })
            return
        end

        now = now or GetGameTimer()
        if math.abs(volume - nuiVolume) >= 0.03 and now - lastVolumeSendAt >= 120 then
            nuiVolume = volume
            lastVolumeSendAt = now
            SendNUIMessage({ action = "audio", volume = volume })
        end
        return
    end

    -- Mode 2: native in-game sound at a world position
    stopNuiAudio()

    if soundPrinterId == id then return end

    stopGameSound()
    soundPrinterId = id
    if not id then return end

    gameSoundId = GetSoundId()
    PlaySoundFromCoord(gameSoundId, soundCfg.name, x, y, z, soundCfg.soundSet, false, soundCfg.distance or 12, false)
end

-- One-shot spark crackle
local function playSparkSound(x, y, z)
    local soundCfg = cfg and cfg.sound
    local spark = soundCfg and soundCfg.spark
    if not (spark and spark.enabled) then return end
    if not (spark.soundSet and spark.name) then return end

    local sid = GetSoundId()
    PlaySoundFromCoord(sid, spark.name, x, y, z, spark.soundSet, false, spark.distance or 8, false)

    CreateThread(function()
        Wait(1200)
        StopSound(sid)
        ReleaseSoundId(sid)
    end)
end

-- ─────────────────────────────────────────────
-- Main draw (lights, sparks, ready pop, preview)
-- ─────────────────────────────────────────────

function PrintFX.Draw(printer, state, progress, themeRgb, dist, now, bedX, bedY, bedZ)
    local blocked = printer.blocked == "battery"

    if not (cfg and cfg.enabled) then return end
    if state ~= "printing" and state ~= "ready" then return end

    if not bedX then
        bedX, bedY, bedZ = PrintFX.BedWorld(printer.coords, printer.heading)
    end
    now = now or GetGameTimer()

    local isReady = state == "ready"
    local fx = getFx(printer.id)

    if not IsSphereVisible(bedX, bedY, bedZ + 0.4, 2.6) then
        fx.seen = now
        return
    end

    -- Spark origin (bed + offset)
    local sparks = cfg.sparks
    local off = (sparks and sparks.offset) or DEFAULT_SPARK_OFFSET
    local ox = bedX + off.x
    local oy = bedY + off.y
    local oz = bedZ + off.z

    drawPreview(printer, fx, isReady, progress, ox, oy, oz, now)

    -- Ready "pop" burst, fired once on transition to ready
    if isReady then
        if fx.wasReady ~= true then
            fx.wasReady = true

            local ready = cfg.ready
            if ready and ready.enabled then
                fx.popUntil = now + (ready.popTime or 620)

                if sparks and sparks.enabled and ensurePtfx(sparks.dict) then
                    local burst = math.max(1, math.floor(ready.popBurst or 6))
                    for _ = 1, burst do
                        local spread = (sparks.spread or 0.06) * 2.0

                        UseParticleFxAssetNextCall(sparks.dict)
                        StartParticleFxNonLoopedAtCoord(
                            sparks.name,
                            bedX + (math.random() - 0.5) * spread,
                            bedY + (math.random() - 0.5) * spread,
                            bedZ + 0.12 + math.random() * spread,
                            0.0, 0.0, 0.0,
                            (sparks.scale or 0.4) * 0.8,
                            false, false, false
                        )
                    end
                end
            end
        end
    else
        fx.wasReady = false
    end

    -- Blocked (battery dead): red pulsing light, nothing else
    if blocked and not isReady then
        local dead = cfg.dead
        if dead and dead.enabled then
            local t = (now / 1000.0) * ((2 * math.pi) / (dead.period or 1.3))
            local pulse = math.max(0.0, math.sin(t)) * (0.6 + 0.4 * math.abs(math.sin(t * 3.7)))

            DrawLightWithRange(
                bedX, bedY, bedZ + 0.18,
                dead.color[1], dead.color[2], dead.color[3],
                dead.range or 1.8,
                0.3 + 1.4 * pulse
            )
        end
        return
    end

    -- Bed light
    if cfg.light then
        local color = (isReady and cfg.readyColor) or (cfg.useTheme and themeRgb) or cfg.color
        local intensity

        if isReady then
            local ready = cfg.ready
            if ready and ready.enabled then
                local t = (now / 1000.0) * ((2 * math.pi) / (ready.period or 2.0))
                local pulse = 0.5 + 0.5 * math.sin(t)

                local minRange = ready.minRange or 0.55
                local maxRange = ready.maxRange or 1.35
                local range = minRange + (maxRange - minRange) * pulse

                DrawLightWithRange(bedX, bedY, bedZ + 0.18, color[1], color[2], color[3], range, 1.1 + 0.5 * pulse)

                DrawLightWithRange(
                    bedX, bedY, bedZ + 0.18,
                    color[1], color[2], color[3],
                    ready.haloRange or 3.0,
                    (ready.haloPower or 0.35) * (1.0 - pulse * 0.5)
                )

                -- Expanding white flash right after finishing
                if fx.popUntil and now < fx.popUntil then
                    local k = (fx.popUntil - now) / math.max(1, ready.popTime or 620)
                    DrawLightWithRange(
                        bedX, bedY, bedZ + 0.18,
                        255, 255, 245,
                        (ready.popRange or 5.0) * k,
                        3.0 * k * k
                    )
                end

                return
            end

            intensity = 0.85 + 0.25 * math.sin(now / 900.0)
        else
            local p = math.min(math.max(progress or 0.0, 0.0), 1.0)
            intensity = (0.55 + 0.45 * p) * (0.82 + 0.3 * math.abs(math.sin(now / 550.0)))
        end

        DrawLightWithRange(bedX, bedY, bedZ + 0.18, color[1], color[2], color[3], cfg.lightRange, intensity)
    end

    if isReady then return end

    -- Welding-style sparks while printing
    if not (sparks and sparks.enabled) then return end
    if dist > (sparks.distance or 14.0) then return end

    local hx, hy, hz = sparkHeadPos(printer, now, ox, oy, oz)

    if sparks.head then
        DrawLightWithRange(hx, hy, hz, 255, 170, 90, 0.5, 0.75 + 0.25 * math.sin(now / 120.0))
    end

    -- Flash at the last spark position
    if now < fx.flashUntil then
        local k = (fx.flashUntil - now) / math.max(1, sparks.flashTime or 150)
        DrawLightWithRange(fx.fx, fx.fy, fx.fz, 255, 225, 190, (sparks.flashRange or 1.6) * k, 2.2 * k)
    end

    if now < fx.nextSpark then return end

    local minDelay = math.floor(sparks.minDelay or 900)
    local maxDelay = math.floor(sparks.maxDelay or 2800)
    fx.nextSpark = now + math.random(minDelay, math.max(minDelay, maxDelay))

    if not ensurePtfx(sparks.dict) then return end

    local spread = sparks.spread or 0.06
    local count = math.random(1, math.max(1, math.floor(sparks.burst or 3)))

    for _ = 1, count do
        local dx = (math.random() - 0.5) * 2.0 * spread
        local dy = (math.random() - 0.5) * 2.0 * spread
        local dz = math.random() * spread

        UseParticleFxAssetNextCall(sparks.dict)
        StartParticleFxNonLoopedAtCoord(
            sparks.name,
            hx + dx, hy + dy, hz + dz,
            0.0, 0.0, 0.0,
            (sparks.scale or 0.4) * (0.75 + math.random() * 0.5),
            false, false, false
        )
    end

    fx.flashUntil = now + (sparks.flashTime or 150)
    fx.fx, fx.fy, fx.fz = hx, hy, hz

    playSparkSound(hx, hy, hz)
end

-- ─────────────────────────────────────────────
-- Cleanup
-- ─────────────────────────────────────────────

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    stopAllSounds()

    for _, st in pairs(fxStates) do
        if st.obj and DoesEntityExist(st.obj) then
            DeleteEntity(st.obj)
        end
    end
end)

-- ─────────────────────────────────────────────
-- Dev commands
-- ─────────────────────────────────────────────

-- /printerpreview [x y z]  -> tweak preview offset live and print the config line
RegisterCommand("printerpreview", function(_, args)
    local preview = cfg and cfg.preview
    if not preview then return end

    local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    if x and y and z then
        preview.offset = { x = x, y = y, z = z }
    end

    local o = preview.offset
    print(("^2[rwprinter] preview.offset = { x = %.3f, y = %.3f, z = %.3f }^0"):format(o.x, o.y, o.z))
end, false)

-- /printersound <soundSet> <name>  -> test a native sound for 4s
RegisterCommand("printersound", function(_, args)
    local soundSet, name = args[1], args[2]

    if not soundSet or not name then
        print("^3[rwprinter] uso: /printersound <soundSet> <nome>^0")
        print("^3  ex: /printersound DLC_HEIST_FLEECA_SOUNDSET Drill_Loop^0")
        return
    end

    local coords = GetEntityCoords(PlayerPedId())
    local sid = GetSoundId()
    PlaySoundFromCoord(sid, name, coords.x, coords.y, coords.z, soundSet, false, 12, false)

    print(("^2[rwprinter] a tocar %s / %s durante 4 s^0"):format(soundSet, name))

    CreateThread(function()
        Wait(4000)
        StopSound(sid)
        ReleaseSoundId(sid)
    end)
end, false)