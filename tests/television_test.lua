local cb, events, emitted, worker={}, {}, {}, nil
HousingDataReady=true
Config={HousingTV={Enabled=true,ControlPermission='furniture',MaxDistance=3.5,Models={tv=true}}}
local properties={['7']={owner='owner1',metadata={},furniture={{id=5,model='tv',stored=0,position={x=0,y=0,z=0,environment='inside'}}}},
 ['8']={owner='owner2',metadata={},furniture={{id=6,model='tv',stored=0,position={x=0,y=0,z=0,environment='inside'}}}}}
local ids={[1]='owner1',[2]='guest',[3]='owner2'}
local buckets={[1]=8,[2]=8,[3]=9}
SV={GetPlayer=function(src) return ids[src] and {id=src} end,GetIdentifier=function(p) return ids[p.id] end}
library={RegisterCallback=function(n,fn) cb[n]=fn end,HasPermissions=function(id,ident) return properties[id].owner==ident end,Notification=function() end}
function GetProperty(id) return properties[id] end
function IsPlayerInProperty(src,id) return buckets[src]==tonumber(id)+1 end
function GetPlayerRoutingBucket(src) return buckets[src] end
function GetPlayerPed(src) return src end
local coords={x=0,y=0,z=0}
function GetEntityCoords() return coords end
function GetPlayers() return {'1','2','3'} end
function TriggerClientEvent(name,src,id,state) emitted[#emitted+1]={name=name,src=src,id=id,state=state} end
function RegisterNetEvent(name,fn) events[name]=fn end
function AddEventHandler(name,fn) events[name]=fn end
function CreateThread(fn) worker=fn end
assert(loadfile('esx_realestate/server/modules/television.lua'))()
source=2; events['vms_housing:tv:control']('7',5,'play','https://youtu.be/abcdefghijk'); assert(#emitted==0)
source=1; events['vms_housing:tv:control']('7',5,'play','https://evil.example/abcdefghijk'); assert(#emitted==0)
coords={x=30,y=0,z=0}; events['vms_housing:tv:control']('7',5,'play','abcdefghijk'); assert(#emitted==0)
coords={x=0,y=0,z=0}; events['vms_housing:tv:control']('7',5,'play','https://youtu.be/abcdefghijk'); assert(#emitted==2)
assert(emitted[1].id=='7' and emitted[1].state.video=='abcdefghijk' and emitted[1].src~=3 and emitted[2].src~=3)
local result; cb['vms_housing:tv:state'](3,function(r) result=r end,'7'); assert(not result.ok)
cb['vms_housing:tv:state'](2,function(r) result=r end,'7'); assert(result.ok and result.state.video=='abcdefghijk')
properties['7'].owner='new-owner'; cb['vms_housing:tv:state'](2,function(r) result=r end,'7'); assert(result.ok and not result.state.on)
source=3; events['vms_housing:tv:control']('8',6,'play','ABCDEFGHIJK'); assert(emitted[3].src==3 and emitted[3].id=='8')
print('TV URL validation, permission, proximity, property isolation and ownership change passed')

-- Test each supported provider and reject non-video URLs and internal literals.
local realTime=os.time; local clock=realTime(); os.time=function() return clock end
local function play(url) clock=clock+3; source=3; events['vms_housing:tv:control']('8',6,'play',url); return emitted[#emitted].state end
local before=#emitted
for _, url in ipairs({'http://example.com/movie.mp4','https://127.0.0.1/movie.mp4','https://example.local/movie.mp4','https://example.com/home','https://user@example.com/movie.mp4','https://www.aparat.com.evil.example/v/BNMK5'}) do
  play(url); assert(#emitted==before, 'unexpectedly accepted '..url)
end
local a=play('https://www.aparat.com/v/BNMK5'); assert(a.provider=='aparat' and a.video=='BNMK5')
local b=play('https://cdn.example.com/media/movie.MP4?token=abc'); assert(b.provider=='direct' and b.video:match('movie.MP4'))
assert(play('https://vimeo.com/123456789').provider=='vimeo')
local c=play('https://www.youtube.com/watch?feature=share&v=abcdefghijk'); assert(c.provider=='youtube' and c.video=='abcdefghijk')
Config.HousingTV.DirectAllowedHosts={['safe.example.com']=true}; before=#emitted
play('https://cdn.example.com/test.mp4'); assert(#emitted==before)
assert(play('https://safe.example.com/test.webm').provider=='direct')
os.time=realTime
print('TV provider parsing, internal host rejection and direct host allowlist passed')
