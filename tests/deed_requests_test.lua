Config={DeedAgencyJob='estate'};HousingDataReady=true
local handlers,events,requests,timers={}, {}, {}, {}
local pos={[1]={x=1,y=0,z=0},[2]={x=100,y=0,z=0},[3]={x=1,y=0,z=0}}
local players={[1]={source=1,id='agent',job='estate'},[2]={source=2,id='owner',job='citizen'},[3]={source=3,id='fake',job='citizen'}}
local prop={owner='owner',name='House',metadata={enter={x=0,y=0,z=0},deedSignature={owner='owner'}}}
SV={GetPlayer=function(src) return players[src] end,GetIdentifier=function(p) return p.id end,GetPlayerJob=function(p) return p.job end,GetSource=function(p) return p.source end,GetCharacterName=function(p) return p.id end,GetPlayerByIdentifier=function(id) if id=='owner' then return players[2] end end}
function GetProperty(id) if id=='42' then return prop end end
function GetPlayerRoutingBucket() return 0 end
function GetPlayerPed(id) return pos[id] and id or 0 end
function GetEntityCoords(id) return pos[id] end
function GetGameTimer() return 100 end
function SetTimeout(_,fn) timers[#timers+1]=fn end
function RegisterNetEvent(n,f) handlers[n]=f end
function AddEventHandler(n,f) handlers[n]=f end
function TriggerClientEvent(n,to,...) events[#events+1]={name=n,to=to,args={...}} end
local issues=0
function HousingDeedIssue(src,id,owner,kind) assert(src==1 and id=='42' and owner=='owner' and kind=='agency');issues=issues+1;return true,'Issued' end
assert(loadfile('esx_realestate/server/modules/deed_requests.lua'))()
source=3;handlers['vms_housing:deedAgency:request']('42');assert(issues==0 and events[#events].name=='vms_housing:notification')
source=1;handlers['vms_housing:deedAgency:request']('42');local prompt=events[#events-1];assert(prompt.name:find(':prompt') and prompt.to==2);local id=prompt.args[1]
source=3;handlers['vms_housing:deedAgency:answer'](id,true);assert(issues==0)
source=2;handlers['vms_housing:deedAgency:answer'](id,false);assert(issues==0)
source=1;handlers['vms_housing:deedAgency:request']('42');id=events[#events-1].args[1]
source=2;handlers['vms_housing:deedAgency:answer'](id,true);assert(issues==1)
source=1;handlers['vms_housing:deedAgency:request']('42');id=events[#events-1].args[1];pos[1]={x=100,y=0,z=0}
source=2;handlers['vms_housing:deedAgency:answer'](id,true);assert(issues==1)
print('agency job, consent, rejection and proximity checks passed')
