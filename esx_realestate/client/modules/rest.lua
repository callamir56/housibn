HousingRest = {}
local active, starting = nil, false
local dict, anim = 'amb@world_human_sunbathe@male@back@base', 'base'

function HousingRest.IsBusy() return active ~= nil or starting end

function HousingRest.IsBed(model)
    local cfg = Config.HousingRest
    local def = Furniture and Furniture[model]
    return cfg and cfg.Enabled and ((cfg.Models and cfg.Models[model]) or (def and def.tag == 'bed'))
end

local function finish(notifyServer)
    local s = active
    if not s then return end
    active = nil
    if notifyServer and s.token then TriggerServerEvent('vms_housing:rest:cancel', s.token) end
    if DoesEntityExist(s.ped) then
        ClearPedTasksImmediately(s.ped)
        if s.origin and PlayerPedId() == s.ped and not IsEntityDead(s.ped)
            and tostring(CurrentProperty or '') == s.property then
            SetEntityCoordsNoOffset(s.ped, s.origin.x, s.origin.y, s.origin.z, false, false, false)
            SetEntityHeading(s.ped, s.heading)
        end
        if s.collisionChanged then SetEntityCollision(s.ped, true, true) end
        if s.frozen then FreezeEntityPosition(s.ped, false) end
    end
    -- Restore the standing position before revealing the screen. No wake-up animation.
    if s.faded then DoScreenFadeIn(500) end
end

local function begin(propertyId, entity, model, token)
    local ped = PlayerPedId()
    if tostring(CurrentProperty or '') ~= tostring(propertyId) or IsEntityDead(ped)
        or IsPedInAnyVehicle(ped, false) or (HousingBathroom and HousingBathroom.IsBusy())
        or (entity and not DoesEntityExist(entity)) then
        if token then TriggerServerEvent('vms_housing:rest:cancel', token) end
        return
    end
    local s = {token=token, property=tostring(propertyId), ped=ped, entity=entity}
    active = s
    if entity then
        local cfg = Config.HousingRest or {}
        local override = (cfg.BedOffsets and cfg.BedOffsets[model]) or cfg.BedOffset
        local offset = HousingInteractionPosition.Resolve(entity, override, 'bed')
        s.origin, s.heading = GetEntityCoords(ped), GetEntityHeading(ped)
        local pos = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
        s.surface = pos
        if type(GetEntityCollisionDisabled) == 'function' and not GetEntityCollisionDisabled(ped) then
            SetEntityCollision(ped, false, false)
            s.collisionChanged = true
        end
        SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
        SetEntityHeading(ped, GetEntityHeading(entity) + (offset.heading or 0.0))
        FreezeEntityPosition(ped, true)
        s.frozen = true
    end
    -- LoadDict can yield, so cancellation/stop must remain able to clean up.
    CreateThread(function()
        library.LoadDict(dict)
        if active ~= s then return end
        if not HasAnimDictLoaded(dict) then finish(true); return CL.Notification('Sleep animation unavailable.', 4000, 'error') end
        TaskPlayAnim(ped, dict, anim, 3.0, 3.0, -1, 1, 0, false, false, false)
        if s.surface then HousingInteractionPosition.AlignPose(ped, s.surface, function() return active == s end) end
        Wait(150)
        if active ~= s then return end
        s.faded = true
        DoScreenFadeOut(300)
        Wait(4300)
        if active == s then finish(true) end
    end)
    CL.Notification('Sleeping. Press X to wake up.', 4000, 'info')
    CreateThread(function()
        while active == s do
            Wait(0)
            if tostring(CurrentProperty or '') ~= s.property or PlayerPedId() ~= ped
                or IsEntityDead(ped) or (entity and not DoesEntityExist(entity)) or IsControlJustPressed(0, 73) then finish(true) end
        end
    end)
end

function HousingRest.Start(propertyId, furnitureId, entity, model)
    if active or starting or (HousingBathroom and HousingBathroom.IsBusy()) or not propertyId or tostring(CurrentProperty or '') ~= tostring(propertyId) then return end
    starting = true
    library.Callback('vms_housing:rest:start', function(result)
        starting = false
        if not result or not result.ok then return CL.Notification(result and result.reason or 'Unable to rest.', 4000, 'error') end
        if active then TriggerServerEvent('vms_housing:rest:cancel', result.token); return end
        begin(propertyId, entity, model, result.token)
    end, tostring(propertyId), furnitureId)
end

-- Fixed map beds are cosmetic: no health reward without server-owned furniture data.
CreateThread(function()
    local cfg = Config.HousingRest
    if not cfg or not cfg.Enabled or not cfg.FixedBeds or Config.TargetResource ~= 'ox_target' then return end
    local models = {}
    for model, enabled in pairs(cfg.Models or {}) do if enabled then models[#models+1] = model end end
    if #models == 0 then return end
    local function fixed(entity)
        if not CurrentProperty or active or starting or (HousingBathroom and HousingBathroom.IsBusy()) or not DoesEntityExist(entity) then return false end
        if Property and (Property.EditingFurniture or Property.EditingTheme) then return false end
        for _, item in ipairs((Property and Property.LoadedFurnitures) or {}) do
            if item.entity == entity then return false end
        end
        return true
    end
    exports.ox_target:addModel(models, {{name='housing-fixed-bed', label='Sleep', icon='fa-solid fa-bed', distance=2.0,
        canInteract=function(entity) return fixed(entity) end,
        onSelect=function(data)
            if fixed(data.entity) then
                local model = nil
                local hash = GetEntityModel(data.entity)
                for _, name in ipairs(models) do if GetHashKey(name) == hash then model = name; break end end
                begin(CurrentProperty, data.entity, model, nil)
            end
        end}})
end)

RegisterNetEvent('vms_housing:rest:tick', function(token, gain)
    if not active or active.token ~= token or tostring(CurrentProperty or '') ~= active.property then return end
    local ped = PlayerPedId()
    if ped ~= active.ped or IsEntityDead(ped) then return finish(true) end
    -- The animation dictionary may still be loading on the first server tick.
    if not IsEntityPlayingAnim(ped, dict, anim, 3) then return end
    local amount = math.max(0, math.min(tonumber(gain) or 0, 25))
    SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + amount))
end)
RegisterNetEvent('vms_housing:rest:finish', function(token)
    if active and active.token == token then finish(false) end
end)
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then finish(true) end
end)
