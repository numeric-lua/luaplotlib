-- Runnable Cartesian controls example. Writes examples/output/cartesian-controls.svg.
--
-- Demonstrates fractional reference spans, a masked fill band with
-- interpolated mask boundaries, and independent major/minor grid styling.
--
--   luajit examples/cartesian_controls.lua

local script = (arg and arg[0]) or "examples/cartesian_controls.lua"
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

local x, signal, lower, upper, mask = {}, {}, {}, {}, {}
for i = 1, 181 do
  local value = (i - 1) * 2 * math.pi / 180
  x[i] = value
  signal[i] = math.sin(value) + 0.15 * math.cos(4 * value)
  lower[i] = signal[i] - 0.28
  upper[i] = signal[i] + 0.28
  mask[i] = math.sin(3 * value) > 0
end

local fig = plt.figure({ width = 860, height = 520 })
fig:fill_between(x, lower, upper, {
  where = mask,
  interpolate = true,
  color = "#4c78a8",
  edgecolor = "#2f5f8f",
  alpha = 0.32,
  label = "active band",
})
fig:plot(x, signal, {
  color = "#1f77b4",
  linewidth = 2.2,
  label = "signal",
})
fig:axhline(0.75, {
  xmin = 0.06,
  xmax = 0.40,
  color = "#d62728",
  linewidth = 1.6,
  label = "partial target",
})
fig:axvline(4.2, {
  ymin = 0.18,
  ymax = 0.82,
  color = "#9467bd",
  linewidth = 1.6,
  linestyle = "dotted",
  label = "phase marker",
})
fig:title("luaplotlib: Cartesian controls")
fig:xlabel("x (radians)")
fig:ylabel("value")
fig:xlim(0, 2 * math.pi)
fig:ylim(-1.5, 1.5)
fig:grid(true, {
  color = "#cbd5e1",
  linewidth = 1,
  alpha = 0.75,
  minor = true,
  minor_color = "#e2e8f0",
  minor_linewidth = 0.6,
  minor_linestyle = "dotted",
  minor_alpha = 0.4,
})
fig:minorticks(true)
fig:legend({ loc = "upper right", ncol = 2 })

local path = outdir .. "/cartesian-controls.svg"
fig:savefig(path)
print("wrote " .. path)
