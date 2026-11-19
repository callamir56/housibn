local threads, events, fades, waits, anims, steps, handlers = {}, {}, {}, {}, {}, {}, {}
local now=0
CurrentProperty='7'
Config={HousingRest={BedOffset={x=0,y=0,z=0.6,heading=0}}}
function RegisterNetEvent() end
function AddEventHandler(name,fn) handlers[name]=fn end
function TriggerServerEvent(n,token) events[#events+1]={n,token} end
function PlayerPedId() return 10 end
function CreateThread(fn) threads[#threads+1]=fn end
function Wait(ms) waits[#waits+1]=ms; now=now+ms end
function GetCurrentResourceName() return 'housing' end
function ClearPedTasksImmediately() end
function IsEntityDead() return false end
function IsPedInAnyVehicle() return false end
function DoesEntityExist() return true end
function GetOffsetFromEntityInWorldCoords() return {x=1,y=2,z=3} end
function GetEntityHeading() return 0 end
function GetEntityCoords() return {x=0,y=0,z=0} end
function GetPedBoneCoords() return {x=1,y=2,z=3} end
function FreezeEntityPosition(_,v) _G.frozen=v; steps[#steps+1]={'freeze',v} end
function GetEntityCollisionDisabled() return false end
function SetEntityCollision(_,v) _G.collision=v; steps[#steps+1]={'collision',v} end
function HasAnimDictLoaded() return true end
function TaskPlayAnim(_,dict,anim) anims[#anims+1]={dict,anim} end
function SetEntityCoordsNoOffset(_,x,y,z) steps[#steps+1]={'pos',x,y,z} end
function SetEntityHeading() end
function DoScreenFadeOut(ms) fades[#fades+1]={'out',ms}; steps[#steps+1]={'out'} end
function DoScreenFadeIn(ms) fades[#fades+1]={'in',ms}; steps[#steps+1]={'in'} end
CL={Notification=function() end}
library={LoadDict=function() end,Callback=function(_,cb) cb({ok=true,token=17}) end}
assert(loadfile('esx_realestate/client/modules/interaction_position.lua'))()
assert(loadfile('esx_realestate/client/modules/rest.lua'))()
HousingRest.Start('7',4,99)
assert(frozen and collision==false)
table.remove(threads,1)()
table.remove(threads,1)()
assert(#anims==1 and anims[1][2]=='base' and not frozen and collision==true and not HousingRest.IsBusy())
assert(steps[4][1]=='out' and steps[5][1]=='pos' and steps[5][2]==0)
assert(steps[6][1]=='collision' and steps[6][2]==true and steps[7][1]=='freeze' and steps[7][2]==false and steps[8][1]=='in')
for i=1,6 do assert(waits[i]==100) end
assert(waits[7]==150 and waits[8]==4300)
assert(fades[1][1]=='out' and fades[2][1]=='in' and events[1][1]=='vms_housing:rest:cancel')
print('sleep ends standing before fade-in with no wake animation')
