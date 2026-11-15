-- Forge Orders Database Schema
-- Run this script to create the necessary tables for crafting enhancements

-- ==========================================
-- FORGE ORDERS TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS `ox_forge_orders` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `owner` VARCHAR(60) NOT NULL,           -- Player identifier
    `bench_id` VARCHAR(100) NOT NULL,       -- Which forge bench
    `recipe_name` VARCHAR(100) NOT NULL,    -- Item being forged
    `quantity` INT DEFAULT 1,               -- How many to craft
    `start_time` BIGINT NOT NULL,           -- Unix timestamp (ms) when started
    `end_time` BIGINT NOT NULL,             -- Unix timestamp (ms) when complete
    `collected` BOOLEAN DEFAULT FALSE,      -- Whether player picked up items
    `cancelled` BOOLEAN DEFAULT FALSE,      -- Whether order was cancelled
    `is_rush` BOOLEAN DEFAULT FALSE,        -- Rush order (faster, more materials)
    `quality` VARCHAR(20) DEFAULT NULL,     -- Item quality (rolled on collection)
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_owner` (`owner`),
    INDEX `idx_bench` (`bench_id`),
    INDEX `idx_end_time` (`end_time`),
    INDEX `idx_collected` (`collected`),
    INDEX `idx_cancelled` (`cancelled`),
    INDEX `idx_collected_endtime` (`collected`, `end_time`),
    INDEX `idx_forge_active_end` (`collected`, `cancelled`, `end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add columns if table exists (run these if updating existing table)
-- ALTER TABLE ox_forge_orders ADD COLUMN IF NOT EXISTS `cancelled` BOOLEAN DEFAULT FALSE;
-- ALTER TABLE ox_forge_orders ADD COLUMN IF NOT EXISTS `is_rush` BOOLEAN DEFAULT FALSE;
-- ALTER TABLE ox_forge_orders ADD COLUMN IF NOT EXISTS `quality` VARCHAR(20) DEFAULT NULL;

-- ==========================================
-- RECIPE FAVORITES TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS `ox_recipe_favorites` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `owner` VARCHAR(60) NOT NULL,           -- Player identifier
    `recipe_name` VARCHAR(100) NOT NULL,    -- Recipe name
    `bench_id` VARCHAR(100) NOT NULL,       -- Which bench
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_favorite` (`owner`, `recipe_name`, `bench_id`),
    INDEX `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==========================================
-- PLAYER CRAFTING SETTINGS
-- ==========================================
CREATE TABLE IF NOT EXISTS `ox_player_craft_settings` (
    `owner` VARCHAR(60) PRIMARY KEY,        -- Player identifier
    `auto_collect` BOOLEAN DEFAULT FALSE,   -- Auto-collect ready items
    `sound_enabled` BOOLEAN DEFAULT TRUE,   -- Play sound effects
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==========================================
-- CLEANUP
-- ==========================================
-- Cleanup old collected orders after 7 days
-- You can run this periodically or as a scheduled event
-- DELETE FROM ox_forge_orders WHERE collected = TRUE AND created_at < DATE_SUB(NOW(), INTERVAL 7 DAY);

