





local currentSafeFurnitureId = nil
local currentSafeData = nil




function OpenSafe(furnitureId, safeData)
  if not furnitureId or not safeData then
    return
  end


  SetNuiFocus(true, true)
  openedMenu = "Safe"


  currentSafeFurnitureId = furnitureId
  currentSafeData = safeData

  local pin = currentSafeData.pin


  if not pin or pin == "" then
    SendNUIMessage({
      action = "Safe",
      actionName = "SetFirstTime",
    })
    return
  end


  SendNUIMessage({
    action = "Safe",
    actionName = "Open",
  })
end


function CloseSafe()
  SetNuiFocus(false, false)

  SendNUIMessage({
    action = "Safe",
    actionName = "Close",
  })

  openedMenu = nil
  currentSafeFurnitureId = nil
  currentSafeData = nil
end










RegisterNuiCallback("safe:verifyCode", function(data, cb)
  local storedPin = currentSafeData and currentSafeData.pin
  local enteredPin = data.code


  if storedPin == enteredPin then

    if storedPin ~= "" then
      cb(true)


      if not data.isChanging then
        SetNuiFocus(false, false)


        Citizen.CreateThread(function()
          Citizen.Wait(1200)


          CL.InteractableFurniture(nil, "storage", currentSafeFurnitureId, currentSafeData)


          currentSafeFurnitureId = nil
          currentSafeData = nil
        end)
      end
    end
  else
    cb(false)
  end
end)










RegisterNUICallback("safe:changeCode", function(data, cb)
  local oldPin = data.oldCode
  local newPin = data.newCode


  local propertyId = CurrentProperty or GetCurrentPropertyId()


  TriggerServerEvent(
    "vms_housing:sv:changeSafePin",
    propertyId,
    currentSafeFurnitureId,
    newPin,
    oldPin
  )


end)
