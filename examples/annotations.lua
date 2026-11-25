-- Runnable annotations example. Writes examples/output/annotations.svg.
--
--   luajit examples/annotations.lua
--
-- The SVG output path is gitignored.

local script = (arg and arg[0]) or "examples/annotations.lua"
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

local x, y = {}, {}
for i = 0, 20 do
  local value = i / 4
  x[#x + 1] = value
  y[#y + 1] = value * (5 - value) / 2
end

local fig = plt.figure({ width = 800, height = 500 })
fig:plot(x, y, { label = "x(5-x)/2", color = "#1f77b4", linewidth = 2.5 })
fig:annotate("maximum", 2.5, 3.125, {
  xytext = { 3.4, 4.2 },
  align = "center",
  color = "#333333",
  fontsize = 13,
  arrow = { color = "#d62728", linewidth = 1.5, head = 9 },
  backgroundcolor = "#ffffff",
  backgroundedgecolor = "#d62728",
  backgroundalpha = 0.9,
  backgroundpad = 4,
})
fig:annotate("smooth arc", 1.0, 2.0, {
  xytext = { 0.25, 0.35 },
  align = "left",
  color = "#555555",
  fontsize = 12,
  rotation = -12,
})
fig:title("luaplotlib: annotations and arrows")
fig:xlabel("x")
fig:ylabel("y")
fig:xlim(0, 5)
fig:ylim(-0.5, 5)
fig:grid(true)

local path = outdir .. "/annotations.svg"
fig:savefig(path)
print("wrote " .. path)
