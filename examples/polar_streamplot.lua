-- Runnable polar streamplot example. Writes
-- examples/output/polar-streamplot.svg,
-- examples/output/polar-streamplot-styles.svg, and
-- examples/output/polar-streamplot-clip.svg.
--
--   luajit examples/polar_streamplot.lua
--
-- The SVG output paths are gitignored.

local script = (arg and arg[0]) or "examples/polar_streamplot.lua"
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

-- A vector field sampled at every (theta, r) grid node.  u is the local
-- tangential component (toward increasing theta) and v is the radial
-- component; streamlines are integrated through the interpolated field so
-- they curve with the flow.  The domain is a full turn, so it is treated as
-- periodic and the closed orbit near the middle is detected automatically.
local theta, r = {}, {}
for index = 1, 73 do
  theta[index] = (index - 1) * 2 * math.pi / 72
end
for index = 1, 25 do
  r[index] = 0.4 + (5.0 - 0.4) * (index - 1) / 24
end

local u, v = {}, {}
for row = 1, #r do
  u[row], v[row] = {}, {}
  for column = 1, #theta do
    local angle = theta[column]
    u[row][column] = 1.0 + 0.45 * math.cos(2 * angle) + 0.15 * r[row]
    v[row][column] = 0.5 * math.sin(3 * angle)
  end
end

local fig = plt.figure({ width = 640, height = 640, dpi = 100 })
fig:polar_config({ rmax = 5 })
fig:polar_streamplot(theta, r, u, v, {
  label = "integrated streamlines",
  color = "#1f77b4",
  linewidth = 1.4,
  density = 1.2,
  arrow_fraction = 0.5,
})
fig:title("luaplotlib: polar streamlines")
fig:legend({ loc = "best" })
fig:savefig(outdir .. "/polar-streamplot.svg")
print("wrote " .. outdir .. "/polar-streamplot.svg")

-- The same field with a non-solid line style.  Arrows are anchored by arc
-- length, so arrow_fraction = 0.65 places the glyphs later along each line
-- without changing the integration or the line counts.
local styled = plt.figure({ width = 640, height = 640, dpi = 100 })
styled:polar_config({ rmax = 5 })
styled:polar_streamplot(theta, r, u, v, {
  label = "dashed streamlines",
  color = "#d62728",
  linewidth = 1.5,
  density = 1.0,
  linestyle = "dashed",
  arrow_fraction = 0.65,
})
styled:title("luaplotlib: dashed streamlines")
styled:legend({ loc = "best" })
styled:savefig(outdir .. "/polar-streamplot-styles.svg")
print("wrote " .. outdir .. "/polar-streamplot-styles.svg")

-- A purely radial outward field with arrows anchored near the outer edge.
-- The triangular glyphs extend past the frame circle, so the renderer clips
-- their vertices to the polar circle and reports the count.  The shapes stay
-- inside the frame instead of relying on an SVG clip path that a scene
-- consumer could miss.
local radial_theta, radial_r = {}, {}
for index = 1, 37 do
  radial_theta[index] = (index - 1) * 2 * math.pi / 36
end
for index = 1, 5 do
  radial_r[index] = 1 + 4 * (index - 1) / 4
end
local radial_u, radial_v = {}, {}
for row = 1, #radial_r do
  radial_u[row], radial_v[row] = {}, {}
  for column = 1, #radial_theta do
    radial_u[row][column] = 0
    radial_v[row][column] = 1
  end
end

local clipped = plt.figure({ width = 640, height = 640, dpi = 100 })
clipped:polar_config({ rmax = 5 })
clipped:polar_streamplot(radial_theta, radial_r, radial_u, radial_v, {
  label = "outward flow",
  color = "#2ca02c",
  linewidth = 1.4,
  density = 1.0,
  arrow_fraction = 0.95,
  head = 24,
  step = 0.05,
})
clipped:title("luaplotlib: clipped boundary arrows")
clipped:legend({ loc = "best" })
clipped:savefig(outdir .. "/polar-streamplot-clip.svg")
print("wrote " .. outdir .. "/polar-streamplot-clip.svg")
