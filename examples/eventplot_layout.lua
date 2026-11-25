-- Horizontal eventplot layout example. Writes
-- examples/output/eventplot-layout.svg.
--
--   luajit examples/eventplot_layout.lua

local script = (arg and arg[0]) or "examples/eventplot_layout.lua"
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
fig:eventplot({
  { 0.4, 1.1, 1.8, 2.7 },
  { 0.8, 1.4, 2.1, 2.9 },
  { 0.2, 1.6, 2.3, 2.5 },
}, {
  orientation = "horizontal",
  lineoffsets = { 1, 4, 7 },
  linelengths = { 0.7, 1.0, 0.55 },
  labels = { "fast", "nominal", "slow" },
  colors = { "#2ca02c", "#d62728", "#9467bd" },
  linewidth = 2.5,
  linestyle = "dashed",
  label = "events",
})
fig:title("Horizontal event lanes")
fig:xlabel("lane offset")
fig:ylabel("event coordinate")
fig:grid(true, { axis = "y" })
fig:legend({ loc = "lower right" })

local path = root .. "/examples/output/eventplot-layout.svg"
fig:savefig(path)
print("wrote " .. path)
