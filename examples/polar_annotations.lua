-- Runnable polar annotations and error-bar example.
-- Writes examples/output/polar-annotations.svg.
--
--   luajit examples/polar_annotations.lua
--
-- The SVG output path is gitignored.

local script = (arg and arg[0]) or "examples/polar_annotations.lua"
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

local theta, radius = {}, {}
for i = 1, 181 do
  theta[i] = (i - 1) * 2 * math.pi / 180
  radius[i] = 3 + math.sin(4 * theta[i])
end

local fig = plt.figure({ width = 620, height = 620, dpi = 100 })
fig:polar(theta, radius, { label = "3 + sin(4*theta)", linewidth = 2.5 })

-- Radial and angular uncertainty at three sampled angles.
local marks = { 0, math.pi / 4, math.pi / 2 }
local values = { 3.5, 3.8, 4.2 }
fig:polar_errorbar(marks, values, { 0.35, 0.4, 0.3 }, {
  thetaerr = { 0.12, 0.1, 0.15 },
  ecolor = { "#555555", "#7c3aed", "#0f766e" },
  markersize = { 3, 5, 7 },
  elinewidth = { 1, 2, 3 },
  capsize = 5,
  label = "uncertainty",
})

fig:polar_annotate("maximum", math.pi / 2, 4.2, {
  xytext = { 1.85, 5.3 },
  align = "center",
  color = "#d62728",
  fontsize = 13,
  arrow = { color = "#d62728", linewidth = 1.5, head = 9 },
})

fig:title("luaplotlib: polar annotations and error bars")
fig:legend({ loc = "best" })
fig:savefig(outdir .. "/polar-annotations.svg")
print("wrote " .. outdir .. "/polar-annotations.svg")
