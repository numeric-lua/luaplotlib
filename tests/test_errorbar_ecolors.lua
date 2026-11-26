local plt = require("luaplotlib")

test("errorbar accepts one error color per point", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2, 3 }, { 1, 2, 3 }, 0.2, {
    ecolor = { "#ff0000", "#00ff00", "#0000ff" },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="errorbar"')
  assert_contains(svg, 'stroke="#ff0000"')
  assert_contains(svg, 'stroke="#0000ff"')
  local style = fig:to_scene().series[1].style
  assert_equal(style.ecolors[2], "#00ff00")
end)

test("errorbar ecolor arrays validate length and colors", function()
  local fig = plt.figure()
  assert_error("match the number of points", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, { ecolor = { "#fff" } })
  end)
  assert_error("ecolor", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1,
      { ecolor = { "#fff", "12bad" } })
  end)
end)
