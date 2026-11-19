

if not OpenWardrobe then
  function OpenWardrobe()
    CL.Notification("No compatible clothing resource is configured for the wardrobe.", 5000, "error")
  end
end

if not OpenGarage then
  function OpenGarage()
    CL.Notification("No compatible garage resource is configured for this property.", 5000, "error")
  end
end






library = library or {}



function library.RequestHousingShell(name)
  local definition = AvailableShells[name]
  if definition and definition.mapInterior then return true end
  return library.RequestEntity(name)
end

function SpawnHousingShell(name)
  local definition = AvailableShells[name]
  if definition and definition.mapInterior then return 0 end
  local entity = CreateObjectNoOffset(joaat(name), 0.0, 0.0, 500.0, false, false, false)
  while not DoesEntityExist(entity) do Wait(1) end
  SetEntityHeading(entity, 0.0)
  FreezeEntityPosition(entity, true)
  return entity
end

function DeleteHousingShell(entity)
  if entity and entity ~= 0 then DeleteObject(entity) end
end



function ApplyMapInteriorEntry(propertyId, x, y, z, heading)
  if not CurrentProperty or tostring(CurrentProperty) ~= tostring(propertyId) or CurrentShell ~= 0 then return end
  if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" or type(heading) ~= "number" then return end
  local ped = PlayerPedId()
  RequestCollisionAtCoord(x, y, z)
  SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
  SetEntityHeading(ped, heading)
  RequestCollisionAtCoord(x, y, z)
end


library.WaitGameTimer   = nil
library.IsHaveProp      = nil
library.IsHaveProp2     = nil
library.IsPlayingAnimation = false









function library.ActionLimiter(delayMs)
  local now = GetGameTimer()

  if library.WaitGameTimer and now <= library.WaitGameTimer then
    CL.Notification(TRANSLATE("notify.wait"), 4500, "info")
    return true
  end

  local cooldown = delayMs or 1500
  library.WaitGameTimer = now + cooldown
  return false
end






function library.Debug(message, level)
  if not Config.Debug then
    return
  end

  if level == "error" then
    error(message)
  elseif level == "warn" then
    warn(message)
  else
    print(message)
  end
end





function library.Dump(value)
  return json.encode(value, { indent = true })
end





function library.Deepcopy(value)
  if type(value) ~= "table" then
    return value
  end

  local copy = {}

  for k, v in next, value do
    copy[library.Deepcopy(k)] = library.Deepcopy(v)
  end


  return setmetatable(copy, library.Deepcopy(getmetatable(value)))
end







function library.Callback(callbackName, callbackFn, ...)
  if Config.Core == "ESX" then
    ESX.TriggerServerCallback(callbackName, callbackFn, ...)
  else
    QBCore.Functions.TriggerCallback(callbackName, callbackFn, ...)
  end
end








function library.CallbackAwait(callbackName, ...)
  local p = promise.new()

  if Config.Core == "ESX" then
    ESX.TriggerServerCallback(callbackName, function(...)
      p:resolve(...)
    end, ...)
  else
    QBCore.Functions.TriggerCallback(callbackName, function(...)
      p:resolve(...)
    end, ...)
  end

  return Citizen.Await(p)
end









function library.CreateBlip(data)
  local blip = AddBlipForCoord(data.coords)

  SetBlipSprite(blip, data.sprite)
  SetBlipDisplay(blip, data.display)
  SetBlipScale(blip, data.scale)
  SetBlipColour(blip, data.color)
  SetBlipAsShortRange(blip, true)

  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(data.name)
  EndTextCommandSetBlipName(blip)

  if data.blipCategory ~= nil then
    SetBlipCategory(blip, data.blipCategory)
  end

  return blip
end




function library.DeleteBlip(blip)
  if blip then
    RemoveBlip(blip)
    return nil
  end
end









function library.RequestEntity(model)
  local ok = true
  local timeoutAt = GetGameTimer() + 5000


  local modelHash = tonumber(model)
  modelHash = model or modelHash
  if (not modelHash) or (not model) then
    modelHash = GetHashKey(model)
  end

  RequestModel(modelHash)

  while true do
    if HasModelLoaded(modelHash) then
      break
    end

    RequestModel(modelHash)

    if GetGameTimer() > timeoutAt then
      ok = false
      break
    end

    Wait(1)
  end

  return ok
end











function library.SpawnPed(opts)
  library.RequestEntity(opts.model)

  local heading = (opts.coords.w ~= nil) and opts.coords.w or 0.0
  local ped = CreatePed(
    4,
    opts.model,
    opts.coords.x,
    opts.coords.y,
    opts.coords.z,
    heading,
    false,
    true
  )

  FreezeEntityPosition(ped, true)
  SetEntityInvincible(ped, true)
  TaskSetBlockingOfNonTemporaryEvents(ped, true)

  if opts.animation then
    library.PlayAnimation(
      ped,
      opts.animation[1],
      opts.animation[2],
      8.0,
      8.0,
      -1,
      1
    )
  end

  return ped
end














function library.SpawnProp(model, coords, heading, attachData, disableCollision, dynamic)
  local playerPed = PlayerPedId()


  local modelHash = tonumber(model)
  modelHash = model or modelHash
  if (not modelHash) or (not model) then
    modelHash = GetHashKey(model)
  end

  local spawnCoords
  if coords then
    spawnCoords = vec(coords.x, coords.y, coords.z)
  else
    spawnCoords = GetEntityCoords(playerPed)
  end

  library.RequestEntity(modelHash)

  local obj = CreateObject(
    modelHash,
    spawnCoords.xyz,
    heading,
    false,
    true,
    dynamic or false
  )

  if attachData then
    AttachEntityToEntity(
      obj,
      attachData.attachTo,
      attachData.boneIndex,
      attachData.placement[1],
      attachData.placement[2],
      attachData.placement[3],
      attachData.placement[4],
      attachData.placement[5],
      attachData.placement[6],
      true,
      true,
      false,
      true,
      1,
      true
    )
  end

  if disableCollision then
    SetEntityCollision(obj, false, true)
  end

  return obj
end





function library.LoadDict(dict)
  local timedOut = false

  SetTimeout(5000, function()
    timedOut = true
  end)

  repeat
    RequestAnimDict(dict)
    Wait(50)
  until HasAnimDictLoaded(dict) or timedOut
end










function library.PlayAnimation(ped, dict, anim, blendIn, blendOut, duration, flags, prop1, prop2)
  library.LoadDict(dict)


  if prop1 then
    library.IsHaveProp = library.SpawnProp(
      GetHashKey(prop1[1]),
      prop1[2],
      prop1[3],
      prop1[4],
      prop1[5]
    )
  end


  if prop2 then
    library.IsHaveProp2 = library.SpawnProp(
      GetHashKey(prop2[1]),
      prop2[2],
      prop2[3],
      prop2[4],
      prop2[5]
    )
  end

  library.IsPlayingAnimation = true

  TaskPlayAnim(
    ped,
    dict,
    anim,
    blendIn or 8.0,
    blendOut or 8.0,
    duration,
    flags,
    0,
    false,
    false,
    false
  )
end





function library.StopAnimation(ped)
  if library.IsHaveProp then
    DeleteEntity(library.IsHaveProp)
    library.IsHaveProp = nil
  end

  if library.IsHaveProp2 then
    DeleteEntity(library.IsHaveProp2)
    library.IsHaveProp2 = nil
  end

  if library.IsPlayingAnimation then
    ClearPedTasks(ped)
  end

  library.IsPlayingAnimation = false
end





function library.StartParticles(assetName, fxName, coords, rot, scale, colorData)
  RequestNamedPtfxAsset(assetName)
  while not HasNamedPtfxAssetLoaded(assetName) do
    Citizen.Wait(10)
  end

  UseParticleFxAssetNextCall(assetName)

  local fxHandle = StartParticleFxLoopedAtCoord(
    fxName,
    coords.x, coords.y, coords.z,
    rot.x, rot.y, rot.z,
    scale,
    0.0, 0.0, 0.0,
    0
  )

  if colorData and colorData[1] then
    SetParticleFxLoopedColour(
      fxHandle,
      tonumber(colorData[1]) + 0.0,
      tonumber(colorData[2]) + 0.0,
      tonumber(colorData[3]) + 0.0,
      false
    )

    if colorData[4] then
      SetParticleFxLoopedAlpha(fxHandle, tonumber(colorData[4]) + 0.0)
    end
  end

  return fxHandle
end




function library.StopParticles(handle)
  if DoesParticleFxLoopedExist(handle) then
    RemoveParticleFx(handle, false)
  end
end






function library.PlayAudio(key)
  local file = ""
  local volume = 0

  if key == "enterHouse" then
    file, volume = "enter_house", 0.1
  elseif key == "exitHouse" then
    file, volume = "exit_house", 0.1
  elseif key == "openDoors" then
    file, volume = "open_doors", 0.1
  elseif key == "lockDoors" then
    file, volume = "lock_doors", 0.05
  elseif key == "doorbell" then
    file, volume = "doorbell", 0.005
  elseif key == "doorbellInside" then
    file, volume = "doorbell", 0.1
  elseif key == "lightSwitch" then
    file, volume = "light_switch", 0.12
  end

  if file == "" then
    return
  end


  SendNUIMessage({
    action = "PlayAudio",
    file = file,
    volume = volume,
  })
end





function library.GetCurrentRegion(point)
  for regionKey, regionData in pairs(Config.Regions) do
    if regionData.zone then
      if isPointInPolygon(point, regionData.zone) then
        return regionKey
      end
    end
  end

  return nil
end









function library.HasKeys(propertyId)
  if not propertyId then
    return false
  end

  local property = Properties[propertyId] or Properties[tostring(propertyId)]
  if not property then
    return false
  end

  if not Config.UseKeysOnItem then
    if Identifier and property.owner == Identifier then
      return true
    end

    if Identifier and property.renter == Identifier then
      return true
    end

    if Identifier and property.keys then
      if string.find(tostring(property.keys), tostring(Identifier), 1, true) then
        return true
      end
    end

    return false
  end



  if Identifier and (property.owner == Identifier or property.renter == Identifier) then
    return true
  end

  return false
end
 




function library.HasPermissions(propertyId, permissionKey)
  if not propertyId or not permissionKey then
    return false
  end

  local property = Properties[propertyId] or Properties[tostring(propertyId)]
  if not property then
    return false
  end
 
  if property.owner and property.owner == Identifier then
    return true
  end
 
  local perms = property.permissions
  if perms and perms[Identifier] and perms[Identifier][permissionKey] then
    return true
  end
 
  return false
end
 
function library.HasAnyPermission(propertyId)
  if not propertyId then
    return false
  end

  local property = Properties[propertyId] or Properties[tostring(propertyId)]
  if not property then
    return false
  end
 
  if property.owner and property.owner == Identifier then
    return true
  end
 

  if property.renter and property.renter == Identifier then
    return true
  end
 
  local perms = property.permissions
  if perms and perms[Identifier] then
    return true
  end
 
  return false
end





function library.GetItemCount(itemName)
  if not itemName or itemName == "" then
    return 0
  end

  local searchName = tostring(itemName)


  if Config.Inventory == "ox_inventory" and GetResourceState("ox_inventory") == "started" then
    local ok, result = pcall(function()
      return exports.ox_inventory:Search("count", searchName)
    end)

    if ok and type(result) == "number" then
      return result
    end
  end


  if Config.Core == "QB-Core" then
    local items = nil

    if PlayerData and type(PlayerData) == "table" and type(PlayerData.items) == "table" then
      items = PlayerData.items
    elseif QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
      local pd = QBCore.Functions.GetPlayerData()
      if pd and type(pd.items) == "table" then
        items = pd.items
      end
    end

    if items then
      for _, item in pairs(items) do
        if item and item.name == searchName then
          local amount = tonumber(item.amount or item.count or item.quantity) or 0
          return amount
        end
      end
    end
  end


  if Config.Core == "ESX" then
    local inv = nil

    if PlayerData and type(PlayerData) == "table" and type(PlayerData.inventory) == "table" then
      inv = PlayerData.inventory
    elseif ESX and ESX.GetPlayerData then
      local pd = ESX.GetPlayerData()
      if pd and type(pd.inventory) == "table" then
        inv = pd.inventory
      end
    end

    if inv then
      for _, item in pairs(inv) do
        if item and item.name == searchName then
          local count = tonumber(item.count or item.amount or item.quantity) or 0
          return count
        end
      end
    end
  end

  return 0
end

function library.HasItem(itemName, count)
  local needed = tonumber(count) or 1
  if needed < 1 then
    needed = 1
  end

  return library.GetItemCount(itemName) >= needed
end
