local plt = require("luaplotlib")

test("legend frame keeps its default styling", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 1, 2 }, { label = "line" })
  fig:legend()
  local svg = fig:to_svg()
  assert_contains(svg, 'class="legend-meta" data-loc="upper right" data-framealpha="0.92"')
  assert_contains(svg, 'fill="#ffffff" fill-opacity="0.92" stroke="#bbbbbb"')
  local style = fig:to_scene().legend_style
  assert_equal(style.framealpha, 0.92)
  assert_equal(style.facecolor, "#ffffff")
  assert_equal(style.edgecolor, "#bbbbbb")
end)

test("legend framealpha and colors are configurable", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 1, 2 }, { label = "line" })
  fig:legend({
    framealpha = 0.45, facecolor = "#f8fafc", edgecolor = "#334155",
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-framealpha="0.45"')
  assert_contains(svg, 'fill="#f8fafc" fill-opacity="0.45" stroke="#334155"')
  local style = fig:to_scene().legend_style
  assert_equal(style.framealpha, 0.45)
  assert_equal(style.facecolor, "#f8fafc")
  assert_equal(style.edgecolor, "#334155")
end)

test("legend frame=false suppresses the frame but keeps metadata", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 1, 2 }, { label = "line" })
  fig:legend({ frame = false, framealpha = 0.3 })
  local svg = fig:to_svg()
  assert_not_contains(svg, 'class="legend-frame"')
  assert_contains(svg, 'data-framealpha="0.3"')
  assert_equal(fig:to_scene().legend_style.frame, false)
end)

test("polar legend frame styling is applied and exported", function()
  local fig = plt.figure({ width = 520, height = 520 })
  fig:polar({ 0, 1 }, { 1, 1 }, { label = "line" })
  fig:legend({
    loc = "center", framealpha = 0.4, facecolor = "#fef3c7",
    edgecolor = "#92400e",
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-framealpha="0.4"')
  assert_contains(svg, 'fill="#fef3c7" fill-opacity="0.4" stroke="#92400e"')
  local legend = fig:to_scene().polar.legend
  assert_equal(legend.framealpha, 0.4)
  assert_equal(legend.facecolor, "#fef3c7")
  assert_equal(legend.edgecolor, "#92400e")
end)

test("legend frame options validate alpha and colors", function()
  local fig = plt.figure()
  assert_error("framealpha must be <= 1", function()
    fig:legend({ framealpha = 1.5 })
  end)
  assert_error("facecolor", function()
    fig:legend({ facecolor = "12bad" })
  end)
  assert_error("edgecolor", function()
    fig:legend({ edgecolor = {} })
  end)
end)
