--
-- Renderer-agnostic scene export for luaplotlib figures.
--
-- SVG remains the default backend.  This module converts a Figure into a
-- plain Lua table that another backend (LÖVR, a rasterizer, an interactive
-- canvas, ...) can render without depending on luaplotlib internals.
--
local util = require("luaplotlib.util")

local M = {}

local function copy_array(source)
  local result = {}
  for index = 1, #source do
    result[index] = source[index]
  end
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
    width_fraction = style.width_fraction,
  }
end

local function expand(minimum, maximum)
  if minimum == maximum then
    local pad = math.abs(minimum) * 0.05
    if pad == 0 then pad = 0.5 end
    return minimum - pad, maximum + pad
  end
  local pad = (maximum - minimum) * 0.05
  return minimum - pad, maximum + pad
end

-- Log limits are padded multiplicatively so they stay strictly positive.
local function expand_log(minimum, maximum)
  local minimum_log = util.log10(minimum)
  local maximum_log = util.log10(maximum)
  local pad
  if minimum_log == maximum_log then
    pad = 0.05
  else
    pad = (maximum_log - minimum_log) * 0.05
  end
  return 10 ^ (minimum_log - pad), 10 ^ (maximum_log + pad)
end

local function update_xy_range(state, series)
  for index = 1, #series.x do
    local x, y = series.x[index], series.y[index]
    if state.xmin == nil or x < state.xmin then state.xmin = x end
    if state.xmax == nil or x > state.xmax then state.xmax = x end
    if state.ymin == nil or y < state.ymin then state.ymin = y end
    if state.ymax == nil or y > state.ymax then state.ymax = y end
  end
end

function M.from_figure(figure)
  if type(figure) ~= "table" then
    error("scene.from_figure expects a Figure", 2)
  end
  local scene = {
    version = 1,
    type = "luaplotlib",
    width = figure.width,
    height = figure.height,
    dpi = figure.dpi,
    title = figure._title,
    xlabel = figure._xlabel,
    ylabel = figure._ylabel,
    xscale = figure._xscale or "linear",
    yscale = figure._yscale or "linear",
    grid = figure._grid and true or false,
    legend = figure._legend_requested and true or false,
    category_ticks = nil,
    series = {},
  }

  local state = {}
  for _, series in ipairs(figure._series or {}) do
    local copy = {
      kind = series.kind,
      style = copy_style(series.style or {}),
    }
    if series.kind == "line" or series.kind == "scatter" then
      copy.x = copy_array(series.x)
      copy.y = copy_array(series.y)
      update_xy_range(state, copy)
    elseif series.kind == "bar" then
      copy.x = copy_array(series.x)
      copy.y = copy_array(series.y)
      copy.width = series.width
      copy.category = series.category
      for index = 1, #copy.x do
        local x = copy.x[index]
        local y = copy.y[index]
        local left, right = x - copy.width / 2, x + copy.width / 2
        if state.xmin == nil or left < state.xmin then state.xmin = left end
        if state.xmax == nil or right > state.xmax then state.xmax = right end
        if state.ymin == nil or y < state.ymin then state.ymin = y end
        if state.ymax == nil or y > state.ymax then state.ymax = y end
      end
    elseif series.kind == "hist" then
      copy.edges = copy_array(series.edges)
      copy.counts = copy_array(series.counts)
      for index = 1, #copy.edges do
        local x = copy.edges[index]
        if state.xmin == nil or x < state.xmin then state.xmin = x end
        if state.xmax == nil or x > state.xmax then state.xmax = x end
      end
      if state.ymin == nil or 0 < state.ymin then state.ymin = 0 end
      for index = 1, #copy.counts do
        local y = copy.counts[index]
        if state.ymax == nil or y > state.ymax then state.ymax = y end
      end
    end
    scene.series[#scene.series + 1] = copy
  end

  if figure._xlim then
    scene.xlim = { figure._xlim[1], figure._xlim[2] }
  elseif state.xmin ~= nil then
    if scene.xscale == "log" and state.xmin > 0 and state.xmax > 0 then
      scene.xlim = { expand_log(state.xmin, state.xmax) }
    else
      scene.xlim = { expand(state.xmin, state.xmax) }
    end
  else
    scene.xlim = { 0, 1 }
  end
  if figure._ylim then
    scene.ylim = { figure._ylim[1], figure._ylim[2] }
  elseif state.ymin ~= nil then
    if scene.yscale == "log" and state.ymin > 0 and state.ymax > 0 then
      scene.ylim = { expand_log(state.ymin, state.ymax) }
    else
      scene.ylim = { expand(state.ymin, state.ymax) }
    end
  else
    scene.ylim = { 0, 1 }
  end

  if figure._category_ticks then
    scene.category_ticks = {}
    for index, tick in ipairs(figure._category_ticks) do
      scene.category_ticks[index] = { position = tick.position, label = tick.label }
    end
  end

  return scene
end

return M
