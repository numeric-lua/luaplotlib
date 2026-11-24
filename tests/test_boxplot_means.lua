local plt = require("luaplotlib")

local function count(svg, pattern)
  return select(2, svg:gsub(pattern, ""))
end

test("boxplot means are opt-in and exported in the scene", function()
  local fig = plt.figure()
  fig:boxplot({ { 1, 2, 3, 4, 5 } })
  local svg = fig:to_svg()
  assert_not_contains(svg, "box-mean-marker")
  assert_not_contains(svg, "box-mean-line")
  local box = fig:to_scene().series[1]
  assert_equal(box.mean, 3)
  assert_equal(box.showmeans, false)
  assert_equal(box.meanline, false)
end)

test("boxplot showmeans draws a mean marker", function()
  local fig = plt.figure()
  fig:boxplot({ { 1, 2, 3, 4, 5 }, { 2, 4, 6 } }, { showmeans = true })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-showmeans="true"')
  assert_contains(svg, 'data-mean="3"')
  assert_equal(count(svg, 'class="box%-mean%-marker"'), 2)
  assert_equal(count(svg, 'class="box%-mean%-line"'), 0)
  local first = fig:to_scene().series[1]
  assert_equal(first.mean, 3)
  assert_equal(first.showmeans, true)
  assert_equal(first.meanline, false)
end)

test("boxplot meanline draws one dashed line per box", function()
  local fig = plt.figure()
  fig:boxplot({ { 1, 2, 3, 4, 5 } }, {
    orientation = "horizontal", showmeans = true, meanline = true,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-meanline="true"')
  assert_equal(count(svg, 'class="box%-mean%-line"'), 1)
  assert_equal(count(svg, 'class="box%-mean%-marker"'), 0)
  assert_contains(svg, 'stroke-dasharray="4 2"')
  local box = fig:to_scene().series[1]
  assert_equal(box.meanline, true)
  assert_equal(box.showmeans, true)
  assert_equal(box.orientation, "horizontal")
end)

test("boxplot mean options validate booleans", function()
  local fig = plt.figure()
  assert_error("boolean", function()
    fig:boxplot({ { 1, 2 } }, { showmeans = "yes" })
  end)
  assert_error("boolean", function()
    fig:boxplot({ { 1, 2 } }, { meanline = 1 })
  end)
end)
