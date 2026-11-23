-- Runnable stackplot baseline example. Writes examples/output/stack-baseline.svg.
--
--   luajit examples/stack_baseline.lua

local script = (arg and arg[0]) or "examples/stack_baseline.lua"
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

local x = {}
local series = { {}, {}, {} }
for index = 1, 48 do
  local t = (index - 1) / 47
  x[index] = t * 6 * math.pi
  local wave = math.sin(t * 2 * math.pi)
  series[1][index] = 1.2 + 0.5 * wave + 0.25 * math.cos(t * 7)
  series[2][index] = 0.9 + 0.45 * math.sin(t * 3 * math.pi + 0.4)
  series[3][index] = 0.7 + 0.35 * math.cos(t * 4 * math.pi - 0.6)
end

local fig = plt.figure({ width = 860, height = 520 })
fig:stackplot(x, series, {
  labels = { "surface", "mid layer", "deep layer" },
  colors = { "#4c78a8", "#f58518", "#54a24b" },
  baseline = "wiggle",
  alpha = 0.78,
  edgecolor = "#ffffff",
})
fig:title("luaplotlib: wiggle stack baseline")
fig:xlabel("distance")
fig:ylabel("stacked amount")
fig:grid(true, { axis = "y", alpha = 0.35 })
fig:legend({ loc = "upper right", ncol = 3 })

local path = outdir .. "/stack-baseline.svg"
fig:savefig(path)
print("wrote " .. path)
