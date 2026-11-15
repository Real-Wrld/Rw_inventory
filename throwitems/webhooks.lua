

-- Here you can configure the webhooks here is all the diffrent types of webhooks if you only would like some and not all you can either set it as false or leave it as ''.
-- The webhooks are used to log diffrent actions in the server to discord.

Webhooks = {
    ['THROWN_ITEM'] = {
        title = 'Thrown Item',
        template = '%s threw %s',
        webhook = ''
    },
    ['PICKED_UP_ITEM'] = {
        title = 'Picked Up Item',
        template = '%s picked up %s',
        webhook = ''
    },
    ['PLACED_ITEM'] = {
        title = 'Placed Item',
        template = '%s placed %s',
        webhook = ''
    },
    ['GAVE_ITEM'] = {
        title = 'Gave Item',
        template = '%s gave %s',
        webhook = ''
    },
}

function sendWebhook(source, name, messageData)
    if not Config.Logs then return end

    if not Webhooks[name] or not Webhooks[name].webhook or Webhooks[name].webhook == '' then
        Trace('Webhook error: Webhook URL not set for', name)
        return
    end

    local playerName
    if Config.Framework == 'standalone' then
        playerName = GetPlayerName(source)
    else
        playerName = GetPlayerName(source) .. ' (' .. source .. ') ' .. Framework:getPlayerName(source)
    end

    local message = Webhooks[name].template and string.format(Webhooks[name].template, playerName, tostring(messageData)) or
        "ERROR: No template found"

    local payload = {
        embeds = {
            {
                title = Webhooks[name].title or "Webhook",
                description = message,
                color = 8039935,
                footer = {
                    text = 'Bablo ThrowItems | ' .. os.date("%Y-%m-%d %H:%M:%S")
                }
            }
        }
    }

    PerformHttpRequest(Webhooks[name].webhook, function(err, text, headers)
        if err == 401 then
            Trace("ERROR: Unauthorized - The webhook URL might be invalid or expired.")
        elseif err == 429 then
            Trace("ERROR: Rate limited - Too many requests. Wait and try again later.")
        elseif err ~= 200 and err ~= 204 then
            Trace("Webhook failed! HTTP Error:", err, "Response:", text)
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

