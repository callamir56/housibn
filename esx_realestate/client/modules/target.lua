








TargetHandler = TargetHandler or {}






local function blockIfInEditMode()
  if Property.EditingFurniture or Property.EditingTheme then
    CL.Notification(
      TRANSLATE("notify.furniture:you_are_in_furniture_mode"),
      5000,
      "info"
    )
    return true
  end
  return false
end





function TargetHandler.ViewOffer(propertyId)
  return {
    name = "property-offer",
    icon = "fa-solid fa-scroll",
    label = TRANSLATE("target.view_house"),


    action = function(_targetContext)
      Property:ViewOffer(propertyId)
    end,
  }
end








function TargetHandler.Enter(onEnter, canInteract)
  return {
    name = "property-enter",
    icon = "fa-solid fa-door-open",
    label = TRANSLATE("target.enter"),
    action = onEnter,
    canInteract = canInteract,
  }
end





function TargetHandler.Furniture(canInteract)
  return {
    name = "property-furniture",
    icon = "fa-solid fa-chair",
    label = TRANSLATE("target.furniture"),

    action = function()
      if blockIfInEditMode() then return end
      openFurnitureMenu()
    end,

    canInteract = canInteract,
  }
end





function TargetHandler.Doorbell(propertyId)
  return {
    name = "property-doorbell",
    icon = "fa-solid fa-bell",
    label = TRANSLATE("target.doorbell"),

    action = function()

      TriggerServerEvent("vms_housing:sv:ringDoorbell", propertyId)
    end,
  }
end
















function TargetHandler.Lockpick(propertyId, antiBurglaryDoors, hasAntiBurglaryUpgrade, onFinished, canInteract)
  local option = {
    name = "property-lockpick",
    icon = "fa-solid fa-unlock-keyhole",
    label = TRANSLATE("target.lockpick"),
  }

  local baseCanInteract = canInteract
  option.canInteract = function(...)
    if type(baseCanInteract) == "function" then
      if not baseCanInteract(...) then
        return false
      end
    end

    if Config.Lockpick and Config.Lockpick.Item and Config.Lockpick.Item.Required then
      local itemName = Config.Lockpick.Item.Name
      local itemCount = Config.Lockpick.Item.Count or 1
      return itemName and itemName ~= "" and library.HasItem(itemName, itemCount)
    end

    return true
  end

  option.action = function()

    if DispatchAlertClient and Config.Alarm and Config.Alarm.AlertPoliceOnLockpickStart then

      if not Config.Alarm.AlertPoliceOnlyWithUpgrade or hasAntiBurglaryUpgrade then
        DispatchAlertClient(Properties[tostring(propertyId)], "start")
      end
    end


    TriggerServerEvent("vms_housing:sv:startedLockpickDoors", propertyId)


    CL.Minigame("lockpick", function(success)
      if success then

        if DispatchAlertClient and Config.Alarm and Config.Alarm.AlertPoliceOnLockpickSuccess then
          if Config.Alarm.AlertPoliceOnlyWithUpgrade then
            if hasAntiBurglaryUpgrade then
              DispatchAlertClient(Properties[tostring(propertyId)], "success")
            end
          end
        end
      else

        if DispatchAlertClient and Config.Alarm and Config.Alarm.AlertPoliceOnLockpickFail then
          if not Config.Alarm.AlertPoliceOnlyWithUpgrade or hasAntiBurglaryUpgrade then
            DispatchAlertClient(Properties[tostring(propertyId)], "failed")
          end
        end
      end


      onFinished(success)
    end, {
      antiBurglaryDoors = antiBurglaryDoors,
    })
  end


  if Config.Lockpick and Config.Lockpick.Item and Config.Lockpick.Item.Required then
    if Config.Lockpick.Item.Name then
      option.requiredItem = Config.Lockpick.Item.Name
    end
  end

  return option
end






function TargetHandler.Lockdown(action, canInteract)
  if not (Config.PropertyLockdown and Config.PropertyLockdown.Enable) then
    return nil
  end

  local option = {
    name = "property-lockdown",
    icon = "fa-solid fa-road-barrier",
    label = TRANSLATE("target.lockdown"),
    action = action,
    canInteract = canInteract,
  }


  if Config.PropertyLockdown.Jobs and next(Config.PropertyLockdown.Jobs) then
    option.jobs = Config.PropertyLockdown.Jobs
  end


  if Config.PropertyLockdown.Item and Config.PropertyLockdown.Item.Required then
    option.requiredItem = Config.PropertyLockdown.Item.Name
  end

  return option
end






function TargetHandler.RemoveSeal(action, canInteract)
  if not (Config.PropertyLockdown and Config.PropertyLockdown.Enable) then
    return nil
  end

  local option = {
    name = "property-removeseal",
    icon = "fa-solid fa-lock-open",
    label = TRANSLATE("target.removeseal"),
    action = action,
    canInteract = canInteract,
  }

  if Config.PropertyLockdown.Jobs and next(Config.PropertyLockdown.Jobs) then
    option.jobs = Config.PropertyLockdown.Jobs
  end

  return option
end


















function TargetHandler.Raid(propertyId, onFinished, canInteract)
  if not (Config.PropertyRaids and Config.PropertyRaids.Enable) then
    return nil
  end

  local option = {
    name = "property-raid",
    icon = "fa-solid fa-person-walking-arrow-right",
    label = TRANSLATE("target.raid"),
    canInteract = canInteract,
  }

  option.action = function()


    local raidPropertyId = propertyId or GetCurrentPropertyId()
    local isAllowed = library.CallbackAwait("vms_housing:isAllowedToRaid", raidPropertyId)
    if not isAllowed then
      return
    end

    local ped = PlayerPedId()



    local propertyData
    if propertyId and Properties[propertyId] then
      propertyData = Properties[propertyId]
    else
      propertyData = GetCurrentPropertyData()
    end


    library.PlayAnimation(
      ped,
      "missheistfbi3b_ig7",
      "lift_fibagent_loop",
      8.0,
      8.0,
      -1,
      1
    )


    CL.Minigame("police_raid", function(success)
      library.StopAnimation(ped)
      onFinished(success)
    end, {
      antiBurglaryDoors = propertyData.metadata
        and propertyData.metadata.upgrades
        and propertyData.metadata.upgrades.antiBurglaryDoors,
    })
  end


  if Config.PropertyRaids.Jobs and next(Config.PropertyRaids.Jobs) then
    option.jobs = Config.PropertyRaids.Jobs
  end


  if Config.PropertyRaids.Item and Config.PropertyRaids.Item.Required then
    option.requiredItem = Config.PropertyRaids.Item.Name
  end

  return option
end






function TargetHandler.RaidLock(action, canInteract)
  if not (Config.PropertyRaids and Config.PropertyRaids.Enable) then
    return nil
  end

  local option = {
    name = "property-complete_raid",
    icon = "fa-solid fa-door-closed",
    label = TRANSLATE("target.complete_raid"),
    action = action,
    canInteract = canInteract,
  }

  if Config.PropertyRaids.Jobs and next(Config.PropertyRaids.Jobs) then
    option.jobs = Config.PropertyRaids.Jobs
  end

  return option
end













function TargetHandler.Storage(permissionKey, x, y, z, slots, weight)
  local option = {
    name = "property-storage",
    icon = "fa-solid fa-boxes-stacked",
    label = TRANSLATE("target.storage"),
  }

  option.action = function()
    if blockIfInEditMode() then return end

    OpenStorage({
      id = "house_storage-" .. permissionKey,
      slots = slots,
      weight = weight,
    })
  end


  if Config.StaticInteractionAccess == 2 then
    option.canInteract = function()
      return library.HasAnyPermission(permissionKey)
    end
  elseif Config.StaticInteractionAccess == 3 then
    option.canInteract = function()
      return library.HasPermissions(permissionKey, "furniture")
    end
  end


  local zoneId = CL.Target("zone", {
    coords = vector3(x, y, z),
    size = vec(1.5, 1.5, 2.0),
    rotation = 0.0,
    options = { option },
  })

  return {
    type = "storage",
    id = zoneId,
  }
end










function TargetHandler.Wardrobe(permissionKey, x, y, z)
  local option = {
    name = "property-wardrobe",
    icon = "fa-solid fa-shirt",
    label = TRANSLATE("target.wardrobe"),
  }

  option.action = function()
    if blockIfInEditMode() then return end
    OpenWardrobe()
  end

  if Config.StaticInteractionAccess == 2 then
    option.canInteract = function()
      return library.HasAnyPermission(permissionKey)
    end
  elseif Config.StaticInteractionAccess == 3 then
    option.canInteract = function()
      return library.HasPermissions(permissionKey, "furniture")
    end
  end

  local zoneId = CL.Target("zone", {
    coords = vector3(x, y, z),
    size = vec(1.5, 1.5, 2.0),
    rotation = 0.0,
    options = { option },
  })

  return {
    type = "wardrobe",
    id = zoneId,
  }
end





function TargetHandler.Manage(propertyId, canInteract)
  return {
    name = "property-manage",
    icon = "fa-solid fa-gear",
    label = TRANSLATE("target.manage"),

    action = function()
      if blockIfInEditMode() then return end
      openManageMenu(propertyId)
    end,

    canInteract = canInteract,
  }
end





function TargetHandler.ToggleLock(propertyId, canInteract)
  return {
    name = "property-lock",
    icon = "fa-solid fa-key",
    label = TRANSLATE("target.toggle_lock"),

    action = function()
      Property:ToggleLock(propertyId)
    end,

    canInteract = canInteract,
  }
end
