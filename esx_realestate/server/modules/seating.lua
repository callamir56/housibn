-- Leases prevent two players choosing the same seat. No entity IDs or
-- coordinates from the client are trusted: the placed furniture is server data.
local occupants, sessions, nextToken = {}, {}, 0
local function layout(item)
    local cfg = Config.HousingSeats
    if not cfg or not cfg.Enabled or not item then return end
    local def = Furniture[item.model]
    local custom = cfg.Models and cfg.Models[item.model]
    local settings = custom or (def and cfg.Types and cfg.Types[def.tag])
    if type(settings) ~= 'table' or type(settings.slots) ~= 'table' or #settings.slots < 1 then return end
    return settings
end
local function valid(src,id,furnitureId)
    local cfg = Config.HousingSeats
    local prop = HousingDataReady and GetProperty(id)
    local player = SV.GetPlayer(src)
    local identifier = player and SV.GetIdentifier(player)
    local ped = GetPlayerPed(src)
    if not cfg or not prop or not identifier or not ped or ped == 0 or not tonumber(id)
        or not IsPlayerInProperty(src,id) or GetPlayerRoutingBucket(src) ~= tonumber(id)+1 then return end
    if cfg.RequirePermission and not (prop.renter == identifier or library.HasAnyPermission(id,identifier)) then return end
    local item
    for _, row in ipairs(prop.furniture or {}) do
        if tostring(row.id) == tostring(furnitureId) then item = row; break end
    end
    local seat = item and layout(item)
    local position = item and item.position
    if not seat or tonumber(item.stored) ~= 0 or not position or position.environment ~= 'inside'
        or not position.x or not position.y or not position.z then return end
    local at = GetEntityCoords(ped)
    if not at then return end
    local x,y,z = at.x-position.x, at.y-position.y, at.z-position.z
    local limit = math.max(1.0, math.min(tonumber(cfg.MaxDistance) or 3.5, 6.0))
    if x*x+y*y+z*z > limit*limit then return end
    return seat
end
local function release(src, token)
    local s = sessions[src]
    if not s or (token and s.token ~= token) then return end
    sessions[src] = nil
    local seats = occupants[s.key]
    if seats and seats[s.slot] == s then seats[s.slot] = nil end
    if seats and not next(seats) then occupants[s.key] = nil end
end
local function lease(session)
    SetTimeout(session.lease * 1000, function()
        if sessions[session.source] ~= session then return end
        if os.time() >= session.expires or not valid(session.source,session.id,session.furniture) then
            TriggerClientEvent('vms_housing:seat:expired',session.source,session.token)
            return release(session.source,session.token)
        end
        lease(session)
    end)
end
library.RegisterCallback('vms_housing:seat:claim', function(src,cb,rawId,furnitureId)
    local id=tostring(rawId or '')
    local settings=valid(src,id,furnitureId)
    if not settings then return cb({ok=false, reason='Seat unavailable or too far away.'}) end
    if sessions[src] then return cb({ok=false,reason='You are already seated.'}) end
    local key=id..':'..tostring(furnitureId)
    occupants[key]=occupants[key] or {}
    local slot
    for i=1,math.min(#settings.slots,8) do if not occupants[key][i] then slot=i; break end end
    if not slot then return cb({ok=false,reason='All seats are occupied.'}) end
    local cfg=Config.HousingSeats
    local duration=math.max(15,math.min(tonumber(cfg.LeaseSeconds) or 30,120))
    nextToken=nextToken+1
    local s={source=src,id=id,furniture=furnitureId,key=key,slot=slot,token=nextToken,lease=duration,expires=os.time()+duration}
    sessions[src]=s; occupants[key][slot]=s
    cb({ok=true,token=s.token,slot=slot})
    lease(s)
end)
RegisterNetEvent('vms_housing:seat:heartbeat',function(token)
    local s=sessions[source]
    if not s or s.token~=tonumber(token) then return end
    if not valid(source,s.id,s.furniture) then
        TriggerClientEvent('vms_housing:seat:expired',source,s.token)
        return release(source,s.token)
    end
    s.expires=os.time()+s.lease
end)
RegisterNetEvent('vms_housing:seat:leave',function(token) release(source,tonumber(token)) end)
AddEventHandler('playerDropped',function() release(source) end)
