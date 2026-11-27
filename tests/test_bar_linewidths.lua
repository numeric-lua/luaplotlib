local plt = require("luaplotlib")

test("bar accepts one outline width per bar", function()
  local fig = plt.figure()
  fig:bar({ "a", "b", "c" }, { 1, 2, 3 },
    { linewidth = { 0.5, 1.5, 3 } })
  local widths = {}
  for width in fig:to_svg():gmatch('class="bar"[^>]*stroke%-width="([^"]*)"') do
    widths[#widths + 1] = tonumber(width)
  end
  assert_equal(widths[1], 0.5)
  assert_equal(widths[3], 3)
  local style = fig:to_scene().series[1].style
  assert_equal(style.linewidths[2], 1.5)
end)

test("barh accepts one outline width per bar", function()
  local fig = plt.figure()
  fig:barh({ "a", "b" }, { 1, 2 }, { linewidth = { 1, 2.5 } })
  assert_match(fig:to_svg(), 'class="barh"[^>]*stroke%-width="2.5"')
  assert_equal(fig:to_scene().series[1].style.linewidths[1], 1)
end)

test("bar linewidth arrays validate length and values", function()
  local fig = plt.figure()
  assert_error("one value per bar", function()
    fig:bar({ "a", "b" }, { 1, 2 }, { linewidth = { 1 } })
  end)
  assert_error("linewidth%[2%] must be >= 0", function()
    fig:bar({ "a", "b" }, { 1, 2 }, { linewidth = { 1, -1 } })
  end)
end)
