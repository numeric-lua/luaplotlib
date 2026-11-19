local plt = require("luaplotlib")

local matrix = {}
for row = 1, 8 do
  matrix[row] = {}
  for col = 1, 8 do
    matrix[row][col] = math.sin(row / 2) * math.cos(col / 2)
  end
end

local fig = plt.figure({ width = 720, height = 520 })
fig:imshow(matrix)
fig:title("Heatmap")
fig:savefig("examples/output/heatmap.svg")
print("examples/output/heatmap.svg")
