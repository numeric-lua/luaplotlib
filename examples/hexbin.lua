-- Runnable hexagonal-binning example. Writes examples/output/hexbin.svg.
--
-- Demonstrates automatic count limits, minimum counts, a labeled colorbar, and
-- explicit colorbar ticks.
--
--   luajit examples/hexbin.lua

local script = (arg and arg[0]) or "examples/hexbin.lua"
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
for index = 1, 900 do
  local angle = index * 0.071
  local radius = 0.25 + 0.75 * ((index * 37) % 100) / 100
  x[index] = 2.4 * radius * math.cos(angle) + 0.15 * math.sin(index * 1.7)
  y[index] = 1.5 * radius * math.sin(angle) + 0.12 * math.cos(index * 2.3)
end

local fig = plt.figure({ width = 820, height = 540 })
fig:hexbin(x, y, {
  gridsize = 22,
  mincnt = 2,
  label = "sample density",
  colorbar = true,
  colorbar_label = "points per cell",
  colorbar_ticks = 5,
  norm = "log",
  edgecolor = "#ffffff",
  linewidth = 0.6,
  alpha = 0.95,
})
fig:title("luaplotlib: hexagonal binning")
fig:xlabel("x")
fig:ylabel("y")
fig:grid(false)

local path = outdir .. "/hexbin.svg"
fig:savefig(path)
print("wrote " .. path)
