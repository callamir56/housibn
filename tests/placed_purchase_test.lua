
local f = assert(io.open('esx_realestate/server/main.lua'))
local sourceText = f:read('*a'); f:close()
local block = assert(sourceText:match('(local pendingPlacedFurniturePurchases = {}.-)library%.RegisterCallback%("vms_housing:placeFurniture"'))
local callback, money, inserts, events = nil, 500, 0, 0
local prop = {owner='id', metadata={allowFurnitureInside=true, upgrades={}}, furniture={}}
local player = {}
SV = {GetPlayer=function() return player end, GetIdentifier=function() return 'id' end,
  GetMoney=function(_, account) assert(account == 'cash'); return money end,
  RemoveMoney=function(_, account, n) assert(account == 'cash'); money = money-n end,
  AddMoney=function(_, account, n) assert(account == 'cash'); money = money+n end}
function GetProperty(id) if tostring(id)=='6' then return prop end end
function Player() return {state={currentProperty='6'}} end
function GetPlayerPed() return 1 end
function GetEntityCoords() return {x=0,y=0,z=0} end
function GetFurnitureLimit() return 10 end
function TRANSLATE(v) return v end
function TriggerClientEvent() events = events+1 end
Furniture = {chair={isIndoor=1,price=100,label='Chair'}}
library = {RegisterCallback=function(_, cb) callback=cb end, HasPermissions=function() return true end, Notification=function() end}
json = {encode=function(v) return v end, decode=function(v) return v end}
local fail = false
MySQL = {insert={await=function() inserts=inserts+1; if fail then error('database') end; return inserts end}}
assert(load(block))()
local payload = {model='chair',isInside=true,coords={x=1,y=2,z=3},rotation={x=0,y=0,z=4}}
local result
callback(1,function(v) result=v end,6,payload)
assert(result and money==400 and #prop.furniture==1 and prop.furniture[1].position.yaw==4 and events==1)
fail = true
callback(1,function(v) result=v end,6,payload)
assert(not result and money==400 and #prop.furniture==1)
payload.coords.x=1000
callback(1,function(v) result=v end,6,payload)
assert(not result and money==400 and inserts==2)
payload.coords.x=1
library.HasPermissions=function() return false end
callback(1,function(v) result=v end,6,payload)
assert(not result and money==400 and inserts==2)
print('placed furniture purchase checks passed')
