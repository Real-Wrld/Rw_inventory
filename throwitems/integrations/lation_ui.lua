

if Config.TextUI ~= 'lation_ui' then
    return
end

local textUIs = {
    throw = {
        title = 'Throwing',
        description = 'Throw the item where desired',
        icon = 'fas fa-hand-fist',
        position = 'right-center',
        options = {
            { label = 'Throw', icon = 'fas fa-hand-fist', keybind = 'LMB' },
            { label = 'Aim', icon = 'fas fa-crosshairs', keybind = 'RMB' },
            { label = 'Cancel', icon = 'fas fa-xmark', iconColor = '#F87171', keybind = 'X' },
        },
    },
    place = {
        title = 'Placing',
        description = 'Place the object where desired',
        icon = 'fas fa-cube',
        position = 'right-center',
        options = {
            { label = 'Place', icon = 'fas fa-check', iconColor = '#4ADE80', keybind = 'E' },
            { label = 'Rotate', icon = 'fas fa-rotate', keybind = 'SCROLL' },
            { label = 'Cancel', icon = 'fas fa-xmark', iconColor = '#F87171', keybind = 'X' },
        },
    },
}

ShowTextUI = function(id, text)
    local data = textUIs[id]

    if data then
        exports.lation_ui:showText(data)
    else
        exports.lation_ui:showText({ description = text })
    end
end

HideTextUI = function()
    exports.lation_ui:hideText()
end

