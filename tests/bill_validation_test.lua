
local f = assert(io.open('esx_realestate/server/main.lua'))
local text = f:read('*a'); f:close()
local start = assert(text:find('RegisterNetEvent("vms_housing:sv:payTheBill", function', 1, true))
local finish = assert(text:find('\nend)', start, true)) + 5
local handler
function RegisterNetEvent(_, cb) handler = cb end
local bill = {id=1, period='01:2020', type='services', paid=1, total=100}
local property = {bills={bill}, unpaidBills=1}
function getPlayerAndIdentifier() return {}, 'owner' end
function getPropertyOrReturn() return property end
function requirePermissionOrNotify() return true end
local debits = 0
SV = {GetMoney=function() return 1000 end, RemoveMoney=function() debits=debits+1 end, Webhook=function() end, GetCharacterName=function() return 'Test' end}
library = {Notification=function() end, RefreshUtilityDebt=function() end, HandleLightStateMonthOverlap=function() end}
function TRANSLATE() return 'ok' end
WebhookText = {['TITLE.PaidBillServices']='', ['DESCRIPTION.PaidBillServices']='%s %s %s %s %s'}
MySQL = {update={await=function() return 1 end}}
function TriggerClientEvent() end
source = 1
assert(load('local utilityPaymentLocks = {}\n' .. text:sub(start,finish)))()
handler('1','01:2020','services'); assert(debits==0)
bill.paid=0; handler('1','01:2020','invalid'); assert(debits==0)
bill.total=-1; handler('1','01:2020','services'); assert(debits==0)
bill.total=100; handler('1','01:2020','services'); assert(debits==1 and bill.paid==1)
handler('1','01:2020','services'); assert(debits==1)
print('bill validation test passed')

bill.paid=0; local refunded=0; local calls=0
SV.AddMoney=function(_,_,amount) refunded=refunded+amount end
MySQL.update.await=function() calls=calls+1; coroutine.yield(); return 1 end
local first=coroutine.create(function() handler('1','01:2020','services') end)
assert(coroutine.resume(first)); handler('1','01:2020','services')
assert(debits==2 and calls==1)
assert(coroutine.resume(first)); assert(bill.paid==1)

bill.paid=0; MySQL.update.await=function() return 0 end
handler('1','01:2020','services'); assert(debits==3 and refunded==100 and bill.paid==0)
MySQL.update.await=function() error('database unavailable') end
handler('1','01:2020','services'); assert(debits==4 and refunded==200 and bill.paid==0)
print('concurrent payment lock and refund tests passed')
