if RWBridgeSharedLoaded then return end
RWBridgeSharedLoaded = true

local resource = GetCurrentResourceName()

local function run(path)
    local code = LoadResourceFile(resource, path)
    if not code then
        error(('RW bridge missing shared file: %s'):format(path))
    end

    local chunk, err = load(code, ('@@%s/%s'):format(resource, path))
    if not chunk then
        error(err)
    end

    chunk()
end

run('modules/rw_bridge/config.lua')
run('modules/rw_bridge/shared/utils.lua')

run('modules/rw_bridge/modules/frameworks/esx.lua')
run('modules/rw_bridge/modules/frameworks/qbcore.lua')
run('modules/rw_bridge/modules/frameworks/qbox.lua')

run('modules/rw_bridge/modules/inventories/ox_inventory.lua')
run('modules/rw_bridge/modules/inventories/qb_inventory.lua')
run('modules/rw_bridge/modules/inventories/qs_inventory.lua')
run('modules/rw_bridge/modules/inventories/esx_inventory.lua')
run('modules/rw_bridge/modules/inventories/codem_inventory.lua')

run('modules/rw_bridge/modules/appearances/illenium_appearance.lua')
run('modules/rw_bridge/modules/appearances/qb_clothing.lua')
run('modules/rw_bridge/modules/appearances/esx_skin.lua')

run('modules/rw_bridge/shared/init.lua')
