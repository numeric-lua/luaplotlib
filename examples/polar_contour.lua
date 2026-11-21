-- Runnable polar contour example. Writes examples/output/polar-contour.svg.
--
--   luajit examples/polar_contour.lua
--
-- The SVG output path is gitignored.

local script = (arg and arg[0]) or "examples/polar_contour.lua"
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

-- A smooth angular/radial field: 18 radial bands and 48 angular sectors.
local radial_bands, angular_sectors = 18, 48
local values = {}
for row = 1, radial_bands do
  values[row] = {}
  local radius = 6 * row / radial_bands
  for col = 1, angular_sectors do
    local theta = (col - 0.5) * 2 * math.pi / angular_sectors
    values[row][col] = 0.8 * math.sin(3 * theta) +
      0.35 * math.cos(2 * theta) + 0.15 * math.sin(radius)
  end
end

local fig = plt.figure({ width = 700, height = 640, dpi = 100 })
fig:polar_config({ rmax = 6 })
fig:polar_heatmap(values, {
  label = "temperature anomaly",
  colorbar = true,
  colorbar_label = "anomaly",
  colorbar_ticks = 5,
})
fig:polar_contour(values, {
  levels = { -0.6, -0.2, 0.2, 0.6 },
  color = "#111111",
  linewidth = 1.4,
  labels = true,
  label = "isolines",
})
fig:title("luaplotlib: polar contours and colorbar")
fig:legend({ loc = "best" })
fig:savefig(outdir .. "/polar-contour.svg")
print("wrote " .. outdir .. "/polar-contour.svg")
