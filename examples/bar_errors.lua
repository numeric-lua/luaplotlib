-- Runnable bar error-bar example. Writes examples/output/bar-errors.svg.
--
--   luajit examples/bar_errors.lua

local script = (arg and arg[0]) or "examples/bar_errors.lua"
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

local fig = plt.figure({ width = 820, height = 520 })
fig:bar({ "Q1", "Q2", "Q3", "Q4" }, {
  { 12.0, 15.5, 14.0, 18.5 },
  { 9.5, 12.0, 11.5, 14.0 },
}, {
  labels = { "North", "South" },
  colors = { "#4c78a8", "#e45756" },
  yerr = {
    { 0.8, 1.1, 0.9, 1.4 },
    { lower = { 0.6, 0.5, 0.8, 0.7 }, upper = { 1.2, 1.4, 1.0, 1.5 } },
  },
  ecolor = "#1f2937",
  elinewidth = 1.3,
  capsize = 5,
  show_values = false,
})
fig:title("luaplotlib: bars with asymmetric errors")
fig:ylabel("score")
fig:ylim(0, 22)
fig:grid(true, { axis = "y", alpha = 0.35 })
fig:legend({ loc = "upper left", ncol = 2 })

local path = outdir .. "/bar-errors.svg"
fig:savefig(path)
print("wrote " .. path)
