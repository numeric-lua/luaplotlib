-- Pure-Lua SVG renderer for luaplotlib figures.

local ticks = require("luaplotlib.ticks")
local util = require("luaplotlib.util")

local M = {}

local FONT_FAMILY = "Helvetica, Arial, sans-serif"
local TEXT_COLOR = "#222222"
local AXIS_COLOR = "#333333"
local GRID_COLOR = "#d9d9d9"

local function clamp(value, minimum, maximum)
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function layout(fig)
  local width = fig.width
  local height = fig.height
  local left = math.min(72, math.max(36, width * 0.14))
  local right = width - math.min(28, math.max(12, width * 0.04))
  if fig._colorbar then right = right - 62 end
  if fig._twin then right = right - 58 end
  local top = math.min(48, math.max(24, height * 0.10))
  if fig._twiny then top = top + 52 end
  local bottom = height - math.min(66, math.max(36, height * 0.16))

  if right - left < 20 or bottom - top < 20 then
    util.fail("figure is too small to render a plot area", 3)
  end

  return {
    width = width,
    height = height,
    left = left,
    right = right,
    top = top,
    bottom = bottom,
    plot_width = right - left,
    plot_height = bottom - top,
  }
end

-- Collect data extents in axis coordinates. Linear axes use the raw values;
-- log axes use log10(value) and reject non-positive values with a clear error.
local function data_extents(fig, xscale, yscale)
  local min_x, max_x, min_y, max_y
  local baseline_y = false
  local any = false
  local has_x, has_y = false, false
  local x_log = xscale == "log"
  local y_log = yscale == "log"

  local function check_positive(value, axis, series_index, point_index, role)
    if value <= 0 then
      util.fail(string.format(
        "%s axis uses a log scale but %s %d has non-positive value %s at point %d; " ..
        "log scales require strictly positive values",
        axis, role, series_index, util.fmt_tick(value), point_index), 3)
    end
  end

  local function include_x(value, series_index, point_index, role)
    if x_log then
      check_positive(value, "x", series_index, point_index, role)
      value = util.log10(value)
    end
    any = true
    has_x = true
    if min_x == nil or value < min_x then min_x = value end
    if max_x == nil or value > max_x then max_x = value end
  end

  local function include_y(value, series_index, point_index, role)
    if y_log then
      check_positive(value, "y", series_index, point_index, role)
      value = util.log10(value)
    end
    any = true
    has_y = true
    if min_y == nil or value < min_y then min_y = value end
    if max_y == nil or value > max_y then max_y = value end
  end

  for series_index, series in ipairs(fig._series) do
    if series.kind == "image" then
      include_x(0, series_index, 1, "image")
      include_x(series.cols, series_index, 1, "image")
      include_y(0, series_index, 1, "image")
      include_y(series.rows, series_index, 1, "image")
    elseif series.kind == "axhline" then
      include_y(series.y, series_index, 1, "axhline")
    elseif series.kind == "axvline" then
      include_x(series.x, series_index, 1, "axvline")
    elseif series.kind == "line" or series.kind == "scatter" then
      for i = 1, #series.x do
        include_x(series.x[i], series_index, i, "series")
        include_y(series.y[i], series_index, i, "series")
      end
    elseif series.kind == "hist" then
      include_x(series.edges[1], series_index, 1, "histogram edge")
      include_x(series.edges[#series.edges], series_index, #series.edges,
        "histogram edge")
      if y_log then
        -- Zero-count bins are not drawn, so they do not define a log range.
        for i = 1, #series.counts do
          local count = series.counts[i]
          if count > 0 then
            include_y(count, series_index, i, "histogram count")
          elseif count < 0 then
            check_positive(count, "y", series_index, i, "histogram count")
          end
        end
      else
        baseline_y = true
        include_y(0, series_index, 1, "histogram baseline")
        for i = 1, #series.counts do
          include_y(series.counts[i], series_index, i, "histogram count")
        end
      end
    elseif series.kind == "errorbar" then
      for i = 1, #series.x do
        local x, y = series.x[i], series.y[i]
        local xerr = series.xerr and series.xerr[i] or 0
        local yerr = series.yerr[i]
        include_x(x - xerr, series_index, i, "errorbar x")
        include_x(x + xerr, series_index, i, "errorbar x")
        include_y(y - yerr, series_index, i, "errorbar y")
        include_y(y + yerr, series_index, i, "errorbar y")
      end
    elseif series.kind == "fill" then
      for i = 1, #series.x do
        include_x(series.x[i], series_index, i, "fill x")
        include_y(series.y1[i], series_index, i, "fill lower")
        include_y(series.y2[i], series_index, i, "fill upper")
      end
    elseif series.kind == "fillx" then
      for i = 1, #series.y do
        include_y(series.y[i], series_index, i, "fillx y")
        include_x(series.x1[i], series_index, i, "fillx left")
        include_x(series.x2[i], series_index, i, "fillx right")
      end
    elseif series.kind == "step" then
      for i = 1, #series.x do
        include_x(series.x[i], series_index, i, "step x")
        include_y(series.y[i], series_index, i, "step y")
      end
    elseif series.kind == "stem" then
      include_y(0, series_index, 1, "stem baseline")
      for i = 1, #series.x do
        include_x(series.x[i], series_index, i, "stem x")
        include_y(series.y[i], series_index, i, "stem y")
      end
    elseif series.kind == "contour" then
      include_x(0, series_index, 1, "contour")
      include_x(series.cols or 1, series_index, 1, "contour")
      include_y(0, series_index, 1, "contour")
      include_y(series.rows or 1, series_index, 1, "contour")
    elseif series.kind == "barh" then
      include_x(0, series_index, 1, "barh baseline")
      for i = 1, #series.x do
        include_x(series.x[i], series_index, i, "barh value")
        include_y(series.y[i] - series.height / 2, series_index, i, "barh")
        include_y(series.y[i] + series.height / 2, series_index, i, "barh")
      end
    elseif series.kind == "box" then
      include_x(series.position - series.width / 2, series_index, 1, "box")
      include_x(series.position + series.width / 2, series_index, 1, "box")
      include_y(series.low, series_index, 1, "box whisker")
      include_y(series.high, series_index, 1, "box whisker")
      for _, value in ipairs(series.outliers) do
        include_y(value, series_index, 1, "box outlier")
      end
    elseif series.kind == "bar" then
      local half = series.width / 2
      local offset = series.offset or 0
      for i = 1, #series.x do
        local center = series.x[i] + offset
        local left = center - half
        local right = center + half
        if x_log then
          -- The bar position is data and must be positive. Its left edge is
          -- derived geometry, so it may be clipped to the axis instead of
          -- rejecting an otherwise valid positive position.
          include_x(center, series_index, i, "bar x")
          if left > 0 then
            include_x(left, series_index, i, "bar edge")
          end
          include_x(right, series_index, i, "bar edge")
        else
          include_x(left, series_index, i, "bar edge")
          include_x(right, series_index, i, "bar edge")
        end
        if series.bottom ~= nil then
          -- Stacked bars occupy the interval [bottom, bottom + value]. Positive
          -- and negative stacks are accumulated separately by the figure.
          local bottom = series.bottom[i]
          local top = bottom + series.y[i]
          if not y_log then
            include_y(0, series_index, i, "bar baseline")
            include_y(bottom, series_index, i, "bar stack")
            include_y(top, series_index, i, "bar stack top")
          else
            if bottom > 0 then
              include_y(bottom, series_index, i, "bar stack")
            end
            include_y(top, series_index, i, "bar stack top")
          end
        else
          if not y_log then
            include_y(0, series_index, i, "bar baseline")
          end
          include_y(series.y[i], series_index, i, "bar value")
        end
      end
    end
  end

  if not any then
    return nil
  end
  return {
    min_x = min_x,
    max_x = max_x,
    min_y = min_y,
    max_y = max_y,
    baseline_y = baseline_y,
    has_x = has_x,
    has_y = has_y,
  }
end

local function auto_range(lo, hi, zero_baseline)
  local raw_lo, raw_hi = lo, hi
  if raw_hi < raw_lo then
    raw_lo, raw_hi = raw_hi, raw_lo
  end

  if raw_lo == raw_hi then
    if zero_baseline and raw_lo == 0 then
      return 0, 1
    end
    local pad = math.abs(raw_lo) * 0.1
    if pad == 0 then pad = 1 end
    lo, hi = raw_lo - pad, raw_hi + pad
  else
    local pad = (raw_hi - raw_lo) * 0.05
    lo, hi = raw_lo - pad, raw_hi + pad
    if zero_baseline then
      if raw_lo == 0 and lo < 0 then lo = 0 end
      if raw_hi == 0 and hi > 0 then hi = 0 end
    end
  end

  if not (hi > lo) then
    lo, hi = raw_lo - 1, raw_hi + 1
  end
  return lo, hi
end

local function auto_limits(lo, hi, target, zero_baseline)
  lo, hi = auto_range(lo, hi, zero_baseline)
  return lo, hi, ticks.generate(lo, hi, target)
end

-- Build the view for one axis. Extents are already in axis (transformed)
-- coordinates; explicit limits are in data coordinates.
local function make_axis(axis_name, scale, explicit, extents_min, extents_max, target,
    zero_baseline, default_lo, default_hi)
  local is_log = scale == "log"
  local to_axis
  local from_axis
  if is_log then
    to_axis = function(value) return util.log10(value) end
    from_axis = function(value) return 10 ^ value end
  else
    to_axis = function(value) return value end
    from_axis = function(value) return value end
  end

  local minimum, maximum, tick_values
  if explicit ~= nil then
    local lo, hi = explicit[1], explicit[2]
    if is_log then
      if lo <= 0 then
        util.fail(axis_name .. " minimum must be positive for a log axis, got " ..
          util.fmt_tick(lo), 3)
      end
      if hi <= 0 then
        util.fail(axis_name .. " maximum must be positive for a log axis, got " ..
          util.fmt_tick(hi), 3)
      end
    end
    minimum, maximum = to_axis(lo), to_axis(hi)
    if is_log then
      tick_values = ticks.generate_log(lo, hi, target)
    else
      tick_values = ticks.generate(lo, hi, target)
    end
  elseif extents_min ~= nil then
    if is_log then
      minimum, maximum = auto_range(extents_min, extents_max, false)
      tick_values = ticks.generate_log(from_axis(minimum), from_axis(maximum), target)
    else
      minimum, maximum, tick_values =
        auto_limits(extents_min, extents_max, target, zero_baseline)
    end
  else
    if is_log then
      minimum, maximum = 0, 1
      tick_values = ticks.generate_log(1, 10, target)
    else
      minimum, maximum = default_lo, default_hi
      tick_values = ticks.generate(minimum, maximum, target)
    end
  end

  return {
    scale = scale,
    minimum = minimum,
    maximum = maximum,
    to_axis = to_axis,
    from_axis = from_axis,
    ticks = tick_values,
    data_minimum = from_axis(minimum),
    data_maximum = from_axis(maximum),
  }
end

local function tick_count(plot_width, plot_height)
  local x_target = clamp(math.floor(plot_width / 85), 3, 8)
  local y_target = clamp(math.floor(plot_height / 60), 3, 8)
  return x_target, y_target
end

local function find_category_ticks(fig, xmin, xmax)
  if not fig._category_ticks then
    return nil
  end
  local result = {}
  local tolerance = (xmax - xmin) * 1e-9
  for _, category in ipairs(fig._category_ticks) do
    if category.position >= xmin - tolerance and category.position <= xmax + tolerance then
      result[#result + 1] = category
    end
  end
  return result
end

local function swatch(buf, kind, color, x, y)
  if kind == "scatter" then
    buf[#buf + 1] = string.format(
      '  <circle cx="%s" cy="%s" r="4" fill="%s"/>',
      util.fmt(x + 10), util.fmt(y), color)
  elseif kind == "fill" then
    buf[#buf + 1] = string.format(
      '  <rect x="%s" y="%s" width="20" height="9" rx="1" fill="%s"/>',
      util.fmt(x), util.fmt(y - 4), color)
  elseif kind == "hist" or kind == "bar" then
    buf[#buf + 1] = string.format(
      '  <rect x="%s" y="%s" width="20" height="9" rx="1" fill="%s"/>',
      util.fmt(x), util.fmt(y - 4), color)
  else
    buf[#buf + 1] = string.format(
      '  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2.5" stroke-linecap="round"/>',
      util.fmt(x), util.fmt(y), util.fmt(x + 20), util.fmt(y), color)
  end
end

local function render_legend(fig, geom, buf)
  if not fig._legend_requested then
    return
  end

  local entries = {}
  for _, series in ipairs(fig._series) do
    local label = series.style.label
    if label ~= nil and label ~= "" then
      entries[#entries + 1] = {
        kind = series.kind,
        color = series.style.color,
        label = label,
      }
    end
  end
  if #entries == 0 then
    return
  end

  local max_chars = 0
  for _, entry in ipairs(entries) do
    if #entry.label > max_chars then
      max_chars = #entry.label
    end
  end

  local box_width = math.min(geom.plot_width - 8, math.max(88, 52 + max_chars * 6.5))
  local box_height = 12 + #entries * 20
  local opts = fig._legend_opts or { loc = "upper right", frame = true }
  local x, y
  if opts.loc == "upper left" then
    x, y = geom.left + 8, geom.top + 8
  elseif opts.loc == "lower left" then
    x, y = geom.left + 8, geom.bottom - box_height - 8
  elseif opts.loc == "lower right" then
    x, y = geom.right - box_width - 8, geom.bottom - box_height - 8
  else
    x, y = geom.right - box_width - 8, geom.top + 8
  end
  x = clamp(x, geom.left + 4, math.max(geom.left + 4, geom.right - box_width - 4))
  y = clamp(y, geom.top + 4, math.max(geom.top + 4, geom.bottom - box_height - 4))

  buf[#buf + 1] = ' <g class="legend">'
  if opts.frame ~= false then
    buf[#buf + 1] = string.format(
      '  <rect class="legend-frame" x="%s" y="%s" width="%s" height="%s" rx="3" fill="#ffffff" fill-opacity="0.92" stroke="#bbbbbb" stroke-width="1"/>',
      util.fmt(x), util.fmt(y), util.fmt(box_width), util.fmt(box_height))
  end
  for i, entry in ipairs(entries) do
    local entry_y = y + 12 + (i - 1) * 20
    swatch(buf, entry.kind, entry.color, x + 8, entry_y)
    buf[#buf + 1] = string.format(
      '  <text x="%s" y="%s" font-size="11" fill="%s">%s</text>',
      util.fmt(x + 36), util.fmt(entry_y + 4), TEXT_COLOR,
      util.escape_xml(entry.label))
  end
  buf[#buf + 1] = ' </g>'
end

local function attribute(value)
  return util.escape_xml(value)
end

local function render_image(series, map_x, map_y, buf)
  local colors = require("luaplotlib.colors")
  buf[#buf + 1] = '  <g class="heatmap">'
  for row = 1, series.rows do
    for col = 1, series.cols do
      local x0 = map_x(col - 1)
      local x1 = map_x(col)
      local y0 = map_y(series.rows - row)
      local y1 = map_y(series.rows - row + 1)
      local left = math.min(x0, x1)
      local top = math.min(y0, y1)
      local color = colors.heat(series.values[row][col], series.vmin,
        series.vmax)
      buf[#buf + 1] = string.format(
        '   <rect class="heatmap-cell" x="%s" y="%s" width="%s" height="%s" fill="%s"/>',
        util.fmt(left), util.fmt(top), util.fmt(math.abs(x1 - x0)),
        util.fmt(math.abs(y1 - y0)), color)
    end
  end
  buf[#buf + 1] = '  </g>'
end

local function render_colorbar(series, geom, buf)
  local colors = require("luaplotlib.colors")
  local x = geom.right + 14
  local y = geom.top
  local height = geom.plot_height
  local steps = 40
  buf[#buf + 1] = '  <g class="colorbar">'
  for index = 1, steps do
    local value = series.vmin + (series.vmax - series.vmin) *
      ((index - 0.5) / steps)
    buf[#buf + 1] = string.format(
      '   <rect x="%s" y="%s" width="16" height="%s" fill="%s"/>',
      util.fmt(x), util.fmt(y + height * (index - 1) / steps),
      util.fmt(height / steps + 0.5), colors.heat(value, series.vmin,
        series.vmax))
  end
  buf[#buf + 1] = string.format(
    '   <text x="%s" y="%s" font-size="10" text-anchor="start">%s</text>',
    util.fmt(x + 22), util.fmt(y + 10), util.fmt_tick(series.vmax))
  buf[#buf + 1] = string.format(
    '   <text x="%s" y="%s" font-size="10" text-anchor="start">%s</text>',
    util.fmt(x + 22), util.fmt(y + height), util.fmt_tick(series.vmin))
  buf[#buf + 1] = '  </g>'
end

local function render_reference(series, map_x, map_y, geom, buf)
  local style = series.style
  local dash = ""
  if style.linestyle == "dashed" then dash = ' stroke-dasharray="6 4"'
  elseif style.linestyle == "dotted" then dash = ' stroke-dasharray="1.5 3"' end
  local opacity = style.alpha < 1 and
    string.format(' stroke-opacity="%s"', util.fmt(style.alpha)) or ""
  local label = style.label and
    string.format(' data-label="%s"', attribute(style.label)) or ""
  buf[#buf + 1] = string.format('  <g class="series series-%s"%s>',
    series.kind, label)
  if series.kind == "axhline" then
    local y = map_y(series.y)
    buf[#buf + 1] = string.format(
      '   <line class="reference" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s%s/>',
      util.fmt(geom.left), util.fmt(y), util.fmt(geom.right), util.fmt(y),
      style.color, util.fmt(style.linewidth), dash, opacity)
  else
    local x = map_x(series.x)
    buf[#buf + 1] = string.format(
      '   <line class="reference" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s%s/>',
      util.fmt(x), util.fmt(geom.top), util.fmt(x), util.fmt(geom.bottom),
      style.color, util.fmt(style.linewidth), dash, opacity)
  end
  buf[#buf + 1] = '  </g>'
end

local function render_line(series, map_x, map_y, buf)
  local style = series.style
  local color = style.color
  local opacity = ""
  if style.alpha < 1 then
    opacity = string.format(' stroke-opacity="%s"', util.fmt(style.alpha))
  end

  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', attribute(style.label))
  end
  buf[#buf + 1] = string.format('  <g class="series series-line"%s>', label)

  local draw_line = style.linestyle ~= "none"
  if draw_line then
    local points = {}
    for i = 1, #series.x do
      points[i] = util.fmt(map_x(series.x[i])) .. "," .. util.fmt(map_y(series.y[i]))
    end
    local dash = ""
    if style.linestyle == "dashed" then
      dash = ' stroke-dasharray="6 4"'
    elseif style.linestyle == "dotted" then
      dash = ' stroke-dasharray="1.5 3"'
    end
    buf[#buf + 1] = string.format(
      '   <polyline class="line" points="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"%s%s/>',
      table.concat(points, " "), color, util.fmt(style.linewidth), dash, opacity)
  end

  local draw_marker = style.marker ~= nil or (#series.x == 1 and draw_line)
  if draw_marker then
    local marker_opacity = ""
    if style.alpha < 1 then
      marker_opacity = string.format(' fill-opacity="%s"', util.fmt(style.alpha))
    end
    for i = 1, #series.x do
      buf[#buf + 1] = string.format(
        '   <circle class="marker" cx="%s" cy="%s" r="%s" fill="%s"%s/>',
        util.fmt(map_x(series.x[i])), util.fmt(map_y(series.y[i])),
        util.fmt(style.markersize), color, marker_opacity)
    end
  end

  buf[#buf + 1] = '  </g>'
end

local function render_scatter(series, map_x, map_y, buf)
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
    label = string.format(' data-label="%s"', attribute(style.label))
  end

  buf[#buf + 1] = string.format('  <g class="series series-scatter"%s>', label)
  for i = 1, #series.x do
    buf[#buf + 1] = string.format(
      '   <circle class="point" cx="%s" cy="%s" r="%s" fill="%s"%s%s/>',
      util.fmt(map_x(series.x[i])), util.fmt(map_y(series.y[i])),
      util.fmt(style.radius), style.color, fade, outline)
  end
  buf[#buf + 1] = '  </g>'
end

local function render_errorbar(series, map_x, map_y, buf)
  local style = series.style
  local cap = style.capsize or 4
  local width = style.elinewidth or 1
  local color = style.ecolor or style.color
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', attribute(style.label))
  end
  buf[#buf + 1] = string.format('  <g class="series series-errorbar"%s>', label)
  for i = 1, #series.x do
    local x = map_x(series.x[i])
    local y = series.y[i]
    local top = map_y(y + series.yerr[i])
    local bottom = map_y(y - series.yerr[i])
    buf[#buf + 1] = string.format(
      '   <line class="errorbar" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
      util.fmt(x), util.fmt(top), util.fmt(x), util.fmt(bottom), color,
      util.fmt(width))
    buf[#buf + 1] = string.format(
      '   <line class="errorbar-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
      util.fmt(x - cap), util.fmt(top), util.fmt(x + cap), util.fmt(top),
      color, util.fmt(width))
    buf[#buf + 1] = string.format(
      '   <line class="errorbar-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
      util.fmt(x - cap), util.fmt(bottom), util.fmt(x + cap), util.fmt(bottom),
      color, util.fmt(width))
    if series.xerr then
      local left = map_x(series.x[i] - series.xerr[i])
      local right = map_x(series.x[i] + series.xerr[i])
      local center = map_y(y)
      buf[#buf + 1] = string.format(
        '   <line class="errorbar" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
        util.fmt(left), util.fmt(center), util.fmt(right), util.fmt(center),
        color, util.fmt(width))
      buf[#buf + 1] = string.format(
        '   <line class="errorbar-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
        util.fmt(left), util.fmt(center - cap), util.fmt(left),
        util.fmt(center + cap), color, util.fmt(width))
      buf[#buf + 1] = string.format(
        '   <line class="errorbar-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
        util.fmt(right), util.fmt(center - cap), util.fmt(right),
        util.fmt(center + cap), color, util.fmt(width))
    end
  end
  buf[#buf + 1] = '  </g>'
  render_line(series, map_x, map_y, buf)
end

local function render_hist(series, map_x, map_y, baseline, buf)
  local style = series.style
  local opacity = ""
  if style.alpha < 1 then
    local a = util.fmt(style.alpha)
    opacity = string.format(' fill-opacity="%s" stroke-opacity="%s"', a, a)
  end
  local edge = style.edgecolor or "#ffffff"
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', attribute(style.label))
  end

  buf[#buf + 1] = string.format('  <g class="series series-hist"%s>', label)
  for i = 1, #series.counts do
    local count = series.counts[i]
    if count > 0 then
      local x1 = map_x(series.edges[i])
      local x2 = map_x(series.edges[i + 1])
      local top = map_y(count)
      buf[#buf + 1] = string.format(
        '   <rect class="hist-bin" x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="%s" stroke-width="1"%s/>',
        util.fmt(x1), util.fmt(top), util.fmt(x2 - x1), util.fmt(baseline - top),
        style.color, edge, opacity)
    end
  end
  buf[#buf + 1] = '  </g>'
end

local function render_barh(series, map_x, map_y, baseline, buf)
  local style = series.style
  local opacity = ""
  if style.alpha < 1 then
    local a = util.fmt(style.alpha)
    opacity = string.format(' fill-opacity="%s" stroke-opacity="%s"', a, a)
  end
  local edge = style.edgecolor or "#ffffff"
  buf[#buf + 1] = '  <g class="series series-barh">'
  for i = 1, #series.x do
    local value = series.x[i]
    local center = map_y(series.y[i])
    local top = center - math.abs(map_y(series.y[i] + series.height / 2) -
      map_y(series.y[i] - series.height / 2)) / 2
    local height = math.abs(map_y(series.y[i] + series.height / 2) -
      map_y(series.y[i] - series.height / 2))
    local value_x = map_x(value)
    local left = math.min(baseline, value_x)
    local width = math.abs(value_x - baseline)
    local fill = series.bar_colors and series.bar_colors[i] or style.color
    buf[#buf + 1] = string.format(
      '   <rect class="barh" x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="%s" stroke-width="1"%s/>',
      util.fmt(left), util.fmt(top), util.fmt(width), util.fmt(height), fill,
      edge, opacity)
    if series.show_values then
      local text_x = value >= 0 and (value_x + 4) or (value_x - 4)
      local anchor = value >= 0 and "start" or "end"
      buf[#buf + 1] = string.format(
        '   <text class="barh-value" x="%s" y="%s" font-size="10" text-anchor="%s" fill="%s">%s</text>',
        util.fmt(text_x), util.fmt(center + 3), anchor, TEXT_COLOR,
        util.fmt_tick(value))
    end
  end
  buf[#buf + 1] = '  </g>'
end

local function render_fill(series, map_x, map_y, buf)
  local style = series.style
  local opacity = ""
  if style.alpha < 1 then opacity = string.format(' fill-opacity="%s"',
    util.fmt(style.alpha)) end
  local points = {}
  for i = 1, #series.x do
    points[#points + 1] = string.format("%s,%s", util.fmt(map_x(series.x[i])),
      util.fmt(map_y(series.y1[i])))
  end
  for i = #series.x, 1, -1 do
    points[#points + 1] = string.format("%s,%s", util.fmt(map_x(series.x[i])),
      util.fmt(map_y(series.y2[i])))
  end
  buf[#buf + 1] = string.format(
    '  <polygon class="fill-between" points="%s" fill="%s"%s stroke="%s" stroke-width="1"/>',
    table.concat(points, " "), style.color, opacity,
    style.edgecolor or style.color)
end

local function render_fillx(series, map_x, map_y, buf)
  local points = {}
  for i = 1, #series.y do
    points[#points + 1] = string.format("%s,%s", util.fmt(map_x(series.x1[i])),
      util.fmt(map_y(series.y[i])))
  end
  for i = #series.y, 1, -1 do
    points[#points + 1] = string.format("%s,%s", util.fmt(map_x(series.x2[i])),
      util.fmt(map_y(series.y[i])))
  end
  buf[#buf + 1] = string.format(
    '  <polygon class="fill-betweenx" points="%s" fill="%s" fill-opacity="%s" stroke="%s" stroke-width="1"/>',
    table.concat(points, " "), series.style.color, util.fmt(series.style.alpha),
    series.style.edgecolor or series.style.color)
end

local function render_step(series, map_x, map_y, buf)
  local xs, ys = {}, {}
  for i = 1, #series.x do
    if i > 1 then
      if series.where == "pre" then
        xs[#xs + 1] = series.x[i]
        ys[#ys + 1] = series.y[i - 1]
      elseif series.where == "post" then
        xs[#xs + 1] = series.x[i - 1]
        ys[#ys + 1] = series.y[i]
      else
        local mid = (series.x[i - 1] + series.x[i]) / 2
        xs[#xs + 1] = mid
        ys[#ys + 1] = series.y[i - 1]
        xs[#xs + 1] = mid
        ys[#ys + 1] = series.y[i]
      end
    end
    xs[#xs + 1] = series.x[i]
    ys[#ys + 1] = series.y[i]
  end
  buf[#buf + 1] = '  <g class="series series-step">'
  render_line({ x = xs, y = ys, style = series.style, kind = "line" },
    map_x, map_y, buf)
  buf[#buf + 1] = '  </g>' 
end

local function render_stem(series, map_x, map_y, buf)
  local baseline = map_y(0)
  for i = 1, #series.x do
    local x = map_x(series.x[i])
    local y = map_y(series.y[i])
    buf[#buf + 1] = string.format(
      '  <line class="stem-line" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
      util.fmt(x), util.fmt(baseline), util.fmt(x), util.fmt(y),
      series.style.color, util.fmt(series.style.linewidth or 1.5))
    buf[#buf + 1] = string.format(
      '  <circle class="stem-marker" cx="%s" cy="%s" r="%s" fill="%s"/>',
      util.fmt(x), util.fmt(y), util.fmt(series.style.markersize or 4),
      series.style.color)
  end
end

local function render_contour(series, map_x, map_y, buf)
  buf[#buf + 1] = '  <g class="contour">'
  for _, segment in ipairs(series.segments) do
    buf[#buf + 1] = string.format(
      '   <line class="contour-segment" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
      util.fmt(map_x(segment[1])), util.fmt(map_y(segment[2])),
      util.fmt(map_x(segment[3])), util.fmt(map_y(segment[4])),
      series.style.color, util.fmt(series.style.linewidth))
  end
  buf[#buf + 1] = '  </g>'
end

local function render_box(series, map_x, map_y, buf)
  local color = series.style.color
  local half = series.width / 2
  local left = series.position - half
  local right = series.position + half
  local x = map_x(series.position)
  local top = map_y(series.q3)
  local bottom = map_y(series.q1)
  buf[#buf + 1] = string.format(
    '  <rect class="box" x="%s" y="%s" width="%s" height="%s" fill="%s" fill-opacity="0.25" stroke="%s" stroke-width="1.5"/>',
    util.fmt(map_x(left)), util.fmt(top),
    util.fmt(math.abs(map_x(right) - map_x(left))),
    util.fmt(math.abs(bottom - top)), color, color)
  buf[#buf + 1] = string.format(
    '  <line class="box-median" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
    util.fmt(map_x(left)), util.fmt(map_y(series.median)),
    util.fmt(map_x(right)), util.fmt(map_y(series.median)), color)
  buf[#buf + 1] = string.format(
    '  <line class="box-whisker" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5"/>',
    util.fmt(x), util.fmt(map_y(series.q3)), util.fmt(x),
    util.fmt(map_y(series.high)), color)
  buf[#buf + 1] = string.format(
    '  <line class="box-whisker" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5"/>',
    util.fmt(x), util.fmt(map_y(series.q1)), util.fmt(x),
    util.fmt(map_y(series.low)), color)
  buf[#buf + 1] = string.format(
    '  <line class="box-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
    util.fmt(map_x(left + 0.1)), util.fmt(map_y(series.high)),
    util.fmt(map_x(right - 0.1)), util.fmt(map_y(series.high)), color)
  buf[#buf + 1] = string.format(
    '  <line class="box-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
    util.fmt(map_x(left + 0.1)), util.fmt(map_y(series.low)),
    util.fmt(map_x(right - 0.1)), util.fmt(map_y(series.low)), color)
  for _, value in ipairs(series.outliers) do
    buf[#buf + 1] = string.format(
      '  <circle class="box-outlier" cx="%s" cy="%s" r="3" fill="none" stroke="%s" stroke-width="1.5"/>',
      util.fmt(x), util.fmt(map_y(value)), color)
  end
end

local function render_bar(series, map_x, map_y, baseline, yscale, buf)
  local style = series.style
  local opacity = ""
  if style.alpha < 1 then
    local a = util.fmt(style.alpha)
    opacity = string.format(' fill-opacity="%s" stroke-opacity="%s"', a, a)
  end
  local edge = style.edgecolor or "#ffffff"
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', attribute(style.label))
  end

  local offset = series.offset or 0
  buf[#buf + 1] = string.format('  <g class="series series-bar"%s>', label)
  for i = 1, #series.x do
    local value = series.y[i]
    local x1 = map_x(series.x[i] + offset - series.width / 2)
    local x2 = map_x(series.x[i] + offset + series.width / 2)
    local base_y
    local value_y
    if series.bottom ~= nil then
      local bottom = series.bottom[i]
      if yscale == "log" and bottom <= 0 then
        base_y = baseline
      else
        base_y = map_y(bottom)
      end
      value_y = map_y(bottom + value)
    else
      base_y = baseline
      value_y = map_y(value)
    end
    local top = math.min(base_y, value_y)
    local height = math.abs(base_y - value_y)
    local fill = series.bar_colors and series.bar_colors[i] or style.color
    buf[#buf + 1] = string.format(
      '   <rect class="bar" x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="%s" stroke-width="1"%s/>',
      util.fmt(x1), util.fmt(top), util.fmt(x2 - x1), util.fmt(height),
      fill, edge, opacity)
    if series.show_values then
      local center_x = (x1 + x2) / 2
      local value_y = value_y or top
      local text_y = top - 4
      if top > base_y then text_y = top + 14 end
      buf[#buf + 1] = string.format(
        '   <text class="bar-value" x="%s" y="%s" font-size="10" text-anchor="middle" fill="%s">%s</text>',
        util.fmt(center_x), util.fmt(text_y), TEXT_COLOR,
        util.fmt_tick(value))
    end
  end
  buf[#buf + 1] = '  </g>'
end

local ANNOTATION_ANCHORS = {
  left = "start",
  center = "middle",
  right = "end",
}

local function check_annotation_positive(value, axis, annotation)
  if value <= 0 then
    util.fail(string.format(
      "%s axis uses a log scale but annotation %q has non-positive %s value %s; " ..
      "log scales require strictly positive values",
      axis, annotation.text or "", axis, util.fmt_tick(value)), 3)
  end
end

local function render_annotation(annotation, index, map_x, map_y, xscale, yscale, buf)
  local xscale_is_log = xscale == "log"
  local yscale_is_log = yscale == "log"
  if xscale_is_log then
    check_annotation_positive(annotation.x, "x", annotation)
    if annotation.xytext ~= nil then
      check_annotation_positive(annotation.xytext[1], "x", annotation)
    end
  end
  if yscale_is_log then
    check_annotation_positive(annotation.y, "y", annotation)
    if annotation.xytext ~= nil then
      check_annotation_positive(annotation.xytext[2], "y", annotation)
    end
  end

  local target_x = map_x(annotation.x)
  local target_y = map_y(annotation.y)
  local text_x, text_y
  if annotation.xytext ~= nil then
    text_x = map_x(annotation.xytext[1])
    text_y = map_y(annotation.xytext[2])
  elseif annotation.arrow ~= nil then
    -- With no explicit text position, offset the label so the leader line is
    -- visible instead of collapsing to a zero-length segment.
    text_x, text_y = target_x + 12, target_y - 12
  else
    text_x, text_y = target_x, target_y
  end

  local color = annotation.color or TEXT_COLOR
  local fontsize = annotation.fontsize or 12
  local align = annotation.align or "left"
  local anchor = ANNOTATION_ANCHORS[align] or "start"

  buf[#buf + 1] = string.format('   <g class="annotation" data-index="%d">', index)
  if annotation.arrow ~= nil then
    local dx = target_x - text_x
    local dy = target_y - text_y
    local length = math.sqrt(dx * dx + dy * dy)
    if length > 0.0005 then
      local arrow = annotation.arrow
      buf[#buf + 1] = string.format(
        '    <line class="annotation-arrow" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"/>',
        util.fmt(text_x), util.fmt(text_y), util.fmt(target_x), util.fmt(target_y),
        arrow.color or color, util.fmt(arrow.linewidth or 1.5))
      local head = arrow.head or 8
      if head > 0 then
        if head > length then head = length end
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
    util.fmt(text_x), util.fmt(text_y), util.fmt(fontsize), color, anchor, align,
    util.escape_xml(annotation.text))
  buf[#buf + 1] = '   </g>'
end

local function pie_point(cx, cy, radius, degrees)
  local radians = math.rad(degrees)
  return cx + radius * math.cos(radians), cy - radius * math.sin(radians)
end

function M.to_pie_svg(fig)
  local pie = fig._pie
  local width, height = fig.width, fig.height
  local cx, cy = width * 0.42, height / 2 + 8
  local radius = math.min(width, height) * pie.radius * 1.55
  local inner = radius * pie.inner_radius
  local buf = {}
  local function add(line) buf[#buf + 1] = line end
  add('<?xml version="1.0" encoding="UTF-8"?>')
  add(string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" version="1.1" data-dpi="%s" data-pie="true">',
    util.fmt(width), util.fmt(height), util.fmt(width), util.fmt(height),
    util.fmt(fig.dpi)))
  add(' <desc>Generated by luaplotlib, a pure-Lua SVG plotting library.</desc>')
  add(' <rect class="background" width="' .. util.fmt(width) .. '" height="' ..
    util.fmt(height) .. '" fill="#ffffff"/>')
  if fig._title ~= nil then
    add(string.format(' <text class="title" x="%s" y="28" font-size="18" fill="#222222" text-anchor="middle">%s</text>',
      util.fmt(cx), util.escape_xml(fig._title)))
  end
  add(' <g class="pie" font-family="Helvetica, Arial, sans-serif">')
  for index, slice in ipairs(pie.slices) do
    if slice.end_angle < slice.start_angle then
      local sweep = slice.start_angle - slice.end_angle
      local x1, y1 = pie_point(cx, cy, radius, slice.start_angle)
      local x2, y2 = pie_point(cx, cy, radius, slice.end_angle)
      local large = sweep > 180 and 1 or 0
      add(string.format('  <path class="pie-slice" d="M %s %s L %s %s A %s %s 0 %d 1 %s %s Z" fill="%s" stroke="#ffffff" stroke-width="1.5"/>',
        util.fmt(cx), util.fmt(cy), util.fmt(x1), util.fmt(y1),
        util.fmt(radius), util.fmt(radius), large, util.fmt(x2), util.fmt(y2),
        slice.color))
      local middle = (slice.start_angle + slice.end_angle) / 2
      if pie.autopct then
        local tx, ty = pie_point(cx, cy, radius * 0.64, middle)
        local format_string = pie.autopct == true and "%.1f%%" or pie.autopct
        local ok, text = pcall(string.format, format_string, slice.percent)
        if not ok then text = string.format("%.1f%%", slice.percent) end
        add(string.format('  <text class="pie-percent" x="%s" y="%s" font-size="12" fill="#ffffff" text-anchor="middle">%s</text>',
          util.fmt(tx), util.fmt(ty + 4), util.escape_xml(text)))
      end
      local lx, ly = pie_point(cx, cy, radius * 1.08, middle)
      local edge_x, edge_y = pie_point(cx, cy, radius, middle)
      add(string.format('  <line class="pie-label-line" x1="%s" y1="%s" x2="%s" y2="%s" stroke="#777777" stroke-width="1"/>',
        util.fmt(edge_x), util.fmt(edge_y), util.fmt(lx), util.fmt(ly)))
      local anchor = math.cos(math.rad(middle)) >= 0 and "start" or "end"
      add(string.format('  <text class="pie-label" x="%s" y="%s" font-size="12" fill="#222222" text-anchor="%s">%s</text>',
        util.fmt(lx), util.fmt(ly + 4), anchor, util.escape_xml(slice.label)))
    end
  end
  if inner > 0 then
    add(string.format('  <circle class="pie-inner" cx="%s" cy="%s" r="%s" fill="#ffffff"/>',
      util.fmt(cx), util.fmt(cy), util.fmt(inner)))
  end
  add(' </g>')
  if pie.legend then
    local x = width - 180
    local y = 58
    add(' <g class="legend">')
    for index, slice in ipairs(pie.slices) do
      local entry_y = y + (index - 1) * 20
      add(string.format('  <rect x="%s" y="%s" width="12" height="12" fill="%s"/>',
        util.fmt(x), util.fmt(entry_y - 10), slice.color))
      add(string.format('  <text x="%s" y="%s" font-size="12" fill="#222222">%s (%.1f%%)</text>',
        util.fmt(x + 18), util.fmt(entry_y), util.escape_xml(slice.label),
        slice.percent))
    end
    add(' </g>')
  end
  add('</svg>')
  return table.concat(buf, "\n") .. "\n"
end

function M.data_extents(fig, xscale, yscale)
  return data_extents(fig, xscale or "linear", yscale or "linear")
end

function M.to_svg(fig)
  if fig._pie ~= nil then return M.to_pie_svg(fig) end
  local geom = layout(fig)
  local xscale = fig._xscale or "linear"
  local yscale = fig._yscale or "linear"
  local extents = data_extents(fig, xscale, yscale)
  local twin = fig._twin
  local twiny = fig._twiny
  local twiny_extents = twiny and data_extents(twiny,
    twiny._xscale or "linear", yscale) or nil
  if twiny_extents ~= nil then
    if extents == nil then extents = twiny_extents
    else
      if twiny_extents.has_y then
        extents.has_y = true
        if extents.min_y == nil or twiny_extents.min_y < extents.min_y then
          extents.min_y = twiny_extents.min_y
        end
        if extents.max_y == nil or twiny_extents.max_y > extents.max_y then
          extents.max_y = twiny_extents.max_y
        end
      end
    end
  end
  local twin_extents = twin and data_extents(twin, xscale,
    twin._yscale or "linear") or nil
  if twin_extents ~= nil then
    if extents == nil then
      extents = twin_extents
    else
      if twin_extents.has_x then
        extents.has_x = true
        if extents.min_x == nil or twin_extents.min_x < extents.min_x then
          extents.min_x = twin_extents.min_x
        end
        if extents.max_x == nil or twin_extents.max_x > extents.max_x then
          extents.max_x = twin_extents.max_x
        end
      end
    end
  end
  local x_target, y_target = tick_count(geom.plot_width, geom.plot_height)

  local xaxis = make_axis("xlim", xscale, fig._xlim,
    extents and extents.has_x and extents.min_x or nil,
    extents and extents.has_x and extents.max_x or nil,
    x_target, false, 0, 1)
  local yaxis = make_axis("ylim", yscale, fig._ylim,
    extents and extents.has_y and extents.min_y or nil,
    extents and extents.has_y and extents.max_y or nil,
    y_target, extents and extents.baseline_y or false, 0, 1)

  local twiny_xaxis
  if twiny ~= nil then
    twiny_xaxis = make_axis("twin xlim", twiny._xscale or "linear",
      twiny._xlim,
      twiny_extents and twiny_extents.has_x and twiny_extents.min_x or nil,
      twiny_extents and twiny_extents.has_x and twiny_extents.max_x or nil,
      x_target, false, 0, 1)
  end

  local twin_yaxis
  if twin ~= nil then
    twin_yaxis = make_axis("twin ylim", twin._yscale or "linear", twin._ylim,
      twin_extents and twin_extents.has_y and twin_extents.min_y or nil,
      twin_extents and twin_extents.has_y and twin_extents.max_y or nil,
      y_target, twin_extents and twin_extents.baseline_y or false, 0, 1)
  end

  local xmin, xmax = xaxis.data_minimum, xaxis.data_maximum
  local xticks = xaxis.ticks
  local yticks = yaxis.ticks

  local categories = find_category_ticks(fig, xmin, xmax)
  local function format_value(fig_value, formatter)
    if formatter ~= nil then
      local ok, text = pcall(formatter, fig_value)
      if not ok then util.fail("tick formatter failed: " .. tostring(text), 3) end
      return tostring(text)
    end
    return util.fmt_tick(fig_value)
  end
  local function format_x(fig_value)
    if fig._xdate_format ~= nil then
      local ok, text = pcall(os.date, fig._xdate_format, math.floor(fig_value))
      if not ok then util.fail("xdate formatting failed: " .. tostring(text), 3) end
      return text
    end
    return format_value(fig_value, fig._xtick_format)
  end
  local x_display = {}
  if categories then
    for _, category in ipairs(categories) do
      x_display[#x_display + 1] = {
        value = category.position,
        label = category.label,
      }
    end
  elseif fig._xticks ~= nil then
    for index, value in ipairs(fig._xticks.values) do
      x_display[#x_display + 1] = {
        value = value,
        label = fig._xticks.labels and fig._xticks.labels[index] or
          format_x(value),
      }
    end
  else
    for _, value in ipairs(xticks) do
      x_display[#x_display + 1] = {
        value = value, label = format_x(value),
      }
    end
  end
  local y_display = {}
  if fig._yticks ~= nil then
    for index, value in ipairs(fig._yticks.values) do
      y_display[#y_display + 1] = {
        value = value,
        label = fig._yticks.labels and fig._yticks.labels[index] or
          format_value(value, fig._ytick_format),
      }
    end
  else
    for _, value in ipairs(yticks) do
      y_display[#y_display + 1] = {
        value = value, label = format_value(value, fig._ytick_format),
      }
    end
  end

  local twin_y_display = {}
  if twin_yaxis ~= nil then
    for _, value in ipairs(twin_yaxis.ticks) do
      twin_y_display[#twin_y_display + 1] = {
        value = value, label = format_value(value, twin._ytick_format),
      }
    end
  end

  local function map_x(value)
    -- Bar edges derived from a positive position can cross zero. Clamp that
    -- geometry to the left edge of a log plot instead of taking log10(<= 0).
    if xscale == "log" and value <= 0 then
      return geom.left
    end
    local transformed = xaxis.to_axis(value)
    return geom.left +
      (transformed - xaxis.minimum) / (xaxis.maximum - xaxis.minimum) * geom.plot_width
  end

  local function map_x2(value)
    if (twiny._xscale or "linear") == "log" and value <= 0 then
      return geom.left
    end
    local transformed = twiny_xaxis.to_axis(value)
    return geom.left + (transformed - twiny_xaxis.minimum) /
      (twiny_xaxis.maximum - twiny_xaxis.minimum) * geom.plot_width
  end

  local function map_y(value)
    local transformed = yaxis.to_axis(value)
    return geom.bottom -
      (transformed - yaxis.minimum) / (yaxis.maximum - yaxis.minimum) * geom.plot_height
  end

  local function map_y2(value)
    local transformed = twin_yaxis.to_axis(value)
    return geom.bottom -
      (transformed - twin_yaxis.minimum) /
      (twin_yaxis.maximum - twin_yaxis.minimum) * geom.plot_height
  end

  -- A log y axis has no zero baseline; bars and histogram bins grow from the
  -- bottom of the visible plot area instead.
  local y_baseline = geom.bottom
  if yscale ~= "log" then
    y_baseline = map_y(0)
  end

  local buf = {}
  local function add(line)
    buf[#buf + 1] = line
  end
  local function printf(format, ...)
    buf[#buf + 1] = string.format(format, ...)
  end

  local clip_id = "luaplotlib-plot-clip-" .. tostring(fig):gsub("%W", "")

  add('<?xml version="1.0" encoding="UTF-8"?>')
  printf('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" version="1.1" role="img" aria-label="%s" data-dpi="%s" data-xscale="%s" data-yscale="%s">',
    util.fmt(fig.width), util.fmt(fig.height),
    util.fmt(fig.width), util.fmt(fig.height),
    util.escape_xml(fig._aria_label or fig._title or "luaplotlib figure"),
    util.fmt(fig.dpi), util.escape_xml(xscale), util.escape_xml(yscale))
  add(' <title>' .. util.escape_xml(fig._title or "luaplotlib figure") .. '</title>')
  add(' <desc>Generated by luaplotlib, a pure-Lua SVG plotting library.</desc>')
  printf(' <rect class="background" x="0" y="0" width="%s" height="%s" fill="%s"/>',
    util.fmt(fig.width), util.fmt(fig.height), fig._facecolor or "#ffffff")
  add(' <defs>')
  printf('  <clipPath id="%s"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath>',
    clip_id, util.fmt(geom.left), util.fmt(geom.top),
    util.fmt(geom.plot_width), util.fmt(geom.plot_height))
  add(' </defs>')
  add(' <g class="figure" font-family="' .. FONT_FAMILY .. '" font-size="12" fill="' .. TEXT_COLOR .. '">')

  if fig._grid then
    local grid_opts = fig._grid_opts or {}
    local dash = ""
    if grid_opts.linestyle == "dashed" then dash = ' stroke-dasharray="6 4"'
    elseif grid_opts.linestyle == "dotted" then dash = ' stroke-dasharray="2 3"' end
    add('  <g class="grid" stroke="' .. (grid_opts.color or GRID_COLOR) ..
      '" stroke-width="' .. util.fmt(grid_opts.linewidth or 1) .. '"' .. dash .. '>')
    local grid_axis = grid_opts.axis or "both"
    if grid_axis ~= "y" then
      for _, tick in ipairs(x_display) do
        local x = map_x(tick.value)
        printf('   <line x1="%s" y1="%s" x2="%s" y2="%s"/>',
          util.fmt(x), util.fmt(geom.top), util.fmt(x), util.fmt(geom.bottom))
      end
    end
    if grid_axis ~= "x" then
      for _, tick in ipairs(y_display) do
        local y = map_y(tick.value)
        printf('   <line x1="%s" y1="%s" x2="%s" y2="%s"/>',
          util.fmt(geom.left), util.fmt(y), util.fmt(geom.right), util.fmt(y))
      end
    end
    add('  </g>')
  end

  add('  <g class="series-layer" clip-path="url(#' .. clip_id .. ')">')
  for _, series in ipairs(fig._series) do
    if series.kind == "image" then
      render_image(series, map_x, map_y, buf)
    elseif series.kind == "axhline" or series.kind == "axvline" then
      render_reference(series, map_x, map_y, geom, buf)
    elseif series.kind == "line" then
      render_line(series, map_x, map_y, buf)
    elseif series.kind == "scatter" then
      render_scatter(series, map_x, map_y, buf)
    elseif series.kind == "hist" then
      render_hist(series, map_x, map_y, y_baseline, buf)
    elseif series.kind == "bar" then
      render_bar(series, map_x, map_y, y_baseline, yscale, buf)
    elseif series.kind == "fill" then
      render_fill(series, map_x, map_y, buf)
    elseif series.kind == "fillx" then
      render_fillx(series, map_x, map_y, buf)
    elseif series.kind == "step" then
      render_step(series, map_x, map_y, buf)
    elseif series.kind == "stem" then
      render_stem(series, map_x, map_y, buf)
    elseif series.kind == "barh" then
      render_barh(series, map_x, map_y, map_x(0), buf)
    elseif series.kind == "contour" then
      render_contour(series, map_x, map_y, buf)
    elseif series.kind == "box" then
      render_box(series, map_x, map_y, buf)
    elseif series.kind == "errorbar" then
      render_errorbar(series, map_x, map_y, buf)
    end
  end
  add('  </g>')

  if twin ~= nil then
    add('  <g class="series-layer twin-series" clip-path="url(#' .. clip_id .. ')">')
    for _, series in ipairs(twin._series) do
      if series.kind == "line" then
        render_line(series, map_x, map_y2, buf)
      elseif series.kind == "scatter" then
        render_scatter(series, map_x, map_y2, buf)
      elseif series.kind == "errorbar" then
        render_errorbar(series, map_x, map_y2, buf)
      elseif series.kind == "bar" then
        local baseline = geom.bottom
        if (twin._yscale or "linear") ~= "log" then baseline = map_y2(0) end
        render_bar(series, map_x, map_y2, baseline, twin._yscale, buf)
      end
    end
    add('  </g>')
  end

  if twiny ~= nil then
    add('  <g class="series-layer twiny-series" clip-path="url(#' .. clip_id .. ')">')
    for _, series in ipairs(twiny._series) do
      if series.kind == "line" then
        render_line(series, map_x2, map_y, buf)
      elseif series.kind == "scatter" then
        render_scatter(series, map_x2, map_y, buf)
      elseif series.kind == "errorbar" then
        render_errorbar(series, map_x2, map_y, buf)
      end
    end
    add('  </g>')
  end

  if #(fig._annotations or {}) > 0 then
    add('  <g class="annotation-layer" clip-path="url(#' .. clip_id .. ')">')
    for index, annotation in ipairs(fig._annotations) do
      render_annotation(annotation, index, map_x, map_y, xscale, yscale, buf)
    end
    add('  </g>')
  end

  if twin ~= nil then
    add('  <g class="twin-axis">')
    printf('   <path class="spine" d="M %s %s L %s %s" fill="none" stroke="%s" stroke-width="1"/>',
      util.fmt(geom.right), util.fmt(geom.top), util.fmt(geom.right),
      util.fmt(geom.bottom), AXIS_COLOR)
    for _, tick in ipairs(twin_y_display) do
      local y = map_y2(tick.value)
      printf('   <line class="tick-mark" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',
        util.fmt(geom.right), util.fmt(y), util.fmt(geom.right + 5),
        util.fmt(y), AXIS_COLOR)
      printf('   <text class="tick-label" x="%s" y="%s" font-size="11" fill="%s" text-anchor="start">%s</text>',
        util.fmt(geom.right + 9), util.fmt(y + 4), TEXT_COLOR,
        util.escape_xml(tick.label))
    end
    if twin._ylabel ~= nil then
      local center_y = geom.top + geom.plot_height / 2
      local x = geom.width - 14
      printf('   <text class="ylabel" x="%s" y="%s" font-size="13" fill="%s" text-anchor="middle" transform="rotate(90 %s %s)">%s</text>',
        util.fmt(x), util.fmt(center_y), TEXT_COLOR, util.fmt(x),
        util.fmt(center_y), util.escape_xml(twin._ylabel))
    end
    add('  </g>')
  end

  if twiny ~= nil then
    add('  <g class="twiny-axis">')
    printf('   <path class="spine" d="M %s %s L %s %s" fill="none" stroke="%s" stroke-width="1"/>',
      util.fmt(geom.left), util.fmt(geom.top), util.fmt(geom.right),
      util.fmt(geom.top), AXIS_COLOR)
    for _, value in ipairs(twiny_xaxis.ticks) do
      local x = map_x2(value)
      printf('   <line class="tick-mark" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',
        util.fmt(x), util.fmt(geom.top), util.fmt(x), util.fmt(geom.top - 5),
        AXIS_COLOR)
      local label = format_value(value, twiny._xtick_format)
      printf('   <text class="tick-label" x="%s" y="%s" font-size="11" fill="%s" text-anchor="middle">%s</text>',
        util.fmt(x), util.fmt(geom.top - 9), TEXT_COLOR,
        util.escape_xml(label))
    end
    if twiny._xlabel ~= nil then
      printf('   <text class="xlabel" x="%s" y="%s" font-size="13" fill="%s" text-anchor="middle">%s</text>',
        util.fmt(geom.left + geom.plot_width / 2), util.fmt(14),
        TEXT_COLOR, util.escape_xml(twiny._xlabel))
    end
    add('  </g>')
  end

  add('  <g class="axes">')
  printf('   <path class="spine" d="M %s %s L %s %s L %s %s" fill="none" stroke="%s" stroke-width="1"/>',
    util.fmt(geom.left), util.fmt(geom.top), util.fmt(geom.left),
    util.fmt(geom.bottom), util.fmt(geom.right), util.fmt(geom.bottom), AXIS_COLOR)

  add('   <g class="ticks x-ticks">')
  for _, tick in ipairs(x_display) do
    local x = map_x(tick.value)
    printf('    <line class="tick-mark" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',
      util.fmt(x), util.fmt(geom.bottom), util.fmt(x), util.fmt(geom.bottom + 5), AXIS_COLOR)
    local rotation = fig._xtick_rotation or 0
    local transform = ""
    local anchor = "middle"
    if rotation ~= 0 then
      transform = string.format(' transform="rotate(%d %s %s)"', rotation,
        util.fmt(x), util.fmt(geom.bottom + 19))
      anchor = rotation > 0 and "end" or "start"
    end
    printf('    <text class="tick-label" x="%s" y="%s" font-size="11" fill="%s" text-anchor="%s"%s>%s</text>',
      util.fmt(x), util.fmt(geom.bottom + 19), TEXT_COLOR, anchor, transform,
      util.escape_xml(tick.label))
  end
  add('   </g>')

  add('   <g class="ticks y-ticks">')
  for _, tick in ipairs(y_display) do
    local y = map_y(tick.value)
    printf('    <line class="tick-mark" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',
      util.fmt(geom.left - 5), util.fmt(y), util.fmt(geom.left), util.fmt(y), AXIS_COLOR)
    printf('    <text class="tick-label" x="%s" y="%s" font-size="11" fill="%s" text-anchor="end">%s</text>',
      util.fmt(geom.left - 9), util.fmt(y + 4), TEXT_COLOR,
      util.escape_xml(tick.label))
  end
  add('   </g>')

  if fig._xlabel ~= nil then
    printf('   <text class="xlabel" x="%s" y="%s" font-size="13" fill="%s" text-anchor="middle">%s</text>',
      util.fmt(geom.left + geom.plot_width / 2), util.fmt(geom.height - 14),
      TEXT_COLOR, util.escape_xml(fig._xlabel))
  end

  if fig._ylabel ~= nil then
    local center_y = geom.top + geom.plot_height / 2
    local x = 18
    printf('   <text class="ylabel" x="%s" y="%s" font-size="13" fill="%s" text-anchor="middle" transform="rotate(-90 %s %s)">%s</text>',
      util.fmt(x), util.fmt(center_y), TEXT_COLOR,
      util.fmt(x), util.fmt(center_y), util.escape_xml(fig._ylabel))
  end

  if fig._title ~= nil then
    printf('   <text class="title" x="%s" y="%s" font-size="18" fill="%s" text-anchor="middle">%s</text>',
      util.fmt(geom.width / 2), util.fmt(math.max(16, geom.top - 22)),
      TEXT_COLOR, util.escape_xml(fig._title))
  end
  add('  </g>')

  for _, series in ipairs(fig._series) do
    if series.kind == "image" and fig._colorbar then
      render_colorbar(series, geom, buf)
    end
  end
  render_legend(fig, geom, buf)

  add(' </g>')
  add('</svg>')
  return table.concat(buf, "\n") .. "\n"
end

return M
