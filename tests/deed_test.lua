HousingDataReady=true
Config={Inventory="ox_inventory"}
function GetResourceState() return "started" end
local granted
exports={ox_inventory={AddItem=function(_,src,name,count,meta) granted={src=src,name=name,count=count,meta=meta}; return true end}}
local callback, db = nil, nil
local currentId='owner:a'
local property={owner='owner:a',owner_name='A Player',name='My House',address='Example St',metadata={locked=true}}
SV={GetPlayer=function() return {} end,GetIdentifier=function() return currentId end,GetCharacterName=function() return 'A Player' end}
function GetProperty(id) if id=='42' then return property end end
library={RegisterCallback=function(name,cb) assert(name=='vms_housing:deed'); callback=cb end}
json={encode=function(v) return v end}
MySQL={update={await=function(_,args) db=args[1]; assert(args[2]==42 and args[3]=='owner:a'); return 1 end}}
assert(loadfile('esx_realestate/server/modules/deed.lua'))()
local function request(action,id) local result;callback(1,function(r) result=r end,action,id);return result end
local view=request('view','42');assert(view.ok and view.owner=='A Player' and not view.signature)
assert(not request('item','42').ok and not granted)
currentId='other'; assert(not request('view','42').ok and not request('sign','42').ok)
currentId='owner:a';local signed=request('sign','42');assert(signed.ok and signed.signature=='A Player' and signed.signedAt and db.deedSignature.owner=='owner:a')
assert(request('view','42').signature=='A Player')
assert(request('item','42').ok and granted.name=='property_deed' and granted.meta.propertyId=='42' and granted.meta.owner=='owner:a')
property.owner='owner:b';currentId='owner:b';SV.GetCharacterName=function() return 'B Player' end;property.owner_name='B Player'
assert(request('view','42').ok and not request('view','42').signature)
assert(not request('view','99').ok)
print('deed owner authorization, signing, persistence and ownership change passed')
