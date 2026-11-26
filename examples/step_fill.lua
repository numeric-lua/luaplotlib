-- Filled step plot. Writes examples/output/step-fill.svg.
--
--   luajit examples/step_fill.lua

local script = (arg and arg[0]) or "examples/step_fill.lua"
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

local x = { 1, 2, 3, 4, 5, 6, 7, 8 }
local y = { 2.0, 3.5, 3.0, 5.2, 4.4, 6.1, 5.3, 6.8 }

local fig = plt.figure({ width = 800, height = 460 })
fig:step(x, y, {
  where = "mid",
  fill = true,
  fillalpha = 0.28,
  color = "#0f766e",
  linewidth = 2.4,
  label = "throughput",
})
fig:title("Filled step series")
fig:xlabel("interval")
fig:ylabel("throughput")
fig:grid(true, { axis = "y", alpha = 0.35 })
fig:legend({ loc = "lower right" })

local path = root .. "/examples/output/step-fill.svg"
fig:savefig(path)
print("wrote " .. path)
