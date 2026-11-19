











if not Config.Shells.KuzQuality then
  return
end


local startDeadline = GetGameTimer() + 10000

while true do
  local state = GetResourceState("kq_shellbuilder")
  if state == "started" then
    break
  end

  if GetGameTimer() > startDeadline then
    startDeadline = -1
    break
  end

  Citizen.Wait(100)
end


if startDeadline == -1 then
  return warn("KuzQuality Shell Creator is not started, please check the resource state.")
end










local function refreshKuzQualityShells()


  GlobalState.vms_housing_kq_shells = exports.kq_shellbuilder:GetShells()


  local shellRegistry = {}

  local shells = GlobalState.vms_housing_kq_shells
  if shells and next(shells) then
    for _, shell in pairs(shells) do

      local shellModel = ("kq_sbx_shell_%s"):format(shell.id)

      shellRegistry[shellModel] = {
        label = shell.title,
        tags = { "kuzquality" },
        rooms = 1,


        model = shellModel,


        doors = {
          x = shell.spawnPoint.x,
          y = shell.spawnPoint.y,

          z = 500.0 + (shell.spawnPoint.z * 1.5),
          heading = shell.spawnPoint.w,
        },
      }
    end



    addShells(shellRegistry)
  end
end







Citizen.CreateThread(function()
  refreshKuzQualityShells()


  Citizen.Wait(500)

  local count = #GlobalState.vms_housing_kq_shells
  if count <= 0 then

    Citizen.Wait(2500)
    refreshKuzQualityShells()
  end
end)







RegisterNetEvent("kq_shellbuilder:update")
AddEventHandler("kq_shellbuilder:update", function()
  refreshKuzQualityShells()
end)
