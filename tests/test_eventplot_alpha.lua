local plt = require("luaplotlib")

test("eventplot accepts per-row alpha", function()
  local fig = plt.figure()
  fig:eventplot({ { 1 }, { 2 }, { 3 } },
    { alpha = { 0.2, 0.6, 1 } })
  local svg = fig:to_svg()
  assert_contains(svg, 'stroke-opacity="0.2"')
  assert_contains(svg, 'stroke-opacity="0.6"')
  local scene = fig:to_scene().series[1]
  assert_equal(scene.style.alphas[2], 0.6)
end)

test("eventplot alpha arrays validate length and values", function()
  local fig = plt.figure()
  assert_error("one entry per row", function()
    fig:eventplot({ { 1 }, { 2 } }, { alpha = { 1 } })
  end)
  assert_error("alpha%[2%] must be >= 0", function()
    fig:eventplot({ { 1 }, { 2 } }, { alpha = { 1, -1 } })
  end)
end)
