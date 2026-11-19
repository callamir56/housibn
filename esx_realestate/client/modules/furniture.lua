






local isCursorModeEnabled = false



furnitureMode = false


local function toggleCursorMode(forceState)
  if forceState ~= nil then
    isCursorModeEnabled = forceState
  else
    isCursorModeEnabled = not isCursorModeEnabled
  end

  if isCursorModeEnabled then
    SetCursorLocation(0.5, 0.5)
    EnterCursorMode()
  else
    LeaveCursorMode()
  end
end














local function manageFurniture(isEditingExisting, furnitureModel, furnitureId, directPurchase)
  local propertyId = CurrentProperty
  if not propertyId then
    propertyId = GetCurrentPropertyId()
  end

  local propertyData = CurrentPropertyData
  if not propertyData then
    propertyData = GetCurrentPropertyData()
  end

  local heightOffset = 0.0
  local purchasePending = false
  local zRotation = 0.0
  local isInside = false


  if propertyData.type == "mlo" then
    isInside = IsInsideMLO()
  else
    if CurrentProperty then
      isInside = true
    end
  end


  SendNUIMessage({
    action = "Property",
    actionName = "FurniturePlace",
  })


  SetNuiFocus(false, false)


  if Property.EditingFurnitureObj then
    DeleteEntity(Property.EditingFurnitureObj)
    Property.EditingFurnitureObj = nil
    Property.EditingFurnitureData = {}
  end


  local function getGameplayCameraDirection()
    local camRot = GetGameplayCamRot() * (math.pi / 180)
    return vector3(
      -math.sin(camRot.z),
      math.cos(camRot.z),
      math.sin(camRot.x)
    )
  end


  if isEditingExisting then
    for _, furniture in pairs(Property.LoadedFurnitures) do
      if furniture.furnitureId == furnitureId then
        Property.EditingFurnitureObj = furniture.entity
      end
    end


  elseif furnitureModel then
    Property.EditingFurnitureObj = library.SpawnProp(
      furnitureModel,
      GetEntityCoords(PlayerPedId()),
      false,
      nil,
      true
    )


    local timeoutAt = GetGameTimer() + 5000
    local timedOut = false

    while true do
      if DoesEntityExist(Property.EditingFurnitureObj) then
        break
      end

      if GetGameTimer() > timeoutAt then
        timedOut = true
        break
      end

      Citizen.Wait(5)
    end

    if timedOut then
      Property.EditingFurniture = false
      Property.EditingFurnitureObj = nil
      CL.Notification("Could not load this furniture model.", 5000, "error")
      return
    end
  end

  if not Property.EditingFurnitureObj or not DoesEntityExist(Property.EditingFurnitureObj) then
    Property.EditingFurniture = false
    CL.Notification("Could not find this furniture item.", 5000, "error")
    return
  end


  PlaceObjectOnGroundProperly(Property.EditingFurnitureObj)

  SetEntityAsMissionEntity(Property.EditingFurnitureObj, true, true)
  SetEntityCollision(Property.EditingFurnitureObj, false, false)

  SetEntityNoCollisionEntity(PlayerPedId(), Property.EditingFurnitureObj, false)
  SetEntityNoCollisionEntity(Property.EditingFurnitureObj, PlayerPedId(), false)

  FreezeEntityPosition(Property.EditingFurnitureObj, true)
  SetEntityDynamic(Property.EditingFurnitureObj, false)

  SetEntityProofs(
    Property.EditingFurnitureObj,
    true, true, true, true, true, true, true, true
  )
  SetEntityCanBeDamaged(Property.EditingFurnitureObj, false)


  local lastModeSwitchAt = 0
  furnitureMode = "gizmo"


  HousingCreator:CreateCamera(true)
  toggleCursorMode()


  SendNUIMessage({
    action = "ControlsMenu",
    toggle = true,
    controlsLabel = (furnitureMode == "gizmo") and "furniture:gizmo" or "furniture:walkmode",
    controlsName  = (furnitureMode == "gizmo") and "Furniture:gizmo"  or "Furniture:walkmode",
  })


  while true do
    if not Property.EditingFurnitureObj then
      break
    end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)

    HudForceWeaponWheel(false)
    HideHudComponentThisFrame(19)
    HideHudComponentThisFrame(20)

    local objCoords = GetEntityCoords(Property.EditingFurnitureObj)
    local objHeading = GetEntityHeading(Property.EditingFurnitureObj)
    local objRotation = GetEntityRotation(Property.EditingFurnitureObj, 2)


    SetEntityDrawOutline(Property.EditingFurnitureObj, true)
    SetEntityDrawOutlineColor(159, 15, 255, 200)
    SetEntityDrawOutlineShader(1)

    DisabledControls()
    Wait(0)

    if furnitureMode == "gizmo" then

      local entityMatrix = makeEntityMatrix(Property.EditingFurnitureObj)


      local rr1, rr2, rr3, rr4, rr5, rr6, rr7, rr8 = Citizen.ReturnResultAnyway()
      local didMove = Citizen.InvokeNative(
        3945716898,
        entityMatrix:Buffer(entityMatrix),
        "Editor1",
        rr1, rr2, rr3, rr4, rr5, rr6, rr7, rr8
      )

      if didMove then
        applyEntityMatrix(Property.EditingFurnitureObj, entityMatrix)
      end


      EnableControlAction(0, Config.FurnitureControls.ENABLE_CURSOR.controlIndex, true)
      if IsControlJustPressed(0, Config.FurnitureControls.ENABLE_CURSOR.controlIndex) then
        toggleCursorMode()
      end

      rotateCamInputs()
      moveCamInputs(true)

    else

      local hit, hitCoords = RayCastGamePlayCamera(nil, 150.0)
      if hit then
        DrawLine(
          pedCoords.x, pedCoords.y, pedCoords.z,
          hitCoords.x, hitCoords.y, hitCoords.z,
          159, 15, 255, 250
        )

        if Property.EditingFurnitureObj then
          SetEntityCoords(
            Property.EditingFurnitureObj,
            hitCoords.x, hitCoords.y, hitCoords.z + heightOffset
          )
        end
      end


      if IsControlPressed(0, Config.FurnitureControls.UP.controlIndex) then
        if IsControlReleased(0, Config.FurnitureControls.SPEED_DOWN.controlIndex) then
          heightOffset = heightOffset + Config.FurnitureSettings.HeightSpeed
        else
          heightOffset = heightOffset + Config.FurnitureSettings.HeightSpeedSlow
        end
      end


      if IsControlPressed(0, Config.FurnitureControls.DOWN.controlIndex) then
        if IsControlReleased(0, Config.FurnitureControls.SPEED_DOWN.controlIndex) then
          heightOffset = heightOffset - Config.FurnitureSettings.HeightSpeed
        else
          heightOffset = heightOffset - Config.FurnitureSettings.HeightSpeedSlow
        end
      end


      if IsControlPressed(0, Config.FurnitureControls.ROTATE_LEFT.controlIndex) then
        if IsControlReleased(0, Config.FurnitureControls.SPEED_DOWN.controlIndex) then
          zRotation = zRotation + Config.FurnitureSettings.RotateSpeed
        else
          zRotation = zRotation + Config.FurnitureSettings.RotateSpeedSlow
        end

        SetEntityRotation(Property.EditingFurnitureObj, 0, 0, zRotation, 1, true)
      end

      if IsControlPressed(0, Config.FurnitureControls.ROTATE_RIGHT.controlIndex) then
        if IsControlReleased(0, Config.FurnitureControls.SPEED_DOWN.controlIndex) then
          zRotation = zRotation - Config.FurnitureSettings.RotateSpeed
        else
          zRotation = zRotation - Config.FurnitureSettings.RotateSpeedSlow
        end

        SetEntityRotation(Property.EditingFurnitureObj, 0, 0, zRotation, 1, true)
      end
    end


    EnableControlAction(0, Config.FurnitureControls.CHANGE_MODE.controlIndex, true)
    if IsControlJustPressed(0, Config.FurnitureControls.CHANGE_MODE.controlIndex) then
      local now = GetGameTimer()
      if now >= (lastModeSwitchAt + 3000) then
        lastModeSwitchAt = now

        if furnitureMode == "gizmo" then
          furnitureMode = "normal"

          if isCursorModeEnabled then
            toggleCursorMode(false)
          end

          HousingCreator:DeleteCamera()
          FreezeEntityPosition(PlayerPedId(), false)
        else
          furnitureMode = "gizmo"
          toggleCursorMode(true)
          HousingCreator:CreateCamera(true)
        end


        SendNUIMessage({
          action = "ControlsMenu",
          toggle = true,
          controlsLabel = (furnitureMode == "gizmo") and "furniture:gizmo" or "furniture:walkmode",
          controlsName  = (furnitureMode == "gizmo") and "Furniture:gizmo"  or "Furniture:walkmode",
        })
      else
        CL.Notification(
          TRANSLATE("notify.furniture:mode_cooldown"),
          4000,
          "error"
        )
      end
    end


    EnableControlAction(0, Config.FurnitureControls.SNAP_TO_GROUND.controlIndex, true)
    if IsControlJustPressed(0, Config.FurnitureControls.SNAP_TO_GROUND.controlIndex) then
      PlaceObjectOnGroundProperly_2(Property.EditingFurnitureObj)
    end


    if not DoesEntityExist(Property.EditingFurnitureObj) then
      Property.EditingFurniture = false
      DeleteObject(Property.EditingFurnitureObj)
      Property.EditingFurnitureObj = nil
    end


    if not purchasePending and IsControlJustPressed(0, Config.FurnitureControls.CLOSE.controlIndex) then
      Property.EditingFurniture = false
      DeleteObject(Property.EditingFurnitureObj)
      Property.EditingFurnitureObj = nil


      Property:RemoveFurniture(nil, function()

        Property:LoadFurniture(
          (CurrentProperty and "inside" or "outside"),
          propertyData.furniture,
          CurrentProperty
        )


        if propertyData.type == "mlo" then
          Property:LoadFurniture(
            (CurrentProperty and "outside" or "inside"),
            propertyData.furniture,
            CurrentProperty
          )
        end
      end)
    end


    EnableControlAction(0, Config.FurnitureControls.ACCEPT.controlIndex, true)
    if Property.EditingFurnitureObj and not purchasePending and IsControlJustPressed(0, Config.FurnitureControls.ACCEPT.controlIndex) then
      local placedCoords = GetEntityCoords(Property.EditingFurnitureObj)


      local isWithinOutsideZone = nil
      if propertyData.metadata.zone then
        isWithinOutsideZone = isPointInPolygon(placedCoords, propertyData.metadata.zone.points)
      end

      if isInside or (not isInside and isWithinOutsideZone) then
        local isPlacementAllowed = true


        if propertyData.type == "mlo" then
          local isInInterior = isPointInPolygon(
            placedCoords,
            propertyData.metadata.interiorZone.points
          )

          local isFurnitureIndoor  = (Furniture[furnitureModel].isIndoor == 1)
          local isFurnitureOutdoor = (Furniture[furnitureModel].isOutdoor == 1)

          local allowInside  = (propertyData.metadata and propertyData.metadata.allowFurnitureInside)  ~= false
          local allowOutside = (propertyData.metadata and propertyData.metadata.allowFurnitureOutside) ~= false

          if isInInterior then
            if not isFurnitureIndoor then
              isPlacementAllowed = false
              CL.Notification(TRANSLATE("notify.furniture:cannot_place_inside"), 4000, "error")
            elseif not allowInside then
              isPlacementAllowed = false
              CL.Notification(TRANSLATE("notify.furniture:inside_disabled"), 4000, "error")
            end
          else
            if not isFurnitureOutdoor then
              isPlacementAllowed = false
              CL.Notification(TRANSLATE("notify.furniture:cannot_place_outside"), 4000, "error")
            elseif not allowOutside then
              isPlacementAllowed = false
              CL.Notification(TRANSLATE("notify.furniture:outside_disabled"), 4000, "error")
            end


            if propertyData.object_id then
              isPlacementAllowed = false
              CL.Notification(TRANSLATE("notify.furniture:no_outdoor_area"), 4000, "error")
            end
          end
        end

        if isPlacementAllowed then

          Property.EditingFurnitureData = {
            id = furnitureId,
            model = furnitureModel,
            coords = placedCoords,
            rotation = GetEntityRotation(Property.EditingFurnitureObj),
            isInside = isInside,
            isExisting = isEditingExisting,
          }

          if directPurchase and not isEditingExisting then
            if not purchasePending then
              purchasePending = true
              library.Callback("vms_housing:purchasePlacedFurniture", function(success)
                purchasePending = false
                if success and Property.EditingFurnitureObj then
                  DeleteObject(Property.EditingFurnitureObj)
                  Property.EditingFurnitureObj = nil
                  Property.EditingFurniture = false
                elseif not success then
                  CL.Notification("Purchase was not completed; check your cash and furniture access.", 5000, "error")
                end
              end, propertyId, Property.EditingFurnitureData)
            end
          elseif Config.RequirePurchaseFurniture or isEditingExisting then

            TriggerServerEvent("vms_housing:sv:placeFurniture", propertyId, Property.EditingFurnitureData)

            Property.EditingFurniture = false
            DeleteObject(Property.EditingFurnitureObj)
            Property.EditingFurnitureObj = nil
            break
          else

            SendNUIMessage({
              action = "Property",
              actionName = "OpenFurniturePurchase",
              data = {
                label = Furniture[furnitureModel].label,
                price = Furniture[furnitureModel].price,
              }
            })

            openedMenu = "PropertyFurniturePurchase"
            SetNuiFocus(true, true)
          end
        end
      else
        CL.Notification(TRANSLATE("notify.furniture:outside_zone"), 4000, "error")
      end
    end
  end


  if isCursorModeEnabled then
    toggleCursorMode(false)
  end

  HousingCreator:DeleteCamera()
  FreezeEntityPosition(PlayerPedId(), false)


  SendNUIMessage({ action = "ControlsMenu", toggle = false })

  Property.EditingFurniture = false
  Property.EditingFurnitureData = {}


  openFurnitureMenu()
end


  _G.manageFurniture = manageFurniture
  _ENV.manageFurniture = manageFurniture









local function editFurniture()

  Citizen.CreateThread(function()
    local highlighted = {}
    local lastEntity = nil

    while true do
      if not Property.EditingFurniture then
        break
      end

      local ped = PlayerPedId()
      local pedCoords = GetEntityCoords(ped)

      HudForceWeaponWheel(false)
      HideHudComponentThisFrame(19)
      HideHudComponentThisFrame(20)
      DisabledControls()

      local hit, hitCoords, hitEntity = RayCastGamePlayCamera(nil, 80.0)

      if hit then
        DrawLine(
          pedCoords.x, pedCoords.y, pedCoords.z,
          hitCoords.x, hitCoords.y, hitCoords.z,
          159, 15, 255, 250
        )

        if hitEntity then
          if lastEntity ~= hitEntity then

            if lastEntity and highlighted[lastEntity] then
              SetEntityDrawOutline(lastEntity, false)
              highlighted[lastEntity] = nil
            end


            if not highlighted[hitEntity] then
              for _, furniture in pairs(Property.LoadedFurnitures) do
                if furniture.entity == hitEntity then
                  lastEntity = hitEntity
                  highlighted[hitEntity] = furniture

                  SetEntityDrawOutline(hitEntity, true)
                  SetEntityDrawOutlineColor(159, 15, 255, 200)
                  SetEntityDrawOutlineShader(0)
                end
              end
            end
          end


          if IsControlJustPressed(0, Config.FurnitureControls.ACCEPT.controlIndex) then

            for entity in pairs(highlighted) do
              SetEntityDrawOutline(entity, false)
            end

            if highlighted[hitEntity] then
              manageFurniture(true, highlighted[hitEntity].model, highlighted[hitEntity].furnitureId)
            end

            Property.EditingFurniture = false
            break
          end
        end
      else

        if next(highlighted) then
          for entity in pairs(highlighted) do
            SetEntityDrawOutline(entity, false)
          end
          highlighted = {}
        end
      end


      if IsControlJustPressed(0, Config.FurnitureControls.CLOSE.controlIndex) then
        if next(highlighted) then
          for entity in pairs(highlighted) do
            SetEntityDrawOutline(entity, false)
          end
          highlighted = {}
        end

        Property.EditingFurniture = false
        break
      end

      Citizen.Wait(1)
    end
  end)
end

_G.editFurniture = editFurniture
_ENV.editFurniture = editFurniture








local function editTheme(themeIndex)
  Property.EditingTheme = themeIndex

  local propertyId = CurrentProperty
  if not propertyId then
    propertyId = GetCurrentPropertyId()
  end

  local propertyData = CurrentPropertyData
  if not propertyData then
    propertyData = GetCurrentPropertyData()
  end


  if CurrentIPL then
    local iplConfig = AvailableIPLS[propertyData.metadata.ipl]
    local themeConfig = iplConfig.settings.Themes[Property.EditingTheme]

    if themeConfig then

      local function refreshPlayerCoords()
        local coords = GetEntityCoords(PlayerPedId())
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
      end


      IPL.LoadSettings(CurrentIPL, Property.EditingTheme, propertyData.metadata.iplSettings, refreshPlayerCoords)

      while true do
        if not Property.EditingTheme then
          break
        end


        if IsControlJustPressed(0, Config.FurnitureControls.CLOSE.controlIndex) then
          IPL.LoadSettings(CurrentIPL, propertyData.metadata.iplTheme, propertyData.metadata.iplSettings, refreshPlayerCoords)
          Property.EditingTheme = nil
        end


        if IsControlJustPressed(0, Config.FurnitureControls.ACCEPT.controlIndex) then
          SendNUIMessage({
            action = "Property",
            actionName = "OpenFurniturePurchase",
            data = {
              label = themeConfig.label,
              price = themeConfig.price,
            }
          })
          SetNuiFocus(true, true)
          openedMenu = "PropertyFurniturePurchase"
        end

        Citizen.Wait(1)
      end
    end
  end

  Property.EditingTheme = nil
end

_G.editTheme = editTheme
_ENV.editTheme = editTheme









local function openFurnitureMenu()
  local propertyId = CurrentProperty
  if not propertyId then
    propertyId = GetCurrentPropertyId()
  end

  local propertyData = CurrentPropertyData
  if not propertyData then
    propertyData = GetCurrentPropertyData()
  end

  if waitingForLoadAfterRestart then
    return
  end

  if not propertyData then
    return
  end


  if Property.EditingFurniture or Property.EditingTheme then
    return
  end


  if not library.HasPermissions(propertyId, "furniture") then
    return
  end


  local isInside = false
  if propertyData.type == "shell" then
    if CurrentShell then isInside = true end
  elseif propertyData.type == "ipl" then
    if CurrentIPL then isInside = true end
  elseif propertyData.type == "mlo" then
    isInside = IsInsideMLO()
  end

  local isOutside = not isInside


  SendNUIMessage({ action = "Property", actionName = "ReloadAvailableFurniture", data = Furniture or {} })

  SendNUIMessage({
    action = "Property",
    actionName = "OpenFurniture",
    data = {
      propertyFurniture = propertyData.furniture,
      ipl = (isInside and CurrentIPL) or propertyData.furniture,
      allowChangeThemePurchased = propertyData.metadata.allowChangeThemePurchased,
      isInside = isInside,
      isOutside = isOutside,
      allowedInside = propertyData.metadata.allowFurnitureInside,
      allowedOutside = propertyData.metadata.allowFurnitureOutside,
    }
  })

  SetNuiFocus(true, true)
  openedMenu = "PropertyFurniture"
end

_G.openFurnitureMenu = openFurnitureMenu
_ENV.openFurnitureMenu = openFurnitureMenu


exports("OpenFurnitureMenu", openFurnitureMenu)


local function closeFurnitureMenu()
  SendNUIMessage({
    action = "Property",
    actionName = "CloseFurniture",
  })
  SetNuiFocus(false, false)
  openedMenu = nil
end

_G.closeFurnitureMenu = closeFurnitureMenu
_ENV.closeFurnitureMenu = closeFurnitureMenu


if Config.HousingFurniture.Command then
  RegisterCommand(Config.HousingFurniture.Command, function()
    openFurnitureMenu()
  end)

  if Config.HousingFurniture.Key then
    RegisterKeyMapping(
      Config.HousingFurniture.Command,
      Config.HousingFurniture.Description or "",
      "keyboard",
      Config.HousingFurniture.Key
    )
  end
end
