if not lib then return end

local Query = {
    SELECT_STASH = 'SELECT data FROM ox_inventory WHERE owner = ? AND name = ?',
    UPDATE_STASH = 'UPDATE ox_inventory SET data = ? WHERE owner = ? AND name = ?',
    UPSERT_STASH =
    'INSERT INTO ox_inventory (data, owner, name) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)',
    INSERT_STASH = 'INSERT INTO ox_inventory (owner, name) VALUES (?, ?)',
    SELECT_GLOVEBOX = 'SELECT plate, glovebox FROM `{vehicle_table}` WHERE `{vehicle_column}` = ?',
    SELECT_TRUNK = 'SELECT plate, trunk FROM `{vehicle_table}` WHERE `{vehicle_column}` = ?',
    SELECT_PLAYER = 'SELECT inventory FROM `{user_table}` WHERE `{user_column}` = ?',
    UPDATE_TRUNK = 'UPDATE `{vehicle_table}` SET trunk = ? WHERE `{vehicle_column}` = ?',
    UPDATE_GLOVEBOX = 'UPDATE `{vehicle_table}` SET glovebox = ? WHERE `{vehicle_column}` = ?',
    UPDATE_PLAYER = 'UPDATE `{user_table}` SET inventory = ? WHERE `{user_column}` = ?',
}

MySQL.ready(function()
    -- Run database schema checks using FULLY ASYNC callbacks (zero blocking)

    local playerTable, playerColumn, vehicleTable, vehicleColumn

    if shared.framework == 'ox' then
        playerTable = 'character_inventory'
        playerColumn = 'charid'
        vehicleTable = 'vehicles'
        vehicleColumn = 'id'
    elseif shared.framework == 'esx' then
        playerTable = 'users'
        playerColumn = 'identifier'
        vehicleTable = 'owned_vehicles'
        vehicleColumn = 'plate'
    elseif shared.framework == 'nd' then
        playerTable = 'nd_characters'
        playerColumn = 'charid'
        vehicleTable = 'nd_vehicles'
        vehicleColumn = 'id'
    elseif shared.framework == 'qbx' then
        playerTable = 'players'
        playerColumn = 'citizenid'
        vehicleTable = 'player_vehicles'
        vehicleColumn = 'id'
    else
        return
    end

    for k, v in pairs(Query) do
        Query[k] = v:gsub('{user_table}', playerTable):gsub('{user_column}', playerColumn):gsub('{vehicle_table}',
            vehicleTable):gsub('{vehicle_column}', vehicleColumn)
    end

    -- Step 1: Check if ox_inventory table exists (async)
    MySQL.scalar('SELECT 1 FROM ox_inventory', {}, function(result)
        if not result then
            -- Table doesn't exist, create it
            MySQL.query([[CREATE TABLE IF NOT EXISTS `ox_inventory` (
                `owner` varchar(60) DEFAULT NULL,
                `name` varchar(100) NOT NULL,
                `data` longtext DEFAULT NULL,
                `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                UNIQUE KEY `owner` (`owner`,`name`)
            )]], {}, function()
                -- Continue to step 2 after table creation
                checkVehicleColumns(vehicleTable, playerTable)
            end)
        else
            -- Table exists, continue to step 2
            checkVehicleColumns(vehicleTable, playerTable)
        end
    end)

    -- Step 2: Check vehicle table columns (async)
    function checkVehicleColumns(vTable, pTable)
        MySQL.query(('SHOW COLUMNS FROM `%s`'):format(vTable), {}, function(result)
            if result then
                local glovebox, trunk = false, false
                for i = 1, #result do
                    local column = result[i]
                    if column.Field == 'glovebox' then glovebox = true end
                    if column.Field == 'trunk' then trunk = true end
                end

                if not glovebox then
                    MySQL.query(('ALTER TABLE `%s` ADD COLUMN `glovebox` LONGTEXT NULL'):format(vTable))
                end

                if not trunk then
                    MySQL.query(('ALTER TABLE `%s` ADD COLUMN `trunk` LONGTEXT NULL'):format(vTable))
                end
            else
            end

            -- Continue to step 3
            checkPlayerInventoryColumn(pTable)
        end)
    end

    -- Step 3: Check player inventory column (async)
    function checkPlayerInventoryColumn(pTable)
        MySQL.scalar(('SELECT inventory FROM `%s` LIMIT 1'):format(pTable), {}, function(result)
            -- If query fails (column doesn't exist), add it
            -- Note: MySQL.scalar returns nil for both "no rows" and "error"
            -- We use a separate check via SHOW COLUMNS to be safe
            MySQL.query(('SHOW COLUMNS FROM `%s` LIKE "inventory"'):format(pTable), {}, function(columns)
                if not columns or #columns == 0 then
                    MySQL.query(('ALTER TABLE `%s` ADD COLUMN `inventory` LONGTEXT NULL'):format(pTable))
                end

                -- Continue to step 4
                cleanupOldStashes()
            end)
        end)
    end

    -- Step 4: Cleanup old stashes (async, low priority)
    function cleanupOldStashes()
        local clearStashes = GetConvar('inventory:clearstashes', '6 MONTH')
        if clearStashes ~= '' then
            MySQL.query(
                ('DELETE FROM ox_inventory WHERE lastupdated < (NOW() - INTERVAL %s)'):format(clearStashes)
            )
        end
    end
end)

db = {}

function db.loadPlayer(identifier)
    local inventory = MySQL.prepare.await(Query.SELECT_PLAYER, { identifier }) --[[@as string?]]
    return inventory and json.decode(inventory)
end

function db.savePlayer(owner, inventory)
    return MySQL.prepare(Query.UPDATE_PLAYER, { inventory, owner })
end

function db.saveStash(owner, dbId, inventory)
    return MySQL.prepare(Query.UPSERT_STASH, { inventory, owner and tostring(owner) or '', dbId })
end

function db.loadStash(owner, name)
    return MySQL.prepare.await(Query.SELECT_STASH, { owner and tostring(owner) or '', name })
end

function db.saveGlovebox(id, inventory)
    return MySQL.prepare(Query.UPDATE_GLOVEBOX, { inventory, id })
end

function db.loadGlovebox(id)
    return MySQL.prepare.await(Query.SELECT_GLOVEBOX, { id })
end

function db.saveTrunk(id, inventory)
    return MySQL.prepare(Query.UPDATE_TRUNK, { inventory, id })
end

function db.loadTrunk(id)
    return MySQL.prepare.await(Query.SELECT_TRUNK, { id })
end

---@param rows number | MySQLQuery | MySQLQuery[]
local function countRows(rows)
    if type(rows) == 'number' then return rows end

    local n = 0

    for i = 1, #rows do
        if rows[i] == 1 then n = n + 1 end
    end

    return n
end

local function safeQuery(...)
    local ok, resp = pcall(...)

    if not ok then
        return warn(resp)
    end

    return resp
end

---@param players InventorySaveData[]
---@param trunks InventorySaveData[]
---@param gloveboxes InventorySaveData[]
---@param stashes (InventorySaveData | string | number)[]
---@param total number[]
function db.saveInventories(players, trunks, gloveboxes, stashes, total)
    local start = os.nanotime()
    local saveStr = 'Saved %d/%d %s (%.4f ms)'
    local pending = 0

    shared.info(('Saving %s inventories to the database'):format(total[5]))

    if total[1] > 0 then
        pending = pending + 1

        Citizen.CreateThreadNow(function()
            local resp = safeQuery(MySQL.prepare.await, Query.UPDATE_PLAYER, players)
            pending = pending - 1

            if resp then
                shared.info(saveStr:format(countRows(resp), total[1], 'players', (os.nanotime() - start) / 1e6))
            end
        end)
    end

    if total[2] > 0 then
        pending = pending + 1

        Citizen.CreateThreadNow(function()
            local resp = safeQuery(MySQL.prepare.await, Query.UPDATE_TRUNK, trunks)
            pending = pending - 1

            if resp then
                shared.info(saveStr:format(countRows(resp), total[2], 'trunks', (os.nanotime() - start) / 1e6))
            end
        end)
    end

    if total[3] > 0 then
        pending = pending + 1

        Citizen.CreateThreadNow(function()
            local resp = safeQuery(MySQL.prepare.await, Query.UPDATE_GLOVEBOX, gloveboxes)
            pending = pending - 1

            if resp then
                shared.info(saveStr:format(countRows(resp), total[3], 'gloveboxes', (os.nanotime() - start) / 1e6))
            end
        end)
    end

    if total[4] > 0 then
        pending = pending + 1

        if server.bulkstashsave then
            total[4] = total[4] / 3

            Citizen.CreateThreadNow(function()
                local query = Query.UPSERT_STASH:gsub('%(%?, %?, %?%)', string.rep('(?, ?, ?)', total[4], ', '))
                local resp = safeQuery(MySQL.query.await, query, stashes)
                pending = pending - 1

                if resp then
                    local affectedRows = resp.affectedRows

                    if total[4] == 1 then
                        if affectedRows == 2 then affectedRows = 1 end
                    else
                        affectedRows = affectedRows - (tonumber(resp.info:match('Duplicates: (%d+)'), 10) or 0)
                    end

                    shared.info(saveStr:format(affectedRows, total[4], 'stashes', (os.nanotime() - start) / 1e6))
                end
            end)
        else
            Citizen.CreateThreadNow(function()
                local resp = safeQuery(MySQL.rawExecute.await, Query.UPSERT_STASH, stashes)
                pending = pending - 1

                if resp then
                    local affectedRows = 0

                    if table.type(resp) == 'hash' then
                        if resp.affectedRows > 0 then affectedRows = 1 end
                    else
                        for i = 1, #resp do
                            if resp[i].affectedRows > 0 then affectedRows = affectedRows + 1 end
                        end
                    end

                    shared.info(saveStr:format(affectedRows, total[4], 'stashes', (os.nanotime() - start) / 1e6))
                end
            end)
        end
    end

    repeat Wait(0) until pending == 0
end

return db
