local events, threads, callbacks, disposed, targetReleased = {}, {}, {}, 0,0
CurrentProperty='7'; Config={HousingTV={Enabled=true,Models={tv=true}}}
library={Callback=function(_,fn) callbacks[#callbacks+1]=fn end}
CL={Notification=function() end}
function RegisterNetEvent(name,fn) events[name]=fn end
function RegisterNUICallback(name,fn) events[name]=fn end
function TriggerServerEvent(...) sent={...} end
function SendNUIMessage(data) message=data end
function SetNuiFocus(a,b) focus=a end
function AddEventHandler(name,fn) events[name]=fn end
function CreateThread(fn) threads[#threads+1]=fn end
local registered=false
function IsNamedRendertargetRegistered() return registered end
function RegisterNamedRendertarget() registered=true end
function ReleaseNamedRendertarget() registered=false; targetReleased=targetReleased+1 end
function IsNamedRendertargetLinked() return false end
function LinkNamedRendertarget() end
function GetHashKey() return 123 end
function GetNamedRendertargetRenderId() return 100 end
function CreateRuntimeTxd() return 1 end
function CreateDui() return 5 end
function GetCurrentResourceName() return 'housing' end
function GetDuiHandle() return 'handle' end
function CreateRuntimeTextureFromDuiHandle() return 3 end
function DestroyDui() disposed=disposed+1 end
assert(loadfile('esx_realestate/client/modules/television.lua'))()
HousingTV.Refresh('7')
events['vms_housing:tv:update']('7',{on=true,provider='youtube',video='abcdefghijk',version=1})
assert(#threads==1 and registered)
callbacks[1]({ok=true,state={on=false}})
assert(disposed==0)
events['vms_housing:tv:update']('8',{on=false}); assert(disposed==0)
events['vms_housing:tv:update']('7',{on=true,provider='youtube',video='abcdefghijk',version=2}); assert(disposed==1 and targetReleased==0 and registered)
events['vms_housing:tv:update']('7',{on=false}); assert(disposed==2 and targetReleased==0 and registered)
print('TV stale response, property isolation and DUI cleanup passed')

HousingTV.Control('7',5,'play'); assert(message.open and focus and openedMenu=='HousingTVInput')
local result; events['housingTV:submit']({url='https://www.aparat.com/v/BNMK5'},function(v) result=v end)
callbacks[2]({ok=false,reason='Access denied.'})
assert(not result.ok and focus and openedMenu=='HousingTVInput')
events['housingTV:submit']({url='https://www.aparat.com/v/BNMK5'},function(v) result=v end)
callbacks[3]({ok=true})
assert(result.ok and not focus and not openedMenu)
HousingTV.Control('7',5,'play'); CurrentProperty='8'
events['housingTV:submit']({url='https://example.com/test.mp4'},function(v) result=v end)
assert(not result.ok and not focus and not openedMenu)
print('TV input open, submit and stale property tests passed')


events['onResourceStop']('housing')
assert(targetReleased==1 and not registered)
print('TV target is reused across transitions and released on stop')
