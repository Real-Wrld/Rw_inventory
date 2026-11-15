CREATE TABLE IF NOT EXISTS `ox_market_listings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` varchar(50) NOT NULL,
  `owner_name` varchar(50) DEFAULT 'Unknown',
  `item` varchar(50) NOT NULL,
  `label` varchar(100) DEFAULT NULL,
  `count` int(11) NOT NULL DEFAULT 1,
  `price` int(11) NOT NULL COMMENT 'Buy-now price OR auction starting bid',
  `tier` varchar(20) DEFAULT 'basic',
  `metadata` longtext DEFAULT NULL,
  `mode` varchar(20) NOT NULL DEFAULT 'buynow' COMMENT 'buynow, auction',
  `starting_bid` int(11) NOT NULL DEFAULT 0,
  `buyout` int(11) DEFAULT NULL,
  `current_bid` int(11) NOT NULL DEFAULT 0,
  `current_bidder` varchar(50) DEFAULT NULL,
  `current_bidder_name` varchar(50) DEFAULT NULL,
  `duration_hours` int(11) NOT NULL DEFAULT 24,
  `status` varchar(20) NOT NULL DEFAULT 'active' COMMENT 'active, sold, expired, cancelled',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_owner` (`owner`),
  KEY `idx_item` (`item`),
  KEY `idx_tier` (`tier`),
  KEY `idx_status` (`status`),
  KEY `idx_mode` (`mode`),
  KEY `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ox_market_bids` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `listing_id` int(11) NOT NULL,
  `bidder` varchar(50) NOT NULL,
  `bidder_name` varchar(50) DEFAULT 'Unknown',
  `amount` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_listing_id` (`listing_id`),
  KEY `idx_bidder` (`bidder`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ox_market_pending_payouts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ox_market_pending_returns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `item` varchar(50) NOT NULL,
  `count` int(11) NOT NULL DEFAULT 1,
  `metadata` longtext DEFAULT NULL,
  `label` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ox_market_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` varchar(50) NOT NULL,
  `owner_name` varchar(50) DEFAULT 'Unknown',
  `item` varchar(50) NOT NULL,
  `label` varchar(100) DEFAULT NULL,
  `count` int(11) NOT NULL DEFAULT 1,
  `price` int(11) NOT NULL COMMENT 'Money offered for the work',
  `tier` varchar(20) DEFAULT 'basic',
  `materials` longtext DEFAULT NULL COMMENT 'JSON array of materials provided by requester',
  `status` varchar(20) DEFAULT 'active' COMMENT 'active, fulfilled, cancelled',
  `fulfilled_by` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_owner` (`owner`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ox_market_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(20) NOT NULL COMMENT 'sale, purchase, bid, buyout, auction_won, request_fulfilled, request_created',
  `listing_id` int(11) DEFAULT NULL,
  `request_id` int(11) DEFAULT NULL,
  `seller` varchar(50) NOT NULL,
  `seller_name` varchar(50) DEFAULT 'Unknown',
  `buyer` varchar(50) NOT NULL,
  `buyer_name` varchar(50) DEFAULT 'Unknown',
  `item` varchar(50) NOT NULL,
  `label` varchar(100) DEFAULT NULL,
  `count` int(11) NOT NULL DEFAULT 1,
  `price` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_seller` (`seller`),
  KEY `idx_buyer` (`buyer`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Migrations for existing databases (also run from server.lua CreateThread)
-- ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `mode` varchar(20) NOT NULL DEFAULT 'buynow';
-- ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `starting_bid` int(11) NOT NULL DEFAULT 0;
-- ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `buyout` int(11) DEFAULT NULL;
-- ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `current_bid` int(11) NOT NULL DEFAULT 0;
-- ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `current_bidder` varchar(50) DEFAULT NULL;
-- ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `current_bidder_name` varchar(50) DEFAULT NULL;
-- ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `duration_hours` int(11) NOT NULL DEFAULT 24;
-- ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `status` varchar(20) NOT NULL DEFAULT 'active';
-- ALTER TABLE `ox_market_listings` ADD COLUMN IF NOT EXISTS `expires_at` timestamp NULL DEFAULT NULL;
