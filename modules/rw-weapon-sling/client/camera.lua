if not lib then return end

-- Legacy shim — sling editor uses studio.lua for camera + ped preview.
local Studio = require 'modules.rw-weapon-sling.client.studio'

local EditorCam = {}

function EditorCam.start()
    return Studio.open()
end

function EditorCam.stop()
    Studio.close()
end

function EditorCam.getPed()
    return Studio.getPed()
end

return EditorCam
