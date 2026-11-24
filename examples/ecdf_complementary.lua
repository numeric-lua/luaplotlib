-- Complementary empirical CDF. Writes examples/output/ecdf-complementary.svg.
--
--   luajit examples/ecdf_complementary.lua

local script = (arg and arg[0]) or "examples/ecdf_complementary.lua"
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

local values = {}
local state = 17
for index = 1, 140 do
  state = (1103515245 * state + 12345) % 2147483648
  local u1 = (state / 2147483648) + 1e-12
  state = (1103515245 * state + 12345) % 2147483648
  local u2 = state / 2147483648
  local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
  values[index] = 5 + 1.4 * z
end

local fig = plt.figure({ width = 780, height = 480 })
fig:ecdf(values, {
  complementary = true,
  label = "P(X > x)",
  color = "#d62728",
  linewidth = 2.5,
})
fig:title("Complementary empirical CDF")
fig:xlabel("x")
fig:ylabel("exceedance probability")
fig:ylim(0, 1.05)
fig:grid(true, { axis = "y", alpha = 0.35 })
fig:legend({ loc = "upper right" })

local path = root .. "/examples/output/ecdf-complementary.svg"
fig:savefig(path)
print("wrote " .. path)
