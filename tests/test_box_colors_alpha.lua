local plt = require("luaplotlib")

test("boxplot accepts per-sample colors and alpha", function()
  local fig = plt.figure()
  fig:boxplot({ { 1, 2, 3 }, { 2, 3, 4 }, { 3, 4, 5 } }, {
    colors = { "#ff0000", "#00ff00", "#0000ff" },
    alpha = { 0.4, 0.7, 1 },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'stroke="#ff0000"')
  assert_contains(svg, 'fill-opacity="0.175"')
  assert_contains(svg, 'stroke="#0000ff"')
  local scene = fig:to_scene()
  assert_equal(scene.series[2].style.color, "#00ff00")
  assert_equal(scene.series[2].style.alpha, 0.7)
end)

test("boxplot color and alpha arrays validate length and values", function()
  local fig = plt.figure()
  assert_error("one entry per sample", function()
    fig:boxplot({ { 1, 2 }, { 2, 3 } }, { colors = { "#fff" } })
  end)
  assert_error("one entry per sample", function()
    fig:boxplot({ { 1, 2 }, { 2, 3 } }, { alpha = { 1 } })
  end)
  assert_error("alpha%[2%] must be <= 1", function()
    fig:boxplot({ { 1, 2 }, { 2, 3 } }, { alpha = { 1, 2 } })
  end)
end)
