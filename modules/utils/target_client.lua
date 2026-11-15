if not lib then return end

local Target = {}

---Wait for ox_target exports, then run registration safely.
function Target.whenReady(fn)
	CreateThread(function()
		if GetResourceState('ox_target') ~= 'started' then return end

		for _ = 1, 100 do
			local ready = pcall(function()
				return exports.ox_target.addGlobalPlayer
			end)

			if ready then break end
			Wait(100)
		end

		local ok, err = pcall(fn)
		if not ok then
			warn(('[ox_inventory] ox_target registration failed: %s'):format(err))
		end
	end)
end

return Target
