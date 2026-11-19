-- Run with Lua 5.4+ from the repository root.
local f = assert(io.open('esx_realestate/server/init.lua'))
local text = f:read('*a'); f:close()
local block = assert(text:match('(local furnitureListRows%s+= MySQL%.query%.await.-)\n%s*local housesRows'))
local fn = assert(load(block .. '\nreturn furnitureListRows'))
local rows, imports, loads, fail = {}, 0, 0, false
Config = {AutoSeedFurniture = true}
function GetCurrentResourceName() return 'housing' end
function LoadResourceFile(_, path) loads = loads + 1; assert(path == '[SQL]/housing.sql'); return '-- HOUSING_FURNITURE_SEED_BEGIN\nINSERT\n-- HOUSING_FURNITURE_SEED_END' end
MySQL = {query = {await = function(sql)
  if sql == 'INSERT' then
    imports = imports + 1
    if fail then error('database failed') end
    rows = {{model = 'chair'}}
    return
  end
  return rows
end}}
assert(#fn() == 1 and imports == 1 and loads == 1)
assert(#fn() == 1 and imports == 1 and loads == 1) -- existing items left unchanged
rows = {}; Config.AutoSeedFurniture = false
assert(#fn() == 0 and imports == 1 and loads == 1)
Config.AutoSeedFurniture = true; fail = true
assert(#fn() == 0 and imports == 2) -- failure does not pretend to populate catalog
print('furniture seeding tests passed')
