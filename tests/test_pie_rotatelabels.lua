local plt = require("luaplotlib")

test("pie labels are horizontal by default", function()
  local fig = plt.figure()
  fig:pie({ 1, 2, 3 }, { labels = { "a", "b", "c" } })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-rotatelabels="false"')
  for tag in svg:gmatch('<text class="pie%-label"[^>]*>') do
    assert_not_contains(tag, "transform=")
  end
  assert_equal(fig:to_scene().pie.rotatelabels, false)
end)

test("pie labels can rotate with their slices", function()
  local fig = plt.figure()
  fig:pie({ 1, 2, 4 }, {
    labels = { "a", "b", "c" }, rotatelabels = true,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-rotatelabels="true"')
  local rotated = 0
  for tag in svg:gmatch('<text class="pie%-label"[^>]*>') do
    if tag:find("transform=", 1, true) then rotated = rotated + 1 end
  end
  assert_true(rotated > 0, "expected rotated pie labels")
  assert_equal(fig:to_scene().pie.rotatelabels, true)
end)

test("pie rotatelabels validates the boolean", function()
  local fig = plt.figure()
  assert_error("rotatelabels must be a boolean", function()
    fig:pie({ 1, 2 }, { rotatelabels = "yes" })
  end)
end)
