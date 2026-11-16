HousingDataReady = true
local property = {metadata = {garage = {x=1,y=2,z=3}}}
local allowed = false
function GetProperty(id) return id == '42' and property or nil end
library = {HasPermissions = function(id, identifier, permission)
    assert(id == '42' and identifier == 'char:a' and permission == 'garage')
    return allowed
end}
assert(loadfile('esx_realestate/server/modules/garage_access.lua'))()
local access = HousingGarageAccess
assert(not access.CanUse('42', 'char:a'))
allowed = true
assert(access.CanUse('42', 'char:a'))
assert(access.CanUse('42', 'char:a', 'char:a'))
assert(not access.CanUse('42', 'char:a', 'char:b'))
assert(not access.CanUse('missing', 'char:a'))
property.metadata.lockdown = true
assert(not access.CanUse('42', 'char:a'))
property.metadata.lockdown = nil
property.metadata.garage = nil
assert(not access.CanUse('42', 'char:a'))
property.metadata.garage = {x=1,y=2,z=3}
HousingDataReady = false
assert(not access.CanUse('42', 'char:a'))
assert(access.OwnsVehicle('char:a', {owner='char:a'}))
assert(not access.OwnsVehicle('char:a', {owner='char:b'}))
assert(not access.OwnsVehicle('', {owner=''}))
print('garage access checks passed')
