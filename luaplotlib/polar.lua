-- Polar axes and series rendering for the SVG backend.
--
-- A figure enters polar mode through `fig:polar` or `plt.polar`.  Polar
-- figures use their own renderer instead of the Cartesian one: the axes are a
-- circle, the grid is made of concentric circles and angular spokes, and the
-- theta tick labels sit outside the circle.
--
-- Data theta values are radians.  The renderer converts each (theta, r) point
-- with
--
--   x = cx + scale * r * cos(theta_display)
--   y = cy - scale * r * sin(theta_display)
--
-- where theta_display accounts for the configured zero location and direction.
-- Negative r values therefore plot on the opposite side of the origin, which
-- matches matplotlib's polar convention.

local markers = require("luaplotlib.markers")
local ticks = require("luaplotlib.ticks")
local util = require("luaplotlib.util")

local M = {}

local DEGREE = "\194\176" -- UTF-8 degree sign
local GRID_COLOR = "#d9d9d9"
local AXIS_COLOR = "#333333"
local TEXT_COLOR = "#222222"
local FONT_FAMILY = "Helvetica, Arial, sans-serif"

local DEFAULT_THETA_DEGREES = { 0, 45, 90, 135, 180, 225, 270, 315 }

local ZERO_OFFSETS = {
  E = 0,
  N = math.pi / 2,
  W = math.pi,
  S = -math.pi / 2,
}

local DIRECTIONS = {
  counterclockwise = 1,
  ccw = 1,
  clockwise = -1,
  cw = -1,
}

local CONFIG_OPTIONS = {
  theta_zero = true,
  theta_direction = true,
  rmax = true,
  thetagrids = true,
  thetagrid_labels = true,
  rgrids = true,
  rgrid_labels = true,
}

local function fail(message)
  util.fail(message, 3)
end

-- Fresh polar state, attached to a Figure as `_polar`.
function M.new_state()
  return {
    series = {},
    annotations = {},
    theta_zero = 0,
    theta_direction = 1,
    rmax = nil,
    thetagrids = nil,
    thetagrid_labels = nil,
    rgrids = nil,
    rgrid_labels = nil,
  }
end

function M.ensure(figure)
  if figure._polar == nil then
    figure._polar = M.new_state()
  end
  return figure._polar
end

-- Convert a data angle in radians to the display angle used by the SVG
-- conversion (radians from east, counterclockwise positive).
function M.theta_to_display(figure, theta)
  local state = figure._polar or M.new_state()
  return (state.theta_zero or 0) + (state.theta_direction or 1) * theta
end

local function observed_radius(figure)
  local maximum = 0
  for _, series in ipairs(figure._polar.series) do
    if series.r ~= nil then
      for index = 1, #series.r do
        local value = math.abs(series.r[index])
        if series.rerr ~= nil then
          value = value + series.rerr[index]
        end
        if value > maximum then maximum = value end
      end
    end
  end
  return maximum
end

-- Choose radial grid values for an automatic radius.  The outer radius is a
-- multiple of a "nice" step, so the outermost label normally coincides with
-- the polar frame.
local function automatic_rvalues(rmax)
  local step = ticks.nice_step(rmax / 5)
  local values = {}
  local count = math.floor(rmax / step + 1e-9)
  for index = 1, count do
    values[index] = index * step
  end
  if #values == 0 or rmax - values[#values] > step * 0.25 then
    values[#values + 1] = rmax
  end
  return values
end

local function checked_grid(value, name, allow_zero)
  if type(value) ~= "table" or #value == 0 then
    fail(name .. " must be a non-empty table")
  end
  local result = {}
  for index = 1, #value do
    local number = util.check_number(value[index],
      name .. "[" .. index .. "]")
    if allow_zero then
      if number < 0 then
        fail(name .. " values must be non-negative")
      end
    elseif number <= 0 then
      fail(name .. " values must be positive")
    end
    result[index] = number
  end
  return result
end

local function checked_labels(value, name, count)
  if type(value) ~= "table" or #value ~= count then
    fail(string.format("%s must have one entry per grid value (%d ~= %d)",
      name, type(value) == "table" and #value or 0, count))
  end
  local result = {}
  for index = 1, count do
    result[index] = util.check_string(value[index],
      name .. "[" .. index .. "]", true)
  end
  return result
end

-- Validate and apply `fig:polar_config` options.  Orientation values are
-- stored directly on the polar state; grid angles remain in degrees in data
-- theta coordinates, while theta_zero is a display offset in radians.
function M.configure(figure, opts)
  opts = util.check_options(opts, CONFIG_OPTIONS, "polar_config")
  local state = M.ensure(figure)

  if opts.theta_zero ~= nil then
    local value = opts.theta_zero
    if type(value) == "string" then
      local offset = ZERO_OFFSETS[string.upper(value)]
      if offset == nil then
        fail("polar_config theta_zero must be E, N, W, S, or a number in radians")
      end
      state.theta_zero = offset
    elseif type(value) == "number" then
      state.theta_zero = util.check_number(value,
        "polar_config theta_zero")
    else
      fail("polar_config theta_zero must be E, N, W, S, or a number in radians")
    end
  end

  if opts.theta_direction ~= nil then
    if type(opts.theta_direction) ~= "string" then
      fail("polar_config theta_direction must be 'counterclockwise' or 'clockwise'")
    end
    local direction = DIRECTIONS[string.lower(opts.theta_direction)]
    if direction == nil then
      fail("polar_config theta_direction must be 'counterclockwise' or 'clockwise'")
    end
    state.theta_direction = direction
  end

  if opts.rmax ~= nil then
    local rmax = util.check_number(opts.rmax, "polar_config rmax")
    if rmax <= 0 then
      fail("polar_config rmax must be positive")
    end
    state.rmax = rmax
  end

  if opts.thetagrids ~= nil then
    state.thetagrids = checked_grid(opts.thetagrids,
      "polar_config thetagrids", true)
    if opts.thetagrid_labels == nil then
      state.thetagrid_labels = nil
    end
  end
  if opts.thetagrid_labels ~= nil then
    if state.thetagrids == nil then
      fail("polar_config thetagrid_labels requires thetagrids")
    end
    state.thetagrid_labels = checked_labels(opts.thetagrid_labels,
      "polar_config thetagrid_labels", #state.thetagrids)
  end

  if opts.rgrids ~= nil then
    state.rgrids = checked_grid(opts.rgrids, "polar_config rgrids", false)
    if opts.rgrid_labels == nil then
      state.rgrid_labels = nil
    end
  end
  if opts.rgrid_labels ~= nil then
    if state.rgrids == nil then
      fail("polar_config rgrid_labels requires rgrids")
    end
    state.rgrid_labels = checked_labels(opts.rgrid_labels,
      "polar_config rgrid_labels", #state.rgrids)
  end

  return state
end

-- Resolve the radial limit, radial grid, and angular grid used by both the
-- SVG renderer and the scene exporter.
function M.resolve(figure)
  local state = figure._polar
  if state == nil then
    fail("figure has no polar axes")
  end

  local observed = observed_radius(figure)
  local rmax = state.rmax
  if rmax == nil then
    local wanted = observed
    if state.rgrids ~= nil then
      for _, value in ipairs(state.rgrids) do
        if value > wanted then wanted = value end
      end
    end
    if wanted <= 0 then wanted = 1 end
    local target = wanted * 1.05
    local step = ticks.nice_step(target / 5)
    rmax = math.ceil(target / step - 1e-9) * step
  elseif observed > rmax * (1 + 1e-9) then
    fail(string.format(
      "polar r value %s exceeds the configured rmax %s",
      util.fmt_tick(observed), util.fmt_tick(rmax)))
  end
  if not (rmax > 0) then
    fail("polar rmax must be positive")
  end

  local rvalues, rlabels = {}, {}
  if state.rgrids ~= nil then
    for index, value in ipairs(state.rgrids) do
      if value > rmax * (1 + 1e-9) then
        fail(string.format(
          "polar rgrids value %s exceeds the configured rmax %s",
          util.fmt_tick(value), util.fmt_tick(rmax)))
      end
      rvalues[index] = value
      rlabels[index] = state.rgrid_labels and state.rgrid_labels[index] or
        util.fmt_tick(value)
    end
  else
    local values = automatic_rvalues(rmax)
    for index, value in ipairs(values) do
      rvalues[index] = value
      rlabels[index] = util.fmt_tick(value)
    end
  end

  local degrees = state.thetagrids or DEFAULT_THETA_DEGREES
  local angles, labels = {}, {}
  for index, value in ipairs(degrees) do
    angles[index] = value * math.pi / 180
    labels[index] = state.thetagrid_labels and state.thetagrid_labels[index] or
      (util.fmt_tick(value) .. DEGREE)
  end

  return {
    rmax = rmax,
    rticks = rvalues,
    rlabels = rlabels,
    theta_angles = angles,
    theta_labels = labels,
  }
end

-- Map a data (theta, r) pair to SVG user units.
function M.point(figure, cfg, geom, theta, r)
  local display = M.theta_to_display(figure, theta)
  local radial = r / cfg.rmax
  return geom.cx + geom.radius * radial * math.cos(display),
    geom.cy - geom.radius * radial * math.sin(display)
end

local function layout(figure)
  local width, height = figure.width, figure.height
  local top = 22
  if figure._title ~= nil then top = 52 end
  local bottom = 28
  local left, right = 44, 44
  local available_width = width - left - right
  local available_height = height - top - bottom
  local diameter = math.min(available_width, available_height)
  local radius = diameter / 2 - 18
  if radius < 24 then
    fail("figure is too small to render a polar plot")
  end
  return {
    width = width,
    height = height,
    cx = left + available_width / 2,
    cy = top + available_height / 2,
    radius = radius,
  }
end

local function render_line(series, figure, cfg, geom, buf)
  local style = series.style
  local opacity = ""
  if style.alpha < 1 then
    opacity = string.format(' stroke-opacity="%s"', util.fmt(style.alpha))
  end
  local dash = ""
  if style.linestyle == "dashed" then
    dash = ' stroke-dasharray="6 4"'
  elseif style.linestyle == "dotted" then
    dash = ' stroke-dasharray="1.5 3"'
  end
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', util.escape_xml(style.label))
  end

  buf[#buf + 1] = string.format('  <g class="series series-polar-line"%s>',
    label)
  local points = {}
  for index = 1, #series.theta do
    local x, y = M.point(figure, cfg, geom, series.theta[index], series.r[index])
    points[index] = util.fmt(x) .. "," .. util.fmt(y)
  end
  buf[#buf + 1] = string.format(
    '   <polyline class="polar-line" points="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"%s%s/>',
    table.concat(points, " "), style.color, util.fmt(style.linewidth), dash,
    opacity)

  local draw_marker = style.marker ~= nil or
    (#series.theta == 1 and style.linestyle ~= "none")
  if draw_marker then
    local marker_opacity = ""
    if style.alpha < 1 then
      marker_opacity = string.format(' fill-opacity="%s"',
        util.fmt(style.alpha))
    end
    for index = 1, #series.theta do
      local x, y = M.point(figure, cfg, geom, series.theta[index],
        series.r[index])
      buf[#buf + 1] = markers.svg(style.marker, "marker", x, y,
        style.markersize or 4, style.color, marker_opacity, "")
    end
  end
  buf[#buf + 1] = '  </g>'
end

local function render_scatter(series, figure, cfg, geom, buf)
  local style = series.style
  local fade = ""
  if style.alpha < 1 then
    fade = string.format(' fill-opacity="%s"', util.fmt(style.alpha))
  end
  local outline = ""
  if style.edgecolor ~= nil then
    outline = string.format(' stroke="%s" stroke-width="%s"',
      style.edgecolor, util.fmt(style.linewidth))
  end
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', util.escape_xml(style.label))
  end

  buf[#buf + 1] = string.format(
    '  <g class="series series-polar-scatter"%s>', label)
  for index = 1, #series.theta do
    local radius = style.radii and style.radii[index] or style.radius
    local color = style.colors and style.colors[index] or style.color
    local x, y = M.point(figure, cfg, geom, series.theta[index],
      series.r[index])
    buf[#buf + 1] = markers.svg(style.marker, "point", x, y, radius, color,
      fade, outline)
  end
  buf[#buf + 1] = '  </g>'
end

local function render_bar(series, figure, cfg, geom, buf)
  local style = series.style
  local opacity = ""
  if style.alpha < 1 then
    local alpha = util.fmt(style.alpha)
    opacity = string.format(' fill-opacity="%s" stroke-opacity="%s"',
      alpha, alpha)
  end
  local edge = style.edgecolor or "#ffffff"
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', util.escape_xml(style.label))
  end
  local sweep = (figure._polar.theta_direction or 1) < 0 and 1 or 0

  buf[#buf + 1] = string.format(
    '  <g class="series series-polar-bar"%s>', label)
  for index = 1, #series.theta do
    local value = series.r[index]
    if value > 0 then
      local width = series.widths[index] or series.width or 0.8
      local color = series.colors and series.colors[index] or style.color
      local radius = geom.radius * value / cfg.rmax
      if width >= 2 * math.pi - 1e-9 then
        buf[#buf + 1] = string.format(
          '   <circle class="polar-bar" cx="%s" cy="%s" r="%s" fill="%s" stroke="%s" stroke-width="1"%s/>',
          util.fmt(geom.cx), util.fmt(geom.cy), util.fmt(radius), color,
          edge, opacity)
      else
        local x1, y1 = M.point(figure, cfg, geom, series.theta[index], value)
        local x2, y2 = M.point(figure, cfg, geom,
          series.theta[index] + width, value)
        local large = width > math.pi and 1 or 0
        buf[#buf + 1] = string.format(
          '   <path class="polar-bar" d="M %s %s L %s %s A %s %s 0 %d %d %s %s Z" fill="%s" stroke="%s" stroke-width="1"%s/>',
          util.fmt(geom.cx), util.fmt(geom.cy), util.fmt(x1), util.fmt(y1),
          util.fmt(radius), util.fmt(radius), large, sweep, util.fmt(x2),
          util.fmt(y2), color, edge, opacity)
      end
    end
  end
  buf[#buf + 1] = '  </g>'
end

local function render_errorbar(series, figure, cfg, geom, buf)
  local style = series.style
  local cap = style.capsize or 4
  local width = style.elinewidth or 1
  local color = style.ecolor or style.color
  local opacity = ""
  if style.alpha < 1 then
    opacity = string.format(' stroke-opacity="%s"', util.fmt(style.alpha))
  end
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', util.escape_xml(style.label))
  end
  local sweep = (figure._polar.theta_direction or 1) < 0 and 1 or 0

  buf[#buf + 1] = string.format(
    '  <g class="series series-polar-errorbar"%s>', label)
  for index = 1, #series.theta do
    local theta = series.theta[index]
    local value = series.r[index]
    local radial = series.rerr and series.rerr[index] or 0
    if radial > 0 then
      local x0, y0 = M.point(figure, cfg, geom, theta, value - radial)
      local x1, y1 = M.point(figure, cfg, geom, theta, value + radial)
      buf[#buf + 1] = string.format(
        '   <line class="polar-errorbar polar-errorbar-r" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s/>',
        util.fmt(x0), util.fmt(y0), util.fmt(x1), util.fmt(y1), color,
        util.fmt(width), opacity)
      if cap > 0 then
        local dx, dy = x1 - x0, y1 - y0
        local length = math.sqrt(dx * dx + dy * dy)
        if length > 1e-9 then
          local px, py = -dy / length * cap, dx / length * cap
          for _, endpoint in ipairs({ { x0, y0 }, { x1, y1 } }) do
            buf[#buf + 1] = string.format(
              '   <line class="polar-errorbar-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s/>',
              util.fmt(endpoint[1] - px), util.fmt(endpoint[2] - py),
              util.fmt(endpoint[1] + px), util.fmt(endpoint[2] + py), color,
              util.fmt(width), opacity)
          end
        end
      end
    end

    local angular = series.thetaerr and series.thetaerr[index] or 0
    local radius = math.abs(value) / cfg.rmax * geom.radius
    if angular > 0 and radius > 1e-9 then
      if angular >= math.pi - 1e-12 then
        buf[#buf + 1] = string.format(
          '   <circle class="polar-errorbar polar-errorbar-theta" cx="%s" cy="%s" r="%s" fill="none" stroke="%s" stroke-width="%s"%s/>',
          util.fmt(geom.cx), util.fmt(geom.cy), util.fmt(radius), color,
          util.fmt(width), opacity)
      else
        local x0, y0 = M.point(figure, cfg, geom, theta - angular, value)
        local x1, y1 = M.point(figure, cfg, geom, theta + angular, value)
        local large = angular * 2 > math.pi and 1 or 0
        buf[#buf + 1] = string.format(
          '   <path class="polar-errorbar polar-errorbar-theta" d="M %s %s A %s %s 0 %d %d %s %s" fill="none" stroke="%s" stroke-width="%s"%s/>',
          util.fmt(x0), util.fmt(y0), util.fmt(radius), util.fmt(radius),
          large, sweep, util.fmt(x1), util.fmt(y1), color, util.fmt(width),
          opacity)
        if cap > 0 then
          for _, point in ipairs({ { x0, y0 }, { x1, y1 } }) do
            local ux = (point[1] - geom.cx) / radius
            local uy = (point[2] - geom.cy) / radius
            buf[#buf + 1] = string.format(
              '   <line class="polar-errorbar-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s/>',
              util.fmt(point[1] - ux * cap), util.fmt(point[2] - uy * cap),
              util.fmt(point[1] + ux * cap), util.fmt(point[2] + uy * cap),
              color, util.fmt(width), opacity)
          end
        end
      end
    end
  end

  local dash = ""
  if style.linestyle == "dashed" then
    dash = ' stroke-dasharray="6 4"'
  elseif style.linestyle == "dotted" then
    dash = ' stroke-dasharray="1.5 3"'
  end
  if style.linestyle ~= "none" and #series.theta > 1 then
    local points = {}
    for index = 1, #series.theta do
      local x, y = M.point(figure, cfg, geom, series.theta[index],
        series.r[index])
      points[index] = util.fmt(x) .. "," .. util.fmt(y)
    end
    buf[#buf + 1] = string.format(
      '   <polyline class="polar-errorbar-line" points="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"%s%s/>',
      table.concat(points, " "), style.color, util.fmt(style.linewidth), dash,
      opacity)
  end

  if style.marker ~= nil then
    local marker_opacity = ""
    if style.alpha < 1 then
      marker_opacity = string.format(' fill-opacity="%s"',
        util.fmt(style.alpha))
    end
    for index = 1, #series.theta do
      local x, y = M.point(figure, cfg, geom, series.theta[index],
        series.r[index])
      buf[#buf + 1] = markers.svg(style.marker, "marker", x, y,
        style.markersize or 4, style.color, marker_opacity, "")
    end
  end
  buf[#buf + 1] = '  </g>'
end

local function render_grid(figure, cfg, geom, buf)
  local state = figure._polar
  buf[#buf + 1] = string.format(
    '  <g class="polar-grid" stroke="%s" stroke-width="1">', GRID_COLOR)
  for _, angle in ipairs(cfg.theta_angles) do
    local display = state.theta_zero + state.theta_direction * angle
    local x = geom.cx + geom.radius * math.cos(display)
    local y = geom.cy - geom.radius * math.sin(display)
    buf[#buf + 1] = string.format(
      '   <line class="polar-spoke" x1="%s" y1="%s" x2="%s" y2="%s"/>',
      util.fmt(geom.cx), util.fmt(geom.cy), util.fmt(x), util.fmt(y))
  end
  for _, value in ipairs(cfg.rticks) do
    if value < cfg.rmax * (1 - 1e-9) then
      buf[#buf + 1] = string.format(
        '   <circle class="polar-circle" cx="%s" cy="%s" r="%s" fill="none"/>',
        util.fmt(geom.cx), util.fmt(geom.cy),
        util.fmt(geom.radius * value / cfg.rmax))
    end
  end
  buf[#buf + 1] = '  </g>'
end

local function render_theta_labels(figure, cfg, geom, buf)
  local state = figure._polar
  buf[#buf + 1] = '  <g class="theta-ticks">'
  for index, angle in ipairs(cfg.theta_angles) do
    local display = state.theta_zero + state.theta_direction * angle
    local cosine, sine = math.cos(display), math.sin(display)
    local x = geom.cx + (geom.radius + 16) * cosine
    local y = geom.cy - (geom.radius + 16) * sine + 4
    local anchor = "middle"
    if cosine > 0.25 then
      anchor = "start"
    elseif cosine < -0.25 then
      anchor = "end"
    end
    buf[#buf + 1] = string.format(
      '   <text class="theta-tick" x="%s" y="%s" font-size="11" fill="%s" text-anchor="%s">%s</text>',
      util.fmt(x), util.fmt(y), TEXT_COLOR, anchor,
      util.escape_xml(cfg.theta_labels[index]))
  end
  buf[#buf + 1] = '  </g>'
end

local function render_radius_labels(cfg, geom, buf)
  buf[#buf + 1] = '  <g class="r-ticks">'
  for index, value in ipairs(cfg.rticks) do
    local y = geom.cy - geom.radius * value / cfg.rmax + 4
    buf[#buf + 1] = string.format(
      '   <text class="r-tick" x="%s" y="%s" font-size="10" fill="%s" text-anchor="start">%s</text>',
      util.fmt(geom.cx + 6), util.fmt(y), TEXT_COLOR,
      util.escape_xml(cfg.rlabels[index]))
  end
  buf[#buf + 1] = '  </g>'
end

local ANNOTATION_ANCHORS = {
  left = "start",
  center = "middle",
  right = "end",
}

local function render_annotations(figure, cfg, geom, buf)
  local annotations = figure._polar.annotations or {}
  if #annotations == 0 then return end

  buf[#buf + 1] = '  <g class="annotation-layer">'
  for index, annotation in ipairs(annotations) do
    local target_x, target_y = M.point(figure, cfg, geom,
      annotation.theta, annotation.r)
    local text_x, text_y
    if annotation.xytext ~= nil then
      text_x, text_y = M.point(figure, cfg, geom,
        annotation.xytext[1], annotation.xytext[2])
    elseif annotation.arrow ~= nil then
      text_x, text_y = target_x + 12, target_y - 12
    else
      text_x, text_y = target_x, target_y
    end

    local color = annotation.color or TEXT_COLOR
    local fontsize = annotation.fontsize or 12
    local align = annotation.align or "left"
    local anchor = ANNOTATION_ANCHORS[align] or "start"

    buf[#buf + 1] = string.format(
      '   <g class="annotation" data-index="%d">', index)
    if annotation.arrow ~= nil then
      local dx = target_x - text_x
      local dy = target_y - text_y
      local length = math.sqrt(dx * dx + dy * dy)
      if length > 0.0005 then
        local arrow = annotation.arrow
        buf[#buf + 1] = string.format(
          '    <line class="annotation-arrow" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"/>',
          util.fmt(text_x), util.fmt(text_y), util.fmt(target_x),
          util.fmt(target_y), arrow.color or color,
          util.fmt(arrow.linewidth or 1.5))
        local head = arrow.head or 8
        if head > length then head = length end
        if head > 0 then
          local ux, uy = dx / length, dy / length
          local base_x, base_y = target_x - ux * head, target_y - uy * head
          local half = head * 0.5
          local px, py = -uy * half, ux * half
          buf[#buf + 1] = string.format(
            '    <polygon class="annotation-arrow-head" points="%s,%s %s,%s %s,%s" fill="%s"/>',
            util.fmt(target_x), util.fmt(target_y),
            util.fmt(base_x + px), util.fmt(base_y + py),
            util.fmt(base_x - px), util.fmt(base_y - py),
            arrow.color or color)
        end
      end
    end
    buf[#buf + 1] = string.format(
      '    <text class="annotation-text" x="%s" y="%s" font-size="%s" fill="%s" text-anchor="%s" data-align="%s">%s</text>',
      util.fmt(text_x), util.fmt(text_y), util.fmt(fontsize), color, anchor,
      align, util.escape_xml(annotation.text))
    buf[#buf + 1] = '   </g>'
  end
  buf[#buf + 1] = '  </g>'
end

local function render_title(figure, geom, buf)
  if figure._title == nil then return end
  buf[#buf + 1] = string.format(
    '  <text class="title" x="%s" y="30" font-size="18" fill="%s" text-anchor="middle">%s</text>',
    util.fmt(geom.width / 2), TEXT_COLOR, util.escape_xml(figure._title))
end

local function clamp(value, minimum, maximum)
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

-- Number of UTF-8 characters, used only for approximate text metrics.
local function display_chars(text)
  local count = 0
  for index = 1, #text do
    local byte = text:byte(index)
    if byte < 128 or byte >= 192 then
      count = count + 1
    end
  end
  return count
end

local function text_box(x, baseline, text, fontsize, anchor)
  local width = display_chars(text) * fontsize * 0.56
  local height = fontsize * 1.15
  local left = x
  if anchor == "middle" then
    left = x - width / 2
  elseif anchor == "end" then
    left = x - width
  end
  return {
    x = left,
    y = baseline - fontsize * 0.85,
    width = width,
    height = height,
  }
end

local function overlap_area(first, second)
  local left = math.max(first.x, second.x)
  local right = math.min(first.x + first.width, second.x + second.width)
  if right <= left then return 0 end
  local top = math.max(first.y, second.y)
  local bottom = math.min(first.y + first.height, second.y + second.height)
  if bottom <= top then return 0 end
  return (right - left) * (bottom - top)
end

local function point_in_box(x, y, box)
  return x >= box.x and x <= box.x + box.width and
    y >= box.y and y <= box.y + box.height
end

local function corners_inside(box, geom, margin)
  local limit = geom.radius - margin
  local xs = { box.x, box.x + box.width }
  local ys = { box.y, box.y + box.height }
  for _, x in ipairs(xs) do
    for _, y in ipairs(ys) do
      local dx, dy = x - geom.cx, y - geom.cy
      if dx * dx + dy * dy > limit * limit then
        return false
      end
    end
  end
  return true
end

local function legend_entries(figure)
  local entries = {}
  for _, series in ipairs(figure._polar.series) do
    local label = series.style.label
    if label ~= nil and label ~= "" then
      entries[#entries + 1] = {
        kind = series.kind,
        color = series.style.color,
        label = label,
      }
    end
  end
  return entries
end

local function legend_dimensions(figure, geom, entries)
  local max_chars = 0
  for _, entry in ipairs(entries) do
    local chars = display_chars(entry.label)
    if chars > max_chars then max_chars = chars end
  end

  local opts = figure._legend_opts or {
    loc = "upper right", frame = true, ncol = 1,
  }
  local ncol = math.max(1, math.min(opts.ncol or 1, #entries))
  local rows = math.ceil(#entries / ncol)
  local available = math.max(40, geom.radius * 2 - 8)
  local col_width = math.max(60, 52 + max_chars * 6.5)
  col_width = math.min(col_width,
    math.floor((available - (ncol - 1) * 8) / ncol))
  col_width = math.max(40, col_width)
  local box_width = col_width * ncol + (ncol - 1) * 8
  local max_width = math.max(40, geom.width - 16)
  if box_width > max_width then
    box_width = max_width
    col_width = math.max(30,
      math.floor((box_width - (ncol - 1) * 8) / ncol))
  end
  local title_height = opts.title and 20 or 0
  local box_height = 12 + title_height + rows * 20
  return {
    opts = opts,
    ncol = ncol,
    rows = rows,
    col_width = col_width,
    title_height = title_height,
    width = box_width,
    height = box_height,
  }
end

local LOC_ANGLES = {
  ["upper right"] = math.pi / 4,
  ["upper left"] = 3 * math.pi / 4,
  ["lower left"] = 5 * math.pi / 4,
  ["lower right"] = 7 * math.pi / 4,
}

-- Estimate the boxes occupied by theta and radius tick labels.  The legend
-- planner keeps its frame out of these boxes, so a polar legend never covers
-- an angular label even when the requested corner points at one.
local function tick_boxes(figure, cfg, geom)
  local state = figure._polar
  local theta_boxes, radius_boxes = {}, {}
  for index, angle in ipairs(cfg.theta_angles) do
    local display = state.theta_zero + state.theta_direction * angle
    local cosine = math.cos(display)
    local x = geom.cx + (geom.radius + 16) * cosine
    local y = geom.cy - (geom.radius + 16) * math.sin(display) + 4
    local anchor = "middle"
    if cosine > 0.25 then
      anchor = "start"
    elseif cosine < -0.25 then
      anchor = "end"
    end
    theta_boxes[index] = text_box(x, y, cfg.theta_labels[index], 11, anchor)
  end
  for index, value in ipairs(cfg.rticks) do
    local y = geom.cy - geom.radius * value / cfg.rmax + 4
    radius_boxes[index] = text_box(geom.cx + 6, y, cfg.rlabels[index], 10,
      "start")
  end
  return theta_boxes, radius_boxes
end

local function legend_plan(figure, cfg, geom)
  if not figure._legend_requested then return nil end
  local entries = legend_entries(figure)
  if #entries == 0 then return nil end
  local dims = legend_dimensions(figure, geom, entries)
  local width, height = dims.width, dims.height
  local opts = dims.opts
  local theta_boxes, radius_boxes = tick_boxes(figure, cfg, geom)
  local title_box = nil
  if figure._title ~= nil then
    local char_count = display_chars(figure._title)
    title_box = {
      x = geom.cx - char_count * 4.7,
      y = 12,
      width = char_count * 9.4,
      height = 26,
    }
  end

  local data_points = {}
  for _, series in ipairs(figure._polar.series) do
    for index = 1, #series.theta do
      local x, y = M.point(figure, cfg, geom, series.theta[index],
        series.r[index])
      data_points[#data_points + 1] = { x, y }
    end
  end

  local candidates = {}
  local function add(x, y)
    if x < 2 or y < 2 or x + width > geom.width - 2 or
        y + height > geom.height - 2 then
      return
    end
    local box = { x = x, y = y, width = width, height = height }
    box.inside = corners_inside(box, geom, 4)
    candidates[#candidates + 1] = box
  end

  -- Prefer a frame that is fully inside the polar circle: angular labels are
  -- drawn outside the circle, so such a frame cannot cover them.  The box is
  -- placed tangent to the circle in each of the eight compass directions and
  -- the scoring step picks the direction closest to the requested location.
  local half_diagonal = math.sqrt(width * width + height * height) / 2
  local tangent_distance = geom.radius - 6 - half_diagonal
  if tangent_distance > 0 then
    local angles = {
      math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4,
      0, math.pi / 2, math.pi, 3 * math.pi / 2,
    }
    for _, angle in ipairs(angles) do
      add(geom.cx + tangent_distance * math.cos(angle) - width / 2,
        geom.cy - tangent_distance * math.sin(angle) - height / 2)
    end
  end

  -- Canvas corners sit outside the polar circle, where they cover neither the
  -- series nor the angular labels around the frame.  They are often the
  -- cleanest home for a legend on a square-ish canvas.
  local top_y = clamp(geom.cy - geom.radius - 24 - height, 2,
    geom.height - height - 2)
  local bottom_y = clamp(geom.cy + geom.radius + 24, 2,
    geom.height - height - 2)
  add(4, top_y)
  add(geom.width - width - 4, top_y)
  add(4, bottom_y)
  add(geom.width - width - 4, bottom_y)

  -- Fallback positions: the old corner boxes plus the canvas margins.  These
  -- matter when the legend is too large to fit inside the circle.
  local left, top = geom.cx - geom.radius, geom.cy - geom.radius
  local available = geom.radius * 2
  add(left + 8, top + 8)
  add(left + 8, top + available - height - 8)
  add(left + available - width - 8, top + 8)
  add(left + available - width - 8, top + available - height - 8)
  add(geom.cx - width / 2, math.max(4, top - 24 - height))
  add(geom.cx - width / 2, math.min(geom.height - height - 4,
    top + available + 24))
  add(geom.cx + geom.radius + 36, geom.cy - height / 2)
  add(geom.cx - geom.radius - 36 - width, geom.cy - height / 2)
  add(4, 4)
  add(geom.width - width - 4, 4)
  add(4, geom.height - height - 4)
  add(geom.width - width - 4, geom.height - height - 4)

  local target_angle = LOC_ANGLES[opts.loc]
  local target_x, target_y
  if opts.loc == "best" then
    target_x, target_y = geom.cx, geom.cy - geom.radius * 0.45
  else
    target_angle = target_angle or LOC_ANGLES["upper right"]
    target_x = geom.cx + geom.radius * 0.9 * math.cos(target_angle)
    target_y = geom.cy - geom.radius * 0.9 * math.sin(target_angle)
  end

  local function score(box)
    local penalty = 0
    local label_overlap = 0
    for _, tick in ipairs(theta_boxes) do
      label_overlap = label_overlap + overlap_area(box, tick)
    end
    for _, tick in ipairs(radius_boxes) do
      label_overlap = label_overlap + overlap_area(box, tick)
    end
    if title_box ~= nil then
      label_overlap = label_overlap + overlap_area(box, title_box)
    end
    penalty = penalty + label_overlap * 10000

    local outside_samples = 0
    for _, fx in ipairs({ 0, 0.5, 1 }) do
      for _, fy in ipairs({ 0, 0.5, 1 }) do
        local dx = box.x + box.width * fx - geom.cx
        local dy = box.y + box.height * fy - geom.cy
        if dx * dx + dy * dy > geom.radius * geom.radius then
          outside_samples = outside_samples + 1
        end
      end
    end
    penalty = penalty + outside_samples * 4

    for _, point in ipairs(data_points) do
      if point_in_box(point[1], point[2], box) then
        penalty = penalty + 25
      end
    end

    local center_x = box.x + box.width / 2
    local center_y = box.y + box.height / 2
    local dx, dy = center_x - target_x, center_y - target_y
    penalty = penalty + math.sqrt(dx * dx + dy * dy)
    return penalty, label_overlap
  end

  local best, best_score, best_overlap = nil, nil, nil
  for _, box in ipairs(candidates) do
    local value, label_overlap = score(box)
    if best_score == nil or value < best_score then
      best, best_score, best_overlap = box, value, label_overlap
    end
  end

  -- Large legends can leave every coarse candidate touching a label.  Fall
  -- back to a bounded grid search for a label-free position in that case.
  if best_overlap ~= nil and best_overlap > 0 then
    for y = 4, math.max(4, geom.height - height - 4), 10 do
      for x = 4, math.max(4, geom.width - width - 4), 10 do
        local box = { x = x, y = y, width = width, height = height }
        local value, label_overlap = score(box)
        if label_overlap == 0 and
            (best_score == nil or value < best_score) then
          box.inside = corners_inside(box, geom, 4)
          best, best_score, best_overlap = box, value, label_overlap
        end
      end
    end
  end

  if best == nil then
    -- The canvas is smaller than the legend; clamp to the top-left.
    best = { x = 4, y = 4, width = width, height = height, inside = false }
  end

  return {
    x = best.x,
    y = best.y,
    width = width,
    height = height,
    entries = entries,
    ncol = dims.ncol,
    rows = dims.rows,
    col_width = dims.col_width,
    title_height = dims.title_height,
    opts = opts,
    loc = opts.loc or "upper right",
    placement = best.inside and "inside" or "outside",
  }
end

local function polar_swatch(kind, color, x, y, buf)
  if kind == "scatter" then
    buf[#buf + 1] = string.format(
      '   <circle cx="%s" cy="%s" r="4" fill="%s"/>',
      util.fmt(x + 10), util.fmt(y), color)
  elseif kind == "bar" then
    buf[#buf + 1] = string.format(
      '   <rect x="%s" y="%s" width="20" height="9" rx="1" fill="%s"/>',
      util.fmt(x), util.fmt(y - 4), color)
  elseif kind == "errorbar" then
    buf[#buf + 1] = string.format(
      '   <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2" stroke-linecap="round"/>',
      util.fmt(x), util.fmt(y), util.fmt(x + 20), util.fmt(y), color)
    buf[#buf + 1] = string.format(
      '   <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
      util.fmt(x + 10), util.fmt(y - 3), util.fmt(x + 10), util.fmt(y + 3),
      color)
  else
    buf[#buf + 1] = string.format(
      '   <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2.5" stroke-linecap="round"/>',
      util.fmt(x), util.fmt(y), util.fmt(x + 20), util.fmt(y), color)
  end
end

local function render_legend(figure, cfg, geom, buf)
  local plan = legend_plan(figure, cfg, geom)
  if plan == nil then return end
  local x, y = plan.x, plan.y
  local opts = plan.opts

  buf[#buf + 1] = string.format(
    '  <g class="polar-legend" data-loc="%s" data-placement="%s" data-x="%s" data-y="%s" data-width="%s" data-height="%s">',
    util.escape_xml(plan.loc), plan.placement, util.fmt(x), util.fmt(y),
    util.fmt(plan.width), util.fmt(plan.height))
  if opts.frame ~= false then
    buf[#buf + 1] = string.format(
      '   <rect class="legend-frame" x="%s" y="%s" width="%s" height="%s" rx="3" fill="#ffffff" fill-opacity="0.92" stroke="#bbbbbb" stroke-width="1"/>',
      util.fmt(x), util.fmt(y), util.fmt(plan.width), util.fmt(plan.height))
  end
  if opts.title then
    buf[#buf + 1] = string.format(
      '   <text class="legend-title" x="%s" y="%s" font-size="11" font-weight="bold" fill="%s">%s</text>',
      util.fmt(x + 8), util.fmt(y + 14), TEXT_COLOR,
      util.escape_xml(opts.title))
  end
  for index, entry in ipairs(plan.entries) do
    local column = math.floor((index - 1) / plan.rows) + 1
    local row = (index - 1) % plan.rows + 1
    local entry_x = x + 8 + (column - 1) * (plan.col_width + 8)
    local entry_y = y + 12 + plan.title_height + (row - 1) * 20
    polar_swatch(entry.kind, entry.color, entry_x, entry_y, buf)
    buf[#buf + 1] = string.format(
      '   <text x="%s" y="%s" font-size="11" fill="%s">%s</text>',
      util.fmt(entry_x + 28), util.fmt(entry_y + 4), TEXT_COLOR,
      util.escape_xml(entry.label))
  end
  buf[#buf + 1] = '  </g>'
end

function M.to_svg(figure)
  if figure._pie ~= nil then
    fail("cannot combine pie and polar plots in one figure")
  end
  if #figure._series > 0 then
    fail("cannot mix cartesian and polar series in one figure")
  end
  if #figure._annotations > 0 then
    fail("cannot mix cartesian annotations and polar series in one figure")
  end

  local cfg = M.resolve(figure)
  local geom = layout(figure)
  local state = figure._polar
  local direction = state.theta_direction < 0 and "clockwise" or
    "counterclockwise"

  local buf = {}
  local function add(line) buf[#buf + 1] = line end

  add('<?xml version="1.0" encoding="UTF-8"?>')
  add(string.format(
    '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" version="1.1" role="img" aria-label="%s" data-dpi="%s" data-polar="true" data-theta-unit="radians" data-theta-zero="%s" data-theta-direction="%s">',
    util.fmt(figure.width), util.fmt(figure.height),
    util.fmt(figure.width), util.fmt(figure.height),
    util.escape_xml(figure._aria_label or figure._title or
      "luaplotlib polar figure"),
    util.fmt(figure.dpi), util.fmt(state.theta_zero), direction))
  add(' <title>' .. util.escape_xml(figure._title or
    "luaplotlib polar figure") .. '</title>')
  add(' <desc>Generated by luaplotlib, a pure-Lua SVG plotting library.</desc>')
  add(string.format(
    ' <rect class="background" x="0" y="0" width="%s" height="%s" fill="%s"/>',
    util.fmt(figure.width), util.fmt(figure.height),
    figure._facecolor or "#ffffff"))

  local clip_id = "luaplotlib-polar-clip-" .. tostring(figure):gsub("%W", "")
  add(' <defs>')
  add(string.format(
    '  <clipPath id="%s"><circle cx="%s" cy="%s" r="%s"/></clipPath>',
    clip_id, util.fmt(geom.cx), util.fmt(geom.cy), util.fmt(geom.radius)))
  add(' </defs>')
  add(' <g class="figure" font-family="' .. FONT_FAMILY ..
    '" font-size="12" fill="' .. TEXT_COLOR .. '">')
  render_title(figure, geom, buf)
  add(string.format(
    '  <g class="polar" data-cx="%s" data-cy="%s" data-radius="%s" data-rmax="%s">',
    util.fmt(geom.cx), util.fmt(geom.cy), util.fmt(geom.radius),
    util.fmt(cfg.rmax)))
  render_grid(figure, cfg, geom, buf)
  add(string.format(
    '  <circle class="polar-frame" cx="%s" cy="%s" r="%s" fill="none" stroke="%s" stroke-width="1"/>',
    util.fmt(geom.cx), util.fmt(geom.cy), util.fmt(geom.radius), AXIS_COLOR))
  render_theta_labels(figure, cfg, geom, buf)
  render_radius_labels(cfg, geom, buf)
  add('  <g class="series-layer" clip-path="url(#' .. clip_id .. ')">')
  for _, series in ipairs(state.series) do
    if series.kind == "line" then
      render_line(series, figure, cfg, geom, buf)
    elseif series.kind == "scatter" then
      render_scatter(series, figure, cfg, geom, buf)
    elseif series.kind == "bar" then
      render_bar(series, figure, cfg, geom, buf)
    elseif series.kind == "errorbar" then
      render_errorbar(series, figure, cfg, geom, buf)
    end
  end
  add('  </g>')
  render_annotations(figure, cfg, geom, buf)
  add('  </g>')
  render_legend(figure, cfg, geom, buf)
  add(' </g>')
  add('</svg>')
  return table.concat(buf, "\n") .. "\n"
end

local function copy_array(source)
  local result = {}
  for index = 1, #source do result[index] = source[index] end
  return result
end

local function copy_style(style)
  return {
    color = style.color,
    edgecolor = style.edgecolor,
    alpha = style.alpha,
    label = style.label,
    linewidth = style.linewidth,
    linestyle = style.linestyle,
    marker = style.marker,
    markersize = style.markersize,
    radius = style.radius,
    capsize = style.capsize,
    elinewidth = style.elinewidth,
    ecolor = style.ecolor,
  }
end

local function copy_annotation(annotation)
  local copy = {
    kind = "annotation",
    text = annotation.text,
    theta = annotation.theta,
    r = annotation.r,
    color = annotation.color,
    fontsize = annotation.fontsize,
    align = annotation.align,
    style = {
      color = annotation.color,
      fontsize = annotation.fontsize,
      align = annotation.align,
    },
  }
  if annotation.xytext ~= nil then
    local theta, r = annotation.xytext[1], annotation.xytext[2]
    copy.xytext = { theta, r, theta = theta, r = r }
  end
  if annotation.arrow ~= nil then
    copy.arrow = {
      enabled = true,
      color = annotation.arrow.color,
      linewidth = annotation.arrow.linewidth,
      head = annotation.arrow.head,
    }
  end
  return copy
end

-- Renderer-agnostic polar scene.  Grid values are included so a non-SVG
-- backend can draw the same axes without reimplementing the "nice" tick rules.
function M.to_scene(figure)
  if figure._pie ~= nil then
    fail("cannot combine pie and polar plots in one figure")
  end
  if #figure._series > 0 then
    fail("cannot mix cartesian and polar series in one figure")
  end
  if #figure._annotations > 0 then
    fail("cannot mix cartesian annotations and polar series in one figure")
  end

  local cfg = M.resolve(figure)
  local state = figure._polar
  local scene = {
    version = 1,
    type = "luaplotlib",
    orientation = "polar",
    width = figure.width,
    height = figure.height,
    dpi = figure.dpi,
    title = figure._title,
    grid = true,
    legend = figure._legend_requested and true or false,
    series = {},
    annotations = {},
    polar = {
      theta_unit = "radians",
      theta_zero = state.theta_zero,
      theta_direction = state.theta_direction < 0 and "clockwise" or
        "counterclockwise",
      rmin = 0,
      rmax = cfg.rmax,
      theta_ticks = {},
      r_ticks = {},
      series = {},
    },
  }

  for index, angle in ipairs(cfg.theta_angles) do
    scene.polar.theta_ticks[index] = {
      value = angle,
      degrees = angle * 180 / math.pi,
      label = cfg.theta_labels[index],
    }
  end
  for index, value in ipairs(cfg.rticks) do
    scene.polar.r_ticks[index] = {
      value = value,
      fraction = value / cfg.rmax,
      label = cfg.rlabels[index],
    }
  end

  local entries = legend_entries(figure)
  if figure._legend_requested and #entries > 0 then
    local opts = figure._legend_opts or {
      loc = "upper right", frame = true, ncol = 1,
    }
    local exported = {
      loc = opts.loc or "upper right",
      frame = opts.frame ~= false,
      title = opts.title,
      ncol = opts.ncol or 1,
      entries = {},
    }
    for index, entry in ipairs(entries) do
      exported.entries[index] = {
        kind = entry.kind,
        label = entry.label,
        color = entry.color,
      }
    end
    scene.polar.legend = exported
  end

  for _, series in ipairs(state.series) do
    local copy = {
      kind = series.kind,
      theta = copy_array(series.theta),
      r = copy_array(series.r),
      style = copy_style(series.style),
    }
    if series.kind == "scatter" then
      if series.style.radii then
        copy.radii = copy_array(series.style.radii)
      end
      if series.style.colors then
        copy.colors = copy_array(series.style.colors)
      end
    elseif series.kind == "bar" then
      copy.widths = copy_array(series.widths)
      if series.colors then copy.colors = copy_array(series.colors) end
    elseif series.kind == "errorbar" then
      copy.rerr = copy_array(series.rerr)
      if series.thetaerr ~= nil then
        copy.thetaerr = copy_array(series.thetaerr)
      end
    end
    scene.polar.series[#scene.polar.series + 1] = copy
  end

  for _, annotation in ipairs(state.annotations or {}) do
    scene.annotations[#scene.annotations + 1] = copy_annotation(annotation)
  end

  return scene
end

return M
