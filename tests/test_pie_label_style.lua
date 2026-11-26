local plt = require("luaplotlib")

test("pie label and percentage text keep their defaults", function()
  local fig = plt.figure()
  fig:pie({ 1, 2, 3 }, { labels = { "a", "b", "c" }, autopct = true })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-labelsize="12" data-labelcolor="#222222" data-pctsize="12" data-pctcolor="#ffffff"')
  assert_match(svg, 'class="pie%-label" x="[^"]*" y="[^"]*" font%-size="12" fill="#222222"')
  local pie = fig:to_scene().pie
  assert_equal(pie.labelsize, 12)
  assert_equal(pie.pctcolor, "#ffffff")
end)

test("pie label and percentage text styles are configurable", function()
  local fig = plt.figure()
  fig:pie({ 1, 2, 3 }, {
    labels = { "a", "b", "c" }, autopct = true,
    labelsize = 17, labelcolor = "#14532d",
    pctsize = 10, pctcolor = "#fef3c7",
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'font-size="17" fill="#14532d"')
  assert_contains(svg, 'font-size="10" fill="#fef3c7"')
  local pie = fig:to_scene().pie
  assert_equal(pie.labelsize, 17)
  assert_equal(pie.labelcolor, "#14532d")
  assert_equal(pie.pctsize, 10)
  assert_equal(pie.pctcolor, "#fef3c7")
end)

test("pie text styles validate size and color", function()
  local fig = plt.figure()
  assert_error("labelsize must be >= 0.1", function()
    fig:pie({ 1, 2 }, { labels = { "a", "b" }, labelsize = 0 })
  end)
  assert_error("pctcolor", function()
    fig:pie({ 1, 2 }, { autopct = true, pctcolor = "12bad" })
  end)
end)
