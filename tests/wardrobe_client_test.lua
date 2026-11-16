-- Run from the repository root; menu, skinchanger and network callbacks are mocked.
Config={Clothing='esx_skin'}
local menuName, menuOptions, selectHandler, cancelHandler
local menu = {close=function() end}
ESX={UI={Menu={Open=function(_, _, name, opts, select, cancel)
  menuName, menuOptions, selectHandler, cancelHandler = name, opts, select, cancel
end, CloseAll=function() end}}}
CL={Notification=function() end}
function GetResourceState() return 'started' end
local saved, loaded
local outfit={slot=1,name='Test',skin={sex=0,tshirt_1=10}}
library={Callback=function(_, cb, action, data)
  if action=='list' then cb({ok=true,outfits={outfit}})
  elseif action=='save' then saved=data; cb({ok=true})
  elseif action=='delete' then cb({ok=true}) end
end}
function TriggerEvent(name, arg1, arg2)
  if name=='skinchanger:getSkin' then arg1({sex=0,tshirt_1=9})
  elseif name=='skinchanger:loadClothes' then loaded=arg2 end
end
assert(loadfile('esx_realestate/integration/[clothing]/esx_skin.lua'))()
OpenWardrobe(); assert(menuName=='outfits' and #menuOptions.elements==2)
selectHandler({current={value='save'}},menu); assert(menuName=='outfit_name')
selectHandler({value='My Outfit'},menu); assert(saved.name=='My Outfit' and saved.skin.tshirt_1==9)
assert(menuName=='outfits')
selectHandler({current={outfit=outfit}},menu); assert(menuName=='outfit_actions')
selectHandler({current={value='wear'}},menu); assert(loaded == outfit.skin and menuName=='outfits')
print('wardrobe menu save and wear flow passed')
