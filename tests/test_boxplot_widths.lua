local plt = require("luaplotlib")

test("boxplot accepts one width per sample", function()
  local fig = plt.figure()
  fig:boxplot({ { 1, 2, 3 }, { 2, 3, 4 }, { 3, 4, 5 } },
    { width = { 0.4, 0.7, 0.5 } })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-width="0.4"')
  assert_contains(svg, 'data-width="0.7"')
  local widths = {}
  for width in svg:gmatch('class="series series%-box"[^>]*data%-width="([^"]*)"') do
    widths[#widths + 1] = tonumber(width)
  end
  assert_equal(#widths, 3)
  assert_equal(widths[2], 0.7)
end)

test("boxplot width arrays validate length and range", function()
  local fig = plt.figure()
  assert_error("match the number of samples", function()
    fig:boxplot({ { 1, 2 }, { 2, 3 } }, { width = { 0.5 } })
  end)
  assert_error("width%[2%] must be <= 1", function()
    fig:boxplot({ { 1, 2 }, { 2, 3 } }, { width = { 0.5, 2 } })
  end)
end)
