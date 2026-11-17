local activeId
local function close()
    activeId=nil
    SendNUIMessage({action='DeedAgency',actionName='Close'})
    if openedMenu=='DeedAgency' then openedMenu=nil; SetNuiFocus(false,false) end
end
RegisterNetEvent('vms_housing:deedAgency:prompt',function(id,agent,property,address)
    if openedMenu then
        TriggerServerEvent('vms_housing:deedAgency:answer',id,false)
        return CL.Notification('A deed request was declined because another menu is open.',5000,'error')
    end
    activeId=id;openedMenu='DeedAgency';SetNuiFocus(true,true)
    SendNUIMessage({action='DeedAgency',actionName='Open',agent=agent,property=property,address=address})
end)
RegisterNetEvent('vms_housing:deedAgency:close',function(id)
    if activeId and tonumber(id)==tonumber(activeId) then close() end
end)
RegisterNUICallback('deedAgency:answer',function(data,cb)
    if activeId then
        local id=activeId
        close()
        TriggerServerEvent('vms_housing:deedAgency:answer',id,type(data)=='table' and data.accept==true)
    end
    cb({ok=true})
end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() and activeId then close() end end)
