local callback
HousingDataReady = true
local property = {metadata = {garage = {x=0,y=0,z=0}}}
function GetProperty(id) if id == '42' then return property end end
SV = {GetPlayer=function(id) if id == 1 then return {} end end, GetIdentifier=function() return 'char:a' end}
library = {HasPermissions=function(_, id, permission) return id=='char:a' and permission=='garage' end, RegisterCallback=function(_, fn) callback=fn end}
function GetPlayerPed() return 10 end
local positions={[10]={x=0,y=0,z=0},[101]={x=2,y=0,z=0},[102]={x=3,y=0,z=0},[103]={x=30,y=0,z=0},[140]={x=4,y=0,z=0}}
function GetEntityCoords(id) return positions[id] end
function NetworkGetEntityFromNetworkId(id) return id+100 end
function DoesEntityExist(id) return positions[id] ~= nil end
function GetEntityType() return 2 end
function GetEntityRoutingBucket() return 0 end
function GetPlayerRoutingBucket() return 0 end
function GetVehicleNumberPlateText(id) return id==101 and ' OWNED ' or id==140 and ' other ' or 'FOREIGN' end
local rows={{owner='char:a',plate='  owned  ',stored=0},{owner='char:a',plate='OTHER',stored=1},{owner='char:b',plate='FOREIGN',stored=0}}
MySQL = {query={await=function(_, args) assert(args[1]=='char:a'); return rows end}}
assert(loadfile('esx_realestate/server/modules/garage_access.lua'))()
assert(loadfile('esx_realestate/server/modules/garage_candidates.lua'))()
local function check(ids) local r;callback(1,function(value) r=value end,'42',ids);return r end
local result=check({1,1,2,3,40})
assert(result.ok and #result.vehicles==2 and result.vehicles[1].plate=='OWNED' and result.vehicles[1].available)
assert(result.vehicles[2].plate=='OTHER' and result.vehicles[2].available)
local ids={} for i=1,39 do ids[i]=1000+i end ids[40]=1
assert(#check(ids).vehicles==1) -- own vehicle is not dropped behind 30 others
rows[#rows+1]={owner='char:a',plate='OWNED ',stored=0}
assert(#check({1}).vehicles==0) -- ambiguous plates never selectable
local resultMissing;callback(1,function(value) resultMissing=value end,'999',{1});assert(not resultMissing.ok)
positions[10]={x=100,y=0,z=0}; assert(check({1}).reason=='distance')
print('garage candidates: ownership, normalized plates, stored status, limit and distance passed')
