local plt = require("luaplotlib")

local fig, axes = plt.subplots(2, 2, {
  width = 860, height = 620, title = "Subplots",
})
local x = {}
for i = 1, 40 do x[i] = (i - 1) / 10 end
axes[1][1]:plot(x, x, { label = "linear" })
axes[1][1]:title("line")
axes[1][2]:scatter(x, x, { color = "#ff7f0e" })
axes[1][2]:title("scatter")
axes[2][1]:bar({ "a", "b", "c" }, { 3, 5, 2 })
axes[2][1]:title("bars")
axes[2][2]:imshow({ { 0, 1 }, { 1, 0 } })
axes[2][2]:title("heatmap")
fig:savefig("examples/output/subplots.svg")
print("examples/output/subplots.svg")
