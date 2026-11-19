local threads, handlers, targets, frozen, calls = {}, {}, {}, false, {}
Config={TargetResource='ox_target',HousingBathroom={Enabled=true,DurationMs=10000,ToiletModels={'toilet'},ShowerModels={'shower'},BathModels={'bath'},BathOffset={x=0,y=0,z=0},ToiletOffset={x=0,y=0,z=0},ShowerOffset={x=0,y=0,z=0}}}
CurrentProperty='7'
Property={}
exports={ox_target={addModel=function(_,models,opts) targets[models[1]]=opts[1] end,removeModel=function() end}}
function CreateThread(fn) threads[#threads+1]=fn end
function AddEventHandler(n,fn) handlers[n]=fn end
function DoesEntityExist() return true end
function PlayerPedId() return 10 end
function IsEntityDead() return false end
function IsPedInAnyVehicle() return false end
function GetOffsetFromEntityInWorldCoords() return {x=1,y=2,z=3} end
function GetEntityHeading() return 0 end
function GetEntityCoords() return {x=0,y=0,z=0} end
function GetPedBoneCoords() return {x=1,y=2,z=3} end
function HasAnimDictLoaded() return true end
function TaskPlayAnim(_,dict) calls[dict]=true end
function SetEntityCoordsNoOffset() end
function SetEntityHeading(_,v) calls.heading=v end
function FreezeEntityPosition(_,v) frozen=v end
function GetEntityCollisionDisabled() return false end
function SetEntityCollision(_,v) calls.collision=v end
function TaskStartScenarioAtPosition() calls.toilet=true end
function ClearPedTasks() calls.clear=true end
function StopAnimTask() calls.stop=true end
function GetGameTimer() return 0 end
function IsControlJustPressed() return true end
function Wait() end
function GetCurrentResourceName() return 'housing' end
function GetResourceState() return 'started' end
CL={Notification=function() end}
library={LoadDict=function() end}
assert(loadfile('esx_realestate/client/modules/interaction_position.lua'))()
assert(loadfile('esx_realestate/client/modules/bathroom.lua'))()
table.remove(threads,1)()
assert(targets.toilet and targets.shower and targets.bath)
CurrentProperty=nil; assert(not targets.toilet.canInteract(8))
CurrentProperty='7'; targets.toilet.onSelect({entity=8}); assert(calls.toilet and not targets.shower.canInteract(8))
table.remove(threads,1)(); assert(calls.clear)
targets.shower.onSelect({entity=8}); assert(frozen)
table.remove(threads,1)(); assert(calls['mp_safehouseshower@female@'])
table.remove(threads,1)(); assert(calls.stop and not frozen)
targets.bath.onSelect({entity=8}); assert(frozen and calls.collision==false and calls.heading==180)
table.remove(threads,1)(); assert(calls['timetable@ron@ig_3_couch'])
table.remove(threads,1)(); assert(not frozen and calls.collision==true)
targets.shower.onSelect({entity=8}); assert(frozen); handlers.onResourceStop('housing'); assert(not frozen)
table.remove(threads,1)() -- delayed animation must not restart after stop
print('bathroom targets, interruption and cleanup passed')
