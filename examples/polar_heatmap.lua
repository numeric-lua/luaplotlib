-- Runnable polar heatmap example. Writes examples/output/polar-heatmap.svg.
--
--   luajit examples/polar_heatmap.lua
--
-- The SVG output path is gitignored.

local script = (arg and arg[0]) or "examples/polar_heatmap.lua"
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

-- A smooth radial/angular field: 12 radial bands and 36 angular sectors.
local radial_bands, angular_sectors = 12, 36
local values = {}
for row = 1, radial_bands do
  values[row] = {}
  local radius = 6 * row / radial_bands
  for col = 1, angular_sectors do
    local theta = (col - 0.5) * 2 * math.pi / angular_sectors
    values[row][col] = 0.9 * math.sin(3 * theta) * radius / 6 +
      0.45 * math.cos(2 * theta) + 0.08 * radius
  end
end

local fig = plt.figure({ width = 640, height = 640, dpi = 100 })
fig:polar_config({ rmax = 6 })
fig:polar_heatmap(values, {
  label = "projected temperature field",
})

-- An analytic ridge drawn over the projected field.  Polar series render
-- above heatmap cells, so this stays visible.
local ridge_theta, ridge_radius = {}, {}
for index = 1, 180 do
  local theta = (index - 1) * 2 * math.pi / 180
  ridge_theta[index] = theta
  ridge_radius[index] = 3.1 + 0.7 * math.sin(3 * theta)
end
fig:polar(ridge_theta, ridge_radius, {
  color = "#111111",
  linewidth = 2,
  label = "ridge 3.1 + 0.7 sin(3 theta)",
})

fig:polar_annotate("warm ridge", 1.1, 3.6, {
  xytext = { 1.7, 5.4 },
  color = "#111111",
  fontsize = 12,
  arrow = { color = "#111111", linewidth = 1.5, head = 8 },
})

fig:title("luaplotlib: polar heatmap projection")
fig:legend({ loc = "best" })
fig:savefig(outdir .. "/polar-heatmap.svg")
print("wrote " .. outdir .. "/polar-heatmap.svg")
