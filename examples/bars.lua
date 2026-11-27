-- Runnable grouped and stacked bar example.
-- Writes examples/output/bars-grouped.svg and examples/output/bars-stacked.svg.
--
--   luajit examples/bars.lua
--
-- The SVG output paths are gitignored.

local script = (arg and arg[0]) or "examples/bars.lua"
local normalized = script:gsub("\\", "/")
local dir = normalized:match("^(.*)/[^/]+$") or "."
local root
if dir == "." then
  -- Invoked from inside examples/.
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

local outdir = root .. "/examples/output"
local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end
local mkdir_status = os.execute("mkdir -p " .. shell_quote(outdir))
if mkdir_status == nil or mkdir_status == false
    or (type(mkdir_status) == "number" and mkdir_status ~= 0) then
  error("could not create output directory: " .. outdir)
end

local quarters = { "Q1", "Q2", "Q3", "Q4" }
local product = { 14, 18, 16, 22 }
local services = { 9, 11, 13, 12 }
local adjustments = { 2, -3, -2, 4 }

local grouped = plt.figure({ width = 800, height = 500 })
grouped:bar(quarters, { product, services }, {
  labels = { "Product", "Services" },
  grouped = true,
  colors = { "#1f77b4", "#ff7f0e" },
  bar_colors = {
    { "#9ecae1", "#6baed6", "#4292c6", "#2171b5" },
    { "#fdae6b", "#fd8d3c", "#f16913", "#d94801" },
  },
  edgecolors = {
    { "#0c4a6e", "#075985", "#0369a1", "#0c4a6e" },
    { "#7c2d12", "#9a3412", "#c2410c", "#7c2d12" },
  },
})
grouped:title("luaplotlib: grouped bars")
grouped:xlabel("quarter")
grouped:ylabel("revenue")
grouped:grid(true)
grouped:legend({ loc = "upper left" })
local grouped_path = outdir .. "/bars-grouped.svg"
grouped:savefig(grouped_path)
print("wrote " .. grouped_path)

local stacked = plt.figure({ width = 800, height = 500 })
stacked:bar(quarters, { product, services, adjustments }, {
  labels = { "Product", "Services", "Adjustment" },
  stacked = true,
  colors = { "#1f77b4", "#ff7f0e", "#2ca02c" },
})
stacked:title("luaplotlib: stacked bars with a negative series")
stacked:xlabel("quarter")
stacked:ylabel("revenue")
stacked:grid(true)
stacked:legend({ loc = "upper left" })
local stacked_path = outdir .. "/bars-stacked.svg"
stacked:savefig(stacked_path)
print("wrote " .. stacked_path)
