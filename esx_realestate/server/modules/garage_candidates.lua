-- The client supplies network IDs, never ownership. Validate every entity and
-- look up the logged-in character's vehicles on the server.
local function near(a, b, radius)
    if not a or not b then return false end
    local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
    return x*x + y*y + z*z <= radius*radius
end
local function plateKey(plate)
    if type(plate) ~= 'string' or #plate > 16 then return nil end
    local key = plate:match('^%s*(.-)%s*$'):upper()
    if key == '' then return nil end
    return key
end

library.RegisterCallback('vms_housing:garage:candidates', function(src, cb, propertyId, ids)
    propertyId = tostring(propertyId or '')
    local player = SV.GetPlayer(src)
    local identifier = player and SV.GetIdentifier(player)
    if not HousingGarageAccess.CanUse(propertyId, identifier) or type(ids) ~= 'table' then
        return cb({ok = false, reason = 'access'})
    end
    local property = GetProperty(propertyId)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or not near(GetEntityCoords(ped), property.metadata.garage, 8.0) then
        return cb({ok = false, reason = 'distance'})
    end
    local ok, result = pcall(function()
        local rows = MySQL.query.await('SELECT `owner`, `plate`, `stored` FROM `owned_vehicles` WHERE `owner` = ?', {identifier})
        if not rows then error('owned vehicle query failed') end
        local byPlate = {}
        for _, row in ipairs(rows) do
            local key = plateKey(row.plate)
            if key and HousingGarageAccess.OwnsVehicle(identifier, row) then
                -- Ambiguous duplicate normalized plates cannot safely be parked.
                if byPlate[key] ~= nil then byPlate[key] = false else byPlate[key] = row end
            end
        end
        local vehicles, seen = {}, {}
        for i = 1, math.min(#ids, 200) do
            local id = tonumber(ids[i])
            if id and id > 0 and id % 1 == 0 and not seen[id] then
                seen[id] = true
                local vehicle = NetworkGetEntityFromNetworkId(id)
                if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) and GetEntityType(vehicle) == 2
                    and not Entity(vehicle).state.housingGarageGhost
                    and near(GetEntityCoords(vehicle), GetEntityCoords(ped), 12.0)
                    and GetEntityRoutingBucket(vehicle) == GetPlayerRoutingBucket(src) then
                    local key = plateKey(GetVehicleNumberPlateText(vehicle))
                    local row = key and byPlate[key]
                    if row then
                        vehicles[#vehicles + 1] = {id = id, plate = key, available = tonumber(row.stored) == 0 or tonumber(row.stored) == 1}
                    end
                end
            end
        end
        return vehicles
    end)
    if not ok then
        print(('[esx_realestate] Garage candidate lookup failed: %s'):format(err))
        return cb({ok = false, reason = 'database'})
    end
    cb({ok = true, vehicles = result})
end)
