-- Run from the repository root; NUI, skinchanger and network callbacks are mocked.
Config={Clothing='esx_skin'}
local callbacks, messages, focus, saved, loaded = {}, {}, false, nil, nil
function RegisterNUICallback(name, fn) callbacks[name] = fn end
function SendNUIMessage(message) messages[#messages + 1] = message end
function SetNuiFocus(value) focus = value end
function GetResourceState() return 'started' end
CL={Notification=function() end}
local outfit={slot=1,name='Test',skin={sex=0,tshirt_1=10}}
library={Callback=function(_, cb, action, data)
  if action=='list' then cb({ok=true,outfits={outfit}})
  elseif action=='save' then saved=data; cb({ok=true})
  elseif action=='delete' then assert(data.slot==1); cb({ok=true}) end
end}
function TriggerEvent(name, arg1, arg2)
  if name=='skinchanger:getSkin' then arg1({sex=0,tshirt_1=9})
  elseif name=='skinchanger:loadClothes' then loaded=arg2 end
end
assert(loadfile('esx_realestate/integration/[clothing]/esx_skin.lua'))()
OpenWardrobe(); assert(focus and openedMenu=='Wardrobe' and messages[1].actionName=='Open')
assert(messages[2].actionName=='Update' and messages[2].data[1].name=='Test' and messages[2].data[1].skin==nil)
local ack
callbacks['wardrobe:save']({name='My Outfit'},function(value) ack=value.ok end)
assert(ack and saved.name=='My Outfit' and saved.skin.tshirt_1==9)
callbacks['wardrobe:wear']({slot=1},function(value) ack=value.ok end)
assert(ack and loaded == outfit.skin)
callbacks['wardrobe:delete']({slot=1},function(value) ack=value.ok end)
assert(ack)
callbacks['wardrobe:close']({},function(value) ack=value.ok end)
assert(ack and not focus and not openedMenu and messages[#messages].actionName=='Close')
callbacks['wardrobe:wear']({slot=1},function(value) ack=value.ok end); assert(not ack)
print('wardrobe NUI save, wear, delete and close passed')
