-- ═══════════════════════════════════════════════════════════════════════════
--  REALWRLD · 3D PRINTER SYSTEM
--  Reference schema
-- ═══════════════════════════════════════════════════════════════════════════
--
--  YOU DO NOT NEED TO RUN THIS.
--
--  The resource creates and migrates all three tables by itself on the first
--  start. This file is here only for reference, or if your host does not let
--  a resource create tables and you would rather do it by hand.
--
--  Requires oxmysql. With Config.Persistence = false none of this is used.
-- ═══════════════════════════════════════════════════════════════════════════

-- Printers placed on the map ------------------------------------------------
CREATE TABLE IF NOT EXISTS `oxlyn_3dprinters` (
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

-- The editable catalogue -----------------------------------------------------
-- Empty on the first start, then seeded from config/items.lua. After that this
-- table is what the printers read; "Restore defaults" in /printeradmin wipes it
-- and seeds it again.
CREATE TABLE IF NOT EXISTS `oxlyn_3dprinter_items` (
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

-- Readable names for raw materials -------------------------------------------
CREATE TABLE IF NOT EXISTS `oxlyn_3dprinter_materials` (
    `name`  VARCHAR(64) NOT NULL,
    `label` VARCHAR(64) DEFAULT NULL,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Everything else that is editable in game -----------------------------------
-- One row per setting, value stored as JSON. Today that means the battery.
CREATE TABLE IF NOT EXISTS `oxlyn_3dprinter_settings` (
    `k` VARCHAR(64) NOT NULL,
    `v` LONGTEXT    DEFAULT NULL,
    PRIMARY KEY (`k`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
