-- Trade System Client Module
-- Handles trade UI and player interactions

local activeTrade = nil
local tradeItems = {}

-- Request trade with nearby player (command-based)
RegisterCommand('trade', function(source, args)
    if activeTrade then
        return lib.notify({ title = 'Trade', description = 'Already in a trade', type = 'error' })
    end

    local targetId = tonumber(args[1])
    if not targetId then
        -- If no ID specified, get nearest player
        local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 3.0, false)
        if #players > 0 then
            targetId = GetPlayerServerId(players[1].id)
        end
    end

    if not targetId then
        return lib.notify({ title = 'Trade', description = 'No player nearby', type = 'error' })
    end

    TriggerServerEvent('ox_inventory:requestTrade', targetId)
end, false)

-- ox_target integration for trade
if GetResourceState('ox_target') == 'started' then
    exports.ox_target:addGlobalPlayer({
        {
            name = 'trade_player',
            icon = 'fas fa-handshake',
            label = 'Trade',
            distance = 3.0,
            onSelect = function(data)
                if activeTrade then
                    return lib.notify({ title = 'Trade', description = 'Already in a trade', type = 'error' })
                end
                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                TriggerServerEvent('ox_inventory:requestTrade', targetId)
            end
        }
    })
end

-- Receive trade request
RegisterNetEvent('ox_inventory:tradeRequest', function(requesterId, requesterName)
    SendNUIMessage({
        action = 'tradeRequest',
        data = {
            requesterId = requesterId,
            requesterName = requesterName
        }
    })
end)

-- Trade request accepted, open trade window
RegisterNetEvent('ox_inventory:openTrade', function(partnerId, partnerName, tradeId)
    activeTrade = {
        partnerId = partnerId,
        partnerName = partnerName,
        tradeId = tradeId
    }
    tradeItems = {}

    if not LocalPlayer.state.invOpen then
        client.openInventory()
    end

    SendNUIMessage({
        action = 'openTrade',
        data = {
            partnerId = partnerId,
            partnerName = partnerName,
            tradeId = tradeId
        }
    })
end)

-- Trade closed
RegisterNetEvent('ox_inventory:closeTrade', function()
    activeTrade = nil
    tradeItems = {}

    SendNUIMessage({
        action = 'closeTrade'
    })
end)

-- Update my trade items (from server)
RegisterNetEvent('ox_inventory:updateMyTradeItems', function(items)
    tradeItems = items
    SendNUIMessage({
        action = 'updateMyTradeItems',
        data = items
    })
end)

-- Update partner's trade items
RegisterNetEvent('ox_inventory:updateTheirTradeItems', function(items)
    SendNUIMessage({
        action = 'updateTheirTradeItems',
        data = items
    })
end)

-- Partner confirmed
RegisterNetEvent('ox_inventory:setTheirConfirmed', function(confirmed)
    SendNUIMessage({
        action = 'setTheirConfirmed',
        data = confirmed
    })
end)

-- Trade completed notification
RegisterNetEvent('ox_inventory:tradeComplete', function(success)
    activeTrade = nil
    tradeItems = {}

    if success then
        lib.notify({ title = 'Trade', description = 'Trade completed successfully!', type = 'success' })
    end
end)

-- NUI Callbacks
RegisterNUICallback('acceptTrade', function(data, cb)
    TriggerServerEvent('ox_inventory:acceptTrade')
    cb('ok')
end)

RegisterNUICallback('declineTrade', function(data, cb)
    TriggerServerEvent('ox_inventory:declineTrade')
    cb('ok')
end)

RegisterNUICallback('cancelTradeRequest', function(data, cb)
    TriggerServerEvent('ox_inventory:cancelTradeRequest')
    cb('ok')
end)

RegisterNUICallback('addTradeItem', function(data, cb)
    if not activeTrade then return cb('error') end
    TriggerServerEvent('ox_inventory:addTradeItem', data.slot, data.count or 1)
    cb('ok')
end)

RegisterNUICallback('removeTradeItem', function(data, cb)
    if not activeTrade then return cb('error') end
    TriggerServerEvent('ox_inventory:removeTradeItem', data.slot)
    cb('ok')
end)

RegisterNUICallback('confirmTrade', function(data, cb)
    if not activeTrade then return cb('error') end
    TriggerServerEvent('ox_inventory:confirmTrade')
    cb('ok')
end)

RegisterNUICallback('cancelTrade', function(data, cb)
    if activeTrade then
        TriggerServerEvent('ox_inventory:cancelTrade')
    end
    activeTrade = nil
    tradeItems = {}
    cb('ok')
end)

return {}
