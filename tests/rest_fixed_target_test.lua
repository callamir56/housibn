local threads, target, option = {}, nil, nil
Config={TargetResource='ox_target',HousingRest={Enabled=true, FixedBeds=true, Models={bed=true}}}
Furniture={custombed={tag='bed'}, chair={tag='chair'}}
CurrentProperty='7'; Property={LoadedFurnitures={{entity=12}}}
function CreateThread(fn) threads[#threads+1]=fn end
function RegisterNetEvent() end
function AddEventHandler() end
function DoesEntityExist() return true end
exports={ox_target={addModel=function(_,models,opts) target=models; option=opts[1] end}}
assert(loadfile('esx_realestate/client/modules/rest.lua'))()
assert(HousingRest.IsBed('bed') and HousingRest.IsBed('custombed') and not HousingRest.IsBed('chair'))
table.remove(threads,1)()
assert(target[1]=='bed' and option.canInteract(13) and not option.canInteract(12))
CurrentProperty=nil; assert(not option.canInteract(13))
print('fixed and tagged bed targeting passed')
