local plt = require("luaplotlib")

test("pie label and percentage distances have stable defaults", function()
  local fig = plt.figure()
  fig:pie({ 1, 2 }, { labels = { "a", "b" }, autopct = true })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-labeldistance="1.08" data-pctdistance="0.64"')
  local pie = fig:to_scene().pie
  assert_equal(pie.labeldistance, 1.08)
  assert_equal(pie.pctdistance, 0.64)
end)

test("pie label and percentage distances are configurable", function()
  local fig = plt.figure()
  fig:pie({ 1, 2 }, {
    labels = { "a", "b" }, autopct = true,
    labeldistance = 1.2, pctdistance = 0.5,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-labeldistance="1.2" data-pctdistance="0.5"')
  local pie = fig:to_scene().pie
  assert_equal(pie.labeldistance, 1.2)
  assert_equal(pie.pctdistance, 0.5)
  assert_contains(svg, 'class="pie-label"')
  assert_contains(svg, 'class="pie-percent"')
end)

test("pie distances validate positive bounded numbers", function()
  local fig = plt.figure()
  assert_error("labeldistance must be >= 0.01", function()
    fig:pie({ 1, 2 }, { labeldistance = 0 })
  end)
  assert_error("labeldistance must be <= 2", function()
    fig:pie({ 1, 2 }, { labeldistance = 2.5 })
  end)
  assert_error("pctdistance must be a number", function()
    fig:pie({ 1, 2 }, { pctdistance = "inside" })
  end)
end)
