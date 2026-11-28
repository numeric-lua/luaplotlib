-- Runnable line/scatter example. Writes examples/output/line.svg.
--
--   luajit examples/line.lua
--
-- The SVG output path is gitignored.

local script = (arg and arg[0]) or "examples/line.lua"
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

local x, sin_x, cos_x = {}, {}, {}
for i = 1, 121 do
  x[i] = (i - 1) * 2 * math.pi / 120
  sin_x[i] = math.sin(x[i])
  cos_x[i] = math.cos(x[i])
end

local fig = plt.figure({ width = 800, height = 500, dpi = 100 })
fig:plot(x, sin_x, {
  label = "sin(x)",
  color = "#1f77b4",
  linewidth = 2.5,
  marker = "circle",
  markersize = 4,
  markevery = 8,
  markerfacecolor = "#ffffff",
  markeredgecolor = "#1f77b4",
  markeredgewidth = 1.2,
})
fig:plot(x, cos_x, {
  label = "cos(x)",
  color = "#ff7f0e",
  linewidth = 2,
  linestyle = "dashed",
})
fig:title("luaplotlib: line plot", {
  fontsize = 20,
  color = "#0f172a",
  fontweight = "bold",
})
fig:xlabel("x (radians)", {
  labelpad = 10, fontsize = 15, color = "#334155",
  fontweight = "bold",
})
fig:ylabel("value", {
  labelpad = 8, fontsize = 15, color = "#334155",
  fontweight = "bold",
})
fig:xlim(0, 2 * math.pi)
fig:ylim(-1.25, 1.25)
fig:ticklabelsize(12)
fig:ticklabelcolor("#334155")
fig:minorticks(true)
fig:grid(true, { minor = true })
fig:legend({
  loc = "upper center",
  framealpha = 0.85,
  facecolor = "#f8fafc",
  edgecolor = "#94a3b8",
  borderpad = 11,
  handlelength = 26,
  fontsize = 13,
  title = "series",
  title_fontsize = 15,
  markerfirst = false,
})

local path = outdir .. "/line.svg"
fig:savefig(path)
print("wrote " .. path)
