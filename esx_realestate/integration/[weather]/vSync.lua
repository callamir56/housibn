if Config.Weather ~= 'vSync' then
    return
end

function ToggleWeather(toggle, isIPL)
    if toggle then

        TriggerEvent('vSync:toggle', false)
        TriggerEvent('vSync:updateWeather', 'EXTRASUNNY', false) 
        
        if not isIPL then
            Citizen.Wait(100)
            NetworkOverrideClockTime(23, 30, 0)
            ClearOverrideWeather()
            ClearWeatherTypePersist()
            SetWeatherTypePersist('EXTRASUNNY')
            SetWeatherTypeNow('EXTRASUNNY')
            SetWeatherTypeNowPersist('EXTRASUNNY')
        end
    else

        TriggerEvent('vSync:toggle', true)
        TriggerServerEvent('vSync:requestSync')
        SetArtificialLightsState(false)
    end
end
