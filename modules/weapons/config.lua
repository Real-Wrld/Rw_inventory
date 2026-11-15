-- Weapon Component Configuration
-- Defines available attachments, required items, and job restrictions

return {
    -- Attachment items that can be used on weapons
    attachmentItems = {
        -- Scopes
        ["scope_small"] = { component = "COMPONENT_AT_SCOPE_SMALL", slot = "scope", label = "Small Scope" },
        ["scope_medium"] = { component = "COMPONENT_AT_SCOPE_MEDIUM", slot = "scope", label = "Medium Scope" },
        ["scope_large"] = { component = "COMPONENT_AT_SCOPE_LARGE", slot = "scope", label = "Large Scope" },
        ["scope_macro"] = { component = "COMPONENT_AT_SCOPE_MACRO", slot = "scope", label = "Macro Scope" },

        -- Suppressors
        ["suppressor_pistol"] = { component = "COMPONENT_AT_PI_SUPP", slot = "barrel", label = "Pistol Suppressor" },
        ["suppressor_smg"] = { component = "COMPONENT_AT_AR_SUPP", slot = "barrel", label = "SMG Suppressor" },
        ["suppressor_rifle"] = { component = "COMPONENT_AT_AR_SUPP_02", slot = "barrel", label = "Rifle Suppressor" },

        -- Grips
        ["grip_tactical"] = { component = "COMPONENT_AT_AR_AFGRIP", slot = "grip", label = "Tactical Grip" },
        ["grip_vertical"] = { component = "COMPONENT_AT_AR_AFGRIP_02", slot = "grip", label = "Vertical Grip" },

        -- Magazines
        ["magazine_extended"] = { component = "COMPONENT_PISTOL_CLIP_02", slot = "magazine", label = "Extended Mag" },
        ["magazine_drum"] = { component = "COMPONENT_ASSAULTRIFLE_CLIP_03", slot = "magazine", label = "Drum Mag" },

        -- Flashlights
        ["flashlight_weapon"] = { component = "COMPONENT_AT_PI_FLSH", slot = "flashlight", label = "Flashlight" },
        ["flashlight_tactical"] = { component = "COMPONENT_AT_AR_FLSH", slot = "flashlight", label = "Tactical Light" }
    },

    -- Job restrictions for certain attachments
    jobRestrictions = {
        ["scope_large"] = { jobs = { "police", "military" }, minGrade = 3 },
        ["suppressor_rifle"] = { jobs = { "police", "military" }, minGrade = 5 },
        ["magazine_drum"] = { jobs = { "military" }, minGrade = 0 }
    },

    -- Weapon-specific component compatibility
    weaponComponents = {
        ["WEAPON_PISTOL"] = {
            barrel = { "COMPONENT_AT_PI_SUPP" },
            magazine = { "COMPONENT_PISTOL_CLIP_02" },
            flashlight = { "COMPONENT_AT_PI_FLSH" }
        },
        ["WEAPON_COMBATPISTOL"] = {
            barrel = { "COMPONENT_AT_PI_SUPP" },
            magazine = { "COMPONENT_COMBATPISTOL_CLIP_02" },
            flashlight = { "COMPONENT_AT_PI_FLSH" }
        },
        ["WEAPON_SMG"] = {
            scope = { "COMPONENT_AT_SCOPE_MACRO_02" },
            barrel = { "COMPONENT_AT_PI_SUPP" },
            magazine = { "COMPONENT_SMG_CLIP_02", "COMPONENT_SMG_CLIP_03" },
            flashlight = { "COMPONENT_AT_AR_FLSH" }
        },
        ["WEAPON_ASSAULTRIFLE"] = {
            scope = { "COMPONENT_AT_SCOPE_MACRO", "COMPONENT_AT_SCOPE_MEDIUM" },
            barrel = { "COMPONENT_AT_AR_SUPP_02", "COMPONENT_AT_MUZZLE_01" },
            grip = { "COMPONENT_AT_AR_AFGRIP" },
            magazine = { "COMPONENT_ASSAULTRIFLE_CLIP_02", "COMPONENT_ASSAULTRIFLE_CLIP_03" },
            flashlight = { "COMPONENT_AT_AR_FLSH" }
        },
        ["WEAPON_CARBINERIFLE"] = {
            scope = { "COMPONENT_AT_SCOPE_MEDIUM" },
            barrel = { "COMPONENT_AT_AR_SUPP", "COMPONENT_AT_MUZZLE_01" },
            grip = { "COMPONENT_AT_AR_AFGRIP" },
            magazine = { "COMPONENT_CARBINERIFLE_CLIP_02", "COMPONENT_CARBINERIFLE_CLIP_03" },
            flashlight = { "COMPONENT_AT_AR_FLSH" }
        }
    },

    -- Camera settings per weapon type
    cameraSettings = {
        pistol = { distance = 0.4, height = 0.1, fov = 30.0 },
        smg = { distance = 0.5, height = 0.15, fov = 35.0 },
        rifle = { distance = 0.7, height = 0.2, fov = 40.0 },
        shotgun = { distance = 0.6, height = 0.18, fov = 38.0 }
    }
}
