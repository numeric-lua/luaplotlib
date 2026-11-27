local plt = require("luaplotlib")

test("boxplot accepts per-sample edge colors", function()
  local fig = plt.figure()
  fig:boxplot({ { 1, 2, 3 }, { 2, 3, 4 } }, {
    edgecolors = { "#ff0000", "#00ff00" },
  })
  local svg = fig:to_svg()
  assert_match(svg, 'class="box"[^>]*stroke="#ff0000"')
  assert_match(svg, 'class="box"[^>]*stroke="#00ff00"')
  local scene = fig:to_scene()
  assert_equal(scene.series[2].style.edgecolor, "#00ff00")
end)

test("boxplot edge color arrays validate length and values", function()
  local fig = plt.figure()
  assert_error("one entry per sample", function()
    fig:boxplot({ { 1, 2 }, { 2, 3 } }, { edgecolors = { "#fff" } })
  end)
  assert_error("edgecolors", function()
    fig:boxplot({ { 1, 2 }, { 2, 3 } },
      { edgecolors = { "#fff", "12bad" } })
  end)
end)
