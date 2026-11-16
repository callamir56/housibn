-- Run with Lua 5.4+ from the repository root.
local created, deleted = 0, 0
CL = {Notification = function() end}
AvailableShells = { map = {mapInterior = true}, prop = {} }
function CreateObjectNoOffset(...) created = created + 1; return 123 end
function DoesEntityExist(id) return id == 123 end
function joaat(name) return 42 end
function SetEntityHeading(...) end
function FreezeEntityPosition(...) end
function DeleteObject(id) assert(id == 123); deleted = deleted + 1 end
assert(loadfile('esx_realestate/client/lib.lua'))()
local requested = 0
library.RequestEntity = function(name) requested = requested + 1; return true end
assert(library.RequestHousingShell('map') and requested == 0)
assert(SpawnHousingShell('map') == 0 and created == 0)
DeleteHousingShell(0); assert(deleted == 0)
assert(library.RequestHousingShell('prop') and requested == 1)
assert(SpawnHousingShell('prop') == 123 and created == 1)
DeleteHousingShell(123); assert(deleted == 1)
print('map and object shell handling passed')
