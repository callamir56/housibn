local claim, handlers, timers, emitted
handlers,timers,emitted={},{},{}
Config={HousingSeats={Enabled=true,RequirePermission=false,MaxDistance=3.5,LeaseSeconds=30,Models={},Types={chair={slots={{x=0}}},sofa={slots={{x=-.45},{x=.45}}}}}}
HousingDataReady=true; Furniture={couch={tag='sofa'}}
local property={furniture={{id=4,stored=0,model='couch',position={x=1,y=2,z=3,environment='inside'}}}}
local near=true; local bucket=8
function GetProperty(id) if id=='7' then return property end end
SV={GetPlayer=function() return {} end,GetIdentifier=function(p) return 'char' end}
library={RegisterCallback=function(_,fn) claim=fn end,HasAnyPermission=function() return false end}
function GetPlayerPed(src) return src end
function IsPlayerInProperty() return true end
function GetPlayerRoutingBucket() return bucket end
function GetEntityCoords() return near and {x=1,y=2,z=3} or {x=50,y=50,z=50} end
function SetTimeout(_,fn) timers[#timers+1]=fn end
function TriggerClientEvent(...) emitted[#emitted+1]={...} end
function RegisterNetEvent(name,fn) handlers[name]=fn end
function AddEventHandler(name,fn) handlers[name]=fn end
assert(loadfile('esx_realestate/server/modules/seating.lua'))()
local function request(src) local result; claim(src,function(v) result=v end,'7',4); return result end
local a,b=request(1),request(2); assert(a.ok and b.ok and a.slot==1 and b.slot==2)
assert(not request(3).ok and not request(1).ok)
source=1; handlers['vms_housing:seat:leave'](a.token)
local c=request(3); assert(c.ok and c.slot==1)
source=2; near=false; handlers['vms_housing:seat:heartbeat'](b.token); assert(#emitted==1)
near=true; assert(request(4).ok)
bucket=0; assert(not request(5).ok)
print('seating ownership, capacity, release, distance and bucket tests passed')
