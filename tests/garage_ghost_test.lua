-- Ghost display is a local, locked, non-colliding vehicle at the garage point.
local events, callbacks, threads, states = {}, {}, {}, {}
local changeHandler, marker
function RegisterNUICallback(name, fn) callbacks[name]=fn end
function RegisterNetEvent(name, fn) events[name]=fn end
function AddEventHandler() end
function AddStateBagChangeHandler(_, _, fn) changeHandler=fn end
function GetEntityFromStateBagName() return 77 end
function Entity() return {state={housingGarageGhost=marker}} end
function ResetEntityAlpha() states.alpha=255 end
function CreateThread(fn) threads[#threads+1]=fn end
function DoesEntityExist(id) return id==77 and not states.deleted end
function IsModelAVehicle(model) return model==123 end
function RequestModel() end
function HasModelLoaded() return true end
function GetGameTimer() return 0 end
function SetModelAsNoLongerNeeded() end
function CreateVehicle(model,x,y,z,heading,networked)
    assert(model==123 and x==10 and y==20 and z==30 and heading==90 and networked==false)
    return 77
end
function SetEntityAlpha(_,value) states.alpha=value end
function SetEntityCollision(_,value) states.collision=value end
function SetEntityInvincible(_,value) states.invincible=value end
function SetVehicleDoorsLocked(_,value) states.lock=value end
function SetVehicleDoorsLockedForAllPlayers(_,value) states.lockAll=value end
function SetVehicleUndriveable(_,value) states.undriveable=value end
function SetVehicleEngineOn() end
function FreezeEntityPosition(_,value) states.frozen=value end
function DeleteEntity() states.deleted=true end
ESX={Game={SetVehicleProperties=function() error('test customization failure') end}}
library={Callback=function(name, cb)
    assert(name=='vms_housing:garage:ghosts')
    cb({{id='42',coords={x=10,y=20,z=30,w=90},props={model=123}}})
end}
assert(loadfile('esx_realestate/client/modules/housing_garage.lua'))()
assert(#threads==1) -- periodic refresh thread, not run in this mock
events['vms_housing:garage:changed']()
assert(#threads==2); threads[2]()
assert(states.alpha==102 and states.collision==false and states.invincible and states.lock==2 and states.lockAll and states.undriveable and states.frozen)
marker={propertyId='42'}; changeHandler('entity:1',nil,marker); threads[3]()
assert(states.alpha==102 and states.collision==false and states.undriveable)
marker=nil; changeHandler('entity:1',nil,nil); threads[4]()
assert(states.alpha==255 and states.collision==true and not states.undriveable and not states.frozen and not states.lockAll)
print('parked vehicle display and network ghost state restore passed')
