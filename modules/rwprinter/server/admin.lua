-- Sends a message to a player, or prints to the console when source is 0
local function reply(source, message, kind)
    if source > 0 then
        PrinterFramework.Notify(source, message, kind)
    else
        print("[rwprinter] " .. message)
    end
end

-- /<givePrinter> [playerId] [amount]
RegisterCommand(PrinterConfig.Commands.givePrinter, function(source, args)
    if not PrinterFramework.IsAdmin(source) then
        if source > 0 then
            PrinterFramework.Notify(source, PrinterL("no_permission"), "error")
        end
        return
    end

    local target = tonumber(args[1]) or source
    local amount = math.min(math.max(tonumber(args[2]) or 1, 1), 100)

    if target == 0 or not GetPlayerName(target) then
        reply(source, PrinterL("player_not_found"), "error")
        return
    end

    local item = PrinterUtils.PrinterItem()

    if not PrinterInventory.AddItem(target, item, amount) then
        local reason = PrinterInventory.WhyAddFailed(item)
        reply(source, PrinterL(reason, item), "error")
        return
    end

    PrinterFramework.Notify(target, PrinterL("received_printer", amount), "success")

    if source > 0 and source ~= target then
        PrinterFramework.Notify(source, PrinterL("given_printer", amount, GetPlayerName(target)), "success")
    elseif source == 0 then
        print(("[rwprinter] %s"):format(PrinterL("given_printer", amount, GetPlayerName(target))))
    end
end, false)

-- /<removeAll>
RegisterCommand(PrinterConfig.Commands.removeAll, function(source)
    if not PrinterFramework.IsAdmin(source) then
        if source > 0 then
            PrinterFramework.Notify(source, PrinterL("no_permission"), "error")
        end
        return
    end

    local count = PrinterClearAllPrinters()

    if source > 0 then
        PrinterFramework.Notify(source, PrinterL("cleared_printers", count), "success")
    else
        print(("[rwprinter] %s"):format(PrinterL("cleared_printers", count)))
    end
end, false)

-- Register printer item(s) as usable once PrinterFramework and PrinterInventory are ready (waits up to ~15s)
CreateThread(function()
    local tries = 0
    while not (PrinterFramework.name and PrinterInventory.name) and tries < 150 do
        Wait(100)
        tries = tries + 1
    end

    for _, item in ipairs(PrinterUtils.PrinterItems()) do
        PrinterFramework.RegisterUsableItem(item, function(source)
            TriggerClientEvent("rwprinter:client:startPlacement", source)
        end)
    end
end)