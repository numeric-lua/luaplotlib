local plt = require("luaplotlib")

test("bar accepts one edge color per bar", function()
  local fig = plt.figure()
  fig:bar({ "a", "b", "c" }, { 1, 2, 3 }, {
    edgecolors = { "#ff0000", "#00ff00", "#0000ff" },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'stroke="#ff0000"')
  assert_contains(svg, 'stroke="#0000ff"')
  local style = fig:to_scene().series[1].style
  assert_equal(style.edgecolors[2], "#00ff00")
end)

test("barh accepts one edge color per bar", function()
  local fig = plt.figure()
  fig:barh({ "a", "b" }, { 1, 2 }, {
    edgecolors = { "#111111", "#eeeeee" },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'stroke="#111111"')
  assert_contains(svg, 'stroke="#eeeeee"')
  local style = fig:to_scene().series[1].style
  assert_equal(style.edgecolors[2], "#eeeeee")
end)

test("bar edge color arrays validate length and colors", function()
  local fig = plt.figure()
  assert_error("one color per bar", function()
    fig:bar({ "a", "b" }, { 1, 2 }, { edgecolors = { "#fff" } })
  end)
  assert_error("edgecolors", function()
    fig:barh({ "a", "b" }, { 1, 2 }, { edgecolors = { "#fff", "12bad" } })
  end)
end)
