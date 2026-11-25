-- Pie with labels rotated along their slices. Writes
-- examples/output/pie-rotated.svg.
--
--   luajit examples/pie_rotated.lua

local script = (arg and arg[0]) or "examples/pie_rotated.lua"
local normalized = script:gsub("\\", "/")
local dir = normalized:match("^(.*)/[^/]+$") or "."
local root
if dir == "." then
  root = ".."
elseif dir == "examples" or dir == "./examples" then
  root = "."
elseif dir:match("/examples$") then
  root = dir:gsub("/examples$", "")
  if root == "" then root = "." end
else
  root = dir
end

package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
local plt = require("luaplotlib")

local fig = plt.figure({ width = 760, height = 520 })
fig:pie({ 31, 24, 21, 14, 10 }, {
  labels = { "Design", "Build", "Verify", "Ship", "Buffer" },
  startangle = 110,
  radius = 0.24,
  labeldistance = 1.16,
  rotatelabels = true,
  autopct = true,
})
fig:title("Rotated pie labels")

local path = root .. "/examples/output/pie-rotated.svg"
fig:savefig(path)
print("wrote " .. path)
