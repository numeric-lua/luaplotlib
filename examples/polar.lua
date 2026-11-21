-- Runnable polar example. Writes examples/output/polar.svg.
--
--   luajit examples/polar.lua
--
-- The SVG output path is gitignored.

local script = (arg and arg[0]) or "examples/polar.lua"
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

local theta, radius = {}, {}
for i = 1, 181 do
  theta[i] = (i - 1) * 2 * math.pi / 180
  radius[i] = 3 + math.sin(4 * theta[i])
end

local fig = plt.figure({ width = 620, height = 620, dpi = 100 })
fig:polar(theta, radius, { label = "3 + sin(4*theta)", linewidth = 2.5 })

local mark_theta, mark_radius = {}, {}
for i = 1, 8 do
  mark_theta[i] = (i - 1) * 2 * math.pi / 8
  mark_radius[i] = 3 + math.sin(4 * mark_theta[i])
end
fig:polar_scatter(mark_theta, mark_radius, {
  color = "#d62728", size = 5, label = "samples",
})
fig:title("luaplotlib: polar plot")
fig:legend()
fig:savefig(outdir .. "/polar.svg")
print("wrote " .. outdir .. "/polar.svg")
