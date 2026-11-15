

Target = Target or {}

CreateThread(function()
    if Config.Target ~= 'qb-target' then
        return
    end

    function Target:addTargetEntity(entity, data)
        exports['qb-target']:AddTargetEntity(entity, {
            options = {
              { 
                icon = data.icon or false, 
                label = data.label, 
                action = function(entity) 
                    data.action(entity)
                end,
                canInteract = function(entity) 
                  if not entity then return false end
                  return data.canInteract(entity)
                end,
              }
            },
            distance = 2.5, 
        })

        return data.label
    end

    function Target:removeTargetEntity(entity, contextId)
        exports['qb-target']:RemoveTargetEntity(entity, contextId)
    end

    function Target:addGlobalPed(data)
        exports['qb-target']:AddGlobalPed({
            options = {
                { 
                icon = data.icon or false, 
                label = data.label,
                action = function(entity) 
                    if IsPedAPlayer(entity) then return false end 
                    data.action(entity)
                end,
                canInteract = function(entity) 
                    if IsPedAPlayer(entity) then return false end 
                    return data.canInteract(entity)
                end,
                }
            },
            distance = 2.5,
        })

        return data.label
    end

    function Target:removeGlobalPed(contextId)
        exports['qb-target']:RemoveGlobalPed(contextId)
    end

    function Target:addTargetModel(models, data)
        exports['qb-target']:AddTargetModel(models, {
            options = {
                {
                    icon = data.icon or false,
                    label = data.label,
                    action = function(entity)
                        data.action(entity)
                    end,
                    canInteract = function(entity)
                        return data.canInteract(entity)
                    end,
                }
            },
            distance = 2.5
        })
    end

    local zoneCounter = 0

    function Target:addTargetZone(coords, radius, data)
        zoneCounter = zoneCounter + 1
        local zoneName = "bablo_ground_zone_" .. zoneCounter

        exports['qb-target']:AddCircleZone(zoneName, coords, radius or 0.5, {
            name = zoneName,
            useZ = true,
        }, {
            options = {
                {
                    icon = data.icon or false,
                    label = data.label,
                    action = function()
                        if data.action then data.action() end
                    end,
                    canInteract = function()
                        if data.canInteract then return data.canInteract() end
                        return true
                    end,
                }
            },
            distance = data.distance or 2.5,
        })

        return zoneName
    end

    function Target:removeTargetZone(zoneName)
        if not zoneName then return end
        exports['qb-target']:RemoveZone(zoneName)
    end
end)

