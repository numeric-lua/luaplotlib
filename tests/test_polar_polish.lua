-- Polar polish tests: label-aware legend placement, annotations, error bars,
-- and scene/SVG export parity.

local plt = require("luaplotlib")

local function display_chars(text)
  local count = 0
  for index = 1, #text do
    local byte = text:byte(index)
    if byte < 128 or byte >= 192 then count = count + 1 end
  end
  return count
end

local function text_bounds(x, baseline, text, fontsize, anchor)
  local width = display_chars(text) * fontsize * 0.8
  local left = x
  if anchor == "middle" then
    left = x - width / 2
  elseif anchor == "end" then
    left = x - width
  end
  return {
    x = left,
    y = baseline - fontsize,
    width = width,
    height = fontsize * 1.4,
  }
end

local function box_overlap(first, second, padding)
  padding = padding or 0
  local left = math.max(first.x, second.x) - padding
  local right = math.min(first.x + first.width, second.x + second.width) + padding
  local top = math.max(first.y, second.y) - padding
  local bottom = math.min(first.y + first.height, second.y + second.height) + padding
  return right > left and bottom > top
end

local function theta_boxes(svg)
  local boxes = {}
  for x, y, anchor, label in svg:gmatch(
      '<text class="theta%-tick" x="([^"]+)" y="([^"]+)"[^>]*text%-anchor="([^"]+)"[^>]*>(.-)</text>') do
    boxes[#boxes + 1] = text_bounds(tonumber(x), tonumber(y), label, 11, anchor)
  end
  return boxes
end

local function legend_box(svg)
  local loc, placement, x, y, width, height = svg:match(
    '<g class="polar%-legend" data%-loc="([^"]*)" data%-placement="([^"]*)" data%-x="([^"]+)" data%-y="([^"]+)" data%-width="([^"]+)" data%-height="([^"]+)"')
  assert_true(x ~= nil, "expected legend geometry metadata")
  return {
    loc = loc,
    placement = placement,
    x = tonumber(x),
    y = tonumber(y),
    width = tonumber(width),
    height = tonumber(height),
  }
end

local function assert_legend_clear_of_theta(svg)
  local legend = legend_box(svg)
  local boxes = theta_boxes(svg)
  assert_true(#boxes > 0, "expected theta tick labels")
  for index, box in ipairs(boxes) do
    assert_false(box_overlap(legend, box, 2),
      "legend overlaps theta tick label " .. index)
  end
  return legend
end

local function polar_figure(width, height)
  local figure = plt.figure({ width = width or 640, height = height or 480 })
  local theta, radius = {}, {}
  for index = 1, 181 do
    theta[index] = (index - 1) * 2 * math.pi / 180
    radius[index] = 3 + math.sin(4 * theta[index])
  end
  figure:polar(theta, radius, { label = "3 + sin(4*theta)" })
  figure:polar_scatter({ 0, math.pi / 2 }, { 4, 4 }, { label = "samples" })
  return figure
end

test("polar legend avoids theta labels for every requested corner", function()
  for _, loc in ipairs({ "upper right", "upper left", "lower right",
      "lower left", "best" }) do
    local figure = polar_figure()
    figure:title("polar legend")
    figure:legend({ loc = loc })
    local svg = figure:to_svg()
    local legend = assert_legend_clear_of_theta(svg)
    assert_equal(legend.loc, loc)
    assert_contains(svg, 'class="polar-legend"')
    assert_well_formed_svg(svg)
  end
end)

test("polar legend avoids labels without a title and on a square canvas", function()
  local figure = polar_figure(620, 620)
  figure:legend({ loc = "upper right" })
  local svg = figure:to_svg()
  assert_legend_clear_of_theta(svg)
  assert_well_formed_svg(svg)
end)

test("multi-column titled polar legend stays clear of angular labels", function()
  local figure = plt.figure({ width = 640, height = 480 })
  figure:polar({ 0, 1 }, { 2, 3 }, { label = "first series" })
  figure:polar({ 0, 1 }, { 3, 2 }, { label = "second series" })
  figure:polar({ 0, 1 }, { 1, 4 }, { label = "third series" })
  figure:polar({ 0, 1 }, { 4, 1 }, { label = "fourth series" })
  figure:title("multi-column")
  figure:legend({ loc = "best", ncol = 2, title = "series" })
  local svg = figure:to_svg()
  assert_contains(svg, '>series<')
  assert_contains(svg, '>fourth series<')
  assert_legend_clear_of_theta(svg)
  assert_well_formed_svg(svg)
end)

test("polar legend with a frame and no frame both report geometry", function()
  local framed = polar_figure()
  framed:legend()
  local framed_svg = framed:to_svg()
  assert_contains(framed_svg, 'class="legend-frame"')
  assert_legend_clear_of_theta(framed_svg)

  local plain = polar_figure()
  plain:legend({ frame = false })
  local plain_svg = plain:to_svg()
  assert_not_contains(plain_svg, 'class="legend-frame"')
  assert_legend_clear_of_theta(plain_svg)
end)

test("polar annotations render a target, leader arrow, and scene copy", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar({ 0, math.pi / 2 }, { 2, 5 }, { label = "line" })
  figure:polar_annotate("peak", math.pi / 2, 5, {
    xytext = { 1.2, 6 },
    align = "center",
    color = "#d62728",
    fontsize = 13,
    arrow = { color = "#333333", linewidth = 2, head = 9 },
  })
  local svg = figure:to_svg()
  assert_contains(svg, 'class="annotation-layer"')
  assert_contains(svg, 'class="annotation-text"')
  assert_contains(svg, '>peak<')
  assert_contains(svg, 'class="annotation-arrow"')
  assert_contains(svg, 'class="annotation-arrow-head"')
  assert_contains(svg, 'fill="#d62728"')
  assert_contains(svg, 'text-anchor="middle"')
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  assert_equal(#scene.annotations, 1)
  local annotation = scene.annotations[1]
  assert_equal(annotation.kind, "annotation")
  assert_equal(annotation.text, "peak")
  assert_true(math.abs(annotation.theta - math.pi / 2) < 1e-12)
  assert_equal(annotation.r, 5)
  assert_true(math.abs(annotation.xytext[1] - 1.2) < 1e-12)
  assert_equal(annotation.xytext[2], 6)
  assert_equal(annotation.xytext.theta, annotation.xytext[1])
  assert_equal(annotation.xytext.r, annotation.xytext[2])
  assert_equal(annotation.style.align, "center")
  assert_equal(annotation.arrow.enabled, true)
  assert_equal(annotation.arrow.head, 9)
end)

test("Figure:annotate dispatches to polar coordinates", function()
  local figure = plt.figure({ width = 500, height = 500 })
  figure:polar({ 0 }, { 2 }, { label = "point" })
  assert_equal(figure:annotate("north", 90, 2, { degrees = true }), figure)
  local svg = figure:to_svg()
  assert_contains(svg, 'class="annotation-text"')
  assert_contains(svg, '>north<')
  local cx = tonumber(svg:match('data%-cx="([%d%.%-]+)"'))
  local cy = tonumber(svg:match('data%-cy="([%d%.%-]+)"'))
  local radius = tonumber(svg:match('data%-radius="([%d%.%-]+)"'))
  local rmax = tonumber(svg:match('data%-rmax="([%d%.%-]+)"'))
  local x = tonumber(svg:match(
    '<text class="annotation%-text" x="([%d%.%-]+)"'))
  local y = tonumber(svg:match(
    '<text class="annotation%-text" x="[%d%.%-]+" y="([%d%.%-]+)"'))
  assert_true(math.abs(x - cx) < 0.01)
  assert_true(math.abs(y - (cy - radius * 2 / rmax)) < 0.01,
    "90 degrees should place the annotation above the center")
end)

test("polar annotation validates coordinates and options", function()
  local function polar()
    local figure = plt.figure()
    figure:polar({ 0 }, { 1 })
    return figure
  end
  assert_error("requires text, theta, and r", function()
    polar():polar_annotate("x", 0)
  end)
  assert_error("theta must be a number", function()
    polar():polar_annotate("x", "zero", 1)
  end)
  assert_error("r must be a number", function()
    polar():polar_annotate("x", 0, "one")
  end)
  assert_error("unsupported polar annotate option", function()
    polar():polar_annotate("x", 0, 1, { bogus = true })
  end)
  assert_error("align must be", function()
    polar():polar_annotate("x", 0, 1, { align = "justify" })
  end)
  assert_error("cannot both be set", function()
    polar():polar_annotate("x", 0, 1, {
      degrees = true, theta_unit = "degrees",
    })
  end)
  assert_error("xytext must contain exactly two", function()
    polar():polar_annotate("x", 0, 1, { xytext = { 1, 2, 3 } })
  end)
  assert_error("cannot mix cartesian annotations", function()
    local figure = plt.figure()
    figure:annotate("cartesian", 1, 1)
    figure:polar({ 0 }, { 1 })
  end)
end)

test("polar error bars render radial and angular errors with scene export", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar({ 0, math.pi / 2 }, { 2, 3 }, {
    linewidth = 2, marker = "square", label = "line",
  })
  figure:polar_errorbar({ 0, math.pi / 2 }, { 2, 3 }, { 0.5, 0.25 }, {
    thetaerr = { 0.1, 0.2 },
    elinewidth = 2,
    capsize = 5,
    ecolor = "#123456",
    label = "errors",
  })
  local svg = figure:to_svg()
  assert_contains(svg, 'class="series series-polar-errorbar"')
  assert_equal(select(2, svg:gsub('polar%-errorbar%-r"', "")), 2)
  assert_equal(select(2, svg:gsub('polar%-errorbar%-theta"', "")), 2)
  assert_equal(select(2, svg:gsub('polar%-errorbar%-cap"', "")), 8)
  assert_contains(svg, 'stroke="#123456"')
  assert_contains(svg, 'class="polar-errorbar-line"')
  assert_contains(svg, 'data-label="errors"')
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  assert_equal(#scene.polar.series, 2)
  local exported = scene.polar.series[2]
  assert_equal(exported.kind, "errorbar")
  assert_equal(exported.rerr[1], 0.5)
  assert_true(math.abs(exported.thetaerr[2] - 0.2) < 1e-12)
  assert_equal(exported.style.ecolor, "#123456")
  assert_equal(exported.style.capsize, 5)
  assert_equal(exported.style.elinewidth, 2)
  assert_true(scene.polar.rmax >= 3.25,
    "automatic rmax should include the radial error extent")
end)

test("polar error bars accept degrees and full-turn angular errors", function()
  local figure = plt.figure({ width = 500, height = 500 })
  figure:polar_errorbar({ 0, 90 }, { 2, 2 }, 0.5, {
    degrees = true,
    thetaerr = { 180, 360 },
  })
  local svg = figure:to_svg()
  assert_contains(svg, 'polar-errorbar-theta')
  assert_equal(select(2, svg:gsub('polar%-errorbar%-theta"', "")), 2)
  assert_contains(svg, '<circle class="polar-errorbar polar-errorbar-theta"')
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  local thetaerr = scene.polar.series[1].thetaerr
  assert_true(math.abs(thetaerr[1] - math.pi) < 1e-12)
  assert_true(math.abs(thetaerr[2] - 2 * math.pi) < 1e-12)
end)

test("polar error bar validates data and options", function()
  local function polar()
    local figure = plt.figure()
    figure:polar({ 0 }, { 1 })
    return figure
  end
  assert_error("requires rerr", function()
    polar():polar_errorbar({ 0 }, { 1 })
  end)
  assert_error("same length", function()
    polar():polar_errorbar({ 0, 1 }, { 1 })
  end)
  assert_error("one entry per point", function()
    polar():polar_errorbar({ 0, 1 }, { 1, 2 }, { 0.5 })
  end)
  assert_error("non%-negative", function()
    polar():polar_errorbar({ 0 }, { 1 }, { -0.5 })
  end)
  assert_error("at most 2%*pi", function()
    polar():polar_errorbar({ 0 }, { 1 }, 0, { thetaerr = 7 })
  end)
  assert_error("linestyle must be", function()
    polar():polar_errorbar({ 0 }, { 1 }, 0, { linestyle = "wavy" })
  end)
  assert_error("unsupported polar errorbar option", function()
    polar():polar_errorbar({ 0 }, { 1 }, 0, { bogus = true })
  end)
  assert_error("exceeds the configured rmax", function()
    local figure = plt.figure()
    figure:polar_config({ rmax = 2 })
    figure:polar_errorbar({ 0 }, { 2 }, 0.5)
    figure:to_svg()
  end)
end)

test("polar scene exports legend entries and tick fractions", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 4, rgrids = { 1, 2, 4 } })
  figure:polar({ 0, math.pi / 2 }, { 1, 2 }, { label = "line" })
  figure:polar_errorbar({ 0 }, { 3 }, 0.25, { label = "errors" })
  figure:legend({ loc = "best", ncol = 2, title = "legend title" })
  local scene = figure:to_scene()
  assert_equal(scene.polar.legend.loc, "best")
  assert_equal(scene.polar.legend.ncol, 2)
  assert_equal(scene.polar.legend.title, "legend title")
  assert_equal(scene.polar.legend.frame, true)
  assert_equal(#scene.polar.legend.entries, 2)
  assert_equal(scene.polar.legend.entries[1].label, "line")
  assert_equal(scene.polar.legend.entries[2].kind, "errorbar")
  assert_equal(scene.polar.r_ticks[2].fraction, 0.5)
  assert_equal(scene.polar.r_ticks[3].fraction, 1)

  local svg = figure:to_svg()
  assert_contains(svg, '>legend title<')
  assert_contains(svg, '>line<')
  assert_contains(svg, '>errors<')
  assert_well_formed_svg(svg)
end)

test("polar SVG, file, HTML, and scene exports stay consistent", function()
  local figure = polar_figure()
  figure:polar_errorbar({ 0 }, { 4 }, 0.5, { label = "errors" })
  figure:title("export parity")
  figure:legend({ loc = "best" })
  local svg = figure:to_svg()

  local path = (TMPDIR or "/tmp") .. "/luaplotlib-polar-consistency.svg"
  assert_equal(figure:savefig(path), path)
  local handle = assert(io.open(path, "rb"))
  local saved = handle:read("*a")
  handle:close()
  os.remove(path)
  assert_equal(saved, svg)

  local html = figure:to_html("polar export")
  assert_contains(html, svg)
  assert_contains(html, "polar export")

  local scene = figure:to_scene()
  assert_equal(scene.polar.rmax, tonumber(svg:match('data%-rmax="([%d%.%-]+)"')))
  assert_equal(#scene.polar.theta_ticks, 8)
  assert_true(#scene.polar.r_ticks >= 3)
  assert_equal(scene.polar.r_ticks[#scene.polar.r_ticks].fraction, 1)
  assert_equal(scene.annotations and #scene.annotations or 0, 0)
  assert_well_formed_svg(svg)
end)

test("polar scene export rejects mixed cartesian content", function()
  assert_error("cannot mix cartesian and polar series", function()
    local figure = plt.figure()
    figure:polar({ 0 }, { 1 })
    figure:plot({ 1, 2 }, { 1, 2 })
    figure:to_scene()
  end)
  assert_error("cannot mix cartesian annotations", function()
    local figure = plt.figure()
    figure:polar({ 0 }, { 1 })
    -- Bypass the eager guard to exercise the exporter's own check too.
    figure._annotations[1] = {
      text = "cartesian", x = 1, y = 1, color = "#222222",
      fontsize = 12, align = "left",
    }
    figure:to_scene()
  end)
end)

test("polar legend avoids labels after rotation and direction changes", function()
  local figure = polar_figure(620, 620)
  figure:polar_config({
    theta_zero = "N",
    theta_direction = "clockwise",
    thetagrids = { 0, 45, 90, 135, 180, 225, 270, 315 },
    thetagrid_labels = {
      "zero", "forty five", "ninety", "one thirty five",
      "one eighty", "two twenty five", "two seventy", "three fifteen",
    },
  })
  figure:title("rotated labels")
  figure:legend({ loc = "best" })
  local svg = figure:to_svg()
  assert_contains(svg, ">forty five<")
  assert_legend_clear_of_theta(svg)
  assert_well_formed_svg(svg)
end)

test("polar_config rejects a figure with cartesian annotations", function()
  assert_error("cannot mix cartesian annotations", function()
    local figure = plt.figure()
    figure:annotate("cartesian", 1, 1)
    figure:polar_config({ rmax = 1 })
  end)
end)

test("cartesian legends still accept the additive best location", function()
  local figure = plt.figure({ width = 400, height = 300 })
  figure:plot({ 1, 2 }, { 2, 1 }, { label = "line" })
  figure:legend({ loc = "best" })
  local svg = figure:to_svg()
  assert_contains(svg, 'class="legend"')
  assert_contains(svg, '>line<')
  assert_well_formed_svg(svg)
end)

test("polar radial labels draw above series with a contrast halo", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_bar({ 0, math.pi / 2 }, { 4, 4 }, { width = 1 })
  figure:polar({ 0, math.pi / 2 }, { 2, 2 })
  local svg = figure:to_svg()
  local ticks_at = svg:find('<g class="r%-ticks">')
  local series_at = svg:find('<g class="series%-layer"')
  assert_true(ticks_at ~= nil and series_at ~= nil)
  assert_true(ticks_at > series_at,
    "radial labels should render above the clipped series layer")
  assert_contains(svg, 'class="r-tick"')
  assert_contains(svg, 'paint-order="stroke"')
  assert_contains(svg, 'stroke-width="2.5"')
  assert_well_formed_svg(svg)
end)

test("the outermost radial label is clamped inside the polar frame", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar_config({ rmax = 5, rgrids = { 1, 3, 5 } })
  figure:polar({ 0, math.pi / 2 }, { 5, 5 })
  local svg = figure:to_svg()
  local cy, radius = svg:match(
    'class="polar" data%-cx="[^"]+" data%-cy="([^"]+)" data%-radius="([^"]+)"')
  assert_true(cy ~= nil and radius ~= nil)
  cy, radius = tonumber(cy), tonumber(radius)
  local target
  for y, fraction, clamped in svg:gmatch(
      '<text class="r%-tick" x="[^"]+" y="([^"]+)"[^>]-data%-fraction="([^"]+)" data%-clamped="([^"]+)"') do
    if fraction == "1" then
      target = { y = tonumber(y), clamped = clamped }
    end
  end
  assert_true(target ~= nil, "expected the outer radial tick")
  assert_equal(target.clamped, "true")
  assert_true(target.y >= cy - radius + 12.5,
    "outermost label should sit fully inside the frame")
  -- Labels below the frame stay unclamped and keep their natural baseline.
  local saw_unclamped = false
  for flag in svg:gmatch(
      '<text class="r%-tick"[^>]-data%-clamped="([^"]+)"') do
    if flag == "false" then saw_unclamped = true end
  end
  assert_true(saw_unclamped)
  assert_well_formed_svg(svg)
end)

test("polar heatmap legends use a gradient swatch with scene range data",
    function()
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
  local figure = plt.figure({ width = 640, height = 640 })
  figure:polar_heatmap(field(4, 8), { label = "field" })
  figure:legend({ loc = "best" })
  local svg = figure:to_svg()
  local swatches = select(2, svg:gsub('class="legend%-swatch%-step"', ""))
  assert_equal(swatches, 5)
  local colors = {}
  for color in svg:gmatch(
      '<rect class="legend%-swatch%-step"[^>]-fill="([^"]+)"') do
    colors[color] = true
  end
  local distinct = 0
  for _ in pairs(colors) do distinct = distinct + 1 end
  assert_equal(distinct, 5)
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  local entry = scene.polar.legend.entries[1]
  assert_equal(entry.kind, "heatmap")
  assert_equal(entry.vmin, 11)
  assert_equal(entry.vmax, 48)
end)
