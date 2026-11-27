local plt = require("luaplotlib")

test("hist accepts one edge color per bin", function()
  local fig = plt.figure()
  fig:hist({ 1, 1, 2, 2, 3, 3 }, {
    bins = { 0.5, 1.5, 2.5, 3.5 },
    edgecolors = { "#ff0000", "#00ff00", "#0000ff" },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'stroke="#ff0000"')
  assert_contains(svg, 'stroke="#0000ff"')
  local style = fig:to_scene().series[1].style
  assert_equal(style.edgecolors[2], "#00ff00")
end)

test("hist edge color arrays validate count, type, and colors", function()
  local fig = plt.figure()
  assert_error("one color per bin", function()
    fig:hist({ 1, 2 }, { bins = { 0, 1, 2 }, edgecolors = { "#fff" } })
  end)
  assert_error("require histtype bar", function()
    fig:hist({ 1, 2 }, {
      bins = { 0, 1, 2 }, histtype = "step",
      edgecolors = { "#fff", "#000" },
    })
  end)
  assert_error("edgecolors", function()
    fig:hist({ 1, 2 }, {
      bins = { 0, 1, 2 }, edgecolors = { "#fff", "12bad" },
    })
  end)
end)
