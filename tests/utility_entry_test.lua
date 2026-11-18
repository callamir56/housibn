local f=assert(io.open('esx_realestate/server/main.lua')); local code=f:read('*a'); f:close()
local a=assert(code:find('RegisterNetEvent("vms_housing:sv:enterHouse")',1,true))
local b=assert(code:find('RegisterNetEvent("vms_housing:sv:exitHouse")',a,true))-1
local cb
function RegisterNetEvent() end
function AddEventHandler(_,fn) cb=fn end
local prop={type='shell',metadata={shell='map',exit={x=1,y=2,z=3}}}
local denied,teleports=0,0
function GetPlayerPed() return 7 end
function GetProperty() return prop end
function IsAllowedToRaid() return true end
function SetEntityCoords() teleports=teleports+1 end
function SetEntityHeading() end
function SetPlayerRoutingBucket() end
function vector3(x,y,z) return {x=x,y=y,z=z} end
function Player() return {state={}} end
function TriggerClientEvent(event) if event=='vms_housing:cl:utilityEntryDenied' then denied=denied+1 end end
json={encode=function() return '{}' end}
MySQL={query=function() end}
SV={GetPlayer=function() return {set=function() end} end,GetIdentifier=function() return 'id' end}
library={UtilityEntryBlocked=function() return true end, Notification=function() end}
Config={Core='ESX',UtilityAccess={AllowPoliceDuringRaid=true}}
AvailableShells={map={doors={x=1,y=2,z=3,heading=0}}}
source=3
assert(load('local adminAllowedSources = {}\n'..code:sub(a,b)))()
cb('12'); assert(denied==1 and teleports==0 and not prop.playersInside)
prop.isUnderRaid=true; cb('12'); assert(teleports==1 and #prop.playersInside==1)
print('server utility entry rejection and authorized raid exception passed')
