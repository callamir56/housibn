


















local isCameraModeActive = false
local currentCameraIndex = nil
local activeScriptCam = nil
local currentCameraPropEntity = nil
local cameraFurnitureCache = {}


local function checkCameras(propertyId, resultCallback, environment)
  local propertyData = (Properties and propertyId and Properties[propertyId]) or nil


  if not (library and library.HasAnyPermission and library.HasAnyPermission(propertyId)) then
    if resultCallback then
      resultCallback(false)
    end
    return
  end

  if not propertyData or not propertyData.furniture then
    if resultCallback then
      resultCallback(false)
    end
    return
  end


  if not (cameraFurnitureCache and next(cameraFurnitureCache)) then
    cameraFurnitureCache = {}

    for _, furnitureItem in pairs(propertyData.furniture) do
      local isCameraModel = Config.Cameras[furnitureItem.model] ~= nil
      local hasPosition = furnitureItem.position ~= nil
      local isNotStored = (furnitureItem.stored == 0)

      if isCameraModel and hasPosition and isNotStored then
        if environment then
          if furnitureItem.position.environment == environment then
            table.insert(cameraFurnitureCache, furnitureItem)
          end
        else
          table.insert(cameraFurnitureCache, furnitureItem)
        end
      end
    end
  end


  if not next(cameraFurnitureCache) then
    if resultCallback then
      resultCallback(false)
    end
    return
  end


  if resultCallback then
    resultCallback(true)
  end


  DoScreenFadeOut(300)
  Wait(300)





  if not isCameraModeActive then
    if environment then

      if CurrentProperty then
        if environment == "outside" then

          TriggerServerEvent("vms_housing:sv:exitHouse", CurrentProperty, true)

          if ToggleWeather then
            ToggleWeather(false)
          end

          if CurrentShell then
            DeleteHousingShell(CurrentShell)
            CurrentShell = nil
          end

          if CurrentIPL then
            IPL.UnloadSettings(CurrentIPL)
            CurrentIPL = nil
          end
        end


      elseif environment == "inside" then

        TriggerServerEvent("vms_housing:sv:enterCameraModeDifferentEnvironment", propertyId, environment)

        if propertyData.type == "shell" then

          Property:RemoveFurniture()


          CurrentShell = SpawnHousingShell(propertyData.metadata.shell)


          if ToggleWeather then
            Citizen.CreateThread(function()
              while true do
                if not CurrentShell then
                  break
                end

                if CurrentShell then
                  ToggleWeather(true)
                end

                Citizen.Wait(30000)
              end
            end)
          end

        elseif propertyData.type == "ipl" then
          CurrentIPL = propertyData.metadata.ipl
          IPL.LoadSettings(CurrentIPL, propertyData.metadata.iplTheme, propertyData.metadata.iplSettings)
        end


        Wait(1500)


        if propertyData.metadata.lightState ~= nil then
          SetArtificialLightsState(not propertyData.metadata.lightState)
        end


        if propertyData and propertyData.furniture then
          Property:LoadFurniture("inside", propertyData.furniture, propertyId)
        end
      end
    end


    currentCameraIndex = 1
    isCameraModeActive = true
  end





  if isCameraModeActive then
    if currentCameraPropEntity then
      SetEntityVisible(currentCameraPropEntity, true)
    end

    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(activeScriptCam, false)
    activeScriptCam = false
  end


  local playerPed = PlayerPedId()
  local _playerCoords = GetEntityCoords(playerPed)


  local cameraItem = cameraFurnitureCache[currentCameraIndex]
  ClearFocus()





  if not (cameraItem and cameraItem.position) then
    DoScreenFadeOut(400)
    isCameraModeActive = false
    Wait(400)

    ClearFocus()
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()

    RenderScriptCams(false, false, 0, true, false)

    SetFocusEntity(playerPed)
    SetEntityCollision(playerPed, true, true)
    SetEntityVisible(playerPed, true)

    Wait(300)


    if environment then
      if CurrentProperty then
        if environment == "outside" then

          Property:EnterProperty(propertyData, propertyId, function(success)
            if success then
              Citizen.CreateThread(function()
                Citizen.Wait(3000)
                openManageMenu(propertyId)
              end)
            end
          end, true)
        else
          FreezeEntityPosition(playerPed, false)
          DoScreenFadeIn(400)
        end

      elseif environment == "inside" then

        TriggerServerEvent("vms_housing:sv:exitCameraMode", propertyId, environment)

        if ToggleWeather then
          ToggleWeather(false)
        end

        if CurrentShell then
          DeleteHousingShell(CurrentShell)
          CurrentShell = nil
        end

        if CurrentIPL then
          IPL.UnloadSettings(CurrentIPL)
          CurrentIPL = nil
        end

        openManageMenu(propertyId)
        Property:RemoveFurniture()

        FreezeEntityPosition(playerPed, false)
        DoScreenFadeIn(400)
      else
        FreezeEntityPosition(playerPed, false)
        DoScreenFadeIn(400)
      end
    else
      openManageMenu(propertyId)
      FreezeEntityPosition(playerPed, false)
      DoScreenFadeIn(400)
    end


    cameraFurnitureCache = {}


    SendNUIMessage({ action = "ControlsMenu", toggle = false })
    return
  end




  activeScriptCam = CreateCamWithParams(
    "DEFAULT_SCRIPTED_CAMERA",
    vector3(cameraItem.position.x, cameraItem.position.y, cameraItem.position.z),
    0, 0, 0,
    50.0
  )


  currentCameraPropEntity = GetClosestObjectOfType(
    cameraItem.position.x, cameraItem.position.y, cameraItem.position.z,
    0.5,
    GetHashKey(cameraItem.model),
    false, false, false
  )


  local timeoutAt = GetGameTimer() + 3000
  while timeoutAt > GetGameTimer() do
    if DoesEntityExist(currentCameraPropEntity) then
      break
    end

    Wait(1)

    currentCameraPropEntity = GetClosestObjectOfType(
      cameraItem.position.x, cameraItem.position.y, cameraItem.position.z,
      0.5,
      GetHashKey(cameraItem.model),
      false, false, false
    )
  end


  local propRot = GetEntityRotation(currentCameraPropEntity)
  local camPitch = propRot.x - 18.0
  local camYaw = (propRot.z + 180.0) % 360.0

  SetCamRot(activeScriptCam, camPitch, propRot.y, camYaw, 2)
  SetCamActive(activeScriptCam, true)


  SetTimecycleModifier("scanline_cam_cheap")
  DisableAllControlActions(0)

  FreezeEntityPosition(playerPed, true)
  SetEntityCollision(playerPed, false, true)
  SetEntityVisible(playerPed, false)


  SetEntityVisible(currentCameraPropEntity, false)

  SetTimecycleModifierStrength(2.0)
  SetFocusArea(cameraItem.position.x, cameraItem.position.y, cameraItem.position.z, 0.0, 0.0, 0.0)


  PointCamAtCoord(activeScriptCam, vector3(cameraItem.position.x, cameraItem.position.y, cameraItem.position.z))

  RenderScriptCams(true, false, 1, true, false)

  Wait(1000)
  DoScreenFadeIn(500)


  RequestAmbientAudioBank("Phone_Soundset_Franklin", 0, 0)
  RequestAmbientAudioBank("HintCamSounds", 0, 0)


  SendNUIMessage({
    action = "ControlsMenu",
    toggle = true,
    controlsLabel = "property:camera",
    controlsName = "Property:camera"
  })




  while IsCamActive(activeScriptCam) do
    Citizen.Wait(2)

    DisableAllControlActions(0)


    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(19)
    HideHudAndRadarThisFrame()


    SetEntityLocallyInvisible(currentCameraPropEntity)


    if IsDisabledControlPressed(0, 174) then
      local prevIndex = currentCameraIndex - 1
      if cameraFurnitureCache[prevIndex] then
        currentCameraIndex = prevIndex

        checkCameras(propertyId, nil, environment)
      else

        if currentCameraIndex ~= #cameraFurnitureCache then
          currentCameraIndex = #cameraFurnitureCache
          checkCameras(propertyId, nil, environment)
        end
      end
    end


    if IsDisabledControlPressed(0, 175) then
      local nextIndex = currentCameraIndex + 1
      if cameraFurnitureCache[nextIndex] then
        currentCameraIndex = nextIndex

        checkCameras(propertyId, nil, environment)
      else

        if currentCameraIndex ~= 1 then
          currentCameraIndex = 1
          checkCameras(propertyId, nil, environment)
        end
      end
    end


    SetTextFont(4)
    SetTextScale(0.8, 0.8)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0.1, 3, 27, 27, 255)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(
      propertyData.address .. " - Cam " .. currentCameraIndex .. "/" .. #cameraFurnitureCache
    )
    EndTextCommandDisplayText(0.01, 0.01)


    SetTextFont(4)
    SetTextScale(0.7, 0.7)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0.1, 3, 27, 27, 255)
    BeginTextCommandDisplayText("STRING")

    local year, month, day, hour, minute, second = GetPosixTime()
    AddTextComponentSubstringPlayerName(
      day .. "/" .. month .. "/" .. year .. " " .. hour .. ":" .. minute .. ":" .. second
    )
    EndTextCommandDisplayText(0.01, 0.055)


    if IsDisabledControlPressed(1, 194) then
      DoScreenFadeOut(400)
      isCameraModeActive = false
      Wait(400)

      ClearFocus()
      ClearTimecycleModifier()
      ClearExtraTimecycleModifier()

      RenderScriptCams(false, false, 0, true, false)
      SetCamActive(activeScriptCam, false)
      DestroyCam(activeScriptCam, false)

      SetFocusEntity(playerPed)
      SetEntityCollision(playerPed, true, true)
      SetEntityVisible(playerPed, true)

      Wait(300)


      if environment then
        if CurrentProperty then
          if environment == "outside" then

            Property:EnterProperty(propertyData, propertyId, function(success)
                if success then
                  Citizen.CreateThread(function()
                    Citizen.Wait(3000)
                    openManageMenu(propertyId)
                  end)
                end
              end, true)
          else
            FreezeEntityPosition(playerPed, false)
            DoScreenFadeIn(400)
          end

        elseif environment == "inside" then

          TriggerServerEvent("vms_housing:sv:exitCameraMode", propertyId, environment)

          if ToggleWeather then
            ToggleWeather(false)
          end

          if CurrentShell then
            DeleteHousingShell(CurrentShell)
            CurrentShell = nil
          end

          if CurrentIPL then
            IPL.UnloadSettings(CurrentIPL)
            CurrentIPL = nil
          end

          openManageMenu(propertyId)
          Property:RemoveFurniture()

          FreezeEntityPosition(playerPed, false)
          DoScreenFadeIn(400)
        else
          FreezeEntityPosition(playerPed, false)
          DoScreenFadeIn(400)
        end
      else
        openManageMenu(propertyId)
        FreezeEntityPosition(playerPed, false)
        DoScreenFadeIn(400)
      end


      SetEntityVisible(currentCameraPropEntity, true)


      cameraFurnitureCache = {}
      break
    end
  end


  SendNUIMessage({ action = "ControlsMenu", toggle = false })


  SetEntityVisible(currentCameraPropEntity, true)
end


_G.checkCameras = checkCameras
