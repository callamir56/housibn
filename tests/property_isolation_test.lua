-- Exercise the actual broadcast reload block with two properties and a stale callback.
local f=assert(io.open('esx_realestate/client/main.lua')); local text=f:read('*a'); f:close()
local block=assert(text:match('(%-%- Ignore broadcasts for other homes:.-)\n%s*%-%- Apply IPL theme reload'))
local refresh=assert(load('return function(propertyId, reloadWorldFurniture)\n'..block..'\nend'))()
local removed,loaded,delayed=0,{},nil
Properties={['1']={furniture={'one'},type='shell'},['2']={furniture={'two'},type='shell'}}
CurrentProperty='1'; local zone='2'
function GetCurrentPropertyId() return zone end
Property={RemoveFurniture=function(_,_,cb) removed=removed+1; delayed=cb end,LoadFurniture=function(_,env,data,id) loaded[#loaded+1]={env,data,id} end}
refresh('2',true); assert(removed==0 and #loaded==0) -- other home broadcasts do nothing
refresh('1',true); assert(removed==1); delayed(); assert(#loaded==1 and loaded[1][2][1]=='one' and loaded[1][3]=='1')
refresh('1',true); CurrentProperty='2'; delayed(); assert(#loaded==1) -- callback after a move cannot load stale furniture
CurrentProperty=nil; zone='2'; refresh('1',true); assert(removed==2)
refresh('2',true); delayed(); assert(#loaded==2 and loaded[2][1]=='outside' and loaded[2][2][1]=='two')

local sf=assert(io.open('esx_realestate/server/main.lua')); local server=sf:read('*a'); sf:close()
local sale=assert(server:match('(RegisterNetEvent%("vms_housing:sv:automaticSale".-)\n%-%- =+'))
assert(sale:find('DELETE FROM houses_furniture WHERE `house_id` = ?',1,true))
assert(not sale:find('DELETE FROM houses_furniture WHERE `id` = ?',1,true))
print('property furniture broadcasts, stale reload and sale isolation passed')
-- Execute sale handler with crossed furniture/house IDs (old query deleted
-- house 2's row id 1 when house 1 was sold).
local handler
function RegisterNetEvent() end
function AddEventHandler(_,fn) handler=fn end
source=5
local prop={owner='owner',metadata={},sale={defaultPrice=0},rental={},furniture={{id=2}}}
SV={GetPlayer=function() return {} end,GetIdentifier=function() return 'owner' end,AddMoney=function() end}
library={HasPermissions=function() return true end,Notification=function() end}
function GetProperty() return prop end
function TRANSLATE(x) return x end
function TriggerClientEvent() end
json={encode=function() return '{}' end}
local db={{id=2,house_id=1},{id=1,house_id=2}}
MySQL={query=function(sql,args)
    if sql:find('DELETE FROM houses_furniture',1,true) then
        for i=#db,1,-1 do if db[i].house_id==args[1] then table.remove(db,i) end end
    end
end}
assert(load(sale))()
handler('1')
assert(#db==1 and db[1].house_id==2 and db[1].id==1)
print('selling one house preserves another house furniture')
local delivered=assert(text:match('elseif action == "deliveredFurniture" then(.-)elseif action == "soldFurniture"'))
local deliver=assert(load('return function(data) local propertyId; '..delivered..' end'))()
CurrentProperty='1'; zone='2'; Config={DeliveryType=3}
Properties={['1']={metadata={delivery=true,deliveryType='inside'},furniture={{id=5,metadata={}}}},['2']={metadata={delivery=true,deliveryType='inside'},furniture={{id=6,metadata={}}}}}
local deliveries=0
Property={LoadedFurnitures={},LoadFurniture=function(_,_,_,id) deliveries=deliveries+1; assert(id=='1') end}
deliver({['2']={6},['999']={7}}); assert(deliveries==0 and Properties['2'].furniture[1].metadata.delivered)
deliver({['1']={5}}); assert(deliveries==1)
print('delivery updates stay scoped to active property')
