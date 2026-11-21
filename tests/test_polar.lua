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
