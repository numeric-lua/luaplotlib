-- Runnable styled stem example. Writes examples/output/stem.svg.
--
--   luajit examples/stem.lua

local script = (arg and arg[0]) or "examples/stem.lua"
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

local x, y = {}, {}
for i = 1, 10 do
  x[i] = i
  y[i] = 4.5 * math.exp(-(i - 1) / 5) + 0.35 * math.sin(i)
end

local fig = plt.figure({ width = 800, height = 500 })
fig:stem(x, y, {
  base = 0.5,
  marker = "diamond",
  markersize = 5,
  linewidth = 1.6,
  linestyle = "dashed",
  color = "#8c564b",
  label = "samples",
})
fig:title("luaplotlib: styled stems")
fig:xlabel("sample")
fig:ylabel("value")
fig:ylim(-0.5, 5.5)
fig:grid(true, { alpha = 0.5 })
fig:legend({ loc = "upper right" })

local path = outdir .. "/stem.svg"
fig:savefig(path)
print("wrote " .. path)
