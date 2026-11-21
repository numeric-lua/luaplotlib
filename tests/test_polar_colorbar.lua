-- Polar heatmap colorbar tests: opt-in rendering, tick geometry, legend
-- avoidance, scene export, and validation.

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

local function colorbar_box(svg)
  local x, y, width, height = svg:match(
    '<g class="polar%-colorbar"[^>]-data%-x="([^"]+)" data%-y="([^"]+)" data%-width="([^"]+)" data%-height="([^"]+)"')
  assert_true(x ~= nil, "expected colorbar geometry metadata")
  return {
    x = tonumber(x), y = tonumber(y),
    width = tonumber(width), height = tonumber(height),
  }
end

local function legend_box(svg)
  local x, y, width, height = svg:match(
    '<g class="polar%-legend"[^>]-data%-x="([^"]+)" data%-y="([^"]+)" data%-width="([^"]+)" data%-height="([^"]+)"')
  assert_true(x ~= nil, "expected legend geometry metadata")
  return {
    x = tonumber(x), y = tonumber(y),
    width = tonumber(width), height = tonumber(height),
  }
end

local function boxes_overlap(first, second)
  local left = math.max(first.x, second.x)
  local right = math.min(first.x + first.width, second.x + second.width)
  local top = math.max(first.y, second.y)
  local bottom = math.min(first.y + first.height, second.y + second.height)
  return right > left and bottom > top
end

test("polar colorbar is opt-in and shrinks the circle to reserve space", function()
  local plain = plt.figure({ width = 600, height = 600 })
  plain:polar_heatmap(field(4, 8))
  local plain_svg = plain:to_svg()
  assert_not_contains(plain_svg, 'class="polar-colorbar"')

  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_heatmap(field(4, 8), {
    colorbar = true, colorbar_label = "level", colorbar_ticks = 4,
  })
  local svg = figure:to_svg()

  assert_contains(svg, 'class="polar-colorbar"')
  assert_contains(svg,
    'data-orientation="vertical" data-vmin="11" data-vmax="48" data-ticks="4"')
  assert_equal(count(svg, 'class="colorbar%-step"'), 40)
  assert_equal(count(svg, 'class="colorbar%-label"'), 4)
  assert_contains(svg, 'class="colorbar-frame"')
  assert_contains(svg, 'class="colorbar-title"')
  assert_contains(svg, 'transform="rotate(-90 ')
  assert_contains(svg, '>level<')
  assert_well_formed_svg(svg)

  local plain_radius = tonumber(plain_svg:match('data%-radius="([^"]+)"'))
  local bar_radius = tonumber(svg:match('data%-radius="([^"]+)"'))
  assert_true(bar_radius < plain_radius,
    "the colorbar should reserve canvas width instead of overlapping the circle")

  local box = colorbar_box(svg)
  assert_true(box.x >= 0 and box.y >= 0)
  assert_true(box.x + box.width <= 600, "colorbar must stay on the canvas")
  assert_true(box.y + box.height <= 600, "colorbar must stay on the canvas")
  assert_true(box.y + box.height / 2 > box.y + box.height / 3,
    "expected a vertical orientation")
end)

test("polar colorbar ticks run from vmin at the bottom to vmax at the top",
    function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_heatmap(field(4, 8), {
    colorbar = true, colorbar_ticks = 4,
  })
  local svg = figure:to_svg()
  local labels = {}
  for y, value in svg:gmatch(
      '<text class="colorbar%-label" x="[^"]+" y="([^"]+)"[^>]*>([^<]+)</text>') do
    labels[#labels + 1] = { y = tonumber(y), value = tonumber(value) }
  end
  assert_equal(#labels, 4)
  assert_equal(labels[1].value, 11)
  assert_equal(labels[4].value, 48)
  assert_true(labels[1].y > labels[4].y,
    "vmin should be drawn below vmax")

  local scene = figure:to_scene()
  local bar = scene.polar.colorbar
  assert_true(bar ~= nil, "expected colorbar scene export")
  assert_equal(bar.orientation, "vertical")
  assert_equal(bar.vmin, 11)
  assert_equal(bar.vmax, 48)
  assert_equal(#bar.ticks, 4)
  assert_equal(bar.ticks[1], 11)
  assert_equal(bar.ticks[4], 48)
  assert_equal(scene.polar.heatmaps[1].colorbar, true)
end)

test("polar colorbar exports legend range metadata and a gradient swatch",
    function()
  local figure = plt.figure({ width = 640, height = 640 })
  figure:polar_heatmap(field(4, 8), {
    label = "field", colorbar = true, colorbar_label = "value",
  })
  figure:legend({ loc = "best" })
  local svg = figure:to_svg()
  assert_equal(count(svg, 'class="legend%-swatch%-step"'), 5)
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  assert_equal(scene.polar.legend.entries[1].kind, "heatmap")
  assert_equal(scene.polar.legend.entries[1].vmin, 11)
  assert_equal(scene.polar.legend.entries[1].vmax, 48)
  assert_equal(scene.polar.colorbar.label, "value")
end)

test("polar legends stay clear of the reserved colorbar column", function()
  for _, loc in ipairs({ "upper right", "lower right", "best", "upper left" }) do
    local figure = plt.figure({ width = 640, height = 640 })
    figure:polar_heatmap(field(4, 8), {
      label = "field", colorbar = true, colorbar_label = "value",
    })
    figure:legend({ loc = loc })
    local svg = figure:to_svg()
    local legend = legend_box(svg)
    local bar = colorbar_box(svg)
    assert_false(boxes_overlap(legend, bar),
      "legend overlaps the colorbar for loc=" .. loc)
    assert_well_formed_svg(svg)
  end
end)

test("polar colorbar validates options and uniqueness", function()
  local function figure()
    return plt.figure({ width = 500, height = 500 })
  end
  assert_error("colorbar must be a boolean", function()
    figure():polar_heatmap(field(2, 2), { colorbar = "yes" })
  end)
  assert_error("colorbar_label must be a string", function()
    figure():polar_heatmap(field(2, 2), { colorbar_label = 3 })
  end)
  assert_error("colorbar_ticks must be >= 2", function()
    figure():polar_heatmap(field(2, 2), { colorbar = true, colorbar_ticks = 1 })
  end)
  assert_error("colorbar_ticks must be <= 9", function()
    figure():polar_heatmap(field(2, 2), { colorbar = true, colorbar_ticks = 10 })
  end)
  assert_error("colorbar_ticks must be an integer", function()
    figure():polar_heatmap(field(2, 2), {
      colorbar = true, colorbar_ticks = 2.5,
    })
  end)
  assert_error("only one polar colorbar per figure is supported", function()
    local fig = figure()
    fig:polar_heatmap(field(2, 2), { colorbar = true })
    fig:polar_heatmap(field(2, 2), { colorbar = true })
    fig:to_svg()
  end)
  assert_error("only one polar colorbar per figure is supported", function()
    local fig = figure()
    fig:polar_heatmap(field(2, 2), { colorbar = true })
    fig:polar_heatmap(field(2, 2), { colorbar = true })
    fig:to_scene()
  end)
end)

test("polar colorbar leaves cartesian figures untouched", function()
  local cartesian = plt.figure({ width = 400, height = 300 })
  cartesian:imshow({ { 1, 2 }, { 3, 4 } }, { colorbar = true })
  local svg = cartesian:to_svg()
  assert_contains(svg, 'class="colorbar"')
  assert_not_contains(svg, 'class="polar-colorbar"')
  assert_equal(cartesian:to_scene().polar, nil)
end)
