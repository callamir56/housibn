HousingTV = {}
local dui, target, ownedTarget, texture, property, activeVideo, activeVersion, revision = nil,nil,false,nil,nil,nil,nil,0
local textureSerial = 0
local mode = nil
local function stop()
    revision=revision+1
    if dui then DestroyDui(dui); dui=nil end
    if ownedTarget then ReleaseNamedRendertarget('tvscreen') end
    target,ownedTarget,texture,property,activeVideo,activeVersion=nil,false,nil,nil,nil,nil
    mode=nil
end
-- Keep the game's named render target while the TV is off: simply releasing it
-- brings back GTA's default TV picture rather than a black screen.
local function attachTarget(id)
    stop()
    property=id
    local already=IsNamedRendertargetRegistered('tvscreen')
    if already then
        stop(); CL.Notification('TV screen is in use by another resource.',4000,'error'); return false
    end
    RegisterNamedRendertarget('tvscreen',false); ownedTarget=true
    if not IsNamedRendertargetRegistered('tvscreen') then
        stop(); CL.Notification('TV render target unavailable.',4000,'error'); return false
    end
    for model in pairs(Config.HousingTV.Models or {}) do
        local hash=GetHashKey(model)
        if not IsNamedRendertargetLinked(hash) then LinkNamedRendertarget(hash) end
    end
    target=GetNamedRendertargetRenderId('tvscreen')
    return true
end
local function show(id,state)
    if tostring(CurrentProperty or '')~=tostring(id) then return end
    if not state or not state.on then
        if property==id and mode=='off' and target then return end
        if not attachTarget(id) then return end
        mode='off'
        local thisRevision=revision
        CreateThread(function()
            while revision==thisRevision and mode=='off' and target do
                if tostring(CurrentProperty or '')~=id then stop(); break end
                SetTextRenderId(target)
                SetScriptGfxDrawBehindPausemenu(true)
                SetScriptGfxDrawOrder(4)
                DrawRect(0.5,0.5,1.0,1.0,0,0,0,255)
                SetTextRenderId(GetDefaultScriptRendertargetRenderId())
                SetScriptGfxDrawOrder(0)
                SetScriptGfxDrawBehindPausemenu(false)
                Wait(0)
            end
        end)
        return
    end
    if type(state.video)~='string' or #state.video>2048 then return end
    if state.provider~='youtube' and state.provider~='aparat' and state.provider~='vimeo' and state.provider~='direct' then return end
    if property==id and activeVideo==state.video and activeVersion==state.version and dui then return end
    if not attachTarget(id) then return end
    mode='on'; activeVideo=state.video; activeVersion=state.version
    textureSerial=textureSerial+1
    local textureName=('housing_tv_%d'):format(textureSerial)
    local txd=CreateRuntimeTxd(textureName)
    dui=CreateDui(('https://cfx-nui-%s/html/housing_tv.html'):format(GetCurrentResourceName()),1280,720)
    local thisRevision=revision
    CreateThread(function()
        local deadline=GetGameTimer()+10000
        while dui and revision==thisRevision and not IsDuiAvailable(dui) and GetGameTimer()<deadline do Wait(100) end
        if not dui or revision~=thisRevision then return end
        if not IsDuiAvailable(dui) then stop(); return CL.Notification('TV player failed to load.',4000,'error') end
        -- Do not bind a texture to a DUI before the browser is available.
        texture=CreateRuntimeTextureFromDuiHandle(txd,'screen',GetDuiHandle(dui))
        local message=json.encode({action='play',provider=state.provider,video=state.video,elapsed=state.elapsed or 0})
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
            SetScriptGfxDrawOrder(4)
            DrawSprite(textureName,'screen',0.5,0.5,1.0,1.0,0.0,255,255,255,255)
            SetTextRenderId(GetDefaultScriptRendertargetRenderId())
            SetScriptGfxDrawOrder(0)
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
local inputContext
local function closeInput()
    if not inputContext then return end
    inputContext=nil
    SendNUIMessage({action='HousingTVInput',open=false})
    if openedMenu=='HousingTVInput' then openedMenu=nil; SetNuiFocus(false,false) end
end
function HousingTV.Control(id,furnitureId,action)
    if tostring(CurrentProperty or '')~=tostring(id) then return end
    if action=='off' then return TriggerServerEvent('vms_housing:tv:control',tostring(id),furnitureId,'off') end
    if openedMenu or inputContext then return end
    local context={id=tostring(id),furniture=furnitureId}
    inputContext=context
    openedMenu='HousingTVInput'
    SetNuiFocus(true,true)
    SendNUIMessage({action='HousingTVInput',open=true})
    CreateThread(function()
        while inputContext==context do
            Wait(500)
            if tostring(CurrentProperty or '')~=context.id then closeInput(); break end
        end
    end)
end
local inputBusy=false
RegisterNUICallback('housingTV:submit',function(data,cb)
    local context=inputContext
    local url=type(data)=='table' and data.url
    if inputBusy then return cb({ok=false,reason='Please wait.'}) end
    if not context or type(url)~='string' or #url>2048 or not url:match('%S') then
        return cb({ok=false,reason='Enter a video link.'})
    end
    if tostring(CurrentProperty or '')~=context.id then closeInput(); return cb({ok=false,reason='You left the house.'}) end
    inputBusy=true
    library.Callback('vms_housing:tv:play',function(result)
        inputBusy=false
        if inputContext~=context then return cb({ok=false,reason='The TV menu was closed.'}) end
        if result and result.ok then closeInput() end
        cb(result or {ok=false,reason='TV server unavailable.'})
    end,context.id,context.furniture,url)
end)
RegisterNUICallback('housingTV:close',function(_,cb) closeInput(); cb({ok=true}) end)
RegisterNetEvent('vms_housing:tv:update',function(id,state) show(tostring(id),state) end)
AddEventHandler('onResourceStop',function(resource) if resource==GetCurrentResourceName() then closeInput(); stop() end end)
