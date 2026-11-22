-- Runnable clipped-reference-line example. Writes examples/output/axline.svg.
--
--   luajit examples/axline.lua
--
-- The SVG output path is gitignored.

local script = (arg and arg[0]) or "examples/axline.lua"
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

local fig = plt.figure({ width = 800, height = 500 })
fig:plot({ 0, 1, 2, 3, 4 }, { 0, 1.4, 2.1, 2.8, 4.2 }, {
  label = "samples",
  color = "#1f77b4",
  marker = "circle",
  markersize = 5,
})
fig:axline(0, 0, 1, 1, {
  label = "y = x",
  color = "#d62728",
  linestyle = "dashed",
  linewidth = 1.6,
})
fig:axline(0, 4, 1, 2, {
  label = "falling guide",
  color = "#2ca02c",
  linestyle = "dotted",
})
fig:axhline(2, { label = "target", color = "#9467bd" })
fig:axvline(2, { color = "#9467bd", label = "midpoint" })
fig:title("luaplotlib: clipped reference lines")
fig:xlabel("x")
fig:ylabel("value")
fig:xlim(-0.5, 4.5)
fig:ylim(-0.5, 5)
fig:minorticks(true)
fig:grid(true, { minor = true })
fig:ytick_rotation(30)
fig:legend({ loc = "upper left" })

local path = outdir .. "/axline.svg"
fig:savefig(path)
print("wrote " .. path)
