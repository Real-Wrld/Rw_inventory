if not lib then return end

lib.callback.register("rw_inventory:openTrashbin", function(source, model, coords)
    local stashId = "trashbin_" .. math.floor(coords.x) .. "_" .. math.floor(coords.y)
    
    exports.ox_inventory:RegisterStash(stashId, "Trash Bin", 20, 50000, false)
    
    return stashId
end)

