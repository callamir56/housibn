if Config.Weather ~= 'qb-weathersync' and Config.Weather ~= 'qbx_weathersync' then
    return
end

function ToggleWeather(toggle, isIPL)
    if toggle then

        if not isIPL then
            TriggerEvent('qb-weathersync:client:DisableSync')
        end
    else

        TriggerEvent('qb-weathersync:client:EnableSync')
        SetArtificialLightsState(false)
    end
end
