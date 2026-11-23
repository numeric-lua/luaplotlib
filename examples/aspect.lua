-- Runnable aspect-ratio example. Writes examples/output/aspect.svg.
--
-- Equal data units make the unit circle round instead of filling the
-- rectangular canvas.  The plot box is centered inside the normal margins.
--
--   luajit examples/aspect.lua

local script = (arg and arg[0]) or "examples/aspect.lua"
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
for index = 1, 181 do
  local angle = (index - 1) * 2 * math.pi / 180
  x[index] = math.cos(angle)
  y[index] = math.sin(angle)
end

local fig = plt.figure({ width = 760, height = 560 })
fig:plot(x, y, {
  color = "#1f77b4", linewidth = 2.5, label = "unit circle",
})
fig:axhline(0, { color = "#888888", linewidth = 1, linestyle = "dashed" })
fig:axvline(0, { color = "#888888", linewidth = 1, linestyle = "dashed" })
fig:title("luaplotlib: equal aspect")
fig:xlabel("x")
fig:ylabel("y")
fig:xlim(-1.25, 1.25)
fig:ylim(-1.25, 1.25)
fig:aspect("equal")
fig:grid(true, { alpha = 0.45 })
fig:legend({ loc = "upper right" })

local path = outdir .. "/aspect.svg"
fig:savefig(path)
print("wrote " .. path)
