local plt = require("luaplotlib")

local function box_groups(svg)
  local result = {}
  for tag in svg:gmatch('<g class="series series%-box"[^>]*>') do
    local attrs = {}
    for key, value in tag:gmatch('([%w:-]+)="([^"]*)"') do attrs[key] = value end
    result[#result + 1] = attrs
  end
  return result
end

test("boxplot defaults to vertical categories on x", function()
  local fig = plt.figure()
  fig:boxplot({ { 1, 2, 3, 4, 5 } }, { labels = { "A" } })
  local svg = fig:to_svg()
  assert_equal(#box_groups(svg), 1)
  assert_equal(box_groups(svg)[1]["data-orientation"], "vertical")
  assert_contains(svg, ">A<")
  local scene = fig:to_scene()
  assert_equal(scene.category_axis, "x")
  assert_equal(scene.series[1].orientation, "vertical")
end)

test("horizontal boxplot puts categories on y and values on x", function()
  local fig = plt.figure({ width = 700, height = 450 })
  fig:boxplot({ { 1, 2, 3, 4, 5 }, { 2, 3, 4, 5, 6 } }, {
    labels = { "alpha", "beta" }, orientation = "horizontal",
  })
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)
  assert_contains(svg, 'data-orientation="horizontal"')
  assert_contains(svg, ">alpha<")
  assert_contains(svg, ">beta<")
  assert_not_contains(svg, 'data-orientation="vertical"')
  local scene = fig:to_scene()
  assert_equal(scene.category_axis, "y")
  assert_equal(scene.series[1].orientation, "horizontal")
  assert_equal(scene.series[1].low, 1)
  assert_equal(scene.series[1].high, 5)
  assert_true(scene.xlim[1] <= 1 and scene.xlim[2] >= 6)
  assert_true(scene.ylim[1] <= 0.7 and scene.ylim[2] >= 2.3)
  for _, value in ipairs({ scene.xlim[1], scene.xlim[2],
      scene.ylim[1], scene.ylim[2] }) do
    assert_true(value == value and value ~= math.huge and value ~= -math.huge,
      "boxplot scene limits must be finite")
  end
end)

test("boxplot lower whisker reaches the lowest inlier", function()
  local fig = plt.figure()
  fig:boxplot({ 1, 2, 3, 4, 5, 20 })
  local box = fig:to_scene().series[1]
  assert_equal(box.low, 1)
  assert_equal(box.high, 5)
  assert_equal(#box.outliers, 1)
  assert_equal(box.outliers[1], 20)
end)

test("boxplot orientation validation rejects unknown values", function()
  local fig = plt.figure()
  assert_error("orientation must be 'vertical' or 'horizontal'", function()
    fig:boxplot({ { 1, 2 } }, { orientation = "sideways" })
  end)
end)
