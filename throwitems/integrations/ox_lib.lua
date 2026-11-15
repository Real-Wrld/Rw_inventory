

if ShowTextUI and Config.TextUI ~= 'ox_lib' then
    return
end

ShowTextUI = function(id, text)
    lib.showTextUI(text)
end

HideTextUI = function()
    lib.hideTextUI()
end

