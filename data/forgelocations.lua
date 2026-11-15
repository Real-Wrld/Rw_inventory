-- Forge Location Configuration
-- Uses custom forge model from rw-forge resource

return {
    -- Model information (vanilla fallback — custom forge/white_sup_table not in stream)
    model = 'prop_3dprinter_01', -- was 'prop_tool_bench02' (forge bench); stations are 3D printers now (Phase 6)

    -- List of forge locations
    locations = {
        {
            id = 'forge_legion_square',
            coords = vector4(195.0, -934.0, 30.7, 160.0), -- Legion Square area
            label = 'Downtown 3D Printer',
            blip = {
                sprite = 110,
                color = 47,
                scale = 0.8,
                display = 4,
            },
            -- Tier restrictions (nil = all tiers allowed)
            allowedTiers = nil,
        },
        {
            id = 'forge_paleto',
            coords = vector4(-162.0, 6321.0, 31.5, 250.0), -- Paleto Bay
            label = 'Paleto 3D Printer',
            blip = {
                sprite = 110,
                color = 47,
                scale = 0.8,
                display = 4,
            },
            allowedTiers = nil,
        },
        {
            id = 'forge_sandy',
            coords = vector4(1961.0, 3745.0, 32.3, 30.0), -- Sandy Shores
            label = 'Sandy 3D Printer',
            blip = {
                sprite = 110,
                color = 47,
                scale = 0.8,
                display = 4,
            },
            allowedTiers = nil,
        },
        {
            id = 'forge_master',
            coords = vector4(714.0, -962.0, 30.4, 90.0), -- Special master forge
            label = 'Master 3D Printer',
            blip = {
                sprite = 110,
                color = 5, -- Yellow for special
                scale = 1.0,
                display = 4,
            },
            -- Master forge only allows advanced+ recipes
            allowedTiers = { 'advanced', 'master', 'legendary' },
            levelRequired = 15,
        },
    },

    -- Interaction settings
    interaction = {
        distance = 2.5, -- How close to interact
        targetIcon = 'fas fa-hammer',
        targetLabel = 'Open Forge',
    },

    -- Visual settings when spawning model
    visual = {
        useGroundSnap = true,
        light = {
            enabled = true,
            color = { r = 255, g = 150, b = 50 },
            intensity = 2.0,
            range = 5.0,
        },
        -- Particle effect at forge
        ptfx = {
            enabled = true,
            dict = 'core',
            name = 'fire_wrecked_car',
            scale = 0.3,
        },
    },
}
