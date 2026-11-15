if not lib then return end
if RWBridgeClientLoaded then return end
RWBridgeClientLoaded = true

require 'modules.rw_bridge.load_shared'

local resource = GetCurrentResourceName()

local function run(path)
    local code = LoadResourceFile(resource, path)
    if not code then
        error(('RW bridge missing client file: %s'):format(path))
    end

    local chunk, err = load(code, ('@@%s/%s'):format(resource, path))
    if not chunk then
        error(err)
    end

    chunk()
end

run('modules/rw_bridge/client/framework.lua')
run('modules/rw_bridge/client/player.lua')
run('modules/rw_bridge/client/callbacks.lua')
run('modules/rw_bridge/client/inventory.lua')
run('modules/rw_bridge/client/notifications.lua')
run('modules/rw_bridge/client/progressbar.lua')
run('modules/rw_bridge/client/ui.lua')
run('modules/rw_bridge/client/appearance.lua')
run('modules/rw_bridge/client/main.lua')
