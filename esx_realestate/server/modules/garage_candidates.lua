-- Read-only candidate discovery. Parking/retrieval is intentionally not enabled here.
local function near(a, b, radius)
    if not a or not b then return false end
    local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
    return x*x + y*y + z*z <= radius*radius
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
    local result, seen = {}, {}
    local ok, err = pcall(function()
        for i = 1, math.min(#ids, 30) do
            local id = tonumber(ids[i])
            if id and id > 0 and id % 1 == 0 and not seen[id] then
                seen[id] = true
                local vehicle = NetworkGetEntityFromNetworkId(id)
                if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) and GetEntityType(vehicle) == 2
                    and near(GetEntityCoords(vehicle), GetEntityCoords(ped), 12.0)
                    and GetEntityRoutingBucket(vehicle) == GetPlayerRoutingBucket(src) then
                    local plate = GetVehicleNumberPlateText(vehicle)
                    if type(plate) == 'string' and #plate <= 16 then
                        plate = plate:match('^%s*(.-)%s*$')
                        local rows = MySQL.query.await('SELECT `owner`, `plate`, `stored` FROM `owned_vehicles` WHERE `plate` = ? AND `owner` = ? LIMIT 1', {plate, identifier})
                        local row = rows and rows[1]
                        if HousingGarageAccess.OwnsVehicle(identifier, row) and tonumber(row.stored) == 0 then
                            result[#result + 1] = {id = id, plate = row.plate}
                        end
                    end
                end
            end
        end
    end)
    if not ok then
        print(('[esx_realestate] Garage candidate lookup failed: %s'):format(err))
        return cb({ok = false, reason = 'database'})
    end
    cb({ok = true, vehicles = result})
end)
