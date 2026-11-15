-- SQL Setup for Player Stash Persistence
-- Run this script on your database to create the required table

CREATE TABLE IF NOT EXISTS `ox_inventory_stashes` (
    `id` VARCHAR(50) NOT NULL,
    `owner` VARCHAR(60) NOT NULL,
    `type` VARCHAR(20) NOT NULL DEFAULT 'small',
    `model` VARCHAR(50) NOT NULL DEFAULT 'p_v_43_safe_s',
    `coords_x` FLOAT NOT NULL,
    `coords_y` FLOAT NOT NULL,
    `coords_z` FLOAT NOT NULL,
    `heading` FLOAT NOT NULL DEFAULT 0.0,
    `rotation_x` FLOAT DEFAULT 0.0,
    `rotation_y` FLOAT DEFAULT 0.0,
    `rotation_z` FLOAT DEFAULT 0.0,
    `slots` INT NOT NULL DEFAULT 50,
    `max_weight` INT NOT NULL DEFAULT 100000,
    `pin` VARCHAR(4) DEFAULT NULL,
    `shared_access` JSON DEFAULT '[]',
    `failed_attempts` INT DEFAULT 0,
    `lockout_until` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optional: View all safes
-- SELECT * FROM ox_inventory_stashes;

-- Optional: Get safes for specific player
-- SELECT * FROM ox_inventory_stashes WHERE owner = 'license:YOUR_LICENSE_HERE';
