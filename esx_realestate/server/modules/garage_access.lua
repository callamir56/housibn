-- Server-side checks shared by the planned housing garage implementation.
-- This module does not register network handlers or change vehicles.
HousingGarageAccess = {}

function HousingGarageAccess.CanUse(propertyId, identifier, parkedBy)
    if not HousingDataReady or type(propertyId) ~= 'string' or type(identifier) ~= 'string' or identifier == '' then
        return false
    end
    local property = GetProperty(propertyId)
    if not property or not property.metadata or not property.metadata.garage or property.metadata.lockdown then
        return false
    end
    if parkedBy ~= nil and (type(parkedBy) ~= 'string' or parkedBy ~= identifier) then
        return false
    end
    return library.HasPermissions(propertyId, identifier, 'garage') == true
end

function HousingGarageAccess.OwnsVehicle(identifier, row)
    return type(identifier) == 'string' and identifier ~= '' and type(row) == 'table'
        and type(row.owner) == 'string' and row.owner == identifier
end
