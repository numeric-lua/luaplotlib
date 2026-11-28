local plt = require("luaplotlib")

test("pie label and percentage weights are configurable", function()
  local fig = plt.figure()
  fig:pie({ 1, 2, 3 }, {
    labels = { "a", "b", "c" }, autopct = true,
    labelweight = "bold", pctweight = "bold",
  })
  local svg = fig:to_svg()
  assert_match(svg, 'class="pie%-label"[^>]*font%-weight="bold"')
  assert_match(svg, 'class="pie%-percent"[^>]*font%-weight="bold"')
  local pie = fig:to_scene().pie
  assert_equal(pie.labelweight, "bold")
  assert_equal(pie.pctweight, "bold")
end)

test("pie text weights default to normal and validate", function()
  local fig = plt.figure()
  fig:pie({ 1, 2 }, { labels = { "a", "b" }, autopct = true })
  assert_not_contains(fig:to_svg(), 'class="pie-label"[^>]*font-weight')
  assert_error("labelweight must be 'normal' or 'bold'", function()
    fig:pie({ 1, 2 }, { labelweight = "heavy" })
  end)
end)
