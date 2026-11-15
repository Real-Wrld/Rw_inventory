--  REALWRLD Software® · ox_inventory · shared config loader
-- ═════════════════════════════════════════════════════════════
--
--  config.lua is ~87 KB of Lua. Reading it with LoadResourceFile,
--  compiling it with load() and RUNNING it is not free, and every
--  module that did it kept its own private copy of the resulting
--  ~thousand-entry table alive for the whole session.
--
--  Before this module the file was parsed, compiled and executed:
--    • modules/items/shared.lua      (client AND server)
--    • modules/rwadmin/server.lua (server)
--    • modules/rwclothing/*.lua   (client AND server)
--  …i.e. three full parses per side, three retained copies.
--
--  Now it happens ONCE per side and every consumer shares the result.
--  The table is exactly what config.lua assigns to `RWInv`, so
--  callers keep reading the same keys they always did.
--
--  Treat the returned table as READ-ONLY: it is shared, so mutating it
--  would change what every other module sees.
-- ═════════════════════════════════════════════════════════════

local config

---Returns the buyer-editable RWInv table from config.lua.
---Parsed on first call, cached for the lifetime of the resource.
---Always returns a table (empty if config.lua is missing or broken),
---so callers never have to nil-check.
---@return table
local function getConfig()
    if config then return config end

    config = {}

    local data = LoadResourceFile(GetCurrentResourceName(), 'config.lua')
    if not data then return config end

    -- Sandbox with _G as fallback: config.lua only assigns globals, and
    -- an inherited _G keeps any helper it references working.
    local env = setmetatable({}, { __index = _G })
    local chunk = load(data, '@config.lua', 't', env)
    if not chunk then return config end

    if not pcall(chunk) then return config end

    if type(env.RWInv) == 'table' then config = env.RWInv end

    return config
end

-- RW rename (2026-10-24): one-time KVP key migration. The resource's KVP
-- keys were renamed 'oxlyn:' -> 'rw:' for the RealWrld rebrand; on server
-- start, copy any value stored under a legacy key to its new key. Legacy
-- keys are left in place as a backup; a key is only copied while the new
-- key is still unset, so this is a no-op once migrated.
if IsDuplicityVersion and IsDuplicityVersion() then
    local KVP_MIGRATIONS = {
        { 'oxlyn:globalConfig', 'rw:globalConfig' },
        { 'oxlyn:serverSettings', 'rw:serverSettings' },
        { 'oxlyn:webhooks', 'rw:webhooks' },
        { 'oxlyn:pocketConfig', 'rw:pocketConfig' },
        { 'oxlyn:dropProps', 'rw:dropProps' },
        { 'oxlyn:dropsConfig', 'rw:dropsConfig' },
    }
    for i = 1, #KVP_MIGRATIONS do
        local oldKey, newKey = KVP_MIGRATIONS[i][1], KVP_MIGRATIONS[i][2]
        if GetResourceKvpString(newKey) == nil then
            local legacy = GetResourceKvpString(oldKey)
            if legacy ~= nil then SetResourceKvp(newKey, legacy) end
        end
    end
end

return {
    Get = getConfig,
}
