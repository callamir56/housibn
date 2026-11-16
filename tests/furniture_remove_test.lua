-- Run with Lua 5.4+ from the repository root.
local f=assert(io.open('esx_realestate/server/main.lua')); local text=f:read('*a'); f:close()
local block=assert(text:match('(RegisterNetEvent%("vms_housing:sv:sellFurniture".-)\n%-%-========================================================================\n%-%- Safe:'))
local events, balance, deleted = {}, 0, 0
function RegisterNetEvent(name, fn) events[name]=fn end
local prop={furniture={{id=11,model='chair',stored=1},{id=12,model='chair',stored=0}}}
function getPlayerAndIdentifier() return {}, 'owner' end
function getPropertyOrReturn() return prop end
function requirePermissionOrNotify() return true end
function TRANSLATE(s) return s end
function TriggerClientEvent() end
Furniture={chair={price=100}}; Config={FurnitureSellPercentage=50}; source=1
SV={AddMoney=function(_,_,n) balance=balance+n end}; library={Notification=function() end}
MySQL={update={await=function(_,args) deleted=deleted+1; return 1 end}}
assert(load(block))()
events['vms_housing:sv:sellFurniture'](6,99,'chair'); assert(balance==0 and deleted==0)
events['vms_housing:sv:sellFurniture'](6,11,'different'); assert(balance==50 and deleted==1 and #prop.furniture==1)
events['vms_housing:sv:sellFurniture'](6,11,'chair'); assert(balance==50 and deleted==1)
events['vms_housing:sv:removeFurniture'](6,12,'chair'); assert(deleted==2 and #prop.furniture==0)
print('furniture remove and repeat-sale checks passed')
