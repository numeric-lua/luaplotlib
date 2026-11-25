-- Quiver directions in screen space. Writes examples/output/quiver-uv.svg.
--
--   luajit examples/quiver_uv.lua

local script = (arg and arg[0]) or "examples/quiver_uv.lua"
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

local x, y, u, v = {}, {}, {}, {}
local index = 0
for row = 0, 3 do
  for column = 0, 5 do
    index = index + 1
    x[index] = column * 20 + 10
    y[index] = row * 0.25 + 0.125
    u[index] = 1
    v[index] = 0.5
  end
end

local fig = plt.figure({ width = 820, height = 460 })
fig:quiver(x, y, u, v, {
  angles = "uv",
  pivot = "middle",
  color = "#7c3aed",
  label = "screen-space vectors",
  max_arrows = 64,
})
fig:title("Quiver with uv angle projection")
fig:xlabel("x (wide data span)")
fig:ylabel("y (narrow data span)")
fig:xlim(0, 110)
fig:ylim(0, 1)
fig:grid(true, { alpha = 0.35 })
fig:legend({ loc = "upper right" })

local path = root .. "/examples/output/quiver-uv.svg"
fig:savefig(path)
print("wrote " .. path)
