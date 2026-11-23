local plt = require("luaplotlib")

test("imshow maps cells through an extent and lower origin", function()
  local fig = plt.figure({ width = 640, height = 440 })
  fig:imshow({ { 1, 2, 3 }, { 4, 5, 6 } }, {
    extent = { 10, 40, 100, 300 }, origin = "lower", colorbar = false,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="heatmap" data-origin="lower" data-extent="10,40,100,300"')
  assert_equal(count_occurrences(svg, 'class="heatmap-cell"'), 6)
  assert_contains(svg, 'data-row="1" data-col="1"')
  assert_not_contains(svg, 'class="colorbar"')
  assert_well_formed_svg(svg)

  local scene = fig:to_scene()
  local exported = scene.series[1]
  assert_equal(exported.kind, "image")
  assert_equal(exported.origin, "lower")
  assert_equal(exported.extent[1], 10)
  assert_equal(exported.extent[2], 40)
  assert_equal(exported.extent[3], 100)
  assert_equal(exported.extent[4], 300)
  assert_true(scene.xlim[1] < 10)
  assert_true(scene.xlim[2] > 40)
  assert_true(scene.ylim[1] < 100)
  assert_true(scene.ylim[2] > 300)
end)

test("imshow default output keeps the legacy index geometry", function()
  local fig = plt.figure({ width = 500, height = 360 })
  fig:imshow({ { 1, 2 }, { 3, 4 } }, { colorbar = false })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="heatmap"')
  assert_not_contains(svg, 'data-extent=')
  assert_not_contains(svg, 'data-origin=')
  assert_not_contains(svg, 'data-row=')
  local scene = fig:to_scene()
  assert_equal(scene.series[1].origin, "upper")
  assert_equal(scene.series[1].extent, nil)
  assert_equal(scene.xlim[1], -0.1)
  assert_equal(scene.xlim[2], 2.1)
end)

test("imshow lower origin flips rows without an explicit extent", function()
  local fig = plt.figure({ width = 500, height = 360 })
  fig:imshow({ { 1, 2 }, { 3, 4 } }, { origin = "lower", colorbar = false })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="heatmap" data-origin="lower" data-extent="0,2,0,2"')
  local row1_y, row2_y
  local row = 0
  for y in svg:gmatch('<rect class="heatmap%-cell" x="[^"]*" y="([%d%.%-]+)"') do
    row = row + 1
    if row == 1 then row1_y = tonumber(y) end
    if row == 3 then row2_y = tonumber(y) end
  end
  assert_true(row1_y ~= nil and row2_y ~= nil)
  assert_true(row1_y > row2_y,
    "origin lower should place row 1 below row 2")
end)

test("pcolormesh and pcolor accept image extents", function()
  local first = plt.figure()
  first:pcolormesh({ { 1, 2 }, { 3, 4 } }, {
    extent = { -2, 2, 5, 9 }, origin = "lower", colorbar = false,
  })
  assert_contains(first:to_svg(), 'data-extent="-2,2,5,9"')
  local second = plt.figure()
  second:pcolor({ { 1, 2 }, { 3, 4 } }, {
    extent = { 0, 4, 0, 8 }, colorbar = false,
  })
  assert_contains(second:to_svg(), 'data-origin="upper" data-extent="0,4,0,8"')
end)

test("imshow validates extent and origin", function()
  local fig = plt.figure()
  assert_error("extent must be", function()
    fig:imshow({ { 1 } }, { extent = { 0, 1, 0 } })
  end)
  assert_error("right must be greater", function()
    fig:imshow({ { 1 } }, { extent = { 1, 1, 0, 1 } })
  end)
  assert_error("top must be greater", function()
    fig:imshow({ { 1 } }, { extent = { 0, 1, 2, 2 } })
  end)
  assert_error("origin", function()
    fig:imshow({ { 1 } }, { origin = "middle" })
  end)
end)

test("contour accepts explicit x and y coordinate grids", function()
  local values = {
    { 0, 1, 0 },
    { 1, 3, 1 },
    { 0, 1, 0 },
  }
  local fig = plt.figure({ width = 640, height = 440 })
  fig:contour(values, {
    levels = { 1.5 }, color = "#d62728",
    x = { 10, 20, 30 }, y = { 100, 200, 300 },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="contour"')
  assert_true(count_occurrences(svg, 'class="contour-segment"') > 0)
  assert_well_formed_svg(svg)

  local scene = fig:to_scene()
  local exported = scene.series[1]
  assert_equal(exported.kind, "contour")
  assert_equal(exported.x[1], 10)
  assert_equal(exported.x[3], 30)
  assert_equal(exported.y[1], 100)
  assert_equal(exported.y[3], 300)
  assert_equal(exported.level, 1.5)
  assert_true(scene.xlim[1] < 10)
  assert_true(scene.xlim[2] > 30)
  assert_true(scene.ylim[1] < 100)
  assert_true(scene.ylim[2] > 300)
end)

test("contour default geometry and scene remain index based", function()
  local fig = plt.figure()
  fig:contour({ { 0, 1 }, { 1, 0 } }, { levels = { 0.5 } })
  local scene = fig:to_scene()
  assert_equal(scene.series[1].x, nil)
  assert_equal(scene.series[1].y, nil)
  assert_equal(scene.xlim[1], -0.1)
  assert_equal(scene.xlim[2], 2.1)
  assert_equal(scene.ylim[1], -0.1)
  assert_equal(scene.ylim[2], 2.1)
end)

test("contour validates coordinate lengths and values", function()
  local values = { { 0, 1 }, { 1, 0 } }
  local fig = plt.figure()
  assert_error("one coordinate per column", function()
    fig:contour(values, { x = { 0 } })
  end)
  assert_error("one coordinate per row", function()
    fig:contour(values, { y = { 0, 1, 2 } })
  end)
  assert_error("must be a number", function()
    fig:contour(values, { x = { 0, "two" } })
  end)
end)
