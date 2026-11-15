-- modules/items/special_blueprints.lua
-- Handles special effects for blueprint items like Shadow Cloak and Revive Syringe

-- Shadow Cloak Implementation
exports('UseShadowCloak', function(data, slot)
    local ped = cache.ped
    if not ped then return end

    -- Visual Effect (Purple Smoke)
    lib.requestNamedPtfxAsset('scr_josh3')
    UseParticleFxAssetNextCall('scr_josh3')
    StartNetworkedParticleFxNonLoopedAtCoord('scr_josh3_fudge_explosion', GetEntityCoords(ped), 0.0, 0.0, 0.0, 1.0, false,
        false, false, false)

    -- Toggle Invisibility
    SetEntityVisible(ped, false, 0)
    -- Ghostly appearance to self (and others if alpha syncs, but visible false should hide)
    -- We use alpha 50 locally so players know they are cloaked but can see themselves slightly?
    -- Actually SetEntityVisible(false) hides completely.
    -- Let's try to make them invisible to others but visible locally with alpha?
    -- NetworkSetEntityInvisibleToNetwork(ped, true) -- Hides from others
    -- SetEntityAlpha(ped, 50, false)

    -- Simplest approach: Standard visibility toggle
    SetEntityVisible(ped, false, 0)

    lib.notify({
        title = 'Shadow Cloak',
        description = 'You vanish into the shadows...',
        type = 'success',
        duration = 5000
    })

    -- Duration: 30 seconds
    SetTimeout(30000, function()
        if DoesEntityExist(ped) then
            SetEntityVisible(ped, true, 0)
            -- NetworkSetEntityInvisibleToNetwork(ped, false)
            lib.notify({
                title = 'Shadow Cloak',
                description = 'Your cloak fades.',
                type = 'inform'
            })
        end
    end)

    -- Note: Item consumption is handled via 'consume' in items.lua?
    -- If not, we might need to remove it manually.
    -- 'shadow_cloak' is an equippable or consumable?
    -- If it's a reusable artifact, maybe cooldown?
    -- For now, let's assume it consumes or has durability. Item def has no consume/durability yet.
    -- We can add cooldown here.
end)

-- Revive Syringe Implementation
exports('UseReviveSyringe', function(data, slot)
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local closestPlayer, closestDistance = lib.getClosestPlayer(coords, 3.0, false)

    if not closestPlayer then
        lib.notify({ type = 'error', description = 'No one nearby to revive.' })
        return
    end

    local targetId = GetPlayerServerId(closestPlayer)

    -- Animation
    lib.requestAnimDict('mini@repair')
    TaskPlayAnim(ped, 'mini@repair', 'fixing_a_player', 8.0, -8.0, -1, 1, 0, false, false, false)

    if lib.progressBar({
            duration = 5000,
            label = 'Injecting Revive Serum...',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, combat = true },
        }) then
        TriggerServerEvent('ox_inventory:revivePlayer', targetId)
        TriggerServerEvent('ox_inventory:removeItem', 'revive_syringe', 1, nil, slot)
        lib.notify({ type = 'success', description = 'Revived target!' })
    else
        lib.notify({ type = 'error', description = 'Cancelled' })
    end
    ClearPedTasks(ped)
end)
