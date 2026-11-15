if not lib then return end

local modules = {
    'modules.rw_appearance.server',
    'modules.rw_throw.server',
    'modules.rw_trashbin.server',
    'modules.rw_rename.server',
}

for i = 1, #modules do
    local name = modules[i]
    local ok, err = pcall(require, name)
    if not ok then
        lib.print.error(('[ox_inventory] RW server module failed (%s): %s'):format(name, err))
    end
end
