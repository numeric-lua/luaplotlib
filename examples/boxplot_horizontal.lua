-- Horizontal boxplot example. Writes examples/output/boxplot-horizontal.svg.
--
--   luajit examples/boxplot_horizontal.lua

local script = (arg and arg[0]) or "examples/boxplot_horizontal.lua"
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

local fig = plt.figure({ width = 820, height = 480 })
fig:boxplot({
  { 4.1, 4.4, 4.8, 5.0, 5.3, 5.7, 6.0, 6.4 },
  { 3.2, 3.8, 4.1, 4.6, 5.0, 5.4, 6.1, 8.9 },
  { 5.2, 5.5, 5.9, 6.2, 6.5, 6.8, 7.1, 7.6 },
}, {
  labels = { "control", "treatment", "follow-up" },
  orientation = "horizontal",
  color = "#9467bd",
  width = { 0.45, 0.62, 0.52 },
  showmeans = true,
  notch = true,
  whis = 1.0,
  showfliers = false,
})
fig:title("Horizontal box-and-whisker summary")
fig:xlabel("measured value")
fig:ylabel("cohort")
fig:grid(true, { axis = "x" })

local path = root .. "/examples/output/boxplot-horizontal.svg"
fig:savefig(path)
print("wrote " .. path)
