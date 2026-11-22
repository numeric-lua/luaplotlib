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

local function attributes(tag)
  local record = {}
  for key, value in tag:gmatch('([%w%-]+)="([^"]*)"') do
    record[key] = value
  end
  return record
end

local function series_record(svg)
  local tag = svg:match(
    '<g class="series series%-polar%-streamplot" ([^>]*)>')
  assert_true(tag ~= nil, "expected a streamplot series group")
  return attributes(tag)
end

local function line_records(svg)
  local records = {}
  for tag in svg:gmatch('<g class="polar%-streamline" ([^>]*)>') do
    records[#records + 1] = attributes(tag)
  end
  return records
end

local function arrow_records(svg)
  local records = {}
  for tag in svg:gmatch(
      '<polygon class="polar%-stream%-arrow" ([^>]*)/>') do
    records[#records + 1] = attributes(tag)
  end
  return records
end

local function polygon_vertices(record)
  local vertices = {}
  for x, y in record.points:gmatch('([%d%.%-]+),([%d%.%-]+)') do
    vertices[#vertices + 1] = { tonumber(x), tonumber(y) }
  end
  return vertices
end

-- Largest distance from the polar centre for every streamline path vertex and
-- every arrow polygon vertex, plus the frame radius itself.
local function frame_extents(svg)
  local cx, cy, radius = geometry(svg)
  local path_max, arrow_max = 0, 0
  for d in svg:gmatch(
      'class="polar%-streamline%-path" d="([^"]+)"') do
    for x, y in d:gmatch('([%d%.%-]+) ([%d%.%-]+)') do
      local dx, dy = tonumber(x) - cx, tonumber(y) - cy
      local distance = math.sqrt(dx * dx + dy * dy)
      if distance > path_max then path_max = distance end
    end
  end
  for _, record in ipairs(arrow_records(svg)) do
    for _, vertex in ipairs(polygon_vertices(record)) do
      local dx, dy = vertex[1] - cx, vertex[2] - cy
      local distance = math.sqrt(dx * dx + dy * dy)
      if distance > arrow_max then arrow_max = distance end
    end
  end
  return path_max, arrow_max, radius
end

local function assert_close(actual, expected, tolerance, label)
  assert_true(actual ~= nil, (label or "value") .. " is missing")
  assert_true(math.abs(actual - expected) <= tolerance,
    string.format("%s: expected %.6f, got %.6f", label or "value",
      expected, actual))
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

test("polar streamplot reports closed orbits and arc-length anchors", function()
  local theta = full_turn(25)
  local r = linear_grid(5, 1, 5)
  local u, v = azimuthal(theta, r)
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 5 })
  figure:polar_streamplot(theta, r, u, v)

  local svg = figure:to_svg()
  local lines = number_attr(svg, "lines")
  -- Five radial seed rows; the overlap filter must not redraw the same ring
  -- from every angular seed column.
  assert_equal(lines, 5, "closed orbits should be seeded once per radial row")
  assert_equal(number_attr(svg, "closed%-lines"), lines)
  assert_equal(count(svg, 'data%-closed="true"'), lines)
  assert_contains(svg, 'data-arrow-fraction="0.5"')
  assert_contains(svg, 'data-arc-length-unit="data_radius_units"')
  local groups = line_groups(svg)
  assert_equal(#groups, lines)
  for _, group in ipairs(groups) do
    assert_true(group.points >= 3)
    assert_equal(group.arrows, 1)
  end

  local series = scene_series(figure)
  assert_equal(series.closed_line_count, lines)
  assert_equal(series.arrow_fraction, 0.5)
  assert_equal(series.lines[1].seed_theta, series.lines[1].theta[1])
  assert_equal(series.lines[1].seed_r, series.lines[1].r[1])
  local total_points = 0
  for _, line in ipairs(series.lines) do
    assert_equal(line.closed, true)
    assert_true(line.arc_length > 0)
    -- Each ring starts at its seed radius, so its polyline length is the
    -- circumference up to chord discretization error.
    local circumference = 2 * math.pi * line.r[1]
    assert_true(math.abs(line.arc_length - circumference) <
      circumference * 0.01,
      "arc length should track the seeded ring circumference")
    assert_equal(#line.arrows, 1)
    local arrow = line.arrows[1]
    assert_true(arrow.index >= 1 and arrow.index < line.points)
    assert_true(math.abs(arrow.fraction - 0.5) < 0.02,
      "an arrow at fraction 0.5 should land near half the arc length")
    assert_equal(arrow.theta, line.theta[arrow.index])
    assert_equal(arrow.r, line.r[arrow.index])
    total_points = total_points + line.points
  end
  assert_equal(total_points, series.point_count)
  assert_well_formed_svg(svg)
end)

test("polar streamplot arrow_fraction moves arrows along the line", function()
  local theta = full_turn(17)
  local r = linear_grid(4, 1, 4)
  local u, v = radial(theta, r)

  local function render(fraction, with_legend)
    local figure = plt.figure({ width = 500, height = 500 })
    figure:polar_config({ rmax = 4 })
    figure:polar_streamplot(theta, r, u, v, {
      density = 0.5, step = 0.05, max_steps = 100,
      arrow_fraction = fraction, label = "radial flow",
    })
    if with_legend then figure:legend({ loc = "best" }) end
    return figure, figure:to_svg()
  end

  local early_figure, early_svg = render(0.2, false)
  local late_figure, late_svg = render(0.8, false)
  assert_contains(early_svg, 'data-arrow-fraction="0.2"')
  assert_contains(late_svg, 'data-arrow-fraction="0.8"')

  local early = scene_series(early_figure).lines[1].arrows[1]
  local late = scene_series(late_figure).lines[1].arrows[1]
  assert_true(math.abs(early.fraction - 0.2) < 0.02)
  assert_true(math.abs(late.fraction - 0.8) < 0.02)
  assert_true(late.fraction > early.fraction + 0.5,
    "the late arrow should sit farther along the same line")
  assert_true(math.abs(late.index - early.index) > 1,
    "moving the fraction should move the anchor point index")

  local legend_figure, legend_svg = render(0.5, true)
  assert_contains(legend_svg, 'class="legend-swatch-streamplot"')
  assert_true(scene_series(legend_figure).arrow_fraction == 0.5)
  assert_well_formed_svg(early_svg)
  assert_well_formed_svg(late_svg)
  assert_well_formed_svg(legend_svg)
end)

test("polar streamplot clips glyphs to the polar circle", function()
  local theta = full_turn(37)
  local r = linear_grid(5, 1, 5)
  local u, v = radial(theta, r)

  local function render(head, fraction)
    local figure = plt.figure({ width = 640, height = 640 })
    figure:polar_config({ rmax = 5 })
    figure:polar_streamplot(theta, r, u, v, {
      density = 1, step = 0.05, max_steps = 200,
      arrow_fraction = fraction, head = head,
    })
    return figure, figure:to_svg()
  end

  -- Normal arrows fit inside the frame; the clip metadata is explicit but
  -- nothing needs to be shortened.
  local plain_figure, plain = render(6, 0.5)
  local path_max, arrow_max, radius = frame_extents(plain)
  assert_true(path_max <= radius + 1e-6,
    "streamline paths must stay inside the polar frame")
  assert_true(arrow_max <= radius + 1e-6,
    "default arrow glyphs must stay inside the polar frame")
  local plain_series = series_record(plain)
  assert_equal(plain_series["data-clip"], "polar-circle")
  assert_equal(tonumber(plain_series["data-clipped-arrow-count"]), 0)
  assert_equal(count(plain, 'data%-clipped="true"'), 0)
  local plain_scene = scene_series(plain_figure)
  assert_equal(plain_scene.clip, "polar_circle")
  assert_equal(plain_scene.clipped_arrow_count, 0)

  -- A large head with a late anchor pushes the triangle past the circle.  The
  -- rendered vertices are projected onto the frame and reported in both the
  -- SVG and the scene export.
  local clipped_figure, clipped = render(26, 0.95)
  path_max, arrow_max, radius = frame_extents(clipped)
  assert_true(path_max <= radius + 1e-6,
    "clipped streamplot paths must stay inside the frame")
  assert_true(arrow_max <= radius + 1e-6,
    "clipped glyph vertices must stay inside the frame")
  local scene = scene_series(clipped_figure)
  assert_true(scene.clipped_arrow_count > 0,
    "a large boundary glyph should be clipped")
  local records = arrow_records(clipped)
  assert_equal(#records, scene.arrow_count)
  local clipped_records = 0
  for _, record in ipairs(records) do
    if record["data-clipped"] == "true" then
      clipped_records = clipped_records + 1
    end
    local vertices = polygon_vertices(record)
    assert_equal(#vertices, 3)
    local cx, cy, frame_radius = geometry(clipped)
    for _, vertex in ipairs(vertices) do
      local dx, dy = vertex[1] - cx, vertex[2] - cy
      assert_true(math.sqrt(dx * dx + dy * dy) <= frame_radius + 1e-6,
        "every arrow vertex must stay inside the polar frame")
    end
  end
  assert_equal(clipped_records, scene.clipped_arrow_count)
  assert_equal(tonumber(series_record(clipped)["data-clipped-arrow-count"]),
    scene.clipped_arrow_count)
  assert_equal(count(clipped, 'data%-clipped="true"'), clipped_records)
  assert_well_formed_svg(plain)
  assert_well_formed_svg(clipped)
end)

test("polar streamplot supports dashed, dotted, and hidden paths", function()
  local theta = full_turn(17)
  local r = linear_grid(4, 1, 3)
  local u, v = spiral(theta, r)

  local function render(linestyle)
    local figure = plt.figure({ width = 500, height = 500 })
    figure:polar_config({ rmax = 3 })
    figure:polar_streamplot(theta, r, u, v, {
      density = 0.6, linestyle = linestyle, label = "flow",
    })
    figure:legend({ loc = "best" })
    return figure, figure:to_svg()
  end

  local dashed_figure, dashed = render("dashed")
  assert_contains(dashed, 'data-linestyle="dashed"')
  assert_contains(dashed, 'stroke-dasharray="6 4"')
  assert_match(dashed,
    'class="legend%-swatch%-streamplot".-stroke%-dasharray="6 4"')
  assert_equal(scene_series(dashed_figure).style.linestyle, "dashed")

  local dotted_figure, dotted = render("dotted")
  assert_contains(dotted, 'data-linestyle="dotted"')
  assert_contains(dotted, 'stroke-dasharray="1.5 3"')
  assert_match(dotted,
    'class="legend%-swatch%-streamplot".-stroke%-dasharray="1%.5 3"')
  assert_equal(scene_series(dotted_figure).style.linestyle, "dotted")

  local hidden_figure, hidden = render("none")
  assert_contains(hidden, 'data-linestyle="none"')
  assert_equal(count(hidden, 'class="polar%-streamline%-path"'), 0)
  assert_true(number_attr(hidden, "arrow%-count") > 0,
    "hidden paths should keep their directional arrows")
  assert_not_contains(hidden, 'class="legend-swatch-streamplot"')
  assert_equal(scene_series(hidden_figure).style.linestyle, "none")

  assert_well_formed_svg(dashed)
  assert_well_formed_svg(dotted)
  assert_well_formed_svg(hidden)
end)

test("polar streamplot honours theta_zero and direction", function()  local theta = full_turn(17)
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
  assert_equal(series.cols, 9)
  assert_equal(series.rows, 3)
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
  assert_equal(series.arrow_fraction, 0.5)
  assert_equal(series.head, 6)
  assert_equal(series.style.linestyle, "solid")
  assert_equal(series.style.label, "flow")
  assert_equal(series.arc_length_unit, "data_radius_units")
  assert_equal(series.clip, "polar_circle")
  assert_true(series.closed_line_count >= 0)
  assert_true(series.truncated ~= nil)
  assert_equal(scene.polar.legend.entries[1].kind, "streamplot")
  assert_equal(scene.polar.legend.entries[1].linestyle, "solid")

  local total, arrow_total, clipped_total = 0, 0, 0
  for _, line in ipairs(series.lines) do
    total = total + line.points
    arrow_total = arrow_total + line.arrow_count
    clipped_total = clipped_total + line.clipped_arrows
    assert_equal(#line.theta, line.points)
    assert_equal(#line.r, line.points)
    assert_equal(#line.arrows, line.arrow_count)
    assert_true(line.closed == true or line.closed == false)
    assert_true(line.arc_length > 0)
    assert_true(line.seed_theta ~= nil and line.seed_r ~= nil)
    for _, arrow in ipairs(line.arrows) do
      assert_true(arrow.index >= 1 and arrow.index < line.points)
      assert_true(arrow.fraction >= 0 and arrow.fraction <= 1)
      assert_true(arrow.angle ~= nil)
      assert_true(arrow.clipped == true or arrow.clipped == false)
    end
  end
  assert_equal(total, series.point_count)
  assert_equal(arrow_total, series.arrow_count)
  assert_equal(clipped_total, series.clipped_arrow_count)

  -- Scene data is a deep copy: mutating it must not reach the figure.
  series.u[1][1] = 99
  series.lines[1].theta[1] = 99
  assert_true(figure._polar.series[1].u[1][1] ~= 99,
    "scene export must copy component matrices")
  assert_true(figure._polar.series[1].theta[1] ~= 99,
    "scene export must copy the theta grid")
end)

test("polar streamplot SVG metadata agrees with the scene export", function()
  local theta = full_turn(13)
  local r = linear_grid(4, 1, 4)
  local u, v = radial(theta, r)
  local figure = plt.figure({ width = 640, height = 640 })
  figure:polar_config({ rmax = 4 })
  figure:polar_streamplot(theta, r, u, v, {
    density = 0.7, step = 0.05, max_steps = 120, max_lines = 16,
    arrow_fraction = 0.95, head = 26, linestyle = "dashed",
    label = "flow",
  })
  figure:legend({ loc = "best" })
  local svg = figure:to_svg()
  local scene = scene_series(figure)
  local series = series_record(svg)

  assert_equal(tonumber(series["data-cols"]), scene.cols)
  assert_equal(tonumber(series["data-rows"]), scene.rows)
  assert_equal(tonumber(series["data-lines"]), scene.line_count)
  assert_equal(tonumber(series["data-points"]), scene.point_count)
  assert_equal(tonumber(series["data-arrow-count"]), scene.arrow_count)
  assert_equal(tonumber(series["data-clipped-arrow-count"]),
    scene.clipped_arrow_count)
  assert_equal(tonumber(series["data-closed-lines"]), scene.closed_line_count)
  assert_equal(series["data-step-mode"], scene.step_mode)
  assert_equal(series["data-linestyle"], scene.style.linestyle)
  assert_equal(series["data-periodic"], scene.periodic and "true" or "false")
  assert_equal(series["data-truncated"], scene.truncated and "true" or "false")
  assert_equal(series["data-clip"], "polar-circle")
  assert_equal(scene.clip, "polar_circle")
  assert_close(tonumber(series["data-step"]), scene.resolved_step, 1e-9,
    "resolved step")
  assert_close(tonumber(series["data-arrow-fraction"]), scene.arrow_fraction,
    1e-9, "arrow fraction")
  assert_equal(figure:to_scene().polar.legend.entries[1].linestyle, "dashed")

  local lines = line_records(svg)
  assert_equal(#lines, #scene.lines)
  local arrow_total = 0
  for index, line in ipairs(scene.lines) do
    local record = lines[index]
    assert_equal(tonumber(record["data-index"]), index)
    assert_equal(tonumber(record["data-points"]), line.points)
    assert_equal(tonumber(record["data-arrows"]), line.arrow_count)
    assert_equal(tonumber(record["data-clipped-arrows"]), line.clipped_arrows)
    assert_equal(record["data-closed"], line.closed and "true" or "false")
    assert_close(tonumber(record["data-seed-theta"]), line.seed_theta, 1e-3,
      "seed theta")
    assert_close(tonumber(record["data-seed-r"]), line.seed_r, 1e-3,
      "seed radius")
    assert_close(tonumber(record["data-arc-length"]), line.arc_length, 1e-3,
      "arc length")
    arrow_total = arrow_total + line.arrow_count
  end
  assert_equal(arrow_total, scene.arrow_count)

  local flat_arrows = {}
  for _, line in ipairs(scene.lines) do
    for _, arrow in ipairs(line.arrows) do
      flat_arrows[#flat_arrows + 1] = arrow
    end
  end
  local arrows = arrow_records(svg)
  assert_equal(#arrows, #flat_arrows)
  local clipped_total = 0
  for index, arrow in ipairs(flat_arrows) do
    local record = arrows[index]
    assert_equal(tonumber(record["data-index"]), arrow.index)
    assert_close(tonumber(record["data-fraction"]), arrow.fraction, 1e-3,
      "arrow fraction")
    assert_close(tonumber(record["data-theta"]), arrow.theta, 1e-3,
      "arrow theta")
    assert_close(tonumber(record["data-r"]), arrow.r, 1e-3, "arrow radius")
    assert_close(tonumber(record["data-angle"]), arrow.angle, 1e-3,
      "arrow angle")
    assert_equal(record["data-clipped"], arrow.clipped and "true" or "false")
    if arrow.clipped then clipped_total = clipped_total + 1 end
  end
  assert_equal(clipped_total, scene.clipped_arrow_count)
  assert_well_formed_svg(svg)
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
  assert_error("arrow_fraction must be >= 0%.05", function()
    streamplot(theta, r, u, v, { arrow_fraction = 0.01 })
  end)
  assert_error("arrow_fraction must be <= 0%.95", function()
    streamplot(theta, r, u, v, { arrow_fraction = 0.99 })
  end)
  assert_error("arrow_fraction must be a number", function()
    streamplot(theta, r, u, v, { arrow_fraction = "middle" })
  end)
  assert_error("linestyle must be one of", function()
    streamplot(theta, r, u, v, { linestyle = "dashdot" })
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
