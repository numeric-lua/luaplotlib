local plt = require("luaplotlib")

test("horizontal eventplot labels become x category ticks", function()
  local fig = plt.figure()
  fig:eventplot({ { 1, 2 }, { 3 } }, {
    orientation = "horizontal",
    lineoffsets = { 2, 4 },
    labels = { "fast", "slow" },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-labels="true"')
  assert_contains(svg, ">fast<")
  assert_contains(svg, ">slow<")
  local scene = fig:to_scene()
  assert_equal(scene.category_axis, "x")
  assert_equal(#scene.category_ticks, 2)
  assert_equal(scene.category_ticks[1].position, 2)
  assert_equal(scene.category_ticks[1].label, "fast")
  assert_equal(scene.category_ticks[2].position, 4)
  assert_equal(scene.series[1].labels[2], "slow")
end)

test("vertical eventplot labels become y category ticks", function()
  local fig = plt.figure()
  fig:eventplot({ { 1, 2 }, { 3 } }, {
    lineoffsets = { 5, 8 },
    labels = { "control", "treated" },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-orientation="vertical"')
  assert_contains(svg, 'data-labels="true"')
  assert_contains(svg, ">control<")
  assert_contains(svg, ">treated<")
  local scene = fig:to_scene()
  assert_equal(scene.category_axis, "y")
  assert_equal(scene.category_ticks[1].position, 5)
  assert_equal(scene.category_ticks[2].position, 8)
end)

test("eventplot labels validate row count and content", function()
  local fig = plt.figure()
  assert_error("one entry per row", function()
    fig:eventplot({ { 1 }, { 2 } }, { labels = { "only" } })
  end)
  assert_error("string or finite number", function()
    fig:eventplot({ { 1 }, { 2 } }, { labels = { "ok", {} } })
  end)
end)
