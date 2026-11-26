local plt = require("luaplotlib")

local function count(svg, pattern)
  return select(2, svg:gsub(pattern, ""))
end

test("errorbar x limit flags replace left and right caps", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2, 3 }, { 1, 2, 3 }, 0.1, 0.2, {
    xlolims = { true, false, false },
    xuplims = { false, false, true },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-xlolims="true" data-xuplims="true"')
  assert_equal(count(svg, 'class="errorbar%-limit%-left"'), 1)
  assert_equal(count(svg, 'class="errorbar%-limit%-right"'), 1)
  assert_equal(count(svg, 'class="errorbar%-cap"'), 10)
  local scene = fig:to_scene().series[1]
  assert_equal(scene.xlolims[1], true)
  assert_equal(scene.xuplims[3], true)
end)

test("errorbar x limit flags accept scalar booleans", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, 0.2, { xlolims = true })
  local svg = fig:to_svg()
  assert_equal(count(svg, 'class="errorbar%-limit%-left"'), 2)
  assert_equal(count(svg, 'class="errorbar%-cap"'), 6)
  local scene = fig:to_scene().series[1]
  assert_equal(scene.xlolims[1], true)
  assert_equal(scene.xlolims[2], true)
end)

test("errorbar x limit flags validate shapes and booleans", function()
  local fig = plt.figure()
  assert_error("one boolean per point", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, 0.2, { xuplims = { true } })
  end)
  assert_error("must be a boolean", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, 0.2, { xlolims = "yes" })
  end)
end)
