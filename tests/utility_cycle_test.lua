local worker
function CreateThread(fn) worker=coroutine.create(fn) end
function Wait() coroutine.yield() end
local period='12:2025'; local realDate=os.date
os.date=function(format, ...) if format=='%m:%Y' then return period end return realDate(format, ...) end
HousingDataReady=true; Config={UseServiceBills=true,AllowedUnpaidBills=2}
Properties={['1']={owner='owner',type='shell',bills={},metadata={lightState=false}},['2']={type='shell',bills={},metadata={}}}
local created, sync=0,0
library={HandleLightStateMonthOverlap=function() end, RefreshUtilityDebt=function() return 0 end,
 GenerateMonthlyBill=function(id,p) created=created+1; return {id=5,period=p,type='services',paid=0} end}
function TriggerClientEvent(event) if event=='vms_housing:cl:utilityDebtSync' then sync=sync+1 end end
assert(loadfile('esx_realestate/server/modules/utility_cycle.lua'))()
assert(coroutine.resume(worker)); period='01:2026'
assert(coroutine.resume(worker)); assert(created==1 and #Properties['1'].bills==1 and sync==1)
assert(coroutine.resume(worker)); assert(coroutine.resume(worker)); assert(created==1)
os.date=realDate
print('monthly utility rollover and unowned property exclusion passed')
