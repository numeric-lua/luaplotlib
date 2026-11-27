local plt = require("luaplotlib")

test("quiver head width defaults and is configurable", function()
  local fig = plt.figure()
  fig:quiver({ 1, 2 }, { 1, 2 }, { 1, 1 }, { 1, 1 })
  assert_contains(fig:to_svg(), 'data-headwidth="0.9"')

  local wide = plt.figure()
  wide:quiver({ 1 }, { 1 }, { 1 }, { 1 }, { headwidth = 1.6 })
  assert_contains(wide:to_svg(), 'data-headwidth="1.6"')
  assert_equal(wide:to_scene().series[1].style.headwidth, 1.6)
end)

test("quiver head width validates positive numbers", function()
  local fig = plt.figure()
  assert_error("headwidth must be >= 0", function()
    fig:quiver({ 1 }, { 1 }, { 1 }, { 1 }, { headwidth = -1 })
  end)
end)
