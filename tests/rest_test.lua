local cb, events, timers, net = nil, {}, {}, {}
HousingDataReady=true
Config={HousingRest={Enabled=true,Models={bed=true},DurationSeconds=10,TickSeconds=5,HealPerTick=5,CooldownSeconds=30,MaxDistance=3}}
Furniture={newbed={tag='bed'}, chair={tag='chair'}}
local p={owner='alice',metadata={},furniture={{id=4,model='bed',stored=0,position={x=0,y=0,z=0,environment='inside'}},{id=5,model='newbed',stored=0,position={x=0,y=0,z=0,environment='inside'}},{id=6,model='chair',stored=0,position={x=0,y=0,z=0,environment='inside'}}}}
SV={GetPlayer=function() return {} end,GetIdentifier=function() return 'alice' end}
library={RegisterCallback=function(_,fn) cb=fn end,HasAnyPermission=function(_,id) return id=='alice' end}
function GetProperty(id) if id=='7' then return p end end
function GetPlayerPed() return 9 end
function IsPlayerInProperty() return true end
function GetPlayerRoutingBucket() return 8 end
local coords={x=0,y=0,z=0}
function GetEntityCoords() return coords end
function GetEntityHealth() return 180 end
function SetTimeout(_,fn) timers[#timers+1]=fn end
function TriggerClientEvent(name,_,...) events[#events+1]={name,...} end
function RegisterNetEvent(name,fn) net[name]=fn end
function AddEventHandler() end
assert(loadfile('esx_realestate/server/modules/rest.lua'))()
local function request(id,bed) local r; cb(1,function(v) r=v end,id,bed); return r end
assert(not request('7',99).ok)
assert(not request('7',6).ok)
local tagbed=request('7',5); assert(tagbed.ok)
source=1; net['vms_housing:rest:cancel'](tagbed.token)
events, timers = {}, {}
-- reset time-based cooldown for a different character
SV.GetIdentifier=function() return 'bob' end
library.HasAnyPermission=function() return true end
coords={x=10,y=0,z=0}; assert(not request('7',4).ok)
coords={x=0,y=0,z=0}; local r=request('7',4); assert(r.ok)
assert(not request('7',4).ok)
table.remove(timers,1)(); assert(events[1][1]=='vms_housing:rest:tick' and events[1][3]==5)
coords={x=10,y=0,z=0}; table.remove(timers,1)(); assert(events[2][1]=='vms_housing:rest:finish')
coords={x=0,y=0,z=0}; assert(not request('7',4).ok)
print('rest bed, access, proximity, cooldown and interrupted session tests passed')
