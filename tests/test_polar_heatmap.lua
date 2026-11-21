-- Polar heatmap projection tests: annular cells, limits, scene export, and
-- validation.  These are text-level SVG checks; no image library is needed.

local plt = require("luaplotlib")

local function field(rows, cols)
  local values = {}
  for row = 1, rows do
    values[row] = {}
    for col = 1, cols do
      values[row][col] = row * 10 + col
    end
  end
  return values
end

local function count(svg, pattern)
  return select(2, svg:gsub(pattern, ""))
end

test("polar heatmap projects a full-turn matrix into annular cells", function()
  local values = field(4, 8)
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_heatmap(values, { label = "field" })
  figure:legend({ loc = "best" })
  local svg = figure:to_svg()

  assert_contains(svg, 'class="series series-polar-heatmap"')
  assert_contains(svg, 'data-rows="4" data-cols="8"')
  assert_contains(svg, 'data-vmin="11" data-vmax="48"')
  assert_contains(svg, 'data-rmin="0" data-rmax="4"')
  assert_contains(svg, 'data-theta-min="0"')
  assert_contains(svg, 'data-label="field"')
  assert_equal(count(svg, 'class="polar%-heatmap%-cell"'), 32)
  assert_equal(count(svg, '<circle class="polar%-heatmap%-cell"'), 8)
  assert_equal(count(svg, '<path class="polar%-heatmap%-cell"'), 24)
  assert_contains(svg, 'class="polar-legend"')
  assert_contains(svg, ">field<")
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  assert_equal(#scene.polar.heatmaps, 1)
  local exported = scene.polar.heatmaps[1]
  assert_equal(exported.kind, "heatmap")
  assert_equal(exported.rows, 4)
  assert_equal(exported.cols, 8)
  assert_equal(exported.values[1][1], 11)
  assert_equal(exported.values[4][8], 48)
  assert_equal(exported.rmax, 4)
  assert_true(math.abs(exported.theta_max - 2 * math.pi) < 1e-12)
  assert_equal(scene.polar.legend.entries[1].kind, "heatmap")
  assert_equal(scene.polar.legend.entries[1].label, "field")
end)

test("polar heatmap input and scene values are copied", function()
  local values = field(2, 3)
  local figure = plt.figure({ width = 500, height = 500 })
  figure:polar_heatmap(values)
  values[1][1] = -999
  values[2][3] = 999
  local scene = figure:to_scene()
  assert_equal(scene.polar.heatmaps[1].values[1][1], 11)
  assert_equal(scene.polar.heatmaps[1].values[2][3], 23)
end)

test("polar heatmap supports radial ranges, partial sweeps, and overlay order",
    function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_heatmap(field(3, 6), {
    rmin = 1, rmax = 5, theta_min = 0, theta_max = math.pi,
    vmin = 0, vmax = 100, alpha = 0.5,
  })
  figure:polar({ 0, math.pi }, { 3, 3 }, { label = "overlay" })
  local svg = figure:to_svg()

  assert_equal(count(svg, 'class="polar%-heatmap%-cell"'), 18)
  assert_equal(count(svg, '<circle class="polar%-heatmap%-cell"'), 0)
  assert_contains(svg, 'data-rmin="1" data-rmax="5"')
  assert_contains(svg, 'data-vmin="0" data-vmax="100"')
  assert_contains(svg, 'data-theta-max="3.142"')
  assert_contains(svg, 'fill-opacity="0.5"')
  assert_contains(svg, 'stroke-opacity="0.5"')
  local heatmap_at = svg:find('series%-polar%-heatmap')
  local line_at = svg:find('series%-polar%-line')
  assert_true(heatmap_at ~= nil and line_at ~= nil)
  assert_true(heatmap_at < line_at,
    "heatmap should render beneath line series")
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  assert_equal(scene.polar.heatmaps[1].rmin, 1)
  assert_equal(scene.polar.heatmaps[1].rmax, 5)
  assert_true(math.abs(scene.polar.heatmaps[1].theta_max - math.pi) < 1e-12)
end)

test("polar heatmap accepts degrees and the pcolormesh alias", function()
  local figure = plt.figure({ width = 600, height = 600 })
  assert_equal(figure:polar_pcolormesh(field(2, 4), {
    degrees = true, theta_min = 0, theta_max = 180, rmax = 2,
    label = "half turn",
  }), figure)
  local svg = figure:to_svg()
  assert_equal(count(svg, 'class="polar%-heatmap%-cell"'), 8)
  assert_contains(svg, 'data-theta-min="0"')
  assert_contains(svg, 'data-theta-max="3.142"')
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  assert_true(math.abs(scene.polar.heatmaps[1].theta_max - math.pi) < 1e-12)
  assert_equal(scene.polar.heatmaps[1].rmax, 2)
end)

test("polar heatmap composes in subplots and respects configured rmax", function()
  local parent, axes = plt.subplots(1, 2, { width = 800, height = 400 })
  axes[1][1]:polar_heatmap(field(2, 4), { label = "left" })
  axes[1][2]:polar_config({ rmax = 3 })
  axes[1][2]:polar_heatmap(field(2, 4))
  local svg = parent:to_svg()
  assert_contains(svg, 'data-subplots="1x2"')
  assert_equal(select(2, svg:gsub('data%-polar="true"', "")), 2)
  assert_contains(svg, 'class="series series-polar-heatmap"')
  assert_well_formed_svg(svg)

  -- An implicit heatmap extent follows an explicitly configured radial limit.
  local configured = plt.figure({ width = 500, height = 500 })
  configured:polar_config({ rmax = 12 })
  configured:polar_heatmap(field(2, 3))
  local configured_scene = configured:to_scene()
  assert_equal(configured_scene.polar.heatmaps[1].rmax, 12)
end)

test("polar heatmap implicit extent follows a late rmax and rgrids", function()
  local late = plt.figure({ width = 500, height = 500 })
  late:polar_heatmap(field(12, 4))
  late:polar_config({ rmax = 6 })
  local late_svg = late:to_svg()
  assert_contains(late_svg, 'data-rmax="6"')
  assert_well_formed_svg(late_svg)
  assert_equal(late:to_scene().polar.heatmaps[1].rmax, 6)

  local gridded = plt.figure({ width = 500, height = 500 })
  gridded:polar_config({ rgrids = { 12 } })
  gridded:polar_heatmap(field(2, 3))
  local gridded_svg = gridded:to_svg()
  assert_true(tonumber(gridded_svg:match('data%-rmax="([^"]+)"')) >= 12,
    "automatic rmax should cover explicit radial grids")
  assert_well_formed_svg(gridded_svg)
end)

test("polar heatmap validates the matrix, limits, and options", function()
  local function figure()
    return plt.figure({ width = 500, height = 500 })
  end
  assert_error("row 1 must be a table", function()
    figure():polar_heatmap({ 1, 2 })
  end)
  assert_error("equal length", function()
    figure():polar_heatmap({ { 1, 2 }, { 3 } })
  end)
  assert_error("non%-finite", function()
    figure():polar_heatmap({ { 1, 0 / 0 } })
  end)
  assert_error("rmin must be >= 0", function()
    figure():polar_heatmap({ { 1 } }, { rmin = -1 })
  end)
  assert_error("greater than rmin", function()
    figure():polar_heatmap({ { 1 } }, { rmin = 2, rmax = 2 })
  end)
  assert_error("theta_max must be greater", function()
    figure():polar_heatmap({ { 1 } }, { theta_min = 1, theta_max = 0 })
  end)
  assert_error("at most 2%*pi", function()
    figure():polar_heatmap({ { 1 } }, { theta_min = 0, theta_max = 7 })
  end)
  assert_error("alpha must be <= 1", function()
    figure():polar_heatmap({ { 1 } }, { alpha = 2 })
  end)
  assert_error("unsupported polar heatmap option", function()
    figure():polar_heatmap({ { 1 } }, { bogus = true })
  end)
  assert_error("cannot both be set", function()
    figure():polar_heatmap({ { 1 } }, {
      degrees = true, theta_unit = "degrees",
    })
  end)
  assert_error("cannot combine pie and polar", function()
    local fig = figure()
    fig:pie({ 1 })
    fig:polar_heatmap({ { 1 } })
  end)
  assert_error("cannot mix cartesian and polar", function()
    local fig = figure()
    fig:plot({ 1, 2 }, { 1, 2 })
    fig:polar_heatmap({ { 1 } })
  end)
  assert_error("cannot mix cartesian and polar", function()
    local fig = figure()
    fig:polar_heatmap({ { 1 } })
    fig:plot({ 1, 2 }, { 1, 2 })
    fig:to_svg()
  end)
  assert_error("exceeds the configured rmax", function()
    local fig = figure()
    fig:polar_config({ rmax = 2 })
    fig:polar_heatmap({ { 1, 2 }, { 3, 4 } }, { rmax = 3 })
    fig:to_svg()
  end)
  assert_error("must be less than its rmax", function()
    local fig = figure()
    fig:polar_heatmap({ { 1 } }, { rmin = 2 })
    fig:to_svg()
  end)
end)

test("polar heatmap scene does not alter cartesian scene shape", function()
  local cartesian = plt.figure({ width = 400, height = 300 })
  cartesian:plot({ 1, 2 }, { 2, 1 })
  local scene = cartesian:to_scene()
  assert_equal(scene.polar, nil)
  assert_equal(scene.orientation, nil)
end)
