






x, y, z = 0.0, 0.0, 0.0

local function rotationToDirection(rot)
  local rotZ = math.rad(rot.z)
  local rotX = math.rad(rot.x)
  local cosX = math.cos(rotX)
  return vector3(-math.sin(rotZ) * cosX, math.cos(rotZ) * cosX, math.sin(rotX))
end


function startRaycast(cameraHandle)
  local camCoord, camRot

  if cameraHandle and DoesCamExist(cameraHandle) then
    camCoord = GetCamCoord(cameraHandle)
    camRot   = GetCamRot(cameraHandle, 2)
  else
    camCoord = GetGameplayCamCoord()
    camRot   = GetGameplayCamRot(2)
  end

  local direction = rotationToDirection(camRot)
  local maxDistance = 250.0

  local dest = camCoord + (direction * maxDistance)


  local rayHandle = StartShapeTestRay(
    camCoord.x, camCoord.y, camCoord.z,
    dest.x, dest.y, dest.z,
    -1,
    PlayerPedId(),
    0
  )

  local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)


  if hit == 1 then
    x, y, z = endCoords.x, endCoords.y, endCoords.z
    lastRaycastHitEntity = entityHit ~= 0 and entityHit or nil
    return true, endCoords, surfaceNormal, entityHit
  else

    x, y, z = dest.x, dest.y, dest.z
    lastRaycastHitEntity = nil
    return false, dest, vector3(0.0, 0.0, 0.0), 0
  end
end




function RayCastGamePlayCamera(ignoreEntity, distance)
  local camCoord = GetGameplayCamCoord()
  local camRot = GetGameplayCamRot(2)
  local direction = rotationToDirection(camRot)

  local maxDistance = distance or 100.0
  local dest = camCoord + (direction * maxDistance)

  local rayHandle = StartShapeTestRay(
    camCoord.x, camCoord.y, camCoord.z,
    dest.x, dest.y, dest.z,
    -1,
    ignoreEntity or PlayerPedId(),
    0
  )

  local _, hit, endCoords, _surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
  if hit == 1 then
    return true, endCoords, entityHit
  end

  return false, dest, 0
end
