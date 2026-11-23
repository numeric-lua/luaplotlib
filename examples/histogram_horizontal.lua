-- Runnable horizontal histogram example. Writes
-- examples/output/histogram-horizontal.svg.
--
--   luajit examples/histogram_horizontal.lua

local script = (arg and arg[0]) or "examples/histogram_horizontal.lua"
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

local seed = 20261123
local function uniform()
  seed = (48271 * seed) % 2147483647
  return seed / 2147483647
end

local samples = {}
for i = 1, 1800 do
  local z = 0
  for _ = 1, 12 do z = z + uniform() end
  samples[i] = 0.25 + 1.05 * (z - 6)
end

local fig = plt.figure({ width = 820, height = 520 })
fig:hist(samples, {
  bins = 22,
  range = { -4, 4.5 },
  orientation = "horizontal",
  color = "#2ca02c",
  edgecolor = "#ffffff",
  alpha = 0.9,
  label = "1800 samples",
})
fig:title("luaplotlib: horizontal histogram")
fig:xlabel("count")
fig:ylabel("value")
fig:xlim(0, 240)
fig:grid(true, { axis = "x", alpha = 0.55 })
fig:legend({ loc = "upper right" })

local path = outdir .. "/histogram-horizontal.svg"
fig:savefig(path)
print("wrote " .. path)
