local activeId, activeRole, picker = nil, nil, false
local animToken, prop, animationStarted = 0, nil, false
local animDict, animName = 'amb@world_human_clipboard@male@idle_a', 'idle_c'
local function stopAnimation()
    animToken=animToken+1
    if prop and DoesEntityExist(prop) then DeleteEntity(prop) end
    prop=nil
    local ped=PlayerPedId()
    if animationStarted and IsEntityPlayingAnim(ped,animDict,animName,3) then StopAnimTask(ped,animDict,animName,1.0) end
    animationStarted=false
end
local function playAnimation()
    stopAnimation()
    local token=animToken
    CreateThread(function()
        local ped=PlayerPedId()
        if IsPedInAnyVehicle(ped,false) then return end
        RequestAnimDict(animDict)
        local deadline=GetGameTimer()+5000
        while not HasAnimDictLoaded(animDict) and GetGameTimer()<deadline and token==animToken do Wait(50) end
        if token~=animToken or not HasAnimDictLoaded(animDict) then return end
        TaskPlayAnim(ped,animDict,animName,4.0,-4.0,-1,49,0.0,false,false,false)
        animationStarted=true
        local model=joaat('prop_notepad_01')
        RequestModel(model); deadline=GetGameTimer()+5000
        while not HasModelLoaded(model) and GetGameTimer()<deadline and token==animToken do Wait(50) end
        if token~=animToken or not HasModelLoaded(model) then SetModelAsNoLongerNeeded(model); return end
        local p=GetEntityCoords(ped)
        prop=CreateObject(model,p.x,p.y,p.z,true,true,false)
        SetModelAsNoLongerNeeded(model)
        if prop and prop~=0 then
            SetEntityCollision(prop,false,false)
            AttachEntityToEntity(prop,ped,GetPedBoneIndex(ped,18905),0.10,0.02,0.05,10.0,0.0,10.0,true,true,false,true,1,true)
        end
    end)
end
local function closeLocal()
    picker=false
    activeId=nil; activeRole=nil
    stopAnimation()
    SendNUIMessage({action='DeedShare',actionName='ForceClose'})
    if openedMenu=='DeedShare' or openedMenu=='DeedPicker' then openedMenu=nil; SetNuiFocus(false,false) end
end
RegisterNetEvent('vms_housing:deedShare:select',function(players)
    if openedMenu then TriggerServerEvent('vms_housing:deedShare:cancelSelect'); return CL.Notification('Close the current menu first.',5000,'error') end
    picker=true; openedMenu='DeedPicker'; SetNuiFocus(true,true)
    SendNUIMessage({action='DeedShare',actionName='Pick',data=players})
end)
RegisterNetEvent('vms_housing:deedShare:show',function(id,role,data)
    if openedMenu and not (role=='owner' and openedMenu=='DeedPicker' and picker) then
        TriggerServerEvent('vms_housing:deedShare:close',id)
        return
    end
    picker=false; activeId=id; activeRole=role; openedMenu='DeedShare'
    SetNuiFocus(true,true)
    SendNUIMessage({action='DeedShare',actionName='Show',data=data,role=role})
    if role=='owner' then playAnimation() end
end)
RegisterNetEvent('vms_housing:deedShare:close',function(id)
    if activeId and tonumber(id)==tonumber(activeId) then closeLocal() end
end)
RegisterNUICallback('deedShare:choose',function(data,cb)
    if not picker or type(data)~='table' or not tonumber(data.id) then return cb({ok=false,reason='Selection closed.'}) end
    library.Callback('vms_housing:deedShare:choose',function(result) cb(result or {ok=false,reason='Unable to show deed.'}) end,tonumber(data.id))
end)
RegisterNUICallback('deedShare:cancel',function(_,cb)
    if picker then TriggerServerEvent('vms_housing:deedShare:cancelSelect'); closeLocal() end
    cb({ok=true})
end)
RegisterNUICallback('deedShare:close',function(_,cb)
    if activeId then local id=activeId; closeLocal(); TriggerServerEvent('vms_housing:deedShare:close',id) end
    cb({ok=true})
end)
AddEventHandler('onResourceStop',function(name)
    if name==GetCurrentResourceName() then closeLocal() end
end)
