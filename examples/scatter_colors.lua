-- Runnable numeric-color scatter example. Writes examples/output/scatter-colors.svg.
--
--   luajit examples/scatter_colors.lua

local script = (arg and arg[0]) or "examples/scatter_colors.lua"
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

local outdir = root .. "/examples/output"
local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end
local mkdir_status = os.execute("mkdir -p " .. shell_quote(outdir))
if mkdir_status == nil or mkdir_status == false
    or (type(mkdir_status) == "number" and mkdir_status ~= 0) then
  error("could not create output directory: " .. outdir)
end

local x, y, c = {}, {}, {}
for index = 1, 260 do
  local t = index * 0.12
  local radius = 0.7 + t / 9
  x[index] = radius * math.cos(t)
  y[index] = radius * math.sin(t) + 0.25 * math.cos(t * 2.3)
  c[index] = math.sin(t * 1.7) + 0.35 * math.cos(t * 0.6)
end

local marker_names = { "circle", "square", "triangle", "diamond" }
local edge_names = { "#ffffff", "#0f172a" }
local markers, alphas, edges = {}, {}, {}
for index = 1, #x do
  markers[index] = marker_names[(index - 1) % #marker_names + 1]
  alphas[index] = 0.35 + 0.65 * (((index - 1) % 10) / 9)
  edges[index] = edge_names[(index - 1) % #edge_names + 1]
end

local fig = plt.figure({ width = 800, height = 540 })
fig:scatter(x, y, {
  c = c,
  vmin = -1.6,
  vmax = 1.6,
  size = 5.2,
  marker = markers,
  alpha = alphas,
  label = "phase-colored samples",
  colorbar = true,
  colorbar_label = "phase signal",
  colorbar_ticks = 5,
  edgecolor = edges,
  linewidth = 0.8,
})
fig:title("luaplotlib: numeric scatter colors")
fig:xlabel("x")
fig:ylabel("y")
fig:grid(true, { alpha = 0.35 })
fig:legend({ loc = "upper right" })

local path = outdir .. "/scatter-colors.svg"
fig:savefig(path)
print("wrote " .. path)
