-- Run with Lua 5.4+ from the repository root.
local file = assert(io.open('esx_realestate/server/main.lua'))
local text = file:read('*a'); file:close()
local code = assert(text:match('(AddEventHandler%("vms_housing:sv:fetchData".-\nend%))'))
local handler
function AddEventHandler(_, cb) handler = cb end
local time, waits, events = 0, 0, {}
function GetGameTimer() return time end
Citizen = { Wait = function(ms)
  time = time + ms; waits = waits + 1
  if waits == 2 then HousingDataReady = true end
end }
source = 1
SV = {GetPlayer = function() return {} end}
Properties = {['1'] = {id = 1}}
Furniture = {chair = {label = 'Chair'}}
Webhooks = {}
json = {encode = function(value) return value end}
function TriggerClientEvent(name, src, data) events[#events+1] = {name, src, data} end
assert(load(code))()
HousingDataReady = false
handler()
assert(waits == 2 and #events == 3)
assert(events[2][1] == 'vms_housing:cl:loadFurniture' and events[2][3].chair.label == 'Chair')
print('furniture fetch waits for initialization')
