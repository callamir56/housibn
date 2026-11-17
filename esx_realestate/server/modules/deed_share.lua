-- ox_inventory's server-side usedItem event is emitted only after a genuine use.
-- The item is a pointer, not proof of ownership: ownership and proximity are
-- verified again when the target is selected.
local pending, sessions, participant, nextSession = {}, {}, {}, 0
local MAX_DISTANCE = 3.0
local function notify(src, text) library.Notification(src, text, 5000, 'error') end
local function nearby(src, target)
    if not target or src == target or GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then return false end
    local a,b=GetPlayerPed(src),GetPlayerPed(target)
    if not a or a==0 or not b or b==0 then return false end
    local x,y=GetEntityCoords(a),GetEntityCoords(b)
    local dx,dy,dz=x.x-y.x,x.y-y.y,x.z-y.z
    return dx*dx+dy*dy+dz*dz<=MAX_DISTANCE*MAX_DISTANCE
end
local function ownerWithItem(src, data)
    if not HousingDeedValidateItem then return end
    return HousingDeedValidateItem(src, data)
end
local function finishOwner(owner)
    local session=sessions[owner]
    if not session then return end
    sessions[owner]=nil; participant[owner]=nil
    if session.target then
        participant[session.target]=nil
        TriggerClientEvent('vms_housing:deedShare:close',session.target,session.id)
    end
    TriggerClientEvent('vms_housing:deedShare:close',owner,session.id)
end
local function begin(src, target)
    local selection=pending[src]
    if not selection or GetGameTimer()>selection.expires then pending[src]=nil; return false,'Use the deed again.' end
    local property,identifier,player=ownerWithItem(src,selection)
    if not property then pending[src]=nil; return false,'Deed is no longer valid.' end
    if target and (not nearby(src,target) or not SV.GetPlayer(target)) then return false,'Player is no longer nearby.' end
    if participant[src] or (target and participant[target]) then return false,'Player is busy.' end
    nextSession=nextSession+1
    local session={id=nextSession,owner=src,target=target,propertyId=selection.propertyId,slot=selection.slot}
    sessions[src]=session; participant[src]=src; if target then participant[target]=src end; pending[src]=nil
    local data=HousingDeedData(property,selection.propertyId,identifier,player)
    TriggerClientEvent('vms_housing:deedShare:show',src,session.id,'owner',data,target)
    if target then TriggerClientEvent('vms_housing:deedShare:show',target,session.id,'viewer',data,src) end
    return true
end
AddEventHandler('ox_inventory:usedItem', function(src,itemName,slot,metadata)
    src=tonumber(src)
    if itemName~='property_deed' or not src or type(metadata)~='table' or not tonumber(slot) then return end
    local propertyId=tostring(metadata.propertyId or '')
    local selection={propertyId=propertyId,slot=tonumber(slot),expires=GetGameTimer()+60000}
    local property=ownerWithItem(src,selection)
    if not property then return notify(src,'This deed is not valid for your character.') end
    if participant[src] then return notify(src,'Close the current deed first.') end
    local players={}
    for _,raw in ipairs(GetPlayers()) do
        local target=tonumber(raw)
        if target and nearby(src,target) and not participant[target] then
            local player=SV.GetPlayer(target)
            if player then players[#players+1]={id=target,name=SV.GetCharacterName(player) or ('Player '..target)} end
        end
    end
    table.sort(players,function(a,b) return a.id<b.id end)
    pending[src]=selection
    if #players==0 then
        local ok,reason=begin(src,nil)
        if not ok then notify(src,reason) end
    elseif #players==1 then
        local ok,reason=begin(src,players[1].id)
        if not ok then notify(src,reason) end
    else
        TriggerClientEvent('vms_housing:deedShare:select',src,players)
    end
end)
library.RegisterCallback('vms_housing:deedShare:choose',function(src,cb,target)
    target=tonumber(target)
    if not target or target%1~=0 or target<1 then return cb({ok=false,reason='Invalid player.'}) end
    local ok,reason=begin(src,target)
    cb({ok=ok,reason=reason})
end)
RegisterNetEvent('vms_housing:deedShare:cancelSelect',function() pending[source]=nil end)
RegisterNetEvent('vms_housing:deedShare:close',function(id)
    local src=source
    local owner=participant[src]
    local session=owner and sessions[owner]
    if not session or tonumber(id)~=session.id then return end
    if src==owner then
        finishOwner(owner)
    elseif src==session.target then
        participant[src]=nil; session.target=nil
        TriggerClientEvent('vms_housing:deedShare:close',src,session.id)
    end
end)
AddEventHandler('playerDropped',function()
    local src=source; pending[src]=nil
    local owner=participant[src]
    local session=owner and sessions[owner]
    if not session then return end
    if src==owner then finishOwner(owner) else participant[src]=nil; session.target=nil end
end)
AddEventHandler('onResourceStop',function(resource)
    if resource~=GetCurrentResourceName() then return end
    for owner in pairs(sessions) do finishOwner(owner) end
end)

-- Revoke an open display if the item disappears or the house changes owner.
CreateThread(function()
    while true do
        Wait(3000)
        for owner,session in pairs(sessions) do
            if not ownerWithItem(owner, session) then finishOwner(owner) end
        end
    end
end)
