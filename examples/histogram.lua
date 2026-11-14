-- Runnable histogram example. Writes examples/output/histogram.svg.
--
--   luajit examples/histogram.lua
--
-- The SVG output path is gitignored.

local script = (arg and arg[0]) or "examples/histogram.lua"
local normalized = script:gsub("\\", "/")
local dir = normalized:match("^(.*)/[^/]+$") or "."
local root
if dir == "." then
  -- Invoked from inside examples/.
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

-- Deterministic, dependency-free pseudo-random normal-ish samples. Each sample
-- is the sum of 12 uniforms minus 6 (mean 0, standard deviation 1), then scaled
-- and shifted to look like a real measurement distribution.
local seed = 20261114
local function uniform()
  seed = (48271 * seed) % 2147483647
  return seed / 2147483647
end

local samples = {}
for i = 1, 2000 do
  local z = 0
  for _ = 1, 12 do
    z = z + uniform()
  end
  z = z - 6
  samples[i] = 0.25 + 1.1 * z
end

local fig = plt.figure({ width = 800, height = 500, dpi = 100 })
fig:hist(samples, {
  bins = 24,
  range = { -4, 4.5 },
  color = "#2ca02c",
  edgecolor = "#ffffff",
  alpha = 0.9,
  label = "2000 samples",
})
fig:title("luaplotlib: histogram")
fig:xlabel("value")
fig:ylabel("count")
fig:xlim(-4, 4.5)
fig:grid(true)
fig:legend({ loc = "upper right" })

local path = outdir .. "/histogram.svg"
fig:savefig(path)
print("wrote " .. path)
