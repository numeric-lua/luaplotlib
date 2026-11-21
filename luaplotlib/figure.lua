-- Public Figure object and series construction.

local colors = require("luaplotlib.colors")
local data = require("luaplotlib.data")
local polar = require("luaplotlib.polar")
local util = require("luaplotlib.util")

local Figure = {}
Figure.__index = Figure

local DEFAULT_DPI = 100
local DEFAULT_WIDTH_INCHES = 6.4
local DEFAULT_HEIGHT_INCHES = 4.8

local PLOT_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  linestyle = true,
  marker = true,
  markersize = true,
  alpha = true,
}

local POLAR_LINE_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  linestyle = true,
  marker = true,
  markersize = true,
  alpha = true,
}

local POLAR_SCATTER_OPTIONS = {
  color = true,
  label = true,
  size = true,
  s = true,
  markersize = true,
  alpha = true,
  edgecolor = true,
  linewidth = true,
  marker = true,
}

local SCATTER_OPTIONS = {
  color = true,
  label = true,
  size = true,
  s = true,
  markersize = true,
  alpha = true,
  edgecolor = true,
  linewidth = true,
  marker = true,
}

local HIST_OPTIONS = {
  bins = true,
  color = true,
  label = true,
  alpha = true,
  edgecolor = true,
  range = true,
  density = true,
  cumulative = true,
}

local BAR_OPTIONS = {
  color = true,
  label = true,
  labels = true,
  series_labels = true,
  colors = true,
  width = true,
  alpha = true,
  edgecolor = true,
  stacked = true,
  grouped = true,
  bar_colors = true,
  show_values = true,
  hatch = true,
}

local FILL_OPTIONS = {
  color = true,
  label = true,
  alpha = true,
  edgecolor = true,
}

local STEP_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  linestyle = true,
  where = true,
  alpha = true,
}

local STEM_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  markersize = true,
  alpha = true,
}

local STACK_OPTIONS = {
  labels = true,
  colors = true,
  alpha = true,
  edgecolor = true,
}

local PIE_OPTIONS = {
  labels = true,
  colors = true,
  color = true,
  startangle = true,
  autopct = true,
  radius = true,
  inner_radius = true,
  legend = true,
}

local BARH_OPTIONS = {
  color = true,
  label = true,
  labels = true,
  height = true,
  alpha = true,
  edgecolor = true,
  bar_colors = true,
  show_values = true,
}

local CONTOUR_OPTIONS = {
  levels = true,
  color = true,
  linewidth = true,
  label = true,
  labels = true,
  linestyle = true,
}


local BOX_OPTIONS = {
  color = true,
  label = true,
  labels = true,
  width = true,
}

local ERRORBAR_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  linestyle = true,
  marker = true,
  markersize = true,
  alpha = true,
  capsize = true,
  elinewidth = true,
  ecolor = true,
}

local ANNOTATE_OPTIONS = {
  xytext = true,
  color = true,
  fontsize = true,
  align = true,
  arrow = true,
}

local ARROW_OPTIONS = {
  color = true,
  linewidth = true,
  width = true,
  head = true,
  headsize = true,
}

local ANNOTATION_ALIGNS = {
  left = true,
  center = true,
  right = true,
}

local DEFAULT_ANNOTATION_COLOR = "#222222"
local DEFAULT_ANNOTATION_FONTSIZE = 12
local DEFAULT_ARROW_LINEWIDTH = 1.5
local DEFAULT_ARROW_HEAD = 8

local MARKERS = {
  circle = true, o = true, point = true, dot = true,
  square = true, s = true,
  triangle = true, ["^"] = true,
  diamond = true, D = true,
  cross = true, ["+"] = true,
  x = true, X = true,
}

local LINESTYLES = {
  solid = true,
  dashed = true,
  dotted = true,
  none = true,
}

local LEGEND_LOCATIONS = {
  ["upper right"] = true,
  ["upper left"] = true,
  ["lower right"] = true,
  ["lower left"] = true,
}

local SCALES = {
  linear = true,
  log = true,
}

local function fail(message)
  util.fail(message, 3)
end

local function checked_scale(value, name, allow_default)
  if value == nil then
    if allow_default then
      return "linear"
    end
    fail(name .. " requires 'linear' or 'log'")
  end
  if type(value) ~= "string" or not SCALES[value] then
    fail(name .. " must be 'linear' or 'log', got " .. tostring(value))
  end
  return value
end

local function checked_style(self, opts, context)
  local color
  if opts.color == nil then
    color = colors.next(self._color_serial)
  else
    color = util.check_color(opts.color, context .. " color")
  end
  self._color_serial = self._color_serial + 1

  local label = opts.label
  if label ~= nil then
    util.check_string(label, context .. " label", true)
  end

  local alpha = 1
  if opts.alpha ~= nil then
    alpha = util.check_alpha(opts.alpha, context .. " alpha")
  end

  local edgecolor = opts.edgecolor
  if edgecolor ~= nil then
    edgecolor = util.check_color(edgecolor, context .. " edgecolor")
  end

  return {
    color = color,
    label = label,
    alpha = alpha,
    edgecolor = edgecolor,
  }
end

local function checked_marker(value, context)
  if value == nil or value == false then
    return nil
  end
  if value == true then
    return "circle"
  end
  if type(value) ~= "string" or not MARKERS[value] then
    fail(context .. " marker must be circle, square, triangle, diamond, cross, x, true, or false")
  end
  return value
end

local function checked_xytext(value)
  if value == nil then
    return nil
  end
  if type(value) ~= "table" then
    fail("annotate xytext must be a {x, y} table")
  end

  local x, y = value[1], value[2]
  if x == nil and y == nil and (value.x ~= nil or value.y ~= nil) then
    x, y = value.x, value.y
  end
  if value[3] ~= nil or (value[1] ~= nil and value[2] == nil) then
    fail("annotate xytext must contain exactly two coordinates")
  end
  if x == nil then
    fail("annotate xytext requires an x coordinate")
  end
  if y == nil then
    fail("annotate xytext requires a y coordinate")
  end

  return {
    util.check_number(x, "annotate xytext x"),
    util.check_number(y, "annotate xytext y"),
  }
end

local function checked_arrow(value, color)
  if value == nil or value == false then
    return nil
  end
  if value == true then
    return {
      color = color,
      linewidth = DEFAULT_ARROW_LINEWIDTH,
      head = DEFAULT_ARROW_HEAD,
    }
  end
  if type(value) ~= "table" then
    fail("annotate arrow must be a boolean or an options table")
  end

  value = util.check_options(value, ARROW_OPTIONS, "annotate arrow")
  local arrow_color = color
  if value.color ~= nil then
    arrow_color = util.check_color(value.color, "annotate arrow color")
  end

  local linewidth = DEFAULT_ARROW_LINEWIDTH
  local width = value.linewidth
  if width == nil then width = value.width end
  if width ~= nil then
    linewidth = util.check_number(width, "annotate arrow linewidth", 0)
  end

  local head = DEFAULT_ARROW_HEAD
  local head_value = value.head
  if head_value == nil then head_value = value.headsize end
  if head_value ~= nil then
    head = util.check_number(head_value, "annotate arrow head", 0)
  end

  return {
    color = arrow_color,
    linewidth = linewidth,
    head = head,
  }
end

function Figure.new(opts)
  opts = util.check_options(opts, {
    width = true,
    height = true,
    dpi = true,
    xscale = true,
    yscale = true,
  }, "figure")

  local dpi = DEFAULT_DPI
  if opts.dpi ~= nil then
    dpi = util.check_number(opts.dpi, "figure dpi", 1)
  end

  local width
  if opts.width == nil then
    width = math.floor(DEFAULT_WIDTH_INCHES * dpi + 0.5)
  else
    width = util.check_number(opts.width, "figure width", 1)
  end

  local height
  if opts.height == nil then
    height = math.floor(DEFAULT_HEIGHT_INCHES * dpi + 0.5)
  else
    height = util.check_number(opts.height, "figure height", 1)
  end

  return setmetatable({
    width = width,
    height = height,
    dpi = dpi,
    _series = {},
    _annotations = {},
    _color_serial = 0,
    _title = nil,
    _twin = nil,
    _twiny = nil,
    _xlabel = nil,
    _ylabel = nil,
    _xlim = nil,
    _ylim = nil,
    _xscale = checked_scale(opts.xscale, "figure xscale", true),
    _yscale = checked_scale(opts.yscale, "figure yscale", true),
    _grid = false,
    _grid_opts = { color = "#d9d9d9", linewidth = 1, linestyle = "solid" },
    _facecolor = "#ffffff",
    _aria_label = nil,
    _legend_requested = false,
    _legend_opts = { loc = "upper right", frame = true },
    _category_ticks = nil,
    _colorbar = false,
    _xtick_rotation = 0,
    _xticks = nil,
    _yticks = nil,
    _xtick_format = nil,
    _ytick_format = nil,
    _xdate_format = nil,
  }, Figure)
end

function Figure:plot(x, y, opts)
  opts = util.check_options(opts, PLOT_OPTIONS, "plot")
  local xv = data.sequence(x, "plot x")
  local yv = data.sequence(y, "plot y")
  if #xv ~= #yv then
    fail(string.format("plot x and y must have the same length (%d ~= %d)", #xv, #yv))
  end

  local linewidth = 2
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "plot linewidth", 0)
  end

  local linestyle = opts.linestyle or "solid"
  if type(linestyle) ~= "string" or not LINESTYLES[linestyle] then
    fail("plot linestyle must be one of solid, dashed, dotted, or none")
  end

  local marker = checked_marker(opts.marker, "plot")
  local markersize = 4
  if opts.markersize ~= nil then
    markersize = util.check_number(opts.markersize, "plot markersize", 0.1)
  end

  local style = checked_style(self, opts, "plot")
  style.linewidth = linewidth
  style.linestyle = linestyle
  style.marker = marker
  style.markersize = markersize

  self._series[#self._series + 1] = {
    kind = "line",
    x = xv,
    y = yv,
    style = style,
  }
  return self
end

local function ensure_polar_state(self)
  if self._pie ~= nil then
    fail("cannot combine pie and polar plots in one figure")
  end
  if #self._series > 0 then
    fail("cannot mix cartesian and polar series in one figure; create a separate figure")
  end
  return polar.ensure(self)
end

-- Add a polar line series.  Theta values are radians and r values share the
-- same length.  A figure is either Cartesian or polar; mixing the two is
-- rejected so that a typo cannot silently produce an empty plot.
function Figure:polar(theta, r, opts)
  opts = util.check_options(opts, POLAR_LINE_OPTIONS, "polar")
  local tv = data.sequence(theta, "polar theta")
  local rv = data.sequence(r, "polar r")
  if #tv ~= #rv then
    fail(string.format(
      "polar theta and r must have the same length (%d ~= %d)", #tv, #rv))
  end

  local linewidth = 2
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "polar linewidth", 0)
  end
  local linestyle = opts.linestyle or "solid"
  if type(linestyle) ~= "string" or not LINESTYLES[linestyle] then
    fail("polar linestyle must be one of solid, dashed, dotted, or none")
  end
  local marker = checked_marker(opts.marker, "polar")
  local markersize = 4
  if opts.markersize ~= nil then
    markersize = util.check_number(opts.markersize, "polar markersize", 0.1)
  end

  local style = checked_style(self, opts, "polar")
  style.linewidth = linewidth
  style.linestyle = linestyle
  style.marker = marker
  style.markersize = markersize

  local state = ensure_polar_state(self)
  state.series[#state.series + 1] = {
    kind = "line",
    theta = tv,
    r = rv,
    style = style,
  }
  return self
end

-- Add a polar scatter series.  Sizes are marker radii in SVG user units and
-- colors may be a single value or one value per point.
function Figure:polar_scatter(theta, r, opts)
  opts = util.check_options(opts, POLAR_SCATTER_OPTIONS, "polar scatter")
  local tv = data.sequence(theta, "polar scatter theta")
  local rv = data.sequence(r, "polar scatter r")
  if #tv ~= #rv then
    fail(string.format(
      "polar scatter theta and r must have the same length (%d ~= %d)",
      #tv, #rv))
  end

  local radius = 4
  local radii
  local radius_arg = opts.size
  if radius_arg == nil then radius_arg = opts.markersize end
  if radius_arg == nil then radius_arg = opts.s end
  if type(radius_arg) == "table" then
    if #radius_arg ~= #tv then
      fail("polar scatter size array must match the number of points")
    end
    radii = {}
    for index = 1, #radius_arg do
      radii[index] = util.check_number(radius_arg[index],
        "polar scatter size", 0.1)
    end
    radius = radii[1] or radius
  elseif radius_arg ~= nil then
    radius = util.check_number(radius_arg, "polar scatter size", 0.1)
  end

  local linewidth = 1
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "polar scatter linewidth", 0)
  end

  local point_colors
  local style_opts = opts
  if type(opts.color) == "table" then
    if #opts.color ~= #tv then
      fail("polar scatter color array must match the number of points")
    end
    point_colors = {}
    for index = 1, #opts.color do
      point_colors[index] = util.check_color(opts.color[index],
        "polar scatter color")
    end
    style_opts = {}
    for key, value in pairs(opts) do style_opts[key] = value end
    style_opts.color = point_colors[1]
  end

  local style = checked_style(self, style_opts, "polar scatter")
  style.marker = checked_marker(opts.marker, "polar scatter") or "circle"
  style.radius = radius
  style.radii = radii
  style.colors = point_colors
  style.linewidth = linewidth

  local state = ensure_polar_state(self)
  state.series[#state.series + 1] = {
    kind = "scatter",
    theta = tv,
    r = rv,
    style = style,
  }
  return self
end

function Figure:scatter(x, y, opts)
  opts = util.check_options(opts, SCATTER_OPTIONS, "scatter")
  local xv = data.sequence(x, "scatter x")
  local yv = data.sequence(y, "scatter y")
  if #xv ~= #yv then
    fail(string.format("scatter x and y must have the same length (%d ~= %d)", #xv, #yv))
  end

  local radius = 4
  local radii
  local radius_arg = opts.size
  if radius_arg == nil then
    radius_arg = opts.markersize
  end
  if radius_arg == nil then
    radius_arg = opts.s
  end
  if type(radius_arg) == "table" then
    if #radius_arg ~= #xv then
      fail("scatter size array must match the number of points")
    end
    radii = {}
    for i = 1, #radius_arg do
      radii[i] = util.check_number(radius_arg[i], "scatter size", 0.1)
    end
    radius = radii[1] or radius
  elseif radius_arg ~= nil then
    radius = util.check_number(radius_arg, "scatter size", 0.1)
  end

  local linewidth = 1
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "scatter linewidth", 0)
  end

  local point_colors
  local style_opts = opts
  if type(opts.color) == "table" then
    if #opts.color ~= #xv then
      fail("scatter color array must match the number of points")
    end
    point_colors = {}
    for i = 1, #opts.color do
      point_colors[i] = util.check_color(opts.color[i], "scatter color")
    end
    style_opts = {}
    for key, value in pairs(opts) do style_opts[key] = value end
    style_opts.color = point_colors[1]
  end
  local style = checked_style(self, style_opts, "scatter")
  style.marker = checked_marker(opts.marker, "scatter") or "circle"
  style.radius = radius
  style.radii = radii
  style.colors = point_colors
  style.linewidth = linewidth

  self._series[#self._series + 1] = {
    kind = "scatter",
    x = xv,
    y = yv,
    style = style,
  }
  return self
end

local EVENT_OPTIONS = {
  color = true, label = true, linewidth = true, alpha = true,
}

function Figure:eventplot(positions, opts)
  opts = util.check_options(opts, EVENT_OPTIONS, "eventplot")
  local rows = {}
  if type(positions) ~= "table" then
    fail("eventplot positions must be a table")
  end
  if #positions > 0 and (type(positions[1]) == "table" or
      data.is_tensor_like(positions[1])) then
    for i = 1, #positions do
      rows[i] = data.sequence(positions[i], "eventplot row")
    end
  else
    rows[1] = data.sequence(positions, "eventplot positions")
  end
  local linewidth = opts.linewidth
  if linewidth == nil then linewidth = 2 end
  linewidth = util.check_number(linewidth, "eventplot linewidth", 0)
  local style = checked_style(self, opts, "eventplot")
  style.linewidth = linewidth
  self._series[#self._series + 1] = {
    kind = "eventplot", rows = rows, style = style,
  }
  return self
end

function Figure:ecdf(values, opts)
  opts = util.check_options(opts, STEP_OPTIONS, "ecdf")
  local sorted = data.sequence(values, "ecdf values")
  table.sort(sorted)
  local count = #sorted
  if count == 0 then fail("ecdf requires at least one value") end
  local xs, ys = {}, {}
  for i = 1, count do
    xs[i] = sorted[i]
    ys[i] = i / count
  end
  local style = checked_style(self, opts, "ecdf")
  style.linewidth = opts.linewidth or 2
  self._series[#self._series + 1] = {
    kind = "step", x = xs, y = ys, where = "post", style = style,
  }
  return self
end

function Figure:hist(values, opts)
  opts = util.check_options(opts, HIST_OPTIONS, "hist")
  local values_v = data.sequence(values, "hist values")

  local bins = 10
  if opts.bins ~= nil then
    bins = util.check_integer(opts.bins, "hist bins", 1, 1000)
  end

  local lo, hi
  if opts.range ~= nil then
    local range = opts.range
    if type(range) ~= "table" or #range ~= 2 then
      fail("hist range must be a {min, max} table")
    end
    lo = util.check_number(range[1], "hist range min")
    hi = util.check_number(range[2], "hist range max")
    if lo >= hi then
      fail("hist range min must be less than range max")
    end
  else
    lo, hi = values_v[1], values_v[1]
    for i = 2, #values_v do
      if values_v[i] < lo then lo = values_v[i] end
      if values_v[i] > hi then hi = values_v[i] end
    end
    if lo == hi then
      local pad = math.abs(lo) * 0.5
      if pad == 0 then pad = 0.5 end
      lo, hi = lo - pad, hi + pad
    end
  end

  local density = opts.density == true
  local cumulative = opts.cumulative == true
  if opts.density ~= nil and type(opts.density) ~= "boolean" then
    fail("hist density must be a boolean")
  end
  if opts.cumulative ~= nil and type(opts.cumulative) ~= "boolean" then
    fail("hist cumulative must be a boolean")
  end
  local bin_width = (hi - lo) / bins
  local counts = {}
  for i = 1, bins do
    counts[i] = 0
  end
  for i = 1, #values_v do
    local value = values_v[i]
    if value >= lo and value <= hi then
      local index = math.floor((value - lo) / bin_width) + 1
      if index > bins then index = bins end
      if index < 1 then index = 1 end
      counts[index] = counts[index] + 1
    end
  end

  if density then
    local total = 0
    for i = 1, bins do total = total + counts[i] end
    if total > 0 then
      for i = 1, bins do counts[i] = counts[i] / (total * bin_width) end
    end
  end
  if cumulative then
    for i = 2, bins do counts[i] = counts[i] + counts[i - 1] end
  end

  local edges = {}
  for i = 0, bins do
    edges[i + 1] = lo + i * bin_width
  end

  local style = checked_style(self, opts, "hist")
  style.bins = bins

  self._series[#self._series + 1] = {
    kind = "hist",
    edges = edges,
    counts = counts,
    density = density,
    cumulative = cumulative,
    style = style,
  }
  return self
end

-- A table is treated as bar options only when every key is a supported option.
-- Series tables use numeric keys, and series descriptors use keys such as
-- values/label/color, so both remain distinguishable from a trailing opts table.
local function bar_options_table(value)
  if type(value) ~= "table" or data.is_tensor_like(value) then
    return false
  end
  for key in pairs(value) do
    if type(key) ~= "string" or not BAR_OPTIONS[key] then
      return false
    end
  end
  return true
end

-- True when a single bar values argument contains several series rather than
-- one numeric sequence. Both arrays of series and label -> series maps work.
local function bar_series_container(value)
  if type(value) ~= "table" or data.is_tensor_like(value) then
    return false
  end
  if #value > 0 then
    local first = value[1]
    return type(first) == "table" or type(first) == "userdata"
  end
  if next(value) == nil then
    return false
  end
  -- Array wrappers such as { data = {...}, n = ... } are one sequence.
  if value.data ~= nil or value.n ~= nil or value.size ~= nil
      or value.shape ~= nil or value.ndim ~= nil then
    return false
  end
  -- A single descriptor such as { values = {...}, label = "..." }.
  if value.values ~= nil or value.y ~= nil then
    return false
  end
  for _, item in pairs(value) do
    if type(item) ~= "table" and type(item) ~= "userdata" then
      return false
    end
  end
  return true
end

local function checked_series_labels(value, name, count)
  if type(value) ~= "table" then
    fail(name .. " must be a table of series labels")
  end
  if #value ~= count then
    fail(string.format("%s must match the number of value series (%d ~= %d)",
      name, #value, count))
  end
  local labels = {}
  for i = 1, count do
    labels[i] = util.check_string(value[i], string.format("%s[%d]", name, i), true)
  end
  return labels
end

-- Values may be one numeric sequence (the original API), a list of sequences,
-- a list of { values = ..., label = ... } descriptors, or a label -> sequence
-- map. A trailing options table is shared by every series.
function Figure:bar(labels_or_x, values, opts, ...)
  local raw_args = {}
  if values ~= nil then raw_args[#raw_args + 1] = values end
  if opts ~= nil then raw_args[#raw_args + 1] = opts end
  local extra_count = select("#", ...)
  for i = 1, extra_count do
    local extra = select(i, ...)
    if extra ~= nil then raw_args[#raw_args + 1] = extra end
  end
  if #raw_args == 0 then
    fail("bar requires values as its second argument")
  end

  opts = nil
  if #raw_args > 1 then
    local last = raw_args[#raw_args]
    if type(last) == "table" then
      if bar_options_table(last) then
        opts = table.remove(raw_args)
      end
    elseif type(last) ~= "userdata" and #raw_args == 2 then
      -- Preserve the original error for a non-table third options argument.
      opts = table.remove(raw_args)
    end
  end
  opts = util.check_options(opts, BAR_OPTIONS, "bar")

  local raw_series = {}
  local fallback_labels
  if #raw_args > 1 then
    raw_series = raw_args
  else
    local value = raw_args[1]
    if bar_series_container(value) then
      if #value > 0 then
        for i = 1, #value do raw_series[i] = value[i] end
      else
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b)
          return tostring(a) < tostring(b)
        end)
        fallback_labels = {}
        for i, key in ipairs(keys) do
          raw_series[i] = value[key]
          fallback_labels[i] = tostring(key)
        end
      end
    else
      raw_series[1] = value
    end
  end

  local series_values = {}
  local series_meta = {}
  for i, raw in ipairs(raw_series) do
    local source = raw
    local meta = { label = fallback_labels and fallback_labels[i] or nil }
    if type(raw) == "table" and not data.is_tensor_like(raw) then
      local descriptor_values = raw.values
      if descriptor_values == nil then descriptor_values = raw.y end
      if descriptor_values ~= nil then
        source = descriptor_values
        if raw.label ~= nil then meta.label = raw.label end
        meta.color = raw.color
        meta.edgecolor = raw.edgecolor
        meta.alpha = raw.alpha
      end
    end
    local name = "bar values"
    if #raw_series > 1 then
      name = string.format("bar values[%d]", i)
    end
    series_values[i] = data.sequence(source, name)
    series_meta[i] = meta
  end
  local series_count = #series_values

  local kind, xv
  if type(labels_or_x) == "table" and #labels_or_x > 0 then
    kind, xv = data.bar_x(labels_or_x, "bar labels_or_x")
  else
    kind = "numeric"
    xv = data.sequence(labels_or_x, "bar x")
  end

  for i = 1, series_count do
    local yv = series_values[i]
    if #xv ~= #yv then
      fail(string.format(
        "bar labels/x and values must have the same length (%d ~= %d)",
        #xv, #yv))
    end
  end

  if opts.stacked ~= nil then
    util.check_boolean(opts.stacked, "bar stacked")
  end
  if opts.grouped ~= nil then
    util.check_boolean(opts.grouped, "bar grouped")
  end
  if opts.stacked and opts.grouped then
    fail("bar stacked and grouped cannot both be true")
  end

  local label_list
  local raw_labels = opts.labels
  if raw_labels == nil then raw_labels = opts.series_labels end
  if raw_labels == nil and type(opts.label) == "table" then
    raw_labels = opts.label
  end
  if raw_labels ~= nil then
    label_list = checked_series_labels(raw_labels, "bar labels", series_count)
  end
  if series_count > 1 and opts.label ~= nil and type(opts.label) ~= "table"
      and label_list == nil then
    fail("bar label is ambiguous for multiple series; use labels instead")
  end

  local color_list
  local raw_colors = opts.colors
  if raw_colors == nil and type(opts.color) == "table" then
    raw_colors = opts.color
  end
  if raw_colors ~= nil then
    if type(raw_colors) ~= "table" then
      fail("bar colors must be a table of per-series colors")
    end
    if #raw_colors ~= series_count then
      fail(string.format(
        "bar colors must match the number of value series (%d ~= %d)",
        #raw_colors, series_count))
    end
    color_list = {}
    for i = 1, series_count do
      color_list[i] = util.check_color(raw_colors[i],
        string.format("bar colors[%d]", i))
    end
  end
  local global_color
  if type(opts.color) == "string" then
    global_color = opts.color
  elseif opts.color ~= nil and type(opts.color) ~= "table" then
    util.check_color(opts.color, "bar color")
  end

  local width_fraction = 0.8
  if opts.width ~= nil then
    width_fraction = util.check_number(opts.width, "bar width", 0.01, 1)
  end

  local bar_colors = nil
  if opts.bar_colors ~= nil then
    if type(opts.bar_colors) ~= "table" then
      fail("bar bar_colors must be a table")
    end
    if series_count ~= 1 then
      fail("bar bar_colors supports a single value series")
    end
    if #opts.bar_colors ~= #xv then
      fail(string.format(
        "bar bar_colors must have one color per bar (%d ~= %d)",
        #opts.bar_colors, #xv))
    end
    bar_colors = {}
    for i = 1, #opts.bar_colors do
      bar_colors[i] = util.check_color(opts.bar_colors[i],
        "bar bar_colors[" .. i .. "]")
    end
  end
  if opts.show_values ~= nil then
    util.check_boolean(opts.show_values, "bar show_values")
  end
  local hatch = opts.hatch
  if hatch ~= nil then
    if type(hatch) ~= "table" then
      error("bar hatch must be a table of per-series hatches", 2)
    end
    if #hatch ~= series_count then
      error("bar hatch must match the number of value series", 2)
    end
    for i = 1, #hatch do
      local value = hatch[i]
      if type(value) ~= "string" or
          not ({ ["/"]=true, ["\\"]=true, ["|"]=true, ["-"]=true,
            ["+"]=true, x=true, ["."]=true, o=true })[value] then
        error("bar hatch entries must be /, \\, |, -, +, x, ., or o", 2)
      end
    end
  end

  local positions = {}
  if kind == "categories" then
    for i = 1, #xv do
      positions[i] = i
    end
  else
    for i = 1, #xv do
      positions[i] = xv[i]
    end
  end

  local sorted = {}
  for i = 1, #positions do sorted[i] = positions[i] end
  table.sort(sorted)
  local spacing
  for i = 2, #sorted do
    local delta = sorted[i] - sorted[i - 1]
    if delta > 0 and (spacing == nil or delta < spacing) then
      spacing = delta
    end
  end

  local mode
  if opts.stacked then
    mode = "stacked"
  elseif opts.grouped or series_count > 1 then
    mode = "grouped"
  else
    mode = "single"
  end

  local group_width = (spacing or 1) * width_fraction
  local bar_width = group_width
  if mode == "grouped" and series_count > 1 then
    bar_width = group_width / series_count
  end

  local styles = {}
  for i = 1, series_count do
    local meta = series_meta[i]
    local color = meta.color
    if color == nil and color_list ~= nil then color = color_list[i] end
    if color == nil then color = global_color end
    local label
    if label_list ~= nil then
      label = label_list[i]
    elseif meta.label ~= nil then
      label = meta.label
    elseif series_count == 1 then
      label = opts.label
    end
    local style = checked_style(self, {
      color = color,
      label = label,
      alpha = meta.alpha ~= nil and meta.alpha or opts.alpha,
      edgecolor = meta.edgecolor ~= nil and meta.edgecolor or opts.edgecolor,
    }, "bar")
    style.width_fraction = width_fraction
    styles[i] = style
  end

  local stacked_bottoms
  if mode == "stacked" then
    local positive, negative = {}, {}
    for i = 1, #positions do
      positive[i] = 0
      negative[i] = 0
    end
    stacked_bottoms = {}
    for series_index = 1, series_count do
      local bottoms = {}
      local yv = series_values[series_index]
      for i = 1, #positions do
        local value = yv[i]
        if value >= 0 then
          bottoms[i] = positive[i]
          positive[i] = positive[i] + value
        else
          bottoms[i] = negative[i]
          negative[i] = negative[i] + value
        end
      end
      stacked_bottoms[series_index] = bottoms
    end
  end

  if kind == "categories" then
    self._category_ticks = {}
    for i = 1, #xv do
      self._category_ticks[i] = { position = i, label = xv[i] }
    end
  end

  for i = 1, series_count do
    if hatch then styles[i].hatch = hatch[i] end
    local entry = {
      kind = "bar",
      x = positions,
      y = series_values[i],
      width = bar_width,
      category = kind == "categories",
      style = styles[i],
      mode = mode,
      series_index = i,
      series_count = series_count,
      bar_colors = bar_colors,
      show_values = opts.show_values == true,
    }
    if mode == "grouped" then
      entry.offset = 0
      if series_count > 1 then
        entry.offset = (i - (series_count + 1) / 2) * bar_width
      end
    elseif mode == "stacked" then
      entry.bottom = stacked_bottoms[i]
    end
    self._series[#self._series + 1] = entry
  end
  return self
end

-- Render a rectangular scalar matrix as a heatmap.  opts.vmin/vmax override
-- the automatic range; opts.colorbar defaults to true.
local function checked_ticks(values, name)
  if type(values) ~= "table" or #values == 0 then
    fail(name .. " expects a non-empty table of tick values")
  end
  local result = {}
  for index = 1, #values do
    result[index] = util.check_number(values[index], name .. " value " .. index)
  end
  return result
end

-- Format x-axis tick labels as calendar dates.  Values are Unix timestamps;
-- format uses os.date syntax (default "%Y-%m-%d").
-- Create a secondary y axis sharing the x axis.  The returned object exposes
-- the normal series methods (plot/scatter/errorbar) and its own ylim/yscale/
-- ylabel; it is rendered on the right side by the parent figure.
function Figure:twinx()
  if self._twin ~= nil then return self._twin end
  local twin = setmetatable({
    _parent = self,
    _series = {},
    _color_serial = 0,
    _yscale = "linear",
    _ylim = nil,
    _ylabel = nil,
    _ytick_format = nil,
    _legend_requested = false,
    _legend_opts = { loc = "upper right", frame = true },
  }, Figure)
  self._twin = twin
  return twin
end

-- Create a secondary x axis sharing the y axis.  The returned object supports
-- the normal series methods and its own xlim/xscale/xlabel; it renders on the
-- top side.
function Figure:twiny()
  if self._twiny ~= nil then return self._twiny end
  local twiny = setmetatable({
    _parent = self,
    _series = {},
    _color_serial = 0,
    _xscale = "linear",
    _xlim = nil,
    _xlabel = nil,
    _xtick_format = nil,
    _xdate_format = nil,
  }, Figure)
  self._twiny = twiny
  return twiny
end

function Figure:xdate(format)
  if format ~= nil and type(format) ~= "string" then
    fail("xdate format must be a string or nil")
  end
  self._xdate_format = format or "%Y-%m-%d"
  return self
end

function Figure:xticks(values, labels)
  self._xticks = { values = checked_ticks(values, "xticks"),
    labels = labels and checked_series_labels(labels, "xticks labels", #values) or nil }
  return self
end

function Figure:yticks(values, labels)
  self._yticks = { values = checked_ticks(values, "yticks"),
    labels = labels and checked_series_labels(labels, "yticks labels", #values) or nil }
  return self
end

function Figure:xtick_format(formatter)
  if type(formatter) ~= "function" then fail("xtick_format expects a function") end
  self._xtick_format = formatter
  return self
end

function Figure:ytick_format(formatter)
  if type(formatter) ~= "function" then fail("ytick_format expects a function") end
  self._ytick_format = formatter
  return self
end

function Figure:xtick_rotation(angle)
  if type(angle) ~= "number" or angle % 1 ~= 0 or angle < -90 or angle > 90 then
    fail("xtick_rotation must be an integer in [-90, 90]")
  end
  self._xtick_rotation = angle
  return self
end

-- Horizontal bars for a single numeric series.  Category labels are placed on
-- the y axis; values extend horizontally from zero.
-- Pie/donut chart.  Values must be non-negative and sum to a positive total.
-- Basic 3-D projection: isometric-style x/y with a z offset.  This is a
-- projected 2-D plot, not a full 3-D axes implementation.
function Figure:plot3(x, y, z, opts)
  local xv = data.sequence(x, "plot3 x")
  local yv = data.sequence(y, "plot3 y")
  local zv = data.sequence(z, "plot3 z")
  if #xv ~= #yv or #xv ~= #zv then
    fail("plot3 x, y, and z must have the same length")
  end
  local px, py = {}, {}
  for i = 1, #xv do
    px[i] = xv[i] + 0.5 * zv[i]
    py[i] = yv[i] + 0.5 * zv[i]
  end
  self._projection3d = true
  return self:plot(px, py, opts)
end

function Figure:scatter3(x, y, z, opts)
  local xv = data.sequence(x, "scatter3 x")
  local yv = data.sequence(y, "scatter3 y")
  local zv = data.sequence(z, "scatter3 z")
  if #xv ~= #yv or #xv ~= #zv then
    fail("scatter3 x, y, and z must have the same length")
  end
  local px, py = {}, {}
  for i = 1, #xv do
    px[i] = xv[i] + 0.5 * zv[i]
    py[i] = yv[i] + 0.5 * zv[i]
  end
  self._projection3d = true
  return self:scatter(px, py, opts)
end

function Figure:fill_between(x, y1, y2, opts)
  opts = util.check_options(opts, FILL_OPTIONS, "fill_between")
  local xv = data.sequence(x, "fill_between x")
  local lower = data.sequence(y1, "fill_between y1")
  local upper = data.sequence(y2 or y1, "fill_between y2")
  if #xv ~= #lower or #xv ~= #upper then
    fail("fill_between x, y1, and y2 must have the same length")
  end
  local style = checked_style(self, opts, "fill_between")
  style.linewidth = 0
  self._series[#self._series + 1] = {
    kind = "fill", x = xv, y1 = lower, y2 = upper, style = style,
  }
  return self
end

function Figure:fill_betweenx(y, x1, x2, opts)
  opts = util.check_options(opts, FILL_OPTIONS, "fill_betweenx")
  local yv = data.sequence(y, "fill_betweenx y")
  local left = data.sequence(x1, "fill_betweenx x1")
  local right = data.sequence(x2 or x1, "fill_betweenx x2")
  if #yv ~= #left or #yv ~= #right then
    fail("fill_betweenx y, x1, and x2 must have the same length")
  end
  local style = checked_style(self, opts, "fill_betweenx")
  style.linewidth = 0
  self._series[#self._series + 1] = {
    kind = "fillx", y = yv, x1 = left, x2 = right, style = style,
  }
  return self
end

function Figure:pcolormesh(values, opts)
  return self:imshow(values, opts)
end

function Figure:pcolor(values, opts)
  return self:imshow(values, opts)
end

function Figure:contourf(values, opts)
  opts = opts or {}
  if type(opts) ~= "table" then fail("contourf options must be a table") end
  local image_opts = {
    vmin = opts.vmin, vmax = opts.vmax, colorbar = opts.colorbar,
    label = opts.label,
  }
  self:imshow(values, image_opts)
  if opts.contours ~= false then
    self:contour(values, { levels = opts.levels, color = opts.color,
      linewidth = opts.linewidth })
  end
  return self
end

function Figure:step(x, y, opts)
  opts = util.check_options(opts, STEP_OPTIONS, "step")
  local xv = data.sequence(x, "step x")
  local yv = data.sequence(y, "step y")
  if #xv ~= #yv then fail("step x and y must have the same length") end
  local where = opts.where or "pre"
  if where ~= "pre" and where ~= "post" and where ~= "mid" then
    fail("step where must be 'pre', 'post', or 'mid'")
  end
  local linewidth = opts.linewidth
  if linewidth == nil then linewidth = 2 end
  linewidth = util.check_number(linewidth, "step linewidth", 0)
  local linestyle = opts.linestyle or "solid"
  if not LINESTYLES[linestyle] then fail("invalid step linestyle") end
  local style = checked_style(self, opts, "step")
  style.linewidth = linewidth
  style.linestyle = linestyle
  self._series[#self._series + 1] = {
    kind = "step", x = xv, y = yv, where = where, style = style,
  }
  return self
end

function Figure:stem(x, y, opts)
  opts = util.check_options(opts, STEM_OPTIONS, "stem")
  local xv = data.sequence(x, "stem x")
  local yv = data.sequence(y, "stem y")
  if #xv ~= #yv then fail("stem x and y must have the same length") end
  local linewidth = opts.linewidth or 1.5
  linewidth = util.check_number(linewidth, "stem linewidth", 0)
  local markersize = opts.markersize or 4
  markersize = util.check_number(markersize, "stem markersize", 0.1)
  local style = checked_style(self, opts, "stem")
  style.linewidth = linewidth
  style.markersize = markersize
  self._series[#self._series + 1] = {
    kind = "stem", x = xv, y = yv, style = style,
  }
  return self
end

function Figure:stackplot(x, series, opts)
  opts = util.check_options(opts, STACK_OPTIONS, "stackplot")
  if type(series) ~= "table" or #series == 0 then
    fail("stackplot expects a non-empty table of series")
  end
  local xv = data.sequence(x, "stackplot x")
  local labels = opts.labels
  if labels ~= nil and (type(labels) ~= "table" or #labels ~= #series) then
    fail("stackplot labels must match the number of series")
  end
  local colors_list = opts.colors
  if colors_list ~= nil and (type(colors_list) ~= "table" or
      #colors_list ~= #series) then
    fail("stackplot colors must match the number of series")
  end
  local bottom = {}
  for i = 1, #xv do bottom[i] = 0 end
  for index, values in ipairs(series) do
    local yv = data.sequence(values, "stackplot series " .. index)
    if #yv ~= #xv then fail("stackplot series must match x length") end
    local top = {}
    for i = 1, #xv do top[i] = bottom[i] + yv[i] end
    local color = colors_list and util.check_color(colors_list[index],
      "stackplot colors[" .. index .. "]") or colors.next(self._color_serial)
    if colors_list == nil then self._color_serial = self._color_serial + 1 end
    self._series[#self._series + 1] = {
      kind = "fill",
      x = xv,
      y1 = { unpack(bottom) },
      y2 = top,
      style = { color = color, label = labels and labels[index],
        alpha = opts.alpha or 0.8,
        edgecolor = opts.edgecolor and util.check_color(opts.edgecolor,
          "stackplot edgecolor") or nil },
    }
    bottom = top
  end
  return self
end

function Figure:pie(values, opts)
  if self._polar ~= nil then
    fail("cannot combine pie and polar plots in one figure")
  end
  opts = util.check_options(opts, PIE_OPTIONS, "pie")
  local values_v = data.sequence(values, "pie values")
  if #values_v == 0 then fail("pie values must be non-empty") end
  local total = 0
  for _, value in ipairs(values_v) do
    if value < 0 then fail("pie values must be non-negative") end
    total = total + value
  end
  if total <= 0 then fail("pie values must have a positive total") end
  local labels = nil
  if opts.labels ~= nil then
    labels = data.labels(opts.labels, "pie labels")
    if #labels ~= #values_v then
      fail("pie labels must match the number of values")
    end
  end
  local colors_list = {}
  if opts.colors ~= nil then
    if type(opts.colors) ~= "table" or #opts.colors ~= #values_v then
      fail("pie colors must have one entry per value")
    end
    for i = 1, #opts.colors do
      colors_list[i] = util.check_color(opts.colors[i], "pie colors[" .. i .. "]")
    end
  else
    for i = 1, #values_v do colors_list[i] = colors.next(i - 1) end
  end
  local startangle = opts.startangle
  if startangle == nil then startangle = 90 end
  startangle = util.check_number(startangle, "pie startangle")
  local radius = opts.radius
  if radius == nil then radius = 0.34 end
  radius = util.check_number(radius, "pie radius", 0.05, 0.5)
  local inner = opts.inner_radius
  if inner == nil then inner = 0 end
  inner = util.check_number(inner, "pie inner_radius", 0, 0.95)
  local autopct = opts.autopct
  if autopct == nil then autopct = false end
  if autopct ~= false and autopct ~= true and type(autopct) ~= "string" then
    fail("pie autopct must be false, true, or a format string")
  end
  local legend = opts.legend
  if legend == nil then legend = true end
  util.check_boolean(legend, "pie legend")
  local slices = {}
  local angle = startangle
  for index, value in ipairs(values_v) do
    local sweep = 360 * value / total
    slices[index] = {
      value = value,
      percent = 100 * value / total,
      start_angle = angle,
      end_angle = angle - sweep,
      color = colors_list[index],
      label = labels and labels[index] or ("slice " .. index),
    }
    angle = angle - sweep
  end
  self._pie = {
    slices = slices, radius = radius, inner_radius = inner,
    autopct = autopct, legend = legend,
  }
  return self
end

function Figure:donut(values, opts)
  opts = opts or {}
  if type(opts) ~= "table" then fail("donut options must be a table") end
  local copy = {}
  for key, value in pairs(opts) do copy[key] = value end
  if copy.inner_radius == nil then copy.inner_radius = 0.55 end
  return self:pie(values, copy)
end

function Figure:barh(labels_or_y, values, opts)
  opts = util.check_options(opts, BARH_OPTIONS, "barh")
  local values_v = data.sequence(values, "barh values")
  if #values_v == 0 then fail("barh values must be non-empty") end
  local kind, labels_or_positions
  if type(labels_or_y) == "table" and #labels_or_y > 0 and
      type(labels_or_y[1]) ~= "number" then
    kind = "categories"
    labels_or_positions = data.labels(labels_or_y, "barh labels")
  else
    kind = "numeric"
    labels_or_positions = data.sequence(labels_or_y, "barh y")
  end
  if #labels_or_positions ~= #values_v then
    fail(string.format(
      "barh labels/y and values must have the same length (%d ~= %d)",
      #labels_or_positions, #values_v))
  end
  local height = 0.7
  if opts.height ~= nil then
    height = util.check_number(opts.height, "barh height", 0.01, 1)
  end
  local color = opts.color and util.check_color(opts.color, "barh color") or
    colors.next(self._color_serial)
  if opts.color == nil then self._color_serial = self._color_serial + 1 end
  if opts.label ~= nil then util.check_string(opts.label, "barh label", true) end
  local edgecolor = opts.edgecolor and
    util.check_color(opts.edgecolor, "barh edgecolor") or nil
  local alpha = 1
  if opts.alpha ~= nil then alpha = util.check_alpha(opts.alpha, "barh alpha") end
  local positions = {}
  local labels = {}
  if kind == "categories" then
    for i = 1, #labels_or_positions do
      positions[i] = i
      labels[i] = labels_or_positions[i]
    end
    self._yticks = {
      values = positions,
      labels = labels,
    }
  else
    for i = 1, #labels_or_positions do positions[i] = labels_or_positions[i] end
  end
  local bar_colors = nil
  if opts.bar_colors ~= nil then
    if type(opts.bar_colors) ~= "table" or #opts.bar_colors ~= #values_v then
      fail("barh bar_colors must have one color per bar")
    end
    bar_colors = {}
    for i = 1, #opts.bar_colors do
      bar_colors[i] = util.check_color(opts.bar_colors[i],
        "barh bar_colors[" .. i .. "]")
    end
  end
  if opts.show_values ~= nil then
    util.check_boolean(opts.show_values, "barh show_values")
  end
  self._series[#self._series + 1] = {
    kind = "barh", x = values_v, y = positions, height = height,
    bar_colors = bar_colors, show_values = opts.show_values == true,
    style = { color = color, label = opts.label, alpha = alpha,
      edgecolor = edgecolor },
  }
  return self
end

function Figure:imshow(values, opts)
  opts = util.check_options(opts, {
    vmin = true, vmax = true, colorbar = true, label = true,
  }, "imshow")
  local rows, cols, matrix = data.matrix(values, "imshow values")
  local minimum, maximum = math.huge, -math.huge
  for r = 1, rows do
    for c = 1, cols do
      local value = matrix[r][c]
      if value < minimum then minimum = value end
      if value > maximum then maximum = value end
    end
  end
  if opts.vmin ~= nil then
    minimum = util.check_number(opts.vmin, "imshow vmin")
  end
  if opts.vmax ~= nil then
    maximum = util.check_number(opts.vmax, "imshow vmax")
  end
  if maximum <= minimum then
    maximum = minimum + 1
  end
  local colorbar = opts.colorbar
  if colorbar == nil then colorbar = true end
  util.check_boolean(colorbar, "imshow colorbar")
  self._colorbar = colorbar
  self._series[#self._series + 1] = {
    kind = "image", values = matrix, rows = rows, cols = cols,
    vmin = minimum, vmax = maximum,
    style = { color = "#000000", label = opts.label, alpha = 1 },
  }
  return self
end

-- Box-and-whisker plot for one or more numeric samples.
-- Contour lines computed with marching squares.  opts.levels is a count or an
-- explicit level table; each level becomes a separate line series.
function Figure:contour(values, opts)
  opts = util.check_options(opts, CONTOUR_OPTIONS, "contour")
  local rows, cols, matrix = data.matrix(values, "contour values")
  local minimum, maximum = math.huge, -math.huge
  for r = 1, rows do
    for c = 1, cols do
      local value = matrix[r][c]
      if value < minimum then minimum = value end
      if value > maximum then maximum = value end
    end
  end
  local levels = opts.levels
  if levels == nil then levels = 5 end
  if type(levels) == "number" then
    levels = util.check_integer(levels, "contour levels", 1, 50)
    local list = {}
    for i = 1, levels do
      list[i] = minimum + (maximum - minimum) * i / (levels + 1)
    end
    levels = list
  elseif type(levels) ~= "table" or #levels == 0 then
    fail("contour levels must be a positive count or a non-empty table")
  end
  local color = opts.color and util.check_color(opts.color, "contour color") or
    colors.next(self._color_serial)
  if opts.color == nil then self._color_serial = self._color_serial + 1 end
  local linewidth = opts.linewidth
  if linewidth == nil then linewidth = 1.5 end
  linewidth = util.check_number(linewidth, "contour linewidth", 0)
  local linestyle = opts.linestyle or "solid"
  if not LINESTYLES[linestyle] then fail("invalid contour linestyle") end
  if opts.labels ~= nil then util.check_boolean(opts.labels, "contour labels") end
  for _, level in ipairs(levels) do
    if type(level) ~= "number" then fail("contour levels must be numeric") end
    local segments = {}
    local function crossing(a, b, x0, y0, x1, y1)
      local da, db = a - level, b - level
      if da == 0 or db == 0 or da * db > 0 then return nil end
      local t = da / (da - db)
      return { x0 + (x1 - x0) * t, y0 + (y1 - y0) * t }
    end
    for r = 1, rows - 1 do
      for c = 1, cols - 1 do
        local x0, y0 = c - 1, rows - r
        local v0, v1 = matrix[r][c], matrix[r][c + 1]
        local v2, v3 = matrix[r + 1][c + 1], matrix[r + 1][c]
        local intersections = {}
        local function add(point)
          if point ~= nil then intersections[#intersections + 1] = point end
        end
        add(crossing(v0, v1, x0, y0 + 1, x0 + 1, y0 + 1))
        add(crossing(v1, v2, x0 + 1, y0 + 1, x0 + 1, y0))
        add(crossing(v2, v3, x0 + 1, y0, x0, y0))
        add(crossing(v3, v0, x0, y0, x0, y0 + 1))
        if #intersections == 2 then
          segments[#segments + 1] = {
            intersections[1][1], intersections[1][2],
            intersections[2][1], intersections[2][2],
          }
        elseif #intersections == 4 then
          segments[#segments + 1] = {
            intersections[1][1], intersections[1][2],
            intersections[2][1], intersections[2][2],
          }
          segments[#segments + 1] = {
            intersections[3][1], intersections[3][2],
            intersections[4][1], intersections[4][2],
          }
        end
      end
    end
    self._series[#self._series + 1] = {
      kind = "contour", segments = segments, level = level, rows = rows,
      cols = cols, level_label = opts.labels and level or nil,
      style = { color = color, label = opts.label, linewidth = linewidth,
        linestyle = linestyle, alpha = 1 },
    }
  end
  return self
end

function Figure:boxplot(values, opts)
  opts = util.check_options(opts, BOX_OPTIONS, "boxplot")
  if type(values) ~= "table" or #values == 0 then
    fail("boxplot expects a non-empty table of samples")
  end
  local samples = values
  if type(values[1]) == "number" then samples = { values } end
  local width = 0.6
  if opts.width ~= nil then
    width = util.check_number(opts.width, "boxplot width", 0.01, 1)
  end
  local labels = opts.labels
  if labels ~= nil then
    if type(labels) ~= "table" or #labels ~= #samples then
      fail("boxplot labels must have one entry per sample")
    end
  end
  local color = opts.color and util.check_color(opts.color, "boxplot color") or
    colors.next(self._color_serial)
  if opts.color == nil then self._color_serial = self._color_serial + 1 end
  if opts.label ~= nil then util.check_string(opts.label, "boxplot label", true) end
  local ticks = {}
  for index, sample in ipairs(samples) do
    local values_v = data.sequence(sample, "boxplot sample " .. index)
    if #values_v == 0 then fail("boxplot samples must be non-empty") end
    local sorted = {}
    for i = 1, #values_v do sorted[i] = values_v[i] end
    table.sort(sorted)
    local function quantile(p)
      if #sorted == 1 then return sorted[1] end
      local position = ( #sorted - 1) * p
      local lower = math.floor(position) + 1
      local upper = math.min(#sorted, lower + 1)
      local fraction = position - math.floor(position)
      return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction
    end
    local q1, median, q3 = quantile(0.25), quantile(0.5), quantile(0.75)
    local iqr = q3 - q1
    local low_limit, high_limit = q1 - 1.5 * iqr, q3 + 1.5 * iqr
    local whisker_low, whisker_high = q1, q3
    for _, value in ipairs(sorted) do
      if value >= low_limit and value <= q1 then whisker_low = value end
      if value <= high_limit and value >= q3 then whisker_high = value end
    end
    local outliers = {}
    for _, value in ipairs(sorted) do
      if value < whisker_low or value > whisker_high then
        outliers[#outliers + 1] = value
      end
    end
    self._series[#self._series + 1] = {
      kind = "box", position = index, width = width,
      q1 = q1, median = median, q3 = q3,
      low = whisker_low, high = whisker_high, outliers = outliers,
      style = { color = color, label = opts.label, alpha = 1 },
    }
    ticks[#ticks + 1] = {
      position = index,
      label = labels and tostring(labels[index]) or ("sample " .. index),
    }
  end
  self._category_ticks = ticks
  return self
end

function Figure:errorbar(x, y, yerr, xerr, opts)
  -- Allow the common four-argument form: errorbar(x, y, yerr, opts).
  if opts == nil and type(xerr) == "table" then
    local has_string_key = false
    for key in pairs(xerr) do
      if type(key) == "string" then has_string_key = true; break end
    end
    if has_string_key then
      opts, xerr = xerr, nil
    end
  end
  opts = util.check_options(opts, ERRORBAR_OPTIONS, "errorbar")
  local xv = data.sequence(x, "errorbar x")
  local yv = data.sequence(y, "errorbar y")
  if #xv ~= #yv then
    fail(string.format("errorbar x and y must have the same length (%d ~= %d)",
      #xv, #yv))
  end
  if yerr == nil then fail("errorbar requires yerr") end

  local function errors(value, name)
    local result
    if type(value) == "number" then
      result = {}
      for index = 1, #xv do result[index] = value end
    else
      result = data.sequence(value, name)
    end
    if #result ~= #xv then
      fail(string.format("%s must have the same length as x and y (%d ~= %d)",
        name, #result, #xv))
    end
    for index, error in ipairs(result) do
      if error < 0 then
        fail(string.format("%s[%d] must be non-negative", name, index))
      end
    end
    return result
  end

  local lower = errors(yerr, "errorbar yerr")
  local horizontal = nil
  if xerr ~= nil then
    horizontal = errors(xerr, "errorbar xerr")
  end

  local linewidth = 1.5
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "errorbar linewidth", 0)
  end
  local linestyle = opts.linestyle or "solid"
  if type(linestyle) ~= "string" or not LINESTYLES[linestyle] then
    fail("errorbar linestyle must be one of solid, dashed, dotted, or none")
  end
  local marker = checked_marker(opts.marker == nil and "circle" or opts.marker,
    "errorbar")
  local markersize = 4
  if opts.markersize ~= nil then
    markersize = util.check_number(opts.markersize, "errorbar markersize", 0.1)
  end
  local capsize = 4
  if opts.capsize ~= nil then
    capsize = util.check_number(opts.capsize, "errorbar capsize", 0)
  end
  local elinewidth = 1
  if opts.elinewidth ~= nil then
    elinewidth = util.check_number(opts.elinewidth, "errorbar elinewidth", 0)
  end

  local style = checked_style(self, opts, "errorbar")
  style.linewidth = linewidth
  style.linestyle = linestyle
  style.marker = marker
  style.markersize = markersize
  style.capsize = capsize
  style.elinewidth = elinewidth
  if opts.ecolor ~= nil then
    style.ecolor = util.check_color(opts.ecolor, "errorbar ecolor")
  else
    style.ecolor = style.color
  end

  self._series[#self._series + 1] = {
    kind = "errorbar",
    x = xv,
    y = yv,
    yerr = lower,
    xerr = horizontal,
    style = style,
  }
  return self
end

-- Add a text annotation anchored at data coordinates (x, y). If xytext is
-- supplied, the text is drawn there and an optional arrow points from the text
-- to (x, y). Options are validated eagerly; axis-scale checks happen at render
-- time, when the axes are known.
function Figure:annotate(text, x, y, opts)
  util.check_string(text, "annotate text", true)
  if y == nil then
    fail("annotate requires text, x, and y")
  end
  x = util.check_number(x, "annotate x")
  y = util.check_number(y, "annotate y")

  opts = util.check_options(opts, ANNOTATE_OPTIONS, "annotate")
  local xytext = checked_xytext(opts.xytext)

  local color = DEFAULT_ANNOTATION_COLOR
  if opts.color ~= nil then
    color = util.check_color(opts.color, "annotate color")
  end

  local fontsize = DEFAULT_ANNOTATION_FONTSIZE
  if opts.fontsize ~= nil then
    fontsize = util.check_number(opts.fontsize, "annotate fontsize", 0.1)
  end

  local align = opts.align or "left"
  if type(align) ~= "string" or not ANNOTATION_ALIGNS[align] then
    fail("annotate align must be one of left, center, or right")
  end

  self._annotations[#self._annotations + 1] = {
    text = text,
    x = x,
    y = y,
    xytext = xytext,
    color = color,
    fontsize = fontsize,
    align = align,
    arrow = checked_arrow(opts.arrow, color),
  }
  return self
end

function Figure:title(text)
  util.check_string(text, "title", true)
  self._title = text
  return self
end

function Figure:xlabel(text)
  util.check_string(text, "xlabel", true)
  self._xlabel = text
  return self
end

function Figure:ylabel(text)
  util.check_string(text, "ylabel", true)
  self._ylabel = text
  return self
end

function Figure:xlim(minimum, maximum)
  if maximum == nil then
    fail("xlim requires minimum and maximum")
  end
  minimum = util.check_number(minimum, "xlim minimum")
  maximum = util.check_number(maximum, "xlim maximum")
  if minimum >= maximum then
    fail("xlim minimum must be less than maximum")
  end
  self._xlim = { minimum, maximum }
  return self
end

function Figure:ylim(minimum, maximum)
  if maximum == nil then
    fail("ylim requires minimum and maximum")
  end
  minimum = util.check_number(minimum, "ylim minimum")
  maximum = util.check_number(maximum, "ylim maximum")
  if minimum >= maximum then
    fail("ylim minimum must be less than maximum")
  end
  self._ylim = { minimum, maximum }
  return self
end

-- Select the x-axis scale. Valid values are "linear" (the default) and "log".
-- Log scales require strictly positive data, which is checked when rendering.
function Figure:xscale(scale)
  self._xscale = checked_scale(scale, "xscale")
  return self
end

-- Select the y-axis scale. Valid values are "linear" (the default) and "log".
-- Log scales require strictly positive data, which is checked when rendering.
function Figure:yscale(scale)
  self._yscale = checked_scale(scale, "yscale")
  return self
end

local REFERENCE_OPTIONS = {
  color = true, linewidth = true, linestyle = true, alpha = true, label = true,
}

local function reference_style(figure, opts, name)
  opts = util.check_options(opts, REFERENCE_OPTIONS, name)
  local style = checked_style(figure, opts, name)
  style.linewidth = 1.5
  if opts.linewidth ~= nil then
    style.linewidth = util.check_number(opts.linewidth, name .. " linewidth", 0)
  end
  style.linestyle = opts.linestyle or "dashed"
  if not LINESTYLES[style.linestyle] then
    fail(name .. " linestyle must be one of solid, dashed, dotted, or none")
  end
  return style
end

local SPAN_OPTIONS = { color = true, alpha = true, label = true }

function Figure:axhspan(y1, y2, opts)
  if type(y1) ~= "number" or type(y2) ~= "number" then
    fail("axhspan bounds must be numbers")
  end
  if y1 > y2 then y1, y2 = y2, y1 end
  opts = util.check_options(opts, SPAN_OPTIONS, "axhspan")
  self._series[#self._series + 1] = {
    kind = "axhspan", y1 = y1, y2 = y2,
    style = {
      color = util.check_color(opts.color or "#cccccc", "axhspan color"),
      alpha = opts.alpha and util.check_alpha(opts.alpha, "axhspan alpha") or 0.3,
      label = opts.label,
    },
  }
  return self
end

function Figure:axvspan(x1, x2, opts)
  if type(x1) ~= "number" or type(x2) ~= "number" then
    fail("axvspan bounds must be numbers")
  end
  if x1 > x2 then x1, x2 = x2, x1 end
  opts = util.check_options(opts, SPAN_OPTIONS, "axvspan")
  self._series[#self._series + 1] = {
    kind = "axvspan", x1 = x1, x2 = x2,
    style = {
      color = util.check_color(opts.color or "#cccccc", "axvspan color"),
      alpha = opts.alpha and util.check_alpha(opts.alpha, "axvspan alpha") or 0.3,
      label = opts.label,
    },
  }
  return self
end

function Figure:loglog(x, y, opts)
  self:xscale("log"); self:yscale("log"); self:plot(x, y, opts); return self
end

function Figure:semilogx(x, y, opts)
  self:xscale("log"); self:yscale("linear"); self:plot(x, y, opts); return self
end

function Figure:semilogy(x, y, opts)
  self:xscale("linear"); self:yscale("log"); self:plot(x, y, opts); return self
end

function Figure:axhline(y, opts)
  if type(y) ~= "number" or y ~= y or y == math.huge or y == -math.huge then
    fail("axhline y must be a finite number")
  end
  local style = reference_style(self, opts, "axhline")
  self._series[#self._series + 1] = { kind = "axhline", y = y, style = style }
  return self
end

function Figure:axvline(x, opts)
  if type(x) ~= "number" or x ~= x or x == math.huge or x == -math.huge then
    fail("axvline x must be a finite number")
  end
  local style = reference_style(self, opts, "axvline")
  self._series[#self._series + 1] = { kind = "axvline", x = x, style = style }
  return self
end

function Figure:grid(enabled, opts)
  if type(enabled) == "table" and opts == nil then
    opts, enabled = enabled, true
  end
  if enabled == nil then enabled = true end
  util.check_boolean(enabled, "grid")
  if opts ~= nil then
    opts = util.check_options(opts, { color = true, linewidth = true,
      linestyle = true, axis = true }, "grid")
    if opts.axis ~= nil then
      if opts.axis ~= "x" and opts.axis ~= "y" and opts.axis ~= "both" then
        fail("grid axis must be x, y, or both")
      end
      self._grid_opts.axis = opts.axis
    end
    if opts.color ~= nil then
      self._grid_opts.color = util.check_color(opts.color, "grid color")
    end
    if opts.linewidth ~= nil then
      self._grid_opts.linewidth = util.check_number(opts.linewidth,
        "grid linewidth", 0)
    end
    if opts.linestyle ~= nil then
      if opts.linestyle ~= "solid" and opts.linestyle ~= "dashed" and
          opts.linestyle ~= "dotted" then
        fail("grid linestyle must be solid, dashed, or dotted")
      end
      self._grid_opts.linestyle = opts.linestyle
    end
  end
  self._grid = enabled
  return self
end

function Figure:facecolor(color)
  self._facecolor = util.check_color(color, "facecolor")
  return self
end

function Figure:aria_label(text)
  if text ~= nil then util.check_string(text, "aria_label", false) end
  self._aria_label = text
  return self
end

function Figure:legend(opts)
  if opts ~= nil then
    opts = util.check_options(opts, {
      loc = true,
      frame = true,
      ncol = true,
      title = true,
    }, "legend")
    if opts.loc ~= nil then
      util.check_string(opts.loc, "legend loc")
      if not LEGEND_LOCATIONS[opts.loc] then
        fail("legend loc must be one of 'upper right', 'upper left', 'lower right', or 'lower left'")
      end
    end
    if opts.frame ~= nil then
      util.check_boolean(opts.frame, "legend frame")
    end
    local ncol = self._legend_opts.ncol or 1
    if opts.ncol ~= nil then
      ncol = util.check_integer(opts.ncol, "legend ncol", 1, 6)
    end
    if opts.title ~= nil then
      util.check_string(opts.title, "legend title", true)
    end
    self._legend_opts = {
      loc = opts.loc or self._legend_opts.loc,
      frame = opts.frame == nil and self._legend_opts.frame or opts.frame,
      ncol = ncol,
      title = opts.title == nil and self._legend_opts.title or opts.title,
    }
  end
  self._legend_requested = true
  return self
end

function Figure:to_scene()
  return require("luaplotlib.scene").from_figure(self)
end

function Figure:to_svg()
  -- Required lazily so that the renderer can evolve without a require cycle.
  if self._polar ~= nil then
    return require("luaplotlib.polar").to_svg(self)
  end
  local render = require("luaplotlib.render")
  return render.to_svg(self)
end

function Figure:to_html(title)
  local svg = self:to_svg()
  local heading = title and util.escape_xml(tostring(title)) or "luaplotlib figure"
  return table.concat({
    "<!doctype html>",
    '<html lang="en"><head><meta charset="utf-8">',
    "<title>" .. heading .. "</title>",
    "<style>body{margin:0;padding:24px;background:#f5f5f5;font-family:Helvetica,Arial,sans-serif}figure{margin:0 auto;background:#fff;padding:12px;max-width:100%;box-shadow:0 1px 4px #0002}svg{max-width:100%;height:auto}</style>",
    "</head><body><figure>",
    svg,
    "</figure></body></html>",
  }, "\n") .. "\n"
end

function Figure:save_html(path, title)
  util.check_string(path, "save_html path", false)
  local contents = self:to_html(title)
  local handle, err = io.open(path, "wb")
  if handle == nil then
    fail("could not open " .. string.format("%q", path) .. ": " .. tostring(err))
  end
  local wrote, write_error = handle:write(contents)
  local closed, close_error = handle:close()
  if not wrote then fail("could not write HTML: " .. tostring(write_error)) end
  if not closed then fail("could not close HTML: " .. tostring(close_error)) end
  return path
end

function Figure:save_png(path)
  util.check_string(path, "save_png path", false)
  return require("luaplotlib.export").png(self:to_svg(), path)
end

function Figure:save_pdf(path)
  util.check_string(path, "save_pdf path", false)
  return require("luaplotlib.export").pdf(self:to_svg(), path)
end

function Figure:savefig(path)
  util.check_string(path, "savefig path", false)
  local lower = path:lower()
  if lower:sub(-4) == ".png" then return self:save_png(path) end
  if lower:sub(-4) == ".pdf" then return self:save_pdf(path) end
  if lower:sub(-4) ~= ".svg" then
    fail("savefig supports .svg, .png, and .pdf paths", 3)
  end
  local svg = self:to_svg()
  local handle, open_error = io.open(path, "wb")
  if not handle then
    fail("could not open " .. string.format("%q", path) .. " for writing: " ..
      tostring(open_error))
  end
  local wrote, write_error = handle:write(svg)
  if not wrote then
    handle:close()
    fail("could not write " .. string.format("%q", path) .. ": " ..
      tostring(write_error))
  end
  local closed, close_error = handle:close()
  if not closed then
    fail("could not close " .. string.format("%q", path) .. ": " ..
      tostring(close_error))
  end
  return path
end

return Figure
