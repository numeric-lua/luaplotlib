local plt = require("luaplotlib")

test("errorbar markers accept fill and outline styling", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2 }, { 1, 2 }, 0.2, {
    marker = "square", markerfacecolor = "#ffffff",
    markeredgecolor = "#d62728", markeredgewidth = 2,
  })
  local svg = fig:to_svg()
  assert_match(svg, 'class="marker" x="[^"]*" y="[^"]*" width="8" height="8" fill="#ffffff" stroke="#d62728" stroke%-width="2"')
  local style = fig:to_scene().series[1].style
  assert_equal(style.markerfacecolor, "#ffffff")
  assert_equal(style.markeredgecolor, "#d62728")
  assert_equal(style.markeredgewidth, 2)
end)

test("stem markers accept fill and outline styling", function()
  local fig = plt.figure()
  fig:stem({ 1, 2 }, { 1, 2 }, {
    marker = "diamond", markerfacecolor = "#fef3c7",
    markeredgecolor = "#92400e", markeredgewidth = 1.5,
  })
  local svg = fig:to_svg()
  assert_match(svg, '<polygon class="stem%-marker"[^>]*fill="#fef3c7" stroke="#92400e" stroke%-width="1.5"')
  local style = fig:to_scene().series[1].style
  assert_equal(style.markerfacecolor, "#fef3c7")
  assert_equal(style.markeredgecolor, "#92400e")
  assert_equal(style.markeredgewidth, 1.5)
end)

test("errorbar and stem marker styles validate colors and widths", function()
  local fig = plt.figure()
  assert_error("markerfacecolor", function()
    fig:errorbar({ 1 }, { 1 }, 0.1, { markerfacecolor = "12bad" })
  end)
  assert_error("markeredgewidth must be >= 0", function()
    fig:stem({ 1 }, { 1 }, { markeredgewidth = -1 })
  end)
  assert_error("markeredgecolor", function()
    fig:stem({ 1 }, { 1 }, { markeredgecolor = {} })
  end)
end)
