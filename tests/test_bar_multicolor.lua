local plt = require("luaplotlib")

local function bar_fills(svg)
  local fills = {}
  for rect in svg:gmatch('<rect class="bar"[^>]*/>') do
    local fill = rect:match('fill="([^"]*)"')
    fills[#fills + 1] = fill
  end
  return fills
end

test("multi-series bars accept one color per bar per series", function()
  local fig = plt.figure()
  fig:bar({ "A", "B" }, {
    { 1, 2 }, { 3, 4 },
  }, {
    bar_colors = {
      { "#ff0000", "#00ff00" },
      { "#0000ff", "#ffff00" },
    },
  })
  local fills = bar_fills(fig:to_svg())
  assert_equal(#fills, 4)
  assert_contains(fig:to_svg(), 'fill="#ff0000"')
  assert_contains(fig:to_svg(), 'fill="#ffff00"')
  local series = fig:to_scene().series
  assert_equal(series[1].bar_colors[2], "#00ff00")
  assert_equal(series[2].bar_colors[1], "#0000ff")
end)

test("single-series bars still accept a flat color list", function()
  local fig = plt.figure()
  fig:bar({ "A", "B", "C" }, { 1, 2, 3 }, {
    bar_colors = { "#111111", "#222222", "#333333" },
  })
  local series = fig:to_scene().series[1]
  assert_equal(series.bar_colors[1], "#111111")
  assert_equal(series.bar_colors[3], "#333333")
  assert_equal(#bar_fills(fig:to_svg()), 3)
end)

test("multi-series bar colors validate nested lengths and colors", function()
  local fig = plt.figure()
  assert_error("one color list per series", function()
    fig:bar({ "A", "B" }, { { 1, 2 }, { 3, 4 } }, {
      bar_colors = { { "#ff0000", "#00ff00" } },
    })
  end)
  assert_error("must have one color per bar", function()
    fig:bar({ "A", "B" }, { { 1, 2 }, { 3, 4 } }, {
      bar_colors = { { "#ff0000" }, { "#00ff00", "#0000ff" } },
    })
  end)
  assert_error("must contain one color list", function()
    fig:bar({ "A", "B" }, { { 1, 2 }, { 3, 4 } }, {
      bar_colors = { "#ff0000", "#00ff00" },
    })
  end)
  assert_error("color", function()
    fig:bar({ "A" }, { 1 }, { bar_colors = { "12bad" } })
  end)
end)
