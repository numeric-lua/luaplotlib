local plt = require("luaplotlib")

local function polygon_count(svg, klass)
  return select(2, svg:gsub('class="' .. klass .. '"', ""))
end

local function polygon_points(svg, index)
  local count = 0
  for points in svg:gmatch('class="fill%-between"[^>]*points="([^"]*)"') do
    count = count + 1
    if count == index then return points end
  end
  return nil
end

test("where masks split fill_between into contiguous polygons", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:fill_between({ 1, 2, 3, 4, 5, 6 }, { 1, 2, 3, 4, 5, 6 },
    { 2, 3, 4, 5, 6, 7 }, {
      where = { true, true, false, false, true, true },
    })
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)
  assert_contains(svg, 'class="series series-fill"')
  assert_contains(svg, 'data-where="masked"')
  assert_contains(svg, 'data-interpolate="false"')
  assert_contains(svg, 'data-segments="2"')
  assert_equal(polygon_count(svg, "fill%-between"), 2)
  local first = assert(polygon_points(svg, 1))
  assert_equal(select(2, first:gsub("%S+", "")), 4,
    "two visible samples form a four-vertex band")
  local scene = fig:to_scene().series[1]
  assert_equal(#scene.segments, 2)
  assert_equal(scene.segments[1].x[1], 1)
  assert_equal(scene.segments[1].x[2], 2)
  assert_equal(scene.segments[2].x[1], 5)
  assert_equal(scene.segments[2].x[2], 6)
end)

test("interpolate adds midpoints at mask boundaries", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:fill_between({ 1, 2, 3, 4 }, { 1, 1, 1, 1 }, { 2, 2, 2, 2 }, {
    where = { false, true, true, false },
    interpolate = true,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-interpolate="true"')
  assert_contains(svg, 'data-segments="1"')
  local points = assert(polygon_points(svg, 1))
  assert_equal(select(2, points:gsub("%S+", "")), 8,
    "two samples plus two interpolated boundaries form eight vertices")
  local scene = fig:to_scene()
  local run = scene.series[1].segments[1]
  assert_equal(#run.x, 4)
  assert_equal(run.x[1], 1.5)
  assert_equal(run.x[2], 2)
  assert_equal(run.x[3], 3)
  assert_equal(run.x[4], 3.5)
  assert_equal(run.y1[1], 1)
  assert_equal(run.y2[4], 2)
end)

test("fill_betweenx masks and interpolates along y", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:fill_betweenx({ 1, 2, 3, 4, 5 }, { 1, 2, 3, 4, 5 },
    { 2, 3, 4, 5, 6 }, {
      where = { false, true, false, true, true },
      interpolate = true,
    })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="series series-fillx"')
  assert_contains(svg, 'data-segments="2"')
  assert_equal(polygon_count(svg, "fill%-betweenx"), 2)
  local scene = fig:to_scene().series[1]
  assert_equal(scene.kind, "fillx")
  assert_equal(#scene.segments, 2)
  assert_equal(scene.segments[1].y[1], 1.5,
    "first fillx run should start at an interpolated y boundary")
  assert_equal(scene.segments[1].x1[1], 1.5)
  assert_equal(scene.segments[1].y[3], 2.5,
    "single-sample run should gain a trailing interpolated boundary")
  assert_equal(scene.segments[2].y[1], 3.5,
    "second fillx run should start at an interpolated y boundary")
  assert_equal(scene.segments[2].y[#scene.segments[2].y], 5)
end)

test("masked fill extents ignore hidden samples", function()
  local fig = plt.figure()
  fig:fill_between({ 1, 2, 3, 4 }, { 10, 100, 1000, 10000 },
    { 11, 101, 1001, 10001 }, {
      where = { true, false, false, false },
    })
  local scene = fig:to_scene()
  assert_true(scene.ylim[2] < 200,
    "hidden high-valued samples must not drive the exported range")
  assert_true(scene.xlim[2] < 3,
    "hidden late samples must not drive the exported x range")
end)

test("an all-false mask draws no polygons but keeps the series", function()
  local fig = plt.figure()
  fig:fill_between({ 1, 2, 3 }, { 1, 2, 3 }, { 2, 3, 4 }, {
    where = { false, false, false },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-segments="0"')
  assert_equal(polygon_count(svg, "fill%-between"), 0)
  local scene = fig:to_scene()
  assert_equal(#scene.series[1].segments, 0)
  assert_equal(scene.series[1].where[2], false)
end)

test("fill masks validate shape and types", function()
  local fig = plt.figure()
  assert_error("one boolean per sample", function()
    fig:fill_between({ 1, 2, 3 }, { 1, 2, 3 }, { 2, 3, 4 },
      { where = { true, false } })
  end)
  assert_error("must be a boolean", function()
    fig:fill_between({ 1, 2 }, { 1, 2 }, { 2, 3 }, { where = { true, 1 } })
  end)
  assert_error("must be a table of booleans", function()
    fig:fill_between({ 1, 2 }, { 1, 2 }, { 2, 3 }, { where = "yes" })
  end)
  assert_error("interpolate must be a boolean", function()
    fig:fill_between({ 1, 2 }, { 1, 2 }, { 2, 3 },
      { where = { true, false }, interpolate = 1 })
  end)
  assert_error("one boolean per sample", function()
    fig:fill_betweenx({ 1, 2 }, { 1, 2 }, { 2, 3 }, { where = { true } })
  end)
end)
