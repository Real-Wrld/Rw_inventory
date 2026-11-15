-- GetGroundCoord.lua  –  Accurate ground Z lookup via a temporary invisible ped
-- Client-side only.

if IsDuplicityVersion() then return end

local PLAYER_ZERO_HASH = joaat("PLAYER_ZERO")

-- Spawns a hidden ped at the given coords, measures how high above the ground
-- it floats (which equals the ground Z offset), then cleans up and returns
-- the ground Z coordinate.
function GetGroundCoord(coords)
    assert(type(coords) == "vector3",
        ("Failed to get ground coord. Expected vector3, got %s"):format(type(coords)))

    -- Ensure the model is loaded
    if not HasModelLoaded(PLAYER_ZERO_HASH) then
        RequestModel(PLAYER_ZERO_HASH)
        while not HasModelLoaded(PLAYER_ZERO_HASH) do
            Citizen.Wait(50)
        end
    end

    -- Spawn an invisible ped at the target location
    local ped = CreatePed(0, PLAYER_ZERO_HASH, coords.x, coords.y, coords.z, 0.0, false, true)
    while not DoesEntityExist(ped) do
        Citizen.Wait(50)
    end

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityCanBeDamaged(ped, false)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, true)

    -- Ground Z = entity Z minus height above ground
    local groundZ = GetEntityCoords(ped).z - GetEntityHeightAboveGround(ped)

    -- Cleanup
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
        SetEntityAsNoLongerNeeded(ped)
    end
    if HasModelLoaded(PLAYER_ZERO_HASH) then
        SetModelAsNoLongerNeeded(PLAYER_ZERO_HASH)
    end

    return groundZ
end
