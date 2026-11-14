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
  local top = math.min(48, math.max(24, height * 0.10))
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

local function data_extents(fig)
  local min_x, max_x, min_y, max_y
  local baseline_y = false
  local any = false

  local function include_x(value)
    any = true
    if min_x == nil or value < min_x then min_x = value end
    if max_x == nil or value > max_x then max_x = value end
  end

  local function include_y(value)
    any = true
    if min_y == nil or value < min_y then min_y = value end
    if max_y == nil or value > max_y then max_y = value end
  end

  for _, series in ipairs(fig._series) do
    if series.kind == "line" or series.kind == "scatter" then
      for i = 1, #series.x do
        include_x(series.x[i])
        include_y(series.y[i])
      end
    elseif series.kind == "hist" then
      baseline_y = true
      include_x(series.edges[1])
      include_x(series.edges[#series.edges])
      include_y(0)
      for i = 1, #series.counts do
        include_y(series.counts[i])
      end
    elseif series.kind == "bar" then
      baseline_y = true
      local half = series.width / 2
      for i = 1, #series.x do
        include_x(series.x[i] - half)
        include_x(series.x[i] + half)
        include_y(0)
        include_y(series.y[i])
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
  }
end

local function auto_limits(lo, hi, target, zero_baseline)
  local raw_lo, raw_hi = lo, hi
  if raw_hi < raw_lo then
    raw_lo, raw_hi = raw_hi, raw_lo
  end

  if raw_lo == raw_hi then
    if zero_baseline and raw_lo == 0 then
      return 0, 1, ticks.generate(0, 1, target)
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
  return lo, hi, ticks.generate(lo, hi, target)
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

local function render_hist(series, map_x, map_y, buf)
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
  local baseline = map_y(0)
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

local function render_bar(series, map_x, map_y, buf)
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

  buf[#buf + 1] = string.format('  <g class="series series-bar"%s>', label)
  local baseline = map_y(0)
  for i = 1, #series.x do
    local value = series.y[i]
    local x1 = map_x(series.x[i] - series.width / 2)
    local x2 = map_x(series.x[i] + series.width / 2)
    local value_y = map_y(value)
    local top = math.min(baseline, value_y)
    local height = math.abs(baseline - value_y)
    buf[#buf + 1] = string.format(
      '   <rect class="bar" x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="%s" stroke-width="1"%s/>',
      util.fmt(x1), util.fmt(top), util.fmt(x2 - x1), util.fmt(height),
      style.color, edge, opacity)
  end
  buf[#buf + 1] = '  </g>'
end

function M.to_svg(fig)
  local geom = layout(fig)
  local extents = data_extents(fig)
  local x_target, y_target = tick_count(geom.plot_width, geom.plot_height)

  local xmin, xmax, ymin, ymax, xticks, yticks
  if fig._xlim then
    xmin, xmax = fig._xlim[1], fig._xlim[2]
    xticks = ticks.generate(xmin, xmax, x_target)
  elseif extents then
    xmin, xmax, xticks = auto_limits(extents.min_x, extents.max_x, x_target, false)
  else
    xmin, xmax = 0, 1
    xticks = ticks.generate(xmin, xmax, x_target)
  end

  if fig._ylim then
    ymin, ymax = fig._ylim[1], fig._ylim[2]
    yticks = ticks.generate(ymin, ymax, y_target)
  elseif extents then
    ymin, ymax, yticks = auto_limits(extents.min_y, extents.max_y, y_target,
      extents.baseline_y)
  else
    ymin, ymax = 0, 1
    yticks = ticks.generate(ymin, ymax, y_target)
  end

  local categories = find_category_ticks(fig, xmin, xmax)
  local x_display = {}
  if categories then
    for _, category in ipairs(categories) do
      x_display[#x_display + 1] = {
        value = category.position,
        label = category.label,
      }
    end
  else
    for _, value in ipairs(xticks) do
      x_display[#x_display + 1] = { value = value, label = util.fmt_tick(value) }
    end
  end

  local function map_x(value)
    return geom.left + (value - xmin) / (xmax - xmin) * geom.plot_width
  end

  local function map_y(value)
    return geom.bottom - (value - ymin) / (ymax - ymin) * geom.plot_height
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
  printf('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" version="1.1" data-dpi="%s">',
    util.fmt(fig.width), util.fmt(fig.height),
    util.fmt(fig.width), util.fmt(fig.height), util.fmt(fig.dpi))
  add(' <title>' .. util.escape_xml(fig._title or "luaplotlib figure") .. '</title>')
  add(' <desc>Generated by luaplotlib, a pure-Lua SVG plotting library.</desc>')
  printf(' <rect class="background" x="0" y="0" width="%s" height="%s" fill="#ffffff"/>',
    util.fmt(fig.width), util.fmt(fig.height))
  add(' <defs>')
  printf('  <clipPath id="%s"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath>',
    clip_id, util.fmt(geom.left), util.fmt(geom.top),
    util.fmt(geom.plot_width), util.fmt(geom.plot_height))
  add(' </defs>')
  add(' <g class="figure" font-family="' .. FONT_FAMILY .. '" font-size="12" fill="' .. TEXT_COLOR .. '">')

  if fig._grid then
    add('  <g class="grid" stroke="' .. GRID_COLOR .. '" stroke-width="1">')
    for _, tick in ipairs(x_display) do
      local x = map_x(tick.value)
      printf('   <line x1="%s" y1="%s" x2="%s" y2="%s"/>',
        util.fmt(x), util.fmt(geom.top), util.fmt(x), util.fmt(geom.bottom))
    end
    for _, value in ipairs(yticks) do
      local y = map_y(value)
      printf('   <line x1="%s" y1="%s" x2="%s" y2="%s"/>',
        util.fmt(geom.left), util.fmt(y), util.fmt(geom.right), util.fmt(y))
    end
    add('  </g>')
  end

  add('  <g class="series-layer" clip-path="url(#' .. clip_id .. ')">')
  for _, series in ipairs(fig._series) do
    if series.kind == "line" then
      render_line(series, map_x, map_y, buf)
    elseif series.kind == "scatter" then
      render_scatter(series, map_x, map_y, buf)
    elseif series.kind == "hist" then
      render_hist(series, map_x, map_y, buf)
    elseif series.kind == "bar" then
      render_bar(series, map_x, map_y, buf)
    end
  end
  add('  </g>')

  add('  <g class="axes">')
  printf('   <path class="spine" d="M %s %s L %s %s L %s %s" fill="none" stroke="%s" stroke-width="1"/>',
    util.fmt(geom.left), util.fmt(geom.top), util.fmt(geom.left),
    util.fmt(geom.bottom), util.fmt(geom.right), util.fmt(geom.bottom), AXIS_COLOR)

  add('   <g class="ticks x-ticks">')
  for _, tick in ipairs(x_display) do
    local x = map_x(tick.value)
    printf('    <line class="tick-mark" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',
      util.fmt(x), util.fmt(geom.bottom), util.fmt(x), util.fmt(geom.bottom + 5), AXIS_COLOR)
    printf('    <text class="tick-label" x="%s" y="%s" font-size="11" fill="%s" text-anchor="middle">%s</text>',
      util.fmt(x), util.fmt(geom.bottom + 19), TEXT_COLOR,
      util.escape_xml(tick.label))
  end
  add('   </g>')

  add('   <g class="ticks y-ticks">')
  for _, value in ipairs(yticks) do
    local y = map_y(value)
    printf('    <line class="tick-mark" x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',
      util.fmt(geom.left - 5), util.fmt(y), util.fmt(geom.left), util.fmt(y), AXIS_COLOR)
    printf('    <text class="tick-label" x="%s" y="%s" font-size="11" fill="%s" text-anchor="end">%s</text>',
      util.fmt(geom.left - 9), util.fmt(y + 4), TEXT_COLOR, util.fmt_tick(value))
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

  render_legend(fig, geom, buf)

  add(' </g>')
  add('</svg>')
  return table.concat(buf, "\n") .. "\n"
end

return M
