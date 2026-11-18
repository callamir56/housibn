-- A session grants small recovery ticks only while the player remains close to
-- an actual placed indoor bed. The cooldown is keyed by character, not source.
local sessions, cooldowns, sequence = {}, {}, 0

local function context(src, propertyId, furnitureId)
    local cfg = Config.HousingRest
    if not cfg or not cfg.Enabled or not HousingDataReady then return end
    local player = SV.GetPlayer(src)
    local identifier = player and SV.GetIdentifier(player)
    local property = identifier and GetProperty(propertyId)
    local ped = GetPlayerPed(src)
    if not property or not property.metadata or property.metadata.lockdown or not ped or ped == 0
        or not IsPlayerInProperty(src, propertyId)
        or GetPlayerRoutingBucket(src) ~= tonumber(propertyId) + 1
        or not (property.renter == identifier or library.HasAnyPermission(propertyId, identifier)) then return end
    local bed
    for _, item in ipairs(property.furniture or {}) do
        if tostring(item.id) == tostring(furnitureId) then bed = item; break end
    end
    if not bed or tonumber(bed.stored) ~= 0 or not bed.position or bed.position.environment ~= 'inside'
        or not ((cfg.Models and cfg.Models[bed.model]) or (Furniture and Furniture[bed.model] and Furniture[bed.model].tag == 'bed')) then return end
    local pos, target = GetEntityCoords(ped), bed.position
    if not pos or not target.x or not target.y or not target.z then return end
    local x, y, z = pos.x-target.x, pos.y-target.y, pos.z-target.z
    local max = math.max(0.5, math.min(tonumber(cfg.MaxDistance) or 3.0, 5.0))
    if x*x+y*y+z*z > max*max or GetEntityHealth(ped) <= 0 then return end
    return identifier
end

local function stop(src, session)
    if sessions[src] ~= session then return end
    sessions[src] = nil
    TriggerClientEvent('vms_housing:rest:finish', src, session.token)
end

library.RegisterCallback('vms_housing:rest:start', function(src, cb, rawId, furnitureId)
    local id = tostring(rawId or '')
    local identifier = tonumber(id) and context(src, id, furnitureId)
    if not identifier then return cb({ok=false, reason='Bed is unavailable or too far away.'}) end
    local now = os.time()
    if sessions[src] or (cooldowns[identifier] or 0) > now then
        return cb({ok=false, reason='Please wait before resting again.'})
    end
    local cfg = Config.HousingRest
    local interval = math.max(1, math.min(tonumber(cfg.TickSeconds) or 5, 60))
    local duration = math.max(interval, math.min(tonumber(cfg.DurationSeconds) or 30, 300))
    local gain = math.max(0, math.min(math.floor(tonumber(cfg.HealPerTick) or 5), 25))
    cooldowns[identifier] = now + math.max(duration, math.min(tonumber(cfg.CooldownSeconds) or 300, 86400))
    sequence = sequence + 1
    local session = {token=sequence, identifier=identifier, id=id, furniture=furnitureId, ticks=math.floor(duration/interval)}
    sessions[src] = session
    cb({ok=true, token=session.token})
    local function tick()
        if sessions[src] ~= session then return end
        if context(src, session.id, session.furniture) ~= session.identifier then return stop(src, session) end
        TriggerClientEvent('vms_housing:rest:tick', src, session.token, gain)
        session.ticks = session.ticks - 1
        if session.ticks <= 0 then return stop(src, session) end
        SetTimeout(interval * 1000, tick)
    end
    SetTimeout(interval * 1000, tick)
end)

RegisterNetEvent('vms_housing:rest:cancel', function(token)
    local session = sessions[source]
    if session and session.token == tonumber(token) then stop(source, session) end
end)
AddEventHandler('playerDropped', function() sessions[source] = nil end)
