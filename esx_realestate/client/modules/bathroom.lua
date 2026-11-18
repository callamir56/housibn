-- Cosmetic interactions only: no needs, inventory, or server rewards are changed.
local session
local options = {toilet='housing-use-toilet', shower='housing-use-shower', bath='housing-use-bath'}
local function stop()
    local s = session
    if not s then return end
    session = nil
    if DoesEntityExist(s.ped) then
        if s.kind == 'bath' then
            StopAnimTask(s.ped, 'amb@world_human_sunbathe@male@back@base', 'base', 1.0)
        elseif s.kind == 'shower' then
            StopAnimTask(s.ped, 'mp_safehouseshower@female@', 'shower_idle_a', 1.0)
        else
            ClearPedTasks(s.ped)
        end
        if s.frozen then FreezeEntityPosition(s.ped, false) end
        if s.origin and PlayerPedId() == s.ped and not IsEntityDead(s.ped) and tostring(CurrentProperty or '') == s.property then
            SetEntityCoordsNoOffset(s.ped, s.origin.x, s.origin.y, s.origin.z, false, false, false)
            SetEntityHeading(s.ped, s.heading)
        end
    end
end
local function usable(entity)
    local ped = PlayerPedId()
    return Config.HousingBathroom and Config.HousingBathroom.Enabled and CurrentProperty ~= nil
        and not session and DoesEntityExist(entity) and not IsEntityDead(ped)
        and not IsPedInAnyVehicle(ped, false)
        and not (Property and (Property.EditingFurniture or Property.EditingTheme))
end
local function use(entity, kind)
    if not usable(entity) then return end
    local cfg, ped = Config.HousingBathroom, PlayerPedId()
    local offset = kind == 'toilet' and cfg.ToiletOffset or (kind == 'bath' and cfg.BathOffset or cfg.ShowerOffset)
    if kind == 'bath' and cfg.BathOffsets then
        for model, custom in pairs(cfg.BathOffsets) do
            if GetHashKey(model) == GetEntityModel(entity) then offset = custom; break end
        end
    end
    if not offset then return end
    local pos = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
    local heading = GetEntityHeading(entity) + (offset.heading or 0.0)
    local s = {ped=ped, entity=entity, property=tostring(CurrentProperty), kind=kind}
    session = s
    if kind == 'toilet' then
        TaskStartScenarioAtPosition(ped, 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER', pos.x, pos.y, pos.z, heading, -1, true, true)
    else
        s.origin, s.heading = GetEntityCoords(ped), GetEntityHeading(ped)
        SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
        SetEntityHeading(ped, heading)
        FreezeEntityPosition(ped, true)
        s.frozen = true
        CreateThread(function()
            local dict = kind == 'bath' and 'amb@world_human_sunbathe@male@back@base' or 'mp_safehouseshower@female@'
            local anim = kind == 'bath' and 'base' or 'shower_idle_a'
            library.LoadDict(dict)
            if session ~= s then return end
            if not HasAnimDictLoaded(dict) then stop(); return CL.Notification('Animation unavailable.', 4000, 'error') end
            TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 1, 0, false, false, false)
        end)
    end
    CL.Notification('Press X to stop.', 4000, 'info')
    CreateThread(function()
        local deadline = GetGameTimer() + math.max(1000, math.min(tonumber(cfg.DurationMs) or 10000, 120000))
        while session == s do
            Wait(0)
            if PlayerPedId() ~= ped or IsEntityDead(ped) or not DoesEntityExist(entity)
                or tostring(CurrentProperty or '') ~= s.property or IsControlJustPressed(0, 73)
                or GetGameTimer() >= deadline then stop(); break end
        end
    end)
end
CreateThread(function()
    local cfg = Config.HousingBathroom
    if not cfg or not cfg.Enabled or Config.TargetResource ~= 'ox_target' then return end
    for kind, models in pairs({toilet=cfg.ToiletModels, shower=cfg.ShowerModels, bath=cfg.BathModels}) do
        if models and #models > 0 then
            exports.ox_target:addModel(models, {{
                name=options[kind], icon=kind == 'toilet' and 'fa-solid fa-toilet' or (kind == 'bath' and 'fa-solid fa-bath' or 'fa-solid fa-shower'),
                label=kind == 'toilet' and 'Use toilet' or (kind == 'bath' and 'Take a bath' or 'Take a shower'), distance=1.8,
                canInteract=function(entity) return usable(entity) end,
                onSelect=function(data) use(data.entity, kind) end,
            }})
        end
    end
end)
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    stop()
    local cfg = Config.HousingBathroom
    if cfg and Config.TargetResource == 'ox_target' and GetResourceState('ox_target') == 'started' then
        if cfg.ToiletModels then exports.ox_target:removeModel(cfg.ToiletModels, options.toilet) end
        if cfg.ShowerModels then exports.ox_target:removeModel(cfg.ShowerModels, options.shower) end
        if cfg.BathModels then exports.ox_target:removeModel(cfg.BathModels, options.bath) end
    end
end)
