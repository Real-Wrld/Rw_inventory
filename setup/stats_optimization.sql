-- Optimizations for ox_crafting_stats table
-- Speeds up leaderboard and player stat queries
ALTER TABLE `ox_crafting_stats` 
ADD INDEX `idx_count` (`count` DESC),
ADD INDEX `idx_identifier_count` (`identifier`, `count` DESC),
ADD INDEX `idx_itemname_count` (`item_name`, `count` DESC);

-- Optimizations for ox_crafting_totals table
-- Speeds up global leaderboard queries
ALTER TABLE `ox_crafting_totals`
ADD INDEX `idx_total_crafted` (`total_crafted` DESC);

-- Optimizations for ox_forge_orders table (if not already applied)
-- Speeds up active-order lookups and timer hydration
ALTER TABLE `ox_forge_orders`
ADD INDEX `idx_forge_active_end` (`collected`, `cancelled`, `end_time`);
