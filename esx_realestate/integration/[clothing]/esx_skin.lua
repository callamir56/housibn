if Config.Clothing ~= 'esx_skin' then return end

local namespace = 'esx_realestate_wardrobe'
local showWardrobe
local function notice(message, kind)
    CL.Notification(message, 5000, kind or 'info')
end

local function failure(reason)
    if reason == 'full' then
        notice('حداکثر پنج لباس ذخیره می‌شود.', 'error')
    elseif reason == 'invalid' then
        notice('نام یا اطلاعات لباس معتبر نیست.', 'error')
    else
        notice('کمد در دسترس نیست؛ کنسول سرور را بررسی کنید.', 'error')
    end
end

local function openMenu(name, options, select, cancel)
    ESX.UI.Menu.Open('default', namespace, name, options, select, cancel or function(_, menu) menu.close() end)
end

local function saveCurrentOutfit()
    ESX.UI.Menu.Open('dialog', namespace, 'outfit_name', {title = 'نام لباس را وارد کنید'}, function(data, dialog)
        local name = data.value
        if type(name) ~= 'string' or not name:match('%S') then
            notice('یک نام برای لباس وارد کنید.', 'error')
            return
        end
        dialog.close()
        TriggerEvent('skinchanger:getSkin', function(skin)
            if type(skin) ~= 'table' then
                notice('دریافت لباس فعلی ممکن نیست.', 'error')
                return
            end
            library.Callback('vms_housing:wardrobe', function(result)
                if result and result.ok then
                    notice('لباس ذخیره شد.', 'success')
                else
                    failure(result and result.reason)
                end
                showWardrobe()
            end, 'save', {name = name, skin = skin})
        end)
    end, function(_, dialog)
        dialog.close()
        showWardrobe()
    end)
end

local function wearOutfit(outfit)
    TriggerEvent('skinchanger:getSkin', function(currentSkin)
        if type(currentSkin) ~= 'table' or currentSkin.sex ~= outfit.skin.sex then
            notice('این لباس با مدل شخصیت فعلی سازگار نیست.', 'error')
            return
        end
        TriggerEvent('skinchanger:loadClothes', currentSkin, outfit.skin)
        notice('لباس پوشیده شد.', 'success')
    end)
end

local function deleteOutfit(outfit)
    openMenu('delete_confirm', {
        title = 'حذف لباس ' .. outfit.name,
        align = 'top-left',
        elements = {{label = 'بله، حذف شود', value = true}, {label = 'انصراف', value = false}},
    }, function(data, menu)
        menu.close()
        if not data.current.value then return showWardrobe() end
        library.Callback('vms_housing:wardrobe', function(result)
            if result and result.ok then notice('لباس حذف شد.', 'success') else failure(result and result.reason) end
            showWardrobe()
        end, 'delete', {slot = outfit.slot})
    end, function(_, menu) menu.close(); showWardrobe() end)
end

local function outfitActions(outfit)
    openMenu('outfit_actions', {
        title = outfit.name,
        align = 'top-left',
        elements = {{label = 'پوشیدن', value = 'wear'}, {label = 'حذف', value = 'delete'}, {label = 'بازگشت', value = 'back'}},
    }, function(data, menu)
        menu.close()
        if data.current.value == 'wear' then wearOutfit(outfit); showWardrobe()
        elseif data.current.value == 'delete' then deleteOutfit(outfit)
        else showWardrobe() end
    end, function(_, menu) menu.close(); showWardrobe() end)
end

showWardrobe = function()
    library.Callback('vms_housing:wardrobe', function(result)
        if not result or not result.ok then return failure(result and result.reason) end
        local outfits = result.outfits or {}
        local elements = {}
        if #outfits < 5 then
            elements[#elements + 1] = {label = ('ذخیره لباس فعلی (%d/5)'):format(#outfits), value = 'save'}
        else
            elements[#elements + 1] = {label = 'ظرفیت کمد پر است (5/5)', value = 'full'}
        end
        for _, outfit in ipairs(outfits) do
            elements[#elements + 1] = {label = outfit.name, outfit = outfit}
        end
        openMenu('outfits', {title = 'کمد لباس', align = 'top-left', elements = elements}, function(data, menu)
            menu.close()
            if data.current.value == 'save' then saveCurrentOutfit()
            elseif data.current.outfit then outfitActions(data.current.outfit)
            else notice('برای ذخیره لباس جدید، ابتدا یک لباس را حذف کنید.', 'error'); showWardrobe() end
        end)
    end, 'list')
end

function OpenWardrobe()
    if GetResourceState('skinchanger') ~= 'started' or GetResourceState('esx_skin') ~= 'started' then
        return notice('برای کمد لباس، esx_skin و skinchanger باید روشن باشند.', 'error')
    end
    if GetResourceState('esx_menu_default') ~= 'started' or GetResourceState('esx_menu_dialog') ~= 'started' or not (ESX and ESX.UI and ESX.UI.Menu) then
        return notice('برای کمد لباس، esx_menu_default و esx_menu_dialog را اجرا کنید.', 'error')
    end
    ESX.UI.Menu.CloseAll()
    showWardrobe()
end
