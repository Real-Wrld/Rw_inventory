-- version.lua  –  Update checker for bablo-throwitems

Citizen.CreateThread(function()
    local resourceName    = GetCurrentResourceName()
    local currentVersion  = GetResourceMetadata(resourceName, "version", 0)

    local function versionToNumber(str)
        return tonumber(str)
    end

    Citizen.Wait(5000)
    print("^6[CHECKING UPDATES]^0 ^7" .. resourceName .. "^0")

    local url = "https://raw.githubusercontent.com/TheRealBablo/version/master/" .. resourceName .. ".json"

    PerformHttpRequest(url, function(_, body)
        if not body then
            print("^1Unable to check version.^0")
            return
        end

        -- Strip trailing newline before decoding
        local data = json.decode(body:sub(1, -2))
        if not (data and data.version) then
            print("^1Invalid version data received.^0")
            return
        end

        local remoteNum  = versionToNumber(data.version:gsub("%.", ""))
        local currentNum = versionToNumber((currentVersion or "0"):gsub("%.", ""))

        if remoteNum > currentNum then
            -- Word-wrap helper for patch notes
            local function wordWrap(text, maxWidth)
                local words, lines, current = {}, {}, ""
                for word in text:gmatch("%S+") do words[#words + 1] = word end
                for _, word in ipairs(words) do
                    local candidate = current == "" and word or (current .. " " .. word)
                    if candidate:gsub("%^%d", ""):len() <= maxWidth then
                        current = candidate
                    else
                        if current ~= "" then lines[#lines + 1] = current end
                        current = word
                    end
                end
                if current ~= "" then lines[#lines + 1] = current end
                return lines
            end

            local divider = "^3" .. string.rep("-", 50) .. "^0"
            print("")
            print("^1[UPDATE AVAILABLE]^0 ^7" .. resourceName .. "^0")
            print(divider)
            print("^7Current Version: ^5" .. (currentVersion or "?") .. "^0")
            print("^7New Version:     ^2" .. data.version .. "^0")
            print("")
            print("^6Patch Notes:^0")

            if data.descriptions and #data.descriptions > 0 then
                for _, desc in ipairs(data.descriptions) do
                    local lines = wordWrap(desc, 75)
                    for i, line in ipairs(lines) do
                        if i == 1 then
                            print("^6  \226\128\162 ^5" .. line .. "^0")
                        else
                            print("^5    " .. line .. "^0")
                        end
                    end
                end
            else
                print("^6  \226\128\162 ^5No patch notes available^0")
            end

            print("")
            print("^4Download: ^7portal.cfx.re/assets/granted-assets^0")
            print(divider)
            print("")
        else
            print("")
            print("^2[UP TO DATE]^0 ^7" .. resourceName .. " - Version " .. (currentVersion or "?") .. "^0")
            print("")
        end
    end, "GET")
end)
