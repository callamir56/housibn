local active, session, propertyId, busy = false, 0, nil, false
local ghosts, ghostVersion = {}, 0
local renderGhost

local function send(action, data)
    SendNUIMessage({action='HousingGarage', actionName=action, data=data})
end
local function close()
    if not active then return end
    active=false; session=session+1; propertyId=nil; busy=false
    send('Close')
    if openedMenu=='HousingGarage' then openedMenu=nil; SetNuiFocus(false,false) end
end
CloseHousingGarage=close

local function refresh()
    if not active then return end
    local current=session
    local ped=PlayerPedId()
    local origin=GetEntityCoords(ped)
    local candidates, labels={},{}
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if #(GetEntityCoords(vehicle)-origin)<=12.0 and NetworkGetEntityIsNetworked(vehicle) then
            local id=NetworkGetNetworkIdFromEntity(vehicle)
            if id and id~=0 then
                candidates[#candidates+1]={id=id,distance=#(GetEntityCoords(vehicle)-origin)}
                local display=GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
                local label=GetLabelText(display)
                labels[id]=(label and label~='NULL') and label or display
            end
        end
    end
    table.sort(candidates,function(a,b) return a.distance<b.distance end)
    local ids={}
    for i=1,math.min(#candidates,200) do ids[i]=candidates[i].id end
    library.Callback('vms_housing:garage:status',function(status)
        if not active or current~=session then return end
        if not status or not status.ok then return send('Error',status and status.reason or 'Garage unavailable.') end
        if status.parked then busy=false; return send('Update',{parked=status.parked,vehicles={}}) end
        library.Callback('vms_housing:garage:candidates',function(result)
            if not active or current~=session then return end
            busy=false
            if not result or not result.ok then return send('Error','Unable to load vehicles.') end
            for _, vehicle in ipairs(result.vehicles or {}) do vehicle.name=labels[vehicle.id] or 'Vehicle' end
            send('Update',{vehicles=result.vehicles or {}})
        end,propertyId,ids)
    end,propertyId)
end

function OpenHousingGarage(id)
    if active or openedMenu then return end
    active=true; session=session+1; propertyId=tostring(id); busy=false
    openedMenu='HousingGarage'; SetNuiFocus(true,true)
    send('Open'); refresh()
end

RegisterNUICallback('housingGarage:close',function(_,cb) close(); cb({ok=true}) end)
RegisterNUICallback('housingGarage:park',function(data,cb)
    local id=type(data)=='table' and tonumber(data.id)
    if not active or busy or not id then return cb({ok=false}) end
    local entity=NetworkGetEntityFromNetworkId(id)
    if not entity or entity==0 or not DoesEntityExist(entity) then return cb({ok=false}) end
    local props=ESX.Game.GetVehicleProperties(entity)
    if not props then return cb({ok=false}) end
    busy=true; local current=session; cb({ok=true})
    library.Callback('vms_housing:garage:park',function(result)
        if not active or current~=session then return end
        busy=false
        if not result or not result.ok then return send('Error',result and result.reason or 'Could not park.') end
        if result.ghost then renderGhost(result.ghost) end
        refresh()
    end,propertyId,id,props)
end)
RegisterNUICallback('housingGarage:take',function(_,cb)
    if not active or busy then return cb({ok=false}) end
    busy=true; local current=session; cb({ok=true})
    library.Callback('vms_housing:garage:take',function(result)
        if result and result.ok then
            CreateThread(function()
                local deadline=GetGameTimer()+10000
                while not NetworkDoesEntityExistWithNetworkId(result.netId) and GetGameTimer()<deadline do Wait(50) end
                if NetworkDoesEntityExistWithNetworkId(result.netId) then
                    local vehicle=NetworkGetEntityFromNetworkId(result.netId)
                    if DoesEntityExist(vehicle) then
                        NetworkRequestControlOfEntity(vehicle)
                        local controlDeadline=GetGameTimer()+5000
                        while not NetworkHasControlOfEntity(vehicle) and GetGameTimer()<controlDeadline do
                            NetworkRequestControlOfEntity(vehicle); Wait(50)
                        end
                        if NetworkHasControlOfEntity(vehicle) then
                            ESX.Game.SetVehicleProperties(vehicle,result.props)
                            SetVehicleOnGroundProperly(vehicle)
                        else
                            CL.Notification('Vehicle spawned, but its customizations could not be applied.',5000,'error')
                        end
                    end
                else
                    CL.Notification('Vehicle spawned but could not be synced. Check the garage area.',5000,'error')
                end
            end)
        end
        if not active or current~=session then return end
        busy=false
        if not result or not result.ok then return send('Error',result and result.reason or 'Could not retrieve vehicle.') end
        close()
    end,propertyId)
end)

local function clearGhosts()
    ghostVersion=ghostVersion+1
    for _,vehicle in pairs(ghosts) do if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end end
    ghosts={}
end
-- Each player sees a local-only display vehicle at the configured garage point.
renderGhost = function(row)
    if type(row) ~= 'table' or type(row.props) ~= 'table' or type(row.coords) ~= 'table' then return end
    local id = tostring(row.id)
    if ghosts[id] and DoesEntityExist(ghosts[id]) then return end
    local current = ghostVersion
    CreateThread(function()
        local model = tonumber(row.props.model)
        if not model or not IsModelAVehicle(model) then
            print(('[esx_realestate] Invalid parked vehicle model for garage %s'):format(id))
            return
        end
        RequestModel(model)
        local deadline = GetGameTimer() + 10000
        while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(0) end
        if current ~= ghostVersion or not HasModelLoaded(model) then
            SetModelAsNoLongerNeeded(model)
            return
        end
        if ghosts[id] and DoesEntityExist(ghosts[id]) then SetModelAsNoLongerNeeded(model); return end
        local p = row.coords
        local vehicle = CreateVehicle(model, p.x, p.y, p.z, p.w or 0.0, false, false)
        SetModelAsNoLongerNeeded(model)
        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
            print(('[esx_realestate] Failed to create parked vehicle for garage %s'):format(id))
            return
        end
        -- Display safety must still be applied if a customization fails.
        local ok, err = pcall(ESX.Game.SetVehicleProperties, vehicle, row.props)
        if not ok then print(('[esx_realestate] Parked vehicle properties: %s'):format(tostring(err))) end
        SetEntityAlpha(vehicle, 102, false)
        SetEntityCollision(vehicle, false, false)
        SetEntityInvincible(vehicle, true)
        SetVehicleDoorsLocked(vehicle, 2)
        SetVehicleDoorsLockedForAllPlayers(vehicle, true)
        SetVehicleUndriveable(vehicle, true)
        SetVehicleEngineOn(vehicle, false, true, true)
        FreezeEntityPosition(vehicle, true)
        ghosts[id] = vehicle
    end)
end

local function updateGhosts()
    local current = ghostVersion + 1
    ghostVersion = current
    library.Callback('vms_housing:garage:ghosts', function(rows)
        if current ~= ghostVersion or type(rows) ~= 'table' then return end
        local wanted = {}
        for _, row in ipairs(rows or {}) do
            wanted[tostring(row.id)] = true
            renderGhost(row)
        end
        for id, vehicle in pairs(ghosts) do
            if not wanted[id] then
                if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
                ghosts[id] = nil
            end
        end
    end)
end
RegisterNetEvent('vms_housing:garage:changed',function() updateGhosts(); if active and not busy then refresh() end end)
CreateThread(function() Wait(1000); while true do if ESX and ESX.Game then updateGhosts() end; Wait(15000) end end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then close(); clearGhosts() end end)
