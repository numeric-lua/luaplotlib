local plt = require("luaplotlib")

local function shape_counts(svg)
  return {
    circles = select(2, svg:gsub('<circle class="point"', "")),
    rects = select(2, svg:gsub('<rect class="point"', "")),
    polygons = select(2, svg:gsub('<polygon class="point"', "")),
  }
end

test("cartesian scatter supports one marker per point", function()
  local fig = plt.figure()
  fig:scatter({ 1, 2, 3, 4 }, { 1, 2, 3, 4 }, {
    marker = { "circle", "square", "triangle", "diamond" },
  })
  local shapes = shape_counts(fig:to_svg())
  assert_equal(shapes.circles, 1)
  assert_equal(shapes.rects, 1)
  assert_equal(shapes.polygons, 2)
  local markers = fig:to_scene().series[1].style.markers
  assert_equal(#markers, 4)
  assert_equal(markers[2], "square")
  assert_equal(markers[4], "diamond")
end)

test("polar scatter supports one marker per point", function()
  local fig = plt.figure({ width = 480, height = 480 })
  fig:polar_scatter({ 0, 1, 2 }, { 1, 2, 3 }, {
    marker = { "circle", "square", "triangle" },
  })
  local shapes = shape_counts(fig:to_svg())
  assert_equal(shapes.circles, 1)
  assert_equal(shapes.rects, 1)
  assert_equal(shapes.polygons, 1)
  local markers = fig:to_scene().polar.series[1].style.markers
  assert_equal(markers[3], "triangle")
end)

test("scatter marker arrays validate length and entries", function()
  local fig = plt.figure()
  assert_error("match the number of points", function()
    fig:scatter({ 1, 2 }, { 1, 2 }, { marker = { "circle" } })
  end)
  assert_error("must be a marker name or true", function()
    fig:scatter({ 1, 2 }, { 1, 2 }, { marker = { "circle", false } })
  end)
  assert_error("marker must be circle", function()
    fig:polar_scatter({ 0, 1 }, { 1, 2 }, { marker = { "circle", "star" } })
  end)
end)
