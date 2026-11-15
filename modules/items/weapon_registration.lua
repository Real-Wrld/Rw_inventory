local function isWeapon(itemName)
    return itemName:find('^WEAPON_') ~= nil
end

-- Hook into the item button generation
local originalGetButtons = exports.ox_inventory.GetButtons

exports('GetButtons', function(item)
    local buttons = originalGetButtons and originalGetButtons(item) or {}
    
    if isWeapon(item.name) then
        table.insert(buttons, {
            label = 'Register Weapon',
            action = function(slot)
                local itemData = exports.ox_inventory:GetSlot(slot)
                
                if not itemData or not itemData.metadata then
                    lib.notify({type = 'error', description = 'Invalid weapon data'})
                    return
                end
                
                local weaponData = {
                    serial = itemData.metadata.serial or 'Unknown',
                    owner = GetPlayerName(PlayerId()),
                    weapClass = itemData.name,
                    weapModel = itemData.label,
                    image = 'nui://ox_inventory/web/images/'..itemData.name..'.png',
                    notes = ''
                }
                
                TriggerServerEvent('mdt:server:registerweapon', weaponData)
                lib.notify({description = 'Weapon registered with MDT'})
            end
        })
    end
    
    return buttons
end)
