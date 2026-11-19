
AvailableShells = {}
AvailableIPLS   = {}








function addShells(shells)

  if not next(shells) then
    return
  end

  for shellName, shellData in pairs(shells) do
    if AvailableShells[shellName] == nil then
      AvailableShells[shellName] = shellData
    else

      if Config and Config.Debug then warn(("Duplicated shell %s! (CANCELED ACTION)"):format(shellName)) end
    end
  end
end









function reloadShells()
  SendNUIMessage({
    action = "Reload",
    availableShells = AvailableShells,
  })
end








function addIPLS(ipls)
  if not next(ipls) then
    return
  end

  for iplName, iplData in pairs(ipls) do
    if AvailableIPLS[iplName] == nil then
      AvailableIPLS[iplName] = iplData
    else
      if Config and Config.Debug then warn(("Duplicated IPL %s! (CANCELED ACTION)"):format(iplName)) end
    end
  end
end
