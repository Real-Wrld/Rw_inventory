if not lib then return end

local function loadModule(name)
    local ok, err = pcall(require, name)
    if not ok then
        warn(('[ox_inventory] RW client module failed (%s): %s'):format(name, err))
    end
    return ok
end

-- Load after core inventory client finishes (events, NUI, PlayerData handlers).
CreateThread(function()
    Wait(0)

    local order = {
        'modules.rw_bridge.load_client',
        'modules.rw_config.client',
        'modules.rw_appearance.client',
        'modules.rw_weapon_customization.client',
        'modules.rw_throw.client',
        'modules.rw_trashbin.client',
        'modules.rw_integration.client',
        'modules.forge.client',
        'modules.recycler.client',
    }

    for i = 1, #order do
        loadModule(order[i])
    end
end)
