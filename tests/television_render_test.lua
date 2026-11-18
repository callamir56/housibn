local events, threads, order = {}, {}, {}
CurrentProperty='7'; Config={HousingTV={Enabled=true,Models={tv=true}}}
library={Callback=function() end}; CL={Notification=function() end}
function RegisterNetEvent(n,f) events[n]=f end
function RegisterNUICallback() end
function AddEventHandler() end
function CreateThread(f) threads[#threads+1]=coroutine.create(f) end
function Wait() coroutine.yield() end
function GetGameTimer() return 0 end
function IsNamedRendertargetRegistered() return false end
function RegisterNamedRendertarget() end
function ReleaseNamedRendertarget() end
function IsNamedRendertargetLinked() return false end
function LinkNamedRendertarget() end
function GetHashKey() return 123 end
function GetNamedRendertargetRenderId() return 50 end
function CreateRuntimeTxd() return 1 end
function CreateDui() return 5 end
function IsDuiAvailable() order[#order+1]='available'; return true end
function GetCurrentResourceName() return 'housing' end
function GetDuiHandle() return 'handle' end
function CreateRuntimeTextureFromDuiHandle() order[#order+1]='texture'; return 3 end
function SetTextRenderId() end
function SetScriptGfxDrawBehindPausemenu() end
function SetScriptGfxDrawOrder(v) assert(v==4 or v==0); if v==4 then order[#order+1]='layer' end end
function DrawSprite(txd) assert(txd=='housing_tv_1'); order[#order+1]='draw' end
function DrawRect(x,y,w,h,r,g,b,a) assert(r==0 and g==0 and b==0 and a==255); order[#order+1]='black' end
function GetDefaultScriptRendertargetRenderId() return 1 end
function DestroyDui() end
json={encode=function() return '{}' end}
-- The target is free before registration and present afterwards.
local registered=false
function IsNamedRendertargetRegistered() return registered end
function RegisterNamedRendertarget() registered=true end
function ReleaseNamedRendertarget() registered=false end
assert(loadfile('esx_realestate/client/modules/television.lua'))()
events['vms_housing:tv:update']('7',{on=true,provider='aparat',video='BNMK5',version=1})
assert(#order==0 and #threads==1)
assert(coroutine.resume(threads[1]))
assert(table.concat(order,',')=='available,available,texture,layer,draw')
events['vms_housing:tv:update']('7',{on=false})
assert(coroutine.resume(threads[1])) -- old video thread terminates
assert(coroutine.resume(threads[3])) -- off-state render thread draws black
assert(order[#order]=='black' and registered)
CurrentProperty='8'; assert(coroutine.resume(threads[3])); assert(not registered)
print('TV DUI readiness, black off screen and target cleanup passed')
