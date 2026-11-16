-- Run with Lua 5.4+ from the repository root.
local notices = 0
CL = {Notification = function() notices = notices + 1 end}
local loadLibrary = assert(loadfile('esx_realestate/client/lib.lua'))
OpenWardrobe, OpenGarage = nil, nil
loadLibrary()
OpenWardrobe(); OpenGarage()
assert(notices == 2)
local wardrobe, garage = function() end, function() end
OpenWardrobe, OpenGarage = wardrobe, garage
loadLibrary()
assert(OpenWardrobe == wardrobe and OpenGarage == garage)
print('integration fallback tests passed')
