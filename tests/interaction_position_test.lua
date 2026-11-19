function GetEntityModel() return 11 end
function GetModelDimensions() return {x=-1,y=-0.5,z=-0.2},{x=1,y=0.5,z=0.8} end
assert(loadfile('esx_realestate/client/modules/interaction_position.lua'))()
local bed=HousingInteractionPosition.Resolve(5,nil,'bed')
assert(math.abs(bed.z-0.55)<0.0001 and bed.heading==90 and bed.x==0 and bed.y==0)
local bath=HousingInteractionPosition.Resolve(5,nil,'bath')
assert(math.abs(bath.z-0.2)<0.0001 and bath.heading==90)
local custom=HousingInteractionPosition.Resolve(5,{x=0.3,z=1.2,heading=180},'bed')
assert(custom.x==0.3 and custom.z==1.2 and custom.y==0 and custom.heading==180)
print('automatic model bounds and per-model placement passed')
