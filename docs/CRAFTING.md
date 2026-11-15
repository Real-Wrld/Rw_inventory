# RW-Inventory Crafting System

A comprehensive blueprint-based crafting system with XP progression, tiered recipes, and material scavenging.

## 📦 Features

### Blueprint Learning

- **16 Craftable Blueprints** across 4 tiers
- Players must find and use blueprints to learn recipes
- Level requirements prevent learning advanced recipes too early
- Blueprints consumed on use

### Tiered Recipes

| Tier | Color | Level | XP Reward | Description |
|------|-------|-------|-----------|-------------|
| Basic | 🟢 Green | 0 | 8-20 | Common recipes anyone can craft |
| Advanced | 🔵 Blue | 5+ | 25-50 | Better equipment, requires blueprints |
| Master | 🔴 Red | 15+ | 50-75 | Powerful items, rare materials |
| Legendary | 🟡 Gold | 25+ | 100-200 | End-game equipment |

### Crafting Locations

| Location | Coords | Specialization | Blip |
|----------|--------|----------------|------|
| Downtown Workshop | Legion Square | Basic + Advanced | Blue Wrench |
| Industrial Forge | La Mesa | Basic + Master | Red Anvil |
| Arcane Sanctum | Pacific Bluffs | Master + Legendary | Gold Crystal |
| Desert Workshop | Sandy Shores | Basic + Advanced | Orange Wrench |
| Northern Workshop | Paleto Bay | Basic + Advanced | Cyan Wrench |

> Each location has different recipes available. Legendary items can ONLY be crafted at the Arcane Sanctum!

### XP & Level Progression

- Earn XP by successfully crafting items
- 30 levels with balanced progression curve
- Higher tiers require higher crafting levels
- Level displayed in crafting UI

### Crafting Materials

**Gems:**

- Diamond, Ruby, Sapphire, Emerald, Amethyst, Onyx

**Fantasy Materials:**

- Rune Core, Mithril Ore, Arcane Dust, Dark Glass

**Tech Materials:**

- Carbon Fiber, Titanium Alloy

---

## 🛠️ Installation

### 1. Database Setup

Run the SQL script to create the crafting progression table:

```sql
-- Located at: setup/crafting_database.sql
CREATE TABLE IF NOT EXISTS `ox_inventory_crafting` (
    `identifier` VARCHAR(60) NOT NULL,
    `xp` INT DEFAULT 0,
    `level` INT DEFAULT 1,
    `learned_recipes` LONGTEXT DEFAULT '[]',
    PRIMARY KEY (`identifier`)
);
```

### 2. Safe Storage (Optional)

If using player-owned safes:

```sql
-- Located at: setup/stash_database.sql
CREATE TABLE IF NOT EXISTS `ox_inventory_stashes` (...)
```

### 3. Images

Copy all `.png` files from `web/images/` to your inventory's image directory.

---

## 📁 File Structure

```
RW-Inventory/
├── data/
│   ├── blueprints.lua      # Blueprint definitions
│   ├── crafting.lua        # Recipe definitions
│   ├── items.lua           # Item + material definitions
│   └── scavenging.lua      # Loot tables for finding blueprints
├── modules/
│   ├── crafting/
│   │   ├── blueprints.lua  # XP/Level system
│   │   ├── client.lua      # Crafting bench handling
│   │   └── server.lua      # Craft validation + XP rewards
│   ├── scavenging/
│   │   ├── client.lua      # Search interaction
│   │   └── server.lua      # Loot generation
│   └── storage/
│       ├── client.lua      # Safe placement + robbery
│       └── server.lua      # MySQL persistence
├── setup/
│   ├── crafting_database.sql
│   └── stash_database.sql
└── web/
    └── images/             # All material/blueprint images
```

---

## 🎮 How It Works

### Crafting Flow

1. Player approaches crafting bench
2. Opens crafting UI (shows available recipes)
3. Recipes locked until blueprint learned
4. Craft items → earn XP → level up
5. Higher levels unlock ability to learn advanced blueprints

### Finding Blueprints

Blueprints can be found through:

- **Scavenging** - Search locations with small chance of blueprint
- **Admin give** - `/giveitem [player] [blueprint_item]`
- **Drops** - Configure NPC drops to include blueprints

### Learning Recipes

1. Player obtains blueprint item
2. Uses blueprint from inventory
3. If level requirement met → recipe learned
4. Blueprint consumed

---

## ⚙️ Configuration

### Adding New Recipes

Edit `data/crafting.lua`:

```lua
{
    name = 'your_item',
    tier = 'advanced',        -- basic/advanced/master/legendary
    xpReward = 35,
    ingredients = {
        diamond = 1,
        titanium_alloy = 2,
    },
    duration = 8000,          -- Craft time in ms
    count = 1,                -- Output amount
},
```

### Adding New Blueprints

Edit `data/blueprints.lua`:

```lua
['blueprint_your_item'] = {
    recipe = 'your_item',
    tier = 'advanced',
    requiredLevel = 5,
    label = 'Your Item Blueprint',
},
```

### Adding New Materials

Edit `data/items.lua`:

```lua
['your_material'] = {
    label = 'Your Material',
    weight = 50,
    stack = true,
    description = 'Description here',
    client = {
        image = 'your_material.png',
    },
},
```

---

## 🔒 Safe Storage System

### Features

- 3 tiers: Small, Medium, Large safes
- MySQL persistent storage
- Object Gizmo placement
- **Robbery system** with ox_lib skillcheck

### Robbery Mechanics

- Non-owners can attempt to rob safes
- Requires lockpick item
- Skillcheck minigame (harder for larger safes)
- 30-minute cooldown after successful robbery
- 40% chance lockpick breaks

---

## 📋 Dependencies

- **ox_lib** - UI components, callbacks, notifications
- **ox_inventory** - Base inventory system
- **ox_target** - Interaction targeting
- **oxmysql** - Database operations
- **object_gizmo** (optional) - Advanced prop placement

---

## 🐛 Troubleshooting

### Lint Warnings

The Lua linter may show warnings for FiveM natives like `exports`, `MySQL`, `CreateThread`. These are false positives - they work at runtime.

### Images Not Showing

Ensure images are in `web/images/` with correct filenames matching the `image` property in item definitions.

### XP Not Saving

1. Check database table exists
2. Verify oxmysql is running
3. Check server console for errors

---

## 📄 License

Part of the RW-Inventory project. See main repository for license details.
