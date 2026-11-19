




Core = Config.CoreExport()


Properties        = {}
Furniture         = {}
PendingDeliveries = {}
HousingDataReady = false











function SaveFurniture(action, payload)
    if action == "insert" then
        if type(payload) ~= "table" then
            return
        end

        for _, model in ipairs(payload) do
            local item = Furniture[model]
            if not item then

                return
            end

            local metadataJson = nil
            if item.metadata then
                metadataJson = json.encode(item.metadata) or nil
            end


            MySQL.Async.execute([[
                INSERT INTO `houses_furniture_list` (
                    `model`,
                    `label`,
                    `price`,
                    `deliverySize`,
                    `tag`,
                    `isOutdoor`,
                    `isIndoor`,
                    `interactableName`,
                    `metadata`
                )
                VALUES (@model, @label, @price, @deliverySize, @tag, @isOutdoor, @isIndoor, @interactableName, @metadata)
            ]], {
                ["@model"]            = model,
                ["@label"]            = item.label,
                ["@price"]            = item.price,
                ["@deliverySize"]     = item.deliverySize,
                ["@tag"]              = item.tag,
                ["@isOutdoor"]        = item.isOutdoor,
                ["@isIndoor"]         = item.isIndoor,
                ["@interactableName"] = item.interactableName,
                ["@metadata"]         = metadataJson,
            })
        end

    elseif action == "update" then
        local model = payload
        local item = Furniture[model]
        if not item then
            return
        end

        local metadataJson = nil
        if item.metadata then
            metadataJson = json.encode(item.metadata) or nil
        end


        MySQL.Async.execute([[
            UPDATE `houses_furniture_list` SET
                `label` = @label,
                `price` = @price,
                `deliverySize` = @deliverySize,
                `tag` = @tag,
                `isOutdoor` = @isOutdoor,
                `isIndoor` = @isIndoor,
                `interactableName` = @interactableName,
                `metadata` = @metadata
            WHERE `model` = @model
        ]], {
            ["@model"]            = model,
            ["@label"]            = item.label,
            ["@price"]            = item.price,
            ["@deliverySize"]     = item.deliverySize,
            ["@tag"]              = item.tag,
            ["@isOutdoor"]        = item.isOutdoor,
            ["@isIndoor"]         = item.isIndoor,
            ["@interactableName"] = item.interactableName,
            ["@metadata"]         = metadataJson,
        })

    elseif action == "delete" then
        local model = payload


        MySQL.Async.execute([[
            DELETE FROM `houses_furniture_list` WHERE `model` = @model
        ]], {
            ["@model"] = model
        })
    end
end





MySQL.ready(function()




    if Config.AutoExecuteQuery then
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `houses` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `type` varchar(50) DEFAULT NULL,
                `object_id` int(11) DEFAULT NULL,
                `owner` varchar(120) DEFAULT NULL,
                `owner_name` varchar(80) DEFAULT NULL,
                `renter` varchar(120) DEFAULT NULL,
                `renter_name` varchar(80) DEFAULT NULL,
                `name` longtext DEFAULT '',
                `description` longtext DEFAULT NULL,
                `region` varchar(70) DEFAULT NULL,
                `address` varchar(50) DEFAULT NULL,
                `keys` longtext NOT NULL DEFAULT '[]',
                `permissions` longtext DEFAULT '[]',
                `metadata` longtext NOT NULL DEFAULT '[]',
                `sale` longtext DEFAULT '[]',
                `rental` longtext DEFAULT '[]',
                `last_enter` int(11) DEFAULT NULL,
                `creator` varchar(120) DEFAULT NULL,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
        ]])

        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `houses_bills` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `house_id` int(11) NOT NULL,
                `period` varchar(50) NOT NULL DEFAULT '',
                `type` varchar(50) DEFAULT NULL,
                `total` float DEFAULT 0,
                `paid` tinyint(1) DEFAULT 0,
                `details` longtext NOT NULL,
                PRIMARY KEY (`id`),
                UNIQUE KEY `unique_period_per_house_type` (`house_id`,`period`,`type`)
            ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
        ]])

        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `houses_furniture` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `house_id` int(11) NOT NULL,
                `position` longtext DEFAULT NULL,
                `model` varchar(70) DEFAULT NULL,
                `stored` int(11) DEFAULT 0,
                `metadata` longtext DEFAULT NULL,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
        ]])

        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `housing_garage_vehicles` (
                `property_id` varchar(64) NOT NULL,
                `owner` varchar(128) NOT NULL,
                `plate` varchar(16) NOT NULL,
                `vehicle` longtext NOT NULL,
                PRIMARY KEY (`property_id`),
                UNIQUE KEY `housing_garage_plate` (`plate`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
        ]])

        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `housing_deed_issuances` (
              `id` bigint unsigned NOT NULL AUTO_INCREMENT,
              `property_id` int NOT NULL,
              `revision` varchar(64) NOT NULL,
              `owner` varchar(128) NOT NULL,
              `holder` varchar(128) NOT NULL,
              `kind` varchar(16) NOT NULL,
              `owner_slot` tinyint unsigned DEFAULT NULL,
              PRIMARY KEY (`id`),
              UNIQUE KEY `deed_owner_slot` (`property_id`,`revision`,`owner_slot`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
        ]])

        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `housing_wardrobe_outfits` (
                `identifier` varchar(128) NOT NULL,
                `slot` tinyint unsigned NOT NULL,
                `name` varchar(40) NOT NULL,
                `skin` longtext NOT NULL,
                PRIMARY KEY (`identifier`, `slot`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
        ]])

        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `houses_furniture_list` (
                `model` varchar(80) NOT NULL,
                `label` varchar(80) DEFAULT NULL,
                `price` int(11) DEFAULT 0,
                `deliverySize` int(11) DEFAULT 1,
                `tag` varchar(50) DEFAULT NULL,
                `isOutdoor` int(11) DEFAULT 1,
                `isIndoor` int(11) DEFAULT 1,
                `interactableName` varchar(50) DEFAULT NULL,
                `metadata` longtext DEFAULT NULL,
                PRIMARY KEY (`model`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
        ]])
    end




    Citizen.CreateThread(function()
        local initStartMs = GetGameTimer()
        local nowUnix      = os.time()
        local monthPeriod  = os.date("%m:%Y", nowUnix)
        local weekPeriod   = GetWeekPeriod()





        if Config.OptimizeBillsTable then
            MySQL.prepare(string.format(
                "DELETE FROM houses_bills WHERE `paid` = 1 AND `period` != '%s'",
                monthPeriod
            ), {})
        end





        local furnitureListRows   = MySQL.query.await("SELECT * FROM `houses_furniture_list`", {})

        if furnitureListRows and #furnitureListRows == 0 and Config.AutoSeedFurniture then
            local sqlFile = LoadResourceFile(GetCurrentResourceName(), "[SQL]/housing.sql")
            local seedSql = sqlFile and sqlFile:match("%-%- HOUSING_FURNITURE_SEED_BEGIN%s*(.-)%s*%-%- HOUSING_FURNITURE_SEED_END")
            if not seedSql or seedSql == "" then
                print("[esx_realestate] Cannot find [SQL]/housing.sql; furniture catalog remains empty.")
            else
                local ok, err = pcall(function() MySQL.query.await(seedSql, {}) end)
                if ok then
                    furnitureListRows = MySQL.query.await("SELECT * FROM `houses_furniture_list`", {})
                    print(("[esx_realestate] Default furniture catalog loaded: %d items."):format(furnitureListRows and #furnitureListRows or 0))
                else
                    print(("[esx_realestate] Could not import furniture catalog: %s"):format(tostring(err)))
                end
            end
        end
        local housesRows          = MySQL.query.await("SELECT * FROM `houses`", {})
        local billsRows           = MySQL.query.await("SELECT * FROM `houses_bills` ORDER BY id DESC", {})
        local placedFurnitureRows = MySQL.query.await("SELECT * FROM `houses_furniture`", {})




        if furnitureListRows then
            for i = 1, #furnitureListRows do
                local row = furnitureListRows[i]

                if row.metadata then
                    row.metadata = json.decode(row.metadata)
                end

                Furniture[row.model] = row
            end
        end




        for i = 1, #housesRows do
            local house = housesRows[i]
            local propertyId = tostring(house.id)


            house.metadata = json.decode(house.metadata)
            house.sale     = json.decode(house.sale)
            house.rental   = json.decode(house.rental)


            if house.type ~= "building" and house.type ~= "motel" then
                house.permissions    = json.decode(house.permissions)
                house.bills          = {}
                house.unpaidBills    = 0
                house.unpaidRentBills = 0
                house.furniture      = {}


                if not Config.SaveDoorsState then
                    if house.type == "mlo" then
                        if house.metadata and house.metadata.doors then
                            for _, door in pairs(house.metadata.doors) do
                                door.locked = Config.DefaultDoorsLocked
                            end
                        end
                    else
                        house.metadata.locked = Config.DefaultDoorsLocked
                    end
                end


                local taxCfg = Config.CityHallTaxes
                    and Config.CityHallTaxes.PropertyCadastralTax
                    and Config.CityHallTaxes.PropertyCadastralTax.Enabled

                if taxCfg and house.owner then
                    local lastPeriod = house.metadata and house.metadata.lastCadastralPeriod
                    if lastPeriod ~= monthPeriod then

                        local added = SV.AddTax(
                            house.owner,
                            house.owner_name,
                            house.name,
                            house.address,
                            "property_cadastral_tax",
                            house.sale and house.sale.defaultPrice
                        )

                        if added then
                            house.metadata.lastCadastralPeriod = monthPeriod


                            MySQL.prepare(
                                "UPDATE `houses` SET metadata = ? WHERE id = ?",
                                { json.encode(house.metadata), tonumber(house.id) }
                            )
                        end
                    end
                end


                if house.metadata and house.metadata.storage and house.metadata.storage.x then

                    library.RegisterStorage({
                        id     = ("house_storage-%s"):format(house.id),
                        slots  = house.metadata.storage.slots,
                        weight = house.metadata.storage.weight
                    })
                end
            end


            Properties[propertyId] = house


            if (i % 100) == 0 then
                Citizen.Wait(10)
            end
        end




        if placedFurnitureRows then
            for i = 1, #placedFurnitureRows do
                local f = placedFurnitureRows[i]
                f.position = json.decode(f.position)
                f.metadata  = json.decode(f.metadata)

                local propertyId = tostring(f.house_id)
                local house = Properties[propertyId]
                if house then

                    if f.metadata and f.metadata.deliveryTime then
                        table.insert(PendingDeliveries, {
                            propertyId   = propertyId,
                            furnitureId  = f.id,
                            deliveryTime = f.metadata.deliveryTime
                        })
                    end


                    if f.position and f.metadata and next(f.metadata) and f.metadata.weight ~= nil then

                        library.RegisterStorage(f.metadata)
                    end


                    table.insert(house.furniture, f)
                end
            end
        end




        if billsRows then
            for i = 1, #billsRows do
                local bill = billsRows[i]
                local propertyId = tostring(bill.house_id)
                local house = Properties[propertyId]

                if house and house.type ~= "building" and house.type ~= "motel" then
                    if bill.paid ~= true and tonumber(bill.paid) ~= 1 then


                        if bill.type == "rent" and not bill.paid then
                            house.unpaidRentBills = (house.unpaidRentBills or 0) + 1
                        elseif bill.type == "services" and Config.UseServiceBills and bill.period ~= monthPeriod then
                            house.unpaidBills = (house.unpaidBills or 0) + 1
                        end
                    end

                    table.insert(house.bills, bill)
                end
            end








            for propertyId, house in pairs(Properties) do
                if house.type ~= "building" and house.type ~= "motel" then
                    local hasServiceBillThisMonth = false
                    local hasRentBillForCycle     = false


                    local rentPeriod = monthPeriod
                    if house.rental and house.rental.cycle == "weekly" and weekPeriod then
                        rentPeriod = weekPeriod
                    end


                    local bills = house.bills or {}
                    for _, bill in ipairs(bills) do
                        if bill.period == monthPeriod and bill.type == "services" then
                            hasServiceBillThisMonth = true
                        end
                        if bill.period == rentPeriod and bill.type == "rent" and house.renter then
                            hasRentBillForCycle = true
                        end


                        if hasServiceBillThisMonth then
                            if (not house.renter) or hasRentBillForCycle then
                                break
                            end
                        end
                    end


                    if Config.UseServiceBills and not hasServiceBillThisMonth then

                        local newBill = library.GenerateMonthlyBill(propertyId, monthPeriod)
                        if newBill then
                            table.insert(house.bills, 1, newBill)
                        end
                    end

                    library.RefreshUtilityDebt(house)

                    if Config.UseServiceBills and house.unpaidBills then
                        if house.unpaidBills >= Config.AllowedUnpaidBills then
                            if house.metadata and house.metadata.lightState then

                                library.HandleLightStateMonthOverlap(propertyId)

                                house.metadata.lightState = false
                                house.metadata.lightStartTime = nil


                                MySQL.prepare(
                                    "UPDATE `houses` SET metadata = ? WHERE id = ?",
                                    { json.encode(house.metadata), tonumber(propertyId) }
                                )
                            end
                        end
                    end


                    if house.renter then
                        if not hasRentBillForCycle then

                            local rentBill = library.GenerateRentBill(propertyId, rentPeriod)
                            if rentBill then
                                table.insert(house.bills, 1, rentBill)
                                house.unpaidRentBills = (house.unpaidRentBills or 0) + 1
                            end
                        end

                        local unpaidRent = house.unpaidRentBills or 0
                        local mustTerminate =
                            (unpaidRent >= Config.AllowedUnpaidRentBills) or
                            (house.rental and house.rental.terminateAtPeriod == monthPeriod)

                        if mustTerminate then









                            local updateQuery = ""
                            local renterIdentifier = house.renter

                            if house.owner then

                                updateQuery = [[
                                    UPDATE `houses`
                                        SET
                                            `renter` = NULL,
                                            `renter_name` = NULL,
                                            `permissions` = @permissions,
                                            `keys` = @keys,
                                            `metadata` = @metadata,
                                            `rental` = @rental
                                    WHERE id = @id
                                ]]


                                if Config.RemoveKeysOnRentEnd then
                                    house.keys = json.encode({})
                                end


                                house.unpaidRentBills = nil

                                MySQL.prepare(
                                    "DELETE FROM houses_bills WHERE `house_id` = ? AND `type` = ? AND `paid` = 0",
                                    { tonumber(propertyId), "rent" }
                                )


                                for idx = #house.bills, 1, -1 do
                                    local b = house.bills[idx]
                                    if b.type == "rent" and (b.paid == 0 or b.paid == false) then
                                        table.remove(house.bills, idx)
                                    end
                                end


                                house.metadata.locked = true
                                house.metadata.lightState = false
                                house.metadata.lightStartTime = nil


                                if house.permissions then
                                    house.permissions[renterIdentifier] = nil
                                end
                            else

                                updateQuery = [[
                                    UPDATE `houses`
                                        SET
                                            `renter` = NULL,
                                            `renter_name` = NULL,
                                            `keys` = @keys,
                                            `permissions` = @permissions,
                                            `metadata` = @metadata,
                                            `sale` = @sale,
                                            `rental` = @rental,
                                            `last_enter` = NULL
                                    WHERE id = @id
                                ]]


                                house.keys = json.encode({})


                                if house.sale then
                                    house.sale.active = house.sale.defaultActive
                                end
                                if house.rental then
                                    house.rental.active = house.rental.defaultActive
                                end


                                house.metadata.locked = true
                                house.metadata.contact_number = nil
                                house.metadata.lightState = false
                                house.metadata.lightStartTime = nil


                                if Config.RemoveFurnitureOnRentEnd then
                                    house.furniture = {}

                                    MySQL.prepare(
                                        "DELETE FROM houses_furniture WHERE house_id = ?",
                                        { tonumber(propertyId) }
                                    )
                                end


                                house.bills = {}
                                house.unpaidBills = 0
                                house.unpaidRentBills = nil

                                MySQL.prepare(
                                    "DELETE FROM houses_bills WHERE house_id = ?",
                                    { tonumber(propertyId) }
                                )

                                house.permissions = {}
                            end


                            house.renter = nil
                            house.renter_name = nil
                            if house.rental then
                                house.rental.startTime = nil
                                house.rental.terminateAtPeriod = nil
                            end


                            MySQL.Async.execute(updateQuery, {
                                ["@keys"]        = house.keys,
                                ["@permissions"] = json.encode(house.permissions),
                                ["@metadata"]    = json.encode(house.metadata),
                                ["@sale"]        = json.encode(house.sale),
                                ["@rental"]      = json.encode(house.rental),
                                ["@id"]          = tonumber(propertyId),
                            })
                        end
                    end
                end
            end
        end



        HousingDataReady = true
        if not furnitureListRows or #furnitureListRows == 0 then
            print("[esx_realestate] Furniture catalog is empty; import [SQL]/housing.sql once and restart the resource.")
        end



        library.Debug(("^2VMS Housing init completed in %d ms^7"):format(GetGameTimer() - initStartMs))
        library.Debug(("Loaded %d Properies, %d Bills, %d Furniture"):format(
            #housesRows,
            billsRows and #billsRows or 0,
            placedFurnitureRows and #placedFurnitureRows or 0
        ))
    end)
end)





CreateThread(function()
    while true do
        local deliveryType = Config.DeliveryType
        if deliveryType ~= 2 and deliveryType ~= 3 then
            break
        end

        Citizen.Wait(8000)

        if next(PendingDeliveries) then

            ProcessPendingDeliveries(200)
        end


        Wait(30000)
    end
end)
