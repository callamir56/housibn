local handlers, cb, seen, calls = {},nil,nil,{}
CurrentProperty='7'; Furniture={couch={tag='sofa'}}
Config={HousingSeats={Enabled=true,Models={},Types={sofa={slots={{x=.4,y=0,z=.45}},heading=180}}}}
library={Callback=function(_,fn) cb=fn end}
CL={Notification=function() end}
function DoesEntityExist() return true end
function PlayerPedId() return 44 end
function IsPedInAnyVehicle() return false end
function IsEntityDead() return false end
function GetOffsetFromEntityInWorldCoords(_,x,y,z) return {x=x,y=y,z=z} end
function GetEntityHeading() return 5 end
function TaskStartScenarioAtPosition(_,scenario,x,y,z,heading) seen={scenario,x,y,z,heading} end
function TriggerServerEvent(...) calls[#calls+1]={...} end
function CreateThread() end
function ClearPedTasks() end
function RegisterNetEvent(name,fn) handlers[name]=fn end
function AddEventHandler(name,fn) handlers[name]=fn end
assert(loadfile('esx_realestate/client/modules/seating.lua'))()
HousingSeats.Sit('7',4,1,'couch'); cb({ok=true,token=8,slot=1})
assert(seen[1]=='PROP_HUMAN_SEAT_CHAIR_MP_PLAYER' and seen[2]==.4 and seen[5]==185)
handlers['vms_housing:seat:expired'](8)
HousingSeats.Sit('7',4,1,'couch'); CurrentProperty='8'; cb({ok=true,token=9,slot=1})
assert(calls[1][1]=='vms_housing:seat:leave' and calls[1][2]==9)
print('seating client offset and stale callback tests passed')
