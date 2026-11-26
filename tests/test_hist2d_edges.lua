local plt = require("luaplotlib")

test("hist2d accepts explicit x and y bin edges", function()
  local fig = plt.figure()
  fig:hist2d({ 0.5, 1.5, 2.5, 3.5 }, { 0.5, 1.5, 2.5, 3.5 }, {
    bins = { { 0, 1, 3, 4 }, { 0, 2, 4 } },
  })
  local series = fig:to_scene().series[1]
  assert_equal(series.bins_x, 3)
  assert_equal(series.bins_y, 2)
  assert_equal(#series.edges_x, 4)
  assert_equal(#series.edges_y, 3)
  assert_equal(series.edges_x[3], 3)
  assert_equal(series.edges_y[2], 2)
end)

test("hist2d supports one explicit axis and one count", function()
  local fig = plt.figure()
  fig:hist2d({ 1, 2, 3 }, { 1, 2, 3 }, {
    bins = { { 0, 2, 4 }, 2 },
  })
  local series = fig:to_scene().series[1]
  assert_equal(series.bins_x, 2)
  assert_equal(series.bins_y, 2)
  assert_equal(series.edges_x[1], 0)
  assert_equal(series.edges_x[3], 4)
end)

test("hist2d explicit edges validate ordering and range conflicts", function()
  local fig = plt.figure()
  assert_error("strictly increasing", function()
    fig:hist2d({ 1, 2 }, { 1, 2 }, { bins = { { 0, 2, 2 }, 2 } })
  end)
  assert_error("cannot be combined", function()
    fig:hist2d({ 1, 2 }, { 1, 2 }, {
      bins = { { 0, 2 }, { 0, 2 } }, range = { 0, 2, 0, 2 },
    })
  end)
end)
