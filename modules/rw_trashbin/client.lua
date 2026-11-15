if not lib then return end

local Target = require 'modules.utils.target_client'

local Trashbin = {}
local validModels = {}

for _, config in pairs(RWTrashbinsConfig) do
    for _, model in ipairs(config.models) do
        validModels[joaat(model)] = config
    end
end

function Trashbin.open(entity)
    if cache.vehicle then return end
    
    local coords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)
    
    local stashId = lib.callback.await("rw_inventory:openTrashbin", false, model, coords)
    if stashId then
        exports.ox_inventory:openInventory("stash", stashId)
    end
end

Target.whenReady(function()
    exports.ox_target:addGlobalObject({
        {
            name = "rw_inventory:trashbin",
            icon = "fas fa-dumpster",
            distance = 2.0,
            canInteract = function(entity)
                return validModels[GetEntityModel(entity)] ~= nil
            end,
            label = function(entity)
                local modelConfig = validModels[GetEntityModel(entity)]
                if modelConfig then
                    local label = string.lower(modelConfig.label)
                    local formatted = string.format("Search %s", label)
                    if formatted then return formatted end
                end
                return "Search trash"
            end,
            onSelect = function(data)
                Trashbin.open(data.entity)
            end
        }
    })
end)

return Trashbin

