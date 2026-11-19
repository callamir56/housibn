

local clothesFields = {
    'tshirt_1', 'tshirt_2', 'torso_1', 'torso_2', 'decals_1', 'decals_2',
    'arms', 'arms_2', 'pants_1', 'pants_2', 'shoes_1', 'shoes_2',
    'mask_1', 'mask_2', 'bproof_1', 'bproof_2', 'chain_1', 'chain_2',
    'helmet_1', 'helmet_2', 'glasses_1', 'glasses_2', 'ears_1', 'ears_2',
    'watches_1', 'watches_2', 'bracelets_1', 'bracelets_2', 'bags_1', 'bags_2',
}
local pending = {}

local function characterIdentifier(src)
    local player = SV.GetPlayer(src)
    return player and SV.GetIdentifier(player)
end

local function cleanName(name)
    if type(name) ~= 'string' or #name > 160 then return nil end
    name = name:gsub('[%c<>]', ''):match('^%s*(.-)%s*$')
    local length = utf8.len(name)
    if not length or length < 1 or length > 40 then return nil end
    return name
end

local function clothingOnly(skin)
    if type(skin) ~= 'table' or (skin.sex ~= 0 and skin.sex ~= 1) then return nil end
    local clothes = {sex = skin.sex}
    for _, key in ipairs(clothesFields) do
        local value = skin[key]
        if value ~= nil then
            if type(value) ~= 'number' or value ~= value or value % 1 ~= 0 or value < -1 or value > 10000 then return nil end
            clothes[key] = value
        end
    end
    return clothes
end

library.RegisterCallback('vms_housing:wardrobe', function(src, cb, action, data)
    local identifier = characterIdentifier(src)
    if not identifier or pending[identifier] or not HousingDataReady then return cb({ok = false, reason = 'unavailable'}) end
    pending[identifier] = true
    local ok, result = pcall(function()
        if action == 'list' then
            local rows = MySQL.query.await('SELECT `slot`, `name`, `skin` FROM `housing_wardrobe_outfits` WHERE `identifier` = ? ORDER BY `slot`', {identifier})
            local outfits = {}
            for _, row in ipairs(rows or {}) do
                local decodedOk, skin = pcall(json.decode, row.skin)
                if decodedOk and type(skin) == 'table' then
                    outfits[#outfits + 1] = {slot = row.slot, name = row.name, skin = skin}
                end
            end
            return {ok = true, outfits = outfits}
        elseif action == 'save' then
            local name = type(data) == 'table' and cleanName(data.name)
            local clothes = type(data) == 'table' and clothingOnly(data.skin)
            if not name or not clothes then return {ok = false, reason = 'invalid'} end
            local rows = MySQL.query.await('SELECT `slot` FROM `housing_wardrobe_outfits` WHERE `identifier` = ?', {identifier})
            if not rows then return {ok = false, reason = 'database'} end
            local used = {}
            for _, row in ipairs(rows) do used[tonumber(row.slot)] = true end
            local slot
            for i = 1, 5 do if not used[i] then slot = i; break end end
            if not slot then return {ok = false, reason = 'full'} end
            local affected = MySQL.update.await('INSERT INTO `housing_wardrobe_outfits` (`identifier`, `slot`, `name`, `skin`) VALUES (?, ?, ?, ?)', {identifier, slot, name, json.encode(clothes)})
            if not affected or affected < 1 then return {ok = false, reason = 'database'} end
            return {ok = true}
        elseif action == 'delete' then
            local slot = type(data) == 'table' and tonumber(data.slot)
            if not slot or slot % 1 ~= 0 or slot < 1 or slot > 5 then return {ok = false, reason = 'invalid'} end
            local affected = MySQL.update.await('DELETE FROM `housing_wardrobe_outfits` WHERE `identifier` = ? AND `slot` = ?', {identifier, slot})
            return {ok = affected ~= nil and affected > 0, reason = 'missing'}
        end
        return {ok = false, reason = 'invalid'}
    end)
    pending[identifier] = nil
    if not ok then
        print(('[esx_realestate] Wardrobe database error: %s'):format(tostring(result)))
        return cb({ok = false, reason = 'database'})
    end
    cb(result)
end)
