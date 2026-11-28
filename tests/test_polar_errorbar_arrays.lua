local plt = require("luaplotlib")

test("polar errorbar accepts per-point styling arrays", function()
  local fig = plt.figure({ width = 520, height = 520 })
  fig:polar_errorbar({ 0, 1, 2 }, { 2, 3, 4 }, { 0.2, 0.3, 0.4 }, {
    ecolor = { "#ff0000", "#00ff00", "#0000ff" },
    markersize = { 3, 5, 7 },
    elinewidth = { 1, 2, 3 },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'stroke="#ff0000"')
  assert_contains(svg, 'stroke="#0000ff"')
  local scene = fig:to_scene().polar.series[1].style
  assert_equal(scene.ecolors[2], "#00ff00")
  assert_equal(scene.markersizes[3], 7)
  assert_equal(scene.elinewidths[2], 2)
end)

test("polar errorbar styling arrays validate length and values", function()
  local fig = plt.figure({ width = 520, height = 520 })
  assert_error("match the number of points", function()
    fig:polar_errorbar({ 0, 1 }, { 1, 2 }, 0.2,
      { ecolor = { "#fff" } })
  end)
  assert_error("markersize%[2%] must be >= 0.1", function()
    fig:polar_errorbar({ 0, 1 }, { 1, 2 }, 0.2,
      { markersize = { 4, 0 } })
  end)
end)
