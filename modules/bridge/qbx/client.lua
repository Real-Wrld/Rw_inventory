AddStateBagChangeHandler('isLoggedIn', ('player:%s'):format(cache.serverId), function(_, _, value)
    if not value then client.onLogout() end
end)

RegisterNetEvent('qbx_core:client:onGroupUpdate', function(groupName, groupGrade)
    local groups = PlayerData.groups
    if not groupGrade then
        groups[groupName] = nil
    else
        groups[groupName] = groupGrade
    end
    client.setPlayerData('groups', groups)
end)

RegisterNetEvent('qbx_core:client:setGroups', function(groups)
    client.setPlayerData('groups', groups)
end)

---@diagnostic disable-next-line: duplicate-set-field
function client.setPlayerStatus(values)
    local playerState = LocalPlayer.state
    for name, value in pairs(values) do
        -- compatibility for ESX style values
        if value > 100 or value < -100 then
            value = value * 0.0001
        end

        local current = playerState[name]
        if type(current) ~= 'number' then current = 0 end
        playerState:set(name, current + value, true)
    end
end
