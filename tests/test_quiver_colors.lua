local plt = require("luaplotlib")

test("quiver colors can vary per vector", function()
  local fig = plt.figure()
  fig:quiver({ 1, 2, 3 }, { 1, 2, 3 }, { 1, 1, 1 }, { 1, 0, -1 }, {
    color = { "#ff0000", "#00ff00", "#0000ff" },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="quiver-shaft"')
  assert_contains(svg, 'stroke="#ff0000"')
  assert_contains(svg, 'stroke="#00ff00"')
  assert_contains(svg, 'stroke="#0000ff"')
  local style = fig:to_scene().series[1].style
  assert_equal(style.colors[3], "#0000ff")
end)

test("quiver color arrays validate length and colors", function()
  local fig = plt.figure()
  assert_error("match the number of vectors", function()
    fig:quiver({ 1, 2 }, { 1, 2 }, { 1, 1 }, { 1, 1 },
      { color = { "#fff" } })
  end)
  assert_error("color", function()
    fig:quiver({ 1, 2 }, { 1, 2 }, { 1, 1 }, { 1, 1 },
      { color = { "#fff", "12bad" } })
  end)
end)
