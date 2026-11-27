local plt = require("luaplotlib")

test("boxplot component visibility defaults to visible", function()
  local fig = plt.figure()
  fig:boxplot({ 1, 2, 3, 4, 5 })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-showbox="true" data-showwhiskers="true" data-showcaps="true"')
  assert_contains(svg, '<rect class="box"')
  assert_contains(svg, 'class="box-whisker"')
  assert_contains(svg, 'class="box-cap"')
end)

test("boxplot components can be hidden independently", function()
  local fig = plt.figure()
  fig:boxplot({ 1, 2, 3, 4, 5, 20 }, {
    showbox = false, showwhiskers = false, showcaps = false,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-showbox="false" data-showwhiskers="false" data-showcaps="false"')
  assert_not_contains(svg, '<rect class="box"')
  assert_not_contains(svg, 'class="box-whisker"')
  assert_not_contains(svg, 'class="box-cap"')
  local scene = fig:to_scene().series[1]
  assert_equal(scene.showbox, false)
  assert_equal(scene.showwhiskers, false)
  assert_equal(scene.showcaps, false)
end)

test("boxplot visibility options validate booleans", function()
  local fig = plt.figure()
  assert_error("showbox must be a boolean", function()
    fig:boxplot({ 1, 2 }, { showbox = "no" })
  end)
end)
