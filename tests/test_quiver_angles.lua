local plt = require("luaplotlib")

local function first_angle(svg)
  return tonumber(svg:match('class="quiver%-arrow"[^>]*data%-angle="([^"]*)"'))
end

test("quiver defaults to xy angle projection", function()
  local fig = plt.figure()
  fig:quiver({ 1 }, { 1 }, { 1 }, { 1 })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-angles="xy"')
  assert_equal(fig:to_scene().series[1].angles, "xy")
end)

test("quiver uv angles differ from xy angles on unequal axes", function()
  local function build(angles)
    local fig = plt.figure({ width = 700, height = 420 })
    fig:xlim(0, 100)
    fig:ylim(0, 1)
    fig:quiver({ 1 }, { 0.5 }, { 1 }, { 1 }, { angles = angles })
    return first_angle(fig:to_svg())
  end
  local xy = build("xy")
  local uv = build("uv")
  assert_true(xy ~= nil and uv ~= nil)
  assert_true(math.abs(xy - uv) > 10,
    "uv projection should not follow the stretched data axes")
  assert_true(math.abs(uv + 45) < 1e-6,
    "uv projection should use screen-space components")
end)

test("quiver angles validate and export the mode", function()
  local fig = plt.figure()
  fig:quiver({ 1 }, { 1 }, { 1 }, { 0 }, { angles = "uv" })
  assert_contains(fig:to_svg(), 'data-angles="uv"')
  assert_equal(fig:to_scene().series[1].angles, "uv")
  assert_error("angles must be 'xy' or 'uv'", function()
    fig:quiver({ 1 }, { 1 }, { 1 }, { 0 }, { angles = "screen" })
  end)
end)
