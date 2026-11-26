local plt = require("luaplotlib")

local function widths(svg)
  local result = {}
  for tag in svg:gmatch('<circle class="point"[^>]*/>') do
    result[#result + 1] = tonumber(tag:match('stroke%-width="([^"]*)"'))
  end
  return result
end

test("scatter keeps a scalar linewidth by default", function()
  local fig = plt.figure()
  fig:scatter({ 1, 2 }, { 1, 2 }, { edgecolor = "#000000", linewidth = 1.5 })
  local values = widths(fig:to_svg())
  assert_equal(values[1], 1.5)
  assert_equal(values[2], 1.5)
  assert_equal(fig:to_scene().series[1].style.linewidths, nil)
end)

test("scatter accepts one linewidth per point", function()
  local fig = plt.figure()
  fig:scatter({ 1, 2, 3 }, { 1, 2, 3 }, {
    edgecolor = "#000000", linewidth = { 0.5, 1.5, 3 },
  })
  local values = widths(fig:to_svg())
  assert_equal(values[1], 0.5)
  assert_equal(values[2], 1.5)
  assert_equal(values[3], 3)
  local scene = fig:to_scene().series[1]
  assert_equal(scene.style.linewidths[2], 1.5)
end)

test("polar scatter linewidth arrays are supported", function()
  local fig = plt.figure({ width = 480, height = 480 })
  fig:polar_scatter({ 0, 1 }, { 1, 2 }, {
    marker = "square", edgecolor = "#111111", linewidth = { 0.75, 2 },
  })
  local scene = fig:to_scene().polar.series[1]
  assert_equal(scene.style.linewidths[1], 0.75)
  assert_equal(scene.style.linewidths[2], 2)
end)

test("scatter linewidth arrays validate length and values", function()
  local fig = plt.figure()
  assert_error("match the number of points", function()
    fig:scatter({ 1, 2 }, { 1, 2 }, { linewidth = { 1 } })
  end)
  assert_error("must be >= 0", function()
    fig:scatter({ 1, 2 }, { 1, 2 }, { linewidth = { 1, -1 } })
  end)
end)
