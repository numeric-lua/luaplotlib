-- Minor tick subdivision example. Writes examples/output/minor-subdivisions.svg.
--
--   luajit examples/minor_subdivisions.lua

local script = (arg and arg[0]) or "examples/minor_subdivisions.lua"
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

local x, y = {}, {}
for index = 1, 161 do
  x[index] = (index - 1) * 4 * math.pi / 160
  y[index] = math.sin(x[index]) * math.exp(-0.08 * x[index])
end

local fig = plt.figure({ width = 820, height = 500 })
fig:plot(x, y, { label = "damped sine", color = "#1f77b4", linewidth = 2.5 })
fig:title("Four minor ticks per major interval")
fig:xlabel("x")
fig:ylabel("amplitude")
fig:minorticks(true, { subdivisions = 4 })
fig:grid(true, { minor = true })
fig:legend()

local path = root .. "/examples/output/minor-subdivisions.svg"
fig:savefig(path)
print("wrote " .. path)
