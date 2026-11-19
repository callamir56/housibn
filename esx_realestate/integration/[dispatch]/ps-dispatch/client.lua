if Config.Dispatch ~= 'ps-dispatch' then
    return
end

function DispatchAlertClient(property, type)
    local alarm = Config.Alarm
    
    local coords = nil
    if property.type == 'mlo' then
        coords = vector3(property.metadata.menu.x, property.metadata.menu.y, property.metadata.menu.z)
    else
        coords = vector3(property.metadata.enter.x, property.metadata.enter.y, property.metadata.enter.z)
    end

    if not coords then
        return
    end



end
