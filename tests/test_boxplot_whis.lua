local plt = require("luaplotlib")

test("boxplot whisker multiplier and fliers are configurable", function()
  local values = { 1, 2, 3, 4, 5, 20 }
  local fig = plt.figure()
  fig:boxplot(values, { whis = 1.0 })
  local scene = fig:to_scene().series[1]
  assert_equal(scene.whis, 1.0)
  assert_equal(scene.showfliers, true)
  assert_true(#scene.outliers > 0)
  assert_contains(fig:to_svg(), 'class="box-outlier"')
end)

test("boxplot can hide fliers and excludes them from range", function()
  local fig = plt.figure()
  fig:boxplot({ 1, 2, 3, 4, 5, 100 }, { showfliers = false, whis = 0.5 })
  local svg = fig:to_svg()
  assert_not_contains(svg, "box-outlier")
  local exported = fig:to_scene()
  local scene = exported.series[1]
  assert_equal(scene.showfliers, false)
  assert_true(exported.ylim[2] < 100)
end)

test("boxplot whisker options validate", function()
  local fig = plt.figure()
  assert_error("whis must be >= 0", function()
    fig:boxplot({ 1, 2 }, { whis = -1 })
  end)
  assert_error("showfliers must be a boolean", function()
    fig:boxplot({ 1, 2 }, { showfliers = "no" })
  end)
end)
