local plt = require("luaplotlib")

test("hist accepts explicit bin edges", function()
  local fig = plt.figure()
  fig:hist({ 0.5, 1.5, 2.5, 3.5 }, {
    bins = { 0, 1, 3, 4 }, histtype = "bar",
  })
  local scene = fig:to_scene().series[1]
  assert_equal(#scene.edges, 4)
  assert_equal(scene.edges[1], 0)
  assert_equal(scene.edges[2], 1)
  assert_equal(scene.edges[3], 3)
  assert_equal(scene.edges[4], 4)
  assert_equal(scene.counts[1], 1)
  assert_equal(scene.counts[2], 2)
  assert_equal(scene.counts[3], 1)
  local svg = fig:to_svg()
  assert_equal(select(2, svg:gsub('class="hist%-bin"', "")), 3)
end)

test("explicit-edge density uses each bin width", function()
  local fig = plt.figure()
  fig:hist({ 0.5, 1.5, 2.5, 3.5 }, {
    bins = { 0, 1, 3, 4 }, density = true,
  })
  local counts = fig:to_scene().series[1].counts
  assert_true(math.abs(counts[1] - 0.25) < 1e-12)
  assert_true(math.abs(counts[2] - 0.25) < 1e-12)
  assert_true(math.abs(counts[3] - 0.25) < 1e-12)
end)

test("hist bin edges validate ordering, length, and range conflicts", function()
  local fig = plt.figure()
  assert_error("at least two explicit edges", function()
    fig:hist({ 1, 2 }, { bins = { 1 } })
  end)
  assert_error("strictly increasing", function()
    fig:hist({ 1, 2 }, { bins = { 0, 2, 2 } })
  end)
  assert_error("cannot be combined", function()
    fig:hist({ 1, 2 }, { bins = { 0, 1, 2 }, range = { 0, 2 } })
  end)
end)
