-- The coordinates below are the reference positions supplied for each shell.
-- They are NOT yet calibrated for this resource, which spawns shell objects at
-- (0, 0, 500). Replace doors with the entrance position at that spawn location
-- and set needsCalibration = false after verifying each model in game.
local shells = {
    t1_unfurn_shell = {label = 'T1 Unfurnished', model = 't1_unfurn_shell', tags = {'empty'}, doors = {x = -43.758571624756, y = -621.24615478516, z = 13.069511413574, heading = 163.11503601074}},
    t1_furn_shell = {label = 'T1 Furnished', model = 't1_furn_shell', tags = {'furnished'}, doors = {x = -43.758937835693, y = -621.25531005859, z = -29.204921722412, heading = 163.11503601074}},
    t2_unfurn_shell = {label = 'T2 Unfurnished', model = 't2_unfurn_shell', tags = {'empty'}, doors = {x = -590.81280517578, y = -818.99365234375, z = -18.266839981079, heading = 181.92446899414}},
    t2_furn_shell = {label = 'T2 Furnished', model = 't2_furn_shell', tags = {'furnished'}, doors = {x = -590.67864990234, y = -713.25665283203, z = -42.451679229736, heading = 180.931640625}},
    t3_unfurn_shell = {label = 'T3 Unfurnished', model = 't3_unfurn_shell', tags = {'empty'}, doors = {x = -66.28133392334, y = -817.49145507812, z = 20.182094573975, heading = 180.3955078125}},
    t3_furn_shell = {label = 'T3 Furnished', model = 't3_furn_shell', tags = {'furnished'}, doors = {x = -66.28670501709, y = -817.39019775391, z = -20.310405731201, heading = 181.03651428223}},
}

for _, shell in pairs(shells) do
    if shell.needsCalibration == nil then shell.needsCalibration = true end
end

addShells(shells)
