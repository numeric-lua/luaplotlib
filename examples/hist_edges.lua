-- Histogram with explicit bin edges. Writes examples/output/hist-edges.svg.
--
--   luajit examples/hist_edges.lua

local script = (arg and arg[0]) or "examples/hist_edges.lua"
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

local values = {}
for index = 1, 260 do
  local u = ((index * 41) % 101) / 101
  local v = ((index * 67) % 97) / 97
  values[index] = 2 + 3 * u + 0.8 * math.sin(index * 0.3) + 0.4 * (v - 0.5)
end

local fig = plt.figure({ width = 800, height = 480 })
fig:hist(values, {
  bins = { 1, 2, 2.5, 3.5, 4, 6 },
  color = "#7c3aed",
  edgecolor = "#1e1b4b",
  edgecolors = { "#1e1b4b", "#7c3aed", "#0f766e", "#b45309", "#be123c" },
  linewidth = { 0.8, 1.2, 1.6, 2.0, 2.4 },
  hatch = ".",
  label = "custom bins",
})
fig:title("Histogram with explicit bin edges")
fig:xlabel("value")
fig:ylabel("count")
fig:grid(true, { axis = "y", alpha = 0.35 })
fig:legend({ loc = "upper right" })

local path = root .. "/examples/output/hist-edges.svg"
fig:savefig(path)
print("wrote " .. path)
