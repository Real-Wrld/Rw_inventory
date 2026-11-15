PrinterSchemaReady = false

local PRINTERS_TABLE = "rw_3dprinters"

local PRINTERS_SQL = ([[
CREATE TABLE IF NOT EXISTS `%s` (
    `id`          INT(11)      NOT NULL AUTO_INCREMENT,
    `owner`       VARCHAR(64)  NOT NULL,
    `owner_name`  VARCHAR(64)  DEFAULT NULL,
    `x`           FLOAT        NOT NULL,
    `y`           FLOAT        NOT NULL,
    `z`           FLOAT        NOT NULL,
    `heading`     FLOAT        NOT NULL DEFAULT 0,
    `state`       VARCHAR(16)  NOT NULL DEFAULT 'idle',
    `item`        VARCHAR(64)  DEFAULT NULL,
    `amount`      INT(11)      NOT NULL DEFAULT 0,
    `started_at`  BIGINT       DEFAULT NULL,
    `finishes_at` BIGINT       DEFAULT NULL,
    `queue`       LONGTEXT     DEFAULT NULL,
    `output`      LONGTEXT     DEFAULT NULL,
    `access`      LONGTEXT     DEFAULT NULL,
    `theme`       VARCHAR(24)  DEFAULT NULL,
    `battery`     FLOAT        DEFAULT NULL,
    `log`         LONGTEXT     DEFAULT NULL,
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]):format(PRINTERS_TABLE)

local ITEMS_SQL = [[
CREATE TABLE IF NOT EXISTS `rw_3dprinter_items` (
    `name`        VARCHAR(64)  NOT NULL,
    `label`       VARCHAR(64)  DEFAULT NULL,
    `category`    VARCHAR(32)  DEFAULT NULL,
    `time`        INT(11)      NOT NULL DEFAULT 60,
    `amount`      INT(11)      NOT NULL DEFAULT 1,
    `power`       FLOAT        NOT NULL DEFAULT 0,
    `prop`        VARCHAR(64)  DEFAULT NULL,
    `image`       VARCHAR(96)  DEFAULT NULL,
    `description` TEXT         DEFAULT NULL,
    `job`         VARCHAR(255) DEFAULT NULL,
    `grade`       INT(11)      DEFAULT NULL,
    `materials`   LONGTEXT     DEFAULT NULL,
    `enabled`     TINYINT(1)   NOT NULL DEFAULT 1,
    `sort`        INT(11)      NOT NULL DEFAULT 0,
    `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local SETTINGS_SQL = [[
CREATE TABLE IF NOT EXISTS `rw_3dprinter_settings` (
    `k` VARCHAR(64) NOT NULL,
    `v` LONGTEXT    DEFAULT NULL,
    PRIMARY KEY (`k`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local MATERIALS_SQL = [[
CREATE TABLE IF NOT EXISTS `rw_3dprinter_materials` (
    `name`  VARCHAR(64) NOT NULL,
    `label` VARCHAR(64) DEFAULT NULL,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

-- Columns added to older installs that predate them
local REQUIRED_COLUMNS = {
    { name = "owner_name",  ddl = "VARCHAR(64) DEFAULT NULL" },
    { name = "heading",     ddl = "FLOAT NOT NULL DEFAULT 0" },
    { name = "item",        ddl = "VARCHAR(64) DEFAULT NULL" },
    { name = "amount",      ddl = "INT(11) NOT NULL DEFAULT 0" },
    { name = "started_at",  ddl = "BIGINT DEFAULT NULL" },
    { name = "finishes_at", ddl = "BIGINT DEFAULT NULL" },
    { name = "queue",       ddl = "LONGTEXT DEFAULT NULL" },
    { name = "output",      ddl = "LONGTEXT DEFAULT NULL" },
    { name = "access",      ddl = "LONGTEXT DEFAULT NULL" },
    { name = "theme",       ddl = "VARCHAR(24) DEFAULT NULL" },
    { name = "battery",     ddl = "FLOAT DEFAULT NULL" },
    { name = "log",         ddl = "LONGTEXT DEFAULT NULL" },
}

-- Waits up to ~10s for oxmysql to start
local function waitForOxmysql()
    local tries = 0
    while GetResourceState("oxmysql") ~= "started" and tries < 100 do
        Wait(100)
        tries = tries + 1
    end
    return GetResourceState("oxmysql") == "started"
end

local function columnExists(column)
    local count = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = ?
          AND COLUMN_NAME = ?
    ]], { PRINTERS_TABLE, column })

    return (count or 0) > 0
end

CreateThread(function()
    if not PrinterConfig.Persistence then
        PrinterSchemaReady = true
        print("^3[rwprinter] Persistencia desligada; a base de dados nao e usada.^0")
        return
    end

    if not waitForOxmysql() then
        print("^1[rwprinter] oxmysql nao arrancou. A tabela nao foi criada e as^0")
        print("^1[rwprinter] impressoras nao vao sobreviver a um restart.^0")
        return
    end

    -- Printers table + migrate missing columns
    local ok, err = pcall(function()
        MySQL.query.await(PRINTERS_SQL)

        for _, col in ipairs(REQUIRED_COLUMNS) do
            if not columnExists(col.name) then
                MySQL.query.await(("ALTER TABLE `%s` ADD COLUMN `%s` %s"):format(PRINTERS_TABLE, col.name, col.ddl))
                print(("^3[rwprinter] Coluna em falta acrescentada: %s^0"):format(col.name))
            end
        end
    end)

    if not ok then
        print(("^1[rwprinter] Falha ao preparar a base de dados: %s^0"):format(err))
        print("^1[rwprinter] Confirma as credenciais em set mysql_connection_string.^0")
        return
    end

    -- Editable catalog tables (optional)
    local catalogOk, catalogErr = pcall(function()
        MySQL.query.await(ITEMS_SQL)
        MySQL.query.await(MATERIALS_SQL)
        MySQL.query.await(SETTINGS_SQL)
    end)

    CatalogSchemaReady = catalogOk

    if not catalogOk then
        print(("^3[rwprinter] Catalogo editavel indisponivel: %s^0"):format(catalogErr))
        print("^3[rwprinter] O /printeradmin usa o config/items.lua e nao grava.^0")
    end

    PrinterSchemaReady = true
    print("^2[rwprinter] Base de dados pronta.^0")
end)