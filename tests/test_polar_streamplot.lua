-- Polar streamplot tests: grid validation, physical-plane integration,
-- deterministic seeding and caps, clipping, scene export, legend integration,
-- configuration, and Cartesian isolation.  These are text-level SVG checks;
-- no image library is needed.

local plt = require("luaplotlib")

local function count(svg, pattern)
  return select(2, svg:gsub(pattern, ""))
end

local function number_attr(svg, name)
  return tonumber(svg:match('data%-' .. name .. '="([%d%.%-]+)"'))
end

local function series_attr(svg, name)
  return svg:match('class="series series%-polar%-streamplot".-data%-' ..
    name .. '="([^"]+)"')
end

local function geometry(svg)
  local cx, cy, radius, rmax = svg:match(
    'class="polar" data%-cx="([^"]+)" data%-cy="([^"]+)" ' ..
    'data%-radius="([^"]+)" data%-rmax="([^"]+)"')
  assert_true(cx ~= nil, "expected polar geometry metadata")
  return tonumber(cx), tonumber(cy), tonumber(radius), tonumber(rmax)
end

-- Grid helpers.  A full-turn theta grid includes both 0 and 2*pi, which the
-- renderer treats as periodic; the duplicate endpoint ray makes interpolation
-- across the seam continuous.
local function full_turn(count)
  local values = {}
  for index = 1, count do
    values[index] = (index - 1) * 2 * math.pi / (count - 1)
  end
  return values
end

local function linear_grid(count, minimum, maximum)
  local values = {}
  for index = 1, count do
    values[index] = minimum +
      (maximum - minimum) * (index - 1) / (count - 1)
  end
  return values
end

local function field(theta, r, function_u, function_v)
  local u, v = {}, {}
  for row = 1, #r do
    u[row], v[row] = {}, {}
    for column = 1, #theta do
      u[row][column] = function_u(theta[column], r[row])
      v[row][column] = function_v(theta[column], r[row])
    end
  end
  return u, v
end

local function azimuthal(theta, r)
  return field(theta, r, function() return 1 end,
    function() return 0 end)
end

local function radial(theta, r)
  return field(theta, r, function() return 0 end,
    function() return 1 end)
end

local function spiral(theta, r)
  return field(theta, r, function() return 1 end,
    function() return 1 end)
end

local function scene_series(figure)
  return figure:to_scene().polar.series[1]
end

local function line_groups(svg)
  local groups = {}
  for index, points, arrows in svg:gmatch(
      'class="polar%-streamline" data%-index="(%d+)" ' ..
      'data%-points="(%d+)" data%-arrows="(%d+)"') do
    groups[#groups + 1] = {
      index = tonumber(index),
      points = tonumber(points),
      arrows = tonumber(arrows),
    }
  end
  return groups
end

test("polar streamplot draws closed azimuthal streamlines", function()
  local theta = full_turn(25)
  local r = linear_grid(5, 1, 5)
  local u, v = azimuthal(theta, r)
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 5 })
  figure:polar_streamplot(theta, r, u, v)
  local svg = figure:to_svg()

  assert_contains(svg, 'class="series series-polar-streamplot"')
  assert_contains(svg, 'data-cols="25" data-rows="5"')
  assert_contains(svg, 'data-periodic="true"')
  assert_contains(svg, 'data-step-mode="auto"')
  assert_contains(svg, 'data-arrows="true"')
  local lines = number_attr(svg, "lines")
  local points = number_attr(svg, "points")
  local arrows = number_attr(svg, "arrow%-count")
  assert_true(lines ~= nil and lines >= 3 and lines <= 5,
    "expected one streamline per radial seed row")

  local groups = line_groups(svg)
  assert_equal(#groups, lines)
  assert_equal(count(svg, 'class="polar%-streamline%-path"'), lines)
  assert_equal(count(svg, 'class="polar%-stream%-arrow"'), arrows)
  assert_equal(arrows, lines)
  local total = 0
  for index, group in ipairs(groups) do
    assert_equal(group.index, index)
    assert_true(group.points >= 3, "streamline should have at least 3 points")
    assert_equal(group.arrows, 1)
    total = total + group.points
  end
  assert_equal(total, points)

  local series = scene_series(figure)
  assert_equal(series.kind, "streamplot")
  assert_equal(series.components, "tangential_radial")
  assert_equal(series.periodic, true)
  assert_equal(#series.lines, lines)
  assert_equal(series.line_count, lines)
  assert_equal(series.point_count, points)
  for _, line in ipairs(series.lines) do
    assert_equal(#line.theta, line.points)
    assert_equal(#line.r, line.points)
    local minimum, maximum = math.huge, -math.huge
    for index = 1, line.points do
      assert_true(math.abs(line.theta[index]) < 1e6,
        "streamline theta must be finite")
      if line.r[index] < minimum then minimum = line.r[index] end
      if line.r[index] > maximum then maximum = line.r[index] end
    end
    assert_true(maximum - minimum < 1e-6,
      "azimuthal streamlines should keep a constant radius")
    assert_equal(#line.arrows, 1)
    assert_true(line.arrows[1].angle ~= nil)
  end
  assert_well_formed_svg(svg)
end)

test("polar streamplot integrates radial fields as outward rays", function()
  local theta = full_turn(13)
  local r = linear_grid(4, 1, 4)
  local u, v = radial(theta, r)
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 4 })
  figure:polar_streamplot(theta, r, u, v, { density = 0.6 })
  local svg = figure:to_svg()

  local series = scene_series(figure)
  assert_true(#series.lines >= 1)
  for _, line in ipairs(series.lines) do
    local first_theta = line.theta[1]
    for index = 2, line.points do
      local difference = math.abs(line.theta[index] - first_theta)
      difference = difference % (2 * math.pi)
      if difference > math.pi then difference = 2 * math.pi - difference end
      assert_true(difference < 1e-6,
        "a purely radial field must not bend a streamline")
      assert_true(line.r[index] >= line.r[index - 1] - 1e-9,
        "combined radial streamlines should run from inner to outer radius")
    end
    -- The arrow points outward: at theta its SVG angle is -theta degrees.
    local expected = -math.deg(first_theta)
    local actual = line.arrows[1].angle
    local difference = (actual - expected) % 360
    if difference > 180 then difference = 360 - difference end
    assert_true(difference < 1e-6,
      string.format("radial arrow angle: expected %.3f, got %.3f",
        expected, actual))
  end
  assert_well_formed_svg(svg)
end)

test("polar streamplot follows a spiral in both directions", function()
  local theta = full_turn(17)
  local r = linear_grid(4, 1, 3)
  local u, v = spiral(theta, r)
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 3 })
  figure:polar_streamplot(theta, r, u, v, { density = 0.6 })
  local series = scene_series(figure)
  local line = series.lines[1]
  assert_true(line ~= nil, "expected at least one spiral streamline")

  local theta_min, theta_max = math.huge, -math.huge
  local radius_min, radius_max = math.huge, -math.huge
  for index = 1, line.points do
    local value = line.theta[index]
    if value < theta_min then theta_min = value end
    if value > theta_max then theta_max = value end
    if line.r[index] < radius_min then radius_min = line.r[index] end
    if line.r[index] > radius_max then radius_max = line.r[index] end
  end
  assert_true(theta_max - theta_min > 0.5,
    "spiral streamlines should sweep in theta")
  assert_true(radius_max - radius_min > 0.5,
    "spiral streamlines should move radially")
  assert_well_formed_svg(figure:to_svg())
end)

test("polar streamplot caps lines, steps, and points", function()
  local theta = full_turn(25)
  local r = linear_grid(5, 1, 5)
  local u, v = spiral(theta, r)

  local lines_figure = plt.figure({ width = 500, height = 500 })
  lines_figure:polar_config({ rmax = 5 })
  lines_figure:polar_streamplot(theta, r, u, v, {
    density = 3, max_lines = 2, max_steps = 20,
  })
  local lines_svg = lines_figure:to_svg()
  local lines = number_attr(lines_svg, "lines")
  assert_true(lines <= 2, "max_lines must cap the number of streamlines")
  assert_equal(count(lines_svg, 'class="polar%-streamline%-path"'), lines)
  assert_contains(lines_svg, 'data-truncated="true"')
  for _, group in ipairs(line_groups(lines_svg)) do
    assert_true(group.points <= 2 * 20 + 1,
      "max_steps must bound points in both directions")
  end

  local points_figure = plt.figure({ width = 500, height = 500 })
  points_figure:polar_config({ rmax = 5 })
  points_figure:polar_streamplot(theta, r, u, v, {
    density = 3, max_points = 120, max_steps = 100,
  })
  local points_svg = points_figure:to_svg()
  assert_true(number_attr(points_svg, "points") <= 120,
    "max_points must cap total path points")
  assert_contains(points_svg, 'data-max-points="120"')
  assert_well_formed_svg(lines_svg)
  assert_well_formed_svg(points_svg)
end)

test("polar streamplot step controls resolution", function()
  local theta = full_turn(17)
  local r = linear_grid(4, 1, 3)
  local u, v = spiral(theta, r)

  local function rendered(step)
    local figure = plt.figure({ width = 500, height = 500 })
    figure:polar_config({ rmax = 3 })
    figure:polar_streamplot(theta, r, u, v, {
      density = 0.6, step = step, max_steps = 40, max_points = 4000,
    })
    return figure:to_svg()
  end

  local coarse = rendered(0.5)
  local fine = rendered(0.1)
  assert_contains(coarse, 'data-step="0.5"')
  assert_contains(fine, 'data-step="0.1"')
  assert_contains(coarse, 'data-step-mode="explicit"')
  assert_true(number_attr(coarse, "points") < number_attr(fine, "points"),
    "a coarser integration step should use fewer points")
  assert_well_formed_svg(coarse)
  assert_well_formed_svg(fine)

  local exact = plt.figure({ width = 500, height = 500 })
  exact:polar_config({ rmax = 3 })
  exact:polar_streamplot(theta, r, u, v, { step = 0.2 })
  local scene = scene_series(exact)
  assert_equal(scene.step, 0.2)
  assert_equal(scene.resolved_step, 0.2)
  assert_equal(scene.step_mode, "explicit")
  assert_equal(scene.step_unit, "data_radius_units")
end)

test("polar streamplot honours theta_zero and direction", function()
  local theta = full_turn(17)
  local r = linear_grid(4, 1, 4)
  local u, v = azimuthal(theta, r)
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({
    rmax = 4, theta_zero = "N", theta_direction = "clockwise",
  })
  figure:polar_streamplot(theta, r, u, v, { density = 0.6 })
  local svg = figure:to_svg()
  assert_contains(svg, 'data-theta-direction="clockwise"')
  assert_contains(svg, 'data-theta-zero="1.571"')

  local series = scene_series(figure)
  for _, line in ipairs(series.lines) do
    local minimum, maximum = math.huge, -math.huge
    for index = 1, line.points do
      if line.r[index] < minimum then minimum = line.r[index] end
      if line.r[index] > maximum then maximum = line.r[index] end
    end
    assert_true(minimum > 0 and maximum <= 4 + 1e-6,
      "clockwise streamlines should stay inside the frame")
  end
  assert_well_formed_svg(svg)
end)

test("polar streamplot accepts degrees and non-periodic sectors", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 3 })
  figure:polar_streamplot(
    { 0, 45, 90 }, { 1, 2, 3 },
    { { 1, 1, 1 }, { 1, 1, 1 }, { 1, 1, 1 } },
    { { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 } },
    { degrees = true, density = 0.6 })
  local svg = figure:to_svg()
  assert_contains(svg, 'data-periodic="false"')
  local series = scene_series(figure)
  assert_true(math.abs(series.theta[2] - math.pi / 4) < 1e-12)
  assert_true(math.abs(series.theta[3] - math.pi / 2) < 1e-12)
  for _, line in ipairs(series.lines) do
    for index = 1, line.points do
      assert_true(line.theta[index] >= -1e-9 and
        line.theta[index] <= math.pi / 2 + 1e-9,
        "a sector streamplot must not leave its theta bounds")
    end
  end
  assert_well_formed_svg(svg)
end)

test("polar streamplot exports grid, lines, and copied matrices", function()
  local theta = full_turn(9)
  local r = linear_grid(3, 1, 3)
  local u, v = spiral(theta, r)
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 3 })
  figure:polar_streamplot(theta, r, u, v, {
    density = 0.6, max_steps = 30, label = "flow",
  })
  figure:legend({ loc = "best" })
  local scene = figure:to_scene()
  local series = scene.polar.series[1]

  assert_equal(series.kind, "streamplot")
  assert_equal(#series.theta, 9)
  assert_equal(#series.r, 3)
  assert_equal(series.u[1][1], 1)
  assert_equal(series.v[3][2], 1)
  assert_equal(series.components, "tangential_radial")
  assert_equal(series.periodic, true)
  assert_equal(series.step, nil)
  assert_equal(series.step_mode, "auto")
  assert_equal(series.resolved_step, (3 - 1) / 25)
  assert_equal(series.density, 0.6)
  assert_equal(series.max_steps, 30)
  assert_equal(series.arrows, true)
  assert_equal(series.head, 6)
  assert_equal(series.style.label, "flow")
  assert_true(series.truncated ~= nil)
  assert_equal(scene.polar.legend.entries[1].kind, "streamplot")

  local total = 0
  for _, line in ipairs(series.lines) do
    total = total + line.points
    assert_equal(#line.theta, line.points)
    assert_equal(#line.r, line.points)
    assert_true(#line.arrows >= 0)
  end
  assert_equal(total, series.point_count)

  -- Scene data is a deep copy: mutating it must not reach the figure.
  series.u[1][1] = 99
  series.lines[1].theta[1] = 99
  assert_true(figure._polar.series[1].u[1][1] ~= 99,
    "scene export must copy component matrices")
  assert_true(figure._polar.series[1].theta[1] ~= 99,
    "scene export must copy the theta grid")
end)

test("polar streamplot legend swatch and styles", function()
  local theta = full_turn(9)
  local r = linear_grid(3, 1, 2)
  local u, v = azimuthal(theta, r)
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 2 })
  figure:polar_streamplot(theta, r, u, v, {
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
  assert_contains(svg, 'data-head="7"')
  assert_contains(svg, 'class="legend-swatch-streamplot"')
  assert_contains(svg, 'class="polar-legend"')
  assert_contains(svg, ">flow<")
  assert_well_formed_svg(svg)
end)

test("polar streamplot can omit arrows and paths", function()
  local theta = full_turn(9)
  local r = linear_grid(3, 1, 2)
  local u, v = azimuthal(theta, r)

  local no_arrows = plt.figure({ width = 500, height = 500 })
  no_arrows:polar_config({ rmax = 2 })
  no_arrows:polar_streamplot(theta, r, u, v, { arrows = false })
  local no_arrows_svg = no_arrows:to_svg()
  assert_contains(no_arrows_svg, 'data-arrows="false"')
  assert_contains(no_arrows_svg, 'data-arrow-count="0"')
  assert_equal(count(no_arrows_svg, 'class="polar%-stream%-arrow"'), 0)
  assert_true(count(no_arrows_svg, 'class="polar%-streamline%-path"') > 0)

  local no_line = plt.figure({ width = 500, height = 500 })
  no_line:polar_config({ rmax = 2 })
  no_line:polar_streamplot(theta, r, u, v, { linewidth = 0 })
  local no_line_svg = no_line:to_svg()
  assert_equal(count(no_line_svg, 'class="polar%-streamline%-path"'), 0)
  assert_true(count(no_line_svg, 'class="polar%-stream%-arrow"') > 0)
  assert_well_formed_svg(no_arrows_svg)
  assert_well_formed_svg(no_line_svg)
end)

test("polar streamplot is deterministic", function()
  local theta = full_turn(13)
  local r = linear_grid(4, 1, 3)
  local u, v = spiral(theta, r)
  local figure = plt.figure({ width = 500, height = 500 })
  figure:polar_config({ rmax = 3 })
  figure:polar_streamplot(theta, r, u, v, { density = 0.8 })
  local first = figure:to_svg()
  local second = figure:to_svg()
  assert_equal(first, second)

  local series = scene_series(figure)
  local other = plt.figure({ width = 500, height = 500 })
  other:polar_config({ rmax = 3 })
  other:polar_streamplot(theta, r, u, v, { density = 0.8 })
  local repeated = scene_series(other)
  assert_equal(repeated.line_count, series.line_count)
  assert_equal(repeated.point_count, series.point_count)
  assert_well_formed_svg(first)
end)

test("polar streamplot extends the automatic radial limit", function()
  local theta = full_turn(9)
  local r = linear_grid(3, 1, 8)
  local u, v = azimuthal(theta, r)
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_streamplot(theta, r, u, v, { density = 0.5 })
  local svg = figure:to_svg()
  local _, _, _, rmax = geometry(svg)
  assert_true(rmax >= 8, "automatic rmax should cover the field grid")
  assert_well_formed_svg(svg)

  local explicit = plt.figure({ width = 600, height = 600 })
  explicit:polar_config({ rmax = 2 })
  explicit:polar_streamplot(theta, r, u, v)
  assert_error("exceeds the configured rmax", function()
    explicit:to_svg()
  end)
end)

test("polar streamplot rejects malformed grids and options", function()
  local theta = full_turn(9)
  local r = linear_grid(3, 1, 2)
  local u, v = azimuthal(theta, r)

  local function streamplot(t, radii, tu, tv, opts)
    return plt.figure():polar_streamplot(t, radii, tu, tv, opts)
  end

  assert_error("at least two grid values", function()
    streamplot({ 0 }, r, u, v)
  end)
  assert_error("at least two grid values", function()
    streamplot(theta, { 1 }, u, v)
  end)
  assert_error("strictly increasing", function()
    streamplot({ 0, 0, 1 }, r, u, v)
  end)
  assert_error("strictly increasing", function()
    streamplot(theta, { 1, 2, 2 }, u, v)
  end)
  assert_error("non%-negative", function()
    streamplot(theta, { -1, 1, 2 }, u, v)
  end)
  assert_error("at most 2%*pi", function()
    streamplot({ 0, 1, 7 }, r, u, v)
  end)
  assert_error("must be %d%-by%-%d matrices", function()
    streamplot({ 0, 1, 2 }, { 1, 2 }, { { 1, 1, 1 } },
      { { 1, 1, 1 } })
  end)
  assert_error("must be %d%-by%-%d matrices", function()
    streamplot({ 0, 1 }, { 1, 2, 3 }, u, v)
  end)
  assert_error("equal length", function()
    streamplot({ 0, 1 }, { 1, 2 }, { { 1, 2 }, { 1 } }, v)
  end)
  assert_error("row 1 must be a table", function()
    streamplot({ 0, 1 }, { 1, 2 }, { 1, 2 }, v)
  end)
  assert_error("density must be >= 0.1", function()
    streamplot(theta, r, u, v, { density = 0 })
  end)
  assert_error("density must be <= 10", function()
    streamplot(theta, r, u, v, { density = 11 })
  end)
  assert_error("step must be positive", function()
    streamplot(theta, r, u, v, { step = 0 })
  end)
  assert_error("max_steps must be >= 10", function()
    streamplot(theta, r, u, v, { max_steps = 5 })
  end)
  assert_error("max_lines must be >= 1", function()
    streamplot(theta, r, u, v, { max_lines = 0 })
  end)
  assert_error("max_lines must be <= 512", function()
    streamplot(theta, r, u, v, { max_lines = 1000 })
  end)
  assert_error("max_points must be >= 100", function()
    streamplot(theta, r, u, v, { max_points = 50 })
  end)
  assert_error("arrows must be a boolean", function()
    streamplot(theta, r, u, v, { arrows = 1 })
  end)
  assert_error("head must be >= 0", function()
    streamplot(theta, r, u, v, { head = -1 })
  end)
  assert_error("unsupported polar streamplot option", function()
    streamplot(theta, r, u, v, { bogus = true })
  end)
  assert_error("cannot both be set", function()
    streamplot(theta, r, u, v, { degrees = true, theta_unit = "radians" })
  end)
  assert_error("cannot mix cartesian and polar", function()
    local figure = plt.figure()
    figure:plot({ 1, 2 }, { 1, 2 })
    figure:polar_streamplot(theta, r, u, v)
  end)
  assert_error("cannot mix cartesian and polar", function()
    local figure = plt.figure()
    figure:polar_streamplot(theta, r, u, v)
    figure:plot({ 1, 2 }, { 1, 2 })
    figure:to_svg()
  end)
end)

test("polar streamplot leaves Cartesian figures untouched", function()
  local cartesian = plt.figure({ width = 500, height = 400 })
  cartesian:plot({ 1, 2, 3 }, { 3, 1, 2 })
  local svg = cartesian:to_svg()
  assert_not_contains(svg, "streamplot")
  assert_not_contains(svg, "polar-streamline")
  assert_not_contains(svg, 'data-polar="true"')
  assert_contains(svg, 'class="background"')
  assert_well_formed_svg(svg)
end)
