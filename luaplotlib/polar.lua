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

local colors = require("luaplotlib.colors")
local markers = require("luaplotlib.markers")
local text = require("luaplotlib.text")
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
    heatmaps = {},
    contours = {},
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

-- Annotation targets are data positions and must stay inside the radial
-- frame.  Their text positions are layout coordinates, so `xytext` does not
-- extend the radial limit; the renderer keeps that text on the canvas.
local function annotation_radius(figure)
  local maximum = 0
  for _, annotation in ipairs(figure._polar.annotations or {}) do
    local value = math.abs(annotation.r)
    if value > maximum then maximum = value end
  end
  return maximum
end

-- The effective outer radius of a heatmap.  An explicit `rmax` wins; a
-- configured polar `rmax` fills the frame when the caller did not pass one;
-- otherwise one radial band per matrix row is the implicit extent.
local function heatmap_rmax(state, heatmap)
  if heatmap.rmax ~= nil then return heatmap.rmax end
  if state.rmax ~= nil then return state.rmax end
  return heatmap.rows
end

-- Contours follow the same implicit extent rules as the heatmap they overlay.
local function contour_rmax(state, contour)
  if contour.rmax ~= nil then return contour.rmax end
  if state.rmax ~= nil then return state.rmax end
  return contour.rows
end

-- Radial extent that projected fields (heatmaps and contours) would like the
-- automatic limit to cover.
local function field_radius(figure)
  local maximum = 0
  for _, heatmap in ipairs(figure._polar.heatmaps or {}) do
    local value = heatmap_rmax(figure._polar, heatmap)
    if value > maximum then maximum = value end
  end
  for _, contour in ipairs(figure._polar.contours or {}) do
    local value = contour_rmax(figure._polar, contour)
    if value > maximum then maximum = value end
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

  local series_radius = observed_radius(figure)
  local target_radius = annotation_radius(figure)
  local heat_radius = field_radius(figure)
  local observed = math.max(series_radius, target_radius, heat_radius)
  local wanted = observed
  if state.rgrids ~= nil then
    for _, value in ipairs(state.rgrids) do
      if value > wanted then wanted = value end
    end
  end
  local rmax = state.rmax
  if rmax == nil then
    if heat_radius > 0 and wanted <= heat_radius * (1 + 1e-9) then
      -- A projected field defines a complete radial extent.  Without an
      -- explicit limit it fills the frame instead of leaving an outer gap.
      rmax = heat_radius
    else
      if wanted <= 0 then wanted = 1 end
      local target = wanted * 1.05
      local step = ticks.nice_step(target / 5)
      rmax = math.ceil(target / step - 1e-9) * step
    end
  else
    if series_radius > rmax * (1 + 1e-9) then
      fail(string.format(
        "polar r value %s exceeds the configured rmax %s",
        util.fmt_tick(series_radius), util.fmt_tick(rmax)))
    end
    if target_radius > rmax * (1 + 1e-9) then
      fail(string.format(
        "polar annotate r %s exceeds the configured rmax %s",
        util.fmt_tick(target_radius), util.fmt_tick(rmax)))
    end
    if heat_radius > rmax * (1 + 1e-9) then
      local heat_extent = 0
      for _, heatmap in ipairs(state.heatmaps) do
        local value = heatmap_rmax(state, heatmap)
        if value > heat_extent then heat_extent = value end
      end
      if heat_extent > rmax * (1 + 1e-9) then
        fail(string.format(
          "polar heatmap rmax %s exceeds the configured rmax %s",
          util.fmt_tick(heat_extent), util.fmt_tick(rmax)))
      end
      local contour_extent = 0
      for _, contour in ipairs(state.contours or {}) do
        local value = contour_rmax(state, contour)
        if value > contour_extent then contour_extent = value end
      end
      if contour_extent > rmax * (1 + 1e-9) then
        fail(string.format(
          "polar contour rmax %s exceeds the configured rmax %s",
          util.fmt_tick(contour_extent), util.fmt_tick(rmax)))
      end
    end
  end
  if not (rmax > 0) then
    fail("polar rmax must be positive")
  end

  for index, heatmap in ipairs(state.heatmaps or {}) do
    local outer = heatmap_rmax(state, heatmap)
    if heatmap.rmin >= outer - 1e-12 then
      fail(string.format(
        "polar heatmap %d rmin %s must be less than its rmax %s",
        index, util.fmt_tick(heatmap.rmin), util.fmt_tick(outer)))
    end
  end

  for index, contour in ipairs(state.contours or {}) do
    local outer = contour_rmax(state, contour)
    if contour.rmin >= outer - 1e-12 then
      fail(string.format(
        "polar contour %d rmin %s must be less than its rmax %s",
        index, util.fmt_tick(contour.rmin), util.fmt_tick(outer)))
    end
  end

  -- One vertical colorbar can annotate one heatmap per polar figure.  The
  -- layout and legend planner both reserve its canvas column.
  local colorbars = 0
  for _, heatmap in ipairs(state.heatmaps or {}) do
    if heatmap.colorbar then colorbars = colorbars + 1 end
  end
  if colorbars > 1 then
    fail("only one polar colorbar per figure is supported")
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

-- One vertical colorbar can annotate one heatmap per polar figure.
local function colorbar_heatmap(figure)
  local found
  for _, heatmap in ipairs(figure._polar.heatmaps or {}) do
    if heatmap.colorbar then
      if found ~= nil then
        fail("only one polar colorbar per figure is supported")
      end
      found = heatmap
    end
  end
  return found
end

local COLORBAR_WIDTH = 16
local COLORBAR_GAP = 16
local COLORBAR_MARGIN = 68

-- Canvas column reserved for the vertical colorbar and its labels.
local function colorbar_geometry(geom)
  local x = geom.cx + geom.radius + COLORBAR_GAP
  local height = geom.radius * 1.7
  local y = geom.cy - height / 2
  return x, y, COLORBAR_WIDTH, height
end

-- Compact three-significant-digit labels keep the colorbar column narrow and
-- readable; the scene keeps the exact numeric tick values.
local function colorbar_value(value)
  if value == 0 or math.abs(value) < 1e-12 then return "0" end
  local formatted = string.format("%.3g", value)
  return (formatted:gsub("e%+0*", "e"):gsub("e%-0*", "e-"))
end

-- Resolve the labelled colorbar ticks.  Explicit values let callers request
-- "nice" ticks (for example -1.2, -0.6, 0, 0.6, 1.2) instead of an even
-- subdivision of an arbitrary data range.
local function colorbar_ticks(heatmap)
  if heatmap.colorbar_tick_values ~= nil then
    return heatmap.colorbar_tick_values
  end
  local count = heatmap.colorbar_ticks or 3
  local values = {}
  for index = 1, count do
    values[index] = heatmap.vmin +
      (heatmap.vmax - heatmap.vmin) * (index - 1) / (count - 1)
  end
  return values
end

local function layout(figure)
  local width, height = figure.width, figure.height
  local top = 22
  if figure._title ~= nil then top = 52 end
  local bottom = 28
  local left, right = 44, 44
  if colorbar_heatmap(figure) ~= nil then
    right = right + COLORBAR_MARGIN
  end
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

-- Arrow glyphs for polar vector fields.  `u` is the component toward
-- increasing data theta and `v` points outward along the radius.  The local
-- basis is orthonormal, so the screen-space direction is just the rotated
-- component pair.  Glyph lengths use SVG user units to stay legible when the
-- radial limit changes, and large fields are decimated before rendering.
local QUIVER_AUTO_LENGTH = 18
local QUIVER_PIVOTS = { tail = 0, middle = 0.5, tip = 1 }

local function quiver_magnitude(series, index)
  local u, v = series.u[index], series.v[index]
  local magnitude = math.sqrt(u * u + v * v)
  if series.normalize and magnitude > 0 then return 1 end
  return magnitude
end

local function quiver_scale(series)
  if series.scale ~= nil then
    return series.scale, false
  end
  local maximum = 0
  for index = 1, #series.theta do
    local magnitude = quiver_magnitude(series, index)
    if magnitude > maximum then maximum = magnitude end
  end
  if maximum <= 0 then return 1, true end
  return QUIVER_AUTO_LENGTH / maximum, true
end

local function quiver_indices(series)
  local stride = math.max(1,
    math.ceil(#series.theta / series.max_arrows))
  local indices = {}
  for index = 1, #series.theta, stride do
    indices[#indices + 1] = index
  end
  return indices, stride
end

local function quiver_drawn(series, indices)
  local drawn = 0
  for _, index in ipairs(indices) do
    if quiver_magnitude(series, index) > 1e-12 then
      drawn = drawn + 1
    end
  end
  return drawn
end

local function render_quiver(series, figure, cfg, geom, buf)
  local style = series.style
  local scale, automatic = quiver_scale(series)
  local indices, stride = quiver_indices(series)
  local drawn = quiver_drawn(series, indices)
  local direction = figure._polar.theta_direction or 1
  local pivot = QUIVER_PIVOTS[series.pivot] or 0
  local stroke_opacity, fill_opacity = "", ""
  if style.alpha < 1 then
    local alpha = util.fmt(style.alpha)
    stroke_opacity = string.format(' stroke-opacity="%s"', alpha)
    fill_opacity = string.format(' fill-opacity="%s"', alpha)
  end
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', util.escape_xml(style.label))
  end

  buf[#buf + 1] = string.format(
    '  <g class="series series-polar-quiver" data-count="%d" data-drawn="%d" data-stride="%d" data-max-arrows="%d" data-scale="%s" data-scale-mode="%s" data-pivot="%s" data-normalize="%s"%s>',
    #series.theta, drawn, stride, series.max_arrows, util.fmt(scale),
    automatic and "auto" or "explicit", series.pivot,
    series.normalize and "true" or "false", label)

  for _, index in ipairs(indices) do
    local u, v = series.u[index], series.v[index]
    local raw = math.sqrt(u * u + v * v)
    if raw > 1e-12 then
      local magnitude = quiver_magnitude(series, index)
      local theta, r = series.theta[index], series.r[index]
      local display = M.theta_to_display(figure, theta)
      local cosine, sine = math.cos(display), math.sin(display)
      -- Local basis in SVG user space (y grows downward).  Increasing data
      -- theta is counterclockwise unless the figure is configured clockwise.
      local dx = v * cosine - direction * u * sine
      local dy = -v * sine - direction * u * cosine
      local ux, uy = dx / raw, dy / raw
      local length = magnitude * scale
      local x, y = M.point(figure, cfg, geom, theta, r)
      local tail_x = x - ux * length * pivot
      local tail_y = y - uy * length * pivot
      local tip_x = tail_x + ux * length
      local tip_y = tail_y + uy * length
      local head = math.min(style.head or 0, length)
      local neck_x = tip_x - ux * head
      local neck_y = tip_y - uy * head
      local angle = math.deg(math.atan2(dy, dx))

      buf[#buf + 1] = string.format(
        '   <g class="polar-quiver-arrow" data-index="%d" data-magnitude="%s" data-theta="%s" data-r="%s" data-angle="%s">',
        index, util.fmt(magnitude), util.fmt(theta), util.fmt(r),
        util.fmt(angle))
      if style.linewidth > 0 and length - head > 1e-9 then
        buf[#buf + 1] = string.format(
          '    <line class="polar-quiver-shaft" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"%s/>',
          util.fmt(tail_x), util.fmt(tail_y), util.fmt(neck_x),
          util.fmt(neck_y), style.color, util.fmt(style.linewidth),
          stroke_opacity)
      end
      if head > 1e-9 then
        local half = head * 0.45
        local px, py = -uy * half, ux * half
        buf[#buf + 1] = string.format(
          '    <polygon class="polar-quiver-head" points="%s,%s %s,%s %s,%s" fill="%s"%s/>',
          util.fmt(tip_x), util.fmt(tip_y),
          util.fmt(neck_x + px), util.fmt(neck_y + py),
          util.fmt(neck_x - px), util.fmt(neck_y - py),
          style.color, fill_opacity)
      end
      buf[#buf + 1] = '   </g>'
    end
  end
  buf[#buf + 1] = '  </g>'
end

-- Streamlines for polar vector fields.  `u` and `v` are sampled at every
-- (theta, r) grid node in the same local tangential/radial basis as
-- polar_quiver.  Integration happens in the physical plane
-- (x = r*cos(phi), y = r*sin(phi)) so a fixed step stays isotropic even when
-- the angular and radial grid spacings differ.  Seeding is deterministic and
-- both line and point counts are capped so SVG output stays bounded.
local STREAM_WRAP = 2 * math.pi
local STREAM_SEED_ANGULAR = 9
local STREAM_SEED_RADIAL = 5
local STREAM_BINS_COLS = 24
local STREAM_BINS_ROWS = 12
-- A candidate that retraces an earlier line this much is dropped.  The seed
-- bin can be empty while the rest of a closed orbit is already covered.
local STREAM_MAX_OVERLAP = 0.5

local function streamplot_periodic(series)
  return series.theta[#series.theta] - series.theta[1] >=
    STREAM_WRAP - 1e-9
end

local function streamplot_step(series)
  if series.step ~= nil then return series.step, false end
  local span = series.r[#series.r] - series.r[1]
  if span <= 0 then span = series.r[#series.r] end
  return span / 25, true
end

-- Bilinear lookup of (u, v) at a data-space (theta, r) position.  Angles are
-- wrapped into one turn so a full-circle grid is periodic even though its
-- endpoint column duplicates the first ray.  Returns nil outside the grid.
local function stream_sample(series, theta, radial)
  local theta_count = #series.theta
  local radial_count = #series.r
  local theta0, theta1 = series.theta[1], series.theta[theta_count]
  local radial0, radial1 = series.r[1], series.r[radial_count]
  if radial < radial0 - 1e-9 or radial > radial1 + 1e-9 then
    return nil
  end
  theta = theta0 + ((theta - theta0) % STREAM_WRAP)
  if theta > theta1 + 1e-9 then
    return nil
  end

  local column = (theta - theta0) /
    ((theta1 - theta0) / (theta_count - 1))
  local row = (radial - radial0) /
    ((radial1 - radial0) / (radial_count - 1))
  column = math.max(0, math.min(theta_count - 1, column))
  row = math.max(0, math.min(radial_count - 1, row))
  local c0 = math.min(math.floor(column), theta_count - 2)
  local r0 = math.min(math.floor(row), radial_count - 2)
  local cf = column - c0
  local rf = row - r0

  local function at(radial_index, theta_index)
    return series.u[radial_index][theta_index]
  end
  local function blend(a, b, c, d)
    local bottom = a + (b - a) * cf
    local top = c + (d - c) * cf
    return bottom + (top - bottom) * rf
  end
  return blend(at(r0 + 1, c0 + 1), at(r0 + 1, c0 + 2),
      at(r0 + 2, c0 + 1), at(r0 + 2, c0 + 2)),
    blend(series.v[r0 + 1][c0 + 1], series.v[r0 + 1][c0 + 2],
      series.v[r0 + 2][c0 + 1], series.v[r0 + 2][c0 + 2])
end

-- Unit direction in the physical plane.  The local basis is orthonormal, so
-- the component pair rotates directly into (dx, dy); theta_zero and
-- theta_direction change the orientation but not the streamline shape.
local function stream_direction(series, figure, x, y)
  local radial = math.sqrt(x * x + y * y)
  if radial < 1e-12 then return nil end
  local state = figure._polar
  local zero = state and state.theta_zero or 0
  local direction = state and state.theta_direction or 1
  local theta = (math.atan2(y, x) - zero) / direction
  local u, v = stream_sample(series, theta, radial)
  if u == nil then return nil end
  local magnitude = math.sqrt(u * u + v * v)
  if magnitude < 1e-12 then return nil end
  local cosine, sine = x / radial, y / radial
  return (v * cosine - direction * u * sine) / magnitude,
    (v * sine + direction * u * cosine) / magnitude
end

-- One fourth-order Runge-Kutta step.  If an intermediate stage leaves the
-- sampled field, fall back to a first-order step so a line still reaches the
-- boundary instead of stopping half a step early.
local function stream_advance(series, figure, x, y, step)
  local k1x, k1y = stream_direction(series, figure, x, y)
  if k1x == nil then return nil end
  local k2x, k2y = stream_direction(series, figure,
    x + step * 0.5 * k1x, y + step * 0.5 * k1y)
  if k2x == nil then return x + step * k1x, y + step * k1y end
  local k3x, k3y = stream_direction(series, figure,
    x + step * 0.5 * k2x, y + step * 0.5 * k2y)
  if k3x == nil then return x + step * k1x, y + step * k1y end
  local k4x, k4y = stream_direction(series, figure,
    x + step * k3x, y + step * k3y)
  if k4x == nil then return x + step * k1x, y + step * k1y end
  return x + step / 6 * (k1x + 2 * k2x + 2 * k3x + k4x),
    y + step / 6 * (k1y + 2 * k2y + 2 * k3y + k4y)
end

-- Integrate one direction from a seed.  The returned points carry continuous
-- data theta so a full-turn field can wrap across the +/-pi seam without a
-- visual chord; the renderer's trigonometric projection handles any offset.
local function stream_trace(series, figure, seed_theta, seed_radial, step,
    limit, max_steps)
  local state = figure._polar
  local zero = state and state.theta_zero or 0
  local direction = state and state.theta_direction or 1
  local display = M.theta_to_display(figure, seed_theta)
  local x = seed_radial * math.cos(display)
  local y = seed_radial * math.sin(display)
  local seed_x, seed_y = x, y
  local closed = false
  local points = { { theta = seed_theta, r = seed_radial } }
  for _ = 1, max_steps do
    local next_x, next_y = stream_advance(series, figure, x, y, step)
    if next_x == nil then break end
    local radial = math.sqrt(next_x * next_x + next_y * next_y)
    if radial > limit + 1e-9 or radial < 1e-12 then break end
    -- A closed orbit through the seed would otherwise trace the same ring for
    -- the whole step budget.  Stop once the line comes back to its start.
    if #points >= 8 then
      local close_x, close_y = next_x - seed_x, next_y - seed_y
      local tolerance = step * 1.05
      if close_x * close_x + close_y * close_y <
          tolerance * tolerance then
        closed = true
        break
      end
    end
    local current = math.atan2(next_y, next_x)
    while current - display > math.pi do current = current - STREAM_WRAP end
    while current - display < -math.pi do current = current + STREAM_WRAP end
    display = current
    local theta = (current - zero) / direction
    local u, v = stream_sample(series, theta, radial)
    if u == nil or u * u + v * v < 1e-24 then break end
    x, y = next_x, next_y
    points[#points + 1] = { theta = theta, r = radial }
  end
  return points, closed
end

local function stream_canonical_point(figure, point)
  local display = M.theta_to_display(figure, point.theta)
  return point.r * math.cos(display), -point.r * math.sin(display)
end

-- Polyline length in data-radius units.  Theta values are continuous for a
-- wrapped line, so the physical-plane distance needs no seam correction and
-- is unchanged by theta_zero/theta_direction or by the uniform SVG scale.
local function stream_arc_metrics(figure, points)
  local distances = { 0 }
  local total = 0
  local previous_x, previous_y = stream_canonical_point(figure, points[1])
  for index = 2, #points do
    local x, y = stream_canonical_point(figure, points[index])
    local dx, dy = x - previous_x, y - previous_y
    total = total + math.sqrt(dx * dx + dy * dy)
    distances[index] = total
    previous_x, previous_y = x, y
  end
  return distances, total
end

-- One arrow per streamline.  The anchor is selected by arc length rather than
-- by point index, so uneven spacing, a trimmed tail, or a closing segment
-- cannot pull the glyph away from the requested fraction of the line.  The
-- angle comes from canonical screen coordinates and is canvas-independent.
local function stream_arrows(figure, points, distances, total, fraction)
  local arrows = {}
  if #points < 3 or total <= 1e-12 then return arrows end
  fraction = math.max(0, math.min(1, fraction or 0.5))
  local target = total * fraction
  local index, best_delta = nil, nil
  for candidate = 1, #points - 1 do
    local midpoint = (distances[candidate] + distances[candidate + 1]) * 0.5
    local delta = math.abs(midpoint - target)
    if best_delta == nil or delta < best_delta then
      index, best_delta = candidate, delta
    end
  end
  local x1, y1 = stream_canonical_point(figure, points[index])
  local x2, y2 = stream_canonical_point(figure, points[index + 1])
  local dx, dy = x2 - x1, y2 - y1
  if dx * dx + dy * dy < 1e-18 then return arrows end
  arrows[1] = {
    index = index,
    fraction = distances[index] / total,
    theta = points[index].theta,
    r = points[index].r,
    angle = math.deg(math.atan2(dy, dx)),
  }
  return arrows
end

-- Coarse occupancy bins stop nearby seeds from retracing a line the field
-- already covered.  The grid is deterministic, so the same field always
-- produces the same streamlines.  Fractions are quantized before binning so
-- tiny integration drift cannot push a line into the neighbouring bin.
local function stream_quantize(value)
  return math.floor(value * 1000000 + 0.5) / 1000000
end

local function stream_bin(series, theta, radial)
  local theta0 = series.theta[1]
  local theta_span = series.theta[#series.theta] - theta0
  local radial0 = series.r[1]
  local radial_span = series.r[#series.r] - radial0
  local theta_fraction = ((theta - theta0) % STREAM_WRAP) / theta_span
  if streamplot_periodic(series) then
    theta_fraction = theta_fraction % 1
  else
    theta_fraction = math.max(0, math.min(1, theta_fraction))
  end
  local radial_fraction = 0
  if radial_span > 0 then
    radial_fraction = (radial - radial0) / radial_span
  end
  radial_fraction = math.max(0, math.min(1, radial_fraction))
  theta_fraction = math.min(1 - 1e-6, stream_quantize(theta_fraction))
  radial_fraction = math.min(1 - 1e-6, stream_quantize(radial_fraction))
  local column = math.floor(theta_fraction * STREAM_BINS_COLS) + 1
  local row = math.floor(radial_fraction * STREAM_BINS_ROWS) + 1
  return row * STREAM_BINS_COLS + column
end

-- Fraction of a candidate line that falls in already-covered bins.  Closed
-- orbits can be re-seeded at a new phase whose own bin is empty; without this
-- check the whole loop would be drawn again a fraction of a turn later.
local function stream_overlap(series, points, occupied)
  local covered = 0
  for _, point in ipairs(points) do
    if occupied[stream_bin(series, point.theta, point.r)] then
      covered = covered + 1
    end
  end
  return covered / #points
end

local function build_streamplot(series, figure, cfg)
  local periodic = streamplot_periodic(series)
  local step, automatic = streamplot_step(series)
  local theta0 = series.theta[1]
  local theta_span = series.theta[#series.theta] - theta0
  local radial0 = series.r[1]
  local radial1 = series.r[#series.r]
  local limit = math.min(cfg.rmax, radial1)
  local seed_columns = math.max(2, math.ceil(
    STREAM_SEED_ANGULAR * series.density * theta_span / STREAM_WRAP))
  local seed_rows = math.max(2, math.ceil(
    STREAM_SEED_RADIAL * series.density))
  local occupied = {}
  local lines = {}
  local point_count = 0
  local closed_count = 0
  local truncated = false

  for row = 1, seed_rows do
    if #lines >= series.max_lines or point_count >= series.max_points then
      truncated = true
      break
    end
    local radial = radial0 + (limit - radial0) * row / (seed_rows + 1)
    for column = 1, seed_columns do
      if #lines >= series.max_lines or point_count >= series.max_points then
        truncated = true
        break
      end
      local stagger = (row % 2 == 0) and 0.25 or -0.25
      local fraction = (column - 0.5 + stagger) / seed_columns
      if periodic then
        fraction = fraction % 1
      else
        fraction = math.max(0, math.min(1, fraction))
      end
      local seed_theta = theta0 + theta_span * fraction
      local u, v = stream_sample(series, seed_theta, radial)
      if u ~= nil and u * u + v * v > 1e-24 then
        local bin = stream_bin(series, seed_theta, radial)
        if not occupied[bin] then
          local forward, closed = stream_trace(series, figure, seed_theta,
            radial, step, limit, series.max_steps)
          local combined = {}
          if closed then
            -- A closed orbit only needs one direction; joining the endpoint
            -- back to the seed closes the ring without drawing it twice.
            for index = 1, #forward do
              combined[index] = forward[index]
            end
            combined[#combined + 1] = {
              theta = seed_theta,
              r = radial,
            }
          else
            local backward = stream_trace(series, figure, seed_theta,
              radial, -step, limit, series.max_steps)
            for index = #backward, 2, -1 do
              combined[#combined + 1] = backward[index]
            end
            for index = 1, #forward do
              combined[#combined + 1] = forward[index]
            end
          end
          local remaining = series.max_points - point_count
          local line_closed = closed
          if #combined > remaining then
            local trimmed = {}
            for index = 1, remaining do
              trimmed[index] = combined[index]
            end
            combined = trimmed
            line_closed = false
            truncated = true
          end
          if #combined >= 3 and
              stream_overlap(series, combined, occupied) <=
              STREAM_MAX_OVERLAP then
            for _, point in ipairs(combined) do
              occupied[stream_bin(series, point.theta, point.r)] = true
            end
            local distances, arc_length = stream_arc_metrics(figure, combined)
            combined.arc_length = arc_length
            combined.seed_theta = seed_theta
            combined.seed_r = radial
            combined.closed = line_closed
            if series.arrows and series.style.head > 0 then
              combined.arrows = stream_arrows(figure, combined, distances,
                arc_length, series.arrow_fraction)
            else
              combined.arrows = {}
            end
            if line_closed then closed_count = closed_count + 1 end
            lines[#lines + 1] = combined
            point_count = point_count + #combined
          end
        end
      end
    end
  end

  return {
    lines = lines,
    points = point_count,
    step = step,
    automatic = automatic,
    periodic = periodic,
    closed_count = closed_count,
    truncated = truncated,
  }
end

-- The series layer clips streamplot paths and glyphs to the polar circle.
-- Arrow triangles are built in screen space, so a large `head` can put a
-- vertex outside that circle even when the anchor is inside.  Project such
-- vertices back onto the circle: every rendered vertex then lies inside the
-- frame, and the scene export can report the same clipping flags without
-- relying on SVG's clip path.
local function stream_clip_vertex(geom, x, y)
  local dx, dy = x - geom.cx, y - geom.cy
  local distance = math.sqrt(dx * dx + dy * dy)
  -- Coordinates are formatted to three decimals; keep a small inward margin
  -- so rounding cannot push a clipped vertex back over the frame circle.
  local limit = geom.radius - 0.001
  if distance <= limit or distance < 1e-12 then
    return x, y, false
  end
  local scale = limit / distance
  return geom.cx + dx * scale, geom.cy + dy * scale, true
end

-- One arrow triangle in SVG user units.  Returns the three vertices and
-- whether any of them had to be pulled back to the clip circle.
local function stream_arrow_geometry(figure, cfg, geom, arrow, head)
  local x, y = M.point(figure, cfg, geom, arrow.theta, arrow.r)
  local radians = math.rad(arrow.angle)
  local ux, uy = math.cos(radians), math.sin(radians)
  local half = head * 0.45
  local px, py = -uy * half, ux * half
  local tip_x = x + ux * head * 0.5
  local tip_y = y + uy * head * 0.5
  local neck_x = x - ux * head * 0.5
  local neck_y = y - uy * head * 0.5
  local left_x, left_y = neck_x + px, neck_y + py
  local right_x, right_y = neck_x - px, neck_y - py
  local clipped = false
  local outside
  tip_x, tip_y, outside = stream_clip_vertex(geom, tip_x, tip_y)
  clipped = clipped or outside
  left_x, left_y, outside = stream_clip_vertex(geom, left_x, left_y)
  clipped = clipped or outside
  right_x, right_y, outside = stream_clip_vertex(geom, right_x, right_y)
  clipped = clipped or outside
  return tip_x, tip_y, left_x, left_y, right_x, right_y, clipped
end

local function render_streamplot(series, figure, cfg, geom, buf)
  local built = build_streamplot(series, figure, cfg)
  local style = series.style
  local stroke_opacity, fill_opacity = "", ""
  if style.alpha < 1 then
    local alpha = util.fmt(style.alpha)
    stroke_opacity = string.format(' stroke-opacity="%s"', alpha)
    fill_opacity = string.format(' fill-opacity="%s"', alpha)
  end
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', util.escape_xml(style.label))
  end
  local arrow_count = 0
  local clipped_arrow_count = 0
  local arrow_geometry = {}
  for line_index, points in ipairs(built.lines) do
    local line_geometry = {}
    for arrow_index, arrow in ipairs(points.arrows or {}) do
      local tip_x, tip_y, left_x, left_y, right_x, right_y, clipped =
        stream_arrow_geometry(figure, cfg, geom, arrow, style.head)
      line_geometry[arrow_index] = {
        tip_x = tip_x, tip_y = tip_y,
        left_x = left_x, left_y = left_y,
        right_x = right_x, right_y = right_y,
        clipped = clipped,
      }
      arrow_count = arrow_count + 1
      if clipped then clipped_arrow_count = clipped_arrow_count + 1 end
    end
    arrow_geometry[line_index] = line_geometry
  end
  local dash = ""
  if style.linestyle == "dashed" then
    dash = ' stroke-dasharray="6 4"'
  elseif style.linestyle == "dotted" then
    dash = ' stroke-dasharray="1.5 3"'
  end

  buf[#buf + 1] = string.format(
    '  <g class="series series-polar-streamplot" data-cols="%d" data-rows="%d" data-lines="%d" data-points="%d" data-arrow-count="%d" data-clipped-arrow-count="%d" data-step="%s" data-step-mode="%s" data-density="%s" data-max-steps="%d" data-max-lines="%d" data-max-points="%d" data-arrows="%s" data-head="%s" data-linestyle="%s" data-arrow-fraction="%s" data-closed-lines="%d" data-arc-length-unit="data_radius_units" data-clip="polar-circle" data-periodic="%s" data-truncated="%s"%s>',
    #series.theta, #series.r, #built.lines, built.points, arrow_count,
    clipped_arrow_count, util.fmt(built.step),
    built.automatic and "auto" or "explicit",
    util.fmt(series.density), series.max_steps, series.max_lines,
    series.max_points, series.arrows and "true" or "false",
    util.fmt(style.head), style.linestyle, util.fmt(series.arrow_fraction),
    built.closed_count, built.periodic and "true" or "false",
    built.truncated and "true" or "false", label)

  for line_index, points in ipairs(built.lines) do
    local arrows = points.arrows or {}
    local geometries = arrow_geometry[line_index] or {}
    local line_clipped = 0
    for _, geometry in ipairs(geometries) do
      if geometry.clipped then line_clipped = line_clipped + 1 end
    end
    buf[#buf + 1] = string.format(
      '   <g class="polar-streamline" data-index="%d" data-points="%d" data-arrows="%d" data-clipped-arrows="%d" data-closed="%s" data-seed-theta="%s" data-seed-r="%s" data-arc-length="%s">',
      line_index, #points, #arrows, line_clipped,
      points.closed and "true" or "false",
      util.fmt(points.seed_theta), util.fmt(points.seed_r),
      util.fmt(points.arc_length))
    if style.linewidth > 0 and style.linestyle ~= "none" then
      local commands = {}
      for point_index, point in ipairs(points) do
        local x, y = M.point(figure, cfg, geom, point.theta, point.r)
        commands[point_index] = string.format("%s %s %s",
          point_index == 1 and "M" or "L", util.fmt(x), util.fmt(y))
      end
      buf[#buf + 1] = string.format(
        '    <path class="polar-streamline-path" d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"%s%s/>',
        table.concat(commands, " "), style.color,
        util.fmt(style.linewidth), dash, stroke_opacity)
    end
    for arrow_index, arrow in ipairs(arrows) do
      local geometry = geometries[arrow_index]
      buf[#buf + 1] = string.format(
        '    <polygon class="polar-stream-arrow" data-index="%d" data-fraction="%s" data-theta="%s" data-r="%s" data-angle="%s" data-clipped="%s" points="%s,%s %s,%s %s,%s" fill="%s"%s/>',
        arrow.index, util.fmt(arrow.fraction),
        util.fmt(arrow.theta), util.fmt(arrow.r),
        util.fmt(arrow.angle),
        geometry.clipped and "true" or "false",
        util.fmt(geometry.tip_x), util.fmt(geometry.tip_y),
        util.fmt(geometry.left_x), util.fmt(geometry.left_y),
        util.fmt(geometry.right_x), util.fmt(geometry.right_y),
        style.color, fill_opacity)
    end
    buf[#buf + 1] = '   </g>'
  end
  buf[#buf + 1] = '  </g>'
end

local function render_heatmap(heatmap, figure, cfg, geom, buf)
  local state = figure._polar
  local outer_value = heatmap_rmax(state, heatmap)
  local outer = geom.radius * outer_value / cfg.rmax
  local inner = geom.radius * heatmap.rmin / cfg.rmax
  local span = heatmap.theta_max - heatmap.theta_min
  local full_turn = span >= 2 * math.pi - 1e-9
  local sweep = (state.theta_direction or 1) < 0 and 1 or 0
  local opacity = ""
  if heatmap.alpha < 1 then
    local alpha = util.fmt(heatmap.alpha)
    opacity = string.format(' fill-opacity="%s" stroke-opacity="%s"',
      alpha, alpha)
  end
  local label = ""
  if heatmap.label ~= nil then
    label = string.format(' data-label="%s"',
      util.escape_xml(heatmap.label))
  end

  buf[#buf + 1] = string.format(
    '  <g class="series series-polar-heatmap" data-rows="%d" data-cols="%d" data-vmin="%s" data-vmax="%s" data-rmin="%s" data-rmax="%s" data-theta-min="%s" data-theta-max="%s"%s>',
    heatmap.rows, heatmap.cols, util.fmt(heatmap.vmin),
    util.fmt(heatmap.vmax), util.fmt(heatmap.rmin),
    util.fmt(outer_value), util.fmt(heatmap.theta_min),
    util.fmt(heatmap.theta_max), label)

  local function point_at(theta, radius)
    local display = M.theta_to_display(figure, theta)
    return geom.cx + radius * math.cos(display),
      geom.cy - radius * math.sin(display)
  end

  for row = 1, heatmap.rows do
    local inner_radius = inner + (outer - inner) * (row - 1) / heatmap.rows
    local outer_radius = inner + (outer - inner) * row / heatmap.rows
    for col = 1, heatmap.cols do
      local theta0 = heatmap.theta_min +
        span * (col - 1) / heatmap.cols
      local theta1 = heatmap.theta_min + span * col / heatmap.cols
      local color = colors.heat(heatmap.values[row][col], heatmap.vmin,
        heatmap.vmax)
      local shape
      if full_turn then
        if inner_radius <= 0.0005 then
          shape = string.format(
            '<circle class="polar-heatmap-cell" data-row="%d" data-col="%d" cx="%s" cy="%s" r="%s" fill="%s" stroke="%s" stroke-width="0.35"%s/>',
            row, col, util.fmt(geom.cx), util.fmt(geom.cy),
            util.fmt(outer_radius), color, color, opacity)
        else
          shape = string.format(
            '<path class="polar-heatmap-cell" data-row="%d" data-col="%d" fill-rule="evenodd" d="M %s %s A %s %s 0 1 1 %s %s A %s %s 0 1 1 %s %s M %s %s A %s %s 0 1 0 %s %s A %s %s 0 1 0 %s %s Z" fill="%s" stroke="%s" stroke-width="0.35"%s/>',
            row, col,
            util.fmt(geom.cx + outer_radius), util.fmt(geom.cy),
            util.fmt(outer_radius), util.fmt(outer_radius),
            util.fmt(geom.cx - outer_radius), util.fmt(geom.cy),
            util.fmt(outer_radius), util.fmt(outer_radius),
            util.fmt(geom.cx + outer_radius), util.fmt(geom.cy),
            util.fmt(geom.cx + inner_radius), util.fmt(geom.cy),
            util.fmt(inner_radius), util.fmt(inner_radius),
            util.fmt(geom.cx - inner_radius), util.fmt(geom.cy),
            util.fmt(inner_radius), util.fmt(inner_radius),
            util.fmt(geom.cx + inner_radius), util.fmt(geom.cy),
            color, color, opacity)
        end
      else
        local cell_span = theta1 - theta0
        local large = cell_span > math.pi and 1 or 0
        local ox0, oy0 = point_at(theta0, outer_radius)
        local ox1, oy1 = point_at(theta1, outer_radius)
        if inner_radius <= 0.0005 then
          shape = string.format(
            '<path class="polar-heatmap-cell" data-row="%d" data-col="%d" d="M %s %s L %s %s A %s %s 0 %d %d %s %s Z" fill="%s" stroke="%s" stroke-width="0.35"%s/>',
            row, col, util.fmt(geom.cx), util.fmt(geom.cy),
            util.fmt(ox0), util.fmt(oy0), util.fmt(outer_radius),
            util.fmt(outer_radius), large, sweep, util.fmt(ox1),
            util.fmt(oy1), color, color, opacity)
        else
          local ix0, iy0 = point_at(theta0, inner_radius)
          local ix1, iy1 = point_at(theta1, inner_radius)
          shape = string.format(
            '<path class="polar-heatmap-cell" data-row="%d" data-col="%d" d="M %s %s A %s %s 0 %d %d %s %s L %s %s A %s %s 0 %d %d %s %s Z" fill="%s" stroke="%s" stroke-width="0.35"%s/>',
            row, col, util.fmt(ox0), util.fmt(oy0), util.fmt(outer_radius),
            util.fmt(outer_radius), large, sweep, util.fmt(ox1),
            util.fmt(oy1), util.fmt(ix1), util.fmt(iy1),
            util.fmt(inner_radius), util.fmt(inner_radius), large,
            1 - sweep, util.fmt(ix0), util.fmt(iy0), color, color, opacity)
        end
      end
      buf[#buf + 1] = '   ' .. shape
    end
  end
  buf[#buf + 1] = '  </g>'
end

-- Project one normalized contour position onto the canvas.  `u` and `v` are
-- fractions of the field width and height, so both the renderer and the scene
-- exporter can resolve them against the effective radial extent.
local function contour_position(figure, cfg, geom, contour, u, v)
  local outer = contour_rmax(figure._polar, contour)
  local theta = contour.theta_min +
    (contour.theta_max - contour.theta_min) * u
  local radius = contour.rmin + (outer - contour.rmin) * v
  local x, y = M.point(figure, cfg, geom, theta, radius)
  return x, y, theta, radius
end

-- Forward declaration: the contour label planner is defined before the
-- shared geometry helpers, but uses the same overlap test as the legend.
local overlap_area

-- Direction of a contour segment in SVG user space, in degrees.  The polar
-- projection scales theta and r uniformly, so the tangent direction is
-- independent of the canvas geometry; the scene exporter relies on that.
local function contour_segment_angle(figure, cfg, geom, contour, segment)
  local u0, v0 = segment[1], segment[2]
  local du = segment[3] - segment[1]
  local dv = segment[4] - segment[2]
  local x0, y0 = contour_position(figure, cfg, geom, contour,
    u0 + du * 0.4, v0 + dv * 0.4)
  local x1, y1 = contour_position(figure, cfg, geom, contour,
    u0 + du * 0.6, v0 + dv * 0.6)
  local angle = math.deg(math.atan2(y1 - y0, x1 - x0))
  -- Keep labels upright: rotate by the equivalent angle in (-90, 90].
  if angle > 90 then
    angle = angle - 180
  elseif angle <= -90 then
    angle = angle + 180
  end
  return angle
end

-- Axis-aligned bounds of a rotated label, used for collision checks and for
-- keeping the whole label inside the circular clip.  The half height covers
-- the cap height of the 10 px label font plus the white contrast halo.
local function contour_label_box(x, y, value, angle)
  local half_width = text.measure(value, 10) / 2
  local half_height = 6
  local radians = math.rad(angle)
  local cosine = math.abs(math.cos(radians))
  local sine = math.abs(math.sin(radians))
  local extent_x = half_width * cosine + half_height * sine + 2
  local extent_y = half_width * sine + half_height * cosine + 2
  return {
    x = x - extent_x,
    y = y - extent_y,
    width = extent_x * 2,
    height = extent_y * 2,
  }, extent_x, extent_y
end

-- Pick a label anchor for one contour level.  Candidates are the midpoints of
-- every marching-squares segment; the farthest candidate that stays inside the
-- circle and clear of already placed labels, radial ticks, and annotations
-- wins.  Skipping a label is preferable to drawing unreadable overlapping
-- text.
local function contour_label_plan(figure, cfg, geom, contour, level_data,
    occupied)
  if not contour.labels or #level_data.segments == 0 then return nil end
  local value = util.fmt_tick(level_data.level)
  local outer = contour_rmax(figure._polar, contour)
  local radial = outer - contour.rmin
  local best = nil

  for _, segment in ipairs(level_data.segments) do
    local u = (segment[1] + segment[3]) / 2
    local v = (segment[2] + segment[4]) / 2
    local x, y = contour_position(figure, cfg, geom, contour, u, v)
    local angle = contour_segment_angle(figure, cfg, geom, contour, segment)
    local box, extent_x, extent_y = contour_label_box(x, y, value, angle)

    local dx, dy = x - geom.cx, y - geom.cy
    local distance = math.sqrt(dx * dx + dy * dy)
    local fits = true
    if distance > 0 then
      -- Shrink the anchor radially by the rotated box extent along that
      -- direction so the label never crosses the frame.
      local phi = math.atan2(dy, dx)
      local radial_extent = math.abs(extent_x * math.cos(phi)) +
        math.abs(extent_y * math.sin(phi))
      local limit = geom.radius - radial_extent - 1
      if limit <= 0 then
        fits = false
      elseif distance > limit then
        x = geom.cx + dx / distance * limit
        y = geom.cy + dy / distance * limit
        box = contour_label_box(x, y, value, angle)
      end
    end

    if fits then
      for _, other in ipairs(occupied) do
        if overlap_area(box, other) > 0 then
          fits = false
          break
        end
      end
    end

    if fits then
      local radius = math.abs(contour.rmin + radial * v)
      if best == nil or radius > best.radius then
        best = {
          level = level_data.level,
          text = value,
          x = x,
          y = y,
          angle = angle,
          box = box,
          u = u,
          v = v,
          radius = radius,
        }
      end
    end
  end

  return best
end

local function render_contour(contour, figure, cfg, geom, buf, occupied)
  local style = contour.style
  local plans = {}
  local dash = ""
  if style.linestyle == "dashed" then
    dash = ' stroke-dasharray="6 4"'
  elseif style.linestyle == "dotted" then
    dash = ' stroke-dasharray="1.5 3"'
  end
  local opacity = style.alpha < 1 and
    string.format(' stroke-opacity="%s"', util.fmt(style.alpha)) or ""
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"',
      util.escape_xml(style.label))
  end
  local outer = contour_rmax(figure._polar, contour)

  buf[#buf + 1] = string.format(
    '  <g class="series series-polar-contour" data-rows="%d" data-cols="%d" data-levels="%d" data-vmin="%s" data-vmax="%s" data-rmin="%s" data-rmax="%s" data-theta-min="%s" data-theta-max="%s"%s>',
    contour.rows, contour.cols, #contour.levels, util.fmt(contour.vmin),
    util.fmt(contour.vmax), util.fmt(contour.rmin), util.fmt(outer),
    util.fmt(contour.theta_min), util.fmt(contour.theta_max), label)

  for _, level_data in ipairs(contour.levels) do
    buf[#buf + 1] = string.format(
      '   <g class="polar-contour-level" data-level="%s">',
      util.fmt(level_data.level))
    for _, segment in ipairs(level_data.segments) do
      local theta0 = contour.theta_min +
        (contour.theta_max - contour.theta_min) * segment[1]
      local theta1 = contour.theta_min +
        (contour.theta_max - contour.theta_min) * segment[3]
      local radius0 = contour.rmin + (outer - contour.rmin) * segment[2]
      local radius1 = contour.rmin + (outer - contour.rmin) * segment[4]
      -- A straight line in (theta, r) space is a spiral in the projected
      -- frame.  Subdivide each marching-squares edge so long contours stay
      -- visually curved instead of becoming coarse chords.
      local angular = math.abs(theta1 - theta0)
      local radial = math.abs(radius1 - radius0) / cfg.rmax
      local steps = math.max(2, math.ceil(angular / (math.pi / 48)),
        math.ceil(radial * geom.radius / 5))
      if steps > 64 then steps = 64 end
      local points = {}
      for step = 0, steps do
        local t = step / steps
        local u = segment[1] + (segment[3] - segment[1]) * t
        local v = segment[2] + (segment[4] - segment[2]) * t
        local x, y = contour_position(figure, cfg, geom, contour, u, v)
        points[#points + 1] = util.fmt(x) .. " " .. util.fmt(y)
      end
      buf[#buf + 1] = string.format(
        '    <path class="polar-contour-line" d="M %s L %s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"%s%s/>',
        points[1], table.concat(points, " L ", 2), style.color,
        util.fmt(style.linewidth), dash, opacity)
    end
    local plan = contour_label_plan(figure, cfg, geom, contour, level_data,
      occupied)
    if plan ~= nil then
      occupied[#occupied + 1] = plan.box
      plans[#plans + 1] = plan
      local baseline = plan.y + 3
      buf[#buf + 1] = string.format(
        '    <text class="polar-contour-label" data-level="%s" data-angle="%s" x="%s" y="%s" font-size="10" fill="%s" text-anchor="middle" paint-order="stroke" stroke="#ffffff" stroke-width="2.5" stroke-linejoin="round" transform="rotate(%s %s %s)">%s</text>',
        util.fmt(plan.level), util.fmt(plan.angle), util.fmt(plan.x),
        util.fmt(baseline), style.color, util.fmt(plan.angle),
        util.fmt(plan.x), util.fmt(baseline), util.escape_xml(plan.text))
    end
    buf[#buf + 1] = '   </g>'
  end
  buf[#buf + 1] = '  </g>'
  return plans
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

-- Radial tick labels normally sit on the vertical spoke.  The outermost one
-- would cross the frame, so its baseline is capped a few pixels inside.
local function radius_label_baseline(geom, fraction)
  local y = geom.cy - geom.radius * fraction + 4
  local limit = geom.cy - geom.radius + 13
  if y < limit then return limit, true end
  return y, false
end

local function render_radius_labels(cfg, geom, buf)
  buf[#buf + 1] = '  <g class="r-ticks">'
  for index, value in ipairs(cfg.rticks) do
    local fraction = value / cfg.rmax
    local y, clamped = radius_label_baseline(geom, fraction)
    buf[#buf + 1] = string.format(
      '   <text class="r-tick" x="%s" y="%s" font-size="10" fill="%s" text-anchor="start" paint-order="stroke" stroke="#ffffff" stroke-width="2.5" stroke-linejoin="round" data-fraction="%s" data-clamped="%s">%s</text>',
      util.fmt(geom.cx + 6), util.fmt(y), TEXT_COLOR,
      util.fmt(fraction), clamped and "true" or "false",
      util.escape_xml(cfg.rlabels[index]))
  end
  buf[#buf + 1] = '  </g>'
end

-- Vertical colorbar for the heatmap that requested one.  It is drawn outside
-- the polar clip so the bar and its labels stay crisp at the canvas edge.
local function render_colorbar(figure, geom, buf)
  local heatmap = colorbar_heatmap(figure)
  if heatmap == nil then return end
  local x, y, width, height = colorbar_geometry(geom)
  local vmin, vmax = heatmap.vmin, heatmap.vmax
  local values = colorbar_ticks(heatmap)
  local source = heatmap.colorbar_tick_values ~= nil and "explicit" or
    "uniform"
  local span = vmax - vmin

  buf[#buf + 1] = string.format(
    '  <g class="polar-colorbar" data-orientation="vertical" data-vmin="%s" data-vmax="%s" data-ticks="%d" data-tick-source="%s" data-x="%s" data-y="%s" data-width="%s" data-height="%s">',
    util.fmt(vmin), util.fmt(vmax), #values, source, util.fmt(x), util.fmt(y),
    util.fmt(width), util.fmt(height))

  local steps = 40
  for index = 1, steps do
    local value = vmax - (vmax - vmin) * ((index - 0.5) / steps)
    buf[#buf + 1] = string.format(
      '   <rect class="colorbar-step" x="%s" y="%s" width="%s" height="%s" fill="%s"/>',
      util.fmt(x), util.fmt(y + height * (index - 1) / steps),
      util.fmt(width), util.fmt(height / steps + 0.5),
      colors.heat(value, vmin, vmax))
  end
  buf[#buf + 1] = string.format(
    '   <rect class="colorbar-frame" x="%s" y="%s" width="%s" height="%s" fill="none" stroke="%s" stroke-width="1"/>',
    util.fmt(x - 0.5), util.fmt(y - 0.5), util.fmt(width + 1),
    util.fmt(height + 1), AXIS_COLOR)

  local max_label = 0
  for _, value in ipairs(values) do
    local fraction = (value - vmin) / span
    local tick_y = y + height - height * fraction
    local label = colorbar_value(value)
    local measured = text.measure(label, 10)
    if measured > max_label then max_label = measured end
    buf[#buf + 1] = string.format(
      '   <line class="colorbar-tick" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1" data-value="%s" data-fraction="%s"/>',
      util.fmt(x + width), util.fmt(tick_y), util.fmt(x + width + 4),
      util.fmt(tick_y), AXIS_COLOR, util.fmt(value), util.fmt(fraction))
    buf[#buf + 1] = string.format(
      '   <text class="colorbar-label" x="%s" y="%s" font-size="10" fill="%s" text-anchor="start" data-value="%s" data-fraction="%s">%s</text>',
      util.fmt(x + width + 8), util.fmt(tick_y + 3.5), TEXT_COLOR,
      util.fmt(value), util.fmt(fraction), util.escape_xml(label))
  end
  if heatmap.colorbar_label ~= nil and heatmap.colorbar_label ~= "" then
    local label_x = x + width + 8 + max_label + 14
    local label_y = y + height / 2
    buf[#buf + 1] = string.format(
      '   <text class="colorbar-title" x="%s" y="%s" font-size="11" fill="%s" text-anchor="middle" transform="rotate(-90 %s %s)">%s</text>',
      util.fmt(label_x), util.fmt(label_y), TEXT_COLOR,
      util.fmt(label_x), util.fmt(label_y),
      util.escape_xml(heatmap.colorbar_label))
  end
  buf[#buf + 1] = '  </g>'
end

local ANNOTATION_ANCHORS = {
  left = "start",
  center = "middle",
  right = "end",
}

-- Resolve an annotation's target and text layout once, including the canvas
-- clamp applied to the text box.  The legend planner uses the same boxes so
-- it can avoid covering a shifted label.
local function annotation_layout(figure, cfg, geom, annotation)
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

  local fontsize = annotation.fontsize or 12
  local align = annotation.align or "left"
  local anchor = ANNOTATION_ANCHORS[align] or "start"
  local box = text.bounds(text_x, text_y, annotation.text, fontsize, anchor)
  local padding = 2
  local shift_x, shift_y = 0, 0
  if box.x < padding then
    shift_x = padding - box.x
  elseif box.x + box.width > figure.width - padding then
    shift_x = figure.width - padding - (box.x + box.width)
  end
  if box.y < padding then
    shift_y = padding - box.y
  elseif box.y + box.height > figure.height - padding then
    shift_y = figure.height - padding - (box.y + box.height)
  end
  text_x, text_y = text_x + shift_x, text_y + shift_y
  box = text.bounds(text_x, text_y, annotation.text, fontsize, anchor)
  return {
    target_x = target_x,
    target_y = target_y,
    text_x = text_x,
    text_y = text_y,
    box = box,
    fontsize = fontsize,
    align = align,
    anchor = anchor,
    clamped = shift_x ~= 0 or shift_y ~= 0,
  }
end

local function render_annotations(figure, cfg, geom, buf)
  local annotations = figure._polar.annotations or {}
  if #annotations == 0 then return end

  buf[#buf + 1] = '  <g class="annotation-layer" data-clip="canvas">'
  for index, annotation in ipairs(annotations) do
    local layout = annotation_layout(figure, cfg, geom, annotation)
    local target_x, target_y = layout.target_x, layout.target_y
    local text_x, text_y = layout.text_x, layout.text_y
    local color = annotation.color or TEXT_COLOR
    local fontsize = layout.fontsize
    local align = layout.align
    local anchor = layout.anchor
    local clamped = layout.clamped

    buf[#buf + 1] = string.format(
      '   <g class="annotation" data-index="%d" data-theta="%s" data-r="%s" data-clamped="%s">',
      index, util.fmt(annotation.theta), util.fmt(annotation.r),
      clamped and "true" or "false")

    if annotation.background ~= nil then
      local background = annotation.background
      local pad = background.pad or 3
      local stroke = ""
      if background.edgecolor ~= nil then
        stroke = string.format(' stroke="%s" stroke-width="1"',
          background.edgecolor)
      end
      buf[#buf + 1] = string.format(
        '    <rect class="annotation-background" x="%s" y="%s" width="%s" height="%s" rx="2" fill="%s" fill-opacity="%s"%s/>',
        util.fmt(layout.box.x - pad), util.fmt(layout.box.y - pad),
        util.fmt(layout.box.width + 2 * pad),
        util.fmt(layout.box.height + 2 * pad),
        background.color, util.fmt(background.alpha), stroke)
    end

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

local function title_geometry(figure, geom)
  local loc = figure._title_loc or "center"
  if loc == "left" then return 8, "start" end
  if loc == "right" then return geom.width - 8, "end" end
  return geom.width / 2, "middle"
end

local function render_title(figure, geom, buf)
  if figure._title == nil then return end
  local x, anchor = title_geometry(figure, geom)
  buf[#buf + 1] = string.format(
    '  <text class="title" x="%s" y="30" font-size="18" fill="%s" text-anchor="%s">%s</text>',
    util.fmt(x), TEXT_COLOR, anchor, util.escape_xml(figure._title))
end

local function clamp(value, minimum, maximum)
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

-- Text boxes come from the shared approximate metrics module so legend
-- sizing, tick-aware placement, and annotation clamping agree.

local function text_box(x, baseline, value, fontsize, anchor)
  return text.bounds(x, baseline, value, fontsize, anchor)
end

function overlap_area(first, second)
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
  for _, heatmap in ipairs(figure._polar.heatmaps or {}) do
    local label = heatmap.label
    if label ~= nil and label ~= "" then
      entries[#entries + 1] = {
        kind = "heatmap",
        color = colors.heat((heatmap.vmin + heatmap.vmax) / 2,
          heatmap.vmin, heatmap.vmax),
        vmin = heatmap.vmin,
        vmax = heatmap.vmax,
        label = label,
      }
    end
  end
  for _, contour in ipairs(figure._polar.contours or {}) do
    local label = contour.style.label
    if label ~= nil and label ~= "" then
      entries[#entries + 1] = {
        kind = "contour",
        color = contour.style.color,
        label = label,
      }
    end
  end
  for _, series in ipairs(figure._polar.series) do
    local label = series.style.label
    if label ~= nil and label ~= "" then
      entries[#entries + 1] = {
        kind = series.kind,
        color = series.style.color,
        linestyle = series.style.linestyle,
        label = label,
      }
    end
  end
  return entries
end

-- Legend sizing uses measured text widths rather than character counts.
-- The swatch column is 28 user units wide; add left/right padding so every
-- label can be drawn completely inside its column.
local LEGEND_FONT_SIZE = 11
local LEGEND_SWATCH = 28
local LEGEND_PAD = 12

local function legend_dimensions(figure, geom, entries)
  local max_text = 0
  for _, entry in ipairs(entries) do
    local width = text.measure(entry.label, LEGEND_FONT_SIZE)
    if width > max_text then max_text = width end
  end

  local opts = figure._legend_opts or {
    loc = "upper right", frame = true, ncol = 1,
  }
  local requested_ncol = math.max(1, math.min(opts.ncol or 1, #entries))
  local title_width = 0
  local title_height = 0
  if opts.title ~= nil and opts.title ~= "" then
    title_width = text.measure(opts.title, LEGEND_FONT_SIZE) + 16
    title_height = 22
  end

  local max_width = math.max(40, geom.width - 16)
  local ncol = requested_ncol
  local rows, col_width, box_width
  while true do
    rows = math.ceil(#entries / ncol)
    local entry_width = math.max(60,
      LEGEND_SWATCH + max_text + LEGEND_PAD)
    box_width = entry_width * ncol + (ncol - 1) * 8
    if title_width > box_width then box_width = title_width end
    if box_width <= max_width or ncol == 1 then break end
    ncol = ncol - 1
  end
  if box_width > max_width then box_width = max_width end
  col_width = math.max(30,
    math.floor((box_width - (ncol - 1) * 8) / ncol))

  local box_height = 12 + title_height + rows * 20
  return {
    opts = opts,
    ncol = ncol,
    rows = rows,
    col_width = col_width,
    title_height = title_height,
    width = box_width,
    height = box_height,
    text_width = max_text,
  }
end

local LOC_ANGLES = {
  ["upper right"] = math.pi / 4,
  ["upper left"] = 3 * math.pi / 4,
  ["lower left"] = 5 * math.pi / 4,
  ["lower right"] = 7 * math.pi / 4,
  ["upper center"] = math.pi / 2,
  ["center right"] = 0,
  ["lower center"] = 3 * math.pi / 2,
  ["center left"] = math.pi,
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
    local y = radius_label_baseline(geom, value / cfg.rmax)
    radius_boxes[index] = text_box(geom.cx + 6, y, cfg.rlabels[index], 10,
      "start")
  end
  return theta_boxes, radius_boxes
end

-- Boxes that contour labels should keep clear of: radial tick labels (drawn
-- above the series) and annotation text.  Angular labels live outside the
-- circle, so contour labels clamped inside the frame cannot reach them.
local function polar_label_obstacles(figure, cfg, geom)
  local _, radius_boxes = tick_boxes(figure, cfg, geom)
  local boxes = {}
  for _, box in ipairs(radius_boxes) do
    boxes[#boxes + 1] = box
  end
  for _, annotation in ipairs(figure._polar.annotations or {}) do
    local layout = annotation_layout(figure, cfg, geom, annotation)
    boxes[#boxes + 1] = layout.box
  end
  return boxes
end

local function legend_plan(figure, cfg, geom, extra_boxes)
  if not figure._legend_requested then return nil end
  local entries = legend_entries(figure)
  if #entries == 0 then return nil end
  local dims = legend_dimensions(figure, geom, entries)
  local width, height = dims.width, dims.height
  local opts = dims.opts
  local theta_boxes, radius_boxes = tick_boxes(figure, cfg, geom)
  local title_box = nil
  if figure._title ~= nil then
    local title_x, title_anchor = title_geometry(figure, geom)
    title_box = text.bounds(title_x, 30, figure._title, 18, title_anchor)
  end

  -- Keep the legend out of the reserved colorbar column as well.
  local colorbar_box = nil
  local bar_heatmap = colorbar_heatmap(figure)
  if bar_heatmap ~= nil then
    local bx, by, bw, bh = colorbar_geometry(geom)
    local max_label = 0
    for _, value in ipairs(colorbar_ticks(bar_heatmap)) do
      local measured = text.measure(colorbar_value(value), 10)
      if measured > max_label then max_label = measured end
    end
    local extra = 0
    if bar_heatmap.colorbar_label ~= nil and
        bar_heatmap.colorbar_label ~= "" then
      extra = 18
    end
    colorbar_box = {
      x = bx, y = by, width = bw + 8 + max_label + extra, height = bh,
    }
  end

  local data_points = {}
  for _, series in ipairs(figure._polar.series) do
    -- Streamplot grids are axes, not point lists; the streamlines themselves
    -- already cover the field area, so they do not add leader targets.
    if series.kind ~= "streamplot" then
      for index = 1, #series.theta do
        local x, y = M.point(figure, cfg, geom, series.theta[index],
          series.r[index])
        data_points[#data_points + 1] = { x, y }
      end
    end
  end

  local annotation_boxes = {}
  for _, annotation in ipairs(figure._polar.annotations or {}) do
    local layout = annotation_layout(figure, cfg, geom, annotation)
    annotation_boxes[#annotation_boxes + 1] = layout.box
    -- A leader arrow target is a data point too; keep the legend off it.
    data_points[#data_points + 1] = { layout.target_x, layout.target_y }
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
  if opts.loc == "center" then
    target_x, target_y = geom.cx, geom.cy
  elseif opts.loc == "best" then
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
    for _, annotation_box in ipairs(annotation_boxes) do
      label_overlap = label_overlap + overlap_area(box, annotation_box)
    end
    if title_box ~= nil then
      label_overlap = label_overlap + overlap_area(box, title_box)
    end
    if colorbar_box ~= nil then
      label_overlap = label_overlap + overlap_area(box, colorbar_box)
    end
    for _, extra in ipairs(extra_boxes or {}) do
      label_overlap = label_overlap + overlap_area(box, extra)
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
    text_width = dims.text_width,
    opts = opts,
    loc = opts.loc or "upper right",
    placement = best.inside and "inside" or "outside",
  }
end

local function polar_swatch(entry, x, y, buf)
  local kind, color = entry.kind, entry.color
  if kind == "scatter" then
    buf[#buf + 1] = string.format(
      '   <circle cx="%s" cy="%s" r="4" fill="%s"/>',
      util.fmt(x + 10), util.fmt(y), color)
  elseif kind == "heatmap" then
    -- A stepped gradient swatch communicates the field range better than a
    -- single midpoint color, matching the new polar colorbar.
    local vmin = entry.vmin or 0
    local vmax = entry.vmax or vmin
    local steps = 5
    for step = 1, steps do
      local value = vmin + (vmax - vmin) * (step - 0.5) / steps
      buf[#buf + 1] = string.format(
        '   <rect class="legend-swatch-step" x="%s" y="%s" width="%s" height="10" fill="%s"/>',
        util.fmt(x + (step - 1) * 20 / steps), util.fmt(y - 5),
        util.fmt(20 / steps + 0.2), colors.heat(value, vmin, vmax))
    end
  elseif kind == "quiver" then
    buf[#buf + 1] = string.format(
      '   <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2" stroke-linecap="round"/>',
      util.fmt(x), util.fmt(y), util.fmt(x + 14), util.fmt(y), color)
    buf[#buf + 1] = string.format(
      '   <polygon points="%s,%s %s,%s %s,%s" fill="%s"/>',
      util.fmt(x + 20), util.fmt(y), util.fmt(x + 13), util.fmt(y - 3.5),
      util.fmt(x + 13), util.fmt(y + 3.5), color)
  elseif kind == "streamplot" then
    local dash = ""
    if entry.linestyle == "dashed" then
      dash = ' stroke-dasharray="6 4"'
    elseif entry.linestyle == "dotted" then
      dash = ' stroke-dasharray="1.5 3"'
    end
    if entry.linestyle ~= "none" then
      buf[#buf + 1] = string.format(
        '   <path class="legend-swatch-streamplot" d="M %s %s Q %s %s %s %s T %s %s" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round"%s/>',
        util.fmt(x), util.fmt(y), util.fmt(x + 5), util.fmt(y - 5),
        util.fmt(x + 10), util.fmt(y), util.fmt(x + 16), util.fmt(y),
        color, dash)
    end
    buf[#buf + 1] = string.format(
      '   <polygon points="%s,%s %s,%s %s,%s" fill="%s"/>',
      util.fmt(x + 20), util.fmt(y), util.fmt(x + 13), util.fmt(y - 3.5),
      util.fmt(x + 13), util.fmt(y + 3.5), color)
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

local function render_legend(figure, cfg, geom, buf, extra_boxes)
  local plan = legend_plan(figure, cfg, geom, extra_boxes)
  if plan == nil then return end
  local x, y = plan.x, plan.y
  local opts = plan.opts

  buf[#buf + 1] = string.format(
    '  <g class="polar-legend" data-loc="%s" data-placement="%s" data-x="%s" data-y="%s" data-width="%s" data-height="%s" data-text-width="%s" data-framealpha="%s">',
    util.escape_xml(plan.loc), plan.placement, util.fmt(x), util.fmt(y),
    util.fmt(plan.width), util.fmt(plan.height),
    util.fmt(plan.text_width or 0), util.fmt(opts.framealpha or 0.92))
  local framealpha = opts.framealpha or 0.92
  local facecolor = opts.facecolor or "#ffffff"
  local edgecolor = opts.edgecolor or "#bbbbbb"
  if opts.frame ~= false then
    buf[#buf + 1] = string.format(
      '   <rect class="legend-frame" x="%s" y="%s" width="%s" height="%s" rx="3" fill="%s" fill-opacity="%s" stroke="%s" stroke-width="1"/>',
      util.fmt(x), util.fmt(y), util.fmt(plan.width), util.fmt(plan.height),
      facecolor, util.fmt(framealpha), edgecolor)
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
    polar_swatch(entry, entry_x, entry_y, buf)
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
  add('  <g class="series-layer" clip-path="url(#' .. clip_id .. ')">')
  for _, heatmap in ipairs(state.heatmaps or {}) do
    render_heatmap(heatmap, figure, cfg, geom, buf)
  end
  local label_obstacles = polar_label_obstacles(figure, cfg, geom)
  local contour_label_boxes = {}
  for _, contour in ipairs(state.contours or {}) do
    local plans = render_contour(contour, figure, cfg, geom, buf,
      label_obstacles)
    for _, plan in ipairs(plans) do
      contour_label_boxes[#contour_label_boxes + 1] = plan.box
    end
  end
  for _, series in ipairs(state.series) do
    if series.kind == "line" then
      render_line(series, figure, cfg, geom, buf)
    elseif series.kind == "scatter" then
      render_scatter(series, figure, cfg, geom, buf)
    elseif series.kind == "bar" then
      render_bar(series, figure, cfg, geom, buf)
    elseif series.kind == "errorbar" then
      render_errorbar(series, figure, cfg, geom, buf)
    elseif series.kind == "quiver" then
      render_quiver(series, figure, cfg, geom, buf)
    elseif series.kind == "streamplot" then
      render_streamplot(series, figure, cfg, geom, buf)
    end
  end
  add('  </g>')
  -- Radial labels sit inside the circle.  Draw them after the clipped series
  -- layer so bars and filled heatmap cells cannot hide the numbers.
  render_radius_labels(cfg, geom, buf)
  render_annotations(figure, cfg, geom, buf)
  render_colorbar(figure, geom, buf)
  add('  </g>')
  render_legend(figure, cfg, geom, buf, contour_label_boxes)
  add(' </g>')
  add('</svg>')
  return table.concat(buf, "\n") .. "\n"
end

local function copy_array(source)
  local result = {}
  for index = 1, #source do result[index] = source[index] end
  return result
end

local function copy_matrix(source)
  local result = {}
  for row = 1, #source do result[row] = copy_array(source[row]) end
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
    head = style.head,
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
  if annotation.background ~= nil then
    copy.background = {
      color = annotation.background.color,
      edgecolor = annotation.background.edgecolor,
      alpha = annotation.background.alpha,
      pad = annotation.background.pad,
    }
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

-- Map normalized contour segments back to data-space (theta, r) pairs for
-- non-SVG backends.  `outer` is the resolved effective radial extent.  When
-- labels are enabled each level also exposes its preferred anchor (the
-- farthest segment midpoint) in data coordinates plus the upright screen-space
-- tangent angle; the SVG renderer may skip a label that would collide.
local function contour_scene_levels(contour, outer, figure, cfg)
  local span = contour.theta_max - contour.theta_min
  local radial = outer - contour.rmin
  local levels = {}
  for level_index, level_data in ipairs(contour.levels) do
    local segments = {}
    for segment_index, segment in ipairs(level_data.segments) do
      segments[segment_index] = {
        contour.theta_min + span * segment[1],
        contour.rmin + radial * segment[2],
        contour.theta_min + span * segment[3],
        contour.rmin + radial * segment[4],
      }
    end
    local label = nil
    if contour.labels and #level_data.segments > 0 then
      local best, best_radius = nil, -1
      for _, segment in ipairs(level_data.segments) do
        local mid_u = (segment[1] + segment[3]) / 2
        local mid_v = (segment[2] + segment[4]) / 2
        local radius = math.abs(contour.rmin + radial * mid_v)
        if radius > best_radius then
          best, best_radius = segment, radius
        end
      end
      local u = (best[1] + best[3]) / 2
      local v = (best[2] + best[4]) / 2
      -- Geometry only scales and translates the projection, so a canonical
      -- unit circle yields the same tangent direction as the real canvas.
      local angle = contour_segment_angle(figure, cfg,
        { cx = 0, cy = 0, radius = 1 }, contour, best)
      label = {
        text = util.fmt_tick(level_data.level),
        theta = contour.theta_min + span * u,
        r = contour.rmin + radial * v,
        angle = angle,
        u = u,
        v = v,
      }
    end
    levels[level_index] = {
      level = level_data.level,
      segments = segments,
      label = label,
    }
  end
  return levels
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
    title_align = figure._title_loc or "center",
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
      heatmaps = {},
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
      framealpha = opts.framealpha or 0.92,
      facecolor = opts.facecolor or "#ffffff",
      edgecolor = opts.edgecolor or "#bbbbbb",
      title = opts.title,
      ncol = opts.ncol or 1,
      entries = {},
    }
    for index, entry in ipairs(entries) do
      local exported_entry = {
        kind = entry.kind,
        label = entry.label,
        color = entry.color,
      }
      if entry.linestyle ~= nil then
        exported_entry.linestyle = entry.linestyle
      end
      if entry.kind == "heatmap" then
        exported_entry.vmin = entry.vmin
        exported_entry.vmax = entry.vmax
      end
      exported.entries[index] = exported_entry
    end
    scene.polar.legend = exported
  end

  for heatmap_index, heatmap in ipairs(state.heatmaps or {}) do
    scene.polar.heatmaps[#scene.polar.heatmaps + 1] = {
      kind = "heatmap",
      rows = heatmap.rows,
      cols = heatmap.cols,
      values = copy_matrix(heatmap.values),
      vmin = heatmap.vmin,
      vmax = heatmap.vmax,
      rmin = heatmap.rmin,
      rmax = heatmap_rmax(state, heatmap),
      theta_min = heatmap.theta_min,
      theta_max = heatmap.theta_max,
      alpha = heatmap.alpha,
      label = heatmap.label,
      colorbar = heatmap.colorbar and true or false,
      colorbar_ticks = heatmap.colorbar_ticks,
      colorbar_tick_values = heatmap.colorbar_tick_values and
        copy_array(heatmap.colorbar_tick_values) or nil,
    }
  end

  local bar_heatmap = colorbar_heatmap(figure)
  if bar_heatmap ~= nil then
    local values = colorbar_ticks(bar_heatmap)
    local labels, fractions = {}, {}
    local span = bar_heatmap.vmax - bar_heatmap.vmin
    for index, value in ipairs(values) do
      labels[index] = colorbar_value(value)
      fractions[index] = (value - bar_heatmap.vmin) / span
    end
    scene.polar.colorbar = {
      orientation = "vertical",
      vmin = bar_heatmap.vmin,
      vmax = bar_heatmap.vmax,
      ticks = values,
      tick_labels = labels,
      tick_fractions = fractions,
      tick_source = bar_heatmap.colorbar_tick_values ~= nil and "explicit" or
        "uniform",
      label = bar_heatmap.colorbar_label,
    }
  end

  if #(state.contours or {}) > 0 then
    scene.polar.contours = {}
    for _, contour in ipairs(state.contours) do
      local outer = contour_rmax(state, contour)
      scene.polar.contours[#scene.polar.contours + 1] = {
        kind = "contour",
        rows = contour.rows,
        cols = contour.cols,
        vmin = contour.vmin,
        vmax = contour.vmax,
        rmin = contour.rmin,
        rmax = outer,
        theta_min = contour.theta_min,
        theta_max = contour.theta_max,
        labels = contour.labels,
        style = copy_style(contour.style),
        levels = contour_scene_levels(contour, outer, figure, cfg),
      }
    end
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
    elseif series.kind == "quiver" then
      local resolved, automatic = quiver_scale(series)
      local indices, stride = quiver_indices(series)
      copy.u = copy_array(series.u)
      copy.v = copy_array(series.v)
      copy.components = "tangential_radial"
      copy.scale = series.scale
      copy.auto_scale = automatic
      copy.resolved_scale = resolved
      copy.scale_unit = "svg_user_units_per_magnitude"
      copy.pivot = series.pivot
      copy.max_arrows = series.max_arrows
      copy.normalize = series.normalize
      copy.stride = stride
      copy.drawn = quiver_drawn(series, indices)
    elseif series.kind == "streamplot" then
      local built = build_streamplot(series, figure, cfg)
      local stream_geom
      local stream_geom_ready = false
      copy.cols = #series.theta
      copy.rows = #series.r
      copy.u = copy_matrix(series.u)
      copy.v = copy_matrix(series.v)
      copy.components = "tangential_radial"
      copy.periodic = built.periodic
      copy.density = series.density
      copy.step = series.step
      copy.step_mode = built.automatic and "auto" or "explicit"
      copy.resolved_step = built.step
      copy.step_unit = "data_radius_units"
      copy.max_steps = series.max_steps
      copy.max_lines = series.max_lines
      copy.max_points = series.max_points
      copy.arrows = series.arrows
      copy.arrow_fraction = series.arrow_fraction
      copy.head = series.style.head
      copy.closed_line_count = built.closed_count
      copy.arc_length_unit = "data_radius_units"
      copy.clip = "polar_circle"
      copy.truncated = built.truncated
      copy.line_count = #built.lines
      copy.point_count = built.points
      copy.arrow_count = 0
      copy.clipped_arrow_count = 0
      copy.lines = {}
      for line_index, points in ipairs(built.lines) do
        local exported = {
          theta = {},
          r = {},
          points = #points,
          closed = points.closed and true or false,
          seed_theta = points.seed_theta,
          seed_r = points.seed_r,
          arc_length = points.arc_length,
          arrow_count = 0,
          clipped_arrows = 0,
          arrows = {},
        }
        for point_index, point in ipairs(points) do
          exported.theta[point_index] = point.theta
          exported.r[point_index] = point.r
        end
        for arrow_index, arrow in ipairs(points.arrows or {}) do
          local clipped = false
          if series.arrows and series.style.head > 0 then
            if not stream_geom_ready then
              stream_geom_ready = true
              local ok
              ok, stream_geom = pcall(layout, figure)
              if not ok then stream_geom = nil end
            end
            if stream_geom ~= nil then
              local _, _, _, _, _, _, is_clipped = stream_arrow_geometry(
                figure, cfg, stream_geom, arrow, series.style.head)
              clipped = is_clipped
            end
          end
          exported.arrows[arrow_index] = {
            index = arrow.index,
            fraction = arrow.fraction,
            theta = arrow.theta,
            r = arrow.r,
            angle = arrow.angle,
            clipped = clipped,
          }
          exported.arrow_count = exported.arrow_count + 1
          if clipped then
            exported.clipped_arrows = exported.clipped_arrows + 1
            copy.clipped_arrow_count = copy.clipped_arrow_count + 1
          end
        end
        copy.arrow_count = copy.arrow_count + exported.arrow_count
        copy.lines[line_index] = exported
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
