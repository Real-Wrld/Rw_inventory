function GetAppearanceSystemFn(funcName)
    if RW.Modules.Appearance then
        if RW.Modules.Appearance[funcName] then
            return RW.Modules.Appearance[funcName]
        end
    end
    return nil
end

function GetPedAppearance(ped)
    if not RW.Ready then
        return {}
    end
    local fn = GetAppearanceSystemFn("GetPedAppearance")
    if fn then
        return fn(ped)
    end
    RW.Utils.Warn("GetPedAppearance: No appearance system available")
    return {}
end

function SetPedAppearance(ped, appearanceData)
    if not RW.Ready then
        return
    end
    local fn = GetAppearanceSystemFn("SetPedAppearance")
    if fn then
        return fn(ped, appearanceData)
    end
    RW.Utils.Warn("SetPedAppearance: No appearance system available")
end

function SetPedComponent(ped, componentId, drawableId, textureId)
    if not ped then
        ped = PlayerPedId()
    end

    local fn = RW.Ready and GetAppearanceSystemFn('SetPedComponent')
    if fn then
        return fn(ped, componentId, drawableId, textureId)
    end

    SetPedComponentVariation(ped, componentId, drawableId, textureId, 0)
end

function GetPedComponent(ped, componentId)
    if not RW.Ready then
        return { drawable = 0, texture = 0 }
    end
    if not ped then
        ped = PlayerPedId()
    end
    local comp = {}
    comp.drawable = GetPedDrawableVariation(ped, componentId)
    comp.texture = GetPedTextureVariation(ped, componentId)
    return comp
end

function SetPedProp(ped, componentId, drawableId, textureId)
    if not ped then
        ped = PlayerPedId()
    end

    local fn = RW.Ready and GetAppearanceSystemFn('SetPedProp')
    if fn then
        return fn(ped, componentId, drawableId, textureId)
    end

    if drawableId == -1 then
        ClearPedProp(ped, componentId)
    else
        SetPedPropIndex(ped, componentId, drawableId, textureId, true)
    end
end

function GetPedProp(ped, componentId)
    if not RW.Ready then
        return { drawable = -1, texture = 0 }
    end
    if not ped then
        ped = PlayerPedId()
    end
    local prop = {}
    prop.drawable = GetPedPropIndex(ped, componentId)
    prop.texture = GetPedPropTextureIndex(ped, componentId)
    return prop
end

function SetPedHair(ped, drawableId, textureId, highlightColor)
    if not RW.Ready then
        return
    end
    local fn = GetAppearanceSystemFn("SetPedHair")
    if fn then
        return fn(ped, drawableId, textureId, highlightColor)
    end
    if not ped then
        ped = PlayerPedId()
    end
    SetPedComponentVariation(ped, 2, drawableId, 0, 0)
    SetPedHairColor(ped, textureId or 0, highlightColor or 0)
end

function GetPedHair(ped)
    if not RW.Ready then
        return { style = 0, color = 0, highlight = 0 }
    end
    if not ped then
        ped = PlayerPedId()
    end
    local hair = {}
    hair.style = GetPedDrawableVariation(ped, 2)
    hair.color = GetPedHairColor(ped)
    hair.highlight = GetPedHairHighlightColor(ped)
    return hair
end

function SetPedHeadOverlay(ped, overlayID, index, opacity, colorType, firstColor, secondColor)
    if not RW.Ready then
        return
    end
    local fn = GetAppearanceSystemFn("SetPedHeadOverlay")
    if fn then
        return fn(ped, overlayID, index, opacity, colorType, firstColor, secondColor)
    end
    if not ped then
        ped = PlayerPedId()
    end
    SetPedHeadOverlay(ped, overlayID, index, opacity or 1.0)
    if colorType and firstColor then
        SetPedHeadOverlayColor(ped, overlayID, colorType, firstColor, secondColor or firstColor)
    end
end

function GetPedHeadOverlayDataRW(ped, overlayID)
    if not RW.Ready then
        return { index = 255, opacity = 1.0 }
    end
    if not ped then
        ped = PlayerPedId()
    end
    local _, index, colorType, firstColor, secondColor, opacity = GetPedHeadOverlayData(ped, overlayID)
    return {
        index = index,
        opacity = opacity,
        colorType = colorType,
        firstColor = firstColor,
        secondColor = secondColor
    }
end

function SetPedEyeColorRW(ped, index)
    if not RW.Ready then
        return
    end
    local fn = GetAppearanceSystemFn("SetPedEyeColor")
    if fn then
        return fn(ped, index)
    end
    if not ped then
        ped = PlayerPedId()
    end
    SetPedEyeColor(ped, index)
end

function GetPedEyeColorRW(ped)
    if not RW.Ready then
        return 0
    end
    if not ped then
        ped = PlayerPedId()
    end
    return GetPedEyeColor(ped)
end

function GetPedModelRW(ped)
    if not RW.Ready then
        return 0
    end
    if not ped then
        ped = PlayerPedId()
    end
    return GetEntityModel(ped)
end

function SetPedModelRW(ped, modelHash)
    if not RW.Ready then
        return
    end
    local fn = GetAppearanceSystemFn("SetPedModel")
    if fn then
        return fn(nil, modelHash)
    end
    local model = modelHash
    if type(modelHash) == "string" then
        model = joaat(modelHash) or modelHash
    end
    RequestModel(model)
    local waitTime = 500
    while not HasModelLoaded(model) and waitTime > 0 do
        Wait(10)
        waitTime = waitTime - 1
    end
    if HasModelLoaded(model) then
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
    end
end

function GetComponentDrawableCount(ped, componentId)
    if not ped then
        ped = PlayerPedId()
    end
    return GetNumberOfPedDrawableVariations(ped, componentId)
end

function GetComponentTextureCount(ped, componentId, drawableId)
    if not ped then
        ped = PlayerPedId()
    end
    return GetNumberOfPedTextureVariations(ped, componentId, drawableId)
end

function GetPropDrawableCount(ped, propId)
    if not ped then
        ped = PlayerPedId()
    end
    return GetNumberOfPedPropDrawableVariations(ped, propId)
end

function GetPropTextureCount(ped, propId, drawableId)
    if not ped then
        ped = PlayerPedId()
    end
    return GetNumberOfPedPropTextureVariations(ped, propId, drawableId)
end

function GetAppearanceSystem()
    return RW.Appearance
end

function SaveAppearance(appearanceData)
    local fn = RW.Ready and GetAppearanceSystemFn('SaveAppearance')
    if fn then
        return fn(appearanceData)
    end

    if GetResourceState('illenium-appearance') == 'started' then
        local ped = PlayerPedId()
        local appearance = appearanceData
        if not appearance then
            local ok, result = pcall(function()
                return exports['illenium-appearance']:getPedAppearance(ped)
            end)
            if ok then appearance = result end
        end
        if appearance then
            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
        end
    end
end

RegisterNetEvent(Config.EventPrefix .. ":client:saveAppearance", function(appearanceData)
    if not RW.Ready then
        return
    end
    local fn = GetAppearanceSystemFn("SaveAppearance")
    if fn then
        return fn(appearanceData)
    end
    RW.Utils.Warn("SaveAppearance: No appearance system available")
end)

RegisterNetEvent(Config.EventPrefix .. ":client:setAppearance", function(appearanceData)
    if not RW.Ready then
        return
    end
    local fn = GetAppearanceSystemFn("SetAppearanceFromServer")
    if fn then
        return fn(appearanceData)
    end
    RW.Utils.Warn("SetAppearanceFromServer: No appearance system available")
end)

exports("GetPedAppearance", GetPedAppearance)
exports("SetPedAppearance", SetPedAppearance)
exports("SetPedComponent", SetPedComponent)
exports("GetPedComponent", GetPedComponent)
exports("SetPedProp", SetPedProp)
exports("GetPedProp", GetPedProp)
exports("SetPedHair", SetPedHair)
exports("GetPedHair", GetPedHair)
exports("SetPedHeadOverlay", SetPedHeadOverlay)
exports("GetPedHeadOverlay", GetPedHeadOverlayDataRW)
exports("SetPedEyeColor", SetPedEyeColorRW)
exports("GetPedEyeColor", GetPedEyeColorRW)
exports("GetPedModel", GetPedModelRW)
exports("SetPedModel", SetPedModelRW)
exports("GetComponentDrawableCount", GetComponentDrawableCount)
exports("GetComponentTextureCount", GetComponentTextureCount)
exports("GetPropDrawableCount", GetPropDrawableCount)
exports("GetPropTextureCount", GetPropTextureCount)
exports("GetAppearanceSystem", GetAppearanceSystem)
exports("SaveAppearance", SaveAppearance)

