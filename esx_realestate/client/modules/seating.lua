HousingSeats = {}
local active, pending = nil, false
local function finish(notify)
    local s=active
    if not s then return end
    active=nil
    if notify then TriggerServerEvent('vms_housing:seat:leave',s.token) end
    if DoesEntityExist(s.ped) then ClearPedTasks(s.ped) end
end
function HousingSeats.Layout(model)
    local cfg=Config.HousingSeats
    local def=Furniture and Furniture[model]
    if not cfg or not cfg.Enabled then return end
    return (cfg.Models and cfg.Models[model]) or (def and cfg.Types and cfg.Types[def.tag])
end
function HousingSeats.Sit(id,furnitureId,entity,model)
    if active or pending or not id or tostring(CurrentProperty or '')~=tostring(id) or not DoesEntityExist(entity) then return end
    local layout=HousingSeats.Layout(model)
    if not layout or type(layout.slots)~='table' then return end
    pending=true
    library.Callback('vms_housing:seat:claim',function(result)
        pending=false
        if not result or not result.ok then return CL.Notification(result and result.reason or 'Seat unavailable.',4000,'error') end
        local slot=layout.slots[tonumber(result.slot)]
        if tostring(CurrentProperty or '')~=tostring(id) or not DoesEntityExist(entity) or not slot then
            TriggerServerEvent('vms_housing:seat:leave',result.token); return
        end
        local ped=PlayerPedId()
        if IsPedInAnyVehicle(ped,false) or IsEntityDead(ped) then
            TriggerServerEvent('vms_housing:seat:leave',result.token); return
        end
        local pos=GetOffsetFromEntityInWorldCoords(entity,slot.x or 0.0,slot.y or 0.0,slot.z or 0.45)
        local heading=GetEntityHeading(entity)+(layout.heading or 180.0)
        active={token=result.token,property=tostring(id),ped=ped,entity=entity}
        TaskStartScenarioAtPosition(ped,'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER',pos.x,pos.y,pos.z,heading,-1,true,true)
        CL.Notification('Press X to stand up.',4000,'info')
        CreateThread(function()
            local nextHeartbeat=GetGameTimer()+10000
            local checkScenarioAt=GetGameTimer()+3000
            while active and active.token==result.token do
                Wait(0)
                if tostring(CurrentProperty or '')~=active.property or PlayerPedId()~=active.ped
                    or IsEntityDead(active.ped) or not DoesEntityExist(active.entity) or IsControlJustPressed(0,73)
                    or (GetGameTimer()>=checkScenarioAt and not IsPedUsingScenario(active.ped,'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER')) then
                    finish(true); break
                end
                if GetGameTimer()>=nextHeartbeat then
                    TriggerServerEvent('vms_housing:seat:heartbeat',active.token)
                    nextHeartbeat=GetGameTimer()+10000
                end
            end
        end)
    end,tostring(id),furnitureId)
end
RegisterNetEvent('vms_housing:seat:expired',function(token)
    if active and active.token==token then finish(false) end
end)
AddEventHandler('onResourceStop',function(resource)
    if resource==GetCurrentResourceName() then finish(true) end
end)
