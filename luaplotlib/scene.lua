--
-- Renderer-agnostic scene export for luaplotlib figures.
--
-- SVG remains the default backend.  This module converts a Figure into a
-- plain Lua table that another backend (LÖVR, a rasterizer, an interactive
-- canvas, ...) can render without depending on luaplotlib internals.
--
local area = require("luaplotlib.area")
local grid = require("luaplotlib.grid")
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
    markevery = style.markevery and copy_array(style.markevery) or nil,
    radius = style.radius,
    width_fraction = style.width_fraction,
    capsize = style.capsize,
    elinewidth = style.elinewidth,
    ecolor = style.ecolor,
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

local function copy_annotation(annotation)
  local copy = {
    kind = "annotation",
    text = annotation.text,
    x = annotation.x,
    y = annotation.y,
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
    local x, y = annotation.xytext[1], annotation.xytext[2]
    -- The numeric pair keeps the shape consistent with xlim/ylim; the named
    -- fields are a convenience for backends that prefer point tables.
    copy.xytext = { x, y, x = x, y = y }
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

function M.from_figure(figure)
  if type(figure) ~= "table" then
    error("scene.from_figure expects a Figure", 2)
  end
  if figure._polar ~= nil then
    return require("luaplotlib.polar").to_scene(figure)
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
    xtick_rotation = figure._xtick_rotation or 0,
    ytick_rotation = figure._ytick_rotation or 0,
    minorticks = figure._minorticks and figure._minorticks.enabled or false,
    minor_tick_axis = figure._minorticks and figure._minorticks.axis or "both",
    minor_grid = figure._grid_opts and figure._grid_opts.minor == true or false,
    grid = figure._grid and true or false,
    legend = figure._legend_requested and true or false,
    category_ticks = nil,
    series = {},
    annotations = {},
  }

  if figure._aspect ~= nil then
    scene.aspect = figure._aspect
    scene.aspect_mode = figure._aspect == 1 and "equal" or "numeric"
    scene.aspect_adjustable = "box"
  end

  if figure._grid then
    local major, minor = grid.styles(figure._grid_opts)
    scene.grid_style = {
      color = major.color,
      linewidth = major.linewidth,
      linestyle = major.linestyle,
      alpha = major.alpha,
      axis = major.axis,
    }
    if figure._grid_opts and figure._grid_opts.minor then
      scene.minor_grid_style = {
        color = minor.color,
        linewidth = minor.linewidth,
        linestyle = minor.linestyle,
        alpha = minor.alpha,
      }
    end
  end

  if figure._pie ~= nil then
    scene.pie = {
      radius = figure._pie.radius,
      inner_radius = figure._pie.inner_radius,
      slices = {},
    }
    for index, slice in ipairs(figure._pie.slices) do
      scene.pie.slices[index] = {
        value = slice.value, percent = slice.percent,
        start_angle = slice.start_angle, end_angle = slice.end_angle,
        color = slice.color, label = slice.label,
      }
    end
    return scene
  end

  local state = {}
  for _, series in ipairs(figure._series or {}) do
    local copy = {
      kind = series.kind,
      style = copy_style(series.style or {}),
    }
    if series.kind == "line" or series.kind == "scatter" then
      copy.x = copy_array(series.x)
      copy.y = copy_array(series.y)
      if series.style.radii then
        copy.radii = copy_array(series.style.radii)
      end
      if series.style.colors then
        copy.colors = {}
        for i, color in ipairs(series.style.colors) do copy.colors[i] = color end
      end
      update_xy_range(state, copy)
    elseif series.kind == "quiver" then
      copy.x = copy_array(series.x)
      copy.y = copy_array(series.y)
      copy.u = copy_array(series.u)
      copy.v = copy_array(series.v)
      copy.scale = series.scale
      copy.scale_mode = series.scale == nil and "auto" or "explicit"
      copy.scale_unit = "screen_multiplier"
      copy.auto_length = 18
      copy.pivot = series.pivot
      copy.max_arrows = series.max_arrows
      copy.normalize = series.normalize
      local stride = math.max(1, math.ceil(#series.x / series.max_arrows))
      local drawn = 0
      for index = 1, #series.x, stride do
        local u, v = series.u[index], series.v[index]
        if math.sqrt(u * u + v * v) > 1e-12 then drawn = drawn + 1 end
      end
      copy.stride = stride
      copy.drawn = drawn
      update_xy_range(state, copy)
    elseif series.kind == "hexbin" then
      copy.x = copy_array(series.x)
      copy.y = copy_array(series.y)
      copy.cells = {}
      copy.counts = {}
      for index, cell in ipairs(series.cells) do
        copy.cells[index] = {
          row = cell.row,
          column = cell.column,
          x = cell.x,
          y = cell.y,
          count = cell.count,
        }
        copy.counts[index] = cell.count
        local left = cell.x - series.width / 2
        local right = cell.x + series.width / 2
        local bottom = cell.y - series.radius
        local top = cell.y + series.radius
        if state.xmin == nil or left < state.xmin then state.xmin = left end
        if state.xmax == nil or right > state.xmax then state.xmax = right end
        if state.ymin == nil or bottom < state.ymin then state.ymin = bottom end
        if state.ymax == nil or top > state.ymax then state.ymax = top end
      end
      copy.gridsize = series.gridsize
      copy.mincnt = series.mincnt
      copy.width = series.width
      copy.radius = series.radius
      copy.point_count = series.point_count
      copy.vmin = series.vmin
      copy.vmax = series.vmax
      copy.colorbar = series.colorbar and true or false
      copy.colorbar_label = series.colorbar_label
      copy.colorbar_ticks = series.colorbar_ticks
      if series.colorbar_tick_values ~= nil then
        copy.colorbar_tick_values = copy_array(series.colorbar_tick_values)
      end
    elseif series.kind == "errorbar" then
      copy.x = copy_array(series.x)
      copy.y = copy_array(series.y)
      copy.yerr = copy_array(series.yerr_upper or series.yerr)
      copy.yerr_lower = copy_array(series.yerr_lower or series.yerr)
      copy.yerr_upper = copy_array(series.yerr_upper or series.yerr)
      if series.yerr_asymmetric then copy.yerr_asymmetric = true end
      if series.xerr then
        copy.xerr = copy_array(series.xerr_upper or series.xerr)
        copy.xerr_lower = copy_array(series.xerr_lower or series.xerr)
        copy.xerr_upper = copy_array(series.xerr_upper or series.xerr)
        if series.xerr_asymmetric then copy.xerr_asymmetric = true end
      end
      for index = 1, #copy.x do
        local x, y = copy.x[index], copy.y[index]
        local xerr_lower = copy.xerr_lower and copy.xerr_lower[index] or 0
        local xerr_upper = copy.xerr_upper and copy.xerr_upper[index] or 0
        local yerr_lower = copy.yerr_lower[index]
        local yerr_upper = copy.yerr_upper[index]
        local left, right = x - xerr_lower, x + xerr_upper
        local lower, upper = y - yerr_lower, y + yerr_upper
        if state.xmin == nil or left < state.xmin then state.xmin = left end
        if state.xmax == nil or right > state.xmax then state.xmax = right end
        if state.ymin == nil or lower < state.ymin then state.ymin = lower end
        if state.ymax == nil or upper > state.ymax then state.ymax = upper end
      end
    elseif series.kind == "axline" then
      copy.x1 = series.x1
      copy.y1 = series.y1
      copy.x2 = series.x2
      copy.y2 = series.y2
      if state.xmin == nil or series.x1 < state.xmin then state.xmin = series.x1 end
      if state.xmin == nil or series.x2 < state.xmin then state.xmin = series.x2 end
      if state.xmax == nil or series.x1 > state.xmax then state.xmax = series.x1 end
      if state.xmax == nil or series.x2 > state.xmax then state.xmax = series.x2 end
      if state.ymin == nil or series.y1 < state.ymin then state.ymin = series.y1 end
      if state.ymin == nil or series.y2 < state.ymin then state.ymin = series.y2 end
      if state.ymax == nil or series.y1 > state.ymax then state.ymax = series.y1 end
      if state.ymax == nil or series.y2 > state.ymax then state.ymax = series.y2 end
    elseif series.kind == "axhline" then
      copy.y = series.y
      copy.xmin = series.xmin or 0
      copy.xmax = series.xmax or 1
      if state.ymin == nil or series.y < state.ymin then state.ymin = series.y end
      if state.ymax == nil or series.y > state.ymax then state.ymax = series.y end
    elseif series.kind == "axvline" then
      copy.x = series.x
      copy.ymin = series.ymin or 0
      copy.ymax = series.ymax or 1
      if state.xmin == nil or series.x < state.xmin then state.xmin = series.x end
      if state.xmax == nil or series.x > state.xmax then state.xmax = series.x end
    elseif series.kind == "fill" then
      copy.x = copy_array(series.x)
      copy.y1 = copy_array(series.y1)
      copy.y2 = copy_array(series.y2)
      if series.where ~= nil then
        copy.where = copy_array(series.where)
        copy.interpolate = series.interpolate == true
        copy.segments = {}
        for run_index, run in ipairs(area.segments(series)) do
          copy.segments[run_index] = {
            x = copy_array(run.x),
            y1 = copy_array(run.y1),
            y2 = copy_array(run.y2),
          }
        end
      end
      for _, run in ipairs(area.segments(series)) do
        for index = 1, #run.x do
          local x = run.x[index]
          local lower, upper = run.y1[index], run.y2[index]
          if state.xmin == nil or x < state.xmin then state.xmin = x end
          if state.xmax == nil or x > state.xmax then state.xmax = x end
          if state.ymin == nil or lower < state.ymin then state.ymin = lower end
          if state.ymin == nil or upper < state.ymin then state.ymin = upper end
          if state.ymax == nil or lower > state.ymax then state.ymax = lower end
          if state.ymax == nil or upper > state.ymax then state.ymax = upper end
        end
      end
    elseif series.kind == "fillx" then
      copy.y = copy_array(series.y)
      copy.x1 = copy_array(series.x1)
      copy.x2 = copy_array(series.x2)
      if series.where ~= nil then
        copy.where = copy_array(series.where)
        copy.interpolate = series.interpolate == true
        copy.segments = {}
        for run_index, run in ipairs(area.segments(series)) do
          copy.segments[run_index] = {
            y = copy_array(run.y),
            x1 = copy_array(run.x1),
            x2 = copy_array(run.x2),
          }
        end
      end
      for _, run in ipairs(area.segments(series)) do
        for index = 1, #run.y do
          local y = run.y[index]
          local left, right = run.x1[index], run.x2[index]
          if state.ymin == nil or y < state.ymin then state.ymin = y end
          if state.ymax == nil or y > state.ymax then state.ymax = y end
          if state.xmin == nil or left < state.xmin then state.xmin = left end
          if state.xmin == nil or right < state.xmin then state.xmin = right end
          if state.xmax == nil or left > state.xmax then state.xmax = left end
          if state.xmax == nil or right > state.xmax then state.xmax = right end
        end
      end
    elseif series.kind == "step" then
      copy.x = copy_array(series.x)
      copy.y = copy_array(series.y)
      copy.where = series.where
      update_xy_range(state, copy)
    elseif series.kind == "stem" then
      copy.x = copy_array(series.x)
      copy.y = copy_array(series.y)
      copy.base = series.base or 0
      update_xy_range(state, copy)
      if state.ymin == nil or copy.base < state.ymin then
        state.ymin = copy.base
      end
      if state.ymax == nil or copy.base > state.ymax then
        state.ymax = copy.base
      end
    elseif series.kind == "image" then
      copy.rows = series.rows
      copy.cols = series.cols
      copy.values = {}
      for row = 1, series.rows do copy.values[row] = copy_array(series.values[row]) end
      copy.vmin = series.vmin
      copy.vmax = series.vmax
      copy.origin = series.origin or "upper"
      copy.colorbar = figure._colorbar and true or false
      local left, right, bottom, top = 0, series.cols, 0, series.rows
      if series.extent ~= nil then
        left, right = series.extent[1], series.extent[2]
        bottom, top = series.extent[3], series.extent[4]
        copy.extent = { left, right, bottom, top }
      end
      if state.xmin == nil or left < state.xmin then state.xmin = left end
      if state.xmax == nil or right > state.xmax then state.xmax = right end
      if state.ymin == nil or bottom < state.ymin then state.ymin = bottom end
      if state.ymax == nil or top > state.ymax then state.ymax = top end
    elseif series.kind == "barh" then
      copy.x = copy_array(series.x)
      copy.y = copy_array(series.y)
      copy.height = series.height
      copy.bar_colors = series.bar_colors and copy_array(series.bar_colors) or nil
      copy.show_values = series.show_values and true or false
      if state.xmin == nil or 0 < state.xmin then state.xmin = 0 end
      for index = 1, #copy.x do
        local x = copy.x[index]
        local y = copy.y[index]
        if state.xmin == nil or x < state.xmin then state.xmin = x end
        if state.xmax == nil or x > state.xmax then state.xmax = x end
        local low, high = y - copy.height / 2, y + copy.height / 2
        if state.ymin == nil or low < state.ymin then state.ymin = low end
        if state.ymax == nil or high > state.ymax then state.ymax = high end
      end
    elseif series.kind == "box" then
      copy.position = series.position
      copy.width = series.width
      copy.q1 = series.q1
      copy.median = series.median
      copy.q3 = series.q3
      copy.low = series.low
      copy.high = series.high
      copy.outliers = copy_array(series.outliers)
      local left, right = series.position - series.width / 2,
        series.position + series.width / 2
      if state.xmin == nil or left < state.xmin then state.xmin = left end
      if state.xmax == nil or right > state.xmax then state.xmax = right end
      if state.ymin == nil or series.low < state.ymin then state.ymin = series.low end
      if state.ymax == nil or series.high > state.ymax then state.ymax = series.high end
      for _, value in ipairs(copy.outliers) do
        if value < state.ymin then state.ymin = value end
        if value > state.ymax then state.ymax = value end
      end
    elseif series.kind == "contour" then
      copy.segments = {}
      for index, segment in ipairs(series.segments) do
        copy.segments[index] = copy_array(segment)
      end
      copy.level = series.level
      copy.rows = series.rows
      copy.cols = series.cols
      local xmin, xmax = 0, series.cols
      local ymin, ymax = 0, series.rows
      if series.x_coords ~= nil then
        copy.x = copy_array(series.x_coords)
        xmin, xmax = series.x_coords[1], series.x_coords[1]
        for _, value in ipairs(series.x_coords) do
          if value < xmin then xmin = value end
          if value > xmax then xmax = value end
        end
      end
      if series.y_coords ~= nil then
        copy.y = copy_array(series.y_coords)
        ymin, ymax = series.y_coords[1], series.y_coords[1]
        for _, value in ipairs(series.y_coords) do
          if value < ymin then ymin = value end
          if value > ymax then ymax = value end
        end
      end
      if state.xmin == nil or xmin < state.xmin then state.xmin = xmin end
      if state.xmax == nil or xmax > state.xmax then state.xmax = xmax end
      if state.ymin == nil or ymin < state.ymin then state.ymin = ymin end
      if state.ymax == nil or ymax > state.ymax then state.ymax = ymax end
    elseif series.kind == "bar" then
      local mode = series.mode or "single"
      local offset = series.offset or 0
      copy.x = copy_array(series.x)
      copy.y = copy_array(series.y)
      copy.width = series.width
      copy.category = series.category
      copy.mode = mode
      copy.grouped = mode == "grouped"
      copy.stacked = mode == "stacked"
      if series.offset ~= nil then
        -- Keep the category centers in x and expose the grouped offset
        -- separately so non-SVG backends can reproduce the layout themselves.
        copy.offset = series.offset
        copy.x_offset = series.offset
        copy.offsets = {}
        for index = 1, #copy.x do copy.offsets[index] = series.offset end
      end
      if series.bottom ~= nil then
        copy.bottom = copy_array(series.bottom)
        copy.stack = copy_array(series.bottom)
        copy.top = {}
        for index = 1, #copy.x do
          copy.top[index] = copy.bottom[index] + copy.y[index]
        end
      end
      local include_zero = mode ~= "single" and scene.yscale ~= "log"
      for index = 1, #copy.x do
        local x = copy.x[index] + offset
        local y = copy.y[index]
        local left, right = x - copy.width / 2, x + copy.width / 2
        if state.xmin == nil or left < state.xmin then state.xmin = left end
        if state.xmax == nil or right > state.xmax then state.xmax = right end
        if copy.bottom ~= nil then
          local bottom = copy.bottom[index]
          local top = copy.top[index]
          if include_zero then
            if state.ymin == nil or 0 < state.ymin then state.ymin = 0 end
            if state.ymax == nil or 0 > state.ymax then state.ymax = 0 end
          end
          if scene.yscale ~= "log" or bottom > 0 then
            if state.ymin == nil or bottom < state.ymin then state.ymin = bottom end
            if state.ymax == nil or bottom > state.ymax then state.ymax = bottom end
          end
          if state.ymin == nil or top < state.ymin then state.ymin = top end
          if state.ymax == nil or top > state.ymax then state.ymax = top end
        else
          if include_zero then
            if state.ymin == nil or 0 < state.ymin then state.ymin = 0 end
            if state.ymax == nil or 0 > state.ymax then state.ymax = 0 end
          end
          if state.ymin == nil or y < state.ymin then state.ymin = y end
          if state.ymax == nil or y > state.ymax then state.ymax = y end
        end
      end
    elseif series.kind == "hist" then
      copy.edges = copy_array(series.edges)
      copy.counts = copy_array(series.counts)
      copy.orientation = series.orientation or "vertical"
      if copy.orientation == "horizontal" then
        if scene.xscale ~= "log" then
          if state.xmin == nil or 0 < state.xmin then state.xmin = 0 end
        end
        for index = 1, #copy.counts do
          local x = copy.counts[index]
          if x > 0 then
            if state.xmin == nil or x < state.xmin then state.xmin = x end
            if state.xmax == nil or x > state.xmax then state.xmax = x end
          end
        end
        for index = 1, #copy.edges do
          local y = copy.edges[index]
          if state.ymin == nil or y < state.ymin then state.ymin = y end
          if state.ymax == nil or y > state.ymax then state.ymax = y end
        end
      else
        for index = 1, #copy.edges do
          local x = copy.edges[index]
          if state.xmin == nil or x < state.xmin then state.xmin = x end
          if state.xmax == nil or x > state.xmax then state.xmax = x end
        end
        if scene.yscale ~= "log" then
          if state.ymin == nil or 0 < state.ymin then state.ymin = 0 end
        end
        for index = 1, #copy.counts do
          local y = copy.counts[index]
          if state.ymax == nil or y > state.ymax then state.ymax = y end
        end
      end
    end
    scene.series[#scene.series + 1] = copy
  end

  for _, annotation in ipairs(figure._annotations or {}) do
    scene.annotations[#scene.annotations + 1] = copy_annotation(annotation)
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

  if figure._twin ~= nil then
    local twin = figure._twin
    scene.twin = {
      ylabel = twin._ylabel,
      yscale = twin._yscale or "linear",
      ylim = twin._ylim and { twin._ylim[1], twin._ylim[2] } or nil,
      series = {},
    }
    for _, series in ipairs(twin._series or {}) do
      local copy = { kind = series.kind, style = copy_style(series.style or {}) }
      if series.kind == "line" or series.kind == "scatter" then
        copy.x = copy_array(series.x)
        copy.y = copy_array(series.y)
      elseif series.kind == "errorbar" then
        copy.x = copy_array(series.x)
        copy.y = copy_array(series.y)
        copy.yerr = copy_array(series.yerr_upper or series.yerr)
        copy.yerr_lower = copy_array(series.yerr_lower or series.yerr)
        copy.yerr_upper = copy_array(series.yerr_upper or series.yerr)
        if series.yerr_asymmetric then copy.yerr_asymmetric = true end
        if series.xerr then
          copy.xerr = copy_array(series.xerr_upper or series.xerr)
          copy.xerr_lower = copy_array(series.xerr_lower or series.xerr)
          copy.xerr_upper = copy_array(series.xerr_upper or series.xerr)
          if series.xerr_asymmetric then copy.xerr_asymmetric = true end
        end
      elseif series.kind == "bar" then
        copy.x = copy_array(series.x)
        copy.y = copy_array(series.y)
        copy.width = series.width
        copy.bottom = series.bottom and copy_array(series.bottom) or nil
      end
      scene.twin.series[#scene.twin.series + 1] = copy
    end
  end

  if figure._twiny ~= nil then
    local twiny = figure._twiny
    scene.twiny = {
      xlabel = twiny._xlabel,
      xscale = twiny._xscale or "linear",
      xlim = twiny._xlim and { twiny._xlim[1], twiny._xlim[2] } or nil,
      series = {},
    }
    for _, series in ipairs(twiny._series or {}) do
      local copy = { kind = series.kind, style = copy_style(series.style or {}) }
      if series.kind == "line" or series.kind == "scatter" then
        copy.x = copy_array(series.x)
        copy.y = copy_array(series.y)
      elseif series.kind == "errorbar" then
        copy.x = copy_array(series.x)
        copy.y = copy_array(series.y)
        copy.yerr = copy_array(series.yerr_upper or series.yerr)
        copy.yerr_lower = copy_array(series.yerr_lower or series.yerr)
        copy.yerr_upper = copy_array(series.yerr_upper or series.yerr)
        if series.yerr_asymmetric then copy.yerr_asymmetric = true end
        if series.xerr then
          copy.xerr = copy_array(series.xerr_upper or series.xerr)
          copy.xerr_lower = copy_array(series.xerr_lower or series.xerr)
          copy.xerr_upper = copy_array(series.xerr_upper or series.xerr)
          if series.xerr_asymmetric then copy.xerr_asymmetric = true end
        end
      end
      scene.twiny.series[#scene.twiny.series + 1] = copy
    end
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
