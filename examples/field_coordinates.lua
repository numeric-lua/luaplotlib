-- Runnable field-coordinate examples. Writes:
--   examples/output/heatmap-extent.svg
--   examples/output/contour-coords.svg
--
-- The first figure maps a raster through a custom extent with a lower origin;
-- the second gives contour samples explicit x/y coordinates.
--
--   luajit examples/field_coordinates.lua

local script = (arg and arg[0]) or "examples/field_coordinates.lua"
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

-- A 6x9 field mapped onto longitude/latitude-like coordinates.
local field = {}
for row = 1, 6 do
  field[row] = {}
  for column = 1, 9 do
    field[row][column] = math.sin((column - 1) * 0.7) +
      0.6 * math.cos((row - 1) * 0.9)
  end
end

local raster = plt.figure({ width = 820, height = 520 })
raster:imshow(field, {
  extent = { 100, 280, 20, 70 },
  origin = "lower",
  colorbar = true,
  vmin = -1.5,
  vmax = 1.5,
  label = "field values",
})
raster:title("luaplotlib: imshow extent and lower origin")
raster:xlabel("longitude")
raster:ylabel("latitude")
raster:grid(false)

local raster_path = outdir .. "/heatmap-extent.svg"
raster:savefig(raster_path)
print("wrote " .. raster_path)

-- A Gaussian sampled on a non-uniform grid, contoured at explicit levels.
local rows, cols = 9, 13
local values = {}
for row = 1, rows do
  values[row] = {}
  for column = 1, cols do
    local x = -3 + (column - 1) * 0.5
    local y = -2 + (row - 1) * 0.5
    values[row][column] = math.exp(-(x * x + y * y) / 2.4)
  end
end
local xs, ys = {}, {}
for column = 1, cols do xs[column] = -3 + (column - 1) * 0.5 end
for row = 1, rows do ys[row] = -2 + (row - 1) * 0.5 end

local contour = plt.figure({ width = 820, height = 520 })
contour:contour(values, {
  x = xs,
  y = ys,
  levels = { 0.2, 0.4, 0.6, 0.8 },
  labels = true,
  color = "#2f5f8f",
})
contour:title("luaplotlib: contour x/y coordinates")
contour:xlabel("x")
contour:ylabel("y")
contour:grid(true, { alpha = 0.5 })

local contour_path = outdir .. "/contour-coords.svg"
contour:savefig(contour_path)
print("wrote " .. contour_path)
