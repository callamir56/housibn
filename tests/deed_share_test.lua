-- Mock ox_inventory and OneSync; no client can supply deed or owner data.
HousingDataReady=true;Config={Inventory='ox_inventory'}
local handlers,net,callbacks,emitted={}, {}, {}, {}
local positions={[1]={x=0,y=0,z=0},[2]={x=1,y=0,z=0},[3]={x=20,y=0,z=0}}
local players={1,2,3};local item={name='property_deed',metadata={propertyId='42',owner='owner'}}
local prop={owner='owner',owner_name='Owner',metadata={}}
function AddEventHandler(n,fn) handlers[n]=fn end
function RegisterNetEvent(n,fn) net[n]=fn end
function CreateThread() end
function GetGameTimer() return 1000 end
function GetResourceState() return 'started' end
function GetPlayers() return players end
function GetPlayerPed(src) return positions[src] and src or 0 end
function GetEntityCoords(ped) return positions[ped] end
function GetPlayerRoutingBucket() return 0 end
function GetProperty(id) if id=='42' then return prop end end
SV={GetPlayer=function(src) if positions[src] then return {id=src} end end,
    GetIdentifier=function(player) return player.id==1 and 'owner' or 'other' end,
    GetCharacterName=function(player) return 'Name '..player.id end}
exports={ox_inventory={GetSlot=function(_,src,slot) if src==1 and slot==5 then return item end end}}
function HousingDeedData(property,id) return {ok=true,id=id,owner=property.owner_name} end
library={Notification=function() end,RegisterCallback=function(n,cb) callbacks[n]=cb end}
function TriggerClientEvent(name,target,...) emitted[#emitted+1]={name=name,target=target,args={...}} end
assert(loadfile('esx_realestate/server/modules/deed_share.lua'))()
local used=handlers['ox_inventory:usedItem']
used(1,'property_deed',5,item.metadata)
assert(#emitted==2 and emitted[1].target==1 and emitted[2].target==2)
local id=emitted[1].args[1]
source=3;net['vms_housing:deedShare:close'](id);assert(#emitted==2)
source=2;net['vms_housing:deedShare:close'](id);assert(#emitted==3 and emitted[3].target==2)
source=1;net['vms_housing:deedShare:close'](id);assert(#emitted==4 and emitted[4].target==1)
-- Multiple nearby players force selection, which is rechecked when clicked.
emitted={};positions[3]={x=2,y=0,z=0};used(1,'property_deed',5,item.metadata)
assert(#emitted==1 and emitted[1].name:find(':select'))
local result
positions[2]={x=50,y=0,z=0};callbacks['vms_housing:deedShare:choose'](1,function(r) result=r end,2);assert(not result.ok)
callbacks['vms_housing:deedShare:choose'](1,function(r) result=r end,3);assert(result.ok and #emitted==3)
id=emitted[2].args[1];source=1;net['vms_housing:deedShare:close'](id);assert(#emitted==5 and emitted[4].target==3 and emitted[5].target==1)
-- Stale/transferred/deleted items cannot be used to impersonate an owner.
emitted={};prop.owner='someone_else';used(1,'property_deed',5,item.metadata);assert(#emitted==0)
prop.owner='owner';item=nil;used(1,'property_deed',5,{propertyId='42',owner='owner'});assert(#emitted==0)
print('deed sharing target, ownership, distance and independent close passed')
