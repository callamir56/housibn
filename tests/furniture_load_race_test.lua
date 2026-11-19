function exports() end
assert(loadfile('esx_realestate/client/modules/property.lua'))()
local deleted={}
function vector3(x,y,z) return {x=x,y=y,z=z} end
function GetGameTimer() return 0 end
function DoesEntityExist(e) return e==12 end
function DeleteObject(e) deleted[#deleted+1]=e end
CL={Target=function() end}
library={SpawnProp=function()

    Property:RemoveFurniture()
    return 12
end}
local a={{id=3,stored=0,model='chair',position={environment='inside',x=1,y=2,z=3}}}
Property:LoadFurniture('inside',a,'1')
assert(#Property.LoadedFurnitures==0 and #deleted==1 and deleted[1]==12)
print('stale furniture load discarded after property transition')
