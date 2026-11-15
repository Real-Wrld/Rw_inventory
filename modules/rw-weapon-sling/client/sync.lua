local Props = require 'modules.rw-weapon-sling.client.props'

local Remote = {
    entries = {},
}

local function destroyRemote(playerId)
    local bucket = Remote.entries[playerId]
    if not bucket then return end
    for i = 1, #bucket do
        Props.destroyEntry(bucket[i])
    end
    Remote.entries[playerId] = nil
end

function Remote.apply(playerId, ped, payload)
    destroyRemote(playerId)
    if playerId == cache.serverId then return end
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    if not payload or payload.enabled == false or not payload.slings then return end

    local bucket = {}
    for i = 1, #payload.slings do
        local entry = Props.spawnAttached(ped, payload.slings[i])
        if entry then bucket[#bucket + 1] = entry end
    end
    Remote.entries[playerId] = bucket
end

function Remote.clearAll()
    for playerId in pairs(Remote.entries) do
        destroyRemote(playerId)
    end
end

AddStateBagChangeHandler('rwSlings', nil, function(bagName, _, value)
    local playerId = GetPlayerFromStateBagName(bagName)
    if playerId == 0 then return end
    if playerId == cache.serverId then return end
    local ped = GetPlayerPed(playerId)
    Remote.apply(playerId, ped, value)
end)

return Remote
