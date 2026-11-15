-- callbacks.lua  –  Lightweight callback system for bablo-pettycrimes
-- Runs on both client and server; each side registers what it supports.

local isServer = IsDuplicityVersion()

-- Msgpack helpers for packing/unpacking variadic arguments over events
local tableUnpack = table.unpack
local msgpackPack      = msgpack.pack
local msgpackUnpack    = msgpack.unpack
local msgpackPackArgs  = msgpack.pack_args

-- Promise state constants (from the CitizenFX promise library)
local PROMISE_PENDING   = 0
local PROMISE_RESOLVING = 1
local PROMISE_RESOLVED  = 2
local PROMISE_REJECTED  = 3
local PROMISE_HANDLED   = 4

-- Event name prefixes
local PREFIX_SERVER_CB   = "bablo_pettycrimes_callbacks__server_callback:"
local PREFIX_CLIENT_CB   = "bablo_pettycrimes_callbacks__client_callback:"
local PREFIX_CLIENT_RESP = "bablo_pettycrimes_callbacks__client_callback_response:"
local PREFIX_RETVAL      = "bablo_pettycrimes_callbacks__callback_retval:"

-- ─── Type assertion helper ────────────────────────────────────────────────────

-- Asserts that `value` matches `expectedType` (and optionally `altType`).
-- Errors with a message referencing the calling function name.
local function AssertType(value, expectedType, altType, customMsg)
    local actualType  = type(value)
    local callerName  = debug.getinfo(2).name

    local errorMsg = customMsg
    if not errorMsg then
        if altType == nil then
            errorMsg = callerName .. " expected %s, but got %s"
        else
            errorMsg = callerName .. " expected %s or %s, but got %s"
        end
    end

    if expectedType == "function" then
        -- For function type: also accept CFX function references in tables
        if actualType == "table" then
            if not rawget(value, "__cfx_functionReference") then
                error(errorMsg:format(expectedType, altType, actualType))
            end
        end
        -- If not a table and not a function, fall through to generic check below
    else
        if actualType ~= expectedType and actualType ~= altType then
            error(errorMsg:format(expectedType, altType, actualType))
        end
    end
end

-- ─── Shared response handler ──────────────────────────────────────────────────

-- Resolves a promise with the unpacked msgpack data, and optionally calls a callback.
local function HandleCallbackResponse(prom, userCallback, rawData)
    if userCallback and prom.state == PROMISE_PENDING then
        userCallback(tableUnpack(msgpackUnpack(rawData)))
    end
    prom:resolve(tableUnpack(msgpackUnpack(rawData)))
end

-- Registers a timeout that calls the timedout function and rejects the promise
-- if it is still pending after `timeoutSec` seconds.
local function AttachTimeout(prom, timeoutSec, timedoutFn, eventHandler)
    if timeoutSec == nil or not timedoutFn then return end

    SetTimeout(timeoutSec * 1000, function()
        -- Only fire if the promise is still in a terminal-waiting state
        if prom.state == PROMISE_PENDING
            or prom.state == PROMISE_HANDLED
            or prom.state == PROMISE_RESOLVED then

            timedoutFn(prom.state)
            if prom.state == PROMISE_PENDING then
                prom:reject(prom)
            end
            if eventHandler then
                RemoveEventHandler(eventHandler)
            end
        end
    end)
end

-- ─── Server-side API ─────────────────────────────────────────────────────────

if isServer then

    -- RegisterServerCallback({ eventName, eventCallback })
    -- Registers a server-side handler. When called from another server script
    -- (source == nil), executes locally. When triggered by a client, fires
    -- TriggerClientEvent with the response.
    function RegisterServerCallback(opts)
        AssertType(opts,               "table")
        AssertType(opts.eventName,     "string")
        AssertType(opts.eventCallback, "function")

        local handler   = opts.eventCallback
        local eventName = opts.eventName

        local eventHandler = RegisterNetEvent(PREFIX_SERVER_CB .. eventName,
            function(packedArgs, responseName, ...)
                local playerId = tonumber(source)

                if not playerId then
                    -- Local server-to-server call: invoke callback directly
                    local replyFn = responseName
                    local args    = tableUnpack(msgpackUnpack(packedArgs))
                    replyFn(msgpackPackArgs(handler(args)))
                else
                    -- Client-originated call: send response back via client event
                    local replyEvent = (PREFIX_RETVAL .. "%s:%s"):format(eventName, playerId)
                    local args       = tableUnpack(msgpackUnpack(packedArgs))
                    TriggerClientEvent(replyEvent, playerId,
                        msgpackPackArgs(handler(playerId, args)))
                end
            end)

        return eventHandler
    end

    function UnregisterServerCallback(eventHandler)
        RemoveEventHandler(eventHandler)
    end

    -- TriggerClientCallback({ source, eventName, args?, timeout?, timedout?, callback? })
    -- Calls a client-registered callback from the server.
    -- If `callback` is provided: async (fires and forgets).
    -- If `callback` is nil: blocks with Citizen.Await.
    function TriggerClientCallback(opts)
        AssertType(opts,           "table")
        AssertType(opts.source,    "string", "number")
        AssertType(opts.eventName, "string")
        AssertType(opts.args,      "table",  "nil")
        AssertType(opts.timeout,   "number", "nil")
        AssertType(opts.timedout,  "function", "nil")
        AssertType(opts.callback,  "function", "nil")

        local sourceId = tonumber(opts.source)
        if sourceId < 0 then
            error("source should be equal to or higher than 0")
        end

        local callId    = tostring(sourceId) .. "x" .. tostring(GetGameTimer())
        local prom      = promise.new()
        local userCb    = opts.callback
        local retvalKey = (PREFIX_RETVAL .. "%s:%s:%s"):format(opts.source, opts.eventName, callId)

        local eventHandler = RegisterNetEvent(retvalKey, function(rawData)
            HandleCallbackResponse(prom, userCb, rawData)
            prom:resolve(tableUnpack(msgpackUnpack(rawData)))
        end)

        local packedArgs = msgpackPack(opts.args or {})
        TriggerClientEvent(PREFIX_CLIENT_CB .. opts.eventName,
            opts.source, packedArgs, prom)

        AttachTimeout(prom, opts.timeout, opts.timedout, eventHandler)

        if not userCb then
            local result = Citizen.Await(prom)
            RemoveEventHandler(eventHandler)
            return result
        end
    end

    -- TriggerServerCallback({ source, eventName, args?, timeout?, timedout?, callback? })
    -- Calls a server-registered callback from within a server script.
    function TriggerServerCallback(opts)
        AssertType(opts,           "table")
        AssertType(opts.source,    "string", "number")
        AssertType(opts.eventName, "string")
        AssertType(opts.args,      "table",  "nil")
        AssertType(opts.timeout,   "number", "nil")
        AssertType(opts.timedout,  "function", "nil")
        AssertType(opts.callback,  "function", "nil")

        local prom   = promise.new()
        local userCb = opts.callback

        local packedArgs = msgpackPack(opts.args or {})

        TriggerEvent(PREFIX_SERVER_CB .. opts.eventName,
            packedArgs, opts.source, function(rawData)
                HandleCallbackResponse(prom, userCb, rawData)
                prom:resolve(tableUnpack(msgpackUnpack(rawData)))
            end)

        AttachTimeout(prom, opts.timeout, opts.timedout)

        if not userCb then
            return Citizen.Await(prom)
        end
    end

    exports("RegisterServerCallback",  RegisterServerCallback)
    exports("UnregisterServerCallback", UnregisterServerCallback)
    exports("TriggerClientCallback",   TriggerClientCallback)
    exports("TriggerServerCallback",   TriggerServerCallback)
end

-- ─── Client-side API ─────────────────────────────────────────────────────────

if not isServer then

    local myServerId = GetPlayerServerId(PlayerId())

    -- RegisterClientCallback({ eventName, eventCallback })
    -- Registers a client-side handler. When triggered by the server, if the
    -- incoming `responseInfo` is a function it's a local call; otherwise the
    -- result is sent back to the server via TriggerServerEvent.
    function RegisterClientCallback(opts)
        AssertType(opts,               "table")
        AssertType(opts.eventName,     "string")
        AssertType(opts.eventCallback, "function")

        local handler   = opts.eventCallback
        local eventName = opts.eventName

        local eventHandler = RegisterNetEvent(PREFIX_CLIENT_CB .. eventName,
            function(packedArgs, responseInfo)
                if type(responseInfo) == "function" then
                    -- Local (same-side) call: respond directly
                    local args = tableUnpack(msgpackUnpack(packedArgs))
                    responseInfo(msgpackPackArgs(handler(args)))
                else
                    -- Server-originated call: send result back
                    local retvalKey = (PREFIX_RETVAL .. "%s:%s:%s"):format(
                        myServerId, eventName, responseInfo)
                    local args      = tableUnpack(msgpackUnpack(packedArgs))
                    TriggerServerEvent(retvalKey, msgpackPackArgs(handler(args)))
                end
            end)

        return eventHandler
    end

    function UnregisterClientCallback(eventHandler)
        RemoveEventHandler(eventHandler)
    end

    -- TriggerServerCallback({ eventName, args?, timeout?, timedout?, callback? })
    -- Calls a server-registered callback from the client.
    function TriggerServerCallback(opts)
        AssertType(opts,           "table")
        AssertType(opts.eventName, "string")
        AssertType(opts.args,      "table",    "nil")
        AssertType(opts.timeout,   "number",   "nil")
        AssertType(opts.timedout,  "function", "nil")
        AssertType(opts.callback,  "function", "nil")

        local prom      = promise.new()
        local userCb    = opts.callback
        local retvalKey = (PREFIX_CLIENT_RESP .. "%s:%s"):format(opts.eventName, myServerId)

        local eventHandler = RegisterNetEvent(retvalKey, function(rawData)
            HandleCallbackResponse(prom, userCb, rawData)
            prom:resolve(tableUnpack(msgpackUnpack(rawData)))
        end)

        local packedArgs = msgpackPack(opts.args or {})
        TriggerServerEvent(PREFIX_SERVER_CB .. opts.eventName, packedArgs)

        AttachTimeout(prom, opts.timeout, opts.timedout, eventHandler)

        if not userCb then
            local result = Citizen.Await(prom)
            RemoveEventHandler(eventHandler)
            return result
        end
    end

    -- TriggerClientCallback({ eventName, args?, timeout?, timedout?, callback? })
    -- Calls a client-registered callback from within client code.
    function TriggerClientCallback(opts)
        AssertType(opts,           "table")
        AssertType(opts.eventName, "string")
        AssertType(opts.args,      "table",    "nil")
        AssertType(opts.timeout,   "number",   "nil")
        AssertType(opts.timedout,  "function", "nil")
        AssertType(opts.callback,  "function", "nil")

        local prom   = promise.new()
        local userCb = opts.callback

        local packedArgs = msgpackPack(opts.args or {})

        TriggerEvent(PREFIX_CLIENT_CB .. opts.eventName, packedArgs, function(rawData)
            HandleCallbackResponse(prom, userCb, rawData)
            prom:resolve(tableUnpack(msgpackUnpack(rawData)))
        end)

        AttachTimeout(prom, opts.timeout, opts.timedout)

        if not userCb then
            return Citizen.Await(prom)
        end
    end

    exports("RegisterClientCallback",  RegisterClientCallback)
    exports("UnregisterClientCallback", UnregisterClientCallback)
    exports("TriggerServerCallback",   TriggerServerCallback)
    exports("TriggerClientCallback",   TriggerClientCallback)
end
