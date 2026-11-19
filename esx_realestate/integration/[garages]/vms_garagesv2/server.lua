if Config.Garages ~= 'vms_garagesv2' then
    return
end


function RegisterGarage(propertyId, propertyData, isNew)
    exports['vms_garagesv2']:registerHousingGarage(
        'vms_housing.garage.' .. propertyId,
        propertyData.name,
        propertyId,
        vector4(propertyData.metadata.garage.x, propertyData.metadata.garage.y, propertyData.metadata.garage.z, propertyData.metadata.garage.w),
        1
    )
end
