-- Exploded pie with a soft shadow. Writes examples/output/pie-explode.svg.
--
--   luajit examples/pie_explode.lua

local script = (arg and arg[0]) or "examples/pie_explode.lua"
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
fig:pie({ 34, 26, 22, 18 }, {
  labels = { "Design", "Build", "Verify", "Ship" },
  colors = { "#4c78a8", "#f58518", "#54a24b", "#b279a2" },
  startangle = 90,
  radius = 0.24,
  explode = { 0.08, 0.04, 0.0, 0.12 },
  shadow = true,
  autopct = true,
  labeldistance = 1.14,
  pctdistance = 0.55,
})
fig:title("Effort by phase")

local path = root .. "/examples/output/pie-explode.svg"
fig:savefig(path)
print("wrote " .. path)
