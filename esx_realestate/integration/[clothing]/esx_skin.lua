if Config.Clothing ~= 'esx_skin' then return end

local active = false
local generation = 0
local outfits = {}

local function send(action, data)
    SendNUIMessage({action = 'Wardrobe', actionName = action, data = data})
end

local function message(reason)
    if reason == 'full' then return 'You can save up to five outfits.' end
    if reason == 'invalid' then return 'Please enter a valid name (1–40 characters).' end
    if reason == 'missing' then return 'This outfit no longer exists.' end
    return 'Wardrobe unavailable. Please check the server console.'
end

local function refresh()
    local session = generation
    library.Callback('vms_housing:wardrobe', function(result)
        if not active or session ~= generation then return end
        if not result or not result.ok then return send('Error', message(result and result.reason)) end
        outfits = {}
        local entries = {}
        for _, outfit in ipairs(result.outfits or {}) do
            outfits[tonumber(outfit.slot)] = outfit
            entries[#entries + 1] = {slot = outfit.slot, name = outfit.name}
        end
        send('Update', entries)
    end, 'list')
end

local function closeWardrobe()
    active = false
    generation = generation + 1
    outfits = {}
    send('Close')
    if openedMenu == 'Wardrobe' then
        openedMenu = nil
        SetNuiFocus(false, false)
    end
end

function OpenWardrobe()
    if GetResourceState('skinchanger') ~= 'started' or GetResourceState('esx_skin') ~= 'started' then
        return CL.Notification('The wardrobe requires esx_skin and skinchanger.', 5000, 'error')
    end
    if active or openedMenu then return end
    active = true
    generation = generation + 1
    openedMenu = 'Wardrobe'
    SetNuiFocus(true, true)
    send('Open')
    refresh()
end

CloseWardrobe = closeWardrobe

RegisterNUICallback('wardrobe:close', function(_, cb)
    closeWardrobe()
    cb({ok = true})
end)

RegisterNUICallback('wardrobe:save', function(data, cb)
    if not active or type(data) ~= 'table' or type(data.name) ~= 'string' then cb({ok = false}); return end
    local session = generation
    cb({ok = true})
    TriggerEvent('skinchanger:getSkin', function(skin)
        if not active or session ~= generation then return end
        if type(skin) ~= 'table' then return send('Error', 'Could not read your current outfit.') end
        library.Callback('vms_housing:wardrobe', function(result)
            if not active or session ~= generation then return end
            if not result or not result.ok then return send('Error', message(result and result.reason)) end
            send('Success', 'Outfit saved.')
            refresh()
        end, 'save', {name = data.name, skin = skin})
    end)
end)

RegisterNUICallback('wardrobe:wear', function(data, cb)
    local outfit = active and type(data) == 'table' and outfits[tonumber(data.slot)]
    if not outfit then cb({ok = false}); return end
    local session = generation
    cb({ok = true})
    TriggerEvent('skinchanger:getSkin', function(skin)
        if not active or session ~= generation then return end
        if type(skin) ~= 'table' or skin.sex ~= outfit.skin.sex then
            return send('Error', 'This outfit is not compatible with your current character model.')
        end
        TriggerEvent('skinchanger:loadClothes', skin, outfit.skin)
        send('Success', 'Outfit applied.')
    end)
end)

RegisterNUICallback('wardrobe:delete', function(data, cb)
    local outfit = active and type(data) == 'table' and outfits[tonumber(data.slot)]
    if not outfit then cb({ok = false}); return end
    local session = generation
    cb({ok = true})
    library.Callback('vms_housing:wardrobe', function(result)
        if not active or session ~= generation then return end
        if not result or not result.ok then return send('Error', message(result and result.reason)) end
        send('Success', 'Outfit deleted.')
        refresh()
    end, 'delete', {slot = outfit.slot})
end)
