
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
local coords, heading, collision = nil, nil, 0
function PlayerPedId() return 44 end
function RequestCollisionAtCoord(x,y,z) collision = collision + 1 end
function SetEntityCoordsNoOffset(ped,x,y,z) assert(ped == 44); coords = {x,y,z} end
function SetEntityHeading(ped,h) assert(ped == 44); heading = h end
CurrentProperty = '6'; CurrentShell = 0
ApplyMapInteriorEntry(6, 1, 2, 3, 180)
assert(coords[1] == 1 and coords[2] == 2 and coords[3] == 3 and heading == 180 and collision == 2)
coords = nil
ApplyMapInteriorEntry(7, 1, 2, 3, 180)
assert(coords == nil)
CurrentShell = nil
ApplyMapInteriorEntry(6, 1, 2, 3, 180)
assert(coords == nil)
print('map entry confirmation tests passed')
