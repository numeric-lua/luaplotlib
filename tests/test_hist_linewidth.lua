local plt = require("luaplotlib")

local function count(svg, pattern)
  return select(2, svg:gsub(pattern, ""))
end

test("histograms keep a one-pixel outline by default", function()
  local fig = plt.figure()
  fig:hist({ 1, 2, 2, 3, 3, 3 }, { bins = 3, range = { 1, 3 } })
  local svg = fig:to_svg()
  assert_match(svg, 'class="hist%-bin" x="[^"]*" y="[^"]*" width="[^"]*" height="[^"]*" fill="[^"]*" stroke="[^"]*" stroke%-width="1"')
  assert_equal(fig:to_scene().series[1].style.linewidth, 1)
end)

test("step histograms keep their previous 1.5-pixel default outline", function()
  local fig = plt.figure()
  fig:hist({ 1, 2, 2, 3, 3, 3 }, {
    bins = 3, range = { 1, 3 }, histtype = "step",
  })
  assert_contains(fig:to_svg(), 'stroke-width="1.5"')
  assert_equal(fig:to_scene().series[1].style.linewidth, 1.5)
end)

test("bar and step histograms accept an outline width", function()
  local bars = plt.figure()
  bars:hist({ 1, 2, 2, 3, 3, 3 }, {
    bins = 3, range = { 1, 3 }, linewidth = 3,
  })
  assert_contains(bars:to_svg(), 'stroke-width="3"')
  assert_equal(bars:to_scene().series[1].style.linewidth, 3)

  local step = plt.figure()
  step:hist({ 1, 2, 2, 3, 3, 3 }, {
    bins = 3, range = { 1, 3 }, histtype = "step", linewidth = 2.5,
  })
  assert_match(step:to_svg(), '<polyline class="hist%-step" points="[^"]*" fill="none" stroke="[^"]*" stroke%-width="2.5"')
  assert_equal(step:to_scene().series[1].style.linewidth, 2.5)

  local filled = plt.figure()
  filled:hist({ 1, 2, 2, 3, 3, 3 }, {
    bins = 3, range = { 1, 3 }, histtype = "stepfilled", linewidth = 2,
  })
  assert_match(filled:to_svg(), '<polygon class="hist%-step%-filled" points="[^"]*" fill="[^"]*" stroke="[^"]*" stroke%-width="2"')
end)

test("hist linewidth validates non-negative numbers", function()
  local fig = plt.figure()
  assert_error("must be >= 0", function()
    fig:hist({ 1, 2, 3 }, { linewidth = -1 })
  end)
  assert_error("must be a number", function()
    fig:hist({ 1, 2, 3 }, { linewidth = "thin" })
  end)
end)
