-- Image colorbar controls example. Writes
-- examples/output/imshow-colorbar.svg.
--
--   luajit examples/imshow_colorbar.lua

local script = (arg and arg[0]) or "examples/imshow_colorbar.lua"
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

local rows, cols = 18, 26
local matrix = {}
for row = 1, rows do
  matrix[row] = {}
  for col = 1, cols do
    local x = (col - 1) / (cols - 1)
    local y = (row - 1) / (rows - 1)
    matrix[row][col] = 0.5 + 0.5 * math.sin(6 * x) * math.cos(4 * y)
  end
end

local fig = plt.figure({ width = 820, height = 520 })
fig:imshow(matrix, {
  vmin = 0, vmax = 1,
  colorbar = true,
  colorbar_label = "response",
  colorbar_tick_values = { 0, 0.25, 0.5, 0.75, 1 },
})
fig:title("Image with explicit colorbar ticks")
fig:xlabel("column")
fig:ylabel("row")

local path = root .. "/examples/output/imshow-colorbar.svg"
fig:savefig(path)
print("wrote " .. path)
