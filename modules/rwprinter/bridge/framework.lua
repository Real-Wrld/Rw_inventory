

-- ---------------------------------------------------------------------------
-- PrinterFramework bridge: ESX / QBCore / Qbox / standalone
--
-- Runs on both sides; branches with IsDuplicityVersion(). Nothing else in the
-- resource talks to a framework directly -- everything goes through the
-- `PrinterFramework` table below. To support a framework that is not listed here, you
-- only have to fill in these functions; the rest of the script does not change.
--
-- With no framework at all the resource still runs: identifiers fall back to
-- the player's license and jobs to 'unemployed'. Job-locked items simply stop
-- being reachable, everything else works.
-- ---------------------------------------------------------------------------

PrinterFramework = {
    name = nil,   -- 'esx' | 'qb' | 'qbox' | 'standalone'
    core = nil,   -- the framework object, when it has one
}

local IS_SERVER = IsDuplicityVersion()

local function running(name)
    return GetResourceState(name) == 'started'
end

-- ---------------------------------------------------------------------------
-- Detection
-- ---------------------------------------------------------------------------

--- Qbox exposes functions directly and has no core object.
---
--- `exports.qbx_core` is a PROXY: reading a key it does not export throws
--- "No such export". Never probe it for a function to see whether it exists --
--- only call the documented ones, and always inside a pcall.
local function tryQbox()
    if not running('qbx_core') then return false end
    PrinterFramework.name, PrinterFramework.core = 'qbox', nil
    return true
end

local function tryQb()
    if not running('qb-core') then return false end

    local core
    pcall(function() core = exports['qb-core']:GetCoreObject() end)
    if not core then return false end

    PrinterFramework.name, PrinterFramework.core = 'qb', core
    return true
end

--- ESX changed how the object is handed out around 1.9. The export is the
--- modern way; the event is kept for older builds still in the wild.
local function tryEsx()
    if not running('es_extended') then return false end

    local core
    pcall(function() core = exports['es_extended']:getSharedObject() end)

    if not core then
        pcall(function()
            TriggerEvent('esx:getSharedObject', function(obj) core = obj end)
        end)
    end

    if not core then return false end

    PrinterFramework.name, PrinterFramework.core = 'esx', core
    return true
end

local function detect()
    local forced = (PrinterConfig and PrinterConfig.Framework) or 'auto'

    if forced == 'standalone' then
        PrinterFramework.name = 'standalone'
        return true
    elseif forced == 'esx' then return tryEsx()
    elseif forced == 'qb' then return tryQb()
    elseif forced == 'qbox' then return tryQbox()
    end

    -- Qbox first: it also ships qb-core compatibility, so asking qb-core first
    -- would identify a Qbox server as QBCore and use the wrong exports.
    return tryQbox() or tryQb() or tryEsx()
end

CreateThread(function()
    -- Frameworks start at their own pace. Try for ~10 s before giving up and
    -- running standalone, rather than assuming a fixed delay is enough.
    local tries = 0

    while not PrinterFramework.name and tries < 100 do
        if detect() then break end
        Wait(100)
        tries = tries + 1
    end

    if not PrinterFramework.name then
        PrinterFramework.name = 'standalone'
        print('^3[rwprinter] No framework detected (esx / qb-core / qbx_core).^0')
        print('^3[rwprinter] Running standalone: no jobs, license used as identifier.^0')
    else
        print(('^2[rwprinter] PrinterFramework: %s^0'):format(PrinterFramework.name))
    end
end)

-- ---------------------------------------------------------------------------
-- SERVER
-- ---------------------------------------------------------------------------
if IS_SERVER then

    --- The framework's player object for a source, whatever shape it takes.
    local function player(src)
        local p

        if PrinterFramework.name == 'esx' and PrinterFramework.core then
            pcall(function() p = PrinterFramework.core.GetPlayerFromId(src) end)
        elseif PrinterFramework.name == 'qb' and PrinterFramework.core then
            pcall(function() p = PrinterFramework.core.Functions.GetPlayer(src) end)
        elseif PrinterFramework.name == 'qbox' then
            pcall(function() p = exports.qbx_core:GetPlayer(src) end)
        end

        return p
    end

    PrinterFramework.GetPlayer = player

    --- Stable identifier for a player. This is what a printer is owned by, so
    --- it has to survive reconnects and server restarts.
    ---@param src number
    ---@return string|nil
    function PrinterFramework.GetIdentifier(src)
        local p = player(src)

        if p then
            if PrinterFramework.name == 'esx' then
                return p.identifier
            else
                return p.PlayerData and p.PlayerData.citizenid
            end
        end

        -- Standalone, or the player object is not ready yet.
        return GetPlayerIdentifierByType(src, 'license')
    end

    --- Display name, used on the printer and in the admin console.
    ---@param src number
    ---@return string
    function PrinterFramework.GetName(src)
        local p = player(src)

        if p then
            if PrinterFramework.name == 'esx' then
                -- getName() is the modern accessor; older builds only have the
                -- name field.
                local name
                pcall(function() name = p.getName and p.getName() end)
                if name and name ~= '' then return name end
                if p.name and p.name ~= '' then return p.name end
            else
                local ci = p.PlayerData and p.PlayerData.charinfo
                if ci and ci.firstname then
                    return ('%s %s'):format(ci.firstname, ci.lastname or '')
                end
            end
        end

        return GetPlayerName(src) or ('Player %s'):format(src)
    end

    --- Job and grade. Used by items locked to a job in config/items.lua.
    ---@param src number
    ---@return string job, number grade
    function PrinterFramework.GetJob(src)
        local p = player(src)

        if p then
            if PrinterFramework.name == 'esx' then
                if p.job then return p.job.name, p.job.grade or 0 end
            else
                local job = p.PlayerData and p.PlayerData.job
                if job then
                    -- QBCore keeps the number under grade.level; some forks
                    -- store the grade directly.
                    local grade = job.grade
                    if type(grade) == 'table' then grade = grade.level end
                    return job.name, grade or 0
                end
            end
        end

        return 'unemployed', 0
    end

    --- Is this player an administrator?
    ---
    --- Checked in three places, cheapest first: the server console, an ACE
    --- permission, then the framework's own group system. Any one is enough.
    ---@param src number
    ---@return boolean
    function PrinterFramework.IsAdmin(src)
        if src == 0 then return true end   -- server console

        for _, group in ipairs(PrinterConfig.AdminGroups or {}) do
            if IsPlayerAceAllowed(src, ('rwprinter.%s'):format(group)) then return true end
        end

        local p = player(src)

        if p then
            if PrinterFramework.name == 'esx' then
                local group
                pcall(function() group = p.getGroup and p.getGroup() end)

                if group then
                    for _, g in ipairs(PrinterConfig.AdminGroups or {}) do
                        if group == g then return true end
                    end
                end
            elseif PrinterFramework.name == 'qb' and PrinterFramework.core then
                for _, g in ipairs(PrinterConfig.AdminGroups or {}) do
                    local ok, allowed = pcall(function()
                        return PrinterFramework.core.Functions.HasPermission(src, g)
                    end)
                    if ok and allowed then return true end
                end
            elseif PrinterFramework.name == 'qbox' then
                for _, g in ipairs(PrinterConfig.AdminGroups or {}) do
                    local ok, allowed = pcall(function()
                        return exports.qbx_core:HasPermission(src, g)
                    end)
                    if ok and allowed then return true end
                end
            end
        end

        return IsPlayerAceAllowed(src, 'command')
    end

    --- Make the printer item usable, so right-clicking it starts placement.
    ---
    --- ox_inventory is the exception: there the item is wired up on the CLIENT
    --- through `client.export` in its own items.lua, and a server-side usable
    --- item is never called. See client/placement.lua.
    ---@param item string
    ---@param cb function called with the player source
    function PrinterFramework.RegisterUsableItem(item, cb)
        if PrinterInventory and PrinterInventory.name == 'ox' then return end

        if PrinterFramework.name == 'qb' and PrinterFramework.core then
            pcall(function() PrinterFramework.core.Functions.CreateUseableItem(item, cb) end)

        elseif PrinterFramework.name == 'qbox' then
            pcall(function() exports.qbx_core:CreateUseableItem(item, cb) end)

        elseif PrinterFramework.name == 'esx' and PrinterFramework.core then
            pcall(function() PrinterFramework.core.RegisterUsableItem(item, cb) end)
        end
    end

    --- Send a notification to a player. Goes through bridge/notify.lua, which
    --- is where the choice of notification script lives.
    function PrinterFramework.Notify(src, message, kind)
        if PrinterNotify and PrinterNotify.Server then
            PrinterNotify.Server(src, message, kind or 'info')
        else
            TriggerClientEvent('rwprinter:client:notify', src, message, kind or 'info')
        end
    end

-- ---------------------------------------------------------------------------
-- CLIENT
-- ---------------------------------------------------------------------------
else

    --- Notification for this player.
    function PrinterFramework.Notify(message, kind)
        if PrinterNotify and PrinterNotify.Send then
            PrinterNotify.Send(message, kind or 'info')
        else
            SendNUIMessage({ action = 'notify', message = message, type = kind or 'info' })
        end
    end

    --- This player's job. Only used to grey out items they cannot print; the
    --- server checks again before anything is queued.
    ---@return string job, number grade
    function PrinterFramework.GetJob()
        local d

        if PrinterFramework.name == 'esx' and PrinterFramework.core then
            pcall(function() d = PrinterFramework.core.GetPlayerData() end)
        elseif PrinterFramework.name == 'qb' and PrinterFramework.core then
            pcall(function() d = PrinterFramework.core.Functions.GetPlayerData() end)
        elseif PrinterFramework.name == 'qbox' then
            pcall(function() d = exports.qbx_core:GetPlayerData() end)
        end

        if d and d.job then
            local grade = d.job.grade
            if type(grade) == 'table' then grade = grade.level end
            return d.job.name, grade or 0
        end

        return 'unemployed', 0
    end

end

