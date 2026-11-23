local plt = require("luaplotlib")

local function stack_figure(baseline)
  local fig = plt.figure({ width = 700, height = 460 })
  fig:stackplot({ 0, 1, 2 }, {
    { 1, 2, 1 },
    { 2, 3, 2 },
    { 1, 1, 3 },
  }, { baseline = baseline, labels = { "A", "B", "C" } })
  return fig
end

test("stackplot defaults to the unchanged zero baseline", function()
  local fig = plt.figure({ width = 700, height = 460 })
  fig:stackplot({ 1, 2, 3 }, { { 1, 2, 3 }, { 2, 1, 1 } },
    { labels = { "A", "B" }, alpha = 0.7 })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-stack="true" data-baseline="zero" data-index="1"')
  assert_contains(svg, 'data-baseline="zero" data-index="2"')
  local scene = fig:to_scene()
  local first, second = scene.series[1], scene.series[2]
  assert_equal(first.stack_baseline, "zero")
  assert_equal(first.stack_index, 1)
  assert_equal(first.stack_shift[1], 0)
  assert_equal(first.y1[1], 0)
  assert_equal(first.y2[1], 1)
  assert_equal(second.y1[1], 1)
  assert_equal(second.y2[1], 3)
  assert_true(scene.ylim[1] <= 0)
end)

test("stackplot sym centers the complete stack at every sample", function()
  local scene = stack_figure("sym"):to_scene()
  for index = 1, 3 do
    assert_equal(scene.series[1].stack_shift[index],
      -({ 4, 6, 6 })[index] / 2)
  end
  -- At x=1 the total is 4 and the shift is -2, so the stack spans [-2, 2].
  assert_equal(scene.series[1].y1[1], -2)
  assert_equal(scene.series[3].y2[1], 2)
  -- At x=2 the total is 6 and the shift is -3.
  assert_equal(scene.series[1].y1[2], -3)
  assert_equal(scene.series[3].y2[2], 3)
  assert_true(scene.ylim[1] < 0)
  local svg = stack_figure("sym"):to_svg()
  assert_contains(svg, 'data-baseline="sym"')
end)

test("stackplot wiggle centers the cumulative layer boundaries", function()
  local scene = stack_figure("wiggle"):to_scene()
  -- x=1: total 4, cumulative boundary sum 4, shift = -(4+4)/4 = -2.
  assert_equal(scene.series[1].stack_shift[1], -2)
  -- x=2: total 6, cumulative boundaries 2+5=7, shift = -(6+7)/4 = -3.25.
  assert_equal(scene.series[1].stack_shift[2], -3.25)
  assert_equal(scene.series[1].y1[2], -3.25)
  assert_equal(scene.series[3].y2[2], 2.75)
  assert_equal(scene.series[1].stack_baseline, "wiggle")
  assert_equal(scene.series[1].baseline, "wiggle")
  local svg = stack_figure("wiggle"):to_svg()
  assert_contains(svg, 'data-baseline="wiggle"')
  assert_well_formed_svg(svg)
end)

test("stackplot baseline validation rejects unknown modes", function()
  local fig = plt.figure()
  assert_error("baseline", function()
    fig:stackplot({ 1 }, { { 1 } }, { baseline = "weighted" })
  end)
  assert_error("baseline", function()
    fig:stackplot({ 1 }, { { 1 } }, { baseline = true })
  end)
  assert_error("labels", function()
    fig:stackplot({ 1 }, { { 1 } }, { labels = { "a", "b" } })
  end)
  assert_error("colors", function()
    fig:stackplot({ 1 }, { { 1 } }, { colors = { "#000000", "#ffffff" } })
  end)
  assert_error("must match x length", function()
    fig:stackplot({ 1, 2 }, { { 1 } })
  end)
end)
