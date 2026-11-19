local plt = require("luaplotlib")

test("renders boxes, whiskers, and outliers", function()
  local fig = plt.figure({ width = 640, height = 480 })
  fig:boxplot({
    { 1, 2, 2, 3, 3, 4, 20 },
    { 2, 3, 3, 4, 4, 5 },
  }, { labels = { "A", "B" }, color = "#1f77b4" })
  local svg = fig:to_svg()
  assert_equal(select(2, svg:gsub('class="box"', "")), 2)
  assert_contains(svg, 'class="box-median"')
  assert_contains(svg, 'class="box-whisker"')
  assert_contains(svg, 'class="box-outlier"')
  assert_contains(svg, '>A<')
  local path = (TMPDIR or "/tmp") .. "/luaplotlib-box.svg"
  assert_equal(fig:savefig(path), path)
  os.remove(path)
end)

test("boxplot validates sample and label shapes", function()
  local fig = plt.figure()
  assert_error("non%-empty", function() fig:boxplot({}) end)
  assert_error("one entry per sample", function()
    fig:boxplot({ { 1, 2 }, { 3, 4 } }, { labels = { "only" } })
  end)
  assert_error("empty", function() fig:boxplot({ {} }) end)
end)
