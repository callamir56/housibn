local threads, events, fades, waits, anims, steps = {}, {}, {}, {}, {}, {}
local now=0
local handlers={}
CurrentProperty='7'
Config={HousingRest={BedOffset={x=0,y=0,z=0.6,heading=0}}}
function RegisterNetEvent() end
function AddEventHandler(name,fn) handlers[name]=fn end
function TriggerServerEvent(n,token) events[#events+1]={n,token} end
function PlayerPedId() return 10 end
function CreateThread(fn) threads[#threads+1]=fn end
function Wait(ms) waits[#waits+1]=ms; now=now+ms end
function GetGameTimer() return now end
function GetCurrentResourceName() return "housing" end
function StopAnimTask() end
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
function DoScreenFadeOut(ms) fades[#fades+1]={'out',ms} end
function DoScreenFadeIn(ms) fades[#fades+1]={'in',ms} end
CL={Notification=function() end}
library={LoadDict=function() end,PlayAnimation=function(_,dict,anim) anims[#anims+1]={dict,anim} end,Callback=function(_,cb) cb({ok=true,token=17}) end}
assert(loadfile('esx_realestate/client/modules/interaction_position.lua'))()
assert(loadfile('esx_realestate/client/modules/rest.lua'))()
HousingRest.Start('7',4,99)
assert(frozen and collision==false)
table.remove(threads,1)() -- fixed-bed registration
table.remove(threads,1)() -- sleep
assert(anims[1][2]=='base' and frozen and collision==false and #steps==3 and HousingRest.IsBusy())
local wakeThread=threads[2] -- monitoring thread precedes wake thread
wakeThread()
assert(not frozen and collision==true and not HousingRest.IsBusy())
assert(steps[4][1]=='pos' and steps[4][2]==0 and steps[5][1]=='collision' and steps[5][2]==true and steps[6][1]=='freeze' and steps[6][2]==false)
for i=1,6 do assert(waits[i]==100) end
assert(waits[7]==150 and waits[8]==4300)
assert(fades[1][1]=='out' and fades[2][1]=='in')
assert(anims[2][2]=='sleep_getup_rubeyes' and events[1][1]=='vms_housing:rest:cancel')
print('sleep fade, timed wake and cancellation passed')
-- Resource stop while the wake dictionary is loading must still restore state,
-- and a delayed wake thread must not restart the animation afterwards.
threads = {}; steps = {}; fades = {}; now=0
HousingRest.Start('7',4,99)
table.remove(threads,1)() -- sleep
assert(frozen and collision==false and HousingRest.IsBusy())
local pendingWake=threads[2]
local count=#anims
handlers.onResourceStop('housing')
assert(not frozen and collision==true and not HousingRest.IsBusy())
pendingWake()
assert(#anims==count)
print('wake interruption cleanup passed')
