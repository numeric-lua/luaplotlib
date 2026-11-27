local plt = require("luaplotlib")

test("eventplot accepts one line width per row", function()
  local fig = plt.figure()
  fig:eventplot({ { 1, 2 }, { 3, 4 }, { 5 } },
    { linewidth = { 1, 2.5, 4 } })
  local svg = fig:to_svg()
  assert_match(svg, 'data%-row="1"[^>]*stroke%-width="1"')
  assert_match(svg, 'data%-row="3"[^>]*stroke%-width="4"')
  local scene = fig:to_scene().series[1]
  assert_equal(scene.style.linewidths[2], 2.5)
end)

test("eventplot linewidth arrays validate length and values", function()
  local fig = plt.figure()
  assert_error("one entry per row", function()
    fig:eventplot({ { 1 }, { 2 } }, { linewidth = { 1 } })
  end)
  assert_error("linewidth%[2%] must be >= 0", function()
    fig:eventplot({ { 1 }, { 2 } }, { linewidth = { 1, -1 } })
  end)
end)
