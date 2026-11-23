-- Runnable Cartesian vector-field example. Writes examples/output/quiver.svg.
--
-- Demonstrates data-coordinate quiver glyphs, automatic scaling, middle
-- pivots, decimation, and a legend swatch.
--
--   luajit examples/quiver.lua

local script = (arg and arg[0]) or "examples/quiver.lua"
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

local x, y, u, v = {}, {}, {}, {}
local index = 0
for row = 0, 6 do
  for column = 0, 8 do
    index = index + 1
    local px = -2 + column * 0.5
    local py = -1.5 + row * 0.5
    x[index] = px
    y[index] = py
    u[index] = -py
    v[index] = px
  end
end

local fig = plt.figure({ width = 820, height = 560 })
fig:quiver(x, y, u, v, {
  label = "rotation field",
  color = "#1f77b4",
  pivot = "middle",
  head = 6,
  max_arrows = 128,
})
fig:title("luaplotlib: Cartesian quiver")
fig:xlabel("x")
fig:ylabel("y")
fig:xlim(-2.4, 2.4)
fig:ylim(-1.9, 1.9)
fig:grid(true, { alpha = 0.55 })
fig:legend({ loc = "upper right" })

local path = outdir .. "/quiver.svg"
fig:savefig(path)
print("wrote " .. path)
