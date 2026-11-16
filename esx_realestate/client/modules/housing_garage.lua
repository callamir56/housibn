-- Read-only candidate selection until safe parking and retrieval are complete.
local active = false
local session = 0

local function close()
    if not active then return end
    active = false
    session = session + 1
    SendNUIMessage({action='HousingGarage', actionName='Close'})
    if openedMenu == 'HousingGarage' then
        openedMenu = nil
        SetNuiFocus(false, false)
    end
end
CloseHousingGarage = close

function OpenHousingGarage(propertyId)
    if active or openedMenu then return end
    active = true
    session = session + 1
    local thisSession = session
    openedMenu = 'HousingGarage'
    SetNuiFocus(true, true)
    SendNUIMessage({action='HousingGarage', actionName='Open'})
    local ped = PlayerPedId()
    local origin = GetEntityCoords(ped)
    local candidates, vehicleInfo = {}, {}
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if #(GetEntityCoords(vehicle) - origin) <= 12.0 and NetworkGetEntityIsNetworked(vehicle) then
            local id = NetworkGetNetworkIdFromEntity(vehicle)
            if id and id ~= 0 then
                candidates[#candidates + 1] = {id = id, distance = #(GetEntityCoords(vehicle) - origin)}
                local model = GetEntityModel(vehicle)
                local display = GetDisplayNameFromVehicleModel(model)
                local label = GetLabelText(display)
                vehicleInfo[id] = (label and label ~= 'NULL') and label or display
            end
        end
    end
    table.sort(candidates, function(a, b) return a.distance < b.distance end)
    local ids = {}
    for i = 1, math.min(#candidates, 30) do ids[i] = candidates[i].id end
    library.Callback('vms_housing:garage:candidates', function(result)
        if not active or session ~= thisSession then return end
        if not result or not result.ok then
            return SendNUIMessage({action='HousingGarage', actionName='Error', data='Unable to load nearby vehicles.'})
        end
        for _, vehicle in ipairs(result.vehicles or {}) do vehicle.name = vehicleInfo[vehicle.id] or 'Vehicle' end
        SendNUIMessage({action='HousingGarage', actionName='Update', data=result.vehicles or {}})
    end, tostring(propertyId), ids)
end

RegisterNUICallback('housingGarage:close', function(_, cb) close(); cb({ok=true}) end)
AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then close() end
end)
