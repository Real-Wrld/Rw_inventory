if not lib then return end

local MarketPed = nil
local MarketBlip = nil
local MarketTargetAdded = false
local MARKET_COORDS = vec4(1131.16, -482.34, 64.91, 158.17) -- Mirror Park
local PED_MODEL = 'mp_m_shopkeep_01'

local function openMarketUi()
    lib.callback.await('ox_market:claimPending', false)
    local listings = lib.callback.await('ox_market:getListings', false)
    local requests = lib.callback.await('ox_market:getRequests', false)
    local myListings = lib.callback.await('ox_market:getMyListings', false)
    local transactions = lib.callback.await('ox_market:getTransactions', false)
    local sellableItems = lib.callback.await('ox_market:getSellableItems', false)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMarket',
        data = {
            listings = listings or {},
            requests = requests or {},
            myListings = myListings or {},
            transactions = transactions or {},
            sellableItems = sellableItems or {}
        }
    })
end

local function registerMarketTarget()
    if MarketTargetAdded then return true end
    if not MarketPed or not DoesEntityExist(MarketPed) then return false end
    if GetResourceState('ox_target') ~= 'started' then return false end

    local ok = pcall(function()
        exports.ox_target:addLocalEntity(MarketPed, {
            {
                name = 'open_market',
                icon = 'fas fa-gavel',
                label = 'Market / Auction',
                distance = 2.5,
                onSelect = openMarketUi,
            }
        })
    end)

    if ok then
        MarketTargetAdded = true
    end

    return ok
end

-- ============================================================================
-- Create NPC, blip & ox_target
-- ============================================================================

CreateThread(function()
    local blip = AddBlipForCoord(MARKET_COORDS.x, MARKET_COORDS.y, MARKET_COORDS.z)
    SetBlipSprite(blip, 605)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 5) -- yellow
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Market/Auction')
    EndTextCommandSetBlipName(blip)
    MarketBlip = blip

    lib.requestModel(PED_MODEL)

    MarketPed = CreatePed(4, joaat(PED_MODEL), MARKET_COORDS.x, MARKET_COORDS.y, MARKET_COORDS.z, MARKET_COORDS.w,
        false, true)

    if not DoesEntityExist(MarketPed) then
        return
    end

    SetEntityInvincible(MarketPed, true)
    FreezeEntityPosition(MarketPed, true)
    SetBlockingOfNonTemporaryEvents(MarketPed, true)
    SetModelAsNoLongerNeeded(joaat(PED_MODEL))

    -- Retry until ox_target is up (common after ensure/restart order)
    for _ = 1, 30 do
        if registerMarketTarget() then break end
        Wait(1000)
    end
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'ox_target' then
        MarketTargetAdded = false
        registerMarketTarget()
    end
end)

--- GPS / help: /market sets a waypoint to the Mirror Park Market NPC
RegisterCommand('market', function()
    SetNewWaypoint(MARKET_COORDS.x, MARKET_COORDS.y)
    lib.notify({
        title = 'Market / Auction',
        description = 'Waypoint set — Mirror Park. Target the shopkeeper to open buy-now & auctions.',
        type = 'inform',
        duration = 6000,
    })
end, false)

TriggerEvent('chat:addSuggestion', '/market', 'Set a GPS waypoint to the player Market/Auction')

-- ============================================================================
-- Refresh helper: fetch fresh data and send to NUI
-- ============================================================================

local function refreshMarketData()
    local listings = lib.callback.await('ox_market:getListings', false)
    local requests = lib.callback.await('ox_market:getRequests', false)
    local myListings = lib.callback.await('ox_market:getMyListings', false)
    local transactions = lib.callback.await('ox_market:getTransactions', false)
    local sellableItems = lib.callback.await('ox_market:getSellableItems', false)

    SendNUIMessage({
        action = 'refreshMarket',
        data = {
            listings = listings or {},
            requests = requests or {},
            myListings = myListings or {},
            transactions = transactions or {},
            sellableItems = sellableItems or {}
        }
    })
end

-- ============================================================================
-- NUI Callbacks
-- ============================================================================

RegisterNUICallback('closeMarket', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('market:buyItem', function(data, cb)
    local success, err = lib.callback.await('ox_market:buyItem', false, data.id)
    if success then
        refreshMarketData()
    end
    cb({ success = success, error = err })
end)

RegisterNUICallback('market:placeBid', function(data, cb)
    local success, err = lib.callback.await('ox_market:placeBid', false, data.id, data.amount)
    if success then
        refreshMarketData()
    end
    cb({ success = success, error = err })
end)

RegisterNUICallback('market:getSellableItems', function(_, cb)
    local items = lib.callback.await('ox_market:getSellableItems', false)
    cb({ items = items or {} })
end)

RegisterNUICallback('market:createListing', function(data, cb)
    local result = lib.callback.await('ox_market:createListing', false, data)
    if result and result.success then
        refreshMarketData()
    end
    cb(result or { success = false, error = 'unknown' })
end)

RegisterNUICallback('market:cancelListing', function(data, cb)
    local success, err = lib.callback.await('ox_market:cancelListing', false, data.id)
    if success then
        refreshMarketData()
    end
    cb({ success = success, error = err })
end)

RegisterNUICallback('market:createRequest', function(data, cb)
    local result = lib.callback.await('ox_market:createRequest', false, data)
    if result and result.success then
        refreshMarketData()
    end
    cb(result or { success = false, error = 'unknown' })
end)

RegisterNUICallback('market:fulfillRequest', function(data, cb)
    local success, err = lib.callback.await('ox_market:fulfillRequest', false, data.requestId)
    if success then
        refreshMarketData()
    end
    cb({ success = success, error = err })
end)

RegisterNUICallback('market:collectFulfilled', function(data, cb)
    local success, err = lib.callback.await('ox_market:collectFulfilled', false, data.requestId)
    if success then
        refreshMarketData()
    end
    cb({ success = success, error = err })
end)

RegisterNUICallback('market:cancelRequest', function(data, cb)
    local success, err = lib.callback.await('ox_market:cancelRequest', false, data.requestId)
    if success then
        refreshMarketData()
    end
    cb({ success = success, error = err })
end)

RegisterNUICallback('market:searchListings', function(data, cb)
    local listings = lib.callback.await('ox_market:getListings', false, data.filters)
    cb({ listings = listings or {} })
end)

RegisterNUICallback('market:refreshData', function(_, cb)
    refreshMarketData()
    cb('ok')
end)

-- ============================================================================
-- Cleanup
-- ============================================================================

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if MarketPed and DoesEntityExist(MarketPed) then
            DeleteEntity(MarketPed)
        end
        if MarketBlip and DoesBlipExist(MarketBlip) then
            RemoveBlip(MarketBlip)
        end
    end
end)
