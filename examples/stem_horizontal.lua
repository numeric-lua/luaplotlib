-- Horizontal stem plot. Writes examples/output/stem-horizontal.svg.
--
--   luajit examples/stem_horizontal.lua

local script = (arg and arg[0]) or "examples/stem_horizontal.lua"
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

local positions = { 1, 2, 3, 4, 5, 6 }
local values = { 2.1, 3.8, 3.2, 4.6, 2.9, 4.1 }

local fig = plt.figure({ width = 800, height = 460 })
fig:stem(positions, values, {
  orientation = "horizontal",
  base = 0.5,
  color = "#0f766e",
  marker = "diamond",
  markerfacecolor = "#ffffff",
  markeredgecolor = "#0f766e",
  markeredgewidth = 1.3,
  linewidth = 1.6,
  label = "sample",
})
fig:title("Horizontal stems from a custom base")
fig:xlabel("measured value")
fig:ylabel("sample")
fig:xlim(0, 5.2)
fig:grid(true, { axis = "x", alpha = 0.35 })
fig:legend({ loc = "lower right" })

local path = root .. "/examples/output/stem-horizontal.svg"
fig:savefig(path)
print("wrote " .. path)
