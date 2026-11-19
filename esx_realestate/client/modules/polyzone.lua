



























local isInPropertyZone = false
local isInsideInteriorZone = false


local currentPropertyId = nil
local currentPropertyData = nil


function GetCurrentPropertyId()
  return currentPropertyId
end

function GetCurrentPropertyData()
  return currentPropertyData
end


function IsInsideMLO()
  return isInsideInteriorZone
end










function EnterZone(_, propertyId, __)
  currentPropertyId = propertyId


  while waitingForLoadAfterRestart do
    Citizen.Wait(200)
  end

  library.Debug(("You entered the Property Zone: %s"):format(currentPropertyId))

  local prop = Properties[currentPropertyId]
  if not prop then
    return
  end

  currentPropertyData = prop
  RefreshTargets()


  if currentPropertyData.furniture and not CurrentShell and not CurrentIPL then

    Property:LoadFurniture("outside", currentPropertyData.furniture, currentPropertyId)


    if currentPropertyData.type == "mlo" then
      Property:LoadFurniture("inside", currentPropertyData.furniture, currentPropertyId)
    end
  end





  Citizen.CreateThread(function()
    while true do
      if not currentPropertyId then
        break
      end

      if prop.type ~= "motel" and prop.type ~= "mlo" then
        break
      end

      if prop.type == "motel" then

        local motelRooms = Property:GetMotelRooms(currentPropertyData)


        for i = #TargetPoints, 1, -1 do
          if TargetPoints[i].type == "door" then
            CL.Target("remove-entity", TargetPoints[i].entity)
            table.remove(TargetPoints, i)
          end
        end


        for _, room in pairs(motelRooms) do
          if room.type == "mlo" then
            local doors = room.metadata.doors
            local roomKey = tostring(room.id)


            if room.owner or room.renter then
              Property:LoadDoors(doors, roomKey, false)
            else

              Property:LoadDoors(doors, roomKey, false, true)
            end
          end
        end
      else

        local doors = currentPropertyData.metadata.doors


        local isUnowned = (currentPropertyData.owner == nil)
        Property:LoadDoors(doors, nil, true, isUnowned)
      end

      Wait(1500)
    end
  end)
end






function ExitZone(_, __, ___)
  library.Debug(("You have left the Property Zone: %s"):format(currentPropertyId))


  isInPropertyZone = nil
  currentPropertyId = nil
  currentPropertyData = nil



  if not CurrentShell and not CurrentIPL then Property:RemoveFurniture() end


  if Property.EditingFurnitureObj then
    if DoesEntityExist(Property.EditingFurnitureObj) then
      DeleteObject(Property.EditingFurnitureObj)
    end

    Property.EditingFurniture = false
    Property.EditingFurnitureObj = nil
    Property.EditingFurnitureData = {}
  end


  closeNUI(true)


  for i = 1, #TargetPoints do
    local tp = TargetPoints[i]

    if tp.type == "entity" or tp.type == "door" then
      CL.Target("remove-entity", tp.entity)
    else
      CL.Target("remove-zone", tp.id)
    end
  end

  TargetPoints = {}
  RefreshTargets()
end










function getZoneCenter(points, minZ, maxZ)
  local sumX, sumY = 0, 0
  local count = #points

  for i = 1, count do
    sumX = sumX + points[i].x
    sumY = sumY + points[i].y
  end

  local z = 0.0
  if minZ and maxZ then
    z = (minZ + maxZ) / 2
  end

  return vector3(sumX / count, sumY / count, z)
end





function calculatePolygonArea(points)
  local sum = 0
  local j = #points

  for i = 1, #points do
    sum = sum + (points[j].x + points[i].x) * (points[j].y - points[i].y)
    j = i
  end

  local area = math.abs(sum) / 2

  if Config.AreaUnit == "ft2" then
    area = area * 10.7639
  end

  return math.floor(area)
end





function isPointInPolygon(point, poly)
  local intersections = 0
  local n = #poly
  local px, py = point.x, point.y

  for i = 1, n do
    local j = (i % n) + 1
    local a = poly[i]
    local b = poly[j]

    local aboveA = py < a.y
    local aboveB = py < b.y

    if aboveA ~= aboveB then
      local x = (b.x - a.x) * (py - a.y) / (b.y - a.y) + a.x
      if px < x then
        intersections = intersections + 1
      end
    end
  end

  return (intersections % 2) == 1
end













function _drawWall(p1, p2, minZ, maxZ, r, g, b)
  local a1 = vector3(p1.x, p1.y, minZ)
  local a2 = vector3(p1.x, p1.y, maxZ)
  local b1 = vector3(p2.x, p2.y, minZ)
  local b2 = vector3(p2.x, p2.y, maxZ)


  DrawPoly(a1, a2, b1, r, g, b, 70)
  DrawPoly(a2, b2, b1, r, g, b, 70)
  DrawPoly(b1, b2, a2, r, g, b, 70)
  DrawPoly(b1, a2, a1, r, g, b, 70)
end




Citizen.CreateThread(function()
  while waitingForLoadAfterRestart do
    Citizen.Wait(200)
  end

  while Config.DebugPolyZone do
    for _, prop in pairs(Properties) do
      local zone = prop.metadata and prop.metadata.zone
      if zone and zone.points then
        local pts = zone.points

        for i = 1, #pts do
          local p1 = pts[i]
          local p2 = (i < #pts) and pts[i + 1] or pts[1]
          _drawWall(p1, p2, zone.minZ, zone.maxZ, 76, 17, 166)
        end

        local interior = prop.metadata and prop.metadata.interiorZone
        if interior and interior.points then
          local ipts = interior.points

          for i = 1, #ipts do
            local p1 = ipts[i]
            local p2 = (i < #ipts) and ipts[i + 1] or ipts[1]
            _drawWall(p1, p2, interior.minZ, interior.maxZ, 114, 49, 212)
          end
        end
      end
    end

    Citizen.Wait(1)
  end
end)




Citizen.CreateThread(function()
  while waitingForLoadAfterRestart do
    Citizen.Wait(200)
  end

  if Config.DebugRegionsZone then
    RegisterCommand("getRegion", function()
      local coords = GetEntityCoords(PlayerPedId())
      local region = library.GetCurrentRegion(coords.xyz) or "None"
      if Config and Config.Debug then print(("Region: ^3%s"):format(region)) end
    end)
  end

  while Config.DebugRegionsZone do
    for _, regionData in pairs(Config.Regions) do
      local zone = regionData.zone
      if zone then
        for i = 1, #zone do
          local p1 = zone[i]
          local p2 = (i < #zone) and zone[i + 1] or zone[1]

          local r = (regionData.debugColor and regionData.debugColor.x) or 76
          local g = (regionData.debugColor and regionData.debugColor.y) or 17
          local b = (regionData.debugColor and regionData.debugColor.z) or 166

          _drawWall(p1, p2, -20.0, 350.0, r, g, b)
        end
      end
    end

    Citizen.Wait(1)
  end
end)




Citizen.CreateThread(function()
  while waitingForLoadAfterRestart do
    Citizen.Wait(200)
  end

  local shouldSleepLong = true

  while true do
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local point2D = vec2(coords.x, coords.y)

    shouldSleepLong = true


    for propertyId, prop in pairs(Properties) do
      local zone = prop.metadata and prop.metadata.zone
      if zone and zone.points then
        if isPointInPolygon(point2D, zone.points) then
          if coords.z >= zone.minZ and coords.z <= zone.maxZ then

            if not isInPropertyZone then
              isInPropertyZone = true
              EnterZone(true, propertyId)
              Citizen.Wait(150)
            end


            local interior = prop.metadata and prop.metadata.interiorZone
            if interior and interior.points then
              if isPointInPolygon(point2D, interior.points) then
                if coords.z >= interior.minZ and coords.z <= interior.maxZ then
                  if not isInsideInteriorZone then
                    isInsideInteriorZone = true
                    Property:EnterPropertyInterior(prop)
                  end
                end
              end
            end

            shouldSleepLong = false
            break
          end
        end
      end
    end




    if currentPropertyId and not isInsideInteriorZone then
      if currentPropertyData and currentPropertyData.type == "motel" then
        for _, prop in pairs(Properties) do
          if prop.type == "mlo" and prop.object_id == tonumber(currentPropertyId) then
            local interior = prop.metadata and prop.metadata.interiorZone
            if interior and interior.points then
              if isPointInPolygon(point2D, interior.points) then
                if coords.z >= interior.minZ and coords.z <= interior.maxZ then
                  isInsideInteriorZone = true
                  Property:EnterPropertyInterior(prop, prop.id)
                end
              end
            end
          end
        end
      end
    end



    if isInPropertyZone and currentPropertyId and currentPropertyData and isInsideInteriorZone then
      if CurrentPropertyData and CurrentPropertyData.metadata and CurrentPropertyData.metadata.interiorZone then
        local interior = CurrentPropertyData.metadata.interiorZone

        local inside2D = isPointInPolygon(point2D, interior.points)
        local insideZ = coords.z >= interior.minZ and coords.z <= interior.maxZ

        if not (inside2D and insideZ) then
          isInsideInteriorZone = false
          Property:ExitPropertyInterior()
        end
      end
    end


    if isInPropertyZone and currentPropertyId and currentPropertyData then
      local zone = currentPropertyData.metadata.zone

      local inside2D = isPointInPolygon(point2D, zone.points)
      local insideZ = coords.z >= zone.minZ and coords.z <= zone.maxZ

      if not (inside2D and insideZ) then
        isInPropertyZone = false
        isInsideInteriorZone = false

        ExitZone(true, currentPropertyId)
        Citizen.Wait(150)
      end
    end

    Citizen.Wait(shouldSleepLong and 800 or 100)
  end
end)
