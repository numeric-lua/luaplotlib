local plt = require("luaplotlib")

test("polar bar accepts per-bar edge colors and widths", function()
  local fig = plt.figure({ width = 520, height = 520 })
  fig:polar_bar({ 0, 1, 2 }, { 1, 2, 3 }, {
    edgecolors = { "#ff0000", "#00ff00", "#0000ff" },
    linewidth = { 1, 2, 3 },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-edgecolors="true" data-linewidths="true"')
  assert_contains(svg, 'stroke="#ff0000"')
  assert_contains(svg, 'stroke="#0000ff"')
  local style = fig:to_scene().polar.series[1].style
  assert_equal(style.edgecolors[2], "#00ff00")
  assert_equal(style.linewidths[3], 3)
end)

test("polar bar edge arrays validate length and values", function()
  local fig = plt.figure({ width = 520, height = 520 })
  assert_error("one entry per bar", function()
    fig:polar_bar({ 0, 1 }, { 1, 2 }, { edgecolors = { "#fff" } })
  end)
  assert_error("linewidth%[2%] must be >= 0", function()
    fig:polar_bar({ 0, 1 }, { 1, 2 }, { linewidth = { 1, -1 } })
  end)
end)
