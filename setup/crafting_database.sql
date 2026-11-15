-- Database setup for Blueprint Crafting System
-- Run this SQL on your database to create the required table

CREATE TABLE IF NOT EXISTS `ox_inventory_crafting` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL UNIQUE,
    `crafting_xp` INT NOT NULL DEFAULT 0,
    `learned_blueprints` LONGTEXT NOT NULL DEFAULT '[]',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
