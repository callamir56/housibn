local f=assert(io.open('esx_realestate/config/config.lua')); local cfg=f:read('*a'); f:close()
assert(cfg:match('Config%.Debug%s*=%s*false'))
local f2=assert(io.open('esx_realestate/client/lib.lua')); local source=f2:read('*a'); f2:close()
local first=assert(source:find('function library.Debug(message, level)',1,true))
local last=assert(source:find('\nend',first,true))+4
local prints,warns=0,0
local environment={Config={Debug=false}, library={}, print=function() prints=prints+1 end, warn=function() warns=warns+1 end, error=error}
assert(load(source:sub(first,last),'debug','t',environment))()
environment.library.Debug('You entered the Property Zone: 12')
environment.library.Debug('warning','warn')
assert(prints==0 and warns==0)
environment.Config.Debug=true; environment.library.Debug('developer log'); assert(prints==1)
print('client debug logging is disabled by default')
