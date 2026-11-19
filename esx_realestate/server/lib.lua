















local hasWarnedMissingInventory = false


library = library or {}







function library.Debug(message, level)
    if not Config.Debug then
        return
    end

    if level == "error" then
        error(message)
    elseif level == "warn" then
        warn(message)
    else
        print(message)
    end
end


function library.Dump(value)
    return json.encode(value, { indent = true })
end


function library.Round(value, decimals)
    decimals = decimals or 0
    local multiplier = 10 ^ decimals
    return math.floor(value * multiplier + 0.5) / multiplier
end






function library.Notification(playerSrc, title, message, notifType)
    TriggerClientEvent("vms_housing:notification", playerSrc, title, message, notifType)
end







function library.RegisterCallback(name, cb, ...)
    if Config.Core == "ESX" then
        Core.RegisterServerCallback(name, cb, ...)
    elseif Config.Core == "QB-Core" then
        Core.Functions.CreateCallback(name, cb, ...)
    end
end






function library.HasCreatorPermissions(player)
    if not player or not Config.HousingCreator then return false end

    local settings = Config.HousingCreator
    if Config.Core == "ESX" and player.getGroup then
        local group = player.getGroup()
        if settings.AllowedGroups and settings.AllowedGroups[group] then return true end
    end

    return not settings.RequiredJob or SV.GetPlayerJob(player, "name") == settings.RequiredJob
end

library.RegisterCallback("vms_housing:canOpenCreator", function(source, cb)
    cb(library.HasCreatorPermissions(SV.GetPlayer(source)))
end)





function library.DrawChance(chancePercent)
    if not chancePercent or not tonumber(chancePercent) then
        return false
    end

    local roll = math.random() * 100
    return chancePercent > roll
end








function library.HasKeys(playerSrc, identifier, propertyId, keySerialMaybe)
    local property = Properties[propertyId]
    if not property then
        return false
    end


    if Config.UseKeysOnItem then
        local player = SV.GetPlayer(playerSrc)


        if keySerialMaybe then

            local serialPropertyId, serialPart = string.match(keySerialMaybe, "^(.-)%-(.+)$")
            if tostring(propertyId) ~= tostring(serialPropertyId) then
                return false
            end


            if string.find(property.keys, serialPart) then

                local hasItem = SV.GetItem(
                    playerSrc,
                    player,
                    "house_key",
                    { keySerialNumber = keySerialMaybe },
                    "key"
                )
                if hasItem then
                    return true
                end
            end

        else

            local keyList = json.decode(property.keys)

            for i = 1, #keyList do
                local serial = keyList[i]


                local hasItem = SV.GetItem(
                    playerSrc,
                    player,
                    "house_key",
                    { keySerialNumber = serial },
                    "key"
                )
                if hasItem then
                    return true
                end
            end
        end

        return false
    end


    if property.owner == identifier then
        return true
    end
    if property.renter == identifier then
        return true
    end
    if property.keys and string.find(property.keys, identifier) then
        return true
    end

    return false
end






function library.GenerateKeySerialNumber(propertyId)
    if not Config.UseKeysOnItem then
        return
    end


    local function randomLetter()
        local letters = {
            "A","B","C","D","E","F","G","H","I","J","K","L","M",
            "N","O","P","Q","R","S","T","U","V","W","X","Y","Z"
        }
        return letters[math.random(#letters)]
    end


    local serial = tostring(propertyId)
        .. "-"
        .. tostring(math.random(1000, 9999))
        .. randomLetter() .. randomLetter() .. randomLetter()
        .. tostring(math.random(100, 999))


    local encodedKeys = json.encode(Properties[propertyId].keys)
    if string.find(encodedKeys, serial) then
        return library.GenerateKeySerialNumber(propertyId)
    end

    return serial
end





function library.RegisterStorage(storageData)
    if RegisterStorage then
        RegisterStorage(storageData)
        return
    end

    if not hasWarnedMissingInventory then
        hasWarnedMissingInventory = true
        warn("Compatible Inventory is missing!")
        print("Adjust it on ^5vms_housing/integration/[inventory]^7")
    end
end








function library.HandleLightStateMonthOverlap(propertyId)
    if not Config.UseServiceBills then
        return
    end

    local property = GetProperty(propertyId)
    if not property then
        return
    end

    local metadata = property.metadata or {}
    if not (metadata.lightState and metadata.lightStartTime) then
        return
    end

    local now = os.time()
    local lightStart = metadata.lightStartTime


    local nowMonth  = tonumber(os.date("%m", now))
    local nowYear   = tonumber(os.date("%Y", now))
    local startMonth = tonumber(os.date("%m", lightStart))
    local startYear  = tonumber(os.date("%Y", lightStart))


    if nowMonth == startMonth and nowYear == startYear then
        return
    end


    local startOfCurrentMonth = os.time({
        day = 1, month = nowMonth, year = nowYear,
        hour = 0, min = 0, sec = 0
    })


    if lightStart >= startOfCurrentMonth then
        return
    end

    local overlapSeconds = startOfCurrentMonth - lightStart
    if overlapSeconds <= 0 then
        return
    end


    local prevMonth = nowMonth - 1
    local prevYear = nowYear
    if prevMonth <= 0 then
        prevMonth = 12
        prevYear = prevYear - 1
    end
    local prevPeriod = string.format("%02d:%04d", prevMonth, prevYear)


    local bills = property.bills or {}
    local prevServicesBill = nil
    for i = 1, #bills do
        local bill = bills[i]
        if bill.period == prevPeriod and bill.type == "services" then
            prevServicesBill = bill
            break
        end
    end



    metadata.lightStartTime = startOfCurrentMonth
    if prevServicesBill and prevServicesBill.paid ~= true and tonumber(prevServicesBill.paid) ~= 1 then
        local details = json.decode(prevServicesBill.details or "{}")

        local regionCfg = Config.Regions[property.region] or Config.NoRegion


        details.electricityUsage = (details.electricityUsage or 0) + overlapSeconds
        details.electricity      = (details.electricity or 0) + (overlapSeconds * regionCfg.electricity.rate)


        local electricity = details.electricity or 0
        local water       = details.water or 0
        local internet    = details.internet or 0
        prevServicesBill.total = electricity + water + internet

        prevServicesBill.details = json.encode(details)


        MySQL.update.await(
            "UPDATE houses_bills SET details = ?, total = ? WHERE id = ? AND type = ?",
            { json.encode(details), prevServicesBill.total, prevServicesBill.id, "services" }
        )
    end

end








function library.GenerateMonthlyBill(propertyId, period)
    if not Config.UseServiceBills then
        return
    end

    local property = GetProperty(propertyId)
    if not property or not (property.owner or property.renter) then
        return nil
    end

    local metadata = property.metadata or {}
    local waterUsage = metadata.waterUsage or 0

    local regionCfg = Config.Regions[property.region] or Config.NoRegion

    local baseElectricity = 0
    local waterCost = waterUsage * regionCfg.water.rate
    local internetCost = regionCfg.internet.flatRate
    local total = baseElectricity + waterCost + internetCost

    local detailsTable = {
        electricityUsage = 0,
        electricity      = baseElectricity,
        waterUsage       = waterUsage,
        water            = waterCost,
        internet         = internetCost,
        rateInfo         = {
            electricity = library.Round(regionCfg.electricity.rate, 5),
            water       = library.Round(regionCfg.water.rate, 5),
            internet    = library.Round(regionCfg.internet.flatRate, 5),
        }
    }
    local detailsJson = json.encode(detailsTable)


    local ok, insertId = pcall(function()
        return MySQL.insert.await([[
            INSERT INTO houses_bills (house_id, period, type, total, paid, details)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], { tonumber(propertyId), period, "services", total, 0, detailsJson })
    end)

    if ok and insertId then

        metadata.waterUsage = 0

        return {
            id      = insertId,
            house_id = propertyId,
            period  = period,
            type    = "services",
            total   = total,
            paid    = 0,
            paid_at = nil,
            details = detailsJson,
        }
    end


    return MySQL.single.await([[
        SELECT * FROM houses_bills WHERE house_id = ? AND period = ? AND type = ?
    ]], { tonumber(propertyId), period, "services" })
end








function library.GenerateRentBill(propertyId, period, paidFlag)
    local property = GetProperty(propertyId)
    if not (property and property.renter) then
        return nil
    end

    local rentPrice = (property.rental and property.rental.price) or 0
    if rentPrice <= 0 then
        return nil
    end

    local detailsJson = json.encode({ rent = rentPrice })

    local ok, insertId = pcall(function()
        return MySQL.insert.await([[
            INSERT INTO houses_bills (house_id, period, type, total, paid, details)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {
            tonumber(propertyId),
            period,
            "rent",
            rentPrice,
            (paidFlag and 1 or 0),
            detailsJson
        })
    end)

    if ok and insertId then
        return {
            id      = insertId,
            house_id = propertyId,
            period  = period,
            type    = "rent",
            total   = rentPrice,
            paid    = (paidFlag and 1 or 0),
            paid_at = (paidFlag and os.time() or nil),
            details = detailsJson,
        }
    end

    return MySQL.single.await([[
        SELECT * FROM houses_bills WHERE house_id = ? AND period = ? AND type = ?
    ]], { tonumber(propertyId), period, "rent" })
end






function library.RefreshUtilityDebt(property, now)
    if not property then return 0 end
    local date = os.date("*t", now or os.time())
    local current = date.year * 12 + date.month
    local count = 0
    if Config.UseServiceBills then
        for _, bill in ipairs(property.bills or {}) do
            local month, year = tostring(bill.period or ""):match("^(%d%d):(%d%d%d%d)$")
            month, year = tonumber(month), tonumber(year)
            if bill.type == "services" and bill.paid ~= true and tonumber(bill.paid) ~= 1
                and month and month >= 1 and month <= 12 and year * 12 + month < current then
                count = count + 1
            end
        end
    end
    property.unpaidBills = count
    return count
end

function library.UtilityEntryBlocked(property, now)
    local cfg = Config.UtilityAccess or {}
    local count = library.RefreshUtilityDebt(property, now)
    local threshold = math.max(1, math.floor(tonumber(cfg.OverdueBillsToBlock) or 2))
    return Config.UseServiceBills and cfg.BlockEntry == true and count >= threshold, count
end

function library.GetOrCreateBills(propertyId, paidRentFlag)
    local property = GetProperty(propertyId)
    if not property then
        return {}
    end


    library.HandleLightStateMonthOverlap(propertyId)

    local currentMonthPeriod = os.date("%m:%Y")
    local weeklyPeriod = GetWeekPeriod()


    local rentPeriod = currentMonthPeriod
    if property.rental and property.rental.cycle == "weekly" and weeklyPeriod then
        rentPeriod = weeklyPeriod
    end

    local hasServices = false
    local hasRent = false

    for _, bill in ipairs(property.bills or {}) do
        if bill.period == currentMonthPeriod and bill.type == "services" then
            hasServices = true
        end
        if bill.period == rentPeriod and bill.type == "rent" and property.renter then
            hasRent = true
        end
    end

    if not hasServices then
        local newServices = library.GenerateMonthlyBill(propertyId, currentMonthPeriod)
        if newServices then
            local exists = false
            for _, existing in ipairs(property.bills) do
                if existing.id == newServices.id then exists = true; break end
            end
            if not exists then table.insert(property.bills, 1, newServices) end



            if newServices.period ~= currentMonthPeriod then
                property.unpaidBills = (property.unpaidBills or 0) + 1
            end
        end
    end

    if not hasRent then
        local newRent = library.GenerateRentBill(propertyId, rentPeriod, paidRentFlag)
        if newRent then
            table.insert(property.bills, 1, newRent)
            if not paidRentFlag then
                property.unpaidRentBills = (property.unpaidRentBills or 0) + 1
            end
        end
    end

    library.RefreshUtilityDebt(property)
    return property.bills
end








function library.ApplyCurrentLightUsage(propertyId, newLightStartTime, shouldPersistPropertyMeta)
    if not Config.UseServiceBills then
        return
    end

    local property = GetProperty(propertyId)
    if not property then
        return false
    end

    if not (property.metadata and property.metadata.lightState and property.metadata.lightStartTime) then
        return false
    end

    local now = os.time()
    local previousStart = property.metadata.lightStartTime
    local secondsUsed = now - previousStart
    if secondsUsed <= 0 then
        return false
    end

    local period = os.date("%m:%Y", now)
    local regionCfg = Config.Regions[property.region] or Config.NoRegion
    local electricityRate = regionCfg.electricity.rate


    local servicesBill = nil
    for _, bill in ipairs(property.bills or {}) do
        if bill.period == period and bill.type == "services" then
            servicesBill = bill
            break
        end
    end

    if not servicesBill then
        servicesBill = library.GenerateMonthlyBill(propertyId, period)
        table.insert(property.bills, 1, servicesBill)
    end

    local details = json.decode(servicesBill.details or "{}")

    details.electricityUsage = (details.electricityUsage or 0) + secondsUsed
    details.electricity = library.Round((details.electricity or 0) + (secondsUsed * electricityRate), 6)


    local electricity = library.Round(details.electricity or 0, 3)
    local water       = library.Round(details.water or 0, 3)
    local internet    = library.Round(details.internet or 0, 3)
    servicesBill.total = electricity + water + internet

    servicesBill.details = json.encode(details)


    MySQL.update.await(
        "UPDATE houses_bills SET details = ?, total = ? WHERE id = ? AND type = ?",
        { servicesBill.details, servicesBill.total, servicesBill.id, "services" }
    )


    property.metadata.lightStartTime = newLightStartTime

    if shouldPersistPropertyMeta then

        MySQL.update.await(
            "UPDATE houses SET metadata = ? WHERE id = ?",
            { json.encode(property.metadata), tonumber(propertyId) }
        )
    end

    return true
end







function library.ApplyWaterUsage(propertyId, rawUsage)
    if not Config.UseServiceBills then
        return
    end

    local property = GetProperty(propertyId)
    if not property then
        return false
    end

    if not rawUsage or rawUsage <= 0 then
        return false
    end

    local now = os.time()
    local period = os.date("%m:%Y", now)

    local regionCfg = Config.Regions[property.region] or Config.NoRegion
    local waterRate = regionCfg.water.rate


    local billForPeriod = nil
    for _, bill in ipairs(property.bills or {}) do
        if bill.period == period then
            billForPeriod = bill
            break
        end
    end

    if not billForPeriod then
        billForPeriod = library.GenerateMonthlyBill(propertyId, period)
        table.insert(property.bills, 1, billForPeriod)
    end

    local details = json.decode(billForPeriod.details or "{}")

    local usage = rawUsage / 1000
    details.waterUsage = (details.waterUsage or 0) + usage
    details.water = library.Round((details.water or 0) + (usage * waterRate), 6)

    local electricity = library.Round(details.electricity or 0, 3)
    local water       = library.Round(details.water or 0, 3)
    local internet    = library.Round(details.internet or 0, 3)
    billForPeriod.total = electricity + water + internet

    billForPeriod.details = json.encode(details)


    MySQL.update.await(
        "UPDATE houses_bills SET details = ?, total = ? WHERE id = ? AND type = ?",
        { billForPeriod.details, billForPeriod.total, billForPeriod.id, "services" }
    )

    return true
end






function library.HasPermissions(propertyId, identifier, permissionKey)
    local property = GetProperty(propertyId)
    if property and property.owner == identifier then
        return true
    end

    local perms = property and property.permissions
    if perms and perms[identifier] and perms[identifier][permissionKey] then
        return true
    end

    return false
end


function library.HasAnyPermission(propertyId, identifier)
    local property = GetProperty(propertyId)
    if property and property.owner == identifier then
        return true
    end

    local perms = property and property.permissions
    if perms and perms[identifier] then
        return true
    end

    return false
end






function library.GetCurrentRegion(coords)
    for regionKey, regionData in pairs(Config.Regions) do
        if regionData.zone then
            if isPointInPolygon(coords, regionData.zone) then
                return regionKey
            end
        end
    end
    return nil
end




exports("HasKeys", library.HasKeys)
exports("GenerateKeySerialNumber", library.GenerateKeySerialNumber)
exports("HasPermissions", library.HasPermissions)
exports("HasAnyPermission", library.HasAnyPermission)
