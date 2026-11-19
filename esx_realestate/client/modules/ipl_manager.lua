




















local IPL = {}

















function IPL.LoadSettings(iplKey, themeName, enabledConfig, onApplied)
  local iplEntry = AvailableIPLS[iplKey]
  if not iplEntry then
    return false
  end

  local iplSettings = iplEntry.settings



  local interior = exports.bob74_ipl[iplSettings.GetInteriorExport]()


  interior.Style.Clear()
  interior.Style.Set(interior.Style.Theme[themeName], true, false)


  if iplSettings.options then
    for categoryName, categoryOptions in pairs(iplSettings.options) do



      local disableList = {}
      local enableList = {}



      if interior.Swag and interior.Swag[categoryName] then

        for _, swagItem in pairs(interior.Swag[categoryName]) do
          disableList[categoryName] = disableList[categoryName] or {}
          table.insert(disableList[categoryName], swagItem)
        end
      else


        if interior[categoryName] then
          for optionKey, _ in pairs(categoryOptions) do
            local matched = false



            if enabledConfig and enabledConfig[categoryName] then
              for _, selectedKey in ipairs(enabledConfig[categoryName]) do
                if optionKey == selectedKey then
                  matched = true
                  table.insert(enableList, interior[categoryName][optionKey])
                  break
                end
              end
            end


            if not matched then
              disableList[categoryName] = disableList[categoryName] or {}
              table.insert(disableList[categoryName], interior[categoryName][optionKey])
            end
          end
        end
      end


      if enabledConfig and enabledConfig[categoryName] ~= nil then

        if interior.Swag then
          for _, selectedKey in ipairs(enabledConfig[categoryName]) do

            if iplSettings.options[categoryName][selectedKey] ~= nil then
              table.insert(enableList, interior.Swag[categoryName][selectedKey])


              local list = disableList[categoryName]
              if list then
                for i = #list, 1, -1 do
                  if list[i] == interior.Swag[categoryName][selectedKey] then
                    table.remove(list, i)
                  end
                end
              end
            end
          end

          interior.Swag.Enable(enableList, true)
        else

          if interior[categoryName] and interior[categoryName].Enable then
            interior[categoryName].Enable(enableList, true)
          end
        end
      end


      if interior.Swag then
        interior.Swag.Enable(disableList[categoryName], false)
      end
    end
  end






  if iplSettings.Chairs ~= nil then
    if enabledConfig and enabledConfig.Chairs then
      interior.Chairs.Set(interior.Chairs.on)
    else
      interior.Chairs.Set(interior.Chairs.off)
    end
  end


  if iplSettings.Booze ~= nil then
    if enabledConfig and enabledConfig.Booze then
      if interior.Booze.on ~= nil then
        interior.Booze.Set(interior.Booze.on)
      end
    else
      if interior.Booze.off ~= nil then
        interior.Booze.Set(interior.Booze.off)
      end
    end
  end


  if iplSettings.SafeLeft ~= nil then
    if enabledConfig and enabledConfig.SafeLeft then
      interior.Safe.Open("left", true)
    else
      interior.Safe.Close("left", false)
    end
  end

  if iplSettings.SafeRight ~= nil then
    if enabledConfig and enabledConfig.SafeRight then
      interior.Safe.Open("right", true)
    else
      interior.Safe.Close("right", false)
    end
  end


  local doors = AvailableIPLS[iplKey].doors
  local interiorId = GetInteriorAtCoords(doors.x, doors.y, doors.z)
  RefreshInterior(interiorId)


  if onApplied then
    onApplied()
  end


end




function IPL.UnloadSettings(iplKey)
  local iplEntry = AvailableIPLS[iplKey]
  if not iplEntry then
    return false
  end

  local interior = exports.bob74_ipl[iplEntry.settings.GetInteriorExport]()
  interior.LoadDefault()
end


_G.IPL = IPL
