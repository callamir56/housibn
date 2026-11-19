if Config.Dispatch ~= 'core_dispatch' then
    return
end

function DispatchAlertClient(property, type)
    local coords = nil
    if property.type == 'mlo' then
        coords = vector3(property.metadata.menu.x, property.metadata.menu.y, property.metadata.menu.z)
    else
        coords = vector3(property.metadata.enter.x, property.metadata.enter.y, property.metadata.enter.z)
    end

    if not coords then
        return
    end

    TriggerServerEvent("core_dispatch:addCall", 
        "459",
        "Burglary",
        { {icon = "fa-venus-mars", info = "male"} },
        {coords.x, coords.y, coords.z},
        'police',
        5000,
        480,
        1,
        false
    )
end
