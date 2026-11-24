-- Histogram step styles example. Writes examples/output/hist-styles.svg.
--
--   luajit examples/hist_styles.lua

local script = (arg and arg[0]) or "examples/hist_styles.lua"
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

local function normal(mean, sigma, count, seed)
  local values = {}
  local state = seed
  for index = 1, count do
    state = (1103515245 * state + 12345) % 2147483648
    local u1 = (state / 2147483648) + 1e-12
    state = (1103515245 * state + 12345) % 2147483648
    local u2 = state / 2147483648
    local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    values[index] = mean + sigma * z
  end
  return values
end

local first = normal(3.0, 0.8, 500, 7)
local second = normal(5.0, 1.0, 500, 19)

local fig = plt.figure({ width = 820, height = 500 })
fig:hist(first, {
  bins = 22, range = { 0, 9 }, histtype = "stepfilled",
  color = "#1f77b4", alpha = 0.45, label = "sample A (stepfilled)",
})
fig:hist(second, {
  bins = 22, range = { 0, 9 }, histtype = "step",
  color = "#ff7f0e", label = "sample B (step)",
})
fig:title("Histogram outline styles")
fig:xlabel("value")
fig:ylabel("count")
fig:grid(true, { axis = "y" })
fig:legend()

local path = root .. "/examples/output/hist-styles.svg"
fig:savefig(path)
print("wrote " .. path)
