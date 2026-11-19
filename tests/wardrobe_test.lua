
local callback
local rows = {}
local currentIdentifier = 'character:a'
local players = { [1] = {}, [2] = {} }
SV = {GetPlayer = function(id) return players[id] end, GetIdentifier = function() return currentIdentifier end}
HousingDataReady = true
library = {RegisterCallback = function(name, cb) assert(name == 'vms_housing:wardrobe'); callback = cb end}
json = {encode = function(value) return value end, decode = function(value) return value end}
MySQL = {
  query = {await = function(_, args)
    local out = {}
    for slot, value in pairs(rows[args[1]] or {}) do out[#out+1] = {slot = slot, name = value.name, skin = value.skin} end
    return out
  end},
  update = {await = function(sql, args)
    rows[args[1]] = rows[args[1]] or {}
    if sql:match('^INSERT') then
      if rows[args[1]][args[2]] then error('duplicate') end
      rows[args[1]][args[2]] = {name = args[3], skin = args[4]}; return 1
    end
    if rows[args[1]][args[2]] then rows[args[1]][args[2]] = nil; return 1 end
    return 0
  end}
}
assert(loadfile('esx_realestate/server/modules/wardrobe.lua'))()
local function request(src, action, data)
  local result; callback(src, function(value) result = value end, action, data); return result
end
local skin = {sex=0, tshirt_1=12, pants_1=4, hair_1=99, mom=8}
assert(request(1, 'save', {name='لباس ۱', skin=skin}).ok)
assert(rows['character:a'][1].skin.tshirt_1 == 12 and rows['character:a'][1].skin.hair_1 == nil)
for i=2,5 do assert(request(1, 'save', {name='Outfit '..i, skin=skin}).ok) end
assert(request(1, 'save', {name='extra', skin=skin}).reason == 'full')
assert(#request(1, 'list').outfits == 5)
currentIdentifier = 'character:b'
assert(#request(2, 'list').outfits == 0)
assert(not request(2, 'delete', {slot=1}).ok)
currentIdentifier = 'character:a'
assert(request(1, 'delete', {slot=2}).ok)
assert(request(1, 'save', {name='reused', skin=skin}).ok and rows['character:a'][2].name == 'reused')
assert(request(1, 'save', {name='Bad', skin={sex=0, pants_1=0/0}}).reason == 'invalid')
assert(not request(99, 'list').ok)
print('wardrobe character isolation, capacity, deletion and validation passed')
