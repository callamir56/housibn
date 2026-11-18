HousingTV = {}
local dui, target, ownedTarget, texture, property, activeVideo, activeVersion, revision = nil,nil,false,nil,nil,nil,nil,0
local function stop()
    revision=revision+1
    if dui then DestroyDui(dui); dui=nil end
    if ownedTarget then ReleaseNamedRendertarget('tvscreen') end
    target,ownedTarget,texture,property,activeVideo,activeVersion=nil,false,nil,nil,nil,nil
end
local function show(id,state)
    if tostring(CurrentProperty or '')~=tostring(id) then return end
    if not state or not state.on then return stop() end
    if type(state.video)~='string' or not state.video:match('^[%w_-]+$') or #state.video~=11 then return end
    if property==id and activeVideo==state.video and activeVersion==state.version and dui then return end
    stop()
    property=id; activeVideo=state.video; activeVersion=state.version
    local already=IsNamedRendertargetRegistered('tvscreen')
    if already then
        stop(); return CL.Notification('TV screen is in use by another resource.',4000,'error')
    end
    RegisterNamedRendertarget('tvscreen',false); ownedTarget=true
    if not IsNamedRendertargetRegistered('tvscreen') then
        stop(); return CL.Notification('TV render target unavailable.',4000,'error')
    end
    for model in pairs(Config.HousingTV.Models or {}) do
        local hash=GetHashKey(model)
        if not IsNamedRendertargetLinked(hash) then LinkNamedRendertarget(hash) end
    end
    target=GetNamedRendertargetRenderId('tvscreen')
    local txd=CreateRuntimeTxd('housing_tv')
    dui=CreateDui(('https://cfx-nui-%s/html/housing_tv.html'):format(GetCurrentResourceName()),1280,720)
    texture=CreateRuntimeTextureFromDuiHandle(txd,'screen',GetDuiHandle(dui))
    local thisRevision=revision
    CreateThread(function()
        local deadline=GetGameTimer()+10000
        while dui and revision==thisRevision and not IsDuiAvailable(dui) and GetGameTimer()<deadline do Wait(100) end
        if not dui or revision~=thisRevision then return end
        if not IsDuiAvailable(dui) then stop(); return CL.Notification('TV player failed to load.',4000,'error') end
        local message=json.encode({action='play',video=state.video,elapsed=state.elapsed or 0})
        -- DUI availability can precede the page's message handler. Re-send a
        -- few times; the page ignores duplicates once it has accepted the URL.
        CreateThread(function()
            for _=1,4 do
                if not dui or revision~=thisRevision then return end
                SendDuiMessage(dui,message)
                Wait(1000)
            end
        end)
        while dui and revision==thisRevision do
            if tostring(CurrentProperty or '')~=id then stop(); break end
            SetTextRenderId(target)
            SetScriptGfxDrawBehindPausemenu(true)
            DrawSprite('housing_tv','screen',0.5,0.5,1.0,1.0,0.0,255,255,255,255)
            SetTextRenderId(GetDefaultScriptRendertargetRenderId())
            SetScriptGfxDrawBehindPausemenu(false)
            Wait(0)
        end
    end)
end
function HousingTV.Refresh(id)
    id=tostring(id or '')
    local requestRevision=revision
    library.Callback('vms_housing:tv:state',function(data)
        if requestRevision==revision and data and data.ok then show(id,data.state) end
    end,id)
end
function HousingTV.Control(id,furnitureId,action)
    if tostring(CurrentProperty or '')~=tostring(id) then return end
    if action=='off' then return TriggerServerEvent('vms_housing:tv:control',tostring(id),furnitureId,'off') end
    AddTextEntry('HOUSING_TV_URL','YouTube URL or video ID')
    DisplayOnscreenKeyboard(1,'HOUSING_TV_URL','','','','','',512)
    while UpdateOnscreenKeyboard()==0 do Wait(0) end
    local url=GetOnscreenKeyboardResult()
    if url and tostring(CurrentProperty or '')==tostring(id) then
        TriggerServerEvent('vms_housing:tv:control',tostring(id),furnitureId,'play',url)
    end
end
RegisterNetEvent('vms_housing:tv:update',function(id,state) show(tostring(id),state) end)
AddEventHandler('onResourceStop',function(resource) if resource==GetCurrentResourceName() then stop() end end)
