-- Run with Lua 5.4+ from the repository root.
local registry
function addShells(shells) registry = shells end
assert(loadfile('esx_realestate/integration/[shells]/custom.lua'))()
local names = {'t1_unfurn_shell', 't1_furn_shell', 't2_unfurn_shell', 't2_furn_shell', 't3_unfurn_shell', 't3_furn_shell'}
local count = 0
for _ in pairs(registry) do count = count + 1 end
assert(count == 6)
for _, name in ipairs(names) do
  local shell = assert(registry[name])
  assert(shell.model == name and shell.needsCalibration)
  assert(shell.doors.x and shell.doors.y and shell.doors.z and shell.doors.heading)
end
assert(registry.t1_unfurn_shell.doors.x == -43.758571624756)
assert(registry.t3_furn_shell.doors.heading == 181.03651428223)
print('custom shell definitions passed')
