

-- ---------------------------------------------------------------------------
-- Notification bridge
--
-- One call, any notification script. `PrinterConfig.Notify` picks which one; 'auto'
-- looks at what is running on your server and decides.
--
--   Client : PrinterNotify.Send(message, kind)
--   Server : PrinterNotify.Server(source, message, kind)
--
-- `kind` is always one of: 'info' | 'success' | 'error' | 'warning'.
-- Every provider below translates that to whatever names it happens to use,
-- so the rest of the resource never has to care.
--
-- Nothing here is required. With no notification script at all, the built-in
-- toast is used -- it is part of this resource's own interface, so it always
-- works and looks like the rest of it.
-- ---------------------------------------------------------------------------

PrinterNotify = PrinterNotify or {}

local IS_SERVER = IsDuplicityVersion()
local EVENT     = 'rwprinter:client:notify'
local TITLE     = '3D Printer'

local function running(name)
    return GetResourceState(name) == 'started'
end

-- ---------------------------------------------------------------------------
-- Which provider to use
--
-- Resolved once and remembered: `GetResourceState` is cheap but this is asked
-- on every notification, and the answer cannot change without a restart.
-- ---------------------------------------------------------------------------

local chosen = nil

local function provider()
    if chosen then return chosen end

    local want = (PrinterConfig and PrinterConfig.Notify) or 'auto'

    if want ~= 'auto' then
        chosen = want
        return chosen
    end

    -- Order matters: the more specific/nicer ones first, framework defaults
    -- last, built-in as the floor.
    if running('ox_lib') then chosen = 'ox_lib'
    elseif running('okokNotify') then chosen = 'okok'
    elseif running('mythic_notify') then chosen = 'mythic'
    elseif running('t-notify') then chosen = 't-notify'
    elseif running('brutal_notify') then chosen = 'brutal'
    elseif running('wasabi_notify') then chosen = 'wasabi'
    elseif PrinterFramework and PrinterFramework.name == 'esx' then chosen = 'esx'
    elseif PrinterFramework and (PrinterFramework.name == 'qb' or PrinterFramework.name == 'qbox') then chosen = 'qb'
    else chosen = 'builtin'
    end

    return chosen
end

-- ---------------------------------------------------------------------------
-- CLIENT
-- ---------------------------------------------------------------------------

if not IS_SERVER then

    --- The built-in toast. Also the fallback for every provider that fails.
    local function builtin(message, kind)
        SendNUIMessage({ action = 'notify', message = message, type = kind })
    end

    --- ox_lib uses 'inform' where everyone else says 'info'.
    local function oxKind(kind)
        if kind == 'error' or kind == 'success' or kind == 'warning' then return kind end
        return 'inform'
    end

    --- Send a notification to this player.
    ---@param message string
    ---@param kind string|nil 'info' | 'success' | 'error' | 'warning'
    function PrinterNotify.Send(message, kind)
        if type(message) ~= 'string' or message == '' then return end
        kind = kind or 'info'

        local how = provider()
        local ok  = true

        if how == 'builtin' then
            builtin(message, kind)
            return

        elseif how == 'ox_lib' then
            ok = pcall(function()
                exports.ox_lib:notify({
                    title       = TITLE,
                    description = message,
                    type        = oxKind(kind),
                })
            end)

        elseif how == 'okok' then
            ok = pcall(function()
                exports['okokNotify']:Alert(TITLE, message, 5000, kind)
            end)

        elseif how == 'mythic' then
            ok = pcall(function()
                exports['mythic_notify']:DoHudText(kind == 'warning' and 'inform' or kind, message)
            end)

        elseif how == 't-notify' then
            ok = pcall(function()
                exports['t-notify']:Custom({
                    style    = kind == 'warning' and 'warning' or kind,
                    title    = TITLE,
                    message  = message,
                    duration = 5000,
                })
            end)

        elseif how == 'brutal' then
            ok = pcall(function()
                exports['brutal_notify']:SendAlert(TITLE, message, 5000, kind)
            end)

        elseif how == 'wasabi' then
            ok = pcall(function()
                exports['wasabi_notify']:notify(TITLE, message, 5000, kind)
            end)

        elseif how == 'esx' then
            ok = pcall(function()
                if PrinterFramework and PrinterFramework.core and PrinterFramework.core.ShowNotification then
                    PrinterFramework.core.ShowNotification(message)
                else
                    TriggerEvent('esx:showNotification', message)
                end
            end)

        elseif how == 'qb' then
            ok = pcall(function()
                -- QBCore has no 'warning'; 'primary' is the closest it offers.
                TriggerEvent('QBCore:PrinterNotify', message, kind == 'warning' and 'primary' or kind)
            end)

        elseif how == 'custom' then
            -- Your own function, defined in config/config.lua. See PrinterConfig.Notify.
            if type(NotifyCustom) == 'function' then
                ok = pcall(NotifyCustom, message, kind)
            else
                ok = false
            end

        else
            builtin(message, kind)
            return
        end

        -- A provider that errors (wrong export name, resource stopped mid-game)
        -- must not swallow the message. The built-in toast takes over.
        if not ok then builtin(message, kind) end
    end

    RegisterNetEvent(EVENT, function(message, kind)
        PrinterNotify.Send(message, kind)
    end)

-- ---------------------------------------------------------------------------
-- SERVER
--
-- The server never picks a provider: it hands the message to the player's
-- client and that client decides. Two people on the same server can therefore
-- be running different notification scripts and both get a message.
-- ---------------------------------------------------------------------------

else

    ---@param src number player server id
    ---@param message string
    ---@param kind string|nil
    function PrinterNotify.Server(src, message, kind)
        if not src or src <= 0 then return end
        TriggerClientEvent(EVENT, src, message, kind or 'info')
    end

end

