-- Runnable polar quiver example. Writes examples/output/polar-quiver.svg.
--
--   luajit examples/polar_quiver.lua
--
-- The SVG output path is gitignored.

local script = (arg and arg[0]) or "examples/polar_quiver.lua"
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

-- A vector field sampled on a polar grid.  u is the tangential component
-- (toward increasing theta) and v is the radial component; the renderer
-- projects both into the local arrow direction.  This field combines a swirl
-- with a weak two-lobed radial inflow/outflow.  The inner radius leaves the
-- center of the axes clear so the arrows do not crowd the radial tick labels.
local rings, sectors = 8, 20
local theta, r, u, v = {}, {}, {}, {}
local arrow_colors, arrow_widths = {}, {}
for ring = 1, rings do
  local radius = 1.5 + (5.2 - 1.5) * (ring - 1) / (rings - 1)
  for sector = 1, sectors do
    local angle = (sector - 1) * 2 * math.pi / sectors
    local index = #theta + 1
    theta[index] = angle
    r[index] = radius
    u[index] = 0.55 + 0.3 * math.sin(3 * angle)
    v[index] = 0.4 * math.cos(2 * angle) * (radius / 6)
    arrow_colors[index] = sector % 2 == 0 and "#1f77b4" or "#f28e2b"
    arrow_widths[index] = 0.8 + 0.15 * (ring % 3)
  end
end

local fig = plt.figure({ width = 640, height = 640, dpi = 100 })
fig:polar_config({ rmax = 6 })
fig:polar_quiver(theta, r, u, v, {
  label = "swirling vector field",
  color = arrow_colors,
  linewidth = arrow_widths,
  head = 5,
})
fig:title("luaplotlib: polar quiver vector field")
fig:legend({ loc = "best" })
fig:savefig(outdir .. "/polar-quiver.svg")
print("wrote " .. outdir .. "/polar-quiver.svg")
