local f=assert(io.open('esx_realestate/server/lib.lua')); local s=f:read('*a'); f:close()
local start=assert(s:find('function library.RefreshUtilityDebt',1,true))
local finish=assert(s:find('function library.GetOrCreateBills',start,true)) - 1
library={}; Config={UseServiceBills=true, UtilityAccess={BlockEntry=true,OverdueBillsToBlock=2}}
assert(load(s:sub(start,finish)))()
local now=os.time({year=2026,month=1,day=15,hour=12})
local property={bills={
 {type='services',period='11:2025',paid=0},
 {type='services',period='12:2025',paid='0'},
 {type='services',period='01:2026',paid=0},
 {type='services',period='02:2026',paid=0},
 {type='services',period='10:2025',paid=1},
 {type='rent',period='09:2025',paid=0},
 {type='services',period='bogus',paid=0},
}}
local blocked,count=library.UtilityEntryBlocked(property,now)
assert(blocked and count==2 and property.unpaidBills==2)
property.bills[1].paid=true
blocked,count=library.UtilityEntryBlocked(property,now)
assert(not blocked and count==1)
Config.UtilityAccess.OverdueBillsToBlock=1
assert(library.UtilityEntryBlocked(property,now))
Config.UtilityAccess.BlockEntry=false
assert(not library.UtilityEntryBlocked(property,now))
Config.UseServiceBills=false
assert(library.RefreshUtilityDebt(property,now)==0)
print('utility debt, year rollover, grace threshold and disabled mode passed')
