local plt = require("luaplotlib")

test("renders horizontal bars with category labels", function()
  local fig = plt.figure({ width = 640, height = 420 })
  fig:barh({ "alpha", "beta", "gamma" }, { 2, 5, 3 }, {
    bar_colors = { "#ff0000", "#00ff00", "#0000ff" },
    show_values = true,
  })
  local svg = fig:to_svg()
  assert_equal(select(2, svg:gsub('class="barh"', "")), 3)
  assert_contains(svg, ">alpha<")
  assert_contains(svg, ">beta<")
  assert_contains(svg, ">gamma<")
  assert_contains(svg, 'class="barh-value"')
end)

test("barh validates values and colors", function()
  local fig = plt.figure()
  assert_error("same length", function()
    fig:barh({ "a", "b" }, { 1 })
  end)
  assert_error("one color per bar", function()
    fig:barh({ "a", "b" }, { 1, 2 }, { bar_colors = { "#fff" } })
  end)
end)
