local Utils = require 'modules.utils.client'
local Target = require 'modules.utils.target_client'

-- Trading State
local tradingActive = false
local currentSession = nil
local isPlayer1 = false

Target.whenReady(function()
	exports.ox_target:addGlobalPlayer({
		{
			name = 'request_trade',
			icon = 'fa-solid fa-handshake',
			label = 'Request Trade',
			onSelect = function(data)
				TriggerServerEvent('ox_inventory:requestTrade',
					GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity)))
			end,
			canInteract = function()
				return not tradingActive and not IsPedInAnyVehicle(PlayerPedId(), false)
			end
		}
	})
end)

-- Receive Request
RegisterNetEvent('ox_inventory:receiveTradeRequest', function(senderId)
    local alert = lib.alertDialog({
        header = 'Trade Request',
        content = 'Player ' .. senderId .. ' wants to trade with you.',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Accept',
            cancel = 'Decline'
        }
    })

    if alert == 'confirm' then
        TriggerServerEvent('ox_inventory:acceptTrade', senderId)
    else
        -- Optional: notify decline
    end
end)

-- Open UI
RegisterNetEvent('ox_inventory:openTrade', function(data)
    tradingActive = true
    currentSession = data.sessionId
    isPlayer1 = data.isPlayer1

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openTrade',
        data = {
            tradeId = data.sessionId,
            partnerId = data.partner,
            partnerName = 'Player ' .. data.partner -- Placeholder name
        }
    })
end)

-- Update State - Adapter for App.tsx
RegisterNetEvent('ox_inventory:updateTradeState', function(state)
    if not tradingActive then return end

    local myData = isPlayer1 and state.player1 or state.player2
    local theirData = isPlayer1 and state.player2 or state.player1

    -- Convert items object to array for UI
    local myItemsArray = {}
    for slot, item in pairs(myData.items) do
        item.slot = tonumber(slot)
        table.insert(myItemsArray, item)
    end

    local theirItemsArray = {}
    for slot, item in pairs(theirData.items) do
        item.slot = tonumber(slot)
        table.insert(theirItemsArray, item)
    end

    SendNUIMessage({
        action = 'updateMyTradeItems',
        data = myItemsArray
    })

    SendNUIMessage({
        action = 'updateTheirTradeItems',
        data = theirItemsArray
    })

    SendNUIMessage({
        action = 'setTheirConfirmed',
        data = theirData.confirmed
    })

    -- Also sync lock state if needed, though App.tsx didn't seem to have a specific handler for it besides generic updates
end)

-- Trade Complete
RegisterNetEvent('ox_inventory:tradeComplete', function(success)
    if success then
        lib.notify({ type = 'success', description = 'Trade completed successfully!' })
        SendNUIMessage({ action = 'closeTrade' })
    else
        lib.notify({ type = 'error', description = 'Trade failed.' })
    end
    tradingActive = false
    currentSession = nil
    SetNuiFocus(false, false)
end)

-- Trade Closed remotely
RegisterNetEvent('ox_inventory:tradeClosed', function()
    if tradingActive then
        SendNUIMessage({ action = 'closeTrade' })
        tradingActive = false
        currentSession = nil
        SetNuiFocus(false, false)
        lib.notify({ type = 'error', description = 'Trade cancelled.' })
    end
end)

-- NUI Callbacks matching TradePanel.tsx

RegisterNUICallback('cancelTrade', function(data, cb)
    TriggerServerEvent('ox_inventory:cancelTrade')
    tradingActive = false
    currentSession = nil
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('addTradeItem', function(data, cb)
    -- data contains slot
    -- We need to get the item count? TradePanel sends { slot: ... }
    -- We might need to ask input or default to 1.
    -- TradePanel drag drop logic sends: dispatch(addMyItem(...)) then fetchNui('addTradeItem', { slot })
    -- It assumes count is handled?
    -- Creating a payload with default count 1 for now or reading inventory.
    -- Better: Client reads inventory to get count? Or server handles it?
    -- I'll send basic info to server and let server handle logic or use 1.
    -- Ideally, drag drop should send count.

    -- For now, let's assume whole stack or 1.
    -- We can get the item from the slot using Exports or internal util?
    TriggerServerEvent('ox_inventory:updateTradeOffer', { type = 'item', slot = data.slot, count = 1 })
    cb('ok')
end)

RegisterNUICallback('removeTradeItem', function(data, cb)
    TriggerServerEvent('ox_inventory:updateTradeOffer', { type = 'remove', slot = data.slot })
    cb('ok')
end)

RegisterNUICallback('confirmTrade', function(data, cb)
    TriggerServerEvent('ox_inventory:lockTrade', true) -- First lock
    TriggerServerEvent('ox_inventory:confirmTrade')    -- Then confirm
    cb('ok')
end)
