-- One transient playback state per property. Only occupants in the property's
-- routing bucket receive it; no external media service is called server-side.
local playing, lastChange, sequence = {}, {}, 0
local function inside(src,id)
    local player=SV.GetPlayer(src)
    local identifier=player and SV.GetIdentifier(player)
    local prop=HousingDataReady and GetProperty(id)
    if not identifier or not prop or not tonumber(id) or not Config.HousingTV or not Config.HousingTV.Enabled
        or not IsPlayerInProperty(src,id) or GetPlayerRoutingBucket(src)~=tonumber(id)+1 then return end
    return prop, identifier
end
local function findTV(prop,furnitureId)
    for _, item in ipairs(prop.furniture or {}) do
        if tostring(item.id)==tostring(furnitureId) and tonumber(item.stored)==0 and item.position
            and item.position.environment=='inside' and Config.HousingTV.Models and Config.HousingTV.Models[item.model] then return item end
    end
end
local function canControl(src,id,furnitureId)
    local prop,identifier=inside(src,id)
    if not prop or not (prop.renter==identifier or library.HasPermissions(id,identifier,Config.HousingTV.ControlPermission)) then return end
    local item=findTV(prop,furnitureId)
    local ped=GetPlayerPed(src)
    if not item or not ped or ped==0 then return end
    local a,b=GetEntityCoords(ped),item.position
    if not a or not b.x or not b.y or not b.z then return end
    local x,y,z=a.x-b.x,a.y-b.y,a.z-b.z
    local distance=math.max(1,math.min(tonumber(Config.HousingTV.MaxDistance) or 3.5,6))
    if x*x+y*y+z*z>distance*distance then return end
    return item
end
local function videoId(input)
    if type(input)~='string' or #input>512 then return end
    input=input:match('^%s*(.-)%s*$')
    local id
    if #input==11 and input:match('^[A-Za-z0-9_-]+$') then id=input end
    if not id then id=input:match('^https://youtu%.be/([A-Za-z0-9_-]+)[?&#/]?') end
    if not id then id=input:match('^https://www%.youtube%.com/watch%?v=([A-Za-z0-9_-]+)[&#]?') end
    if not id then id=input:match('^https://www%.youtube%.com/shorts/([A-Za-z0-9_-]+)[?&#/]?') end
    if not id then id=input:match('^https://www%.youtube%.com/embed/([A-Za-z0-9_-]+)[?&#/]?') end
    if id and #id==11 then return id end
end
local function snapshot(id)
    local state=playing[id]
    if not state then return {on=false} end
    local prop=GetProperty(id)
    if not prop or prop.owner~=state.owner or prop.renter~=state.renter or not findTV(prop,state.furniture) then
        playing[id]=nil; return {on=false}
    end
    return {on=true,video=state.video,elapsed=math.max(0,os.time()-state.started),furniture=state.furniture,version=state.version}
end
local function broadcast(id)
    local state=snapshot(id)
    for _, playerId in ipairs(GetPlayers()) do
        local src=tonumber(playerId)
        if src and inside(src,id) then TriggerClientEvent('vms_housing:tv:update',src,id,state) end
    end
end
library.RegisterCallback('vms_housing:tv:state',function(src,cb,rawId)
    local id=tostring(rawId or '')
    if not inside(src,id) then return cb({ok=false}) end
    cb({ok=true,state=snapshot(id)})
end)
RegisterNetEvent('vms_housing:tv:control',function(rawId,furnitureId,action,url)
    local src=source
    local id=tostring(rawId or '')
    if not canControl(src,id,furnitureId) then return end
    if action~='play' and action~='off' then return end
    local video=action=='play' and videoId(url)
    if action=='play' and not video then
        return library.Notification(src,'Use a valid YouTube video URL or ID.',4000,'error')
    end
    local now=os.time()
    if lastChange[src] and now-lastChange[src]<2 then return end
    lastChange[src]=now
    local prop=GetProperty(id)
    if action=='off' then playing[id]=nil else
        sequence=sequence+1
        playing[id]={video=video,started=now,furniture=furnitureId,owner=prop.owner,renter=prop.renter,version=sequence}
    end
    broadcast(id)
end)
AddEventHandler('playerDropped',function() lastChange[source]=nil end)

-- Stop a channel if its TV is removed or the property's occupants change.
CreateThread(function()
    while true do
        Wait(5000)
        for id in pairs(playing) do
            if not snapshot(id).on then broadcast(id) end
        end
    end
end)
