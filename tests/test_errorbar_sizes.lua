local plt = require("luaplotlib")

test("errorbar accepts one marker size per point", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2, 3 }, { 1, 2, 3 }, 0.2, {
    markersize = { 3, 5, 7 },
  })
  local svg = fig:to_svg()
  local radii = {}
  for radius in svg:gmatch('class="marker"[^>]*r="([^"]*)"') do
    radii[#radii + 1] = tonumber(radius)
  end
  assert_equal(radii[1], 3)
  assert_equal(radii[3], 7)
  local style = fig:to_scene().series[1].style
  assert_equal(style.markersizes[2], 5)
end)

test("errorbar accepts one error line width per point", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2, 3 }, { 1, 2, 3 }, 0.2, {
    elinewidth = { 1, 2.5, 4 },
  })
  local svg = fig:to_svg()
  assert_match(svg, 'class="errorbar"[^>]*stroke%-width="1"')
  assert_match(svg, 'class="errorbar"[^>]*stroke%-width="4"')
  local style = fig:to_scene().series[1].style
  assert_equal(style.elinewidths[2], 2.5)
end)

test("errorbar size arrays validate length and values", function()
  local fig = plt.figure()
  assert_error("markersize array must match", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, { markersize = { 3 } })
  end)
  assert_error("elinewidth%[2%] must be >= 0", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, { elinewidth = { 1, -1 } })
  end)
end)
