-- Run with Lua 5.4+ from the repository root.
function exports() end
assert(loadfile('esx_realestate/client/modules/property.lua'))()
local zoneId = '6'
local data = {id = 6, type = 'shell', metadata = {shell = 'map', lightState = true}, furniture = {}}
Properties = {['6'] = data}
AvailableShells = {map = {mapInterior = true}}
CL = {CanEnterHouse = function() return true end}
library = {
  Callback = function(_, cb) cb(true) end,
  RequestHousingShell = function() return true end,
  PlayAudio = function() end,
}
function GetCurrentPropertyId() return zoneId end
function GetCurrentPropertyData() return nil end
function SpawnHousingShell() return 0 end
function DoScreenFadeOut() end
local fades, frozen, entered = 0, nil, nil
function DoScreenFadeIn() fades = fades + 1 end
function PlayerPedId() return 7 end
function FreezeEntityPosition(_, state) frozen = state end
function TriggerServerEvent(_, id) entered = id end
function SetArtificialLightsState() end
local waitCount = 0
function Wait()
  waitCount = waitCount + 1
  if waitCount == 1 then zoneId = nil end -- zone disappears during fade
  if waitCount == 3 then CurrentPropertyData = nil end -- async cache refresh
end
function Property:RemoveFurniture() end
function Property:LoadStaticInteractable() end
function Property:LoadFurniture() end
Property:EnterProperty(data)
assert(entered == '6' and CurrentProperty == '6' and CurrentPropertyData == data)
assert(fades == 1 and frozen == false)
print('property entry async context test passed')
-- A missing interior definition should notify the player and stop cleanly.
CurrentShell=nil; CurrentIPL=nil
local alerted, complete = false, nil
CL.Notification=function() alerted=true end
Property:EnterProperty({id=6,type='shell',metadata={shell='missing'}}, '6', function(ok) complete=ok end)
assert(alerted and complete==false)
print('missing property shell reports to player and aborts')
