HousingDataReady=true
local callbacks,stored, entities, props = {},nil,{[11]=true}, {model=123,plate='TEST'}
local prop={metadata={garage={x=0,y=0,z=0,w=90}}}
local identifier='owner'
local bags = {}
function Entity(e)
  bags[e] = bags[e] or setmetatable({}, {__index={set=function(self,key,value) self[key]=value end}})
  return {state=bags[e]}
end
function GetEntityHeading() return 0 end
function SetEntityHeading() end
function SetEntityCoords(entity,x,y,z) assert(entity==11 and x==0 and y==0 and z==0) end
local inVehicle=false
local failDelete=false
local ownedStatus=0
local claimResult=1
SV={GetPlayer=function() return {} end,GetIdentifier=function() return identifier end}
library={HasPermissions=function(_,who) return who=='owner' end,RegisterCallback=function(n,fn) callbacks[n]=fn end}
function GetProperty(id) if id=='1' then return prop end end
function GetPlayerPed() return 9 end
function GetPlayerRoutingBucket() return 0 end
function GetEntityCoords(entity) return {x=entity==11 and 2 or 0,y=0,z=0} end
function NetworkGetEntityFromNetworkId(net) if net==100 then return 11 end return 0 end
function DoesEntityExist(entity) return entities[entity] or false end
function GetEntityType() return 2 end
function GetEntityRoutingBucket() return 0 end
function GetPlayers() return {'1'} end
function GetVehiclePedIsIn() return inVehicle and 11 or 0 end
function GetVehicleNumberPlateText() return 'TEST' end
function GetEntityModel() return 123 end
function DeleteEntity(entity) entities[entity]=nil end
function CreateVehicleServerSetter() entities[12]=true;return 12 end
function NetworkGetNetworkIdFromEntity(entity) return entity==12 and 101 or 100 end
function GetAllVehicles() local r={} for k in pairs(entities) do r[#r+1]=k end return r end
function TriggerClientEvent() end
json={encode=function(value) return value end, decode=function(value) return value end}
MySQL={query={await=function(sql,args)
  if sql:find('housing_garage_vehicles') then return stored and {stored} or {} end
  if sql:find('owned_vehicles') then return {{owner='owner',plate='TEST',vehicle=props,stored=ownedStatus}} end
end},update={await=function(sql,args)
  if sql:find('UPDATE `owned_vehicles`') then if claimResult==1 then ownedStatus=0 end; return claimResult end
  if sql:find('INSERT') then stored={property_id=args[1],owner=args[2],plate=args[3],vehicle=args[4]};return 1 end
  if sql:find('DELETE') then if failDelete then error('db failed') end; stored=nil;return 1 end
end}}
assert(loadfile('esx_realestate/server/modules/garage_access.lua'))()
assert(loadfile('esx_realestate/server/modules/garage_parking.lua'))()
local function call(name,...)
 local out;callbacks['vms_housing:garage:'..name](1,function(v) out=v end,...);return out
end
assert(call('status','1').ok)
inVehicle=true; assert(not call('park','1',100,props).ok and entities[11] and not stored); inVehicle=false
assert(call('park','1',100,props).ok and stored and entities[11] and bags[11].housingGarageGhost)
assert(call('status','1').parked.canTake)
identifier='other';assert(not call('take','1').ok and stored)
identifier='owner'; failDelete=true; assert(not call('take','1').ok and stored and entities[11] and bags[11].housingGarageGhost); failDelete=false
local released=call('take','1'); assert(released.ok and released.netId==100 and not stored and entities[11] and not bags[11].housingGarageGhost)
entities[11]=true;entities[12]=nil
assert(not call('park','1',100,{model=999,plate='TEST'}).ok and entities[11])
ownedStatus=1; claimResult=0; assert(not call('park','1',100,props).ok and entities[11] and not stored and ownedStatus==1)
claimResult=1; assert(call('park','1',100,props).ok and ownedStatus==0 and stored and entities[11] and bags[11].housingGarageGhost)

entities[11]=nil; assert(call('take','1').ok and not stored and entities[12])
print('garage parking, ownership, model and retrieval tests passed')
