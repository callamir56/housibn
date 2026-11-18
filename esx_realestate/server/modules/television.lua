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
-- Only media URLs we can safely canonicalize are accepted. Arbitrary websites
-- are not embedded as privileged NUI pages.
local function parseMedia(input)
    if type(input)~='string' or #input>2048 then return end
    input=input:match('^%s*(.-)%s*$')
    if input:find('[%c%s\\]') then return end
    if #input==11 and input:match('^[A-Za-z0-9_-]+$') then return {provider='youtube',video=input} end
    local authority,rest=input:match('^https://([^/?#]+)(.*)$')
    if not authority then return end
    local host=authority:lower()
    if #host>253 or not host:match('^[a-z0-9%.%-]+$') or not host:find('%.')
        or host:find('%.%.',1,false) or host:match('^%.') or host:match('%.$')
        or host:match('%.local$') or host:match('%.localhost$') or host:match('%.internal$')
        or host:match('^[0-9%.]+$') then return end
    local youtube=host=='youtube.com' or host=='www.youtube.com' or host=='m.youtube.com'
    if youtube or host=='youtu.be' then
        local id
        if host=='youtu.be' then id=rest:match('^/([A-Za-z0-9_-]+)')
        else
            id=rest:match('^/shorts/([A-Za-z0-9_-]+)') or rest:match('^/embed/([A-Za-z0-9_-]+)')
            if not id and rest:match('^/watch%?') then id=rest:match('[?&]v=([A-Za-z0-9_-]+)') end
        end
        if id and #id==11 then return {provider='youtube',video=id} end
        return
    end
    if host=='vimeo.com' or host=='www.vimeo.com' or host=='player.vimeo.com' then
        local id = rest:match('^/(%d+)') or rest:match('^/video/(%d+)')
        if id and #id>=1 and #id<=20 then return {provider='vimeo',video=id} end
        return
    end
    if host=='aparat.com' or host=='www.aparat.com' then
        local hash=rest:match('^/v/([A-Za-z0-9_-]+)') or rest:match('^/embed/([A-Za-z0-9_-]+)')
            or rest:match('^/video/video/embed/videohash/([A-Za-z0-9_-]+)')
        if hash and #hash>=4 and #hash<=32 then return {provider='aparat',video=hash} end
        return
    end
    local path=rest:match('^([^?#]*)') or ''
    local extension=path:lower():match('%.([a-z0-9]+)$')
    if extension=='mp4' or extension=='webm' or extension=='ogv' then
        local allowed=Config.HousingTV.DirectAllowedHosts
        if allowed ~= nil and (type(allowed)~='table' or allowed[host]~=true) then return end
        return {provider='direct',video=input}
    end
end

local function snapshot(id)
    local state=playing[id]
    if not state then return {on=false} end
    local prop=GetProperty(id)
    if not prop or prop.owner~=state.owner or prop.renter~=state.renter or not findTV(prop,state.furniture) then
        playing[id]=nil; return {on=false}
    end
    return {on=true,provider=state.provider,video=state.video,elapsed=math.max(0,os.time()-state.started),furniture=state.furniture,version=state.version}
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
local function control(src,rawId,furnitureId,action,url)
    local id=tostring(rawId or '')
    if not canControl(src,id,furnitureId) then
        return {ok=false,reason='Access denied. Go near your TV and check your house permissions.'}
    end
    if action~='play' and action~='off' then return {ok=false,reason='Invalid action.'} end
    local media=action=='play' and parseMedia(url)
    if action=='play' and not media then
        return {ok=false,reason='Use YouTube, Aparat, Vimeo or a direct HTTPS MP4, WebM or OGV link.'}
    end
    local now=os.time()
    if lastChange[src] and now-lastChange[src]<2 then return {ok=false,reason='Please wait before changing the video.'} end
    lastChange[src]=now
    local prop=GetProperty(id)
    if action=='off' then playing[id]=nil else
        sequence=sequence+1
        playing[id]={provider=media.provider,video=media.video,started=now,furniture=furnitureId,owner=prop.owner,renter=prop.renter,version=sequence}
    end
    broadcast(id)
    return {ok=true}
end
library.RegisterCallback('vms_housing:tv:play',function(src,cb,rawId,furnitureId,url)
    cb(control(src,rawId,furnitureId,'play',url))
end)
RegisterNetEvent('vms_housing:tv:control',function(rawId,furnitureId,action,url)
    local src=source
    local result=control(src,rawId,furnitureId,action,url)
    if not result.ok then library.Notification(src,result.reason,5000,'error') end
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
