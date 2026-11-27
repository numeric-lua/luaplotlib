-- Horizontal violin plot. Writes examples/output/violin-horizontal.svg.
--
--   luajit examples/violin_horizontal.lua

local script = (arg and arg[0]) or "examples/violin_horizontal.lua"
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

local samples = { {}, {}, {} }
for index = 1, 100 do
  local u = ((index * 37) % 97) / 97
  local v = ((index * 53) % 89) / 89
  samples[1][index] = 3.0 + 0.8 * math.sin(index * 0.2) + 0.3 * (u - 0.5)
  samples[2][index] = 4.2 + 1.0 * math.cos(index * 0.17) + 0.4 * (v - 0.5)
  samples[3][index] = 3.6 + 1.2 * (u - 0.5) + 0.4 * (v - 0.5)
end

local fig = plt.figure({ width = 820, height = 480 })
fig:violinplot(samples, {
  orientation = "horizontal",
  labels = { "control", "shifted", "wide" },
  colors = { "#4c78a8", "#f58518", "#54a24b" },
  width = { 0.55, 0.68, 0.60 },
  points = 70,
  alpha = 0.55,
  edgecolor = "#1f2937",
  linewidth = 1.2,
  showmedians = true,
  showquartiles = true,
  showmeans = true,
})
fig:title("Horizontal violin distributions")
fig:xlabel("measured value")
fig:ylabel("cohort")
fig:grid(true, { axis = "x", alpha = 0.35 })
fig:legend({ loc = "lower right" })

local path = root .. "/examples/output/violin-horizontal.svg"
fig:savefig(path)
print("wrote " .. path)
