-- Run with Lua 5.4+ from the repository root; FiveM APIs are mocked.
local events = {}
function RegisterNetEvent(name, handler) events[name] = handler end
Properties = { ['6'] = { metadata = {} } }
CurrentProperty = '6'
CurrentPropertyData = { metadata = {} } -- deliberately stale snapshot
CurrentShell = true
TargetPoints = {{ type = 'wardrobe', id = 1 }, { type = 'storage', id = 2 }}
local removed, created = {}, {}
CL = { Target = function(action, id) if action == 'remove-zone' then removed[id] = true end end }
TargetHandler = {
  Wardrobe = function(id, x, y, z)
    created.wardrobe = {id, x, y, z}
    return {type = 'wardrobe', id = 3}
  end,
  Storage = function(id, x, y, z, slots, weight)
    created.storage = {id, x, y, z, slots, weight}
    return {type = 'storage', id = 4}
  end,
}
library = { HasAnyPermission = function() return true end }
function GetCurrentPropertyId() return '6' end
function RefreshBlips() end
function ExitZone() end
function IsInsideMLO() return false end
assert(loadfile('esx_realestate/client/main.lua'))()
local update = events['vms_housing:cl:updateProperty']
update('changedWardrobePosition', 6, {wardrobe = {x=1,y=2,z=3}})
assert(removed[1] and created.wardrobe[2] == 1 and created.wardrobe[4] == 3)
update('changedStoragePosition', 6, {storage = {x=4,y=5,z=6,slots=10,weight=100}})
assert(removed[2] and created.storage[2] == 4 and created.storage[5] == 10)
update('changedWardrobePosition', 6, {}) -- removes old zone, no invalid target
assert(removed[3] and #TargetPoints == 1)
update('changedStoragePosition', 6, {})
assert(removed[4] and #TargetPoints == 0)
local new = { metadata = {} }
events['vms_housing:cl:createdHouse']('6', new)
assert(CurrentPropertyData == new)
print('position update tests passed')
