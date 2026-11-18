HousingRest = {}
local active, starting = nil, false
local dict, anim = 'amb@world_human_sunbathe@male@back@base', 'base'

local function finish(notifyServer)
    local session = active
    if not session then return end
    active = nil
    if notifyServer then TriggerServerEvent('vms_housing:rest:cancel', session.token) end
    StopAnimTask(PlayerPedId(), dict, anim, 1.0)
end

function HousingRest.Start(propertyId, furnitureId)
    if active or starting or not propertyId or tostring(CurrentProperty or '') ~= tostring(propertyId) then return end
    starting = true
    library.Callback('vms_housing:rest:start', function(result)
        starting = false
        if not result or not result.ok then
            return CL.Notification(result and result.reason or 'Unable to rest.', 4000, 'error')
        end
        if tostring(CurrentProperty or '') ~= tostring(propertyId) then
            TriggerServerEvent('vms_housing:rest:cancel', result.token)
            return
        end
        active = {token=result.token, property=tostring(propertyId), ped=PlayerPedId()}
        library.PlayAnimation(active.ped, dict, anim, 3.0, 3.0, -1, 1)
        CL.Notification('Resting. Press X to stop.', 4000, 'info')
        CreateThread(function()
            while active and active.token == result.token do
                Wait(0)
                if tostring(CurrentProperty or '') ~= active.property or PlayerPedId() ~= active.ped
                    or IsEntityDead(active.ped) or IsControlJustPressed(0, 73) then finish(true) end
            end
        end)
    end, tostring(propertyId), furnitureId)
end

RegisterNetEvent('vms_housing:rest:tick', function(token, gain)
    if not active or active.token ~= token or tostring(CurrentProperty or '') ~= active.property then return end
    local ped = PlayerPedId()
    if ped ~= active.ped or IsEntityDead(ped) or not IsEntityPlayingAnim(ped, dict, anim, 3) then return finish(true) end
    local amount = math.max(0, math.min(tonumber(gain) or 0, 25))
    SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + amount))
end)
RegisterNetEvent('vms_housing:rest:finish', function(token)
    if active and active.token == token then finish(false) end
end)
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then finish(true) end
end)
