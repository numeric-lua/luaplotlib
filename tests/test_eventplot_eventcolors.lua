local plt = require("luaplotlib")

test("eventplot accepts one color per event", function()
  local fig = plt.figure()
  fig:eventplot({ { 1, 2 }, { 3, 4 } }, {
    eventcolors = { "#ff0000", "#00ff00", "#0000ff", "#ffff00" },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-eventcolors="true"')
  assert_contains(svg, 'stroke="#ff0000"')
  assert_contains(svg, 'stroke="#ffff00"')
  local scene = fig:to_scene().series[1]
  assert_equal(scene.eventcolors[2], "#00ff00")
  assert_equal(scene.eventcolors[4], "#ffff00")
end)

test("eventplot event colors override row colors", function()
  local fig = plt.figure()
  fig:eventplot({ { 1 }, { 2 } }, {
    colors = { "#111111", "#222222" },
    eventcolors = { "#abcdef", "#fedcba" },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'stroke="#abcdef"')
  assert_contains(svg, 'stroke="#fedcba"')
end)

test("eventplot event colors validate length and values", function()
  local fig = plt.figure()
  assert_error("one entry per event", function()
    fig:eventplot({ { 1 }, { 2 } }, { eventcolors = { "#fff" } })
  end)
  assert_error("eventcolors", function()
    fig:eventplot({ { 1 }, { 2 } }, { eventcolors = { "#fff", "12bad" } })
  end)
end)
