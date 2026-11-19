if Config.Weather ~= 'av_weather' then
    return
end

function ToggleWeather(toggle, isIPL)
    if toggle then

        if not isIPL then
            TriggerEvent('av_weather:freeze', true, 23, 30, "EXTRASUNNY", false, false, false)
        end
    else

        TriggerEvent('av_weather:freeze', false)
        SetArtificialLightsState(false)
    end
end
