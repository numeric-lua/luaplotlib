-- Configurable bar outline width. Writes examples/output/bar-linewidth.svg.
--
--   luajit examples/bar_linewidth.lua

local script = (arg and arg[0]) or "examples/bar_linewidth.lua"
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

local fig = plt.figure({ width = 820, height = 500 })
fig:bar({ "Q1", "Q2", "Q3", "Q4" }, {
  { 12, 15, 14, 18 },
  { 9, 12, 11, 14 },
}, {
  labels = { "North", "South" },
  colors = { "#4c78a8", "#f58518" },
  edgecolor = "#1f2937",
  linewidth = 3,
  grouped = true,
})
fig:title("Bars with a three-pixel outline")
fig:ylabel("score")
fig:ylim(0, 21)
fig:grid(true, { axis = "y", alpha = 0.35 })
fig:legend({ loc = "upper left", ncol = 2 })

local path = root .. "/examples/output/bar-linewidth.svg"
fig:savefig(path)
print("wrote " .. path)
