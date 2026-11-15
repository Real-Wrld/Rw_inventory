if not lib then return end

local Config = lib.load('data.recycler')
if not Config then return end

local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'

local RecyclerData = {
    collectedOutputs = {},
    recyclerQueues = {},
    activeRecyclers = {},
}

local dataPath = 'data/recycler_data.json'

local function getPlayerIdentifier(source)
    local inv = Inventory(source)
    if inv and inv.owner then
        return inv.owner
    end

    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:find('license:', 1, true) then
            return id
        end
    end

    return tostring(source)
end

local function getRecyclerKey(recyclerIndex, source)
    if Config.syncRecyclers then
        return tostring(recyclerIndex)
    end

    return getPlayerIdentifier(source) .. ':' .. tostring(recyclerIndex)
end

local function cleanupOfflinePlayerData()
    if not Config.dataPersistence.cleanupOfflinePlayers or Config.syncRecyclers then
        return
    end

    local online = {}

    for _, playerSrc in ipairs(GetPlayers()) do
        online[getPlayerIdentifier(tonumber(playerSrc))] = true
    end

    for key in pairs(RecyclerData.recyclerQueues) do
        local identifier = key:match('^([^:]+):')
        if identifier and not online[identifier] then
            RecyclerData.recyclerQueues[key] = nil
        end
    end

    for key in pairs(RecyclerData.collectedOutputs) do
        local identifier = key:match('^([^:]+):')
        if identifier and not online[identifier] then
            RecyclerData.collectedOutputs[key] = nil
        end
    end
end

local function saveRecyclerData()
    if not Config.dataPersistence.enabled then return end

    SaveResourceFile(GetCurrentResourceName(), dataPath, json.encode({
        collectedOutputs = RecyclerData.collectedOutputs,
        recyclerQueues = RecyclerData.recyclerQueues,
        version = '1.0',
        timestamp = os.time(),
        syncMode = Config.syncRecyclers,
    }, { indent = true }), -1)
end

local function loadRecyclerData()
    if not Config.dataPersistence.enabled then return end

    local fileContent = LoadResourceFile(GetCurrentResourceName(), dataPath)
    if not fileContent then return end

    local parsed = json.decode(fileContent)
    if not parsed then return end

    RecyclerData.collectedOutputs = parsed.collectedOutputs or {}
    RecyclerData.recyclerQueues = parsed.recyclerQueues or {}
    RecyclerData.activeRecyclers = {}
    cleanupOfflinePlayerData()
end

local function getItemLabel(name)
    local item = Items(name)
    return item and item.label or name
end

local function completeRecycling(recyclerIndex, source, queue)
    local idxStr = tostring(recyclerIndex)
    RecyclerData.activeRecyclers[idxStr] = { status = 'idle' }

    local key = getRecyclerKey(recyclerIndex, source)
    RecyclerData.recyclerQueues[key] = {}

    local generatedOutputs = {}

    for _, qItem in ipairs(queue) do
        local recipe = Config.recipes[qItem.item]
        if recipe and math.random(1, 100) <= recipe.chance then
            for _, outItem in ipairs(recipe.outputs) do
                local amt = math.random(outItem.amount.min, outItem.amount.max) * qItem.count
                if amt > 0 then
                    generatedOutputs[#generatedOutputs + 1] = {
                        item = outItem.item,
                        amount = amt,
                        label = getItemLabel(outItem.item),
                    }
                end
            end
        end
    end

    RecyclerData.collectedOutputs[key] = RecyclerData.collectedOutputs[key] or {}
    local colOutputs = RecyclerData.collectedOutputs[key]

    for _, gen in ipairs(generatedOutputs) do
        local found = false
        for _, col in ipairs(colOutputs) do
            if col.item == gen.item then
                col.amount = col.amount + gen.amount
                found = true
                break
            end
        end

        if not found then
            colOutputs[#colOutputs + 1] = {
                item = gen.item,
                amount = gen.amount,
                label = gen.label,
            }
        end
    end

    if Config.dataPersistence.saveOnComplete then
        saveRecyclerData()
    end

    TriggerClientEvent('ox_inventory:recycler:complete', source, true, generatedOutputs)
    TriggerClientEvent('ox_inventory:recycler:recyclerCompleted', -1, recyclerIndex, {
        status = 'idle',
        outputs = colOutputs,
    })

    local target = Config.syncRecyclers and -1 or source
    TriggerClientEvent('ox_inventory:recycler:queueUpdated', target, recyclerIndex, {})
    TriggerClientEvent('ox_inventory:recycler:updateCollectedOutputs', -1, recyclerIndex, colOutputs)
end

CreateThread(function()
    while not shared.ready do Wait(100) end
    loadRecyclerData()
end)

CreateThread(function()
    while true do
        Wait(Config.dataPersistence.autoSaveInterval or 30000)
        saveRecyclerData()
    end
end)

RegisterNetEvent('ox_inventory:recycler:requestStateSync', function(recyclerIndex)
    local src = source
    local state = { queues = {}, recyclers = {}, collectedOutputs = {} }

    local indices = recyclerIndex and { recyclerIndex } or {}
    if not recyclerIndex then
        for i = 1, #Config.locations do
            indices[i] = i
        end
    end

    for _, idx in ipairs(indices) do
        local key = getRecyclerKey(idx, src)
        state.queues[tostring(idx)] = RecyclerData.recyclerQueues[key] or {}
        state.recyclers[tostring(idx)] = RecyclerData.activeRecyclers[tostring(idx)] or { status = 'idle' }
        state.collectedOutputs[tostring(idx)] = RecyclerData.collectedOutputs[key] or {}
    end

    TriggerClientEvent('ox_inventory:recycler:fullStateSync', src, state)
end)

RegisterNetEvent('ox_inventory:recycler:checkAvailability', function(index)
    local src = source
    local idxStr = tostring(index)
    local active = RecyclerData.activeRecyclers[idxStr]

    if active and active.status == 'processing' then
        if active.startedBy == src then
            TriggerClientEvent('ox_inventory:recycler:availability', src, index, true, 'owner_access')
        elseif Config.syncRecyclers then
            TriggerClientEvent('ox_inventory:recycler:availability', src, index, false, 'busy')
        else
            TriggerClientEvent('ox_inventory:recycler:availability', src, index, true, nil)
        end
    else
        TriggerClientEvent('ox_inventory:recycler:availability', src, index, true, nil)
    end
end)

RegisterNetEvent('ox_inventory:recycler:getRecipes', function()
    TriggerClientEvent('ox_inventory:recycler:receiveRecipes', source, Config.recipes)
end)

RegisterNetEvent('ox_inventory:recycler:getInventory', function()
    local src = source
    local left = Inventory(src)
    if not left then return end

    local formatted = {}

    for _, slot in pairs(left.items) do
        if slot and slot.name and slot.count and slot.count > 0 and Config.recipes[slot.name] then
            formatted[#formatted + 1] = {
                item = slot.name,
                name = slot.name,
                label = slot.label or getItemLabel(slot.name),
                count = slot.count,
                canRecycle = true,
            }
        end
    end

    TriggerClientEvent('ox_inventory:recycler:receiveInventory', src, formatted)
end)

RegisterNetEvent('ox_inventory:recycler:getCollectedOutputs', function(recyclerIndex)
    local src = source
    local key = getRecyclerKey(recyclerIndex, src)
    TriggerClientEvent('ox_inventory:recycler:receiveCollectedOutputs', src, RecyclerData.collectedOutputs[key] or {})
end)

RegisterNetEvent('ox_inventory:recycler:addToQueue', function(recyclerIndex, itemName, count)
    local src = source
    local left = Inventory(src)
    if not left or not Config.recipes[itemName] then return end

    count = math.floor(tonumber(count) or 0)
    if count < 1 then return end

    if Inventory.GetItemCount(left, itemName) < count then return end
    if not Inventory.RemoveItem(left, itemName, count) then return end

    local key = getRecyclerKey(recyclerIndex, src)
    RecyclerData.recyclerQueues[key] = RecyclerData.recyclerQueues[key] or {}

    local queue = RecyclerData.recyclerQueues[key]
    local found = false

    for _, qItem in ipairs(queue) do
        if qItem.item == itemName then
            qItem.count = qItem.count + count
            found = true
            break
        end
    end

    if not found then
        queue[#queue + 1] = {
            item = itemName,
            count = count,
            label = getItemLabel(itemName),
        }
    end

    if Config.dataPersistence.saveOnStart then
        saveRecyclerData()
    end

    local target = Config.syncRecyclers and -1 or src
    TriggerClientEvent('ox_inventory:recycler:queueUpdated', target, recyclerIndex, queue)
end)

RegisterNetEvent('ox_inventory:recycler:removeFromQueue', function(recyclerIndex, queueIndex)
    local src = source
    local left = Inventory(src)
    if not left then return end

    local key = getRecyclerKey(recyclerIndex, src)
    local queue = RecyclerData.recyclerQueues[key]
    if not queue then return end

    local luaIndex = (tonumber(queueIndex) or -1) + 1
    local qItem = queue[luaIndex]
    if not qItem then return end

    Inventory.AddItem(left, qItem.item, qItem.count)
    table.remove(queue, luaIndex)

    if Config.dataPersistence.saveOnStart then
        saveRecyclerData()
    end

    local target = Config.syncRecyclers and -1 or src
    TriggerClientEvent('ox_inventory:recycler:queueUpdated', target, recyclerIndex, queue)
end)

RegisterNetEvent('ox_inventory:recycler:clearQueue', function(recyclerIndex)
    local src = source
    local left = Inventory(src)
    if not left then return end

    local key = getRecyclerKey(recyclerIndex, src)
    local queue = RecyclerData.recyclerQueues[key]
    if not queue then return end

    for _, qItem in ipairs(queue) do
        Inventory.AddItem(left, qItem.item, qItem.count)
    end

    RecyclerData.recyclerQueues[key] = {}

    if Config.dataPersistence.saveOnStart then
        saveRecyclerData()
    end

    local target = Config.syncRecyclers and -1 or src
    TriggerClientEvent('ox_inventory:recycler:queueUpdated', target, recyclerIndex, {})
end)

RegisterNetEvent('ox_inventory:recycler:start', function(recyclerIndex)
    local src = source
    local key = getRecyclerKey(recyclerIndex, src)
    local queue = RecyclerData.recyclerQueues[key]
    if not queue or #queue == 0 then return end

    local idxStr = tostring(recyclerIndex)
    local active = RecyclerData.activeRecyclers[idxStr]
    if active and active.status == 'processing' and Config.syncRecyclers then
        return
    end

    local processingTime = Config.recycleTime
    for _, qItem in ipairs(queue) do
        local recipe = Config.recipes[qItem.item]
        local itemTime = recipe and recipe.time or Config.recycleTimePerItem
        processingTime = processingTime + (itemTime * qItem.count)
    end

    processingTime = math.min(processingTime, Config.maxRecycleTime)

    RecyclerData.activeRecyclers[idxStr] = {
        status = 'processing',
        startedBy = src,
        processingTime = processingTime,
        startTime = os.time(),
        endTime = os.time() + (processingTime / 1000),
    }

    if Config.dataPersistence.saveOnStart then
        saveRecyclerData()
    end

    TriggerClientEvent('ox_inventory:recycler:startProcess', src, processingTime)
    TriggerClientEvent('ox_inventory:recycler:recyclerStarted', -1, recyclerIndex, {
        startedBy = src,
        processingTime = processingTime,
    })

    CreateThread(function()
        local startTime = GetGameTimer()
        local totalDuration = processingTime
        local endTime = startTime + totalDuration
        local queueCopy = lib.table.deepclone(queue)

        while GetGameTimer() < endTime do
            Wait(500)

            local activeState = RecyclerData.activeRecyclers[idxStr]
            if not activeState or activeState.status ~= 'processing' then
                return
            end

            local now = GetGameTimer()
            local elapsed = now - startTime
            local progress = math.min((elapsed / totalDuration) * 100, 100)
            local timeLeft = math.max(0, math.ceil((endTime - now) / 1000))

            TriggerClientEvent('ox_inventory:recycler:progress', -1, {
                recyclerIndex = recyclerIndex,
                progress = progress,
                timeLeft = timeLeft,
            })
        end

        completeRecycling(recyclerIndex, src, queueCopy)
    end)
end)

RegisterNetEvent('ox_inventory:recycler:cancel', function(recyclerIndex)
    local src = source
    local idxStr = tostring(recyclerIndex)
    local active = RecyclerData.activeRecyclers[idxStr]

    if active and active.status == 'processing' and active.startedBy == src then
        RecyclerData.activeRecyclers[idxStr] = { status = 'idle' }

        if Config.dataPersistence.saveOnCancel then
            saveRecyclerData()
        end

        TriggerClientEvent('ox_inventory:recycler:recyclerCancelled', -1, recyclerIndex, { status = 'idle' })
    end
end)

RegisterNetEvent('ox_inventory:recycler:collectItem', function(recyclerIndex, itemName, count)
    local src = source
    local left = Inventory(src)
    if not left then return end

    local key = getRecyclerKey(recyclerIndex, src)
    local colOutputs = RecyclerData.collectedOutputs[key]
    if not colOutputs then return end

    count = math.floor(tonumber(count) or 0)
    if count < 1 then return end

    for idx, col in ipairs(colOutputs) do
        if col.item == itemName then
            local amountToGive = math.min(col.amount, count)
            if amountToGive > 0 and Inventory.AddItem(left, itemName, amountToGive) then
                col.amount = col.amount - amountToGive
                if col.amount <= 0 then
                    table.remove(colOutputs, idx)
                end

                if Config.dataPersistence.saveOnComplete then
                    saveRecyclerData()
                end

                TriggerClientEvent('ox_inventory:recycler:receiveCollectedOutputs', src, colOutputs)
                TriggerClientEvent('ox_inventory:recycler:updateCollectedOutputs', -1, recyclerIndex, colOutputs)
            end
            break
        end
    end
end)

RegisterNetEvent('ox_inventory:recycler:collectAll', function(recyclerIndex)
    local src = source
    local left = Inventory(src)
    if not left then return end

    local key = getRecyclerKey(recyclerIndex, src)
    local colOutputs = RecyclerData.collectedOutputs[key]
    if not colOutputs or #colOutputs == 0 then return end

    for _, col in ipairs(colOutputs) do
        Inventory.AddItem(left, col.item, col.amount)
    end

    RecyclerData.collectedOutputs[key] = {}

    if Config.dataPersistence.saveOnComplete then
        saveRecyclerData()
    end

    TriggerClientEvent('ox_inventory:recycler:receiveCollectedOutputs', src, {})
    TriggerClientEvent('ox_inventory:recycler:updateCollectedOutputs', -1, recyclerIndex, {})
end)

AddEventHandler('playerDropped', function()
    local src = source

    for idx, active in pairs(RecyclerData.activeRecyclers) do
        if active.status == 'processing' and active.startedBy == src then
            RecyclerData.activeRecyclers[idx] = { status = 'idle' }
            TriggerClientEvent('ox_inventory:recycler:recyclerCancelled', -1, tonumber(idx) or idx, { status = 'idle' })
        end
    end

    if Config.dataPersistence.saveOnPlayerDisconnect then
        saveRecyclerData()
    end
end)
