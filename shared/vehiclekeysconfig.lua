return {
    lockDistance = 10.0,

    -- Police Alert Settings
    alertCooldown = 10000,         -- Cooldown period in milliseconds (10 seconds)
    policeAlertChance = 0.75,      -- Chance of alerting the police during the day
    policeNightAlertChance = 0.50, -- Chance of alerting the police at night
    policeAlertNightStartHour = 1,
    policeAlertNightDuration = 5,

    alertPolice = function(crime, vehicle)
        TriggerServerEvent('police:server:policeAlert', 'Vehicle Theft: ' .. crime)
    end,
    anim = {
        dict = 'anim@mp_player_intmenu@key_fob@',
        clip = 'fob_click'
    },
    hotwire = {
        timeBetween = 5000,
        minKeysSearchTime = 20000,
        maxKeysSearchTime = 40000,
        cooldown = 1000,
        anim = {
            dict = 'anim@veh@plane@howard@front@ds@base',
            clip = 'hotwire'
        }
    },
    lockpick = {
        cooldown = 1000,
        anim = {
            dict = 'veh@break_in@0h@p_m_one@',
            clip = 'low_force_entry_ds'
        }
    },
    skillCheck = {
        difficulty = { 'easy', 'easy', { areaSize = 60, speedMultiplier = 1 }, 'medium' },
        inputs = { '1', '2', '3' }
    },
    keepEngineOnWhenAbandoned = true,

    -- Job Settings
    sharedKeys = { -- Share keys amongst employees. Employees can lock/unlock any job-listed vehicle
        police = { -- Job name
            enableAutolock = true,
            requireOnduty = true,
            classes = {},
            vehicles = {
                [`police`] = true,  -- Vehicle model
                [`police2`] = true, -- Vehicle model
                [`police3`] = true, -- Vehicle model
                [`polmustang`] = true,
                [`polcharger`] = true,
                [`polcoach`] = true,
                [`polsilv`] = true,
                [`poloutlaw`] = true,
                [`shel`] = true,
            }
        },
        ambulance = {
            enableAutolock = true,
            requireOnduty = true,
            classes = {},
            vehicles = {
                [`ambulance`] = true,
            },
        },
        mechanic = {
            requireOnduty = false,
            vehicles = {
                [`towtruck`] = true,
                [`flatbed`] = true,
                [`flatbed3`] = true,
            }
        }
    },
}
