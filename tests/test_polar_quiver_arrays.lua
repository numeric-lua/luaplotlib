local plt = require("luaplotlib")

test("polar quiver accepts per-vector colors and widths", function()
  local fig = plt.figure({ width = 520, height = 520 })
  fig:polar_quiver({ 0, 1, 2 }, { 2, 3, 4 }, { 1, 1, 1 }, { 1, 0, -1 }, {
    color = { "#ff0000", "#00ff00", "#0000ff" },
    linewidth = { 0.5, 1.5, 3 },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'stroke="#ff0000"')
  assert_contains(svg, 'stroke="#0000ff"')
  local style = fig:to_scene().polar.series[1].style
  assert_equal(style.colors[2], "#00ff00")
  assert_equal(style.linewidths[3], 3)
end)

test("polar quiver styling arrays validate length and values", function()
  local fig = plt.figure({ width = 520, height = 520 })
  assert_error("match the number of vectors", function()
    fig:polar_quiver({ 0, 1 }, { 1, 2 }, { 1, 1 }, { 1, 1 },
      { color = { "#fff" } })
  end)
  assert_error("linewidth%[2%] must be >= 0", function()
    fig:polar_quiver({ 0, 1 }, { 1, 2 }, { 1, 1 }, { 1, 1 },
      { linewidth = { 1, -1 } })
  end)
end)
