local plt = require("luaplotlib")

local function event_strokes(svg)
  local strokes = {}
  for line in svg:gmatch('<line class="event"[^>]*/>') do
    local color = line:match('stroke="([^"]*)"')
    strokes[#strokes + 1] = color
  end
  return strokes
end

test("eventplot keeps one color by default and reports it", function()
  local fig = plt.figure()
  fig:eventplot({ { 1, 2 }, { 3 } })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-colors="false"')
  local strokes = event_strokes(svg)
  assert_equal(#strokes, 3)
  assert_equal(strokes[1], strokes[2])
  assert_equal(strokes[2], strokes[3])
  assert_equal(fig:to_scene().series[1].colors, nil)
end)

test("eventplot supports one color per row", function()
  local fig = plt.figure()
  fig:eventplot({ { 1, 2 }, { 3 }, { 4 } }, {
    colors = { "#ff0000", "#00ff00", "#0000ff" },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-colors="true"')
  assert_contains(svg, 'stroke="#ff0000"')
  assert_contains(svg, 'stroke="#00ff00"')
  assert_contains(svg, 'stroke="#0000ff"')
  local colors = fig:to_scene().series[1].colors
  assert_equal(#colors, 3)
  assert_equal(colors[2], "#00ff00")
  assert_equal(fig:to_scene().series[1].style.color, "#ff0000")
end)

test("eventplot colors validate row count and color syntax", function()
  local fig = plt.figure()
  assert_error("one entry per row", function()
    fig:eventplot({ { 1 }, { 2 } }, { colors = { "#ff0000" } })
  end)
  assert_error("color", function()
    fig:eventplot({ 1, 2 }, { colors = { "12bad" } })
  end)
  assert_error("colors must have one entry per row", function()
    fig:eventplot({ 1, 2 }, { colors = "#ff0000" })
  end)
  assert_error("colors and color cannot both be set", function()
    fig:eventplot({ 1, 2 }, { color = "#ff0000", colors = { "#00ff00" } })
  end)
end)
