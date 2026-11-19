
OBJECTS_PHOTOS_TOOL_WEBHOOK = nil
MARKETPLACE_PHOTOS_WEBHOOK  = nil


waitingForLoadAfterRestart = true


AlarmBlips    = {}
Blips         = {}
TargetPoints  = {}
Properties    = {}
Furniture     = {}


CurrentShell        = nil
CurrentIPL          = nil
CurrentProperty     = nil
CurrentPropertyData = nil
SelectedApartment   = nil
openedMenu          = nil


PlayerData     = {}
Identifier     = nil
CharacterName  = ""


if Config.Core == "ESX" then
  ESX = Config.CoreExport()
elseif Config.Core == "QB-Core" then
  QBCore = Config.CoreExport()
end











local function initializeHousing(isResourceRestart, playerData)
  Citizen.CreateThread(function()

    PlayerData = (type(playerData) == "table") and playerData or {}



    local function refreshPlayerData()
      local data = CL.GetPlayerData and CL.GetPlayerData() or nil
      if type(data) == "table" then
        PlayerData = data
      end
    end

    refreshPlayerData()

    Identifier = CL.GetPlayerIdentifier()
    if not Identifier or Identifier == "" then
      local deadline = GetGameTimer() + 10000
      while (not Identifier or Identifier == "") and GetGameTimer() < deadline do
        Citizen.Wait(200)
        refreshPlayerData()
        Identifier = CL.GetPlayerIdentifier()
      end
    end

    CharacterName = CL.GetPlayerCharacterName() or ""


    SpawnInLastProperty()


    TriggerEvent("vms_housing:init")


    Citizen.Wait(isResourceRestart and 5000 or 0)


    SendNUIMessage({
      action = "loaded2",
      characterName = CharacterName,
    })


    TriggerServerEvent("vms_housing:sv:fetchData")
  end)
end


RegisterNetEvent("vms_housing:cl:enterMapInterior", function(propertyId, x, y, z, heading)
  ApplyMapInteriorEntry(propertyId, x, y, z, heading)
end)


RegisterNetEvent("vms_housing:notification", CL.Notification)


AddEventHandler("onResourceStart", function(resourceName)
  if resourceName ~= GetCurrentResourceName() then
    return
  end


  if Config.Core == "ESX" then
    while not ESX do
      Citizen.Wait(200)
    end
  else
    while not QBCore do
      Citizen.Wait(200)
    end
  end


  if CL.IsPlayerLoaded() then
    initializeHousing(true, CL.GetPlayerData())
  end
end)


AddEventHandler("onResourceStop", function(resourceName)
  if resourceName ~= GetCurrentResourceName() then
    return
  end

  if CurrentProperty then

    TriggerServerEvent("vms_housing:sv:exitHouse", CurrentProperty)


    if ToggleWeather then
      ToggleWeather(false)
    end


    if CurrentShell then
      DeleteHousingShell(CurrentShell)
    end
  end


  Property:RemoveFurniture()


  if Config.Marketplace.__ped then
    DeleteEntity(Config.Marketplace.__ped)
  end
end)


RegisterNetEvent(Config.PlayerLoaded, function(coreNameOrNil)



  local initPlayerData = coreNameOrNil or Config.Core



  if initPlayerData ~= "ESX" or not coreNameOrNil then
    initPlayerData = CL.GetPlayerData()
  end

  initializeHousing(false, initPlayerData)
end)


RegisterNetEvent(Config.PlayerSetJob, function(jobData)
  PlayerData.job = jobData
end)





RegisterNetEvent("vms_housing:cl:loadProperties", function(propertiesJson)
  Properties = json.decode(propertiesJson)


  if CurrentProperty then
    CurrentPropertyData = Properties[tostring(CurrentProperty)] or CurrentPropertyData
  end


  for propertyId, propertyData in pairs(Properties) do
    if propertyData.type == "mlo"
      and propertyData.metadata
      and propertyData.metadata.doors
    then


      local forceLockValue = propertyData.owner
      forceLockValue = propertyData.renter
      forceLockValue = (not forceLockValue) and forceLockValue

      Property:RegisterDoors({
        propertyId = propertyId,
        forceLock  = forceLockValue,
        doors      = propertyData.metadata.doors,
      })
    end
  end
end)


RegisterNetEvent("vms_housing:cl:loadFurniture", function(furnitureJson)
  Furniture = json.decode(furnitureJson)

  SendNUIMessage({
    action = "Property",
    actionName = "ReloadAvailableFurniture",
    data = Furniture,
  })
end)


RegisterNetEvent("vms_housing:cl:fetchedData", function(objectsPhotosWebhook, marketplacePhotosWebhook)
  waitingForLoadAfterRestart = false

  OBJECTS_PHOTOS_TOOL_WEBHOOK = objectsPhotosWebhook
  MARKETPLACE_PHOTOS_WEBHOOK  = marketplacePhotosWebhook


  SendNUIMessage({
    action = "LoadWebhook",
    webhook = OBJECTS_PHOTOS_TOOL_WEBHOOK,
  })


  if Config.Debug then
    Citizen.CreateThread(function()
      local propertiesCount = 0
      for _ in pairs(Properties) do
        propertiesCount = propertiesCount + 1
      end

      library.Debug(("^4[Loaded]^7 Loaded %s Properties!"):format(propertiesCount))

      local furnitureCount = 0
      for _ in pairs(Furniture) do
        furnitureCount = furnitureCount + 1
      end

      library.Debug(("^4[Loaded]^7 Loaded %s Furniture!"):format(furnitureCount))
    end)
  end


  RefreshBlips()
end)






local function setupMarketplace()
  local marketplaceCfg = Config.Marketplace
  if not marketplaceCfg.Enabled then
    return
  end


  if marketplaceCfg.Ped and marketplaceCfg.Ped.Model and marketplaceCfg.Ped.Coords then
    marketplaceCfg.__ped = library.SpawnPed({
      model = marketplaceCfg.Ped.Model,
      coords = marketplaceCfg.Ped.Coords,
      animation = marketplaceCfg.Ped.Animation,
    })
  end


  if marketplaceCfg.Blip and marketplaceCfg.BlipCoords then
    marketplaceCfg.__blip = library.CreateBlip({
      coords = marketplaceCfg.BlipCoords,
      sprite = marketplaceCfg.Blip.sprite,
      display = marketplaceCfg.Blip.display,
      scale = marketplaceCfg.Blip.scale,
      color = marketplaceCfg.Blip.color,
      name = marketplaceCfg.Blip.name,
    })
  end


  CL.Target("zone", {
    coords = marketplaceCfg.TargetCoords.xyz,
    rotation = marketplaceCfg.TargetCoords.w,
    size = marketplaceCfg.TargetSize,
    options = {
      {
        name = "marketplace",
        icon = "fa-solid fa-building",
        label = TRANSLATE("target.marketplace"),
        action = function()
          openMarketplace()
        end,
      },
    },
  })
end


Citizen.CreateThread(function()
  Citizen.Wait(2000)


  if Config.Weather then
    library.Debug(("^2[Compatibility]^7 Found Compatible Weather: ^3%s^7"):format(Config.Weather))
  else
    library.Debug("^1[Compatibility]^7 No compatible weather found!")
  end

  if Config.Clothing then
    library.Debug(("^2[Compatibility]^7 Found Compatible Clothing: ^3%s^7"):format(Config.Clothing))
  else
    library.Debug("^1[Compatibility]^7 No compatible clothing found!")
  end

  if Config.Garages then
    library.Debug(("^2[Compatibility]^7 Found Compatible Garage: ^3%s^7"):format(Config.Garages))
  else
    library.Debug("^1[Compatibility]^7 No compatible garage found!")
  end

  if Config.Inventory then
    library.Debug(("^2[Compatibility]^7 Found Compatible Inventory: ^3%s^7"):format(Config.Inventory))
  else
    library.Debug("^1[Compatibility]^7 No compatible inventory found!")
  end


  setupMarketplace()
end)
