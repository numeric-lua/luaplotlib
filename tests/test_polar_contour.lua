-- Polar contour tests: projected marching squares, field extents, style
-- options, legend/scene export parity, and validation.  These are text-level
-- SVG checks; no image library is needed.

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

test("polar contour projects a matrix into clipped curved paths", function()
  local values = field(4, 8)
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_heatmap(values, { label = "field" })
  figure:polar_contour(values, { label = "iso" })
  local svg = figure:to_svg()

  assert_contains(svg, 'class="series series-polar-contour"')
  assert_contains(svg, 'data-rows="4" data-cols="8" data-levels="5"')
  assert_contains(svg, 'data-vmin="11" data-vmax="48"')
  assert_contains(svg, 'data-rmin="0" data-rmax="4"')
  assert_contains(svg, 'data-theta-min="0" data-theta-max="6.283"')
  assert_contains(svg, 'data-label="iso"')
  assert_equal(count(svg, 'class="polar%-contour%-level"'), 5)
  assert_true(count(svg, 'class="polar%-contour%-line"') > 0,
    "expected contour segments")
  assert_match(svg,
    'class="polar%-contour%-line" d="M [%d%.%-]+ [%d%.%-]+ L [%d%.%-]+ [%d%.%-]+ L ')

  -- Heatmaps render first so contours can overlay the projected field.
  local heatmap_at = svg:find('series%-polar%-heatmap')
  local contour_at = svg:find('series%-polar%-contour')
  assert_true(heatmap_at ~= nil and contour_at ~= nil)
  assert_true(heatmap_at < contour_at,
    "heatmap should render beneath contour lines")
  local layer_at = svg:find('<g class="series%-layer"')
  assert_true(layer_at ~= nil and layer_at < contour_at,
    "contours should be clipped by the polar series layer")
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  assert_equal(#scene.polar.contours, 1)
  local contour = scene.polar.contours[1]
  assert_equal(contour.kind, "contour")
  assert_equal(contour.rows, 4)
  assert_equal(contour.cols, 8)
  assert_equal(contour.rmax, 4)
  assert_equal(contour.style.label, "iso")
  assert_equal(#contour.levels, 5)
  local segment = contour.levels[1].segments[1]
  assert_equal(#segment, 4)
  assert_true(segment[1] >= 0 and segment[1] <= 2 * math.pi)
  assert_true(segment[2] >= 0 and segment[2] <= 4)
  assert_well_formed_svg(svg)
end)

test("polar contour input and scene segments are copied", function()
  local values = field(3, 5)
  local figure = plt.figure({ width = 500, height = 500 })
  figure:polar_contour(values, { levels = 2 })
  values[1][1] = -999
  values[3][5] = 999
  local scene = figure:to_scene()
  assert_equal(scene.polar.contours[1].vmin, 11)
  assert_equal(scene.polar.contours[1].vmax, 35)
  assert_true(#scene.polar.contours[1].levels[1].segments > 0)
end)

test("polar contour supports explicit levels, styles, and partial sweeps",
    function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_contour(field(3, 6), {
    levels = { 12.5, 22.5 }, color = "#123456", linewidth = 2,
    linestyle = "dashed", alpha = 0.5, labels = true,
    theta_min = 0, theta_max = 180, degrees = true,
    rmin = 1, rmax = 5, label = "iso",
  })
  local svg = figure:to_svg()

  assert_contains(svg, 'data-levels="2"')
  assert_contains(svg, 'data-rmin="1" data-rmax="5"')
  assert_contains(svg, 'data-theta-min="0" data-theta-max="3.142"')
  assert_contains(svg, 'data-level="12.5"')
  assert_contains(svg, 'data-level="22.5"')
  assert_contains(svg, 'stroke="#123456"')
  assert_contains(svg, 'stroke-width="2"')
  assert_contains(svg, 'stroke-dasharray="6 4"')
  assert_contains(svg, 'stroke-opacity="0.5"')
  assert_contains(svg, 'class="polar-contour-label"')
  assert_contains(svg, 'paint-order="stroke"')
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  local contour = scene.polar.contours[1]
  assert_equal(contour.rmin, 1)
  assert_equal(contour.rmax, 5)
  assert_equal(contour.labels, true)
  assert_true(math.abs(contour.theta_max - math.pi) < 1e-12)
  assert_equal(contour.levels[1].level, 12.5)
  assert_equal(contour.levels[2].level, 22.5)
  local segment = contour.levels[1].segments[1]
  assert_true(segment[2] >= 1 and segment[2] <= 5,
    "segments should use the explicit radial range")
end)

test("polar contour labels rotate along the local tangent inside the frame",
    function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_contour(field(4, 8), { levels = 3, labels = true })
  local svg = figure:to_svg()

  local cx, cy, radius = svg:match(
    'class="polar" data%-cx="([^"]+)" data%-cy="([^"]+)" data%-radius="([^"]+)"')
  assert_true(cx ~= nil, "expected polar geometry")
  cx, cy, radius = tonumber(cx), tonumber(cy), tonumber(radius)

  local labels = 0
  local seen_levels = {}
  for attributes in svg:gmatch(
      '<text class="polar%-contour%-label" ([^>]*)>') do
    labels = labels + 1
    local x = tonumber(attributes:match(' x="([^"]+)"'))
    local y = tonumber(attributes:match(' y="([^"]+)"'))
    local angle = tonumber(attributes:match('data%-angle="([^"]+)"'))
    local level = attributes:match('data%-level="([^"]+)"')
    assert_true(x ~= nil and y ~= nil and angle ~= nil and level ~= nil,
      "contour label should expose position, angle, and level")
    assert_true(angle > -90 and angle <= 90,
      "contour labels should stay upright")
    seen_levels[level] = true

    local dx, dy = x - cx, y - cy
    assert_true(math.sqrt(dx * dx + dy * dy) <= radius,
      "contour label should stay inside the circular frame")
  end
  assert_equal(labels, 3)
  assert_equal(count(svg, 'class="polar%-contour%-label"'), 3)
  local level_count = 0
  for _ in pairs(seen_levels) do level_count = level_count + 1 end
  assert_equal(level_count, 3)
  assert_well_formed_svg(svg)
end)

test("polar contour labels avoid placing text on top of each other", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_contour(field(4, 8), { levels = 3, labels = true })
  figure:polar_contour(field(4, 8), {
    levels = 3, labels = true, color = "#d62728",
  })
  local svg = figure:to_svg()

  local positions = {}
  local labels = 0
  for attributes in svg:gmatch(
      '<text class="polar%-contour%-label" ([^>]*)>') do
    labels = labels + 1
    local x = tonumber(attributes:match(' x="([^"]+)"'))
    local y = tonumber(attributes:match(' y="([^"]+)"'))
    local key = string.format("%.1f,%.1f", x, y)
    assert_true(positions[key] == nil,
      "two contour labels were placed at the same position")
    positions[key] = true
  end
  assert_equal(labels, 6)
  assert_well_formed_svg(svg)
end)

test("polar contour scene exports preferred label anchors", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_contour(field(3, 6), {
    levels = { 12.5, 22.5 }, labels = true,
    theta_min = 0, theta_max = 180, degrees = true,
    rmin = 1, rmax = 5,
  })
  local scene = figure:to_scene()
  local contour = scene.polar.contours[1]
  local first = contour.levels[1].label
  assert_true(first ~= nil, "expected a scene label anchor")
  assert_equal(first.text, "12.5")
  assert_equal(first.u >= 0 and first.u <= 1, true)
  assert_equal(first.v >= 0 and first.v <= 1, true)
  assert_true(first.theta >= 0 and first.theta <= math.pi)
  assert_true(first.r >= 1 and first.r <= 5)
  assert_true(first.angle > -90 and first.angle <= 90)
  assert_true(contour.levels[2].label ~= nil)

  local plain = plt.figure({ width = 500, height = 500 })
  plain:polar_contour(field(3, 6), { levels = 2 })
  assert_equal(plain:to_scene().polar.contours[1].levels[1].label, nil)
end)

test("polar contour follows automatic and late radial limits", function()
  local automatic = plt.figure({ width = 500, height = 500 })
  automatic:polar_contour(field(12, 8))
  local svg = automatic:to_svg()
  assert_contains(svg, 'data-rmax="12"')
  assert_equal(automatic:to_scene().polar.contours[1].rmax, 12)

  local late = plt.figure({ width = 500, height = 500 })
  late:polar_contour(field(4, 8))
  late:polar_config({ rmax = 8 })
  local late_svg = late:to_svg()
  assert_contains(late_svg, 'data-rmax="8"')
  assert_equal(late:to_scene().polar.contours[1].rmax, 8)

  -- The largest extent wins when a heatmap and a contour share the figure.
  local mixed = plt.figure({ width = 500, height = 500 })
  mixed:polar_heatmap(field(3, 6), { rmax = 3 })
  mixed:polar_contour(field(5, 6), { rmax = 5 })
  assert_contains(mixed:to_svg(), 'data-rmax="5"')
end)

test("polar contours participate in the legend and scene legend", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_heatmap(field(2, 4), { label = "field" })
  figure:polar_contour(field(2, 4), { label = "iso", color = "#654321" })
  figure:legend({ loc = "best" })
  local svg = figure:to_svg()
  assert_contains(svg, 'class="polar-legend"')
  assert_contains(svg, '>field<')
  assert_contains(svg, '>iso<')
  assert_contains(svg, 'stroke="#654321"')
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  assert_equal(#scene.polar.legend.entries, 2)
  assert_equal(scene.polar.legend.entries[1].kind, "heatmap")
  assert_equal(scene.polar.legend.entries[2].kind, "contour")
  assert_equal(scene.polar.legend.entries[2].label, "iso")
end)

test("polar contour validates the matrix, levels, and extent", function()
  local function figure()
    return plt.figure({ width = 500, height = 500 })
  end
  assert_error("at least 2x2", function()
    figure():polar_contour({ { 1, 2 } })
  end)
  assert_error("at least 2x2", function()
    figure():polar_contour({ { 1 }, { 2 } })
  end)
  assert_error("levels must be >= 1", function()
    figure():polar_contour(field(2, 2), { levels = 0 })
  end)
  assert_error("levels must be <= 50", function()
    figure():polar_contour(field(2, 2), { levels = 51 })
  end)
  assert_error("positive count or a non%-empty table", function()
    figure():polar_contour(field(2, 2), { levels = {} })
  end)
  assert_error("levels%[1%] must be a number", function()
    figure():polar_contour(field(2, 2), { levels = { "hot" } })
  end)
  assert_error("linestyle must be one of", function()
    figure():polar_contour(field(2, 2), { linestyle = "wavy" })
  end)
  assert_error("linewidth must be >= 0", function()
    figure():polar_contour(field(2, 2), { linewidth = -1 })
  end)
  assert_error("alpha must be <= 1", function()
    figure():polar_contour(field(2, 2), { alpha = 2 })
  end)
  assert_error("rmin must be >= 0", function()
    figure():polar_contour(field(2, 2), { rmin = -1 })
  end)
  assert_error("greater than rmin", function()
    figure():polar_contour(field(2, 2), { rmin = 2, rmax = 2 })
  end)
  assert_error("theta_max must be greater", function()
    figure():polar_contour(field(2, 2), { theta_min = 1, theta_max = 0 })
  end)
  assert_error("at most 2%*pi", function()
    figure():polar_contour(field(2, 2), { theta_min = 0, theta_max = 7 })
  end)
  assert_error("unsupported polar contour option", function()
    figure():polar_contour(field(2, 2), { bogus = true })
  end)
  assert_error("cannot both be set", function()
    figure():polar_contour(field(2, 2), {
      degrees = true, theta_unit = "degrees",
    })
  end)
  assert_error("must be less than its rmax", function()
    local fig = figure()
    fig:polar_contour(field(2, 2), { rmin = 2 })
    fig:to_svg()
  end)
  assert_error("polar contour rmax 3 exceeds the configured rmax 1", function()
    local fig = figure()
    fig:polar_config({ rmax = 1 })
    fig:polar_contour(field(3, 3), { rmax = 3 })
    fig:to_svg()
  end)
  assert_error("cannot combine pie and polar", function()
    local fig = figure()
    fig:pie({ 1 })
    fig:polar_contour(field(2, 2))
  end)
  assert_error("cannot mix cartesian and polar", function()
    local fig = figure()
    fig:plot({ 1, 2 }, { 1, 2 })
    fig:polar_contour(field(2, 2))
  end)
  assert_error("cannot mix cartesian and polar", function()
    local fig = figure()
    fig:polar_contour(field(2, 2))
    fig:plot({ 1, 2 }, { 1, 2 })
    fig:to_svg()
  end)
end)

test("polar contour leaves cartesian scenes and contours unchanged", function()
  local cartesian = plt.figure({ width = 400, height = 300 })
  cartesian:contour({ { 1, 2 }, { 3, 4 } })
  local scene = cartesian:to_scene()
  assert_equal(scene.polar, nil)
  assert_equal(scene.orientation, nil)
  assert_equal(scene.series[1].kind, "contour")
end)
