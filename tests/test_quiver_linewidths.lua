local plt = require("luaplotlib")

test("quiver accepts one line width per vector", function()
  local fig = plt.figure()
  fig:quiver({ 1, 2, 3 }, { 1, 2, 3 }, { 1, 1, 1 }, { 1, 0, -1 },
    { linewidth = { 0.5, 1.5, 3 } })
  local svg = fig:to_svg()
  local widths = {}
  for width in svg:gmatch('class="quiver%-shaft"[^>]*stroke%-width="([^"]*)"') do
    widths[#widths + 1] = tonumber(width)
  end
  assert_equal(widths[1], 0.5)
  assert_equal(widths[3], 3)
  local style = fig:to_scene().series[1].style
  assert_equal(style.linewidths[2], 1.5)
end)

test("quiver linewidth arrays validate length and values", function()
  local fig = plt.figure()
  assert_error("match the number of vectors", function()
    fig:quiver({ 1, 2 }, { 1, 2 }, { 1, 1 }, { 1, 1 },
      { linewidth = { 1 } })
  end)
  assert_error("linewidth%[2%] must be >= 0", function()
    fig:quiver({ 1, 2 }, { 1, 2 }, { 1, 1 }, { 1, 1 },
      { linewidth = { 1, -1 } })
  end)
end)
