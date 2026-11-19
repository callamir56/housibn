
function exports() end
assert(loadfile('esx_realestate/client/modules/property.lua'))()
Property:RegisterDoors(nil)
Property:RegisterDoors({})
Property:RegisterDoors({doors = false})
Property:RegisterDoors({doors = {}})
local added = 0
function joaat() return 42 end
function AddDoorToSystem(...) added = added + 1 end
function DoorSystemSetDoorState(...) end
function DoorSystemSetAutomaticRate(...) end
local door = { type = 'single', model = 123, coords = {x=1,y=2,z=3}, locked=true }
Property:RegisterDoors({propertyId = 6, doors = {door}})
assert(added == 1 and door.hash == 42)
print('door registration tests passed')
