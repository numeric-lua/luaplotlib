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

local function fail(message)
  util.fail(message, 3)
end

-- Fresh polar state, attached to a Figure as `_polar`.
function M.new_state()
  return {
    series = {},
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

local function polar_swatch(kind, color, x, y, buf)
  if kind == "scatter" then
    buf[#buf + 1] = string.format(
      '   <circle cx="%s" cy="%s" r="4" fill="%s"/>',
      util.fmt(x + 10), util.fmt(y), color)
  elseif kind == "bar" then
    buf[#buf + 1] = string.format(
      '   <rect x="%s" y="%s" width="20" height="9" rx="1" fill="%s"/>',
      util.fmt(x), util.fmt(y - 4), color)
  else
    buf[#buf + 1] = string.format(
      '   <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2.5" stroke-linecap="round"/>',
      util.fmt(x), util.fmt(y), util.fmt(x + 20), util.fmt(y), color)
  end
end

local function render_legend(figure, geom, buf)
  if not figure._legend_requested then return end

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
  if #entries == 0 then return end

  local max_chars = 0
  for _, entry in ipairs(entries) do
    if #entry.label > max_chars then max_chars = #entry.label end
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
  local box_width = col_width * ncol + (ncol - 1) * 8
  local title_height = opts.title and 20 or 0
  local box_height = 12 + title_height + rows * 20

  local left = geom.cx - geom.radius
  local top = geom.cy - geom.radius
  local x, y
  if opts.loc == "upper left" then
    x, y = left + 8, top + 8
  elseif opts.loc == "lower left" then
    x, y = left + 8, top + available - box_height - 8
  elseif opts.loc == "lower right" then
    x, y = left + available - box_width - 8,
      top + available - box_height - 8
  else
    x, y = left + available - box_width - 8, top + 8
  end
  x = clamp(x, left + 4, math.max(left + 4, left + available - box_width - 4))
  y = clamp(y, top + 4, math.max(top + 4, top + available - box_height - 4))

  buf[#buf + 1] = '  <g class="polar-legend">'
  if opts.frame ~= false then
    buf[#buf + 1] = string.format(
      '   <rect class="legend-frame" x="%s" y="%s" width="%s" height="%s" rx="3" fill="#ffffff" fill-opacity="0.92" stroke="#bbbbbb" stroke-width="1"/>',
      util.fmt(x), util.fmt(y), util.fmt(box_width), util.fmt(box_height))
  end
  if opts.title then
    buf[#buf + 1] = string.format(
      '   <text class="legend-title" x="%s" y="%s" font-size="11" font-weight="bold" fill="%s">%s</text>',
      util.fmt(x + 8), util.fmt(y + 14), TEXT_COLOR,
      util.escape_xml(opts.title))
  end
  for index, entry in ipairs(entries) do
    local column = math.floor((index - 1) / rows) + 1
    local row = (index - 1) % rows + 1
    local entry_x = x + 8 + (column - 1) * (col_width + 8)
    local entry_y = y + 12 + title_height + (row - 1) * 20
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
    end
  end
  add('  </g>')
  add('  </g>')
  render_legend(figure, geom, buf)
  add(' </g>')
  add('</svg>')
  return table.concat(buf, "\n") .. "\n"
end

return M
