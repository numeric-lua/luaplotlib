local plt = require("luaplotlib")

local function count(svg, pattern)
  return select(2, svg:gsub(pattern, ""))
end

test("errorbar limit flags replace only the requested caps", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2, 3 }, { 1, 2, 3 }, { 0.2, 0.2, 0.2 }, {
    lolims = { true, false, true },
    uplims = { false, true, false },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-lolims="true" data-uplims="true"')
  assert_equal(count(svg, 'class="errorbar%-cap"'), 3)
  assert_equal(count(svg, 'class="errorbar%-limit%-lower"'), 2)
  assert_equal(count(svg, 'class="errorbar%-limit%-upper"'), 1)
  local scene = fig:to_scene().series[1]
  assert_equal(scene.lolims[1], true)
  assert_equal(scene.uplims[2], true)
end)

test("errorbar limit flags accept a scalar boolean", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, { lolims = true })
  local svg = fig:to_svg()
  assert_equal(count(svg, 'class="errorbar%-limit%-lower"'), 2)
  assert_equal(count(svg, 'class="errorbar%-cap"'), 2)
  local scene = fig:to_scene().series[1]
  assert_equal(scene.lolims[1], true)
  assert_equal(scene.lolims[2], true)
end)

test("errorbar limit flags validate shapes and booleans", function()
  local fig = plt.figure()
  assert_error("one boolean per point", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, { lolims = { true } })
  end)
  assert_error("must be a boolean", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, { uplims = "yes" })
  end)
  assert_error("%[2%] must be a boolean", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, { uplims = { true, 1 } })
  end)
end)
