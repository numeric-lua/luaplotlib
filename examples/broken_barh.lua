-- Horizontal broken-bar schedule. Writes examples/output/broken-barh.svg.
--
--   luajit examples/broken_barh.lua

local script = (arg and arg[0]) or "examples/broken_barh.lua"
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

local fig = plt.figure({ width = 840, height = 460 })
fig:broken_barh({ { 0, 3 }, { 5, 2 }, { 8, 1.5 } }, { 3, 0.65 }, {
  color = "#4c78a8", label = "design", linewidth = 1.5,
})
fig:broken_barh({ { 2, 4 }, { 7, 3 } }, { 2, 0.65 }, {
  color = "#f58518", label = "build", linewidth = 1.5,
})
fig:broken_barh({ { 6, 2 }, { 9, 2 } }, { 1, 0.65 }, {
  color = "#54a24b", label = "verify", linewidth = 1.5,
})
fig:title("Project schedule", { loc = "right" })
fig:xlabel("week")
fig:ylabel("workstream")
fig:ylim(0.5, 3.8)
fig:grid(true, { axis = "x", alpha = 0.35 })
fig:legend({ loc = "lower right", ncol = 3 })

local path = root .. "/examples/output/broken-barh.svg"
fig:savefig(path)
print("wrote " .. path)
