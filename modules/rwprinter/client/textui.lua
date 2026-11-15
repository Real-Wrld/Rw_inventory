PrinterTextUI = {}

local shown = false
local currentKey = nil
local currentLabel = nil

function PrinterTextUI.Show(key, label)
    -- Skip if already showing the same prompt
    if shown and currentKey == key and currentLabel == label then
        return
    end

    shown = true
    currentKey = key
    currentLabel = label

    SendNUIMessage({
        action   = "textui",
        show     = true,
        key      = key,
        label    = label,
        icon     = "printer",
        position = PrinterConfig.UI.textUIPos or "bottom-center",
    })
end

function PrinterTextUI.Hide()
    if not shown then return end

    shown = false
    currentKey = nil
    currentLabel = nil

    SendNUIMessage({ action = "textui", show = false })
end

function PrinterTextUI.IsShown()
    return shown
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    PrinterTextUI.Hide()
end)