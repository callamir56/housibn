-- Roll the existing invoice system forward without requiring a resource restart.
-- Deliberately do not backfill months while the server was offline: usage for
-- those periods cannot be reconstructed reliably from the existing schema.
CreateThread(function()
    while not HousingDataReady do Wait(1000) end
    local previous = os.date('%m:%Y')
    while true do
        Wait(60000)
        local period = os.date('%m:%Y')
        if period ~= previous then
            previous = period
            if Config.UseServiceBills then
                for id, property in pairs(Properties) do
                    if (property.owner or property.renter) and property.type ~= 'building' and property.type ~= 'motel' then
                        local ok, err = pcall(function()
                            library.HandleLightStateMonthOverlap(id)
                            local found = false
                            for _, bill in ipairs(property.bills or {}) do
                                if bill.type == 'services' and bill.period == period then found = true; break end
                            end
                            if not found then
                                local bill = library.GenerateMonthlyBill(id, period)
                                if bill then
                                    local duplicate = false
                                    for _, existing in ipairs(property.bills or {}) do
                                        if existing.id == bill.id then duplicate = true; break end
                                    end
                                    if not duplicate then table.insert(property.bills, 1, bill) end
                                end
                            end
                            local overdue = library.RefreshUtilityDebt(property)
                            if overdue >= Config.AllowedUnpaidBills and property.metadata and property.metadata.lightState then
                                library.ApplyCurrentLightUsage(id, os.time(), true)
                                property.metadata.lightState = false
                                property.metadata.lightStartTime = nil
                                MySQL.update.await('UPDATE houses SET metadata = ? WHERE id = ?', {json.encode(property.metadata), tonumber(id)})
                                TriggerClientEvent('vms_housing:cl:updateProperty', -1, 'toggleLight', id, {lightState = false})
                            end
                            TriggerClientEvent('vms_housing:cl:utilityDebtSync', -1, tostring(id), overdue)
                        end)
                        if not ok then print('[esx_realestate] Utility rollover failed for ' .. tostring(id) .. ': ' .. tostring(err)) end
                        Wait(10)
                    end
                end
            end
        end
    end
end)
