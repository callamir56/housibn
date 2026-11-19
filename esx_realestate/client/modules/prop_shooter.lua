























local propsToRegister = {}
local CINEMA_SCREEN_MODEL = "prop_big_cin_screen"
local currentIndex = 1


local previewPropEntity = nil
local screenTopEntity = nil
local screenMidEntity = nil
local screenBottomEntity = nil
local previewCam = nil


local playerOriginalCoords = nil


local STAGING_POS = vector3(500.0, 500.0, 350.0)


local countdownActive = false
local countdownMs = 3000
local countdownPaused = false


local registeredFurnitureData = {}





local function getDeliverySizeFromDimensions(minDim, maxDim)
  local size = vector3(
    math.abs(maxDim.x - minDim.x),
    math.abs(maxDim.y - minDim.y),
    math.abs(maxDim.z - minDim.z)
  )

  local volume = size.x * size.y * size.z

  if volume <= 0.3 then
    return 1
  elseif volume <= 1.0 then
    return 2
  else
    return 3
  end
end




function drawText2D(text, x, y, scale, r, g, b)
  SetTextFont(4)
  SetTextProportional(1)
  SetTextScale(0.0, scale)
  SetTextColour(r, g, b, 255)

  SetTextDropshadow(0, 0, 0, 0, 205)
  SetTextEdge(1, 0, 0, 0, 150)
  SetTextDropshadow()
  SetTextOutline()
  SetTextCentre(1)

  BeginTextCommandDisplayText("STRING")
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayText(x, y)
end









function startCountdown()
  countdownActive = true
  countdownMs = 3000
  countdownPaused = false

  while countdownActive do
    Citizen.Wait(0)

    if not countdownPaused then
      countdownMs = countdownMs - 10

      drawText2D(tostring(countdownMs) .. "ms", 0.5, 0.5, 0.8, 200, 0, 0)
      drawText2D("Press SPACE to hold timer", 0.5, 0.54, 0.3, 210, 210, 210)
    else
      drawText2D(tostring(countdownMs) .. "ms", 0.5, 0.5, 0.8, 200, 200, 0)
      drawText2D("Press SPACE to resume timer", 0.5, 0.54, 0.3, 210, 210, 210)
    end


    drawText2D("Change FOV using SCROLL", 0.5, 0.70, 0.4, 240, 240, 240)
    drawText2D("Change HEIGHT using LMB/RMB", 0.5, 0.73, 0.4, 240, 240, 240)
    drawText2D("Change ROTATION using ARROWS", 0.5, 0.76, 0.4, 240, 240, 240)


    if IsControlJustPressed(0, 22) then
      countdownPaused = not countdownPaused
    end


    if IsControlPressed(0, 24) then
      local coords = GetEntityCoords(previewPropEntity)
      SetEntityCoords(previewPropEntity, coords.x, coords.y, coords.z + 0.01)
    end


    if IsControlPressed(0, 70) then
      local coords = GetEntityCoords(previewPropEntity)
      SetEntityCoords(previewPropEntity, coords.x, coords.y, coords.z - 0.01)
    end


    if IsControlPressed(0, 174) then
      local heading = (GetEntityHeading(previewPropEntity) + 1.0) % 360
      SetEntityHeading(previewPropEntity, heading)
    end


    if IsControlPressed(0, 175) then
      local heading = (GetEntityHeading(previewPropEntity) - 1.0) % 360
      if heading < 0 then
        heading = heading + 360
      end
      SetEntityHeading(previewPropEntity, heading)
    end


    if IsControlPressed(0, 180) then
      SetCamFov(previewCam, GetCamFov(previewCam) + 2.0)
    end


    if IsControlPressed(0, 181) then
      SetCamFov(previewCam, GetCamFov(previewCam) - 2.0)
    end

    if countdownMs <= 0 then
      countdownActive = false
    end
  end

  Citizen.Wait(1250)
end




function setupCamera(entity)

  if previewCam then
    DestroyCam(previewCam, false)
    SetCamActive(previewCam, false)
  end

  previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

  local coords = GetEntityCoords(entity)
  local minDim, maxDim = GetModelDimensions(GetEntityModel(entity))
  local size = (maxDim - minDim)

  local sizeX = size.x
  local sizeY = size.y
  local sizeZ = size.z

  local maxXY = math.max(sizeX, sizeY)
  local camDistance = math.max(2.5, maxXY * 1.4)


  SetCamCoord(previewCam, coords.x, coords.y - camDistance, coords.z + (sizeZ * 1.2))


  PointCamAtCoord(previewCam, coords.x, coords.y, coords.z + (sizeZ * 0.5))


  local computedFov = math.max(40.0, math.min(70.0, 65.0 - (maxXY * 3.0)))
  SetCamFov(previewCam, computedFov)

  SetCamActive(previewCam, true)
  RenderScriptCams(true, true, 500, true, true)
end





function takeScreenshot(fileName, onDone)
  exports["screenshot-basic"]:requestScreenshot(function(imageData)
    SendNUIMessage({
      action = "ProcessImage",
      fileName = fileName,
      image = imageData
    })


    onDone(true)
  end)
end




function spawnNextProp()

  if previewPropEntity then
    DeleteEntity(previewPropEntity)
  end

  local modelName = propsToRegister[currentIndex]


  previewPropEntity = library.SpawnProp(
    GetHashKey(modelName),
    vector3(STAGING_POS.x, STAGING_POS.y, STAGING_POS.z + 10.0),
    false
  )


  if DoesEntityExist(previewPropEntity) then
    FreezeEntityPosition(previewPropEntity, true)
    SetEntityHeading(previewPropEntity, 25.0)

    setupCamera(previewPropEntity)

    Citizen.Wait(500)
    startCountdown()


    takeScreenshot(modelName, function()
      if DoesEntityExist(previewPropEntity) then
        local minDim, maxDim = GetModelDimensions(modelName)
        registeredFurnitureData[modelName] = {
          deliverySize = getDeliverySizeFromDimensions(minDim, maxDim)
        }
      else
        if Config and Config.Debug then print('Entity "' .. tostring(modelName) .. '" does not exist') end
      end


      currentIndex = currentIndex + 1
      if currentIndex > #propsToRegister then
        currentIndex = 0
      end
    end)
  else

    if Config and Config.Debug then print('Entity "' .. tostring(modelName) .. '" does not exist') end

    currentIndex = currentIndex + 1
    if currentIndex > #propsToRegister then
      currentIndex = 0
    end
  end
end






function RegisterFurniture(modelList)
  if not OBJECTS_PHOTOS_TOOL_WEBHOOK then
    return library.Debug(
      "Nie możesz korzystać z tej opcji. Nie ma skonfigurowanego webhooka.",
      "warn"
    )
  end

  propsToRegister = modelList
  registeredFurnitureData = {}
  currentIndex = 1


  playerOriginalCoords = GetEntityCoords(PlayerPedId())
  Citizen.Wait(100)

  local ped = PlayerPedId()
  SetEntityCoords(
    ped,
    STAGING_POS.x, STAGING_POS.y, STAGING_POS.z + 15.0,
    false, false, false, true
  )
  FreezeEntityPosition(ped, true)


  screenTopEntity = library.SpawnProp(
    GetHashKey(CINEMA_SCREEN_MODEL),
    vector3(STAGING_POS.x, STAGING_POS.y, STAGING_POS.z + 15.0),
    false
  )
  FreezeEntityPosition(screenTopEntity, true)

  screenMidEntity = library.SpawnProp(
    GetHashKey(CINEMA_SCREEN_MODEL),
    vector3(STAGING_POS.x, STAGING_POS.y, STAGING_POS.z),
    false
  )
  FreezeEntityPosition(screenMidEntity, true)

  screenBottomEntity = library.SpawnProp(
    GetHashKey(CINEMA_SCREEN_MODEL),
    vector3(STAGING_POS.x, STAGING_POS.y, STAGING_POS.z - 15.0),
    false
  )
  FreezeEntityPosition(screenBottomEntity, true)


  CL.Hud.Disable()
  Wait(1000)


  while currentIndex ~= 0 do
    spawnNextProp()
    Citizen.Wait(1000)
  end

  Citizen.Wait(750)


  if previewPropEntity then DeleteEntity(previewPropEntity) end
  if screenTopEntity then DeleteEntity(screenTopEntity) end
  if screenMidEntity then DeleteEntity(screenMidEntity) end
  if screenBottomEntity then DeleteEntity(screenBottomEntity) end


  CL.Hud.Enable()
  FreezeEntityPosition(PlayerPedId(), false)

  if playerOriginalCoords and playerOriginalCoords.x then
    SetEntityCoords(PlayerPedId(), playerOriginalCoords.x, playerOriginalCoords.y, playerOriginalCoords.z)
  end


  DestroyCam(previewCam, false)
  SetCamActive(previewCam, false)
  RenderScriptCams(false, true, 500, true, true)


  TriggerServerEvent("vms_housing:sv:addFurniture", registeredFurnitureData)
end
