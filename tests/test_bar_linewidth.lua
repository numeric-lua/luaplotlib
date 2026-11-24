local plt = require("luaplotlib")

local function strokes(svg, klass)
  local result = {}
  for rect in svg:gmatch('<rect class="' .. klass .. '"[^>]*/>') do
    result[#result + 1] = tonumber(rect:match('stroke%-width="([^"]*)"'))
  end
  return result
end

test("bars keep a one-pixel outline by default", function()
  local fig = plt.figure()
  fig:bar({ "A", "B" }, { 1, 2 })
  local widths = strokes(fig:to_svg(), "bar")
  assert_equal(#widths, 2)
  assert_equal(widths[1], 1)
  assert_equal(fig:to_scene().series[1].style.linewidth, 1)
end)

test("bar and barh accept an explicit outline width", function()
  local bars = plt.figure()
  bars:bar({ "A", "B" }, { 1, 2 }, { linewidth = 3 })
  local widths = strokes(bars:to_svg(), "bar")
  assert_equal(widths[1], 3)
  assert_equal(bars:to_scene().series[1].style.linewidth, 3)

  local horizontal = plt.figure()
  horizontal:barh({ "A", "B" }, { 1, 2 }, { linewidth = 2.5 })
  local barh = strokes(horizontal:to_svg(), "barh")
  assert_equal(barh[1], 2.5)
  assert_equal(horizontal:to_scene().series[1].style.linewidth, 2.5)
end)

test("bar linewidth validates non-negative finite numbers", function()
  local fig = plt.figure()
  assert_error("must be >= 0", function()
    fig:bar({ "A" }, { 1 }, { linewidth = -1 })
  end)
  assert_error("must be a number", function()
    fig:barh({ "A" }, { 1 }, { linewidth = "thick" })
  end)
end)
