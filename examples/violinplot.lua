-- Runnable violin-plot example. Writes examples/output/violinplot.svg.
--
--   luajit examples/violinplot.lua

local script = (arg and arg[0]) or "examples/violinplot.lua"
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

local samples = { {}, {}, {} }
for index = 1, 120 do
  local u = ((index * 43) % 101) / 101
  local v = ((index * 71) % 97) / 97
  samples[1][index] = 3.0 + 0.8 * math.sin(index * 0.31) +
    0.35 * math.cos(index * 1.7)
  samples[2][index] = 4.1 + 1.0 * math.cos(index * 0.23) +
    0.4 * math.sin(index * 1.3)
  samples[3][index] = 3.4 + 1.3 * (u - 0.5) + 0.5 * (v - 0.5)
end

local fig = plt.figure({ width = 820, height = 540 })
fig:violinplot(samples, {
  labels = { "control", "shifted", "wide" },
  colors = { "#4c78a8", "#f58518", "#54a24b" },
  width = 0.62,
  points = 80,
  alpha = 0.55,
  edgecolor = "#1f2937",
  linewidth = 1.2,
  showextrema = true,
  showmedians = true,
  showquartiles = true,
})
fig:title("luaplotlib: violin distributions")
fig:ylabel("measured value")
fig:grid(true, { axis = "y", alpha = 0.4 })
fig:legend({ loc = "upper right" })

local path = outdir .. "/violinplot.svg"
fig:savefig(path)
print("wrote " .. path)
