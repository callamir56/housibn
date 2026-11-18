-- The real server and client handlers are connected by mocked FiveM callbacks.
local serverCallbacks, clientEvents, serverEvents, nui, tasks = {}, {}, {}, {}, {}
local registered, creates, destroys, releases = false,0,0,0
CurrentProperty='7'; HousingDataReady=true; openedMenu=nil
Config={HousingTV={Enabled=true,ControlPermission='furniture',MaxDistance=3.5,Models={tv=true}}}
local prop={owner='alice',metadata={},furniture={{id=5,stored=0,model='tv',position={x=1,y=2,z=3,environment='inside'}}}}
SV={GetPlayer=function() return {} end, GetIdentifier=function() return 'alice' end}
library={
 RegisterCallback=function(name,fn) serverCallbacks[name]=fn end,
 Callback=function(name,fn,...) serverCallbacks[name](1,fn,...) end,
 HasPermissions=function() return true end,
 Notification=function() end,
}
CL={Notification=function(message) error('unexpected: '..message) end}
function GetProperty(id) if id=='7' then return prop end end
function IsPlayerInProperty(src,id) return src==1 and id=='7' end
function GetPlayerRoutingBucket() return 8 end
function GetPlayerPed() return 10 end
function GetEntityCoords() return {x=1,y=2,z=3} end
function GetPlayers() return {'1'} end
function RegisterNetEvent(name,fn)
 if name:find(':sv:') or name=='vms_housing:tv:control' then serverEvents[name]=fn else clientEvents[name]=fn end
end
function AddEventHandler() end
function RegisterNUICallback(name,fn) nui[name]=fn end
function TriggerClientEvent(name,src,...) assert(src==1); clientEvents[name](...) end
function TriggerServerEvent(name,...) source=1; serverEvents[name](...) end
function CreateThread(fn) tasks[#tasks+1]=fn end
function IsNamedRendertargetRegistered() return registered end
function RegisterNamedRendertarget() assert(not registered); registered=true end
function ReleaseNamedRendertarget() assert(registered); registered=false; releases=releases+1 end
function IsNamedRendertargetLinked() return false end
function LinkNamedRendertarget() end
function GetHashKey() return 123 end
function GetNamedRendertargetRenderId() return 50 end
function CreateRuntimeTxd() return 1 end
function CreateDui() creates=creates+1; return creates end
function DestroyDui() destroys=destroys+1 end
function GetCurrentResourceName() return 'housing' end
function SetNuiFocus() end
function SendNUIMessage() end
assert(loadfile('esx_realestate/server/modules/television.lua'))()
assert(loadfile('esx_realestate/client/modules/television.lua'))()
HousingTV.Refresh('7'); assert(registered and creates==0)
HousingTV.Control('7',5,'play')
local result; nui['housingTV:submit']({url='https://www.aparat.com/v/BNMK5'},function(r) result=r end)
assert(result.ok and creates==1 and destroys==0 and releases==0 and registered)
HousingTV.Control('7',5,'off')
assert(destroys==1 and releases==0 and registered)
local state; serverCallbacks['vms_housing:tv:state'](1,function(r) state=r end,'7')
assert(state.ok and not state.state.on)
print('single TV play and single off work without re-registering target')
