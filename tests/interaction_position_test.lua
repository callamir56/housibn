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

local current, moves, waits = 0, {}, 0
function Wait(ms) assert(ms==100); waits=waits+1 end
function GetEntityCoords() return {x=4,y=5,z=current} end
function GetPedBoneCoords(_,bone) assert(bone==11816); return {x=4,y=5,z=current-0.4} end
function SetEntityCoordsNoOffset(_,x,y,z,keepTasks,keepIK,warp)
    assert(x==4 and y==5 and keepTasks and keepIK and not warp)
    current=z; moves[#moves+1]=z
end
HousingInteractionPosition.AlignPose(10,{z=1.0},function() return true end)
assert(#moves==1 and math.abs(current-1.4)<0.001 and waits==6)
waits=0; moves={}
HousingInteractionPosition.AlignPose(10,{z=2.0},function() return false end)
assert(#moves==0 and waits==1)
print('animated pelvis correction and cancellation passed')
