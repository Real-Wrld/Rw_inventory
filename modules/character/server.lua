-- Character Panel Server Module
-- Handles clothing equip/unequip events and persistence

-- ============================================
-- DISABLED: Character panel causes streamer crashes
-- The entire module is disabled. Uncomment below when ready.
-- ============================================
return {}

--[[ DISABLED MODULE CODE BELOW - DO NOT REMOVE, JUST KEEP COMMENTED

-- Handle clothing equipped event
RegisterNetEvent("ox_inventory:clothingEquipped", function(slot, itemData)
    local source = source
    if not source or source <= 0 then return end
end)

-- Handle clothing unequipped event
RegisterNetEvent("ox_inventory:clothingUnequipped", function(slot, equippedData)
    local source = source
    if not source or source <= 0 then return end
end)

-- Get player's equipped clothing (for save/load)
lib.callback.register("ox_inventory:getEquippedClothing", function(source)
    return {}
end)


--]] -- END DISABLED MODULE
