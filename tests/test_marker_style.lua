local plt = require("luaplotlib")

test("line markers keep their series color by default", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 1, 2 }, { marker = true, color = "#123456" })
  local svg = fig:to_svg()
  assert_match(svg, 'class="marker" cx="[^"]*" cy="[^"]*" r="4" fill="#123456"')
  local style = fig:to_scene().series[1].style
  assert_equal(style.markerfacecolor, nil)
  assert_equal(style.markeredgecolor, nil)
end)

test("line markers accept a fill and outline", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 1, 2 }, {
    marker = "square", markerfacecolor = "#ffffff",
    markeredgecolor = "#d62728", markeredgewidth = 2.5,
  })
  local svg = fig:to_svg()
  assert_match(svg, 'class="marker" x="[^"]*" y="[^"]*" width="8" height="8" fill="#ffffff" stroke="#d62728" stroke%-width="2.5"')
  local style = fig:to_scene().series[1].style
  assert_equal(style.markerfacecolor, "#ffffff")
  assert_equal(style.markeredgecolor, "#d62728")
  assert_equal(style.markeredgewidth, 2.5)
end)

test("marker outline opacity follows alpha", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 1, 2 }, {
    marker = true, alpha = 0.5, markeredgecolor = "#000000",
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'fill-opacity="0.5"')
  assert_contains(svg, 'stroke-opacity="0.5"')
end)

test("marker face and edge options validate colors and widths", function()
  local fig = plt.figure()
  assert_error("markerfacecolor", function()
    fig:plot({ 1, 2 }, { 1, 2 }, { markerfacecolor = "12bad" })
  end)
  assert_error("markeredgecolor", function()
    fig:plot({ 1, 2 }, { 1, 2 }, { markeredgecolor = {} })
  end)
  assert_error("markeredgewidth must be >= 0", function()
    fig:plot({ 1, 2 }, { 1, 2 }, { markeredgewidth = -1 })
  end)
end)
