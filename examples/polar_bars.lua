-- Runnable polar bar example. Writes examples/output/polar-bars.svg.
--
--   luajit examples/polar_bars.lua
--
-- The SVG output path is gitignored.

local script = (arg and arg[0]) or "examples/polar_bars.lua"
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

local sectors = 12
local theta, radius, colors = {}, {}, {}
local edge_colors, line_widths, alphas = {}, {}, {}
local palette = { "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728" }
local edges = { "#0c4a6e", "#7c2d12", "#14532d", "#7f1d1d" }
for i = 1, sectors do
  theta[i] = (i - 1) * 2 * math.pi / sectors
  radius[i] = 2 + 2 * math.abs(math.sin(2 * theta[i]))
  colors[i] = palette[(i - 1) % #palette + 1]
  edge_colors[i] = edges[(i - 1) % #edges + 1]
  line_widths[i] = 1 + ((i - 1) % 3)
  alphas[i] = 0.65 + 0.35 * ((i - 1) % 4) / 3
end

local fig = plt.figure({ width = 620, height = 620, dpi = 100 })
fig:polar_bar(theta, radius, {
  width = 2 * math.pi / sectors * 0.9,
  colors = colors,
  label = "radial bars",
  edgecolors = edge_colors,
  linewidth = line_widths,
  alpha = alphas,
})
fig:title("luaplotlib: polar bars")
fig:savefig(outdir .. "/polar-bars.svg")
print("wrote " .. outdir .. "/polar-bars.svg")
