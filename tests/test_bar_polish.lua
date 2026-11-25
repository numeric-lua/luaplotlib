local plt = require("luaplotlib")

test("bar supports per-bar colors and value labels", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:bar({ "a", "b", "c" }, { 1, 2, 3 }, {
    bar_colors = { "#ff0000", "#00ff00", "#0000ff" },
    show_values = true,
  })
  local svg = fig:to_svg()
  assert_equal(select(2, svg:gsub('class="bar"', "")), 3)
  assert_contains(svg, 'fill="#ff0000"')
  assert_contains(svg, 'fill="#00ff00"')
  assert_contains(svg, 'fill="#0000ff"')
  assert_equal(select(2, svg:gsub('class="bar%-value"', "")), 3)
end)

test("bar color/label options are validated", function()
  local fig = plt.figure()
  assert_error("one color per bar", function()
    fig:bar({ "a", "b" }, { 1, 2 }, { bar_colors = { "#fff" } })
  end)
  assert_error("one color list per series", function()
    fig:bar({ "a", "b" }, { { 1, 2 }, { 2, 3 } },
      { bar_colors = { "#fff", "#000" } })
  end)
  assert_error("boolean", function()
    fig:bar({ "a" }, { 1 }, { show_values = "yes" })
  end)
end)
