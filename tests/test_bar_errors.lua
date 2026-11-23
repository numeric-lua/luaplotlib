local plt = require("luaplotlib")

test("bar yerr draws symmetric error lines and caps", function()
  local fig = plt.figure({ width = 700, height = 460 })
  fig:bar({ "A", "B", "C" }, { 3, 5, 4 }, {
    yerr = { 0.2, 0.5, 0.3 }, ecolor = "#d62728", elinewidth = 1.4,
    capsize = 5,
  })
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)
  assert_contains(svg, '<g class="series series-bar" data-yerr="true">')
  assert_equal(count_occurrences(svg, 'class="bar-error"'), 3)
  assert_equal(count_occurrences(svg, 'class="bar-error-cap"'), 6)
  assert_contains(svg, 'stroke="#d62728" stroke-width="1.4"')
  local scene = fig:to_scene()
  local exported = scene.series[1]
  assert_equal(exported.kind, "bar")
  assert_equal(exported.yerr_lower[1], 0.2)
  assert_equal(exported.yerr_upper[2], 0.5)
  assert_equal(exported.yerr[3], 0.3)
  assert_equal(exported.yerr_asymmetric, false)
  assert_equal(exported.ecolor, "#d62728")
  assert_equal(exported.elinewidth, 1.4)
  assert_equal(exported.capsize, 5)
  assert_true(scene.ylim[2] >= 5.5,
    "automatic range should include the upper error extent")
end)

test("bar yerr supports independent lower and upper extents", function()
  local fig = plt.figure({ width = 660, height = 440 })
  fig:bar({ 1, 2 }, { 4, 6 }, {
    yerr = {
      lower = { 0.5, 1.0 },
      upper = { 1.5, 2.0 },
    },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-yerr-mode="asymmetric"')
  assert_equal(count_occurrences(svg, 'class="bar-error"'), 2)
  assert_equal(count_occurrences(svg, 'class="bar-error-cap"'), 4)
  local scene = fig:to_scene()
  local exported = scene.series[1]
  assert_equal(exported.yerr_lower[2], 1.0)
  assert_equal(exported.yerr_upper[2], 2.0)
  assert_equal(exported.yerr_asymmetric, true)
  assert_true(scene.ylim[2] >= 8.0)
  assert_true(scene.ylim[1] <= 3.5)
end)

test("bar yerr accepts one error specification per value series", function()
  local fig = plt.figure({ width = 760, height = 480 })
  fig:bar({ "Q1", "Q2" }, {
    { 4, 6 },
    { 3, 5 },
  }, {
    labels = { "North", "South" },
    yerr = {
      { 0.4, 0.6 },
      { lower = { 0.2, 0.3 }, upper = { 0.5, 0.8 } },
    },
  })
  local svg = fig:to_svg()
  assert_equal(count_occurrences(svg, 'class="series series-bar"'), 2)
  assert_equal(count_occurrences(svg, 'class="bar-error"'), 4)
  assert_equal(count_occurrences(svg, 'class="bar-error-cap"'), 8)
  local scene = fig:to_scene()
  assert_equal(scene.series[1].yerr_upper[2], 0.6)
  assert_equal(scene.series[2].yerr_lower[2], 0.3)
  assert_equal(scene.series[2].yerr_upper[2], 0.8)
  assert_equal(scene.series[2].yerr_asymmetric, true)
end)

test("stacked bar errors are anchored to each segment top", function()
  local fig = plt.figure({ width = 700, height = 460 })
  fig:bar({ "A", "B" }, {
    { 2, 3 },
    { 4, 2 },
  }, {
    stacked = true,
    yerr = { { 0.2, 0.3 }, { 0.5, 0.4 } },
  })
  local scene = fig:to_scene()
  local top = scene.series[2]
  assert_true(top.bottom ~= nil)
  assert_equal(top.bottom[1] + top.y[1], 6)
  assert_equal(top.yerr_lower[1], 0.5)
  assert_equal(top.yerr_upper[1], 0.5)
  assert_true(scene.ylim[2] >= 6.5,
    "stacked error extents should extend beyond the segment top")
end)

test("bar error options validate input and error geometry", function()
  local fig = plt.figure()
  assert_error("per value series", function()
    fig:bar({ "A" }, { { 1 }, { 2 } }, { yerr = { 0.1 } })
  end)
  assert_error("require yerr", function()
    fig:bar({ "A" }, { 1 }, { ecolor = "#000000" })
  end)
  assert_error("require yerr", function()
    fig:bar({ "A" }, { 1 }, { elinewidth = 2 })
  end)
  assert_error("require yerr", function()
    fig:bar({ "A" }, { 1 }, { capsize = 2 })
  end)
  assert_error("non%-negative", function()
    fig:bar({ "A" }, { 1 }, { yerr = { -0.5 } })
  end)
  assert_error("same length", function()
    fig:bar({ "A", "B" }, { 1, 2 }, { yerr = { 0.1 } })
  end)
  assert_error("elinewidth", function()
    fig:bar({ "A" }, { 1 }, { yerr = { 0.1 }, elinewidth = -1 })
  end)
  assert_error("capsize", function()
    fig:bar({ "A" }, { 1 }, { yerr = { 0.1 }, capsize = -1 })
  end)
  assert_error("ecolor", function()
    fig:bar({ "A" }, { 1 }, { yerr = { 0.1 }, ecolor = "not a color!" })
  end)
end)
