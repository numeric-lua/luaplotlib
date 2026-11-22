-- Polar quiver tests: local radial/tangential projection, glyph geometry,
-- automatic and explicit scaling, pivots, large-field decimation, scene
-- export, legend integration, validation, and Cartesian isolation.  These are
-- text-level SVG checks; no image library is needed.

local plt = require("luaplotlib")

local function count(svg, pattern)
  return select(2, svg:gsub(pattern, ""))
end

local function number_attr(svg, name)
  return tonumber(svg:match('data%-' .. name .. '="([%d%.%-]+)"'))
end

local function geometry(svg)
  local cx, cy, radius, rmax = svg:match(
    'class="polar" data%-cx="([^"]+)" data%-cy="([^"]+)" ' ..
    'data%-radius="([^"]+)" data%-rmax="([^"]+)"')
  assert_true(cx ~= nil, "expected polar geometry metadata")
  return tonumber(cx), tonumber(cy), tonumber(radius), tonumber(rmax)
end

local function arrow_group(svg, index)
  local target = string.format(
    '<g class="polar-quiver-arrow" data-index="%d"', index)
  local start = svg:find(target, 1, true)
  assert_true(start ~= nil, "expected quiver arrow " .. index)
  local finish = svg:find("</g>", start, true)
  assert_true(finish ~= nil, "expected a closed quiver arrow group")
  return svg:sub(start, finish)
end

local function arrow_attributes(group)
  local attrs = {}
  for key, value in group:gmatch('data%-(%a+)="([^"]*)"') do
    attrs[key] = value
  end
  return attrs
end

local function head_tip(group)
  local points = group:match(
    'class="polar%-quiver%-head" points="([^"]+)"')
  assert_true(points ~= nil, "expected a quiver arrow head")
  local x, y = points:match("^([^,]+),([^ ]+)")
  return tonumber(x), tonumber(y)
end

local function shaft(group)
  local x1, y1, x2, y2 = group:match(
    'class="polar%-quiver%-shaft" x1="([^"]+)" y1="([^"]+)" ' ..
    'x2="([^"]+)" y2="([^"]+)"')
  if x1 == nil then return nil end
  return tonumber(x1), tonumber(y1), tonumber(x2), tonumber(y2)
end

local function close(actual, expected, tolerance, message)
  assert_true(math.abs(actual - expected) <= (tolerance or 0.02),
    string.format("%s: expected %.3f, got %.3f",
      message or "unexpected coordinate", expected, actual))
end

test("polar quiver projects radial and tangential components locally", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 6 })
  figure:polar_quiver({ 0, math.pi / 2 }, { 3, 3 }, { 1, 1 }, { 1, 1 }, {
    scale = 20,
  })
  local svg = figure:to_svg()
  assert_contains(svg, 'class="series series-polar-quiver"')
  assert_contains(svg, 'data-count="2" data-drawn="2"')
  assert_equal(count(svg, 'class="polar%-quiver%-arrow"'), 2)
  assert_equal(count(svg, 'class="polar%-quiver%-shaft"'), 2)
  assert_equal(count(svg, 'class="polar%-quiver%-head"'), 2)

  -- At theta=0 an arrow with u=1, v=1 points northeast in screen space, so
  -- the SVG angle (y grows downward) is -45 degrees.  Rotating the position by
  -- 90 degrees rotates the local arrow by another 90 degrees.
  local first = arrow_attributes(arrow_group(svg, 1))
  assert_equal(first.theta, "0")
  assert_equal(first.r, "3")
  assert_equal(first.angle, "-45")
  local second = arrow_attributes(arrow_group(svg, 2))
  assert_equal(second.angle, "-135")
  assert_well_formed_svg(svg)
end)

test("polar quiver follows theta_zero and direction", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({
    rmax = 6, theta_zero = "N", theta_direction = "clockwise",
  })
  figure:polar_quiver({ 0, 0 }, { 3, 3 }, { 1, 0 }, { 0, 1 }, { scale = 20 })
  local svg = figure:to_svg()

  -- At the north zero location a clockwise tangential (u=1) arrow points east
  -- (angle 0) while a radial (v=1) arrow points north (angle -90).
  assert_equal(arrow_attributes(arrow_group(svg, 1)).angle, "0")
  assert_equal(arrow_attributes(arrow_group(svg, 2)).angle, "-90")
  assert_contains(svg, 'data-theta-direction="clockwise"')
  assert_well_formed_svg(svg)
end)

test("polar quiver glyph length, head, and pivot use SVG units", function()
  local function render(pivot)
    local figure = plt.figure({ width = 600, height = 600 })
    figure:polar_config({ rmax = 6 })
    figure:polar_quiver({ 0 }, { 3 }, { 0 }, { 1 }, {
      scale = 20, head = 5, pivot = pivot,
    })
    local svg = figure:to_svg()
    local group = arrow_group(svg, 1)
    local cx, cy, radius, rmax = geometry(svg)
    return svg, group, cx + radius * 3 / rmax, cy
  end

  local svg, group, point_x, point_y = render("tail")
  local tip_x, tip_y = head_tip(group)
  close(tip_x, point_x + 20, 0.02, "tail-pivot tip x")
  close(tip_y, point_y, 0.02, "tail-pivot tip y")
  local x1, y1, x2 = shaft(group)
  close(x1, point_x, 0.02, "shaft starts at the data point")
  close(y1, point_y, 0.02, "shaft starts at the data point")
  close(x2, point_x + 15, 0.02, "shaft stops at the arrow neck")
  assert_contains(svg, 'data-pivot="tail"')

  local _, middle, middle_x = render("middle")
  local middle_tip = head_tip(middle)
  close(middle_tip, middle_x + 10, 0.02, "middle-pivot tip x")
  local middle_x1 = shaft(middle)
  close(middle_x1, middle_x - 10, 0.02, "middle-pivot tail x")

  local _, tip_pivot, tip_point_x = render("tip")
  local tip_pivot_x = head_tip(tip_pivot)
  close(tip_pivot_x, tip_point_x, 0.02, "tip-pivot head ends at the data point")
  local tip_tail_x = shaft(tip_pivot)
  close(tip_tail_x, tip_point_x - 20, 0.02, "tip-pivot tail x")
  assert_well_formed_svg(svg)
end)

test("polar quiver automatic scaling and normalization", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 6 })
  figure:polar_quiver({ 0, 0 }, { 2, 2 }, { 1, 0 }, { 0, 2.5 })
  local svg = figure:to_svg()
  assert_contains(svg, 'data-scale="7.2"')
  assert_contains(svg, 'data-scale-mode="auto"')

  local normalized = plt.figure({ width = 600, height = 600 })
  normalized:polar_config({ rmax = 6 })
  normalized:polar_quiver({ 0, 0 }, { 2, 2 }, { 1, 0 }, { 0, 2.5 }, {
    normalize = true,
  })
  local normalized_svg = normalized:to_svg()
  assert_contains(normalized_svg, 'data-scale="18"')
  assert_contains(normalized_svg, 'data-normalize="true"')
  assert_equal(arrow_attributes(arrow_group(normalized_svg, 1)).magnitude, "1")
  assert_equal(arrow_attributes(arrow_group(normalized_svg, 2)).magnitude, "1")
  assert_well_formed_svg(svg)
  assert_well_formed_svg(normalized_svg)
end)

test("polar quiver caps large fields deterministically", function()
  local theta, r, u, v = {}, {}, {}, {}
  for index = 1, 100 do
    theta[index] = index * 0.01
    r[index] = 2
    u[index] = 1
    v[index] = 0
  end
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 6 })
  figure:polar_quiver(theta, r, u, v, { max_arrows = 25, scale = 10 })
  local svg = figure:to_svg()

  assert_contains(svg, 'data-count="100" data-drawn="25" data-stride="4"')
  assert_contains(svg, 'data-max-arrows="25"')
  assert_equal(count(svg, 'class="polar%-quiver%-arrow"'), 25)
  assert_equal(arrow_attributes(arrow_group(svg, 1)).index, "1")
  assert_equal(arrow_attributes(arrow_group(svg, 97)).index, "97")

  -- The default cap is 512 arrows; 1000 vectors select every second one.
  local default = plt.figure({ width = 600, height = 600 })
  local long_theta, long_r, long_u, long_v = {}, {}, {}, {}
  for index = 1, 1000 do
    long_theta[index] = index * 0.001
    long_r[index] = 2
    long_u[index] = 1
    long_v[index] = 0
  end
  default:polar_config({ rmax = 6 })
  default:polar_quiver(long_theta, long_r, long_u, long_v)
  local default_svg = default:to_svg()
  assert_contains(default_svg,
    'data-count="1000" data-drawn="500" data-stride="2"')
  assert_contains(default_svg, 'data-max-arrows="512"')
  assert_equal(count(default_svg, 'class="polar%-quiver%-arrow"'), 500)
  assert_well_formed_svg(svg)
  assert_well_formed_svg(default_svg)
end)

test("polar quiver skips zero-magnitude vectors", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 6 })
  figure:polar_quiver({ 0, 1, 2 }, { 3, 3, 3 }, { 0, 1, 0 }, { 0, 0, 0 }, {
    scale = 10,
  })
  local svg = figure:to_svg()
  assert_contains(svg, 'data-count="3" data-drawn="1"')
  assert_equal(count(svg, 'class="polar%-quiver%-arrow"'), 1)
  assert_equal(arrow_attributes(arrow_group(svg, 2)).index, "2")
  assert_well_formed_svg(svg)
end)

test("polar quiver styles, legend, and render order", function()
  local values = {
    { 0.1, 0.2, 0.3 },
    { 0.4, 0.5, 0.6 },
  }
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_heatmap(values, { label = "field" })
  figure:polar_quiver({ 0, math.pi / 2 }, { 2, 2 }, { 1, 0 }, { 0, 1 }, {
    color = "#123456", linewidth = 2, head = 7, alpha = 0.5,
    label = "flow",
  })
  figure:legend({ loc = "best" })
  local svg = figure:to_svg()

  assert_contains(svg, 'stroke="#123456"')
  assert_contains(svg, 'fill="#123456"')
  assert_contains(svg, 'stroke-width="2"')
  assert_contains(svg, 'stroke-opacity="0.5"')
  assert_contains(svg, 'fill-opacity="0.5"')
  assert_contains(svg, 'data-label="flow"')
  assert_contains(svg, 'class="polar-legend"')
  assert_contains(svg, ">flow<")
  local heatmap_at = svg:find('series%-polar%-heatmap')
  local quiver_at = svg:find('series%-polar%-quiver')
  local layer_at = svg:find('<g class="series%-layer"')
  assert_true(heatmap_at ~= nil and quiver_at ~= nil and layer_at ~= nil)
  assert_true(heatmap_at < quiver_at,
    "quiver arrows should render above heatmap cells")
  assert_true(layer_at < quiver_at,
    "quiver arrows should be clipped by the series layer")
  assert_well_formed_svg(svg)
end)

test("polar quiver scene export copies vectors and scaling metadata",
    function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 6 })
  local theta = { 0, math.pi / 2 }
  local r = { 2, 3 }
  local u = { 1, 0 }
  local v = { 0, 2 }
  figure:polar_quiver(theta, r, u, v, {
    pivot = "middle", max_arrows = 10, normalize = true, label = "flow",
  })
  figure:legend({ loc = "best" })
  u[1] = 999
  v[2] = -999

  local scene = figure:to_scene()
  local quiver = scene.polar.series[1]
  assert_equal(quiver.kind, "quiver")
  assert_equal(quiver.components, "tangential_radial")
  assert_equal(quiver.u[1], 1)
  assert_equal(quiver.v[2], 2)
  assert_equal(quiver.normalize, true)
  assert_equal(quiver.pivot, "middle")
  assert_equal(quiver.max_arrows, 10)
  assert_equal(quiver.auto_scale, true)
  assert_equal(quiver.resolved_scale, 18)
  assert_equal(quiver.scale_unit, "svg_user_units_per_magnitude")
  assert_equal(quiver.stride, 1)
  assert_equal(quiver.drawn, 2)
  assert_equal(quiver.style.head, 5)
  assert_equal(quiver.style.label, "flow")
  assert_equal(scene.polar.legend.entries[1].kind, "quiver")

  local explicit = plt.figure({ width = 600, height = 600 })
  explicit:polar_config({ rmax = 6 })
  explicit:polar_quiver({ 0 }, { 2 }, { 1 }, { 0 }, { scale = 4 })
  local explicit_quiver = explicit:to_scene().polar.series[1]
  assert_equal(explicit_quiver.scale, 4)
  assert_equal(explicit_quiver.auto_scale, false)
  assert_equal(explicit_quiver.resolved_scale, 4)
end)

test("polar quiver extends the automatic radial limit", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_quiver({ 0 }, { 8 }, { 1 }, { 0 })
  local svg = figure:to_svg()
  assert_true(number_attr(svg, "rmax") >= 8,
    "automatic rmax should cover quiver positions")
  assert_well_formed_svg(svg)

  local explicit = plt.figure({ width = 600, height = 600 })
  explicit:polar_config({ rmax = 2 })
  explicit:polar_quiver({ 0 }, { 3 }, { 1 }, { 0 })
  assert_error("exceeds the configured rmax", function()
    explicit:to_svg()
  end)
end)

test("polar quiver accepts degrees and rejects malformed input", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 6 })
  figure:polar_quiver({ 90 }, { 3 }, { 0 }, { 1 }, {
    degrees = true, scale = 10,
  })
  local svg = figure:to_svg()
  assert_equal(arrow_attributes(arrow_group(svg, 1)).theta, "1.571")

  local function quiver(opts)
    return plt.figure({ width = 500, height = 500 }):polar_quiver(
      { 0 }, { 2 }, { 1 }, { 0 }, opts)
  end
  assert_error("same length", function()
    plt.figure():polar_quiver({ 0, 1 }, { 2 }, { 1 }, { 0 })
  end)
  assert_error("same length", function()
    plt.figure():polar_quiver({ 0 }, { 2, 3 }, { 1 }, { 0 })
  end)
  assert_error("same length", function()
    plt.figure():polar_quiver({ 0 }, { 2 }, { 1, 2 }, { 0 })
  end)
  assert_error("same length", function()
    plt.figure():polar_quiver({ 0 }, { 2 }, { 1 }, { 0, 2 })
  end)
  assert_error("must not be empty", function()
    plt.figure():polar_quiver({}, {}, {}, {})
  end)
  assert_error("must be finite", function()
    plt.figure():polar_quiver({ 0 }, { 2 }, { 0 / 0 }, { 0 })
  end)
  assert_error("scale must be positive", function() quiver({ scale = 0 }) end)
  assert_error("scale must be positive", function()
    quiver({ scale = -1 })
  end)
  assert_error("max_arrows must be an integer", function()
    quiver({ max_arrows = 2.5 })
  end)
  assert_error("max_arrows must be >= 1", function()
    quiver({ max_arrows = 0 })
  end)
  assert_error("max_arrows must be <= 4096", function()
    quiver({ max_arrows = 5000 })
  end)
  assert_error("pivot must be 'tail', 'middle', or 'tip'", function()
    quiver({ pivot = "center" })
  end)
  assert_error("head must be >= 0", function() quiver({ head = -1 }) end)
  assert_error("normalize must be a boolean", function()
    quiver({ normalize = 1 })
  end)
  assert_error("unsupported polar quiver option", function()
    quiver({ bogus = true })
  end)
  assert_error("cannot both be set", function()
    quiver({ degrees = true, theta_unit = "radians" })
  end)
end)

test("polar quiver leaves Cartesian figures untouched and refuses mixing",
    function()
  local cartesian = plt.figure({ width = 500, height = 400 })
  cartesian:plot({ 1, 2, 3 }, { 3, 1, 2 })
  local svg = cartesian:to_svg()
  assert_not_contains(svg, "polar-quiver")
  assert_not_contains(svg, 'data-polar="true"')
  assert_contains(svg, 'class="background"')
  assert_well_formed_svg(svg)

  assert_error("cannot mix cartesian and polar", function()
    local figure = plt.figure()
    figure:plot({ 1, 2 }, { 1, 2 })
    figure:polar_quiver({ 0 }, { 1 }, { 1 }, { 0 })
  end)
  assert_error("cannot mix cartesian and polar", function()
    local figure = plt.figure()
    figure:polar_quiver({ 0 }, { 1 }, { 1 }, { 0 })
    figure:plot({ 1, 2 }, { 1, 2 })
    figure:to_svg()
  end)
end)
