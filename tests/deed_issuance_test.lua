HousingDataReady=true;Config={Inventory='ox_inventory',DeedAgencyJob='realestateagent'}
local property={owner='owner',metadata={deedSignature={owner='owner',name='Owner',date='2026-01-01'}}}
local players={[1]={id='owner',job='citizen'},[2]={id='agent',job='realestateagent'}}
local rows,items,nextId,failAdd={}, {}, 0, false
function GetResourceState() return 'started' end
function GetProperty(id) if id=='42' then return property end end
SV={GetPlayer=function(id) return players[id] end,GetIdentifier=function(p) return p.id end,GetPlayerJob=function(p) return p.job end}
json={encode=function(v) return v end}
MySQL={query={await=function(sql,args)
 local result={}
 if sql:find('SELECT `owner_slot`') then
  for _,r in pairs(rows) do if r.property==args[1] and r.revision==args[2] and r.slot then result[#result+1]={owner_slot=r.slot} end end
 elseif sql:find('SELECT `id`') then local r=rows[args[1]];if r and r.property==args[2] and r.revision==args[3] and r.owner==args[4] and r.holder==args[5] then result[1]={id=args[1]} end end
 return result
end},update={await=function(sql,args)
 if sql:find('UPDATE `houses`') then assert(args[3]==property.owner);return 1 end
 if sql:find('DELETE FROM `housing_deed_issuances`') then rows[args[1]]=nil;return 1 end
end},insert={await=function(_,args)
 nextId=nextId+1;rows[nextId]={property=args[1],revision=args[2],owner=args[3],holder=args[4],kind=args[5],slot=args[6]};return nextId
end}}
exports={ox_inventory={AddItem=function(_,src,name,count,meta) if failAdd then return false end;items[src]={name=name,metadata=meta};return true end,GetSlot=function(_,src) return items[src] end}}
assert(loadfile('esx_realestate/server/modules/deed_issuance.lua'))()
assert(HousingDeedIssue(1,'42','owner','owner'))
assert(items[1].metadata.description=='Original deed' and HousingDeedCopyCount(property,'42')==1)
local oldItem=items[1]
assert(HousingDeedIssue(1,'42','owner','owner'))
assert(items[1].metadata.description=='Deed copy' and HousingDeedCopyCount(property,'42')==2)
assert(not HousingDeedIssue(1,'42','owner','owner'))
for i=1,4 do assert(HousingDeedIssue(2,'42','owner','agency')) end
assert(HousingDeedCopyCount(property,'42')==2)
assert(HousingDeedValidateItem(2,{propertyId='42',slot=1})==property)
players[2].id='impostor';assert(not HousingDeedValidateItem(2,{propertyId='42',slot=1}));players[2].id='agent'
property.owner='newOwner';property.metadata.deedSignature={owner='newOwner',name='New Owner'};players[1].id='newOwner'
assert(not HousingDeedValidateItem(1,{propertyId='42',slot=1}))
failAdd=true;assert(not HousingDeedIssue(1,'42','newOwner','owner'));assert(HousingDeedCopyCount(property,'42')==0)
failAdd=false;assert(HousingDeedIssue(1,'42','newOwner','owner'));assert(items[1].metadata.description=='Original deed')
print('deed issuance limits, agency copies, binding and rollback passed')
