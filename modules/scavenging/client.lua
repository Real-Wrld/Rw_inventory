-- Scavenging Client Module
-- Handles prop detection, interactions, and UI for searching
-- Hardened: never blocks ox_target onSelect, always releases search lock, safe anims.

if not lib then return end

local ScavengingConfig = lib.load('data.scavenging')
if not ScavengingConfig then return end

local isSearching = false
local searchToken = 0

-- Safe fallbacks when a configured dict is missing / invalid in this build
local SAFE_ANIM = { dict = 'mini@repair', anim = 'fixing_a_player' }

local SearchableModels = {}
local ZoneModels = {} -- hash -> { zoneId, zone }

local function BuildModelLookup()
    SearchableModels = {}
    for locationType, config in pairs(ScavengingConfig.locations or {}) do
        for _, modelName in ipairs(config.model or {}) do
            local hash = joaat(modelName)
            SearchableModels[hash] = {
                kind = 'location',
                type = locationType,
                label = config.label,
                duration = config.duration,
                animation = config.animation,
            }
        end
    end

    ZoneModels = {}
    for zoneId, zone in pairs(ScavengingConfig.zones or {}) do
        for _, modelName in ipairs(zone.targetModels or {}) do
            local hash = joaat(modelName)
            ZoneModels[hash] = ZoneModels[hash] or {}
            ZoneModels[hash][#ZoneModels[hash] + 1] = {
                kind = 'zone',
                zoneId = zoneId,
                zone = zone,
                label = zone.label,
                duration = zone.duration or 6000,
                animation = zone.animation,
            }
        end
    end
end
BuildModelLookup()

local function resolveAnim(animation)
    local dict = animation and animation.dict
    local clip = animation and (animation.anim or animation.clip)
    if type(dict) ~= 'string' or type(clip) ~= 'string' or dict == '' or clip == '' then
        return SAFE_ANIM.dict, SAFE_ANIM.anim
    end

    local ok = pcall(function()
        if not DoesAnimDictExist(dict) then
            error('missing')
        end
        lib.requestAnimDict(dict, 2500)
    end)

    if not ok or not HasAnimDictLoaded(dict) then
        return SAFE_ANIM.dict, SAFE_ANIM.anim
    end

    return dict, clip
end

local function forceReleaseSearch(token)
    if token and token ~= searchToken then return end
    isSearching = false

    local ped = cache.ped or PlayerPedId()
    if ped and DoesEntityExist(ped) then
        ClearPedTasksImmediately(ped)
    end

    if lib.progressActive and lib.progressActive() then
        pcall(function()
            lib.cancelProgress()
        end)
    end
end

local function GetClosestSearchable(maxDistance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestObj, closestDist, closestData = nil, maxDistance, nil

    local objects = GetGamePool('CObject')
    for i = 1, #objects do
        local obj = objects[i]
        local model = GetEntityModel(obj)
        local searchData = SearchableModels[model]

        if searchData then
            local dist = #(playerCoords - GetEntityCoords(obj))
            if dist < closestDist then
                closestObj = obj
                closestDist = dist
                closestData = searchData
            end
        else
            local zoneList = ZoneModels[model]
            if zoneList then
                for j = 1, #zoneList do
                    local z = zoneList[j]
                    if #(playerCoords - z.zone.coords) <= (z.zone.radius or 50.0) then
                        local dist = #(playerCoords - GetEntityCoords(obj))
                        if dist < closestDist then
                            closestObj = obj
                            closestDist = dist
                            closestData = z
                        end
                    end
                end
            end
        end
    end

    return closestObj, closestDist, closestData
end

local function PerformSearch(obj, searchData)
    if isSearching then return end
    if not searchData then return end
    if lib.progressActive and lib.progressActive() then
        lib.notify({
            title = 'Busy',
            description = 'Finish your current action first.',
            type = 'error',
            duration = 2000,
        })
        return
    end

    isSearching = true
    searchToken = searchToken + 1
    local token = searchToken
    local duration = tonumber(searchData.duration) or 5000

    -- Hard failsafe — never leave the player locked if progress/NUI stalls
    SetTimeout(duration + 4000, function()
        if isSearching and searchToken == token then
            forceReleaseSearch(token)
            lib.notify({
                title = 'Search Interrupted',
                description = 'Search timed out. You can try again.',
                type = 'error',
                duration = 2500,
            })
        end
    end)

    local ok, err = pcall(function()
        local dict, clip = resolveAnim(searchData.animation)

        local finished = lib.progressBar({
            duration = duration,
            label = ScavengingConfig.settings.messages.searching or 'Searching...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
            },
            anim = {
                dict = dict,
                clip = clip,
                flag = 49,
            },
        })

        if searchToken ~= token then return end

        if not finished then
            lib.notify({
                title = 'Cancelled',
                description = 'Search cancelled',
                type = 'error',
                duration = 2000,
            })
            return
        end

        local playerCoords = GetEntityCoords(PlayerPedId())
        local streetHash = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
        local streetName = GetStreetNameFromHashKey(streetHash)
        local locationHash = tostring(obj and GetEntityCoords(obj) or playerCoords)

        local result
        if searchData.kind == 'zone' then
            result = lib.callback.await('ox_inventory:searchZone', false, searchData.zoneId, locationHash, streetName)
        else
            result = lib.callback.await('ox_inventory:searchLocation', false, searchData.type, locationHash, streetName)
        end

        if not result then
            lib.notify({
                title = 'Search Failed',
                description = 'No response from server.',
                type = 'error',
                duration = 2500,
            })
            return
        end

        if result.success then
            if result.found then
                SendNUIMessage({
                    action = 'showScavengeLoot',
                    data = {
                        item = result.item,
                        label = result.label or result.item,
                        count = result.count or 1,
                        isBlueprint = result.isBlueprint or false,
                        xpGained = result.xpGained or 0,
                    }
                })

                if result.isBlueprint then
                    PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                else
                    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                end
            else
                SendNUIMessage({
                    action = 'showScavengeLoot',
                    data = {
                        nothingFound = true,
                        message = result.message or 'Nothing found here...',
                    }
                })
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
        else
            if result.error == 'cooldown' then
                lib.notify({
                    title = 'Recently Searched',
                    description = string.format('%s (%ds remaining)', result.message or 'Cooldown', result.remaining or 0),
                    type = 'error',
                    duration = 3000,
                })
            elseif result.error == 'inventory_full' then
                lib.notify({
                    title = 'Inventory Full',
                    description = result.message or 'Your inventory is full!',
                    type = 'error',
                    duration = 3000,
                })
            elseif result.error == 'out_of_zone' then
                lib.notify({
                    title = 'Too Far',
                    description = result.message or 'Leave and re-enter the search area.',
                    type = 'error',
                    duration = 3000,
                })
            else
                lib.notify({
                    title = 'Search Failed',
                    description = result.message or result.error or 'Unknown error',
                    type = 'error',
                    duration = 2500,
                })
            end
        end
    end)

    forceReleaseSearch(token)

    if not ok then
        lib.notify({
            title = 'Search Failed',
            description = 'Something went wrong while searching.',
            type = 'error',
            duration = 2500,
        })
    end
end

local function beginSearch(obj, searchData)
    CreateThread(function()
        PerformSearch(obj, searchData)
    end)
end

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)

    local factor = string.len(text) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 100)
    ClearDrawOrigin()
end

-- E-key proximity loop (fallback when not using ox_target eye)
CreateThread(function()
    while true do
        local sleep = 500

        if not isSearching then
            local obj, dist, searchData = GetClosestSearchable(ScavengingConfig.settings.maxDistance or 2.3)

            if obj and searchData then
                sleep = 0
                local objCoords = GetEntityCoords(obj)
                DrawText3D(objCoords.x, objCoords.y, objCoords.z + 0.5, ('[E] %s'):format(searchData.label))

                if IsControlJustPressed(0, 38) then
                    beginSearch(obj, searchData)
                end
            end
        end

        Wait(sleep)
    end
end)

-- ox_target integration
CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do Wait(100) end

    for _ = 1, 50 do
        if pcall(function() return exports.ox_target.addModel end) then break end
        Wait(100)
    end

    pcall(function()
        for locationType, config in pairs(ScavengingConfig.locations or {}) do
            exports.ox_target:addModel(config.model, {
                {
                    name = 'search_' .. locationType,
                    icon = 'fas fa-search',
                    label = config.label,
                    distance = ScavengingConfig.settings.maxDistance or 2.3,
                    onSelect = function(data)
                        beginSearch(data.entity, {
                            kind = 'location',
                            type = locationType,
                            label = config.label,
                            duration = config.duration,
                            animation = config.animation,
                        })
                    end,
                    canInteract = function()
                        return not isSearching and not (lib.progressActive and lib.progressActive())
                    end,
                },
            })
        end

        for zoneId, zone in pairs(ScavengingConfig.zones or {}) do
            exports.ox_target:addModel(zone.targetModels, {
                {
                    name = 'search_zone_' .. zoneId,
                    icon = 'fas fa-box-open',
                    label = zone.label,
                    distance = ScavengingConfig.settings.maxDistance or 2.3,
                    onSelect = function(data)
                        beginSearch(data.entity, {
                            kind = 'zone',
                            zoneId = zoneId,
                            zone = zone,
                            label = zone.label,
                            duration = zone.duration or 6000,
                            animation = zone.animation,
                        })
                    end,
                    canInteract = function()
                        if isSearching or (lib.progressActive and lib.progressActive()) then
                            return false
                        end
                        local playerCoords = GetEntityCoords(cache.ped)
                        return #(playerCoords - zone.coords) <= (zone.radius or 50.0)
                    end,
                },
            })
        end
    end)
end)

