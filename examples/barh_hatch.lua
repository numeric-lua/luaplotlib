-- Horizontal bars with a hatch pattern. Writes examples/output/barh-hatch.svg.
--
--   luajit examples/barh_hatch.lua

local script = (arg and arg[0]) or "examples/barh_hatch.lua"
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

local fig = plt.figure({ width = 820, height = 460 })
fig:barh({ "Design", "Build", "Verify", "Ship" }, { 8, 14, 9, 5 }, {
  color = "#4c78a8",
  edgecolor = "#1f2937",
  edgecolors = { "#1f2937", "#7c3aed", "#0f766e", "#b45309" },
  linewidth = { 1, 2, 3, 4 },
  hatch = "/",
  height = { 0.5, 0.8, 0.6, 0.9 },
  label = "effort",
})
fig:title("Horizontal bars with hatching")
fig:xlabel("effort")
fig:ylabel("phase")
fig:grid(true, { axis = "x", alpha = 0.35 })
fig:legend({ loc = "lower right" })

local path = root .. "/examples/output/barh-hatch.svg"
fig:savefig(path)
print("wrote " .. path)
