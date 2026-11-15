-- funcs.lua  –  Shared utilities for bablo-throwitems
-- Runs on both client and server.

-- ─── Logging ──────────────────────────────────────────────────────────────────

function Trace(...)
    if not Config.Debug then return end

    local prefix = ""
    if IsDuplicityVersion() then
        prefix = os.date('%Y-%m-%d %H:%M:%S', os.time())
    end

    local parts = { ... }
    local line  = prefix .. " [" .. (GetCurrentResourceName() or "LOG") .. "] "
    for i = 1, #parts do
        line = line .. tostring(parts[i]) .. " "
    end

    print(line)
end

-- ─── Localisation ─────────────────────────────────────────────────────────────

function Translate(key, args)
    if not Config.Locale then return key end

    local translation = Locales[Config.Locale] and Locales[Config.Locale][key]
    if not translation then return key end

    if args then
        local i = 1
        translation = translation:gsub("%%s", function()
            local arg = args[i]
            i = i + 1
            return tostring(arg)
        end)
    end

    return translation
end

-- ─── Resource state helper ────────────────────────────────────────────────────

function IsResourceStartedOrStarting(resourceName)
    local state = GetResourceState(resourceName)
    return state == "started" or state == "starting"
end

-- ─── Main.usableItems ────────────────────────────────────────────────────────
-- Inventory files iterate Main.usableItems in Inventory:Init() to register
-- each item as usable. On use the server fires a client event, and the
-- listener below calls the throwItem export directly.

Main = Main or {}
Main.usableItems = {}

for itemName, _ in pairs(Config.ThrowProps) do
    table.insert(Main.usableItems, {
        name = itemName,
        use  = function(src, name)
            TriggerClientEvent("bablo-throwitems:client:useItem", src, name)
        end,
    })
end

-- ─── Client: receive use event and start throw mode ──────────────────────────

if not IsDuplicityVersion() then
    RegisterNetEvent("bablo-throwitems:client:useItem")
    AddEventHandler("bablo-throwitems:client:useItem", function(itemName)
        exports["bablo-throwitems"]:throwItem({ name = itemName })
    end)
end

-- ─── Framework auto-detection ─────────────────────────────────────────────────

if Config.Framework == "auto" then
    Trace("Detecting framework")

    if IsResourceStartedOrStarting("es_extended") then
        Config.Framework = "esx"
    elseif IsResourceStartedOrStarting("qbx_core") then
        Config.Framework = "qbox"
    elseif IsResourceStartedOrStarting("qb-core") then
        Config.Framework = "qbcore"
    else
        Config.Framework = "standalone"
    end

    Trace("Detected framework: " .. Config.Framework)
end

-- ─── Inventory auto-detection ─────────────────────────────────────────────────

if Config.Inventory == "auto" then
    Trace("Detecting inventory")

    local inventoryPriority = {
        { resource = "tgiann-inventory", name = "tgiann-inventory" },
        { resource = "qb-inventory",     name = "qb-inventory"     },
        { resource = "qs-inventory",     name = "qs-inventory"     },
        { resource = "ps-inventory",     name = "ps-inventory"     },
        { resource = "ox_inventory",     name = "ox_inventory"     },
        { resource = "origen_inventory", name = "origen_inventory" },
        { resource = "core_inventory",   name = "core_inventory"   },
        { resource = "codem-inventory",  name = "codem-inventory"  },
    }

    for _, entry in ipairs(inventoryPriority) do
        if IsResourceStartedOrStarting(entry.resource) then
            Config.Inventory = entry.name
            break
        end
    end

    Trace("Detected inventory: " .. tostring(Config.Inventory))
end
