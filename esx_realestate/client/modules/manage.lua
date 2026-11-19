
















local ManageMenu = {}


local lastManageFetchPropertyId = nil
local manageFetchCacheExpiresAt = nil



function openManageMenu(propertyId, isDevice)

  if propertyId then
    MotelManageId = propertyId
  end


  local resolvedPropertyId = propertyId
  if not resolvedPropertyId then
    resolvedPropertyId = CurrentProperty
    if not resolvedPropertyId then
      resolvedPropertyId = GetCurrentPropertyId()
    end
  end

  if not resolvedPropertyId then
    return
  end


  local propertyData = nil
  if resolvedPropertyId and Properties[resolvedPropertyId] then
    propertyData = Properties[resolvedPropertyId]
  else
    propertyData = CurrentPropertyData
    if not propertyData then
      propertyData = GetCurrentPropertyData()
    end
  end


  if not library.HasAnyPermission(resolvedPropertyId) then
    return
  end


  local isInside = false
  local isOutside = false

  if propertyData.type == "shell" then
    if CurrentShell then
      isInside = true
    else
      isOutside = true
    end
  elseif propertyData.type == "ipl" then
    if CurrentIPL then
      isInside = true
    else
      isOutside = true
    end
  elseif propertyData.type == "mlo" then
    isInside = IsInsideMLO()
    isOutside = not isInside
  end


  local regionData = Config.Regions[propertyData.region]
  if not regionData then
    regionData = Config.NoRegion
  end


  local manageServerData = nil

  local cacheValid = false
  if manageFetchCacheExpiresAt then
    local now = GetGameTimer()
    if not (now > manageFetchCacheExpiresAt) and lastManageFetchPropertyId == resolvedPropertyId then
      cacheValid = true
    end
  end

  if not cacheValid then

    local p = promise.new()

    library.Callback("vms_housing:openManageMenu", function(serverData)

      manageFetchCacheExpiresAt = GetGameTimer() + 60000
      p:resolve(serverData)
    end, resolvedPropertyId)

    lastManageFetchPropertyId = resolvedPropertyId
    manageServerData = Citizen.Await(p)
    if not manageServerData or manageServerData.error or not Properties[resolvedPropertyId] then
      manageFetchCacheExpiresAt = nil
      return
    end


    Properties[resolvedPropertyId].bills = manageServerData.bills
    Properties[resolvedPropertyId].unpaidRentBills = manageServerData.unpaidRentBills
    Properties[resolvedPropertyId].unpaidBills = manageServerData.unpaidBills
  end


  local isOwner = false
  if propertyData.owner then
    isOwner = (propertyData.owner == Identifier)
  end

  local isRenter = false
  if propertyData.renter then
    isRenter = (propertyData.renter == Identifier)
  end


  local payload = {
    action = "Property",
    actionName = "OpenManage",
    data = {}
  }

  local myPerms = propertyData.permissions and propertyData.permissions[Identifier] or {}
  local decodedKeys = json.decode(propertyData.keys)


  payload.data.type = propertyData.type
  payload.data.isObject = (propertyData.object_id ~= nil)
  payload.data.isDevice = isDevice
  payload.data.isOwner = isOwner
  payload.data.isRenter = isRenter
  payload.data.renter = propertyData.renter
  payload.data.renterName = propertyData.renter_name
  payload.data.myPermissions = myPerms

  payload.data.bills = propertyData.bills
  payload.data.unpaidBills = propertyData.unpaidBills
  payload.data.unpaidRentBills = propertyData.unpaidRentBills
  payload.data.utilityAccess = Config.UtilityAccess
  payload.data.utilityBillsEnabled = Config.UseServiceBills

  payload.data.keys = decodedKeys
  payload.data.deliveries = Config.Deliveries

  payload.data.name = propertyData.name
  payload.data.description = propertyData.description
  payload.data.address = propertyData.address
  payload.data.region = propertyData.region

  payload.data.electricity = regionData and regionData.electricity or nil
  payload.data.internet = regionData and regionData.internet or nil
  payload.data.water = regionData and regionData.water or nil

  payload.data.isInside = isInside
  payload.data.lastEnter = propertyData.last_enter


  payload.data.garage = (propertyData.metadata and propertyData.metadata.garage ~= nil) or false
  if propertyData.metadata and propertyData.metadata.parking then
    payload.data.parking = #propertyData.metadata.parking
  else
    payload.data.parking = false
  end


  payload.data.sale = propertyData.sale
  payload.data.rental = propertyData.rental
  payload.data.keysLimit = propertyData.metadata and propertyData.metadata.keysLimit or nil


  payload.data.furnitureLimit = GetFurnitureLimit(propertyData.metadata and propertyData.metadata.upgrades)


  local autoSellPrice = nil
  autoSellPrice = propertyData.sale and propertyData.sale.defaultPrice
  if autoSellPrice then
    local defaultPrice = propertyData.sale.defaultPrice
    local _unusedMultiplier = (Config.AutomaticSell / 100)
    autoSellPrice = (defaultPrice >= 1 and defaultPrice)
  end
  payload.data.autoSellPrice = autoSellPrice


  if isOwner or isRenter then
    payload.data.permissions = propertyData.permissions
  end


  if library.HasPermissions(resolvedPropertyId, "furniture") then
    payload.data.furniture = propertyData.furniture
    payload.data.allowedInside = propertyData.metadata and propertyData.metadata.allowFurnitureInside
    payload.data.allowedOutside = propertyData.metadata and propertyData.metadata.allowFurnitureOutside


    payload.data.hasWardrobe = (propertyData.metadata and propertyData.metadata.wardrobe and propertyData.metadata.wardrobe.x ~= nil) or false
    payload.data.hasStorage = (propertyData.metadata and propertyData.metadata.storage and propertyData.metadata.storage.x ~= nil) or false
  end


  if library.HasPermissions(resolvedPropertyId, "upgradesManage") then
    payload.data.upgrades = Config.HousingUpgrades
    payload.data.ownUpgrades = {}

    for _, upgradeDef in pairs(Config.HousingUpgrades) do
      if propertyData.metadata and propertyData.metadata.upgrades then
        local upgradeKey = upgradeDef.metadata
        local ownedValue = propertyData.metadata.upgrades[upgradeKey]
        if ownedValue then
          payload.data.ownUpgrades[upgradeKey] = ownedValue
        end
      end
    end
  end


  if library.HasPermissions(resolvedPropertyId, "marketplaceManage") then
    payload.data.furnished = propertyData.metadata and propertyData.metadata.furnished
    payload.data.contact_number = propertyData.metadata and propertyData.metadata.contact_number
    payload.data.images = propertyData.metadata and propertyData.metadata.images
  end



  SendNUIMessage({ action = "Property", actionName = "ReloadAvailableFurniture", data = Furniture or {} })

  SetNuiFocus(true, true)
  SendNUIMessage(payload)
  openedMenu = "PropertyManage"
end


exports("OpenManageMenu", openManageMenu)


function closeManageMenu()
  SendNUIMessage({
    action = "Property",
    actionName = "CloseManage"
  })

  SetNuiFocus(false, false)
  openedMenu = nil


  MotelManageId = nil
end


if Config.HousingManagement and Config.HousingManagement.Command then
  RegisterCommand(Config.HousingManagement.Command, function()
    openManageMenu()
  end)

  if Config.HousingManagement.Key then
    RegisterKeyMapping(
      Config.HousingManagement.Command,
      Config.HousingManagement.Description or "",
      "keyboard",
      Config.HousingManagement.Key
    )
  end
end
