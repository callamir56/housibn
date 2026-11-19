




















isOfferByMarketplace = false
marketplaceOfferId = nil


local function getFirstMarketplaceImage(propertyData)
  if not propertyData.metadata or not propertyData.metadata.images then
    return nil
  end

  for i = 1, 5 do
    local key = tostring(i)
    local img = propertyData.metadata.images[key]
    if img then
      return img
    end
  end

  return nil
end


local function isPropertyListedForMarketplace(propertyData)
  local saleActive = propertyData.sale and propertyData.sale.active == true
  local rentalActive = propertyData.rental and propertyData.rental.active == true

  if not (saleActive or rentalActive) then
    return false
  end



  if not propertyData.owner and Config.Marketplace.ShowSecondaryMarketOnly then
    return false
  end

  return true
end



local function buildDisplayAddress(propertyData)
  local display = propertyData.address
  if Config.Regions[propertyData.region] then
    display = display .. ", " .. propertyData.region
  end
  return display
end




local function buildMarketplaceEntry(propertyKey, propertyData)
  local image = getFirstMarketplaceImage(propertyData)
  local displayAddress = buildDisplayAddress(propertyData)

  local hasGarage = (propertyData.metadata and propertyData.metadata.garage ~= nil) or false
  local parking = propertyData.metadata and propertyData.metadata.parking or nil

  local area = nil
  if propertyData.metadata and propertyData.metadata.zone and propertyData.metadata.zone.area then
    area = propertyData.metadata.zone.area
  end

  local entry = {
    name = displayAddress,
    parking = parking,
    garage = hasGarage,
    image = image,
    area = area,
    sale = propertyData.sale,
    rental = propertyData.rental,
  }


  if propertyData.object_id then
    local buildingKey = tostring(propertyData.object_id)
    local buildingData = Properties[buildingKey]
    if buildingData then
      entry.building = {
        type = buildingData.type,
        name = buildingData.name,
        parkingSpaces = buildingData.metadata and buildingData.metadata.parkingSpaces or nil,
      }
    end
  end

  return entry
end

function openMarketplace()

  isOfferByMarketplace = false
  marketplaceOfferId = nil


  local listedProperties = {}

  for propertyKey, propertyData in pairs(Properties) do
    if isPropertyListedForMarketplace(propertyData) then
      listedProperties[propertyKey] = buildMarketplaceEntry(propertyKey, propertyData)
    end
  end


  local payload = {
    action = "Marketplace",
    actionName = "Open",
    data = {
      propertiesList = listedProperties,
      noRegion = Config.NoRegion,
      regions = Config.Regions,
    }
  }


  SetNuiFocus(true, true)
  SendNUIMessage(payload)
  openedMenu = "Marketplace"
end

function closeMarketplace()
  SendNUIMessage({
    action = "Marketplace",
    actionName = "Close",
  })

  SetNuiFocus(false, false)
  openedMenu = nil


  isOfferByMarketplace = false
  marketplaceOfferId = nil
end


exports("OpenMarketplace", openMarketplace)
