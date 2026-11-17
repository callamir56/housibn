-- Agency copies require a fresh owner approval for every issuance.
local byOwner, byAgent, sequence = {}, {}, 0
local TIMEOUT = 30000
local function notify(src,msg,kind) TriggerClientEvent('vms_housing:notification',src,msg,5000,kind or 'info') end
local function nearHouse(src,prop)
    if GetPlayerRoutingBucket(src)~=0 then return false end
    local ped=GetPlayerPed(src)
    if not ped or ped==0 then return false end
    local pos=GetEntityCoords(ped)
    local function close(coords)
        if not coords or not coords.x or not coords.y or not coords.z then return false end
        local x,y,z=pos.x-coords.x,pos.y-coords.y,pos.z-coords.z
        return x*x+y*y+z*z<=25.0
    end
    local metadata=prop.metadata or {}
    if close(metadata.enter) or close(metadata.menu) then return true end
    local parent=prop.object_id and GetProperty(tostring(prop.object_id))
    return parent and parent.metadata and (close(parent.metadata.enter) or close(parent.metadata.menu)) or false
end
local function remove(request)
    if byOwner[request.owner]~=request then return false end
    byOwner[request.owner]=nil; byAgent[request.agent]=nil
    TriggerClientEvent('vms_housing:deedAgency:close',request.owner,request.id)
    return true
end
RegisterNetEvent('vms_housing:deedAgency:request',function(rawId)
    local src=source
    local player=SV.GetPlayer(src)
    if not player or SV.GetPlayerJob(player,'name')~=Config.DeedAgencyJob then return notify(src,'Access denied.','error') end
    local id=tostring(rawId or '')
    local property=HousingDataReady and GetProperty(id)
    if not property or not property.owner or not nearHouse(src,property) then return notify(src,'Property is unavailable or too far away.','error') end
    local signature=property.metadata and property.metadata.deedSignature
    if type(signature)~='table' or signature.owner~=property.owner then return notify(src,'The owner must sign the deed first.','error') end
    local owner=SV.GetPlayerByIdentifier(property.owner)
    local ownerSrc=owner and tonumber(SV.GetSource(owner))
    if not ownerSrc then return notify(src,'The owner must be online.','error') end
    if byOwner[ownerSrc] or byAgent[src] then return notify(src,'A request is already pending.','error') end
    sequence=sequence+1
    local request={id=sequence,agent=src,owner=ownerSrc,ownerIdentifier=property.owner,propertyId=id,expires=GetGameTimer()+TIMEOUT}
    byOwner[ownerSrc]=request;byAgent[src]=request
    TriggerClientEvent('vms_housing:deedAgency:prompt',ownerSrc,request.id,SV.GetCharacterName(player) or 'An agent',property.name or '',property.address or '',TIMEOUT)
    notify(src,'Copy request sent.')
    SetTimeout(TIMEOUT,function()
        if remove(request) then notify(src,'Copy request expired.','error') end
    end)
end)
RegisterNetEvent('vms_housing:deedAgency:answer',function(id,accepted)
    local src=source
    local request=byOwner[src]
    if not request or tonumber(id)~=request.id then return end
    if not remove(request) then return end
    if accepted~=true then return notify(request.agent,'Copy request declined.','error') end
    if GetGameTimer()>request.expires then return notify(request.agent,'Copy request expired.','error') end
    local owner=SV.GetPlayer(src);local agent=SV.GetPlayer(request.agent)
    local property=GetProperty(request.propertyId)
    if not owner or SV.GetIdentifier(owner)~=request.ownerIdentifier or not agent
        or SV.GetPlayerJob(agent,'name')~=Config.DeedAgencyJob or not property
        or property.owner~=request.ownerIdentifier or not nearHouse(request.agent,property) then
        return notify(request.agent,'Request no longer valid.','error')
    end
    local ok,msg=HousingDeedIssue(request.agent,request.propertyId,request.ownerIdentifier,'agency')
    notify(request.agent,msg,ok and 'success' or 'error')
    notify(src,ok and 'Deed copy approved.' or 'Could not issue the deed copy.',ok and 'success' or 'error')
end)
AddEventHandler('playerDropped',function()
    local src=source
    local request=byOwner[src] or byAgent[src]
    if request and remove(request) then
        if src~=request.agent then notify(request.agent,'Owner disconnected.','error') end
    end
end)
AddEventHandler('onResourceStop',function(name)
    if name==GetCurrentResourceName() then
        for _,request in pairs(byOwner) do remove(request) end
    end
end)
