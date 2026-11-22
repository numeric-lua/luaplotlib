-- Cartesian regression guards for the polar streamplot work.  Adding a new
-- polar series must not change Cartesian SVG output, Cartesian scene shape,
-- quiver scene metadata, or per-figure palette assignment.

local plt = require("luaplotlib")

local function cartesian_figure()
  local figure = plt.figure({ width = 480, height = 360 })
  figure:plot({ 1, 2, 3 }, { 3, 1, 2 }, { color = "#123456", label = "line" })
  figure:scatter({ 1, 2 }, { 2, 3 }, { color = "#654321", marker = "square" })
  figure:title("Cartesian baseline")
  figure:xlabel("x")
  figure:ylabel("y")
  figure:legend({ loc = "upper right" })
  return figure
end

local function polar_figure()
  local theta, r = {}, { 1, 2, 3 }
  for index = 1, 9 do
    theta[index] = (index - 1) * 2 * math.pi / 8
  end
  local u, v = {}, {}
  for row = 1, #r do
    u[row], v[row] = {}, {}
    for column = 1, #theta do
      u[row][column] = 1
      v[row][column] = 0
    end
  end
  local figure = plt.figure({ width = 480, height = 480 })
  figure:polar_config({ rmax = 3 })
  figure:polar_streamplot(theta, r, u, v, {
    density = 0.6, linestyle = "dashed", arrow_fraction = 0.95,
    head = 26, step = 0.05,
  })
  return figure
end

local function deep_equal(first, second)
  if type(first) ~= type(second) then return false end
  if type(first) ~= "table" then return first == second end
  for key, value in pairs(first) do
    if not deep_equal(value, second[key]) then return false end
  end
  for key in pairs(second) do
    if first[key] == nil then return false end
  end
  return true
end

test("polar streamplot leaves Cartesian SVG output byte-identical", function()
  local figure = cartesian_figure()
  local before_svg = figure:to_svg()
  local before_scene = figure:to_scene()

  -- Creating, rendering, and exporting another figure must not touch this one.
  local polar = polar_figure()
  polar:to_svg()
  polar:to_scene()

  assert_equal(figure:to_svg(), before_svg)
  local after_scene = figure:to_scene()
  assert_true(deep_equal(after_scene, before_scene),
    "Cartesian scene must not change when a polar figure is created")
  assert_equal(after_scene.polar, nil)
  assert_equal(#after_scene.series, 2)
  assert_equal(after_scene.series[1].kind, "line")
  assert_equal(after_scene.series[2].kind, "scatter")
  assert_not_contains(before_svg, "streamplot")
  assert_not_contains(before_svg, 'data-polar="true"')
  assert_not_contains(before_svg, "data-arrow-fraction")
  assert_not_contains(before_svg, "data-closed-lines")
  assert_not_contains(before_svg, "data-arc-length")
  assert_not_contains(before_svg, "data-clipped-arrow-count")
  assert_not_contains(before_svg, "data-clipped")
  assert_not_contains(before_svg, 'data-clip="polar-circle"')
  assert_not_contains(before_svg, "polar-streamline")
  assert_well_formed_svg(before_svg)
end)

test("polar streamplot leaves quiver scene export unchanged", function()
  local theta = { 0, math.pi / 2, math.pi, 3 * math.pi / 2 }
  local r = { 2, 3, 2, 3 }
  local u = { 1, 1, 1, 1 }
  local v = { 1, 2, 1, 2 }

  local function quiver_figure()
    local figure = plt.figure({ width = 480, height = 480 })
    figure:polar_config({ rmax = 4 })
    figure:polar_quiver(theta, r, u, v, {
      pivot = "middle", max_arrows = 2, label = "vectors",
    })
    figure:legend({ loc = "upper right" })
    return figure
  end

  local figure = quiver_figure()
  local before_svg = figure:to_svg()
  local before = figure:to_scene().polar.series[1]
  polar_figure():to_scene()
  local after = figure:to_scene().polar.series[1]

  assert_equal(figure:to_svg(), before_svg)
  assert_equal(after.kind, "quiver")
  assert_equal(after.components, "tangential_radial")
  assert_equal(after.pivot, "middle")
  assert_equal(after.max_arrows, 2)
  assert_equal(after.stride, 2)
  assert_equal(after.drawn, 2)
  assert_equal(after.u[2], 1)
  assert_equal(after.v[2], 2)
  assert_true(deep_equal(after, before),
    "quiver scene export must not change after a streamplot exists")
  assert_well_formed_svg(before_svg)
end)

test("polar streamplot does not consume another figure's palette", function()
  local cartesian = plt.figure({ width = 400, height = 300 })
  cartesian:plot({ 1, 2 }, { 1, 2 })
  local color = cartesian._series[1].style.color
  polar_figure():to_svg()
  cartesian:plot({ 1, 2 }, { 2, 1 })
  assert_true(cartesian._series[2].style.color ~= color,
    "the Cartesian figure should advance its own palette")
  assert_equal(cartesian._series[1].style.color, color)
  assert_well_formed_svg(cartesian:to_svg())
end)
