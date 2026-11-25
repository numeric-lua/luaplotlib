local plt = require("luaplotlib")

local function fade_values(svg)
  local values = {}
  for tag in svg:gmatch('<circle class="point"[^>]*/>') do
    local value = tag:match('fill%-opacity="([^"]*)"')
    if value ~= nil then values[#values + 1] = value end
  end
  return values
end

test("scatter keeps a scalar alpha by default", function()
  local fig = plt.figure()
  fig:scatter({ 1, 2 }, { 1, 2 }, { alpha = 0.5 })
  local values = fade_values(fig:to_svg())
  assert_equal(#values, 2)
  assert_equal(values[1], "0.5")
  assert_equal(fig:to_scene().series[1].style.alphas, nil)
end)

test("cartesian and polar scatter accept per-point alpha", function()
  local cartesian = plt.figure()
  cartesian:scatter({ 1, 2, 3 }, { 1, 2, 3 }, { alpha = { 0.2, 0.5, 0.9 } })
  local values = fade_values(cartesian:to_svg())
  assert_equal(#values, 3)
  assert_equal(values[1], "0.2")
  assert_equal(values[3], "0.9")
  local alphas = cartesian:to_scene().series[1].style.alphas
  assert_equal(alphas[2], 0.5)

  local polar = plt.figure({ width = 480, height = 480 })
  polar:polar_scatter({ 0, 1 }, { 1, 2 }, { alpha = { 0.3, 0.7 } })
  local scene = polar:to_scene().polar.series[1]
  assert_equal(scene.style.alphas[1], 0.3)
  assert_equal(scene.style.alphas[2], 0.7)
end)

test("scatter alpha arrays validate length and range", function()
  local fig = plt.figure()
  assert_error("match the number of points", function()
    fig:scatter({ 1, 2 }, { 1, 2 }, { alpha = { 0.5 } })
  end)
  assert_error("must be <= 1", function()
    fig:scatter({ 1, 2 }, { 1, 2 }, { alpha = { 0.5, 1.5 } })
  end)
  assert_error("match the number of points", function()
    fig:polar_scatter({ 0, 1 }, { 1, 2 }, { alpha = { 0.5 } })
  end)
end)
