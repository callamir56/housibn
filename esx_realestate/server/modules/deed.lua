-- Read and sign a deed using the current server-side owner; no client-supplied
-- names or property details are treated as evidence of ownership.
local pending = {}
local function resultFor(src, propertyId)
    if not HousingDataReady then return nil end
    local player = SV.GetPlayer(src)
    local identifier = player and SV.GetIdentifier(player)
    local property = GetProperty(propertyId)
    if not identifier or not property or property.owner ~= identifier then return nil end
    return property, identifier, player
end
local function deed(property, propertyId, identifier, player)
    local name = property.owner_name
    if (type(name) ~= 'string' or name == '') and player and SV.GetIdentifier(player) == identifier then name = SV.GetCharacterName(player) end
    if type(name) ~= 'string' or name == '' then name = 'Unknown owner' end
    local signature = property.metadata and property.metadata.deedSignature
    if type(signature) ~= 'table' or signature.owner ~= identifier then signature = nil end
    return {ok = true, id = propertyId, address = property.address or 'Not available',
        name = property.name or '', owner = name, issued = os.date('!%Y-%m-%d'),
        signature = signature and signature.name or nil, signedAt = signature and signature.date or nil,
        copyCount = HousingDeedCopyCount and HousingDeedCopyCount(property,propertyId) or nil}
end
library.RegisterCallback('vms_housing:deed', function(src, cb, action, propertyId)
    propertyId = tostring(propertyId or '')
    local property, identifier, player = resultFor(src, propertyId)
    if not property then return cb({ok=false, reason='Access denied.'}) end
    if action == 'view' then return cb(deed(property, propertyId, identifier, player)) end
    if action == 'item' then
        if not HousingDeedIssue then return cb({ok=false,reason='Deed unavailable.'}) end
        local ok,message=HousingDeedIssue(src,propertyId,identifier,'owner')
        local count=HousingDeedCopyCount(property,propertyId)
        return cb({ok=ok,reason=not ok and message or nil,message=ok and message or nil,copyCount=count})
    end
    if action ~= 'sign' or pending[propertyId] then return cb({ok=false, reason='Please try again.'}) end
    pending[propertyId] = true
    local ok, result = pcall(function()
        local current = property.metadata and property.metadata.deedSignature
        if type(current) == 'table' and current.owner == identifier then return deed(property, propertyId, identifier, player) end
        local name = property.owner_name
        if type(name) ~= 'string' or name == '' then name = SV.GetCharacterName(player) end
        if type(name) ~= 'string' or name == '' or #name > 160 then return {ok=false,reason='Owner name is unavailable.'} end
        local metadata = {}
        for k,v in pairs(property.metadata or {}) do metadata[k] = v end
        local signature = {owner=identifier, name=name, date=os.date('!%Y-%m-%d')}
        metadata.deedSignature = signature
        local affected = MySQL.update.await('UPDATE `houses` SET `metadata` = ? WHERE `id` = ? AND `owner` = ?', {json.encode(metadata), tonumber(propertyId), identifier})
        if not affected or affected < 1 then return {ok=false,reason='Ownership changed or deed could not be saved.'} end
        if property.owner ~= identifier then return {ok=false,reason='Ownership changed.'} end
        property.metadata = property.metadata or {}
        property.metadata.deedSignature = signature
        return deed(property, propertyId, identifier, player)
    end)
    pending[propertyId] = nil
    if not ok then print(('[esx_realestate] Deed error: %s'):format(tostring(result))); return cb({ok=false,reason='Deed unavailable.'}) end
    cb(result)
end)

-- Shared deed view is built only from server-held property data.
HousingDeedData = function(property, propertyId, identifier, player) return deed(property, propertyId, identifier, player) end
