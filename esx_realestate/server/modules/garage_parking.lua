

local locks = {}
local function distance(a,b,r)
    if not a or not b then return false end
    local x,y,z = a.x-b.x,a.y-b.y,a.z-b.z
    return x*x+y*y+z*z <= r*r
end
local function trim(s) return type(s)=='string' and s:match('^%s*(.-)%s*$') or '' end
local function context(src,id)
    local player=SV.GetPlayer(src)
    local identifier=player and SV.GetIdentifier(player)
    if not HousingGarageAccess.CanUse(id,identifier) then return end
    local property=GetProperty(id)
    local ped=GetPlayerPed(src)
    if not ped or ped==0 or GetPlayerRoutingBucket(src) ~= 0 or not distance(GetEntityCoords(ped),property.metadata.garage,8.0) then return end
    return identifier, property, ped
end
local function parked(id)
    local rows=MySQL.query.await('SELECT `property_id`,`owner`,`plate`,`vehicle` FROM `housing_garage_vehicles` WHERE `property_id` = ? LIMIT 1',{id})
    return rows and rows[1]
end
local function decode(s)
    local ok,v=pcall(json.decode,s or '')
    return ok and type(v)=='table' and v or nil
end


local function findParkedEntity(id, plate, model)
    local found, conflict
    for _, entity in ipairs(GetAllVehicles()) do
        if DoesEntityExist(entity)
            and trim(GetVehicleNumberPlateText(entity)):upper() == trim(plate):upper()
            and (GetEntityModel(entity) & 0xffffffff) == (model & 0xffffffff) then
            local state = Entity(entity).state.housingGarageGhost
            if type(state) == 'table' and tostring(state.propertyId) == id then
                if found then conflict = true else found = entity end
            else

                conflict = true
            end
        end
    end
    return found, conflict or false
end
local function announce() TriggerClientEvent('vms_housing:garage:changed',-1) end
local function guarded(src, cb, id, fn)
    id=tostring(id or '')
    local identifier, property, ped=context(src,id)
    if not identifier then return cb({ok=false,reason='Access denied or too far away.'}) end
    if locks[id] then return cb({ok=false,reason='Please wait.'}) end
    locks[id]=true
    local ok, result=pcall(fn,id,identifier,property,ped)
    locks[id]=nil
    if not ok then
        print(('[esx_realestate] Garage error: %s'):format(tostring(result)))
        return cb({ok=false,reason='Garage unavailable.'})
    end
    cb(result)
end

library.RegisterCallback('vms_housing:garage:status',function(src,cb,id)
    guarded(src,cb,id,function(propertyId, identifier)
        local row=parked(propertyId)
        if not row then return {ok=true} end
        return {ok=true, parked={plate=row.plate, canTake=row.owner==identifier}}
    end)
end)

library.RegisterCallback('vms_housing:garage:park',function(src,cb,id,netId,props)
    guarded(src,cb,id,function(propertyId,identifier,property,ped)
        if parked(propertyId) then return {ok=false,reason='Garage is full.'} end
        local net=tonumber(netId)
        local vehicle=net and net>0 and NetworkGetEntityFromNetworkId(net) or 0
        if not vehicle or vehicle==0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle)~=2
            or GetEntityRoutingBucket(vehicle)~=0 or not distance(GetEntityCoords(vehicle),GetEntityCoords(ped),12.0) then
            return {ok=false,reason='Vehicle not nearby.'}
        end
        for _, other in ipairs(GetPlayers()) do
            local otherPed=GetPlayerPed(tonumber(other))
            if otherPed and otherPed~=0 and GetVehiclePedIsIn(otherPed,false)==vehicle then
                return {ok=false,reason='Everyone must exit the vehicle.'}
            end
        end
        local plate=trim(GetVehicleNumberPlateText(vehicle))
        if plate=='' or #plate>16 or type(props)~='table' or trim(props.plate)~=plate
            or type(props.model)~='number' or (props.model & 0xffffffff)~=(GetEntityModel(vehicle) & 0xffffffff) then
            return {ok=false,reason='Invalid vehicle.'}
        end
        local rows=MySQL.query.await('SELECT `owner`,`plate`,`vehicle`,`stored` FROM `owned_vehicles` WHERE UPPER(TRIM(`plate`)) = UPPER(?) AND `owner` = ? LIMIT 2',{plate,identifier})
        local row=rows and #rows==1 and rows[1]
        local registered=row and decode(row.vehicle)
        local storedStatus = row and tonumber(row.stored)
        if not HousingGarageAccess.OwnsVehicle(identifier,row) or (storedStatus~=0 and storedStatus~=1) or not registered
            or type(registered.model)~='number' or (registered.model & 0xffffffff)~=(props.model & 0xffffffff) then
            return {ok=false,reason='Vehicle is not available.'}
        end
        local stillAllowed, _, currentPed=context(src,propertyId)
        if stillAllowed~=identifier or not DoesEntityExist(vehicle) or not distance(GetEntityCoords(vehicle),GetEntityCoords(currentPed),12.0)
            or trim(GetVehicleNumberPlateText(vehicle))~=plate then return {ok=false,reason='Vehicle no longer available.'} end
        local encoded=json.encode(props)
        if not encoded or #encoded>65536 then return {ok=false,reason='Invalid vehicle data.'} end



        if storedStatus == 1 then
            local alreadyParked = MySQL.query.await('SELECT `plate` FROM `housing_garage_vehicles` WHERE UPPER(TRIM(`plate`)) = UPPER(?) LIMIT 1', {plate})
            if not alreadyParked or #alreadyParked > 0 then return {ok=false,reason='Vehicle is already parked.'} end
            local updated = MySQL.update.await('UPDATE `owned_vehicles` SET `stored` = 0 WHERE UPPER(TRIM(`plate`)) = UPPER(?) AND `owner` = ? AND `stored` = 1 LIMIT 1', {plate,identifier})
            if updated ~= 1 then return {ok=false,reason='Vehicle status changed. Try again.'} end


        end
        local currentIdentifier, _, checkedPed = context(src, propertyId)
        if currentIdentifier ~= identifier or not DoesEntityExist(vehicle)
            or not distance(GetEntityCoords(vehicle),GetEntityCoords(checkedPed),12.0)
            or trim(GetVehicleNumberPlateText(vehicle)) ~= plate then
            return {ok=false,reason='Vehicle no longer available.'}
        end
        for _, other in ipairs(GetPlayers()) do
            local otherPed=GetPlayerPed(tonumber(other))
            if otherPed and otherPed~=0 and GetVehiclePedIsIn(otherPed,false)==vehicle then
                return {ok=false,reason='Everyone must exit the vehicle.'}
            end
        end

        local inserted=MySQL.update.await('INSERT INTO `housing_garage_vehicles` (`property_id`,`owner`,`plate`,`vehicle`) VALUES (?, ?, ?, ?)',{propertyId,identifier,plate,encoded})
        if not inserted or inserted~=1 then return {ok=false,reason='Could not park vehicle.'} end
        local p = property.metadata.garage
        local old = GetEntityCoords(vehicle)
        local oldHeading = GetEntityHeading(vehicle)
        local moved, err = pcall(function()
            Entity(vehicle).state:set('housingGarageGhost', {propertyId=propertyId}, true)
            SetEntityCoords(vehicle, p.x, p.y, p.z, false, false, false, false)
            SetEntityHeading(vehicle, p.w or 0.0)
        end)
        if not moved or not DoesEntityExist(vehicle) then
            if DoesEntityExist(vehicle) then
                pcall(function() Entity(vehicle).state:set('housingGarageGhost', nil, true); SetEntityCoords(vehicle, old.x, old.y, old.z, false, false, false, false); SetEntityHeading(vehicle, oldHeading) end)
            end
            MySQL.update.await('DELETE FROM `housing_garage_vehicles` WHERE `property_id` = ? AND `owner` = ? AND `plate` = ?',{propertyId,identifier,plate})
            if not moved then print(('[esx_realestate] Could not park vehicle: %s'):format(tostring(err))) end
            return {ok=false,reason='Could not move vehicle. Try again.'}
        end
        announce()
        return {ok=true}
    end)
end)

library.RegisterCallback('vms_housing:garage:take',function(src,cb,id)
    guarded(src,cb,id,function(propertyId,identifier,property)
        local row=parked(propertyId)
        if not row or not HousingGarageAccess.CanUse(propertyId,identifier,row.owner) then return {ok=false,reason='Vehicle unavailable.'} end
        local data=decode(row.vehicle)
        local owned=MySQL.query.await('SELECT `owner`,`stored` FROM `owned_vehicles` WHERE UPPER(TRIM(`plate`)) = UPPER(?) AND `owner` = ? LIMIT 2',{row.plate,identifier})
        if not data or type(data.model)~='number' or not owned or #owned~=1 or not HousingGarageAccess.OwnsVehicle(identifier,owned[1]) or tonumber(owned[1].stored)~=0 then
            return {ok=false,reason='Vehicle unavailable.'}
        end
        if context(src,propertyId)~=identifier then return {ok=false,reason='Access denied or too far away.'} end
        local p=property.metadata.garage
        local entity, ambiguous = findParkedEntity(propertyId, row.plate, data.model)
        if ambiguous then return {ok=false,reason='Duplicate parked vehicles detected.'} end
        local existing = entity ~= nil
        if not existing then
            for _,other in ipairs(GetAllVehicles()) do
                if DoesEntityExist(other) and GetEntityRoutingBucket(other)==0 and distance(GetEntityCoords(other),p,3.5) then
                    return {ok=false,reason='Parking space is blocked.'}
                end
            end

            entity=CreateVehicleServerSetter(data.model,'automobile',p.x,p.y,p.z,p.w or 0.0)
            if not entity or entity==0 or not DoesEntityExist(entity) then return {ok=false,reason='Could not spawn vehicle.'} end
        end
        local net=NetworkGetNetworkIdFromEntity(entity)
        if not net or net==0 then if not existing then DeleteEntity(entity) end; return {ok=false,reason='Could not retrieve vehicle.'} end
        if existing then
            local released = pcall(function() Entity(entity).state:set('housingGarageGhost', nil, true) end)
            if not released then return {ok=false,reason='Could not release vehicle.'} end
        end
        local dbOk,removed=pcall(MySQL.update.await,'DELETE FROM `housing_garage_vehicles` WHERE `property_id` = ? AND `owner` = ? AND `plate` = ?',{propertyId,identifier,row.plate})
        if not dbOk or removed~=1 then
            if existing then
                pcall(function() Entity(entity).state:set('housingGarageGhost', {propertyId=propertyId}, true) end)
            else
                DeleteEntity(entity)
            end
            return {ok=false,reason='Could not retrieve vehicle.'}
        end
        announce()
        return {ok=true,netId=net,props=data}
    end)
end)

library.RegisterCallback('vms_housing:garage:ghosts',function(src,cb)
    if not HousingDataReady or GetPlayerRoutingBucket(src)~=0 then return cb({}) end
    local ped=GetPlayerPed(src)
    if not ped or ped==0 then return cb({}) end
    local pos=GetEntityCoords(ped)
    local ok,rows=pcall(MySQL.query.await,'SELECT `property_id`,`vehicle` FROM `housing_garage_vehicles`',{})
    if not ok or not rows then return cb(nil) end
    local result={}
    for _,row in ipairs(rows) do
        local property=GetProperty(tostring(row.property_id))
        local p=property and property.metadata and property.metadata.garage
        if p and distance(pos,p,100.0) then
            local data=decode(row.vehicle)
            if data and type(data.model)=='number' then
                local entity, ambiguous = findParkedEntity(tostring(row.property_id), data.plate, data.model)
                local net = not ambiguous and entity and NetworkGetNetworkIdFromEntity(entity) or nil
                result[#result+1]={id=row.property_id,coords=p,props=data,netId=net}
            end
        end
    end
    cb(result)
end)
