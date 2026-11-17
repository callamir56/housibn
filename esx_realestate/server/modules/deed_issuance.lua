-- Each signed ownership period receives a revision. Owner slots 1 and 2 are
-- unique in the database; agency slots are NULL and do not consume the limit.
local locks = {}
local function newRevision()
    return ('%x-%08x-%08x'):format(os.time(), math.random(0,0x7fffffff), math.random(0,0x7fffffff))
end
local function signature(property)
    local s=property.metadata and property.metadata.deedSignature
    if type(s)~='table' or s.owner~=property.owner or type(s.name)~='string' then return nil end
    return s
end
local function ensureRevision(property,id)
    local sign=signature(property)
    if not sign then return nil,'Owner must sign the deed first.' end
    if sign.revision then return sign.revision end
    local copy={}; for k,v in pairs(property.metadata or {}) do copy[k]=v end
    local newSign={}; for k,v in pairs(sign) do newSign[k]=v end
    newSign.revision=newRevision(); copy.deedSignature=newSign
    local changed=MySQL.update.await('UPDATE `houses` SET `metadata` = ? WHERE `id` = ? AND `owner` = ?', {json.encode(copy),tonumber(id),property.owner})
    if not changed or changed~=1 or signature(property)~=sign then return nil,'Could not prepare deed.' end
    property.metadata.deedSignature=newSign
    return newSign.revision
end
local function rowCount(property,id)
    local sign=signature(property)
    if not sign then return 0 end
    if not sign.revision then return 0 end
    local rows=MySQL.query.await('SELECT `owner_slot` FROM `housing_deed_issuances` WHERE `property_id` = ? AND `revision` = ? AND `owner_slot` IS NOT NULL',{tonumber(id),sign.revision})
    if not rows then error('issuance count query failed') end
    return #rows
end
HousingDeedCopyCount=function(property,id)
    local ok,count=pcall(rowCount,property,id)
    return ok and count or nil
end
HousingDeedIssue=function(src, propertyId, expectedOwner, kind)
    propertyId=tostring(propertyId or '')
    if kind~='owner' and kind~='agency' then return false,'Invalid request.' end
    if locks[propertyId] then return false,'Please wait.' end
    locks[propertyId]=true
    local ok, success, reason=pcall(function()
        if Config.Inventory~='ox_inventory' or GetResourceState('ox_inventory')~='started' then return false,'ox_inventory is unavailable.' end
        local player=SV.GetPlayer(src); local holder=player and SV.GetIdentifier(player)
        local property=GetProperty(propertyId)
        if not holder or not property or property.owner~=expectedOwner then return false,'Ownership changed.' end
        if kind=='owner' and holder~=property.owner then return false,'Access denied.' end
        if kind=='agency' and SV.GetPlayerJob(player,'name')~=Config.DeedAgencyJob then return false,'Access denied.' end
        local revision,err=ensureRevision(property,propertyId)
        if not revision then return false,err end
        local slot
        if kind=='owner' then
            local rows=MySQL.query.await('SELECT `owner_slot` FROM `housing_deed_issuances` WHERE `property_id` = ? AND `revision` = ? AND `owner_slot` IS NOT NULL',{tonumber(propertyId),revision})
            if not rows then return false,'Deed unavailable.' end
            local used={};for _,r in ipairs(rows) do used[tonumber(r.owner_slot)]=true end
            if not used[1] then slot=1 elseif not used[2] then slot=2 else return false,'Copy limit reached.' end
        end
        if property.owner~=expectedOwner or not signature(property) or signature(property).revision~=revision then return false,'Ownership changed.' end
        local issuance
        if slot then
            issuance=MySQL.insert.await('INSERT INTO `housing_deed_issuances` (`property_id`,`revision`,`owner`,`holder`,`kind`,`owner_slot`) VALUES (?, ?, ?, ?, ?, ?)',{tonumber(propertyId),revision,expectedOwner,holder,kind,slot})
        else
            issuance=MySQL.insert.await('INSERT INTO `housing_deed_issuances` (`property_id`,`revision`,`owner`,`holder`,`kind`) VALUES (?, ?, ?, ?, ?)',{tonumber(propertyId),revision,expectedOwner,holder,kind})
        end
        if not issuance then return false,'Could not create deed.' end
        local currentPlayer=SV.GetPlayer(src)
        if not currentPlayer or SV.GetIdentifier(currentPlayer)~=holder
            or (kind=='agency' and SV.GetPlayerJob(currentPlayer,'name')~=Config.DeedAgencyJob)
            or property.owner~=expectedOwner or not signature(property) or signature(property).revision~=revision then
            MySQL.update.await('DELETE FROM `housing_deed_issuances` WHERE `id` = ?', {issuance})
            return false,'Request is no longer valid.'
        end
        -- Fail closed: a failed/crashed delivery can leave a reserved slot;
        -- a failed delivery is rolled back if the database is available.
        local metadata={propertyId=propertyId,owner=expectedOwner,holder=holder,revision=revision,issuanceId=issuance,
            description=kind=='agency' and 'Agency copy' or (slot==1 and 'Original deed' or 'Deed copy')}
        local addOk,added=pcall(function() return exports.ox_inventory:AddItem(src,'property_deed',1,metadata) end)
        if not addOk or not added then
            local rollbackOk,rollbackErr=pcall(MySQL.update.await,'DELETE FROM `housing_deed_issuances` WHERE `id` = ?', {issuance})
            if not rollbackOk then print(('[esx_realestate] Deed reservation rollback failed: %s'):format(tostring(rollbackErr))) end
            return false,'Inventory full or deed item is not installed.'
        end
        return true, kind=='agency' and 'Agency copy issued.' or (slot==1 and 'Original deed issued.' or 'Copy issued.')
    end)
    locks[propertyId]=nil
    if not ok then print(('[esx_realestate] Deed issuance failed: %s'):format(tostring(success))); return false,'Deed unavailable.' end
    return success,reason
end
HousingDeedValidateItem=function(src,data)
    if not data or not HousingDataReady or Config.Inventory~='ox_inventory' or GetResourceState('ox_inventory')~='started' then return end
    local player=SV.GetPlayer(src); local holder=player and SV.GetIdentifier(player)
    local property=GetProperty(data.propertyId)
    if not holder or not property or not property.owner then return end
    local ok,item=pcall(function() return exports.ox_inventory:GetSlot(src,data.slot) end)
    if not ok or type(item)~='table' or item.name~='property_deed' or type(item.metadata)~='table' then return end
    local m=item.metadata; local sign=signature(property)
    if not sign or not sign.revision or tostring(m.propertyId or '')~=data.propertyId or m.owner~=property.owner
        or m.holder~=holder or m.revision~=sign.revision or not tonumber(m.issuanceId) then return end
    local found,rows=pcall(MySQL.query.await,'SELECT `id` FROM `housing_deed_issuances` WHERE `id` = ? AND `property_id` = ? AND `revision` = ? AND `owner` = ? AND `holder` = ? LIMIT 1', {tonumber(m.issuanceId),tonumber(data.propertyId),sign.revision,property.owner,holder})
    if not found or not rows or #rows~=1 then return end
    return property,property.owner,player
end
