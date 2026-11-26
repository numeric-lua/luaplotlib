local plt = require("luaplotlib")

local function strokes(svg)
  local values = {}
  for tag in svg:gmatch('<circle class="point"[^>]*/>') do
    local value = tag:match('stroke="([^"]*)"')
    if value ~= nil then values[#values + 1] = value end
  end
  return values
end

test("scatter edgecolor accepts one color per point", function()
  local fig = plt.figure()
  fig:scatter({ 1, 2, 3 }, { 1, 2, 3 }, {
    edgecolor = { "#ff0000", "#00ff00", "#0000ff" }, linewidth = 1,
  })
  local values = strokes(fig:to_svg())
  assert_equal(#values, 3)
  assert_equal(values[1], "#ff0000")
  assert_equal(values[3], "#0000ff")
  local edges = fig:to_scene().series[1].style.edgecolors
  assert_equal(edges[2], "#00ff00")
end)

test("polar scatter edgecolor arrays are supported", function()
  local fig = plt.figure({ width = 480, height = 480 })
  fig:polar_scatter({ 0, 1 }, { 1, 2 }, {
    marker = "square", edgecolor = { "#111111", "#eeeeee" },
  })
  local scene = fig:to_scene().polar.series[1]
  assert_equal(scene.style.edgecolors[1], "#111111")
  assert_equal(scene.style.edgecolors[2], "#eeeeee")
end)

test("scatter edgecolor arrays validate length and colors", function()
  local fig = plt.figure()
  assert_error("match the number of points", function()
    fig:scatter({ 1, 2 }, { 1, 2 }, { edgecolor = { "#fff" } })
  end)
  assert_error("edgecolor", function()
    fig:scatter({ 1, 2 }, { 1, 2 }, { edgecolor = { "#fff", "12bad" } })
  end)
end)
