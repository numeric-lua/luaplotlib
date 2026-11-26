-- Runnable error-bar example. Writes examples/output/errorbar.svg.
--
--   luajit examples/errorbar.lua
--
-- The SVG output path is gitignored.

local script = (arg and arg[0]) or "examples/errorbar.lua"
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

local x = { 1, 2, 3, 4, 5, 6 }
local y = { 2.1, 3.8, 6.2, 7.9, 10.1, 12.2 }
local yerr = {
  lower = { 0.2, 0.3, 0.25, 0.4, 0.35, 0.3 },
  upper = { 0.45, 0.6, 0.5, 0.8, 0.7, 0.55 },
}
local xerr = {
  lower = { 0.08, 0.08, 0.08, 0.08, 0.08, 0.08 },
  upper = { 0.16, 0.16, 0.16, 0.16, 0.16, 0.16 },
}

local fig = plt.figure({ width = 800, height = 500 })
fig:errorbar(x, y, yerr, xerr, {
  label = "measurement",
  color = "#1f77b4",
  ecolor = {
    "#d62728", "#d62728", "#7c3aed", "#7c3aed", "#d62728", "#d62728",
  },
  capsize = 6,
  markersize = 5,
  markerfacecolor = "#ffffff",
  markeredgecolor = "#1f77b4",
  markeredgewidth = 1.2,
  errorevery = 2,
  lolims = { true, false, true, false, false, false },
  uplims = { false, false, false, false, true, false },
  xlolims = { true, false, false, false, false, false },
  xuplims = { false, false, false, false, true, false },
})
fig:title("luaplotlib: error bars")
fig:xlabel("sample")
fig:ylabel("value")
fig:grid(true)
fig:legend()

local path = outdir .. "/errorbar.svg"
fig:savefig(path)
print("wrote " .. path)
