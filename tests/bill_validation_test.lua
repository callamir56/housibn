-- Isolate the existing payment handler so validation can be tested without FiveM.
local f = assert(io.open('esx_realestate/server/main.lua'))
local text = f:read('*a'); f:close()
local start = assert(text:find('RegisterNetEvent("vms_housing:sv:payTheBill", function', 1, true))
local finish = assert(text:find('\nend)', start, true)) + 5
local handler
function RegisterNetEvent(_, cb) handler = cb end
local bill = {period='01:2020', type='services', paid=1, total=100}
local property = {bills={bill}, unpaidBills=1}
function getPlayerAndIdentifier() return {}, 'owner' end
function getPropertyOrReturn() return property end
function requirePermissionOrNotify() return true end
local debits = 0
SV = {GetMoney=function() return 1000 end, RemoveMoney=function() debits=debits+1 end, Webhook=function() end, GetCharacterName=function() return 'Test' end}
library = {Notification=function() end}
function TRANSLATE() return 'ok' end
WebhookText = {['TITLE.PaidBillServices']='', ['DESCRIPTION.PaidBillServices']='%s %s %s %s %s'}
MySQL = {query=function() end}
function TriggerClientEvent() end
source = 1
assert(load(text:sub(start,finish)))()
handler('1','01:2020','services'); assert(debits==0)
bill.paid=0; handler('1','01:2020','invalid'); assert(debits==0)
bill.total=-1; handler('1','01:2020','services'); assert(debits==0)
bill.total=100; handler('1','01:2020','services'); assert(debits==1 and bill.paid==1)
handler('1','01:2020','services'); assert(debits==1)
print('bill validation test passed')
