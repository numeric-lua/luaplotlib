local plt = require("luaplotlib")

test("eventplot accepts one linestyle per row", function()
  local fig = plt.figure()
  fig:eventplot({ { 1 }, { 2 }, { 3 } },
    { linestyle = { "solid", "dashed", "dotted" } })
  local svg = fig:to_svg()
  assert_match(svg, 'data%-row="2"[^>]*stroke%-dasharray="6 4"')
  assert_match(svg, 'data%-row="3"[^>]*stroke%-dasharray="1.5 3"')
  local scene = fig:to_scene().series[1]
  assert_equal(scene.style.linestyles[2], "dashed")
end)

test("eventplot linestyle arrays validate length and values", function()
  local fig = plt.figure()
  assert_error("one entry per row", function()
    fig:eventplot({ { 1 }, { 2 } }, { linestyle = { "solid" } })
  end)
  assert_error("must be one of solid", function()
    fig:eventplot({ { 1 }, { 2 } },
      { linestyle = { "solid", "wavy" } })
  end)
end)
