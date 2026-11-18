local events, registered = {}, {}
CurrentProperty='7'
Config={}
function RegisterNetEvent(name,fn) registered[name]=fn end
function AddEventHandler(name,fn) registered[name]=fn end
function TriggerServerEvent(name,token) events[#events+1]={name,token} end
function PlayerPedId() return 10 end
function CreateThread(fn) end
function StopAnimTask() end
function IsEntityDead() return false end
local playing=true
function IsEntityPlayingAnim() return playing end
local health=198
function GetEntityHealth() return health end
function GetEntityMaxHealth() return 200 end
function SetEntityHealth(_,v) health=v end
CL={Notification=function() end}
library={PlayAnimation=function() end,Callback=function(_,cb) cb({ok=true,token=17}) end}
assert(loadfile('esx_realestate/client/modules/rest.lua'))()
HousingRest.Start('7',4)
registered['vms_housing:rest:tick'](17,5); assert(health==200)
health=150; registered['vms_housing:rest:tick'](16,5); assert(health==150)
playing=false; registered['vms_housing:rest:tick'](17,5); assert(health==150 and events[1][1]=='vms_housing:rest:cancel')
print('rest client health cap, token and animation interruption tests passed')
