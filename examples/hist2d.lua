-- Runnable rectangular 2-D histogram example. Writes examples/output/hist2d.svg.
--
--   luajit examples/hist2d.lua

local script = (arg and arg[0]) or "examples/hist2d.lua"
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

local x, y = {}, {}
for index = 1, 2400 do
  local u = ((index * 37) % 997) / 997
  local v = ((index * 101) % 991) / 991
  local radius = math.sqrt(-2 * math.log(0.02 + 0.96 * u))
  local angle = 2 * math.pi * v
  local cluster = index % 2 == 0 and 1.0 or -1.1
  x[index] = cluster + 0.85 * radius * math.cos(angle)
  y[index] = 0.55 * radius * math.sin(angle) + 0.25 * cluster
end

local x_edges, y_edges = {}, {}
for index = 0, 26 do x_edges[index + 1] = -3.5 + 7 * index / 26 end
for index = 0, 18 do y_edges[index + 1] = -2.5 + 5 * index / 18 end

local fig = plt.figure({ width = 840, height = 540 })
fig:hist2d(x, y, {
  bins = { x_edges, y_edges },
  label = "sample density",
  colorbar = true,
  colorbar_label = "samples per bin",
  colorbar_ticks = 5,
  color_norm = "log",
  show_empty = true,
  edgecolor = "#f8fafc",
  linewidth = 0.45,
  alpha = 0.96,
})
fig:title("luaplotlib: rectangular 2-D histogram")
fig:xlabel("x")
fig:ylabel("y")
fig:grid(false)

local path = outdir .. "/hist2d.svg"
fig:savefig(path)
print("wrote " .. path)
