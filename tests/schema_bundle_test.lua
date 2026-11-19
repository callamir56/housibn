local p=io.popen("find esx_realestate -type f -iname '*.sql'"); local names=p:read('*a'); p:close()
assert(names=='esx_realestate/[SQL]/housing.sql\n')
local f=assert(io.open('esx_realestate/[SQL]/housing.sql')); local sql=f:read('*a'); f:close()
for _,name in ipairs({'houses','houses_bills','houses_furniture','houses_furniture_list','housing_wardrobe_outfits','housing_garage_vehicles','housing_deed_issuances'}) do
    assert(sql:find('CREATE TABLE IF NOT EXISTS `'..name..'`',1,true), name)
end
assert(sql:find('information_schema.COLUMNS',1,true) and sql:find('housing_last_property_stmt',1,true))
assert(sql:find('INSERT IGNORE INTO `houses_furniture_list`',1,true))
assert(not sql:upper():match('DROP%s+TABLE') and not sql:upper():match('TRUNCATE%s+TABLE'))
assert(sql:find('HOUSING_FURNITURE_SEED_BEGIN',1,true) and sql:find('HOUSING_FURNITURE_SEED_END',1,true))
local _, count=sql:gsub("%('[-%w_]+',",'')
assert(count>400, 'missing default furniture models')
print('single ESX SQL bundle and non-destructive seed checks passed: '..count..' models')
