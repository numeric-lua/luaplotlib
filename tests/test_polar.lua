local plt = require("luaplotlib")

local function number_attr(svg, name)
  return tonumber(svg:match('data%-' .. name .. '="([%d%.%-]+)"'))
end

local function polar_points(svg)
  local points = svg:match('class="polar%-line" points="([^"]+)"')
  assert_true(points ~= nil, "expected a polar polyline")
  local result = {}
  for pair in points:gmatch("%S+") do
    local x, y = pair:match("^([^,]+),(.+)$")
    assert_true(x ~= nil and y ~= nil, "expected an x,y polar point")
    result[#result + 1] = { tonumber(x), tonumber(y) }
  end
  return result
end

test("polar line renders circular grid, spokes, and theta labels", function()
  local fig = plt.figure({ width = 600, height = 600 })
  fig:polar({ 0, math.pi / 2, math.pi }, { 2, 4, 6 }, {
    label = "sample",
    color = "#1f77b4",
  })
  fig:title("polar")
  local svg = fig:to_svg()
  assert_contains(svg, 'data-polar="true"')
  assert_contains(svg, 'data-theta-unit="radians"')
  assert_contains(svg, 'class="polar-frame"')
  assert_contains(svg, 'class="polar-line"')
  assert_contains(svg, 'data-label="sample"')
  assert_contains(svg, 'class="title"')
  assert_equal(select(2, svg:gsub('class="polar%-spoke"', "")), 8)
  assert_true(select(2, svg:gsub('class="polar%-circle"', "")) >= 3,
    "expected concentric radial grid circles")
  assert_contains(svg, "0\194\176")
  assert_contains(svg, "90\194\176")
  assert_contains(svg, "270\194\176")
  assert_well_formed_svg(svg)
end)

test("polar theta/r conversion maps cardinal directions", function()
  local fig = plt.figure({ width = 600, height = 600 })
  fig:polar({ 0, math.pi / 2, math.pi, -math.pi / 2 }, { 5, 5, 5, 5 })
  local svg = fig:to_svg()
  local cx = number_attr(svg, "cx")
  local cy = number_attr(svg, "cy")
  local radius = number_attr(svg, "radius")
  local rmax = number_attr(svg, "rmax")
  assert_true(cx ~= nil and cy ~= nil and radius ~= nil and rmax ~= nil,
    "expected polar geometry metadata")
  local scale = radius * 5 / rmax
  local points = polar_points(svg)
  assert_equal(#points, 4)
  local expected = {
    { cx + scale, cy },
    { cx, cy - scale },
    { cx - scale, cy },
    { cx, cy + scale },
  }
  for index = 1, #expected do
    assert_true(math.abs(points[index][1] - expected[index][1]) < 0.01,
      "unexpected x for point " .. index)
    assert_true(math.abs(points[index][2] - expected[index][2]) < 0.01,
      "unexpected y for point " .. index)
  end
  assert_well_formed_svg(svg)
end)

test("negative polar radii plot on the opposite side of the origin", function()
  local fig = plt.figure({ width = 600, height = 600 })
  fig:polar({ 0 }, { -4 })
  local svg = fig:to_svg()
  local cx = number_attr(svg, "cx")
  local cy = number_attr(svg, "cy")
  local radius = number_attr(svg, "radius")
  local rmax = number_attr(svg, "rmax")
  local points = polar_points(svg)
  assert_equal(#points, 1)
  assert_true(math.abs(points[1][1] - (cx - radius * 4 / rmax)) < 0.01,
    "negative r should extend left of the center")
  assert_true(math.abs(points[1][2] - cy) < 0.01)
end)

test("plt.polar returns a figure and performs automatic radial limits", function()
  local fig = plt.polar({ 0, math.pi / 2 }, { 3, 4 })
  assert_equal(fig.width, 640)
  assert_equal(fig.height, 480)
  assert_equal(#fig._polar.series, 1)
  local svg = fig:to_svg()
  local rmax = number_attr(svg, "rmax")
  assert_true(rmax >= 4 and rmax <= 5,
    "automatic rmax should cover the data with a small margin")
  assert_contains(svg, 'data-rmax="' .. rmax .. '"')

  local path = (TMPDIR or "/tmp") .. "/luaplotlib-polar.svg"
  assert_equal(fig:savefig(path), path)
  local handle = assert(io.open(path, "rb"))
  local contents = handle:read("*a")
  handle:close()
  os.remove(path)
  assert_contains(contents, 'data-polar="true"')
  assert_well_formed_svg(contents)
end)

test("polar validates data and refuses mixed axes", function()
  assert_error("same length", function()
    plt.figure():polar({ 0, 1 }, { 1 })
  end)
  assert_error("must not be empty", function()
    plt.figure():polar({}, {})
  end)
  assert_error("must be finite", function()
    plt.figure():polar({ 0 / 0 }, { 1 })
  end)
  assert_error("unsupported polar option", function()
    plt.figure():polar({ 0 }, { 1 }, { bogus = true })
  end)
  assert_error("cannot mix cartesian and polar", function()
    local fig = plt.figure()
    fig:plot({ 1, 2 }, { 1, 2 })
    fig:polar({ 0 }, { 1 })
  end)
  assert_error("cannot mix cartesian and polar", function()
    local fig = plt.figure()
    fig:polar({ 0 }, { 1 })
    fig:plot({ 1, 2 }, { 1, 2 })
    fig:to_svg()
  end)
  assert_error("cannot combine pie and polar", function()
    local fig = plt.figure()
    fig:polar({ 0 }, { 1 })
    fig:pie({ 1 })
  end)
  assert_error("cannot combine pie and polar", function()
    local fig = plt.figure()
    fig:pie({ 1 })
    fig:polar({ 0 }, { 1 })
  end)
end)

test("polar line markers and scatter support per-point styles", function()
  local fig = plt.figure({ width = 600, height = 600 })
  fig:polar({ 0, math.pi / 2 }, { 2, 3 }, {
    marker = "square", markersize = 6, label = "line",
  })
  fig:polar_scatter({ 0, math.pi / 2, math.pi }, { 4, 4, 4 }, {
    size = { 4, 8, 12 },
    color = { "#ff0000", "#00ff00", "#0000ff" },
    label = "points",
  })
  fig:legend({ title = "series" })
  local svg = fig:to_svg()
  assert_equal(select(2, svg:gsub('class="marker"', "")), 2)
  assert_equal(select(2, svg:gsub('class="point"', "")), 3)
  assert_contains(svg, 'fill="#ff0000"')
  assert_contains(svg, 'fill="#00ff00"')
  assert_contains(svg, 'fill="#0000ff"')
  assert_contains(svg, 'class="polar-legend"')
  assert_contains(svg, '>line<')
  assert_contains(svg, '>points<')
  assert_contains(svg, '>series<')
  assert_well_formed_svg(svg)
end)

test("a single polar line point is still visible", function()
  local fig = plt.figure({ width = 400, height = 400 })
  fig:polar({ 0 }, { 2 })
  local svg = fig:to_svg()
  assert_equal(select(2, svg:gsub('class="marker"', "")), 1)
  assert_contains(svg, 'class="marker"')
end)

test("polar scatter validates arrays and options", function()
  assert_error("same length", function()
    plt.figure():polar_scatter({ 0, 1 }, { 1 })
  end)
  assert_error("size array must match", function()
    plt.figure():polar_scatter({ 0, 1 }, { 1, 2 }, { size = { 4 } })
  end)
  assert_error("color array must match", function()
    plt.figure():polar_scatter({ 0, 1 }, { 1, 2 },
      { color = { "#ff0000" } })
  end)
  assert_error("unsupported polar scatter option", function()
    plt.figure():polar_scatter({ 0 }, { 1 }, { bogus = true })
  end)
  assert_error("must be finite", function()
    plt.figure():polar_scatter({ 0 / 0 }, { 1 })
  end)
  assert_error("cannot mix cartesian and polar", function()
    local fig = plt.figure()
    fig:plot({ 1, 2 }, { 1, 2 })
    fig:polar_scatter({ 0 }, { 1 })
  end)
end)

test("polar bars render wedges with per-bar widths and colors", function()
  local fig = plt.figure({ width = 600, height = 600 })
  fig:polar_bar({ 0, math.pi / 2, math.pi }, { 3, 4, 5 }, {
    width = { math.pi / 4, math.pi / 2, 3 * math.pi / 2 },
    colors = { "#ff0000", "#00ff00", "#0000ff" },
    label = "bars",
    edgecolor = "#333333",
  })
  fig:legend()
  local svg = fig:to_svg()
  assert_equal(select(2, svg:gsub('class="polar%-bar"', "")), 3)
  assert_contains(svg, 'fill="#ff0000"')
  assert_contains(svg, 'fill="#00ff00"')
  assert_contains(svg, 'fill="#0000ff"')
  assert_contains(svg, 'stroke="#333333"')
  assert_match(svg, "A [%d%.]+ [%d%.]+ 0 1 0")
  assert_contains(svg, 'class="series series-polar-bar"')
  assert_contains(svg, 'class="polar-legend"')
  assert_contains(svg, '>bars<')
  assert_well_formed_svg(svg)
end)

test("a full-turn polar bar renders as a disk", function()
  local fig = plt.figure({ width = 400, height = 400 })
  fig:polar_bar({ 0 }, { 2 }, { width = 2 * math.pi })
  local svg = fig:to_svg()
  assert_equal(select(2, svg:gsub('class="polar%-bar"', "")), 1)
  assert_contains(svg, '<circle class="polar-bar"')
  assert_well_formed_svg(svg)
end)

test("polar bar validates values, widths, and colors", function()
  assert_error("same length", function()
    plt.figure():polar_bar({ 0, 1 }, { 1 })
  end)
  assert_error("non%-negative", function()
    plt.figure():polar_bar({ 0 }, { -1 })
  end)
  assert_error("width array must match", function()
    plt.figure():polar_bar({ 0, 1 }, { 1, 2 }, { width = { 0.5 } })
  end)
  assert_error("width must be positive", function()
    plt.figure():polar_bar({ 0 }, { 1 }, { width = 0 })
  end)
  assert_error("at most 2%*pi", function()
    plt.figure():polar_bar({ 0 }, { 1 }, { width = 7 })
  end)
  assert_error("one entry per bar", function()
    plt.figure():polar_bar({ 0, 1 }, { 1, 2 }, { colors = { "#ff0000" } })
  end)
  assert_error("cannot both be set", function()
    plt.figure():polar_bar({ 0 }, { 1 }, {
      color = "#ff0000", colors = { "#00ff00" },
    })
  end)
  assert_error("unsupported polar bar option", function()
    plt.figure():polar_bar({ 0 }, { 1 }, { bogus = true })
  end)
end)

test("polar config rotates the zero location and direction", function()
  local fig = plt.figure({ width = 600, height = 600 })
  fig:polar_config({ theta_zero = "N", rmax = 5 })
  fig:polar({ 0 }, { 5 })
  local svg = fig:to_svg()
  local cx = number_attr(svg, "cx")
  local cy = number_attr(svg, "cy")
  local radius = number_attr(svg, "radius")
  local point = polar_points(svg)[1]
  assert_true(math.abs(point[1] - cx) < 0.01)
  assert_true(math.abs(point[2] - (cy - radius)) < 0.01,
    "theta=0 should point north when theta_zero is N")
  assert_contains(svg, 'data-theta-zero="1.571"')
  assert_contains(svg, 'data-theta-direction="counterclockwise"')

  local clockwise = plt.figure({ width = 600, height = 600 })
  clockwise:polar_config({ theta_direction = "clockwise", rmax = 5 })
  clockwise:polar({ math.pi / 2 }, { 5 })
  local cw_svg = clockwise:to_svg()
  local cw_cx = number_attr(cw_svg, "cx")
  local cw_cy = number_attr(cw_svg, "cy")
  local cw_radius = number_attr(cw_svg, "radius")
  local cw_point = polar_points(cw_svg)[1]
  assert_true(math.abs(cw_point[1] - cw_cx) < 0.01)
  assert_true(math.abs(cw_point[2] - (cw_cy + cw_radius)) < 0.01,
    "theta=90 should point south when direction is clockwise")
  assert_contains(cw_svg, 'data-theta-direction="clockwise"')
end)

test("polar config accepts explicit radial and angular grids", function()
  local fig = plt.figure({ width = 600, height = 600 })
  fig:polar_config({
    rmax = 2,
    rgrids = { 1, 2 },
    thetagrids = { 0, 90, 180, 270 },
    thetagrid_labels = { "E", "N", "W", "S" },
  })
  fig:polar({ 0 }, { 1.5 })
  local svg = fig:to_svg()
  assert_equal(select(2, svg:gsub('class="polar%-spoke"', "")), 4)
  assert_equal(select(2, svg:gsub('class="polar%-circle"', "")), 1)
  assert_contains(svg, ">E<")
  assert_contains(svg, ">N<")
  assert_contains(svg, ">W<")
  assert_contains(svg, ">S<")
  assert_not_contains(svg, "45\194\176")
  assert_contains(svg, '>1<')
  assert_contains(svg, '>2<')
  assert_well_formed_svg(svg)

  assert_error("exceeds the configured rmax", function()
    local bad = plt.figure()
    bad:polar_config({ rmax = 2, rgrids = { 3 } })
    bad:polar({ 0 }, { 1 })
    bad:to_svg()
  end)
  assert_error("exceeds the configured rmax", function()
    local bad = plt.figure()
    bad:polar_config({ rmax = 2 })
    bad:polar({ 0 }, { 3 })
    bad:to_svg()
  end)
end)

test("polar series accept degrees and theta_unit", function()
  local fig = plt.figure({ width = 600, height = 600 })
  fig:polar_config({ rmax = 5 })
  fig:polar_scatter({ 0, 90, 180 }, { 5, 5, 5 }, { degrees = true })
  local svg = fig:to_svg()
  local cx = number_attr(svg, "cx")
  local cy = number_attr(svg, "cy")
  local radius = number_attr(svg, "radius")
  local group = svg:match('class="series%-layer"[^>]*>(.-)</g>')
  assert_true(group ~= nil)
  -- Parse attribute pairs directly instead of relying on XML parsing.
  local count = 0
  for x, y in group:gmatch('class="point" cx="([^"]+)" cy="([^"]+)"') do
    count = count + 1
    local xv, yv = tonumber(x), tonumber(y)
    if count == 1 then
      assert_true(math.abs(xv - (cx + radius)) < 0.01)
      assert_true(math.abs(yv - cy) < 0.01)
    elseif count == 2 then
      assert_true(math.abs(xv - cx) < 0.01)
      assert_true(math.abs(yv - (cy - radius)) < 0.01)
    else
      assert_true(math.abs(xv - (cx - radius)) < 0.01)
      assert_true(math.abs(yv - cy) < 0.01)
    end
  end
  assert_equal(count, 3)

  local unit = plt.figure({ width = 600, height = 600 })
  unit:polar_config({ rmax = 5 })
  unit:polar({ 90 }, { 5 }, { theta_unit = "degrees" })
  local unit_svg = unit:to_svg()
  local unit_point = polar_points(unit_svg)[1]
  local unit_cy = number_attr(unit_svg, "cy")
  local unit_radius = number_attr(unit_svg, "radius")
  assert_true(math.abs(unit_point[2] - (unit_cy - unit_radius)) < 0.01)

  assert_error("cannot both be set", function()
    plt.figure():polar({ 0 }, { 1 }, { degrees = true, theta_unit = "degrees" })
  end)
  assert_error("must be a boolean", function()
    plt.figure():polar({ 0 }, { 1 }, { degrees = "yes" })
  end)
  assert_error("unit must be", function()
    plt.figure():polar({ 0 }, { 1 }, { theta_unit = "turns" })
  end)
end)

test("polar scene export includes orientation, grids, and series", function()
  local fig = plt.figure({ width = 600, height = 600 })
  fig:polar_config({
    theta_zero = "N",
    theta_direction = "clockwise",
    rmax = 10,
    thetagrids = { 0, 90 },
    thetagrid_labels = { "zero", "ninety" },
    rgrids = { 2.5, 5 },
  })
  fig:polar({ 0, math.pi }, { 1, 2 }, { label = "line" })
  fig:polar_scatter({ 0 }, { 3 }, {
    size = { 5 }, color = { "#ff0000" }, label = "point",
  })
  fig:polar_bar({ 0 }, { 4 }, {
    width = 0.5, colors = { "#00ff00" }, label = "bar",
  })
  fig:legend()

  local scene = fig:to_scene()
  assert_equal(scene.type, "luaplotlib")
  assert_equal(scene.orientation, "polar")
  assert_equal(scene.polar.theta_unit, "radians")
  assert_true(math.abs(scene.polar.theta_zero - math.pi / 2) < 1e-12)
  assert_equal(scene.polar.theta_direction, "clockwise")
  assert_equal(scene.polar.rmax, 10)
  assert_equal(#scene.polar.theta_ticks, 2)
  assert_equal(scene.polar.theta_ticks[1].label, "zero")
  assert_true(math.abs(scene.polar.theta_ticks[2].degrees - 90) < 1e-12)
  assert_equal(#scene.polar.r_ticks, 2)
  assert_equal(scene.polar.r_ticks[2].value, 5)
  assert_equal(#scene.polar.series, 3)
  assert_equal(scene.polar.series[1].kind, "line")
  assert_equal(scene.polar.series[1].theta[1], 0)
  assert_equal(scene.polar.series[1].style.label, "line")
  assert_equal(scene.polar.series[2].kind, "scatter")
  assert_equal(scene.polar.series[2].radii[1], 5)
  assert_equal(scene.polar.series[2].colors[1], "#ff0000")
  assert_equal(scene.polar.series[3].widths[1], 0.5)
  assert_equal(scene.polar.series[3].colors[1], "#00ff00")
  assert_equal(#scene.series, 0)
  assert_true(scene.legend)
  assert_equal(plt.scene.from_figure(fig).orientation, "polar")
end)

test("polar figures compose inside subplots", function()
  local parent, axes = plt.subplots(1, 2, { width = 800, height = 400 })
  axes[1][2]:polar_config({ rmax = 5 })
  axes[1][2]:polar({ 0, math.pi / 2 }, { 5, 5 })
  axes[1][2]:title("polar cell")
  local svg = parent:to_svg()
  assert_contains(svg, 'data-subplots="1x2"')
  assert_contains(svg, 'data-polar="true"')
  assert_contains(svg, ">polar cell<")
  assert_equal(select(2, svg:gsub("<%?xml", "")), 1)
  assert_well_formed_svg(svg)
end)

test("polar_config validates orientation and grid options", function()
  assert_error("theta_zero must be", function()
    plt.figure():polar_config({ theta_zero = "Q" })
  end)
  assert_error("theta_direction must be", function()
    plt.figure():polar_config({ theta_direction = "sideways" })
  end)
  assert_error("rmax must be positive", function()
    plt.figure():polar_config({ rmax = 0 })
  end)
  assert_error("non%-empty", function()
    plt.figure():polar_config({ thetagrids = {} })
  end)
  assert_error("one entry per grid value", function()
    plt.figure():polar_config({
      thetagrids = { 0, 90 }, thetagrid_labels = { "only one" },
    })
  end)
  assert_error("requires thetagrids", function()
    plt.figure():polar_config({ thetagrid_labels = { "x" } })
  end)
  assert_error("requires rgrids", function()
    plt.figure():polar_config({ rgrid_labels = { "x" } })
  end)
  assert_error("values must be positive", function()
    plt.figure():polar_config({ rgrids = { 0 } })
  end)
  assert_error("unsupported polar_config option", function()
    plt.figure():polar_config({ bogus = true })
  end)
  assert_error("cannot mix cartesian and polar", function()
    local fig = plt.figure()
    fig:plot({ 1, 2 }, { 1, 2 })
    fig:polar_config({ rmax = 1 })
  end)
end)

test("polar_config applies after series and supports an empty polar axes", function()
  local fig = plt.figure({ width = 500, height = 500 })
  fig:polar({ 0 }, { 2 })
  fig:polar_config({ rmax = 4 })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-rmax="4"')

  local empty = plt.figure({ width = 500, height = 500 })
  empty:polar_config({ rmax = 1 })
  local empty_svg = empty:to_svg()
  assert_contains(empty_svg, 'class="polar-frame"')
  assert_well_formed_svg(empty_svg)
end)
