-- Pure-Lua SVG renderer for luaplotlib figures.

local area = require("luaplotlib.area")
local grid = require("luaplotlib.grid")
local markers = require("luaplotlib.markers")
local text = require("luaplotlib.text")
local ticks = require("luaplotlib.ticks")
local util = require("luaplotlib.util")

local M = {}

local FONT_FAMILY = "Helvetica, Arial, sans-serif"
local TEXT_COLOR = "#222222"
local AXIS_COLOR = "#333333"
local hatch_id

local function clamp(value, minimum, maximum)
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function layout(fig)
  local width = fig.width
  local height = fig.height
  local tick_extra = math.max(0, (fig._ticklabelsize or 11) - 11)
  local label_extra = math.max(0, math.max(
    (fig._xlabel_fontsize or 13), (fig._ylabel_fontsize or 13)) - 13)
  local left = math.min(72, math.max(36, width * 0.14)) +
    (fig._ylabel_pad or 0) + tick_extra + label_extra
  local right = width - math.min(28, math.max(12, width * 0.04))
  if fig._colorbar then right = right - 62 end
  if fig._twin then right = right - 58 end
  local top = math.min(48, math.max(24, height * 0.10))
  if fig._twiny then top = top + 52 end
  local bottom = height - math.min(66, math.max(36, height * 0.16)) -
    (fig._xlabel_pad or 0) - tick_extra - label_extra

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

-- Shrink and center the plot box so the requested data-unit aspect ratio is
-- honored.  The label margins around the returned box stay untouched.
local function apply_aspect(geom, aspect, xspan, yspan)
  if aspect == nil or xspan <= 0 or yspan <= 0 then return end
  local desired_height = aspect * (yspan / xspan) * geom.plot_width
  if desired_height <= geom.plot_height then
    if desired_height < 20 then
      util.fail("aspect ratio leaves no drawable plot height", 3)
    end
    local offset = (geom.plot_height - desired_height) / 2
    geom.top = geom.top + offset
    geom.bottom = geom.top + desired_height
    geom.plot_height = desired_height
  else
    local desired_width = geom.plot_height * xspan / (aspect * yspan)
    if desired_width < 20 then
      util.fail("aspect ratio leaves no drawable plot width", 3)
    end
    local offset = (geom.plot_width - desired_width) / 2
    geom.left = geom.left + offset
    geom.right = geom.left + desired_width
    geom.plot_width = desired_width
  end
end

-- Collect data extents in axis coordinates. Linear axes use the raw values;
-- log axes use log10(value) and reject non-positive values with a clear error.
local function data_extents(fig, xscale, yscale)
  local min_x, max_x, min_y, max_y
  local baseline_x = false
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
      if series.extent ~= nil then
        include_x(series.extent[1], series_index, 1, "image")
        include_x(series.extent[2], series_index, 1, "image")
        include_y(series.extent[3], series_index, 1, "image")
        include_y(series.extent[4], series_index, 1, "image")
      else
        include_x(0, series_index, 1, "image")
        include_x(series.cols, series_index, 1, "image")
        include_y(0, series_index, 1, "image")
        include_y(series.rows, series_index, 1, "image")
      end
    elseif series.kind == "axhspan" then
      include_y(series.y1, series_index, 1, "axhspan")
      include_y(series.y2, series_index, 1, "axhspan")
    elseif series.kind == "axvspan" then
      include_x(series.x1, series_index, 1, "axvspan")
      include_x(series.x2, series_index, 1, "axvspan")
    elseif series.kind == "axhline" then
      include_y(series.y, series_index, 1, "axhline")
    elseif series.kind == "axvline" then
      include_x(series.x, series_index, 1, "axvline")
    elseif series.kind == "axline" then
      include_x(series.x1, series_index, 1, "axline")
      include_x(series.x2, series_index, 2, "axline")
      include_y(series.y1, series_index, 1, "axline")
      include_y(series.y2, series_index, 2, "axline")
    elseif series.kind == "line" or series.kind == "scatter" or
        series.kind == "quiver" then
      for i = 1, #series.x do
        include_x(series.x[i], series_index, i, "series")
        include_y(series.y[i], series_index, i, "series")
      end
    elseif series.kind == "hist2d" then
      include_x(series.edges_x[1], series_index, 1, "hist2d x")
      include_x(series.edges_x[#series.edges_x], series_index,
        #series.edges_x, "hist2d x")
      include_y(series.edges_y[1], series_index, 1, "hist2d y")
      include_y(series.edges_y[#series.edges_y], series_index,
        #series.edges_y, "hist2d y")
    elseif series.kind == "hexbin" then
      for _, cell in ipairs(series.cells) do
        include_x(cell.x - series.width / 2, series_index, 1, "hexbin")
        include_x(cell.x + series.width / 2, series_index, 1, "hexbin")
        include_y(cell.y - series.radius, series_index, 1, "hexbin")
        include_y(cell.y + series.radius, series_index, 1, "hexbin")
      end
      if #series.cells == 0 then
        for i = 1, #series.x do
          include_x(series.x[i], series_index, i, "hexbin point")
          include_y(series.y[i], series_index, i, "hexbin point")
        end
      end
    elseif series.kind == "hist" then
      local horizontal = series.orientation == "horizontal"
      if horizontal then
        if x_log then
          -- Zero-count bins are not drawn, so they do not define a log range.
          for i = 1, #series.counts do
            local count = series.counts[i]
            if count > 0 then
              include_x(count, series_index, i, "histogram count")
            elseif count < 0 then
              check_positive(count, "x", series_index, i, "histogram count")
            end
          end
        else
          baseline_x = true
          include_x(0, series_index, 1, "histogram baseline")
          for i = 1, #series.counts do
            include_x(series.counts[i], series_index, i, "histogram count")
          end
        end
        include_y(series.edges[1], series_index, 1, "histogram edge")
        include_y(series.edges[#series.edges], series_index, #series.edges,
          "histogram edge")
      else
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
      end
    elseif series.kind == "errorbar" then
      local every = series.errorevery or 1
      for i = 1, #series.x do
        local x, y = series.x[i], series.y[i]
        if (i - 1) % every == 0 then
          local xerr_lower = (series.xerr_lower or series.xerr) and
            (series.xerr_lower or series.xerr)[i] or 0
          local xerr_upper = (series.xerr_upper or series.xerr) and
            (series.xerr_upper or series.xerr)[i] or 0
          local yerr_lower = (series.yerr_lower or series.yerr)[i]
          local yerr_upper = (series.yerr_upper or series.yerr)[i]
          include_x(x - xerr_lower, series_index, i, "errorbar x")
          include_x(x + xerr_upper, series_index, i, "errorbar x")
          include_y(y - yerr_lower, series_index, i, "errorbar y")
          include_y(y + yerr_upper, series_index, i, "errorbar y")
        else
          include_x(x, series_index, i, "errorbar x")
          include_y(y, series_index, i, "errorbar y")
        end
      end
    elseif series.kind == "fill" or series.kind == "fillx" then
      local fillx = series.kind == "fillx"
      for _, run in ipairs(area.segments(series)) do
        for i = 1, #run[fillx and "y" or "x"] do
          if fillx then
            include_y(run.y[i], series_index, i, "fillx y")
            include_x(run.x1[i], series_index, i, "fillx left")
            include_x(run.x2[i], series_index, i, "fillx right")
          else
            include_x(run.x[i], series_index, i, "fill x")
            include_y(run.y1[i], series_index, i, "fill lower")
            include_y(run.y2[i], series_index, i, "fill upper")
          end
        end
      end
    elseif series.kind == "eventplot" then
      local horizontal = series.orientation == "horizontal"
      for row = 1, #series.rows do
        local offset = series.lineoffsets[row]
        local half = series.linelengths[row] / 2
        for i = 1, #series.rows[row] do
          local value = series.rows[row][i]
          if horizontal then
            include_y(value, series_index, i, "eventplot value")
          else
            include_x(value, series_index, i, "eventplot value")
          end
        end
        if horizontal then
          include_x(offset - half, series_index, 1, "eventplot extent")
          include_x(offset + half, series_index, 1, "eventplot extent")
        else
          include_y(offset - half, series_index, 1, "eventplot extent")
          include_y(offset + half, series_index, 1, "eventplot extent")
        end
      end
    elseif series.kind == "step" then
      for i = 1, #series.x do
        include_x(series.x[i], series_index, i, "step x")
        include_y(series.y[i], series_index, i, "step y")
      end
    elseif series.kind == "stem" then
      if series.orientation == "horizontal" then
        include_x(series.base or 0, series_index, 1, "stem baseline")
        for i = 1, #series.x do
          include_x(series.y[i], series_index, i, "stem value")
          include_y(series.x[i], series_index, i, "stem position")
        end
      else
        include_y(series.base or 0, series_index, 1, "stem baseline")
        for i = 1, #series.x do
          include_x(series.x[i], series_index, i, "stem x")
          include_y(series.y[i], series_index, i, "stem y")
        end
      end
    elseif series.kind == "contour" then
      if series.x_coords ~= nil then
        for _, value in ipairs(series.x_coords) do
          include_x(value, series_index, 1, "contour x")
        end
      else
        include_x(0, series_index, 1, "contour")
        include_x(series.cols or 1, series_index, 1, "contour")
      end
      if series.y_coords ~= nil then
        for _, value in ipairs(series.y_coords) do
          include_y(value, series_index, 1, "contour y")
        end
      else
        include_y(0, series_index, 1, "contour")
        include_y(series.rows or 1, series_index, 1, "contour")
      end
    elseif series.kind == "barh" then
      include_x(0, series_index, 1, "barh baseline")
      for i = 1, #series.x do
        include_x(series.x[i], series_index, i, "barh value")
        include_y(series.y[i] - series.height / 2, series_index, i, "barh")
        include_y(series.y[i] + series.height / 2, series_index, i, "barh")
      end
    elseif series.kind == "broken_barh" then
      for index = 1, #series.ranges do
        local range = series.ranges[index]
        include_x(range[1], series_index, index, "broken_barh start")
        include_x(range[1] + range[2], series_index, index,
          "broken_barh end")
      end
      include_y(series.y, series_index, 1, "broken_barh y")
      include_y(series.y + series.height, series_index, 1,
        "broken_barh height")
    elseif series.kind == "violin" then
      if series.orientation == "horizontal" then
        include_y(series.position - series.width / 2, series_index, 1,
          "violin")
        include_y(series.position + series.width / 2, series_index, 1,
          "violin")
        include_x(series.minimum, series_index, 1, "violin minimum")
        include_x(series.maximum, series_index, 1, "violin maximum")
      else
        include_x(series.position - series.width / 2, series_index, 1, "violin")
        include_x(series.position + series.width / 2, series_index, 1, "violin")
        include_y(series.minimum, series_index, 1, "violin minimum")
        include_y(series.maximum, series_index, 1, "violin maximum")
      end
    elseif series.kind == "box" then
      local horizontal = series.orientation == "horizontal"
      local low_edge = series.position - series.width / 2
      local high_edge = series.position + series.width / 2
      if horizontal then
        include_y(low_edge, series_index, 1, "box")
        include_y(high_edge, series_index, 1, "box")
        include_x(series.low, series_index, 1, "box whisker")
        include_x(series.high, series_index, 1, "box whisker")
        if series.showfliers ~= false then
          for _, value in ipairs(series.outliers) do
            include_x(value, series_index, 1, "box outlier")
          end
        end
      else
        include_x(low_edge, series_index, 1, "box")
        include_x(high_edge, series_index, 1, "box")
        include_y(series.low, series_index, 1, "box whisker")
        include_y(series.high, series_index, 1, "box whisker")
        if series.showfliers ~= false then
          for _, value in ipairs(series.outliers) do
            include_y(value, series_index, 1, "box outlier")
          end
        end
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
        if series.yerr_lower ~= nil then
          local reference = series.y[i]
          if series.bottom ~= nil then
            reference = series.bottom[i] + series.y[i]
          end
          include_y(reference - series.yerr_lower[i], series_index, i,
            "bar lower error")
          include_y(reference + series.yerr_upper[i], series_index, i,
            "bar upper error")
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
    baseline_x = baseline_x,
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

local function find_category_ticks(fig, minimum, maximum, axis)
  if not fig._category_ticks then
    return nil
  end
  if (fig._category_axis or "x") ~= axis then
    return nil
  end
  local result = {}
  local tolerance = (maximum - minimum) * 1e-9
  for _, category in ipairs(fig._category_ticks) do
    if category.position >= minimum - tolerance and
        category.position <= maximum + tolerance then
      result[#result + 1] = category
    end
  end
  return result
end

local function swatch(buf, kind, color, x, y, length)
  length = length or 20
  if kind == "scatter" then
    buf[#buf + 1] = string.format(
      '  <circle cx="%s" cy="%s" r="4" fill="%s"/>',
      util.fmt(x + length / 2), util.fmt(y), color)
  elseif kind == "fill" then
    buf[#buf + 1] = string.format(
      '  <rect x="%s" y="%s" width="%s" height="9" rx="1" fill="%s"/>',
      util.fmt(x), util.fmt(y - 4), util.fmt(length), color)
  elseif kind == "hist" or kind == "bar" or kind == "hexbin" or
      kind == "hist2d" or kind == "violin" or kind == "broken_barh" then
    buf[#buf + 1] = string.format(
      '  <rect x="%s" y="%s" width="%s" height="9" rx="1" fill="%s"/>',
      util.fmt(x), util.fmt(y - 4), util.fmt(length), color)
  elseif kind == "quiver" then
    buf[#buf + 1] = string.format(
      '  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2" stroke-linecap="round"/>',
      util.fmt(x), util.fmt(y), util.fmt(x + length * 0.7), util.fmt(y),
      color)
    buf[#buf + 1] = string.format(
      '  <polygon points="%s,%s %s,%s %s,%s" fill="%s"/>',
      util.fmt(x + length), util.fmt(y), util.fmt(x + length * 0.65),
      util.fmt(y - 3.5), util.fmt(x + length * 0.65), util.fmt(y + 3.5),
      color)
  else
    buf[#buf + 1] = string.format(
      '  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2.5" stroke-linecap="round"/>',
      util.fmt(x), util.fmt(y), util.fmt(x + length), util.fmt(y), color)
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

  local opts = fig._legend_opts or { loc = "upper right", frame = true, ncol = 1 }
  local border = opts.borderpad or 8
  local handle = opts.handlelength or 20
  local fontsize = opts.fontsize or 11
  local row_height = fontsize + 9
  local char_width = fontsize * 6.5 / 11
  local ncol = math.max(1, math.min(opts.ncol or 1, #entries))
  local rows = math.ceil(#entries / ncol)
  local col_width = math.min(geom.plot_width - border,
    math.max(88, border + handle + 8 + 16 + max_chars * char_width))
  local box_width = math.min(geom.plot_width - border,
    col_width * ncol + (ncol - 1) * border)
  local title_height = opts.title and row_height or 0
  local box_height = 2 * border - 4 + title_height + rows * row_height
  local loc = opts.loc or "upper right"
  local center_x = geom.left + (geom.plot_width - box_width) / 2
  local center_y = geom.top + (geom.plot_height - box_height) / 2
  local x, y
  if loc == "upper left" then
    x, y = geom.left + border, geom.top + border
  elseif loc == "upper center" then
    x, y = center_x, geom.top + border
  elseif loc == "lower left" then
    x, y = geom.left + border, geom.bottom - box_height - border
  elseif loc == "lower center" then
    x, y = center_x, geom.bottom - box_height - border
  elseif loc == "lower right" then
    x, y = geom.right - box_width - border,
      geom.bottom - box_height - border
  elseif loc == "center left" then
    x, y = geom.left + border, center_y
  elseif loc == "center right" then
    x, y = geom.right - box_width - border, center_y
  elseif loc == "center" then
    x, y = center_x, center_y
  else
    x, y = geom.right - box_width - border, geom.top + border
  end
  x = clamp(x, geom.left + 4, math.max(geom.left + 4, geom.right - box_width - 4))
  y = clamp(y, geom.top + 4, math.max(geom.top + 4, geom.bottom - box_height - 4))

  local framealpha = opts.framealpha or 0.92
  local facecolor = opts.facecolor or "#ffffff"
  local edgecolor = opts.edgecolor or "#bbbbbb"
  buf[#buf + 1] = ' <g class="legend">'
  buf[#buf + 1] = string.format(
    '  <g class="legend-meta" data-loc="%s" data-framealpha="%s" data-borderpad="%s" data-handlelength="%s" data-fontsize="%s"/>',
    util.escape_xml(loc), util.fmt(framealpha), util.fmt(border),
    util.fmt(handle), util.fmt(fontsize))
  if opts.frame ~= false then
    buf[#buf + 1] = string.format(
      '  <rect class="legend-frame" x="%s" y="%s" width="%s" height="%s" rx="3" fill="%s" fill-opacity="%s" stroke="%s" stroke-width="1"/>',
      util.fmt(x), util.fmt(y), util.fmt(box_width), util.fmt(box_height),
      facecolor, util.fmt(framealpha), edgecolor)
  end
  if opts.title then
    buf[#buf + 1] = string.format(
      '  <text class="legend-title" x="%s" y="%s" font-size="%s" font-weight="bold" fill="%s">%s</text>',
      util.fmt(x + border), util.fmt(y + border + fontsize + 3),
      util.fmt(fontsize), TEXT_COLOR, util.escape_xml(opts.title))
  end
  for i, entry in ipairs(entries) do
    local column = math.floor((i - 1) / rows) + 1
    local row = (i - 1) % rows + 1
    local entry_x = x + border + (column - 1) * (col_width + border)
    local entry_y = y + (2 * border - 4) + title_height +
      (row - 1) * row_height
    swatch(buf, entry.kind, entry.color, entry_x, entry_y, handle)
    buf[#buf + 1] = string.format(
      '  <text x="%s" y="%s" font-size="%s" fill="%s">%s</text>',
      util.fmt(entry_x + handle + 8), util.fmt(entry_y + fontsize * 0.36),
      util.fmt(fontsize), TEXT_COLOR, util.escape_xml(entry.label))
  end
  buf[#buf + 1] = ' </g>'
end

local function attribute(value)
  return util.escape_xml(value)
end

local function render_image(series, map_x, map_y, buf)
  local colors = require("luaplotlib.colors")
  local extent = series.extent
  local lower = series.origin == "lower"
  local metadata = ""
  if extent ~= nil or lower then
    local ext = extent or { 0, series.cols, 0, series.rows }
    metadata = string.format(
      ' data-origin="%s" data-extent="%s,%s,%s,%s"',
      series.origin or "upper", util.fmt(ext[1]), util.fmt(ext[2]),
      util.fmt(ext[3]), util.fmt(ext[4]))
  end
  local alpha = series.style.alpha or 1
  local opacity = ""
  if alpha < 1 then
    metadata = metadata .. string.format(' data-alpha="%s"', util.fmt(alpha))
    opacity = string.format(' fill-opacity="%s"', util.fmt(alpha))
  end
  if extent == nil and lower then
    extent = { 0, series.cols, 0, series.rows }
  end
  buf[#buf + 1] = string.format('  <g class="heatmap"%s>', metadata)
  for row = 1, series.rows do
    for col = 1, series.cols do
      local data_x0, data_x1, data_y0, data_y1
      if extent ~= nil then
        local step_x = (extent[2] - extent[1]) / series.cols
        local step_y = (extent[4] - extent[3]) / series.rows
        data_x0 = extent[1] + (col - 1) * step_x
        data_x1 = extent[1] + col * step_x
        if lower then
          data_y0 = extent[3] + (row - 1) * step_y
          data_y1 = extent[3] + row * step_y
        else
          data_y0 = extent[4] - row * step_y
          data_y1 = extent[4] - (row - 1) * step_y
        end
      else
        data_x0, data_x1 = col - 1, col
        data_y0, data_y1 = series.rows - row, series.rows - row + 1
      end
      local x0 = map_x(data_x0)
      local x1 = map_x(data_x1)
      local y0 = map_y(data_y0)
      local y1 = map_y(data_y1)
      local left = math.min(x0, x1)
      local top = math.min(y0, y1)
      local color = colors.heat(series.values[row][col], series.vmin,
        series.vmax)
      local cell_metadata = ""
      if metadata ~= "" then
        cell_metadata = string.format(' data-row="%d" data-col="%d"', row, col)
      end
      buf[#buf + 1] = string.format(
        '   <rect class="heatmap-cell" x="%s" y="%s" width="%s" height="%s" fill="%s"%s%s/>',
        util.fmt(left), util.fmt(top), util.fmt(math.abs(x1 - x0)),
        util.fmt(math.abs(y1 - y0)), color, cell_metadata, opacity)
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

local function render_span(series, map_x, map_y, geom, buf)
  local style = series.style
  local x1, x2, y1, y2
  if series.kind == "axhspan" then
    x1, x2 = geom.left, geom.right
    y1, y2 = map_y(series.y1), map_y(series.y2)
  else
    x1, x2 = map_x(series.x1), map_x(series.x2)
    y1, y2 = geom.top, geom.bottom
  end
  local left, right = math.min(x1, x2), math.max(x1, x2)
  local top, bottom = math.min(y1, y2), math.max(y1, y2)
  local fill = style.color
  if style.hatch then fill = "url(#" .. hatch_id(style.hatch, fill) .. ")" end
  buf[#buf + 1] = string.format(
    '  <rect class="span %s" x="%s" y="%s" width="%s" height="%s" fill="%s" fill-opacity="%s"/>',
    series.kind, util.fmt(left), util.fmt(top), util.fmt(right - left),
    util.fmt(bottom - top), fill, util.fmt(style.alpha))
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
  if series.kind == "axhline" then
    local xmin = series.xmin or 0
    local xmax = series.xmax or 1
    local y = map_y(series.y)
    local x1 = geom.left + xmin * geom.plot_width
    local x2 = geom.left + xmax * geom.plot_width
    buf[#buf + 1] = string.format(
      '  <g class="series series-%s" data-xmin="%s" data-xmax="%s"%s>',
      series.kind, util.fmt(xmin), util.fmt(xmax), label)
    buf[#buf + 1] = string.format(
      '   <line class="reference" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s%s/>',
      util.fmt(x1), util.fmt(y), util.fmt(x2), util.fmt(y),
      style.color, util.fmt(style.linewidth), dash, opacity)
  else
    local ymin = series.ymin or 0
    local ymax = series.ymax or 1
    local x = map_x(series.x)
    local y1 = geom.bottom - ymin * geom.plot_height
    local y2 = geom.bottom - ymax * geom.plot_height
    buf[#buf + 1] = string.format(
      '  <g class="series series-%s" data-ymin="%s" data-ymax="%s"%s>',
      series.kind, util.fmt(ymin), util.fmt(ymax), label)
    buf[#buf + 1] = string.format(
      '   <line class="reference" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s%s/>',
      util.fmt(x), util.fmt(y1), util.fmt(x), util.fmt(y2),
      style.color, util.fmt(style.linewidth), dash, opacity)
  end
  buf[#buf + 1] = '  </g>'
end

-- Liang-Barsky clipping for the infinite axline. Coordinates are already in
-- screen space, so the line is clipped to the plot rectangle after projection.
local function clip_segment(x0, y0, x1, y1, left, top, right, bottom)
  local dx, dy = x1 - x0, y1 - y0
  local t0, t1 = 0, 1

  local function edge(p, q)
    if math.abs(p) < 1e-12 then
      return q >= 0
    end
    local r = q / p
    if p < 0 then
      if r > t1 then return false end
      if r > t0 then t0 = r end
    else
      if r < t0 then return false end
      if r < t1 then t1 = r end
    end
    return true
  end

  if not edge(-dx, x0 - left) then return nil end
  if not edge(dx, right - x0) then return nil end
  if not edge(-dy, y0 - top) then return nil end
  if not edge(dy, bottom - y0) then return nil end

  return x0 + t0 * dx, y0 + t0 * dy, x0 + t1 * dx, y0 + t1 * dy
end

local function render_axline(series, map_x, map_y, geom, buf)
  local style = series.style
  local dash = ""
  if style.linestyle == "dashed" then dash = ' stroke-dasharray="6 4"'
  elseif style.linestyle == "dotted" then dash = ' stroke-dasharray="1.5 3"' end
  local opacity = style.alpha < 1 and
    string.format(' stroke-opacity="%s"', util.fmt(style.alpha)) or ""
  local label = style.label and
    string.format(' data-label="%s"', attribute(style.label)) or ""

  local ax, ay = map_x(series.x1), map_y(series.y1)
  local bx, by = map_x(series.x2), map_y(series.y2)
  local dx, dy = bx - ax, by - ay
  local length = math.sqrt(dx * dx + dy * dy)
  if length < 1e-9 then return end
  -- axline is infinite: extend the defining segment well past the plot
  -- rectangle before clipping, then keep only the visible intersection.
  local extension = (geom.plot_width + geom.plot_height) / length
  local sx, sy = ax - dx * extension, ay - dy * extension
  local ex, ey = bx + dx * extension, by + dy * extension
  local x0, y0, x1, y1 = clip_segment(sx, sy, ex, ey, geom.left, geom.top,
    geom.right, geom.bottom)
  if x0 == nil then return end

  local clipped = math.abs(x0 - ax) > 1e-6 or math.abs(y0 - ay) > 1e-6 or
    math.abs(x1 - bx) > 1e-6 or math.abs(y1 - by) > 1e-6
  buf[#buf + 1] = string.format(
    '  <g class="series series-axline" data-x1="%s" data-y1="%s" data-x2="%s" data-y2="%s" data-clipped="%s"%s>',
    util.fmt(series.x1), util.fmt(series.y1), util.fmt(series.x2),
    util.fmt(series.y2), clipped and "true" or "false", label)
  if style.linestyle ~= "none" then
    buf[#buf + 1] = string.format(
      '   <line class="reference axline" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s%s/>',
      util.fmt(x0), util.fmt(y0), util.fmt(x1), util.fmt(y1), style.color,
      util.fmt(style.linewidth), dash, opacity)
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

  local draw_line = style.linestyle ~= "none"
  local draw_marker = style.marker ~= nil or (#series.x == 1 and draw_line)
  local marker_indices = {}
  if draw_marker then
    if style.markevery then
      for _, index in ipairs(style.markevery) do
        marker_indices[#marker_indices + 1] = index
      end
    else
      for index = 1, #series.x do marker_indices[#marker_indices + 1] = index end
    end
  end
  local metadata = label
  if draw_marker then
    metadata = metadata .. string.format(' data-marker-count="%d"',
      #marker_indices)
    if style.markevery then metadata = metadata .. ' data-markevery="true"' end
  end
  buf[#buf + 1] = string.format('  <g class="series series-line"%s>', metadata)

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

  if draw_marker then
    local marker_opacity = ""
    local marker_outline = ""
    if style.alpha < 1 then
      local alpha = util.fmt(style.alpha)
      marker_opacity = string.format(' fill-opacity="%s"', alpha)
      if style.markeredgecolor ~= nil then
        marker_outline = marker_outline ..
          string.format(' stroke-opacity="%s"', alpha)
      end
    end
    local marker_fill = style.markerfacecolor or color
    if style.markeredgecolor ~= nil then
      marker_outline = string.format(' stroke="%s" stroke-width="%s"%s',
        style.markeredgecolor, util.fmt(style.markeredgewidth or 1),
        marker_outline)
    end
    for _, i in ipairs(marker_indices) do
      local marker_size = style.markersizes and style.markersizes[i] or
        style.markersize
      buf[#buf + 1] = markers.svg(style.marker, "marker",
        map_x(series.x[i]), map_y(series.y[i]), marker_size,
        marker_fill, marker_opacity, marker_outline)
    end
  end

  buf[#buf + 1] = '  </g>'
end

local function render_scatter(series, map_x, map_y, buf)
  local style = series.style
  local outline = ""
  if style.edgecolor ~= nil then
    outline = string.format(' stroke="%s" stroke-width="%s"',
      style.edgecolor, util.fmt(style.linewidth))
  end
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', attribute(style.label))
  end
  if series.color_values ~= nil then
    label = label .. string.format(
      ' data-color-values="true" data-vmin="%s" data-vmax="%s"',
      util.fmt(series.vmin), util.fmt(series.vmax))
  end

  buf[#buf + 1] = string.format('  <g class="series series-scatter"%s>', label)
  for i = 1, #series.x do
    local radius = style.radii and style.radii[i] or style.radius
    local color = style.colors and style.colors[i] or style.color
    local marker = style.markers and style.markers[i] or style.marker
    local alpha = style.alphas and style.alphas[i] or style.alpha
    local edge = style.edgecolors and style.edgecolors[i] or style.edgecolor
    local width = style.linewidths and style.linewidths[i] or style.linewidth
    local point_outline = ""
    if edge ~= nil then
      point_outline = string.format(' stroke="%s" stroke-width="%s"',
        edge, util.fmt(width))
    end
    local fade = ""
    if alpha < 1 then
      local opacity = util.fmt(alpha)
      fade = string.format(' fill-opacity="%s"', opacity)
      if point_outline ~= "" then
        point_outline = point_outline ..
          string.format(' stroke-opacity="%s"', opacity)
      end
    end
    buf[#buf + 1] = markers.svg(marker, "point",
      map_x(series.x[i]), map_y(series.y[i]), radius, color, fade,
      point_outline)
  end
  buf[#buf + 1] = '  </g>'
end

local CARTESIAN_QUIVER_AUTO_LENGTH = 18
local QUIVER_PIVOT_FRACTIONS = { tail = 0, middle = 0.5, tip = 1 }

local function render_quiver(series, map_x, map_y, buf)
  local style = series.style
  local count = #series.x
  local stride = math.max(1, math.ceil(count / series.max_arrows))
  local entries = {}
  local maximum = 0
  for index = 1, count, stride do
    local u, v = series.u[index], series.v[index]
    local magnitude = math.sqrt(u * u + v * v)
    if magnitude > 1e-12 then
      local x, y = series.x[index], series.y[index]
      local dx, dy
      if series.angles == "uv" then
        dx, dy = u, -v
      else
        dx = map_x(x + u) - map_x(x)
        dy = map_y(y + v) - map_y(y)
      end
      local length = math.sqrt(dx * dx + dy * dy)
      if length > 1e-12 then
        if series.normalize then
          dx, dy = dx / length, dy / length
          length = 1
        end
        entries[#entries + 1] = {
          index = index, x = x, y = y, magnitude = magnitude,
          dx = dx, dy = dy, length = length,
        }
        if length > maximum then maximum = length end
      end
    end
  end
  local automatic = series.scale == nil
  local scale = series.scale
  if scale == nil then
    scale = maximum > 0 and CARTESIAN_QUIVER_AUTO_LENGTH / maximum or 1
  end
  local pivot = QUIVER_PIVOT_FRACTIONS[series.pivot] or 0
  local stroke_opacity, fill_opacity = "", ""
  if style.alpha < 1 then
    local alpha = util.fmt(style.alpha)
    stroke_opacity = string.format(' stroke-opacity="%s"', alpha)
    fill_opacity = string.format(' fill-opacity="%s"', alpha)
  end
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', attribute(style.label))
  end

  buf[#buf + 1] = string.format(
    '  <g class="series series-quiver" data-count="%d" data-drawn="%d" data-stride="%d" data-max-arrows="%d" data-scale="%s" data-scale-mode="%s" data-pivot="%s" data-normalize="%s" data-angles="%s"%s>',
    count, #entries, stride, series.max_arrows, util.fmt(scale),
    automatic and "auto" or "explicit", series.pivot,
    series.normalize and "true" or "false", series.angles or "xy", label)

  for _, entry in ipairs(entries) do
    local color = style.colors and style.colors[entry.index] or style.color
    local length = entry.length * scale
    local base_length = entry.length
    local ux, uy = entry.dx / base_length, entry.dy / base_length
    local anchor_x, anchor_y = map_x(entry.x), map_y(entry.y)
    local tail_x = anchor_x - ux * length * pivot
    local tail_y = anchor_y - uy * length * pivot
    local tip_x = tail_x + ux * length
    local tip_y = tail_y + uy * length
    local head = math.min(style.head or 0, length)
    local neck_x = tip_x - ux * head
    local neck_y = tip_y - uy * head
    local angle = math.deg(math.atan2(entry.dy, entry.dx))
    buf[#buf + 1] = string.format(
      '   <g class="quiver-arrow" data-index="%d" data-magnitude="%s" data-x="%s" data-y="%s" data-angle="%s">',
      entry.index, util.fmt(entry.magnitude), util.fmt(entry.x),
      util.fmt(entry.y), util.fmt(angle))
    if style.linewidth > 0 and length - head > 1e-9 then
      buf[#buf + 1] = string.format(
        '    <line class="quiver-shaft" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"%s/>',
        util.fmt(tail_x), util.fmt(tail_y), util.fmt(neck_x),
        util.fmt(neck_y), color, util.fmt(style.linewidth),
        stroke_opacity)
    end
    if head > 1e-9 then
      local half = head * 0.45
      local px, py = -uy * half, ux * half
      buf[#buf + 1] = string.format(
        '    <polygon class="quiver-head" points="%s,%s %s,%s %s,%s" fill="%s"%s/>',
        util.fmt(tip_x), util.fmt(tip_y),
        util.fmt(neck_x + px), util.fmt(neck_y + py),
        util.fmt(neck_x - px), util.fmt(neck_y - py),
        color, fill_opacity)
    end
    buf[#buf + 1] = '   </g>'
  end
  buf[#buf + 1] = '  </g>'
end

local function render_hexbin(series, map_x, map_y, buf)
  local colors = require("luaplotlib.colors")
  local style = series.style
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', attribute(style.label))
  end
  local opacity = ""
  if style.alpha < 1 then
    opacity = string.format(' fill-opacity="%s"', util.fmt(style.alpha))
  end
  buf[#buf + 1] = string.format(
    '  <g class="series series-hexbin" data-bins="%d" data-points="%d" data-gridsize="%d" data-mincnt="%d" data-norm="%s" data-vmin="%s" data-vmax="%s"%s>',
    #series.cells, series.point_count, series.gridsize, series.mincnt,
    series.norm or "linear", util.fmt(series.vmin), util.fmt(series.vmax),
    label)
  local half_width = series.width / 2
  local half_height = series.radius / 2
  for _, cell in ipairs(series.cells) do
    local left = map_x(cell.x - half_width)
    local right = map_x(cell.x + half_width)
    local center_x = map_x(cell.x)
    local top = map_y(cell.y + series.radius)
    local bottom = map_y(cell.y - series.radius)
    local upper = map_y(cell.y + half_height)
    local lower = map_y(cell.y - half_height)
    local points = string.format(
      "%s,%s %s,%s %s,%s %s,%s %s,%s %s,%s",
      util.fmt(center_x), util.fmt(top), util.fmt(right), util.fmt(upper),
      util.fmt(right), util.fmt(lower), util.fmt(center_x), util.fmt(bottom),
      util.fmt(left), util.fmt(lower), util.fmt(left), util.fmt(upper))
    buf[#buf + 1] = string.format(
      '   <polygon class="hexbin-cell" data-row="%d" data-col="%d" data-count="%d" data-x="%s" data-y="%s" points="%s" fill="%s" stroke="%s" stroke-width="%s"%s/>',
      cell.row, cell.column, cell.count, util.fmt(cell.x), util.fmt(cell.y),
      points, colors.heat(cell.color_value or cell.count,
        series.color_vmin or series.vmin, series.color_vmax or series.vmax),
      series.edgecolor, util.fmt(series.linewidth), opacity)
  end
  buf[#buf + 1] = '  </g>'
end

local function colorbar_values(series)
  if series.colorbar_tick_values ~= nil then
    return series.colorbar_tick_values, "explicit"
  end
  local count = series.colorbar_ticks or 3
  local values = {}
  for index = 1, count do
    local fraction = (index - 1) / (count - 1)
    if (series.color_norm or series.norm) == "log" then
      values[index] = math.exp(math.log(1 + series.vmin) +
        (math.log(1 + series.vmax) - math.log(1 + series.vmin)) * fraction) - 1
    else
      values[index] = series.vmin +
        (series.vmax - series.vmin) * fraction
    end
  end
  return values, "uniform"
end

-- Shared vertical heat colorbar used by image, hexbin, hist2d, and numeric
-- scatter series.  `class_name` preserves the existing feature-specific
-- classes and `extra_attributes` carries additive norm metadata.
local function render_value_colorbar(series, geom, buf, class_name,
    extra_attributes)
  local colors = require("luaplotlib.colors")
  local values, source = colorbar_values(series)
  local x = geom.right + 14
  local y = geom.top
  local width = 16
  local height = geom.plot_height
  local color_vmin = series.color_vmin or series.vmin
  local color_vmax = series.color_vmax or series.vmax
  local span = color_vmax - color_vmin
  local function transform(value)
    if (series.color_norm or series.norm) == "log" then
      return math.log(1 + value)
    end
    return value
  end
  buf[#buf + 1] = string.format(
    '  <g class="%s" data-orientation="vertical" data-vmin="%s" data-vmax="%s" data-ticks="%d" data-tick-source="%s" data-x="%s" data-y="%s" data-width="%s" data-height="%s"%s>',
    class_name, util.fmt(series.vmin), util.fmt(series.vmax), #values, source,
    util.fmt(x), util.fmt(y), util.fmt(width), util.fmt(height),
    extra_attributes or "")
  local steps = 40
  for index = 1, steps do
    local value = color_vmax - span * ((index - 0.5) / steps)
    buf[#buf + 1] = string.format(
      '   <rect class="colorbar-step" x="%s" y="%s" width="%s" height="%s" fill="%s"/>',
      util.fmt(x), util.fmt(y + height * (index - 1) / steps),
      util.fmt(width), util.fmt(height / steps + 0.5),
      colors.heat(value, color_vmin, color_vmax))
  end
  buf[#buf + 1] = string.format(
    '   <rect class="colorbar-frame" x="%s" y="%s" width="%s" height="%s" fill="none" stroke="%s" stroke-width="1"/>',
    util.fmt(x - 0.5), util.fmt(y - 0.5), util.fmt(width + 1),
    util.fmt(height + 1), AXIS_COLOR)
  local maximum_label = 0
  for _, value in ipairs(values) do
    local fraction = span == 0 and 0 or (transform(value) - color_vmin) / span
    local tick_y = y + height - height * fraction
    local label = util.fmt_tick(value)
    local measured = #label * 6
    if measured > maximum_label then maximum_label = measured end
    buf[#buf + 1] = string.format(
      '   <line class="colorbar-tick" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1" data-value="%s" data-fraction="%s"/>',
      util.fmt(x + width), util.fmt(tick_y), util.fmt(x + width + 4),
      util.fmt(tick_y), AXIS_COLOR, util.fmt(value), util.fmt(fraction))
    buf[#buf + 1] = string.format(
      '   <text class="colorbar-label" x="%s" y="%s" font-size="10" fill="%s" text-anchor="start" data-value="%s" data-fraction="%s">%s</text>',
      util.fmt(x + width + 8), util.fmt(tick_y + 3.5), TEXT_COLOR,
      util.fmt(value), util.fmt(fraction), util.escape_xml(label))
  end
  if series.colorbar_label ~= nil and series.colorbar_label ~= "" then
    local label_x = x + width + 8 + maximum_label + 14
    local label_y = y + height / 2
    buf[#buf + 1] = string.format(
      '   <text class="colorbar-title" x="%s" y="%s" font-size="11" fill="%s" text-anchor="middle" transform="rotate(-90 %s %s)">%s</text>',
      util.fmt(label_x), util.fmt(label_y), TEXT_COLOR,
      util.fmt(label_x), util.fmt(label_y),
      util.escape_xml(series.colorbar_label))
  end
  buf[#buf + 1] = '  </g>'
end

local function render_hexbin_colorbar(series, geom, buf)
  render_value_colorbar(series, geom, buf, "colorbar hexbin-colorbar")
end

local function render_hist2d(series, map_x, map_y, buf)
  local colors = require("luaplotlib.colors")
  local style = series.style
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', attribute(style.label))
  end
  local opacity = ""
  if style.alpha < 1 then
    opacity = string.format(' fill-opacity="%s"', util.fmt(style.alpha))
  end
  local norm = series.density and "density" or "count"
  buf[#buf + 1] = string.format(
    '  <g class="series series-hist2d" data-points="%d" data-inside="%d" data-bins-x="%d" data-bins-y="%d" data-norm="%s" data-color-norm="%s" data-show-empty="%s" data-vmin="%s" data-vmax="%s" data-explicit-bins="%s"%s>',
    series.point_count, series.inside_count, series.bins_x, series.bins_y, norm,
    series.color_norm or "linear", series.show_empty and "true" or "false",
    util.fmt(series.vmin), util.fmt(series.vmax),
    series.explicit_edges and "true" or "false", label)
  for _, cell in ipairs(series.cells) do
    local x0 = map_x(cell.x0)
    local x1 = map_x(cell.x1)
    local y0 = map_y(cell.y0)
    local y1 = map_y(cell.y1)
    local left = math.min(x0, x1)
    local top = math.min(y0, y1)
    buf[#buf + 1] = string.format(
      '   <rect class="hist2d-cell" data-row="%d" data-col="%d" data-count="%d" data-value="%s" data-x0="%s" data-x1="%s" data-y0="%s" data-y1="%s" x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="%s" stroke-width="%s"%s/>',
      cell.row, cell.column, cell.count, util.fmt(cell.value),
      util.fmt(cell.x0), util.fmt(cell.x1), util.fmt(cell.y0),
      util.fmt(cell.y1), util.fmt(left), util.fmt(top),
      util.fmt(math.abs(x1 - x0)), util.fmt(math.abs(y1 - y0)),
      colors.heat(cell.color_value or cell.value,
        series.color_vmin or series.vmin, series.color_vmax or series.vmax),
      series.edgecolor, util.fmt(series.linewidth), opacity)
  end
  buf[#buf + 1] = '  </g>'
end

local function render_errorbar(series, map_x, map_y, buf)
  local style = series.style
  local cap = style.capsize or 4
  local base_width = style.elinewidth or 1
  local base_color = style.ecolor or style.color
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', attribute(style.label))
  end
  local every = series.errorevery or 1
  local drawn = math.floor((#series.x - 1) / every) + 1
  local any_lolims, any_uplims = false, false
  local any_xlolims, any_xuplims = false, false
  for index = 1, #series.x do
    if series.lolims and series.lolims[index] then any_lolims = true end
    if series.uplims and series.uplims[index] then any_uplims = true end
    if series.xlolims and series.xlolims[index] then any_xlolims = true end
    if series.xuplims and series.xuplims[index] then any_xuplims = true end
  end
  local metadata = string.format(
    ' data-errorevery="%d" data-error-points="%d" data-lolims="%s" data-uplims="%s" data-xlolims="%s" data-xuplims="%s"',
    every, drawn, any_lolims and "true" or "false",
    any_uplims and "true" or "false", any_xlolims and "true" or "false",
    any_xuplims and "true" or "false")
  if series.yerr_asymmetric then metadata = metadata .. ' data-yerr-mode="asymmetric"' end
  if series.xerr_asymmetric then metadata = metadata .. ' data-xerr-mode="asymmetric"' end
  buf[#buf + 1] = string.format('  <g class="series series-errorbar"%s%s>',
    label, metadata)
  for i = 1, #series.x do
    if (i - 1) % every == 0 then
      local color = style.ecolors and style.ecolors[i] or base_color
      local width = style.elinewidths and style.elinewidths[i] or base_width
      local x = map_x(series.x[i])
      local y = series.y[i]
      local yerr_lower = (series.yerr_lower or series.yerr)[i]
      local yerr_upper = (series.yerr_upper or series.yerr)[i]
      local xerr_lower = (series.xerr_lower or series.xerr) and
        (series.xerr_lower or series.xerr)[i] or 0
      local xerr_upper = (series.xerr_upper or series.xerr) and
        (series.xerr_upper or series.xerr)[i] or 0
      local top = map_y(y + yerr_upper)
      local bottom = map_y(y - yerr_lower)
      buf[#buf + 1] = string.format(
        '   <line class="errorbar" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
        util.fmt(x), util.fmt(top), util.fmt(x), util.fmt(bottom), color,
        util.fmt(width))
      if series.uplims and series.uplims[i] then
        buf[#buf + 1] = string.format(
          '   <polygon class="errorbar-limit-upper" points="%s,%s %s,%s %s,%s" fill="%s"/>',
          util.fmt(x), util.fmt(top), util.fmt(x - cap * 0.5),
          util.fmt(top + cap), util.fmt(x + cap * 0.5),
          util.fmt(top + cap), color)
      else
        buf[#buf + 1] = string.format(
          '   <line class="errorbar-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
          util.fmt(x - cap), util.fmt(top), util.fmt(x + cap), util.fmt(top),
          color, util.fmt(width))
      end
      if series.lolims and series.lolims[i] then
        buf[#buf + 1] = string.format(
          '   <polygon class="errorbar-limit-lower" points="%s,%s %s,%s %s,%s" fill="%s"/>',
          util.fmt(x), util.fmt(bottom), util.fmt(x - cap * 0.5),
          util.fmt(bottom - cap), util.fmt(x + cap * 0.5),
          util.fmt(bottom - cap), color)
      else
        buf[#buf + 1] = string.format(
          '   <line class="errorbar-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
          util.fmt(x - cap), util.fmt(bottom), util.fmt(x + cap),
          util.fmt(bottom), color, util.fmt(width))
      end
      if series.xerr then
        local left = map_x(series.x[i] - xerr_lower)
        local right = map_x(series.x[i] + xerr_upper)
        local center = map_y(y)
        buf[#buf + 1] = string.format(
          '   <line class="errorbar" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
          util.fmt(left), util.fmt(center), util.fmt(right), util.fmt(center),
          color, util.fmt(width))
        if series.xlolims and series.xlolims[i] then
          buf[#buf + 1] = string.format(
            '   <polygon class="errorbar-limit-left" points="%s,%s %s,%s %s,%s" fill="%s"/>',
            util.fmt(left), util.fmt(center), util.fmt(left + cap),
            util.fmt(center - cap * 0.5), util.fmt(left + cap),
            util.fmt(center + cap * 0.5), color)
        else
          buf[#buf + 1] = string.format(
            '   <line class="errorbar-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
            util.fmt(left), util.fmt(center - cap), util.fmt(left),
            util.fmt(center + cap), color, util.fmt(width))
        end
        if series.xuplims and series.xuplims[i] then
          buf[#buf + 1] = string.format(
            '   <polygon class="errorbar-limit-right" points="%s,%s %s,%s %s,%s" fill="%s"/>',
            util.fmt(right), util.fmt(center), util.fmt(right - cap),
            util.fmt(center - cap * 0.5), util.fmt(right - cap),
            util.fmt(center + cap * 0.5), color)
        else
          buf[#buf + 1] = string.format(
            '   <line class="errorbar-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
            util.fmt(right), util.fmt(center - cap), util.fmt(right),
            util.fmt(center + cap), color, util.fmt(width))
        end
      end
    end
  end
  buf[#buf + 1] = '  </g>'
  render_line(series, map_x, map_y, buf)
end

local function hist_step_points(series, map_x, map_y, baseline, horizontal)
  local points = {}
  local function add(x, y)
    points[#points + 1] = util.fmt(x) .. "," .. util.fmt(y)
  end
  if horizontal then
    add(baseline, map_y(series.edges[1]))
    for index = 1, #series.counts do
      local x = map_x(series.counts[index])
      add(x, map_y(series.edges[index]))
      add(x, map_y(series.edges[index + 1]))
    end
    add(baseline, map_y(series.edges[#series.edges]))
  else
    add(map_x(series.edges[1]), baseline)
    for index = 1, #series.counts do
      local y = map_y(series.counts[index])
      add(map_x(series.edges[index]), y)
      add(map_x(series.edges[index + 1]), y)
    end
    add(map_x(series.edges[#series.edges]), baseline)
  end
  return table.concat(points, " ")
end

local function render_hist(series, map_x, map_y, y_baseline, x_baseline, buf)
  local style = series.style
  local opacity = ""
  if style.alpha < 1 then
    local a = util.fmt(style.alpha)
    opacity = string.format(' fill-opacity="%s" stroke-opacity="%s"', a, a)
  end
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', attribute(style.label))
  end
  local horizontal = series.orientation == "horizontal"
  local orientation = horizontal and "horizontal" or "vertical"
  local histtype = series.histtype or "bar"
  local edge = style.edgecolor or "#ffffff"

  buf[#buf + 1] = string.format(
    '  <g class="series series-hist"%s data-orientation="%s" data-histtype="%s">',
    label, orientation, histtype)
  if histtype == "step" or histtype == "stepfilled" then
    local points = hist_step_points(series, map_x, map_y,
      horizontal and x_baseline or y_baseline, horizontal)
    if histtype == "step" then
      local stroke_opacity = ""
      if style.alpha < 1 then
        stroke_opacity = string.format(' stroke-opacity="%s"',
          util.fmt(style.alpha))
      end
      buf[#buf + 1] = string.format(
        '   <polyline class="hist-step" points="%s" fill="none" stroke="%s" stroke-width="%s"%s/>',
        points, style.color, util.fmt(style.linewidth or 1), stroke_opacity)
    else
      local fill = style.color
      if style.hatch then
        fill = "url(#" .. hatch_id(style.hatch, fill) .. ")"
      end
      local stroke = style.edgecolor or style.color
      buf[#buf + 1] = string.format(
        '   <polygon class="hist-step-filled" points="%s" fill="%s" stroke="%s" stroke-width="%s"%s/>',
        points, fill, stroke, util.fmt(style.linewidth or 1), opacity)
    end
  else
    for i = 1, #series.counts do
      local count = series.counts[i]
      if count > 0 then
        if horizontal then
          local y1 = map_y(series.edges[i])
          local y2 = map_y(series.edges[i + 1])
          local value_x = map_x(count)
          local left = math.min(x_baseline, value_x)
          local top = math.min(y1, y2)
          local fill = style.color
          if style.hatch then
            fill = "url(#" .. hatch_id(style.hatch, fill) .. ")"
          end
          buf[#buf + 1] = string.format(
            '   <rect class="hist-bin" x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="%s" stroke-width="%s"%s/>',
            util.fmt(left), util.fmt(top),
            util.fmt(math.abs(value_x - x_baseline)),
            util.fmt(math.abs(y2 - y1)), fill, edge,
            util.fmt(style.linewidth or 1), opacity)
        else
          local x1 = map_x(series.edges[i])
          local x2 = map_x(series.edges[i + 1])
          local top = map_y(count)
          local fill = style.color
          if style.hatch then
            fill = "url(#" .. hatch_id(style.hatch, fill) .. ")"
          end
          buf[#buf + 1] = string.format(
            '   <rect class="hist-bin" x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="%s" stroke-width="%s"%s/>',
            util.fmt(x1), util.fmt(top), util.fmt(x2 - x1),
            util.fmt(y_baseline - top), fill, edge,
            util.fmt(style.linewidth or 1), opacity)
        end
      end
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
    if style.hatch then fill = "url(#" .. hatch_id(style.hatch, fill) .. ")" end
    buf[#buf + 1] = string.format(
      '   <rect class="barh" x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="%s" stroke-width="%s"%s/>',
      util.fmt(left), util.fmt(top), util.fmt(width), util.fmt(height), fill,
      edge, util.fmt(style.linewidth or 1), opacity)
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

local function render_broken_barh(series, map_x, map_y, buf)
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
  buf[#buf + 1] = string.format(
    '  <g class="series series-broken-barh" data-y="%s" data-height="%s"%s>',
    util.fmt(series.y), util.fmt(series.height), label)
  for index, range in ipairs(series.ranges) do
    local x1 = map_x(range[1])
    local x2 = map_x(range[1] + range[2])
    local y1 = map_y(series.y)
    local y2 = map_y(series.y + series.height)
    local left, right = math.min(x1, x2), math.max(x1, x2)
    local top, bottom = math.min(y1, y2), math.max(y1, y2)
    buf[#buf + 1] = string.format(
      '   <rect class="broken-barh" data-index="%d" data-start="%s" data-width="%s" x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="%s" stroke-width="%s"%s/>',
      index, util.fmt(range[1]), util.fmt(range[2]), util.fmt(left),
      util.fmt(top), util.fmt(right - left), util.fmt(bottom - top),
      style.color, edge, util.fmt(style.linewidth or 1), opacity)
  end
  buf[#buf + 1] = '  </g>'
end

local function fill_polygon_points(run, map_x, map_y)
  local points = {}
  if run.kind == "fillx" then
    for index = 1, #run.y do
      points[#points + 1] = string.format("%s,%s", util.fmt(map_x(run.x1[index])),
        util.fmt(map_y(run.y[index])))
    end
    for index = #run.y, 1, -1 do
      points[#points + 1] = string.format("%s,%s", util.fmt(map_x(run.x2[index])),
        util.fmt(map_y(run.y[index])))
    end
  else
    for index = 1, #run.x do
      points[#points + 1] = string.format("%s,%s", util.fmt(map_x(run.x[index])),
        util.fmt(map_y(run.y1[index])))
    end
    for index = #run.x, 1, -1 do
      points[#points + 1] = string.format("%s,%s", util.fmt(map_x(run.x[index])),
        util.fmt(map_y(run.y2[index])))
    end
  end
  return table.concat(points, " ")
end

local function render_fill(series, map_x, map_y, buf)
  local style = series.style
  local opacity = ""
  if style.alpha < 1 then opacity = string.format(' fill-opacity="%s"',
    util.fmt(style.alpha)) end
  if series.where == nil and not series.interpolate then
    local points = fill_polygon_points({
      kind = "fill", x = series.x, y1 = series.y1, y2 = series.y2,
    }, map_x, map_y)
    local stack = ""
    if series.stack_baseline ~= nil then
      stack = string.format(' data-stack="true" data-baseline="%s" data-index="%d"',
        series.stack_baseline, series.stack_index or 1)
    end
    local fill = style.color
    if style.hatch then fill = "url(#" .. hatch_id(style.hatch, fill) .. ")" end
    buf[#buf + 1] = string.format(
      '  <polygon class="fill-between"%s points="%s" fill="%s"%s stroke="%s" stroke-width="1"/>',
      stack, points, fill, opacity, style.edgecolor or style.color)
    return
  end

  local segments = area.segments(series)
  buf[#buf + 1] = string.format(
    '  <g class="series series-fill" data-where="masked" data-interpolate="%s" data-segments="%d">',
    series.interpolate and "true" or "false", #segments)
  for index, run in ipairs(segments) do
    local fill = style.color
    if style.hatch then fill = "url(#" .. hatch_id(style.hatch, fill) .. ")" end
    buf[#buf + 1] = string.format(
      '   <polygon class="fill-between" data-index="%d" points="%s" fill="%s"%s stroke="%s" stroke-width="1"/>',
      index, fill_polygon_points(run, map_x, map_y), fill, opacity,
      style.edgecolor or style.color)
  end
  buf[#buf + 1] = '  </g>'
end

local function render_fillx(series, map_x, map_y, buf)
  local style = series.style
  if series.where == nil and not series.interpolate then
    local points = fill_polygon_points({
      kind = "fillx", y = series.y, x1 = series.x1, x2 = series.x2,
    }, map_x, map_y)
    local fill = style.color
    if style.hatch then fill = "url(#" .. hatch_id(style.hatch, fill) .. ")" end
    buf[#buf + 1] = string.format(
      '  <polygon class="fill-betweenx" points="%s" fill="%s" fill-opacity="%s" stroke="%s" stroke-width="1"/>',
      points, fill, util.fmt(style.alpha),
      style.edgecolor or style.color)
    return
  end

  local segments = area.segments(series)
  local opacity = ""
  if style.alpha < 1 then opacity = string.format(' fill-opacity="%s"',
    util.fmt(style.alpha)) end
  buf[#buf + 1] = string.format(
    '  <g class="series series-fillx" data-where="masked" data-interpolate="%s" data-segments="%d">',
    series.interpolate and "true" or "false", #segments)
  for index, run in ipairs(segments) do
    local fill = style.color
    if style.hatch then fill = "url(#" .. hatch_id(style.hatch, fill) .. ")" end
    buf[#buf + 1] = string.format(
      '   <polygon class="fill-betweenx" data-index="%d" points="%s" fill="%s"%s stroke="%s" stroke-width="1"/>',
      index, fill_polygon_points(run, map_x, map_y), fill, opacity,
      style.edgecolor or style.color)
  end
  buf[#buf + 1] = '  </g>'
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
  local metadata = ""
  if series.ecdf then
    metadata = ' data-ecdf="true"'
    if series.complementary then
      metadata = metadata .. ' data-complementary="true"'
    end
  end
  if series.fill then metadata = metadata .. ' data-fill="true"' end
  buf[#buf + 1] = string.format('  <g class="series series-step"%s>',
    metadata)
  if series.fill then
    local baseline = map_y(0)
    local polygon = {}
    for index = 1, #xs do
      polygon[#polygon + 1] = util.fmt(map_x(xs[index])) .. "," ..
        util.fmt(ys[index])
    end
    for index = #xs, 1, -1 do
      polygon[#polygon + 1] = util.fmt(map_x(xs[index])) .. "," ..
        util.fmt(baseline)
    end
    buf[#buf + 1] = string.format(
      '   <polygon class="step-fill" points="%s" fill="%s" fill-opacity="%s" stroke="none"/>',
      table.concat(polygon, " "), series.style.color,
      util.fmt(series.fillalpha or 0.2))
  end
  render_line({ x = xs, y = ys, style = series.style, kind = "line" },
    map_x, map_y, buf)
  buf[#buf + 1] = '  </g>'
end

local function render_stem(series, map_x, map_y, buf)
  local style = series.style
  local horizontal = series.orientation == "horizontal"
  local baseline = horizontal and map_x(series.base or 0) or
    map_y(series.base or 0)
  local dash = ""
  if style.linestyle == "dashed" then dash = ' stroke-dasharray="6 4"'
  elseif style.linestyle == "dotted" then dash = ' stroke-dasharray="1.5 3"' end
  local line_opacity = ""
  if style.alpha < 1 then
    line_opacity = string.format(' stroke-opacity="%s"', util.fmt(style.alpha))
  end
  local marker_opacity = ""
  local marker_outline = ""
  if style.alpha < 1 then
    local alpha = util.fmt(style.alpha)
    marker_opacity = string.format(' fill-opacity="%s"', alpha)
    if style.markeredgecolor ~= nil then
      marker_outline = string.format(' stroke-opacity="%s"', alpha)
    end
  end
  local marker_fill = style.markerfacecolor or style.color
  if style.markeredgecolor ~= nil then
    marker_outline = string.format(' stroke="%s" stroke-width="%s"%s',
      style.markeredgecolor, util.fmt(style.markeredgewidth or 1),
      marker_outline)
  end
  buf[#buf + 1] = string.format(
    '  <g class="series series-stem" data-base="%s" data-marker="%s" data-linestyle="%s" data-orientation="%s">',
    util.fmt(series.base or 0), style.marker or "none",
    style.linestyle or "solid",
    horizontal and "horizontal" or "vertical")
  for i = 1, #series.x do
    local value = horizontal and map_x(series.y[i]) or map_y(series.y[i])
    local position = horizontal and map_y(series.x[i]) or map_x(series.x[i])
    if style.linestyle ~= "none" then
      local x1, y1, x2, y2
      if horizontal then
        x1, y1, x2, y2 = baseline, position, value, position
      else
        x1, y1, x2, y2 = position, baseline, position, value
      end
      buf[#buf + 1] = string.format(
        '   <line class="stem-line" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s%s/>',
        util.fmt(x1), util.fmt(y1), util.fmt(x2), util.fmt(y2),
        style.color, util.fmt(style.linewidth or 1.5), dash, line_opacity)
    end
    if style.marker ~= nil then
      buf[#buf + 1] = markers.svg(style.marker, "stem-marker", value,
        position, style.markersize or 4, marker_fill, marker_opacity,
        marker_outline)
    end
  end
  buf[#buf + 1] = '  </g>'
end

local function render_contour(series, map_x, map_y, buf)
  local dash = ""
  if series.style.linestyle == "dashed" then dash = ' stroke-dasharray="6 4"'
  elseif series.style.linestyle == "dotted" then dash = ' stroke-dasharray="2 3"' end
  buf[#buf + 1] = '  <g class="contour">'
  for _, segment in ipairs(series.segments) do
    buf[#buf + 1] = string.format(
      '   <line class="contour-segment" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s/>',
      util.fmt(map_x(segment[1])), util.fmt(map_y(segment[2])),
      util.fmt(map_x(segment[3])), util.fmt(map_y(segment[4])),
      series.style.color, util.fmt(series.style.linewidth), dash)
  end
  if series.level_label and series.segments[1] then
    local segment = series.segments[1]
    local x = (map_x(segment[1]) + map_x(segment[3])) / 2
    local y = (map_y(segment[2]) + map_y(segment[4])) / 2
    buf[#buf + 1] = string.format(
      '   <text class="contour-label" x="%s" y="%s" font-size="10" fill="%s">%s</text>',
      util.fmt(x), util.fmt(y), series.style.color, util.fmt(series.level_label))
  end
  buf[#buf + 1] = '  </g>'
end

local function render_violin(series, map_x, map_y, buf)
  local style = series.style
  local horizontal = series.orientation == "horizontal"
  local value_map = horizontal and map_x or map_y
  local position_map = horizontal and map_y or map_x
  local points = {}
  for index = 1, #series.body_x do
    points[index] = util.fmt(map_x(series.body_x[index])) .. "," ..
      util.fmt(map_y(series.body_y[index]))
  end
  local label = ""
  if style.label ~= nil then
    label = string.format(' data-label="%s"', attribute(style.label))
  end
  buf[#buf + 1] = string.format(
    '  <g class="series series-violin" data-position="%s" data-width="%s" data-points="%d" data-bandwidth="%s" data-min="%s" data-max="%s" data-mean="%s" data-q1="%s" data-median="%s" data-q3="%s" data-showmeans="%s" data-meanline="%s" data-orientation="%s"%s>',
    util.fmt(series.position), util.fmt(series.width), series.points,
    util.fmt(series.bandwidth),
    util.fmt(series.minimum), util.fmt(series.maximum), util.fmt(series.mean),
    util.fmt(series.q1), util.fmt(series.median), util.fmt(series.q3),
    series.showmeans and "true" or "false",
    series.meanline and "true" or "false",
    horizontal and "horizontal" or "vertical", label)
  buf[#buf + 1] = string.format(
    '   <polygon class="violin-body" points="%s" fill="%s" fill-opacity="%s" stroke="%s" stroke-width="%s"/>',
    table.concat(points, " "), style.color, util.fmt(style.alpha),
    style.edgecolor or style.color, util.fmt(style.linewidth or 1))
  local center = position_map(series.position)
  if horizontal then
    buf[#buf + 1] = string.format(
      '   <line class="violin-center" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',
      util.fmt(value_map(series.minimum)), util.fmt(center),
      util.fmt(value_map(series.maximum)), util.fmt(center),
      style.edgecolor or style.color)
  else
    buf[#buf + 1] = string.format(
      '   <line class="violin-center" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',
      util.fmt(center), util.fmt(value_map(series.minimum)),
      util.fmt(center), util.fmt(value_map(series.maximum)),
      style.edgecolor or style.color)
  end
  if series.showquartiles then
    for _, value in ipairs({ series.q1, series.q3 }) do
      if horizontal then
        local low = position_map(series.position - series.width * 0.25)
        local high = position_map(series.position + series.width * 0.25)
        buf[#buf + 1] = string.format(
          '   <line class="violin-quartile" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1" stroke-dasharray="3 2"/>',
          util.fmt(value_map(value)), util.fmt(low),
          util.fmt(value_map(value)), util.fmt(high),
          style.edgecolor or style.color)
      else
        local half = (map_x(series.position + series.width * 0.25) -
          map_x(series.position - series.width * 0.25)) / 2
        local y = map_y(value)
        buf[#buf + 1] = string.format(
          '   <line class="violin-quartile" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1" stroke-dasharray="3 2"/>',
          util.fmt(center - half), util.fmt(y), util.fmt(center + half),
          util.fmt(y), style.edgecolor or style.color)
      end
    end
  end
  if series.showmedians then
    if horizontal then
      local low = position_map(series.position - series.width * 0.5)
      local high = position_map(series.position + series.width * 0.5)
      buf[#buf + 1] = string.format(
        '   <line class="violin-median" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
        util.fmt(value_map(series.median)), util.fmt(low),
        util.fmt(value_map(series.median)), util.fmt(high),
        style.edgecolor or style.color)
    else
      local half = (map_x(series.position + series.width * 0.5) -
        map_x(series.position - series.width * 0.5)) / 2
      local y = map_y(series.median)
      buf[#buf + 1] = string.format(
        '   <line class="violin-median" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
        util.fmt(center - half), util.fmt(y), util.fmt(center + half),
        util.fmt(y), style.edgecolor or style.color)
    end
  end
  if series.showextrema then
    for _, value in ipairs({ series.minimum, series.maximum }) do
      if horizontal then
        buf[#buf + 1] = string.format(
          '   <circle class="violin-extrema" cx="%s" cy="%s" r="2.5" fill="%s"/>',
          util.fmt(value_map(value)), util.fmt(center),
          style.edgecolor or style.color)
      else
        buf[#buf + 1] = string.format(
          '   <circle class="violin-extrema" cx="%s" cy="%s" r="2.5" fill="%s"/>',
          util.fmt(center), util.fmt(value_map(value)),
          style.edgecolor or style.color)
      end
    end
  end
  if series.showmeans then
    if horizontal then
      if series.meanline then
        local low = position_map(series.position - series.width * 0.5)
        local high = position_map(series.position + series.width * 0.5)
        buf[#buf + 1] = string.format(
          '   <line class="violin-mean-line" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5" stroke-dasharray="4 2"/>',
          util.fmt(value_map(series.mean)), util.fmt(low),
          util.fmt(value_map(series.mean)), util.fmt(high),
          style.edgecolor or style.color)
      else
        buf[#buf + 1] = string.format(
          '   <circle class="violin-mean-marker" cx="%s" cy="%s" r="3" fill="%s"/>',
          util.fmt(value_map(series.mean)), util.fmt(center),
          style.edgecolor or style.color)
      end
    elseif series.meanline then
      local half = (map_x(series.position + series.width * 0.5) -
        map_x(series.position - series.width * 0.5)) / 2
      buf[#buf + 1] = string.format(
        '   <line class="violin-mean-line" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5" stroke-dasharray="4 2"/>',
        util.fmt(center - half), util.fmt(map_y(series.mean)),
        util.fmt(center + half), util.fmt(map_y(series.mean)),
        style.edgecolor or style.color)
    else
      buf[#buf + 1] = string.format(
        '   <circle class="violin-mean-marker" cx="%s" cy="%s" r="3" fill="%s"/>',
        util.fmt(center), util.fmt(map_y(series.mean)),
        style.edgecolor or style.color)
    end
  end
  buf[#buf + 1] = '  </g>'
end
local function render_box(series, map_x, map_y, buf)
  local color = series.style.color
  local horizontal = series.orientation == "horizontal"
  local half = series.width / 2
  local low_position = series.position - half
  local high_position = series.position + half
  local position_a = horizontal and map_y(low_position) or map_x(low_position)
  local position_b = horizontal and map_y(high_position) or map_x(high_position)
  local q1_screen = horizontal and map_x(series.q1) or map_y(series.q1)
  local q3_screen = horizontal and map_x(series.q3) or map_y(series.q3)
  local center = horizontal and map_y(series.position) or map_x(series.position)
  local low_screen = horizontal and map_x(series.low) or map_y(series.low)
  local high_screen = horizontal and map_x(series.high) or map_y(series.high)
  local median_screen = horizontal and map_x(series.median) or
    map_y(series.median)
  local mean_screen = horizontal and map_x(series.mean) or
    map_y(series.mean)
  local cap_a = horizontal and map_y(series.position - half + 0.1) or
    map_x(series.position - half + 0.1)
  local cap_b = horizontal and map_y(series.position + half - 0.1) or
    map_x(series.position + half - 0.1)

  local rect_left = math.min(horizontal and q1_screen or position_a,
    horizontal and q3_screen or position_b)
  local rect_top = math.min(horizontal and position_a or q1_screen,
    horizontal and position_b or q3_screen)
  local rect_width = math.abs(horizontal and (q3_screen - q1_screen) or
    (position_b - position_a))
  local rect_height = math.abs(horizontal and (position_b - position_a) or
    (q3_screen - q1_screen))

  buf[#buf + 1] = string.format(
    '  <g class="series series-box" data-position="%s" data-orientation="%s" data-width="%s" data-mean="%s" data-showmeans="%s" data-meanline="%s" data-notch="%s" data-whis="%s" data-showfliers="%s">',
    util.fmt(series.position), horizontal and "horizontal" or "vertical",
    util.fmt(series.width), util.fmt(series.mean),
    series.showmeans and "true" or "false",
    series.meanline and "true" or "false", series.notch and "true" or "false",
    util.fmt(series.whis or 1.5), series.showfliers == false and "false" or "true")
  if series.notch then
    local function point(position, value)
      if horizontal then
        return util.fmt(map_x(value)) .. "," .. util.fmt(map_y(position))
      end
      return util.fmt(map_x(position)) .. "," .. util.fmt(map_y(value))
    end
    local low_position = series.position - half
    local high_position = series.position + half
    local notch_points = {
      point(low_position, series.q3),
      point(high_position, series.q3),
      point(high_position, series.notch_high),
      point(series.position, series.median),
      point(high_position, series.notch_low),
      point(high_position, series.q1),
      point(low_position, series.q1),
      point(low_position, series.notch_low),
      point(series.position, series.median),
      point(low_position, series.notch_high),
    }
    buf[#buf + 1] = string.format(
      '   <polygon class="box box-notch" points="%s" fill="%s" fill-opacity="0.25" stroke="%s" stroke-width="1.5"/>',
      table.concat(notch_points, " "), color, color)
  else
    buf[#buf + 1] = string.format(
      '   <rect class="box" x="%s" y="%s" width="%s" height="%s" fill="%s" fill-opacity="0.25" stroke="%s" stroke-width="1.5"/>',
      util.fmt(rect_left), util.fmt(rect_top), util.fmt(rect_width),
      util.fmt(rect_height), color, color)
  end
  if horizontal then
    buf[#buf + 1] = string.format(
      '   <line class="box-median" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
      util.fmt(median_screen), util.fmt(math.min(position_a, position_b)),
      util.fmt(median_screen), util.fmt(math.max(position_a, position_b)), color)
    buf[#buf + 1] = string.format(
      '   <line class="box-whisker" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5"/>',
      util.fmt(q3_screen), util.fmt(center), util.fmt(high_screen),
      util.fmt(center), color)
    buf[#buf + 1] = string.format(
      '   <line class="box-whisker" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5"/>',
      util.fmt(low_screen), util.fmt(center), util.fmt(q1_screen),
      util.fmt(center), color)
    buf[#buf + 1] = string.format(
      '   <line class="box-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
      util.fmt(high_screen), util.fmt(cap_a), util.fmt(high_screen),
      util.fmt(cap_b), color)
    buf[#buf + 1] = string.format(
      '   <line class="box-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
      util.fmt(low_screen), util.fmt(cap_a), util.fmt(low_screen),
      util.fmt(cap_b), color)
  else
    buf[#buf + 1] = string.format(
      '   <line class="box-median" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
      util.fmt(math.min(position_a, position_b)), util.fmt(median_screen),
      util.fmt(math.max(position_a, position_b)), util.fmt(median_screen), color)
    buf[#buf + 1] = string.format(
      '   <line class="box-whisker" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5"/>',
      util.fmt(center), util.fmt(q3_screen), util.fmt(center),
      util.fmt(high_screen), color)
    buf[#buf + 1] = string.format(
      '   <line class="box-whisker" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5"/>',
      util.fmt(center), util.fmt(low_screen), util.fmt(center),
      util.fmt(q1_screen), color)
    buf[#buf + 1] = string.format(
      '   <line class="box-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
      util.fmt(cap_a), util.fmt(high_screen), util.fmt(cap_b),
      util.fmt(high_screen), color)
    buf[#buf + 1] = string.format(
      '   <line class="box-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',
      util.fmt(cap_a), util.fmt(low_screen), util.fmt(cap_b),
      util.fmt(low_screen), color)
  end
  if series.showmeans then
    if series.meanline then
      if horizontal then
        buf[#buf + 1] = string.format(
          '   <line class="box-mean-line" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5" stroke-dasharray="4 2"/>',
          util.fmt(mean_screen), util.fmt(math.min(position_a, position_b)),
          util.fmt(mean_screen), util.fmt(math.max(position_a, position_b)),
          color)
      else
        buf[#buf + 1] = string.format(
          '   <line class="box-mean-line" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5" stroke-dasharray="4 2"/>',
          util.fmt(math.min(position_a, position_b)), util.fmt(mean_screen),
          util.fmt(math.max(position_a, position_b)), util.fmt(mean_screen),
          color)
      end
    elseif horizontal then
      buf[#buf + 1] = string.format(
        '   <circle class="box-mean-marker" cx="%s" cy="%s" r="3" fill="%s"/>',
        util.fmt(mean_screen), util.fmt(center), color)
    else
      buf[#buf + 1] = string.format(
        '   <circle class="box-mean-marker" cx="%s" cy="%s" r="3" fill="%s"/>',
        util.fmt(center), util.fmt(mean_screen), color)
    end
  end
  if series.showfliers ~= false then
    for _, value in ipairs(series.outliers) do
      if horizontal then
      buf[#buf + 1] = string.format(
        '   <circle class="box-outlier" cx="%s" cy="%s" r="3" fill="none" stroke="%s" stroke-width="1.5"/>',
        util.fmt(map_x(value)), util.fmt(center), color)
    else
        buf[#buf + 1] = string.format(
          '   <circle class="box-outlier" cx="%s" cy="%s" r="3" fill="none" stroke="%s" stroke-width="1.5"/>',
          util.fmt(center), util.fmt(map_y(value)), color)
      end
    end
  end
  buf[#buf + 1] = '  </g>'
end
local HATCH_PATTERNS = {
  ["/"] = { transform = "rotate(45)", body = '<line x1="0" y1="0" x2="0" y2="6" stroke="#333" stroke-width="1"/>' },
  ["\\"] = { transform = "rotate(-45)", body = '<line x1="0" y1="0" x2="0" y2="6" stroke="#333" stroke-width="1"/>' },
  ["|"] = { body = '<line x1="0" y1="0" x2="0" y2="6" stroke="#333" stroke-width="1"/>' },
  ["-"] = { body = '<line x1="0" y1="3" x2="6" y2="3" stroke="#333" stroke-width="1"/>' },
  ["+"] = { body = '<line x1="0" y1="3" x2="6" y2="3" stroke="#333" stroke-width="1"/><line x1="3" y1="0" x2="3" y2="6" stroke="#333" stroke-width="1"/>' },
  x = { body = '<path d="M0,0 L6,6 M6,0 L0,6" stroke="#333" stroke-width="1"/>' },
  ["."] = { body = '<circle cx="3" cy="3" r="1" fill="#333"/>' },
  o = { body = '<circle cx="3" cy="3" r="2" fill="none" stroke="#333" stroke-width="1"/>' },
}

hatch_id = function(hatch, color)
  return "hatch-" .. hatch:gsub("[^%w]", "x") .. "-" ..
    color:gsub("[^%w]", "")
end

local function hatch_defs(fig)
  local out, seen = {}, {}
  local function add(hatch, color)
    if not hatch or seen[hatch .. color] then return end
    seen[hatch .. color] = true
    local spec = HATCH_PATTERNS[hatch]
    if not spec then return end
    out[#out + 1] = string.format(
      '  <pattern id="%s" patternUnits="userSpaceOnUse" width="6" height="6"%s>',
      hatch_id(hatch, color), spec.transform and (' patternTransform="' .. spec.transform .. '"') or "")
    out[#out + 1] = '   <rect width="6" height="6" fill="' .. color .. '" fill-opacity="0.15"/>'
    out[#out + 1] = '   ' .. spec.body
    out[#out + 1] = '  </pattern>'
  end
  for _, series in ipairs(fig._series) do
    local style = series.style
    if style and style.hatch then
      add(style.hatch, style.color)
      if series.bar_colors then
        for _, color in ipairs(series.bar_colors) do add(style.hatch, color) end
      end
    end
  end
  return table.concat(out, "\n")
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
  local yerr_meta = ""
  if series.yerr_lower ~= nil then
    yerr_meta = ' data-yerr="true"'
    if series.yerr_asymmetric then
      yerr_meta = yerr_meta .. ' data-yerr-mode="asymmetric"'
    end
  end
  local color_meta = series.bar_colors ~= nil and
    ' data-per-bar-colors="true"' or ""
  buf[#buf + 1] = string.format('  <g class="series series-bar"%s%s%s>',
    label, yerr_meta, color_meta)
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
    if style.hatch then fill = "url(#" .. hatch_id(style.hatch, fill) .. ")" end
    buf[#buf + 1] = string.format(
      '   <rect class="bar" x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="%s" stroke-width="%s"%s/>',
      util.fmt(x1), util.fmt(top), util.fmt(x2 - x1), util.fmt(height),
      fill, edge, util.fmt(style.linewidth or 1), opacity)
    if series.yerr_lower ~= nil then
      local reference = value
      if series.bottom ~= nil then reference = series.bottom[i] + value end
      local upper_y = map_y(reference + series.yerr_upper[i])
      local lower_y = map_y(reference - series.yerr_lower[i])
      local center_x = (x1 + x2) / 2
      local error_color = series.ecolor or style.color
      local error_width = series.elinewidth or 1
      local cap = series.capsize or 4
      buf[#buf + 1] = string.format(
        '   <line class="bar-error" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
        util.fmt(center_x), util.fmt(upper_y), util.fmt(center_x),
        util.fmt(lower_y), error_color, util.fmt(error_width))
      buf[#buf + 1] = string.format(
        '   <line class="bar-error-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
        util.fmt(center_x - cap), util.fmt(upper_y),
        util.fmt(center_x + cap), util.fmt(upper_y), error_color,
        util.fmt(error_width))
      buf[#buf + 1] = string.format(
        '   <line class="bar-error-cap" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
        util.fmt(center_x - cap), util.fmt(lower_y),
        util.fmt(center_x + cap), util.fmt(lower_y), error_color,
        util.fmt(error_width))
    end
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
  if annotation.background ~= nil then
    local background = annotation.background
    local box = text.bounds(text_x, text_y, annotation.text, fontsize, anchor)
    local pad = background.pad or 3
    local stroke = ""
    if background.edgecolor ~= nil then
      stroke = string.format(' stroke="%s" stroke-width="1"',
        background.edgecolor)
    end
    buf[#buf + 1] = string.format(
      '    <rect class="annotation-background" x="%s" y="%s" width="%s" height="%s" rx="2" fill="%s" fill-opacity="%s"%s/>',
      util.fmt(box.x - pad), util.fmt(box.y - pad),
      util.fmt(box.width + 2 * pad), util.fmt(box.height + 2 * pad),
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
  local rotation = annotation.rotation or 0
  local rotation_attr = ""
  if rotation ~= 0 then
    rotation_attr = string.format(' transform="rotate(%s %s %s)"',
      util.fmt(rotation), util.fmt(text_x), util.fmt(text_y))
  end
  buf[#buf + 1] = string.format(
    '    <text class="annotation-text" x="%s" y="%s" font-size="%s" fill="%s" text-anchor="%s" data-align="%s"%s>%s</text>',
    util.fmt(text_x), util.fmt(text_y), util.fmt(fontsize), color, anchor, align,
    rotation_attr, util.escape_xml(annotation.text))
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
  add(string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" version="1.1" data-dpi="%s" data-pie="true" data-labeldistance="%s" data-pctdistance="%s" data-labelsize="%s" data-labelcolor="%s" data-pctsize="%s" data-pctcolor="%s" data-rotatelabels="%s" data-counterclock="%s">',
    util.fmt(width), util.fmt(height), util.fmt(width), util.fmt(height),
    util.fmt(fig.dpi), util.fmt(pie.labeldistance or 1.08),
    util.fmt(pie.pctdistance or 0.64), util.fmt(pie.labelsize or 12),
    pie.labelcolor or "#222222", util.fmt(pie.pctsize or 12),
    pie.pctcolor or "#ffffff",
    pie.rotatelabels and "true" or "false",
    pie.counterclock and "true" or "false"))
  add(' <desc>Generated by luaplotlib, a pure-Lua SVG plotting library.</desc>')
  add(' <rect class="background" width="' .. util.fmt(width) .. '" height="' ..
    util.fmt(height) .. '" fill="#ffffff"/>')
  if fig._title ~= nil then
    local title_x, title_anchor = cx, "middle"
    if fig._title_loc == "left" then
      title_x, title_anchor = width * 0.05, "start"
    elseif fig._title_loc == "right" then
      title_x, title_anchor = width * 0.95, "end"
    end
    add(string.format(' <text class="title" x="%s" y="28" font-size="%s" fill="%s" text-anchor="%s">%s</text>',
      util.fmt(title_x), util.fmt(fig._title_fontsize or 18),
      fig._title_color or "#222222", title_anchor,
      util.escape_xml(fig._title)))
  end
  add(' <g class="pie" font-family="Helvetica, Arial, sans-serif">')
  for index, slice in ipairs(pie.slices) do
    local sweep = math.abs(slice.end_angle - slice.start_angle)
    if sweep > 0 then
      local middle = (slice.start_angle + slice.end_angle) / 2
      local arc_sweep = slice.end_angle < slice.start_angle and 1 or 0
      local offset = radius * (slice.explode or 0)
      local slice_cx, slice_cy = pie_point(cx, cy, offset, middle)
      local x1, y1 = pie_point(slice_cx, slice_cy, radius, slice.start_angle)
      local x2, y2 = pie_point(slice_cx, slice_cy, radius, slice.end_angle)
      local large = sweep > 180 and 1 or 0
      if pie.shadow then
        add(string.format('  <path class="pie-shadow" d="M %s %s L %s %s A %s %s 0 %d %d %s %s Z" fill="#000000" fill-opacity="0.18"/>',
          util.fmt(slice_cx + 4), util.fmt(slice_cy + 4),
          util.fmt(x1 + 4), util.fmt(y1 + 4), util.fmt(radius),
          util.fmt(radius), large, arc_sweep, util.fmt(x2 + 4),
          util.fmt(y2 + 4)))
      end
      add(string.format('  <path class="pie-slice" data-explode="%s" d="M %s %s L %s %s A %s %s 0 %d %d %s %s Z" fill="%s" stroke="%s" stroke-width="%s"/>',
        util.fmt(slice.explode or 0), util.fmt(slice_cx), util.fmt(slice_cy),
        util.fmt(x1), util.fmt(y1), util.fmt(radius), util.fmt(radius),
        large, arc_sweep, util.fmt(x2), util.fmt(y2), slice.color,
        pie.edgecolor or "#ffffff", util.fmt(pie.linewidth or 1.5)))
      if pie.autopct then
        local tx, ty = pie_point(slice_cx, slice_cy, radius * (pie.pctdistance or 0.64), middle)
        local format_string = pie.autopct == true and "%.1f%%" or pie.autopct
        local ok, text = pcall(string.format, format_string, slice.percent)
        if not ok then text = string.format("%.1f%%", slice.percent) end
        add(string.format('  <text class="pie-percent" x="%s" y="%s" font-size="%s" fill="%s" text-anchor="middle">%s</text>',
          util.fmt(tx), util.fmt(ty + 4), util.fmt(pie.pctsize or 12),
          pie.pctcolor or "#ffffff", util.escape_xml(text)))
      end
      local lx, ly = pie_point(slice_cx, slice_cy, radius * (pie.labeldistance or 1.08), middle)
      local edge_x, edge_y = pie_point(slice_cx, slice_cy, radius, middle)
      add(string.format('  <line class="pie-label-line" x1="%s" y1="%s" x2="%s" y2="%s" stroke="#777777" stroke-width="1"/>',
        util.fmt(edge_x), util.fmt(edge_y), util.fmt(lx), util.fmt(ly)))
      local anchor = math.cos(math.rad(middle)) >= 0 and "start" or "end"
      local rotation = 0
      if pie.rotatelabels then
        local normalized = middle % 360
        if normalized < 0 then normalized = normalized + 360 end
        rotation = -normalized
        if normalized > 90 and normalized < 270 then
          rotation = rotation + 180
        end
      end
      local transform = ""
      if rotation ~= 0 then
        transform = string.format(' transform="rotate(%s %s %s)"',
          util.fmt(rotation), util.fmt(lx), util.fmt(ly + 4))
      end
      add(string.format('  <text class="pie-label" x="%s" y="%s" font-size="%s" fill="%s" text-anchor="%s"%s>%s</text>',
        util.fmt(lx), util.fmt(ly + 4), util.fmt(pie.labelsize or 12),
        pie.labelcolor or "#222222", anchor, transform,
        util.escape_xml(slice.label)))
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
    x_target, extents and extents.baseline_x or false, 0, 1)
  local yaxis = make_axis("ylim", yscale, fig._ylim,
    extents and extents.has_y and extents.min_y or nil,
    extents and extents.has_y and extents.max_y or nil,
    y_target, extents and extents.baseline_y or false, 0, 1)

  if fig._aspect ~= nil then
    apply_aspect(geom, fig._aspect, xaxis.maximum - xaxis.minimum,
      yaxis.maximum - yaxis.minimum)
    x_target, y_target = tick_count(geom.plot_width, geom.plot_height)
    xaxis = make_axis("xlim", xscale, fig._xlim,
      extents and extents.has_x and extents.min_x or nil,
      extents and extents.has_x and extents.max_x or nil,
      x_target, extents and extents.baseline_x or false, 0, 1)
    yaxis = make_axis("ylim", yscale, fig._ylim,
      extents and extents.has_y and extents.min_y or nil,
      extents and extents.has_y and extents.max_y or nil,
      y_target, extents and extents.baseline_y or false, 0, 1)
  end

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

  local categories = find_category_ticks(fig, xmin, xmax, "x")
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
  local y_categories = find_category_ticks(fig, yaxis.data_minimum,
    yaxis.data_maximum, "y")
  local y_display = {}
  if y_categories then
    for _, category in ipairs(y_categories) do
      y_display[#y_display + 1] = {
        value = category.position,
        label = category.label,
      }
    end
  elseif fig._yticks ~= nil then
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

  local minorticks = fig._minorticks or
    { enabled = false, axis = "both", subdivisions = 5 }
  local minor_axis = minorticks.axis or "both"
  local minor_subdivisions = minorticks.subdivisions or 5
  local grid_minor = fig._grid and fig._grid_opts and
    fig._grid_opts.minor == true
  local x_minor, y_minor = {}, {}
  if minorticks.enabled or grid_minor then
    if not categories then
      local major_x = {}
      for _, tick in ipairs(x_display) do
        major_x[#major_x + 1] = tick.value
      end
      x_minor = ticks.generate_minor(xmin, xmax, major_x, xscale,
        minor_subdivisions)
    end
    if not y_categories then
      local major_y = {}
      for _, tick in ipairs(y_display) do
        major_y[#major_y + 1] = tick.value
      end
      y_minor = ticks.generate_minor(yaxis.data_minimum, yaxis.data_maximum,
        major_y, yscale, minor_subdivisions)
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
  local x_baseline = geom.left
  if xscale ~= "log" then
    x_baseline = map_x(0)
  end

  local buf = {}
  local function add(line)
    buf[#buf + 1] = line
  end
  local function printf(format, ...)
    buf[#buf + 1] = string.format(format, ...)
  end

  local clip_id = "luaplotlib-plot-clip-" .. tostring(fig):gsub("%W", "")
  local aspect_metadata = ""
  if fig._aspect ~= nil then
    aspect_metadata = string.format(
      ' data-aspect="%s" data-plot-width="%s" data-plot-height="%s"',
      fig._aspect == 1 and "equal" or util.fmt(fig._aspect),
      util.fmt(geom.plot_width), util.fmt(geom.plot_height))
  end
  local labelpad_metadata = ""
  if (fig._xlabel_pad or 0) > 0 or (fig._ylabel_pad or 0) > 0 then
    labelpad_metadata = string.format(
      ' data-xlabel-pad="%s" data-ylabel-pad="%s"',
      util.fmt(fig._xlabel_pad or 0), util.fmt(fig._ylabel_pad or 0))
  end
  local tickstyle_metadata = ""
  if (fig._ticklabelsize or 11) ~= 11 or
      (fig._ticklabelcolor or "#222222") ~= "#222222" then
    tickstyle_metadata = string.format(
      ' data-ticklabelsize="%s" data-ticklabelcolor="%s"',
      util.fmt(fig._ticklabelsize or 11),
      util.escape_xml(fig._ticklabelcolor or "#222222"))
  end

  add('<?xml version="1.0" encoding="UTF-8"?>')
  printf('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" version="1.1" role="img" aria-label="%s" data-dpi="%s" data-xscale="%s" data-yscale="%s" data-minorticks="%s" data-minor-subdivisions="%d" data-minor-grid="%s"%s>',
    util.fmt(fig.width), util.fmt(fig.height),
    util.fmt(fig.width), util.fmt(fig.height),
    util.escape_xml(fig._aria_label or fig._title or "luaplotlib figure"),
    util.fmt(fig.dpi), util.escape_xml(xscale), util.escape_xml(yscale),
    minorticks.enabled and minor_axis or "none", minor_subdivisions,
    grid_minor and "true" or "false",
    aspect_metadata .. labelpad_metadata .. tickstyle_metadata)
  add(' <title>' .. util.escape_xml(fig._title or "luaplotlib figure") .. '</title>')
  add(' <desc>Generated by luaplotlib, a pure-Lua SVG plotting library.</desc>')
  printf(' <rect class="background" x="0" y="0" width="%s" height="%s" fill="%s"/>',
    util.fmt(fig.width), util.fmt(fig.height), fig._facecolor or "#ffffff")
  add(' <defs>')
  printf('  <clipPath id="%s"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath>',
    clip_id, util.fmt(geom.left), util.fmt(geom.top),
    util.fmt(geom.plot_width), util.fmt(geom.plot_height))
  local hatch_markup = hatch_defs(fig)
  if hatch_markup ~= "" then add(hatch_markup) end
  add(' </defs>')
  add(' <g class="figure" font-family="' .. FONT_FAMILY .. '" font-size="12" fill="' .. TEXT_COLOR .. '">')

  if fig._grid then
    local grid_opts = fig._grid_opts or {}
    local major, minor = grid.styles(grid_opts)
    local function dash_for(style)
      if style.linestyle == "dashed" then return ' stroke-dasharray="6 4"' end
      if style.linestyle == "dotted" then return ' stroke-dasharray="2 3"' end
      return ""
    end
    local function opacity_for(style)
      if style.alpha < 1 then
        return ' stroke-opacity="' .. util.fmt(style.alpha) .. '"'
      end
      return ""
    end
    add('  <g class="grid" stroke="' .. major.color ..
      '" stroke-width="' .. util.fmt(major.linewidth) .. '"' ..
      dash_for(major) .. opacity_for(major) .. '>')
    local grid_axis = major.axis
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
    if grid_opts.minor then
      add('  <g class="grid-minor" stroke="' .. minor.color ..
        '" stroke-width="' .. util.fmt(minor.linewidth) .. '"' ..
        dash_for(minor) .. opacity_for(minor) .. '>')
      if grid_axis ~= "y" then
        for _, value in ipairs(x_minor) do
          local x = map_x(value)
          printf('   <line class="minor-grid-line" x1="%s" y1="%s" x2="%s" y2="%s"/>',
            util.fmt(x), util.fmt(geom.top), util.fmt(x),
            util.fmt(geom.bottom))
        end
      end
      if grid_axis ~= "x" then
        for _, value in ipairs(y_minor) do
          local y = map_y(value)
          printf('   <line class="minor-grid-line" x1="%s" y1="%s" x2="%s" y2="%s"/>',
            util.fmt(geom.left), util.fmt(y), util.fmt(geom.right),
            util.fmt(y))
        end
      end
      add('  </g>')
    end
  end

  add('  <g class="series-layer" clip-path="url(#' .. clip_id .. ')">')
  for _, series in ipairs(fig._series) do
    if series.kind == "image" then
      render_image(series, map_x, map_y, buf)
    elseif series.kind == "axhspan" or series.kind == "axvspan" then
      render_span(series, map_x, map_y, geom, buf)
    elseif series.kind == "axline" then
      render_axline(series, map_x, map_y, geom, buf)
    elseif series.kind == "axhline" or series.kind == "axvline" then
      render_reference(series, map_x, map_y, geom, buf)
    elseif series.kind == "line" then
      render_line(series, map_x, map_y, buf)
    elseif series.kind == "scatter" then
      render_scatter(series, map_x, map_y, buf)
    elseif series.kind == "quiver" then
      render_quiver(series, map_x, map_y, buf)
    elseif series.kind == "hist2d" then
      render_hist2d(series, map_x, map_y, buf)
    elseif series.kind == "hexbin" then
      render_hexbin(series, map_x, map_y, buf)
    elseif series.kind == "hist" then
      render_hist(series, map_x, map_y, y_baseline, x_baseline, buf)
    elseif series.kind == "bar" then
      render_bar(series, map_x, map_y, y_baseline, yscale, buf)
    elseif series.kind == "fill" then
      render_fill(series, map_x, map_y, buf)
    elseif series.kind == "fillx" then
      render_fillx(series, map_x, map_y, buf)
    elseif series.kind == "eventplot" then
      local style = series.style
      local opacity = ""
      if style.alpha < 1 then
        opacity = string.format(' stroke-opacity="%s"', util.fmt(style.alpha))
      end
      local horizontal = series.orientation == "horizontal"
      local label = ""
      if style.label ~= nil then
        label = string.format(' data-label="%s"', attribute(style.label))
      end
      local row_colors = series.colors
      local dash = ""
      if style.linestyle == "dashed" then
        dash = ' stroke-dasharray="6 4"'
      elseif style.linestyle == "dotted" then
        dash = ' stroke-dasharray="1.5 3"'
      end
      buf[#buf + 1] = string.format(
        '  <g class="series series-eventplot" data-orientation="%s" data-rows="%d" data-colors="%s" data-eventcolors="%s" data-labels="%s" data-linestyle="%s"%s>',
        horizontal and "horizontal" or "vertical", #series.rows,
        row_colors ~= nil and "true" or "false",
        series.eventcolors ~= nil and "true" or "false",
        series.labels ~= nil and "true" or "false",
        style.linestyle or "solid", label)
      local event_index = 0
      for row, events in ipairs(series.rows) do
        local offset = series.lineoffsets[row]
        local half = series.linelengths[row] / 2
        local row_color = row_colors and row_colors[row] or style.color
        local row_width = style.linewidths and style.linewidths[row] or
          style.linewidth
        for _, value in ipairs(events) do
          event_index = event_index + 1
          local event_color = series.eventcolors and
            series.eventcolors[event_index] or row_color
          local line
          if horizontal then
            local y = map_y(value)
            local x1, x2 = map_x(offset - half), map_x(offset + half)
            line = string.format(
              '   <line class="event" data-row="%d" data-offset="%s" data-length="%s" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s%s/>',
              row, util.fmt(offset), util.fmt(series.linelengths[row]),
              util.fmt(x1), util.fmt(y), util.fmt(x2), util.fmt(y),
              event_color, util.fmt(row_width), dash, opacity)
          else
            local x = map_x(value)
            local y1, y2 = map_y(offset - half), map_y(offset + half)
            line = string.format(
              '   <line class="event" data-row="%d" data-offset="%s" data-length="%s" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s%s/>',
              row, util.fmt(offset), util.fmt(series.linelengths[row]),
              util.fmt(x), util.fmt(y1), util.fmt(x), util.fmt(y2),
              event_color, util.fmt(row_width), dash, opacity)
          end
          if style.linestyle ~= "none" then buf[#buf + 1] = line end
        end
      end
      buf[#buf + 1] = '  </g>'
    elseif series.kind == "step" then
      render_step(series, map_x, map_y, buf)
    elseif series.kind == "stem" then
      render_stem(series, map_x, map_y, buf)
    elseif series.kind == "barh" then
      render_barh(series, map_x, map_y, map_x(0), buf)
    elseif series.kind == "broken_barh" then
      render_broken_barh(series, map_x, map_y, buf)
    elseif series.kind == "contour" then
      render_contour(series, map_x, map_y, buf)
    elseif series.kind == "violin" then
      render_violin(series, map_x, map_y, buf)
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
      local rotation = fig._ytick_rotation or 0
      local transform = ""
      if rotation ~= 0 then
        transform = string.format(' transform="rotate(%d %s %s)"', rotation,
          util.fmt(geom.right + 9), util.fmt(y + 4))
      end
      printf('   <text class="tick-label" x="%s" y="%s" font-size="%s" fill="%s" text-anchor="start"%s>%s</text>',
        util.fmt(geom.right + 9), util.fmt(y + 4),
        util.fmt(fig._ticklabelsize or 11), fig._ticklabelcolor or TEXT_COLOR,
        transform, util.escape_xml(tick.label))
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
      printf('   <text class="tick-label" x="%s" y="%s" font-size="%s" fill="%s" text-anchor="middle">%s</text>',
        util.fmt(x), util.fmt(geom.top - 9),
        util.fmt(fig._ticklabelsize or 11), fig._ticklabelcolor or TEXT_COLOR,
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
    printf('    <text class="tick-label" x="%s" y="%s" font-size="%s" fill="%s" text-anchor="%s"%s>%s</text>',
      util.fmt(x), util.fmt(geom.bottom + 19),
      util.fmt(fig._ticklabelsize or 11), fig._ticklabelcolor or TEXT_COLOR,
      anchor, transform, util.escape_xml(tick.label))
  end
  if minorticks.enabled and minor_axis ~= "y" then
    for _, value in ipairs(x_minor) do
      local x = map_x(value)
      printf('    <line class="minor-tick-mark" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',
        util.fmt(x), util.fmt(geom.bottom), util.fmt(x),
        util.fmt(geom.bottom + 3), AXIS_COLOR)
    end
  end
  add('   </g>')

  add('   <g class="ticks y-ticks">')
  for _, tick in ipairs(y_display) do
    local y = map_y(tick.value)
    printf('    <line class="tick-mark" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',
      util.fmt(geom.left - 5), util.fmt(y), util.fmt(geom.left), util.fmt(y), AXIS_COLOR)
    local rotation = fig._ytick_rotation or 0
    local transform = ""
    if rotation ~= 0 then
      transform = string.format(' transform="rotate(%d %s %s)"', rotation,
        util.fmt(geom.left - 9), util.fmt(y + 4))
    end
    printf('    <text class="tick-label" x="%s" y="%s" font-size="%s" fill="%s" text-anchor="end"%s>%s</text>',
      util.fmt(geom.left - 9), util.fmt(y + 4),
      util.fmt(fig._ticklabelsize or 11), fig._ticklabelcolor or TEXT_COLOR,
      transform, util.escape_xml(tick.label))
  end
  if minorticks.enabled and minor_axis ~= "x" then
    for _, value in ipairs(y_minor) do
      local y = map_y(value)
      printf('    <line class="minor-tick-mark" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',
        util.fmt(geom.left - 3), util.fmt(y), util.fmt(geom.left),
        util.fmt(y), AXIS_COLOR)
    end
  end
  add('   </g>')

  if fig._xlabel ~= nil then
    printf('   <text class="xlabel" x="%s" y="%s" font-size="%s" fill="%s" text-anchor="middle">%s</text>',
      util.fmt(geom.left + geom.plot_width / 2), util.fmt(geom.height - 14),
      util.fmt(fig._xlabel_fontsize or 13),
      fig._xlabel_color or TEXT_COLOR, util.escape_xml(fig._xlabel))
  end

  if fig._ylabel ~= nil then
    local center_y = geom.top + geom.plot_height / 2
    local x = 18
    printf('   <text class="ylabel" x="%s" y="%s" font-size="%s" fill="%s" text-anchor="middle" transform="rotate(-90 %s %s)">%s</text>',
      util.fmt(x), util.fmt(center_y),
      util.fmt(fig._ylabel_fontsize or 13), fig._ylabel_color or TEXT_COLOR,
      util.fmt(x), util.fmt(center_y), util.escape_xml(fig._ylabel))
  end

  if fig._title ~= nil then
    local title_x, title_anchor = geom.left + geom.plot_width / 2, "middle"
    if fig._title_loc == "left" then
      title_x, title_anchor = geom.left, "start"
    elseif fig._title_loc == "right" then
      title_x, title_anchor = geom.right, "end"
    end
    printf('   <text class="title" x="%s" y="%s" font-size="%s" fill="%s" text-anchor="%s">%s</text>',
      util.fmt(title_x), util.fmt(math.max(16, geom.top - 22)),
      util.fmt(fig._title_fontsize or 18),
      fig._title_color or TEXT_COLOR, title_anchor,
      util.escape_xml(fig._title))
  end
  add('  </g>')

  for _, series in ipairs(fig._series) do
    if series.kind == "image" and fig._colorbar then
      if series.colorbar_ticks ~= nil or
          series.colorbar_tick_values ~= nil or
          (series.colorbar_label ~= nil and series.colorbar_label ~= "") then
        render_value_colorbar(series, geom, buf, "colorbar imshow-colorbar")
      else
        render_colorbar(series, geom, buf)
      end
    elseif series.kind == "hexbin" and series.colorbar then
      render_hexbin_colorbar(series, geom, buf)
    elseif series.kind == "hist2d" and series.colorbar then
      local norm = series.density and "density" or "count"
      render_value_colorbar(series, geom, buf, "colorbar hist2d-colorbar",
        ' data-norm="' .. norm .. '"')
    elseif series.kind == "scatter" and series.colorbar then
      render_value_colorbar(series, geom, buf, "colorbar scatter-colorbar",
        ' data-norm="linear"')
    end
  end
  render_legend(fig, geom, buf)

  add(' </g>')
  add('</svg>')
  return table.concat(buf, "\n") .. "\n"
end

return M
