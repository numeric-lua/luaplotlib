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
  markevery = true,
  markerfacecolor = true,
  markeredgecolor = true,
  markeredgewidth = true,
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
  degrees = true,
  theta_unit = true,
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
  degrees = true,
  theta_unit = true,
}

local POLAR_BAR_OPTIONS = {
  color = true,
  colors = true,
  label = true,
  width = true,
  alpha = true,
  edgecolor = true,
  degrees = true,
  theta_unit = true,
}

local POLAR_ANNOTATE_OPTIONS = {
  xytext = true,
  color = true,
  fontsize = true,
  align = true,
  arrow = true,
  backgroundcolor = true,
  backgroundedgecolor = true,
  backgroundalpha = true,
  backgroundpad = true,
  rotation = true,
  degrees = true,
  theta_unit = true,
}

local POLAR_ERRORBAR_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  linestyle = true,
  marker = true,
  markersize = true,
  markerfacecolor = true,
  markeredgecolor = true,
  markeredgewidth = true,
  alpha = true,
  capsize = true,
  elinewidth = true,
  ecolor = true,
  thetaerr = true,
  degrees = true,
  theta_unit = true,
}

local POLAR_QUIVER_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  alpha = true,
  head = true,
  headwidth = true,
  scale = true,
  pivot = true,
  max_arrows = true,
  normalize = true,
  degrees = true,
  theta_unit = true,
}

local POLAR_STREAMPLOT_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  linestyle = true,
  alpha = true,
  density = true,
  step = true,
  max_steps = true,
  max_lines = true,
  max_points = true,
  arrows = true,
  arrow_fraction = true,
  head = true,
  degrees = true,
  theta_unit = true,
}

local POLAR_HEATMAP_OPTIONS = {
  vmin = true,
  vmax = true,
  rmin = true,
  rmax = true,
  theta_min = true,
  theta_max = true,
  alpha = true,
  label = true,
  colorbar = true,
  colorbar_label = true,
  colorbar_ticks = true,
  colorbar_tick_values = true,
  degrees = true,
  theta_unit = true,
}

local POLAR_CONTOUR_OPTIONS = {
  vmin = true,
  vmax = true,
  levels = true,
  color = true,
  linewidth = true,
  linestyle = true,
  alpha = true,
  label = true,
  labels = true,
  rmin = true,
  rmax = true,
  theta_min = true,
  theta_max = true,
  degrees = true,
  theta_unit = true,
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
  c = true,
  vmin = true,
  vmax = true,
  colorbar = true,
  colorbar_label = true,
  colorbar_ticks = true,
  colorbar_tick_values = true,
}

local HIST_OPTIONS = {
  bins = true,
  color = true,
  label = true,
  alpha = true,
  edgecolor = true,
  edgecolors = true,
  range = true,
  density = true,
  cumulative = true,
  orientation = true,
  histtype = true,
  linewidth = true,
  hatch = true,
}

local HIST2D_OPTIONS = {
  bins = true,
  range = true,
  density = true,
  vmin = true,
  vmax = true,
  color_norm = true,
  colorbar = true,
  colorbar_label = true,
  colorbar_ticks = true,
  colorbar_tick_values = true,
  alpha = true,
  edgecolor = true,
  linewidth = true,
  show_empty = true,
  label = true,
}

local BAR_OPTIONS = {
  color = true,
  label = true,
  labels = true,
  series_labels = true,
  colors = true,
  width = true,
  linewidth = true,
  alpha = true,
  edgecolor = true,
  edgecolors = true,
  stacked = true,
  grouped = true,
  bar_colors = true,
  show_values = true,
  hatch = true,
  yerr = true,
  ecolor = true,
  elinewidth = true,
  capsize = true,
}

local FILL_OPTIONS = {
  color = true,
  label = true,
  alpha = true,
  edgecolor = true,
  hatch = true,
  where = true,
  interpolate = true,
}

local STEP_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  linestyle = true,
  where = true,
  alpha = true,
  fill = true,
  fillalpha = true,
}

local ECDF_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  linestyle = true,
  where = true,
  alpha = true,
  complementary = true,
}

local STEM_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  linestyle = true,
  marker = true,
  markersize = true,
  markerfacecolor = true,
  markeredgecolor = true,
  markeredgewidth = true,
  base = true,
  orientation = true,
  alpha = true,
}

local STACK_OPTIONS = {
  labels = true,
  colors = true,
  alpha = true,
  edgecolor = true,
  baseline = true,
}

local VIOLIN_OPTIONS = {
  positions = true,
  width = true,
  points = true,
  bandwidth = true,
  showextrema = true,
  showmedians = true,
  showquartiles = true,
  showmeans = true,
  meanline = true,
  orientation = true,
  colors = true,
  color = true,
  labels = true,
  label = true,
  alpha = true,
  edgecolor = true,
  linewidth = true,
}

local PIE_OPTIONS = {
  labels = true,
  colors = true,
  color = true,
  startangle = true,
  counterclock = true,
  autopct = true,
  radius = true,
  inner_radius = true,
  explode = true,
  shadow = true,
  edgecolor = true,
  linewidth = true,
  labelsize = true,
  labelcolor = true,
  pctsize = true,
  pctcolor = true,
  labeldistance = true,
  pctdistance = true,
  rotatelabels = true,
  legend = true,
}

local BARH_OPTIONS = {
  color = true,
  label = true,
  labels = true,
  height = true,
  linewidth = true,
  hatch = true,
  alpha = true,
  edgecolor = true,
  edgecolors = true,
  bar_colors = true,
  show_values = true,
}

local BROKEN_BARH_OPTIONS = {
  color = true,
  label = true,
  alpha = true,
  edgecolor = true,
  linewidth = true,
}

local IMAGE_OPTIONS = {
  vmin = true,
  vmax = true,
  colorbar = true,
  colorbar_label = true,
  colorbar_ticks = true,
  colorbar_tick_values = true,
  alpha = true,
  label = true,
  extent = true,
  origin = true,
}

local CONTOUR_OPTIONS = {
  levels = true,
  color = true,
  linewidth = true,
  label = true,
  labels = true,
  linestyle = true,
  x = true,
  y = true,
}

local HEXBIN_OPTIONS = {
  gridsize = true,
  mincnt = true,
  vmin = true,
  vmax = true,
  norm = true,
  colorbar = true,
  colorbar_label = true,
  colorbar_ticks = true,
  colorbar_tick_values = true,
  alpha = true,
  edgecolor = true,
  linewidth = true,
  label = true,
}

local QUIVER_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  alpha = true,
  head = true,
  headwidth = true,
  scale = true,
  pivot = true,
  max_arrows = true,
  normalize = true,
  angles = true,
}


local BOX_OPTIONS = {
  color = true,
  label = true,
  labels = true,
  width = true,
  orientation = true,
  showmeans = true,
  meanline = true,
  notch = true,
  whis = true,
  showfliers = true,
  showbox = true,
  showwhiskers = true,
  showcaps = true,
  colors = true,
  alpha = true,
}

local ERRORBAR_OPTIONS = {
  color = true,
  label = true,
  linewidth = true,
  linestyle = true,
  marker = true,
  markersize = true,
  markerfacecolor = true,
  markeredgecolor = true,
  markeredgewidth = true,
  alpha = true,
  capsize = true,
  elinewidth = true,
  ecolor = true,
  errorevery = true,
  lolims = true,
  uplims = true,
  xlolims = true,
  xuplims = true,
}

local ANNOTATE_OPTIONS = {
  xytext = true,
  color = true,
  fontsize = true,
  align = true,
  arrow = true,
  backgroundcolor = true,
  backgroundedgecolor = true,
  backgroundalpha = true,
  backgroundpad = true,
  rotation = true,
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

local HATCH_TYPES = {
  ["/"] = true,
  ["\\"] = true,
  ["|"] = true,
  ["-"] = true,
  ["+"] = true,
  x = true,
  ["."] = true,
  o = true,
}

local QUIVER_PIVOTS = {
  tail = true,
  middle = true,
  tip = true,
}

local LEGEND_LOCATIONS = {
  ["upper right"] = true,
  ["upper left"] = true,
  ["lower right"] = true,
  ["lower left"] = true,
  ["upper center"] = true,
  ["lower center"] = true,
  ["center left"] = true,
  ["center right"] = true,
  ["center"] = true,
  ["best"] = true,
}

local TITLE_LOCATIONS = {
  left = true,
  center = true,
  right = true,
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

-- Normalize one marker (string/true/false) or one marker per data point.
local function checked_markers(value, count, context)
  if type(value) ~= "table" then
    return nil, checked_marker(value, context) or "circle"
  end
  if #value ~= count then
    fail(context .. " marker array must match the number of points")
  end
  local markers = {}
  for index = 1, count do
    local marker = checked_marker(value[index], context)
    if marker == nil then
      fail(string.format("%s marker[%d] must be a marker name or true",
        context, index))
    end
    markers[index] = marker
  end
  return markers, markers[1] or "circle"
end

local function checked_marker_style(opts, context, style)
  if opts.markerfacecolor ~= nil then
    style.markerfacecolor = util.check_color(opts.markerfacecolor,
      context .. " markerfacecolor")
  end
  if opts.markeredgecolor ~= nil then
    style.markeredgecolor = util.check_color(opts.markeredgecolor,
      context .. " markeredgecolor")
  end
  if opts.markeredgewidth ~= nil then
    style.markeredgewidth = util.check_number(opts.markeredgewidth,
      context .. " markeredgewidth", 0)
  end
  return style
end

-- Normalize markevery into a sorted list of one-based point indices. An integer
-- is a stride starting at the first point; a table is an explicit index list.
local function checked_markevery(value, count, context)
  if value == nil then
    return nil
  end
  local indices = {}
  if type(value) == "number" then
    local stride = util.check_integer(value, context .. " markevery", 1)
    for index = 1, count, stride do
      indices[#indices + 1] = index
    end
  elseif type(value) == "table" then
    if #value == 0 then
      fail(context .. " markevery index table must not be empty")
    end
    local seen = {}
    for position = 1, #value do
      local index = util.check_integer(value[position],
        string.format("%s markevery[%d]", context, position), 1, count)
      if not seen[index] then
        seen[index] = true
        indices[#indices + 1] = index
      end
    end
    table.sort(indices)
  else
    fail(context .. " markevery must be a positive integer or an index table")
  end
  return indices
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

-- Normalize an optional annotation background box.  Supplying
-- `backgroundcolor` enables the box; the edge, alpha, and padding are optional.
local function checked_annotation_rotation(opts, context)
  local rotation = 0
  if opts.rotation ~= nil then
    rotation = util.check_number(opts.rotation, context .. " rotation",
      -180, 180)
  end
  return rotation
end

local function checked_annotation_background(opts, context)
  if opts.backgroundcolor == nil then
    if opts.backgroundedgecolor ~= nil or opts.backgroundalpha ~= nil or
        opts.backgroundpad ~= nil then
      fail(context .. " background options require backgroundcolor")
    end
    return nil
  end
  local color = util.check_color(opts.backgroundcolor,
    context .. " backgroundcolor")
  local edgecolor = nil
  if opts.backgroundedgecolor ~= nil then
    edgecolor = util.check_color(opts.backgroundedgecolor,
      context .. " backgroundedgecolor")
  end
  local alpha = 1
  if opts.backgroundalpha ~= nil then
    alpha = util.check_alpha(opts.backgroundalpha,
      context .. " backgroundalpha")
  end
  local pad = 3
  if opts.backgroundpad ~= nil then
    pad = util.check_number(opts.backgroundpad,
      context .. " backgroundpad", 0)
  end
  return { color = color, edgecolor = edgecolor, alpha = alpha, pad = pad }
end

local function checked_limit_flags(value, count, name)
  if value == nil then return nil end
  local flags = {}
  if type(value) == "boolean" then
    for index = 1, count do flags[index] = value end
    return flags
  end
  if type(value) ~= "table" or #value ~= count then
    fail(name .. " must be a boolean or one boolean per point")
  end
  for index = 1, count do
    util.check_boolean(value[index], name .. "[" .. index .. "]")
    flags[index] = value[index]
  end
  return flags
end

-- Normalize symmetric or asymmetric error input into one lower and one upper
-- value per point. Symmetric input is a non-negative number or a flat numeric
-- sequence. Asymmetric input is either { lower = ..., upper = ... } or a
-- two-element { lower_sequence, upper_sequence }; each side may be a scalar or
-- a sequence.
local function error_components(value, count, name)
  if value == nil then
    fail(name .. " is required")
  end

  local lower_raw, upper_raw
  local asymmetric = false
  if type(value) == "number" then
    lower_raw, upper_raw = value, value
  elseif type(value) == "table" then
    local has_named = value.lower ~= nil or value.upper ~= nil
    local has_pair = type(value[1]) == "table" or type(value[2]) == "table"
    if has_named and has_pair then
      fail(name .. " must use either lower/upper fields or two sequences, not both")
    end
    if has_named then
      if value.lower == nil or value.upper == nil then
        fail(name .. " asymmetric table requires both lower and upper")
      end
      lower_raw, upper_raw = value.lower, value.upper
      asymmetric = true
    elseif has_pair then
      if #value ~= 2 then
        fail(name .. " asymmetric table must contain exactly two sequences")
      end
      lower_raw, upper_raw = value[1], value[2]
      asymmetric = true
    else
      lower_raw, upper_raw = value, value
    end
  else
    fail(name .. " must be a number, a numeric sequence, or an asymmetric table")
  end

  local function side(raw, side_name)
    local result
    if type(raw) == "number" then
      result = {}
      for index = 1, count do result[index] = raw end
    else
      result = data.sequence(raw, side_name)
    end
    if #result ~= count then
      fail(string.format("%s must have the same length as x and y (%d ~= %d)",
        side_name, #result, count))
    end
    for index, error in ipairs(result) do
      if error < 0 then
        fail(string.format("%s[%d] must be non-negative", side_name, index))
      end
    end
    return result
  end

  local lower = side(lower_raw, name .. " lower")
  local upper = side(upper_raw, name .. " upper")
  return lower, upper, asymmetric
end

-- Shared validation for heat-style colorbars (imshow-like series).  A colorbar
-- is enabled by default when the caller maps a scalar value to the heat
-- palette.  Explicit tick values and a tick count are mutually exclusive.
local function checked_colorbar_options(opts, context, default_enabled)
  local colorbar = opts.colorbar
  if colorbar == nil then colorbar = default_enabled end
  util.check_boolean(colorbar, context .. " colorbar")

  local label = opts.colorbar_label
  if label ~= nil then
    util.check_string(label, context .. " colorbar_label", true)
  end

  local ticks = nil
  if opts.colorbar_ticks ~= nil then
    ticks = util.check_integer(opts.colorbar_ticks,
      context .. " colorbar_ticks", 2, 10)
  end

  local tick_values = nil
  if opts.colorbar_tick_values ~= nil then
    if ticks ~= nil then
      fail(context .. " colorbar_ticks and colorbar_tick_values cannot both be set")
    end
    if type(opts.colorbar_tick_values) ~= "table" or
        #opts.colorbar_tick_values == 0 then
      fail(context .. " colorbar_tick_values must be a non-empty table")
    end
    tick_values = {}
    for index = 1, #opts.colorbar_tick_values do
      tick_values[index] = util.check_number(
        opts.colorbar_tick_values[index],
        context .. " colorbar_tick_values[" .. index .. "]")
    end
  end
  return colorbar, label, ticks, tick_values
end

-- Resolve automatic or explicit vmin/vmax for a scalar value range.  A
-- degenerate range is padded so the palette still spans a visible interval.
local function checked_value_range(opts, minimum, maximum, context)
  if opts.vmin ~= nil then
    minimum = util.check_number(opts.vmin, context .. " vmin")
  end
  if opts.vmax ~= nil then
    maximum = util.check_number(opts.vmax, context .. " vmax")
  end
  if minimum == nil then minimum = 0 end
  if maximum == nil then maximum = minimum + 1 end
  if maximum <= minimum then
    if opts.vmin ~= nil or opts.vmax ~= nil then
      fail(context .. " vmax must be greater than vmin")
    elseif minimum == maximum then
      minimum, maximum = minimum - 0.5, maximum + 0.5
    else
      fail(context .. " vmax must be greater than vmin")
    end
  end
  return minimum, maximum
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
    _title_loc = "center",
    _title_fontsize = 18,
    _title_color = "#222222",
    _twin = nil,
    _twiny = nil,
    _xlabel = nil,
    _ylabel = nil,
    _xlabel_pad = 0,
    _ylabel_pad = 0,
    _xlabel_fontsize = 13,
    _ylabel_fontsize = 13,
    _xlabel_color = "#222222",
    _ylabel_color = "#222222",
    _xlim = nil,
    _ylim = nil,
    _xscale = checked_scale(opts.xscale, "figure xscale", true),
    _yscale = checked_scale(opts.yscale, "figure yscale", true),
    _grid = false,
    _grid_opts = {
      color = "#d9d9d9", linewidth = 1, linestyle = "solid", alpha = 1,
      minor = false,
    },
    _minorticks = { enabled = false, axis = "both", subdivisions = 5 },
    _facecolor = "#ffffff",
    _aria_label = nil,
    _legend_requested = false,
    _legend_opts = {
      loc = "upper right", frame = true, framealpha = 0.92,
      facecolor = "#ffffff", edgecolor = "#bbbbbb",
      borderpad = 8, handlelength = 20, fontsize = 11,
    },
    _category_ticks = nil,
    _category_axis = "x",
    _colorbar = false,
    _aspect = nil,
    _xtick_rotation = 0,
    _ytick_rotation = 0,
    _ticklabelsize = 11,
    _ticklabelcolor = "#222222",
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
  style.markevery = checked_markevery(opts.markevery, #xv, "plot")
  checked_marker_style(opts, "plot", style)

  self._series[#self._series + 1] = {
    kind = "line",
    x = xv,
    y = yv,
    style = style,
  }
  return self
end

-- Draw a Cartesian vector field.  `u` and `v` are the vector components in
-- data coordinates; directions and lengths are projected through the current
-- x/y transforms so the glyphs remain legible on linear and log axes.  Large
-- fields are decimated deterministically with `max_arrows`.
function Figure:quiver(x, y, u, v, opts)
  opts = util.check_options(opts, QUIVER_OPTIONS, "quiver")
  local xv = data.sequence(x, "quiver x")
  local yv = data.sequence(y, "quiver y")
  local uv = data.sequence(u, "quiver u")
  local vv = data.sequence(v, "quiver v")
  local count = #xv
  if #yv ~= count or #uv ~= count or #vv ~= count then
    fail(string.format(
      "quiver x, y, u, and v must have the same length (%d, %d, %d, %d)",
      count, #yv, #uv, #vv))
  end

  local point_linewidths
  local linewidth = 1.2
  if type(opts.linewidth) == "table" then
    if #opts.linewidth ~= count then
      fail("quiver linewidth array must match the number of vectors")
    end
    point_linewidths = {}
    for index = 1, count do
      point_linewidths[index] = util.check_number(opts.linewidth[index],
        "quiver linewidth[" .. index .. "]", 0)
    end
    linewidth = point_linewidths[1]
  elseif opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "quiver linewidth", 0)
  end
  local head = 6
  if opts.head ~= nil then
    head = util.check_number(opts.head, "quiver head", 0)
  end
  local headwidth = 0.9
  if opts.headwidth ~= nil then
    headwidth = util.check_number(opts.headwidth, "quiver headwidth", 0)
  end
  local scale = nil
  if opts.scale ~= nil then
    scale = util.check_number(opts.scale, "quiver scale", 0)
    if scale <= 0 then
      fail("quiver scale must be positive")
    end
  end
  local pivot = opts.pivot or "tail"
  if type(pivot) ~= "string" or not QUIVER_PIVOTS[pivot] then
    fail("quiver pivot must be 'tail', 'middle', or 'tip'")
  end
  local max_arrows = 512
  if opts.max_arrows ~= nil then
    max_arrows = util.check_integer(opts.max_arrows,
      "quiver max_arrows", 1, 4096)
  end
  local normalize = false
  if opts.normalize ~= nil then
    normalize = util.check_boolean(opts.normalize, "quiver normalize")
  end
  local angles = opts.angles or "xy"
  if angles ~= "xy" and angles ~= "uv" then
    fail("quiver angles must be 'xy' or 'uv'")
  end

  local style_opts = opts
  local point_colors
  if type(opts.color) == "table" then
    if #opts.color ~= count then
      fail("quiver color array must match the number of vectors")
    end
    point_colors = {}
    for index = 1, count do
      point_colors[index] = util.check_color(opts.color[index],
        "quiver color[" .. index .. "]")
    end
    style_opts = {}
    for key, value in pairs(opts) do style_opts[key] = value end
    style_opts.color = point_colors[1]
  end
  local style = checked_style(self, style_opts, "quiver")
  style.linewidth = linewidth
  style.linewidths = point_linewidths
  style.head = head
  style.headwidth = headwidth
  style.colors = point_colors

  self._series[#self._series + 1] = {
    kind = "quiver",
    x = xv,
    y = yv,
    u = uv,
    v = vv,
    scale = scale,
    pivot = pivot,
    max_arrows = max_arrows,
    normalize = normalize,
    angles = angles,
    style = style,
  }
  return self
end

-- Resolve the theta unit shared by every polar series and annotation method.
local function checked_theta_unit(opts, name)
  local unit = opts.theta_unit
  if unit ~= nil then
    if unit ~= "radians" and unit ~= "degrees" then
      fail(name .. " unit must be 'radians' or 'degrees'")
    end
    if opts.degrees ~= nil then
      fail(name .. " degrees and theta_unit cannot both be set")
    end
  elseif opts.degrees ~= nil then
    util.check_boolean(opts.degrees, name .. " degrees")
    unit = opts.degrees and "degrees" or "radians"
  else
    unit = "radians"
  end
  return unit
end

local function checked_theta_values(value, opts, name)
  local values = data.sequence(value, name)
  if checked_theta_unit(opts, name) == "degrees" then
    for index = 1, #values do
      values[index] = values[index] * math.pi / 180
    end
  end
  return values
end

-- Scalar theta values are accepted by annotations, which mark one point
-- rather than a whole series.
local function checked_theta_scalar(value, opts, name)
  local number = util.check_number(value, name)
  if checked_theta_unit(opts, name) == "degrees" then
    number = number * math.pi / 180
  end
  return number
end

-- Resolve the rectangular (theta, r) domain shared by polar field plots
-- (heatmaps and contours).  Angles are returned in radians; `name` prefixes
-- validation errors so callers keep their own wording.
local function checked_field_extent(opts, name)
  local rmin = 0
  if opts.rmin ~= nil then
    rmin = util.check_number(opts.rmin, name .. " rmin", 0)
  end
  local rmax = nil
  if opts.rmax ~= nil then
    rmax = util.check_number(opts.rmax, name .. " rmax", 0)
    if rmax <= rmin then
      fail(name .. " rmax must be greater than rmin")
    end
  end

  local unit = checked_theta_unit(opts, name)
  local theta_min, theta_max
  if unit == "degrees" then
    theta_min = opts.theta_min == nil and 0 or
      util.check_number(opts.theta_min, name .. " theta_min")
    theta_max = opts.theta_max == nil and 360 or
      util.check_number(opts.theta_max, name .. " theta_max")
    theta_min = theta_min * math.pi / 180
    theta_max = theta_max * math.pi / 180
  else
    theta_min = opts.theta_min == nil and 0 or
      util.check_number(opts.theta_min, name .. " theta_min")
    theta_max = opts.theta_max == nil and 2 * math.pi or
      util.check_number(opts.theta_max, name .. " theta_max")
  end
  if theta_max <= theta_min then
    fail(name .. " theta_max must be greater than theta_min")
  end
  if theta_max - theta_min > 2 * math.pi + 1e-9 then
    fail(name .. " theta span must be at most 2*pi radians")
  end
  return rmin, rmax, theta_min, theta_max
end

local function ensure_polar_state(self)
  if self._pie ~= nil then
    fail("cannot combine pie and polar plots in one figure")
  end
  if #self._series > 0 then
    fail("cannot mix cartesian and polar series in one figure; create a separate figure")
  end
  if #self._annotations > 0 then
    fail("cannot mix cartesian annotations and polar series in one figure; create a separate figure")
  end
  return polar.ensure(self)
end

-- Add a polar line series.  Theta values are radians and r values share the
-- same length.  A figure is either Cartesian or polar; mixing the two is
-- rejected so that a typo cannot silently produce an empty plot.
function Figure:polar(theta, r, opts)
  opts = util.check_options(opts, POLAR_LINE_OPTIONS, "polar")
  local tv = checked_theta_values(theta, opts, "polar theta")
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
  local tv = checked_theta_values(theta, opts, "polar scatter theta")
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

  local point_linewidths
  local linewidth = 1
  if type(opts.linewidth) == "table" then
    if #opts.linewidth ~= #tv then
      fail("polar scatter linewidth array must match the number of points")
    end
    point_linewidths = {}
    for index = 1, #opts.linewidth do
      point_linewidths[index] = util.check_number(opts.linewidth[index],
        "polar scatter linewidth[" .. index .. "]", 0)
    end
    linewidth = point_linewidths[1] or 1
  elseif opts.linewidth ~= nil then
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

  local point_edgecolors
  if type(opts.edgecolor) == "table" then
    if #opts.edgecolor ~= #tv then
      fail("polar scatter edgecolor array must match the number of points")
    end
    point_edgecolors = {}
    for index = 1, #opts.edgecolor do
      point_edgecolors[index] = util.check_color(opts.edgecolor[index],
        "polar scatter edgecolor[" .. index .. "]")
    end
    if style_opts == opts then
      style_opts = {}
      for key, value in pairs(opts) do style_opts[key] = value end
    end
    style_opts.edgecolor = point_edgecolors[1]
  end
  local point_alphas
  if type(opts.alpha) == "table" then
    if #opts.alpha ~= #tv then
      fail("polar scatter alpha array must match the number of points")
    end
    point_alphas = {}
    for index = 1, #opts.alpha do
      point_alphas[index] = util.check_alpha(opts.alpha[index],
        "polar scatter alpha[" .. index .. "]")
    end
    if style_opts == opts then
      style_opts = {}
      for key, value in pairs(opts) do style_opts[key] = value end
    end
    style_opts.alpha = 1
  end
  local style = checked_style(self, style_opts, "polar scatter")
  local marker_list, marker = checked_markers(opts.marker, #tv,
    "polar scatter")
  style.marker = marker
  style.markers = marker_list
  style.radius = radius
  style.radii = radii
  style.colors = point_colors
  style.edgecolors = point_edgecolors
  style.alphas = point_alphas
  style.linewidth = linewidth
  style.linewidths = point_linewidths

  local state = ensure_polar_state(self)
  state.series[#state.series + 1] = {
    kind = "scatter",
    theta = tv,
    r = rv,
    style = style,
  }
  return self
end

-- Add polar bars.  Each bar is a wedge spanning `width` radians (0.8 by
-- default) from its theta position; widths may also be a per-bar array.
function Figure:polar_bar(theta, r, opts)
  opts = util.check_options(opts, POLAR_BAR_OPTIONS, "polar bar")
  local tv = checked_theta_values(theta, opts, "polar bar theta")
  local rv = data.sequence(r, "polar bar r")
  if #tv ~= #rv then
    fail(string.format(
      "polar bar theta and r must have the same length (%d ~= %d)",
      #tv, #rv))
  end
  for index = 1, #rv do
    if rv[index] < 0 then
      fail("polar bar r values must be non-negative")
    end
  end

  local function checked_width(value)
    local width = util.check_number(value, "polar bar width")
    if width <= 0 then
      fail("polar bar width must be positive")
    end
    if width > 2 * math.pi + 1e-12 then
      fail("polar bar width must be at most 2*pi radians")
    end
    return width
  end

  local widths = {}
  if opts.width == nil then
    for index = 1, #tv do widths[index] = 0.8 end
  elseif type(opts.width) == "table" then
    if #opts.width ~= #tv then
      fail("polar bar width array must match the number of bars")
    end
    for index = 1, #tv do
      widths[index] = checked_width(opts.width[index])
    end
  else
    local width = checked_width(opts.width)
    for index = 1, #tv do widths[index] = width end
  end

  local bar_colors
  if opts.colors ~= nil then
    if type(opts.colors) ~= "table" or #opts.colors ~= #tv then
      fail("polar bar colors must have one entry per bar")
    end
    if opts.color ~= nil then
      fail("polar bar color and colors cannot both be set")
    end
    bar_colors = {}
    for index = 1, #tv do
      bar_colors[index] = util.check_color(opts.colors[index],
        "polar bar colors[" .. index .. "]")
    end
  end

  local style_opts = opts
  if bar_colors ~= nil then
    style_opts = {}
    for key, value in pairs(opts) do style_opts[key] = value end
    style_opts.color = bar_colors[1]
  end
  local style = checked_style(self, style_opts, "polar bar")

  local state = ensure_polar_state(self)
  state.series[#state.series + 1] = {
    kind = "bar",
    theta = tv,
    r = rv,
    widths = widths,
    colors = bar_colors,
    style = style,
  }
  return self
end

-- Add radial and/or angular error bars to polar points.  `rerr` is a scalar or
-- one non-negative radial error per point.  Angular errors use the `thetaerr`
-- option, with the same scalar-or-array rules; they are interpreted in the
-- same unit as `theta`.
function Figure:polar_errorbar(theta, r, rerr, opts)
  opts = util.check_options(opts, POLAR_ERRORBAR_OPTIONS, "polar errorbar")
  local tv = checked_theta_values(theta, opts, "polar errorbar theta")
  local rv = data.sequence(r, "polar errorbar r")
  if #tv ~= #rv then
    fail(string.format(
      "polar errorbar theta and r must have the same length (%d ~= %d)",
      #tv, #rv))
  end
  if rerr == nil then
    fail("polar errorbar requires rerr")
  end

  local angular_unit = checked_theta_unit(opts, "polar errorbar")
  local function errors(value, name, angular)
    local result
    if type(value) == "number" then
      util.check_number(value, name)
      result = {}
      for index = 1, #tv do result[index] = value end
    else
      result = data.sequence(value, name)
    end
    if #result ~= #tv then
      fail(string.format("%s must have one entry per point (%d ~= %d)",
        name, #result, #tv))
    end
    for index = 1, #result do
      local error = util.check_number(result[index],
        name .. "[" .. index .. "]")
      if error < 0 then
        fail(name .. "[" .. index .. "] must be non-negative")
      end
      if angular then
        if angular_unit == "degrees" then
          error = error * math.pi / 180
        end
        if error > 2 * math.pi + 1e-12 then
          fail(name .. " must be at most 2*pi radians")
        end
      end
      result[index] = error
    end
    return result
  end

  local radial = errors(rerr, "polar errorbar rerr", false)
  local angular
  if opts.thetaerr ~= nil then
    angular = errors(opts.thetaerr, "polar errorbar thetaerr", true)
  end

  local linewidth = 1.5
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "polar errorbar linewidth", 0)
  end
  local linestyle = opts.linestyle or "solid"
  if type(linestyle) ~= "string" or not LINESTYLES[linestyle] then
    fail("polar errorbar linestyle must be one of solid, dashed, dotted, or none")
  end
  local marker = checked_marker(opts.marker == nil and "circle" or opts.marker,
    "polar errorbar")
  local markersize = 4
  if opts.markersize ~= nil then
    markersize = util.check_number(opts.markersize, "polar errorbar markersize", 0.1)
  end
  local capsize = 4
  if opts.capsize ~= nil then
    capsize = util.check_number(opts.capsize, "polar errorbar capsize", 0)
  end
  local elinewidth = 1
  if opts.elinewidth ~= nil then
    elinewidth = util.check_number(opts.elinewidth, "polar errorbar elinewidth", 0)
  end

  local style = checked_style(self, opts, "polar errorbar")
  style.linewidth = linewidth
  style.linestyle = linestyle
  style.marker = marker
  style.markersize = markersize
  checked_marker_style(opts, "errorbar", style)
  style.capsize = capsize
  style.elinewidth = elinewidth
  if opts.ecolor ~= nil then
    style.ecolor = util.check_color(opts.ecolor, "polar errorbar ecolor")
  else
    style.ecolor = style.color
  end

  local state = ensure_polar_state(self)
  state.series[#state.series + 1] = {
    kind = "errorbar",
    theta = tv,
    r = rv,
    rerr = radial,
    thetaerr = angular,
    style = style,
  }
  return self
end

-- Draw one arrow per (theta, r) position.  `u` is the component in the
-- direction of increasing data theta (counterclockwise by default) and `v` is
-- the radial component pointing outward; both keep their sign.  Arrow glyphs
-- are sized in SVG user units, so `scale` is user units per unit magnitude and
-- defaults to an automatic scale whose longest arrow is 18 units.  Large
-- fields are decimated deterministically to `max_arrows` glyphs.
function Figure:polar_quiver(theta, r, u, v, opts)
  opts = util.check_options(opts, POLAR_QUIVER_OPTIONS, "polar quiver")
  local tv = checked_theta_values(theta, opts, "polar quiver theta")
  local rv = data.sequence(r, "polar quiver r")
  local uv = data.sequence(u, "polar quiver u")
  local vv = data.sequence(v, "polar quiver v")
  local count = #tv
  if #rv ~= count or #uv ~= count or #vv ~= count then
    fail(string.format(
      "polar quiver theta, r, u, and v must have the same length " ..
      "(%d, %d, %d, %d)", count, #rv, #uv, #vv))
  end

  local linewidth = 1.2
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth,
      "polar quiver linewidth", 0)
  end
  local head = 5
  if opts.head ~= nil then
    head = util.check_number(opts.head, "polar quiver head", 0)
  end
  local scale = nil
  if opts.scale ~= nil then
    scale = util.check_number(opts.scale, "polar quiver scale")
    if scale <= 0 then
      fail("polar quiver scale must be positive")
    end
  end
  local pivot = opts.pivot or "tail"
  if type(pivot) ~= "string" or not QUIVER_PIVOTS[pivot] then
    fail("polar quiver pivot must be 'tail', 'middle', or 'tip'")
  end
  local max_arrows = 512
  if opts.max_arrows ~= nil then
    max_arrows = util.check_integer(opts.max_arrows,
      "polar quiver max_arrows", 1, 4096)
  end
  local normalize = false
  if opts.normalize ~= nil then
    normalize = util.check_boolean(opts.normalize,
      "polar quiver normalize")
  end

  local style = checked_style(self, opts, "polar quiver")
  style.linewidth = linewidth
  style.head = head

  local state = ensure_polar_state(self)
  state.series[#state.series + 1] = {
    kind = "quiver",
    theta = tv,
    r = rv,
    u = uv,
    v = vv,
    scale = scale,
    pivot = pivot,
    max_arrows = max_arrows,
    normalize = normalize,
    style = style,
  }
  return self
end

-- Draw streamlines of a polar vector field sampled on a regular grid.
-- `theta` and `r` are the strictly increasing grid coordinates and `u`/`v`
-- are rows-by-columns matrices of the local tangential/radial components
-- sampled at every grid node.  Long fields are integrated with a fixed
-- physical step, seeded deterministically, and capped by `max_lines` and
-- `max_points` so SVG output stays bounded.
function Figure:polar_streamplot(theta, r, u, v, opts)
  opts = util.check_options(opts, POLAR_STREAMPLOT_OPTIONS,
    "polar streamplot")
  local tv = checked_theta_values(theta, opts, "polar streamplot theta")
  local rv = data.sequence(r, "polar streamplot r")
  if #tv < 2 then
    fail("polar streamplot theta must have at least two grid values")
  end
  if #rv < 2 then
    fail("polar streamplot r must have at least two grid values")
  end
  if rv[1] < 0 then
    fail("polar streamplot r values must be non-negative")
  end
  for index = 2, #tv do
    if tv[index] <= tv[index - 1] then
      fail("polar streamplot theta grid must be strictly increasing")
    end
  end
  for index = 2, #rv do
    if rv[index] <= rv[index - 1] then
      fail("polar streamplot r grid must be strictly increasing")
    end
  end
  if tv[#tv] - tv[1] > 2 * math.pi + 1e-9 then
    fail("polar streamplot theta span must be at most 2*pi radians")
  end

  local rows, cols = #rv, #tv
  local urows, ucols, um = data.matrix(u, "polar streamplot u")
  local vrows, vcols, vm = data.matrix(v, "polar streamplot v")
  if urows ~= rows or ucols ~= cols or vrows ~= rows or vcols ~= cols then
    fail(string.format(
      "polar streamplot u and v must be %d-by-%d matrices matching r and " ..
      "theta (got %d-by-%d and %d-by-%d)",
      rows, cols, urows, ucols, vrows, vcols))
  end

  local linewidth = 1.5
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth,
      "polar streamplot linewidth", 0)
  end
  local head = 6
  if opts.head ~= nil then
    head = util.check_number(opts.head, "polar streamplot head", 0)
  end
  local density = 1
  if opts.density ~= nil then
    density = util.check_number(opts.density,
      "polar streamplot density", 0.1, 10)
  end
  local step = nil
  if opts.step ~= nil then
    step = util.check_number(opts.step, "polar streamplot step")
    if step <= 0 then
      fail("polar streamplot step must be positive")
    end
  end
  local max_steps = 300
  if opts.max_steps ~= nil then
    max_steps = util.check_integer(opts.max_steps,
      "polar streamplot max_steps", 10, 5000)
  end
  local max_lines = 64
  if opts.max_lines ~= nil then
    max_lines = util.check_integer(opts.max_lines,
      "polar streamplot max_lines", 1, 512)
  end
  local max_points = 8000
  if opts.max_points ~= nil then
    max_points = util.check_integer(opts.max_points,
      "polar streamplot max_points", 100, 200000)
  end
  local arrows = true
  if opts.arrows ~= nil then
    arrows = util.check_boolean(opts.arrows, "polar streamplot arrows")
  end
  local arrow_fraction = 0.5
  if opts.arrow_fraction ~= nil then
    arrow_fraction = util.check_number(opts.arrow_fraction,
      "polar streamplot arrow_fraction", 0.05, 0.95)
  end
  local linestyle = opts.linestyle or "solid"
  if type(linestyle) ~= "string" or not LINESTYLES[linestyle] then
    fail("polar streamplot linestyle must be one of solid, dashed, dotted, " ..
      "or none")
  end

  local style = checked_style(self, opts, "polar streamplot")
  style.linewidth = linewidth
  style.linestyle = linestyle
  style.head = head

  local state = ensure_polar_state(self)
  state.series[#state.series + 1] = {
    kind = "streamplot",
    theta = tv,
    r = rv,
    u = um,
    v = vm,
    density = density,
    step = step,
    max_steps = max_steps,
    max_lines = max_lines,
    max_points = max_points,
    arrows = arrows,
    arrow_fraction = arrow_fraction,
    style = style,
  }
  return self
end

-- Project a rectangular value matrix into an annular polar heatmap.  Rows
-- run from the inner radius to the outer radius and columns sweep from
-- theta_min to theta_max.  The matrix is rendered beneath line/scatter/bar
-- series, so callers can overlay contours or curves on the field.
function Figure:polar_heatmap(values, opts)
  opts = util.check_options(opts, POLAR_HEATMAP_OPTIONS, "polar heatmap")
  local rows, cols, matrix = data.matrix(values, "polar heatmap values")

  local minimum, maximum = math.huge, -math.huge
  for row = 1, rows do
    for col = 1, cols do
      local value = matrix[row][col]
      if value < minimum then minimum = value end
      if value > maximum then maximum = value end
    end
  end
  if opts.vmin ~= nil then
    minimum = util.check_number(opts.vmin, "polar heatmap vmin")
  end
  if opts.vmax ~= nil then
    maximum = util.check_number(opts.vmax, "polar heatmap vmax")
  end
  if maximum <= minimum then maximum = minimum + 1 end

  local rmin, rmax, theta_min, theta_max =
    checked_field_extent(opts, "polar heatmap")

  local alpha = 1
  if opts.alpha ~= nil then
    alpha = util.check_alpha(opts.alpha, "polar heatmap alpha")
  end
  if opts.label ~= nil then
    util.check_string(opts.label, "polar heatmap label", true)
  end

  local colorbar = false
  if opts.colorbar ~= nil then
    util.check_boolean(opts.colorbar, "polar heatmap colorbar")
    colorbar = opts.colorbar
  end
  if opts.colorbar_label ~= nil then
    util.check_string(opts.colorbar_label,
      "polar heatmap colorbar_label", true)
  end
  local colorbar_ticks = 3
  if opts.colorbar_ticks ~= nil then
    colorbar_ticks = util.check_integer(opts.colorbar_ticks,
      "polar heatmap colorbar_ticks", 2, 9)
  end
  local colorbar_tick_values = nil
  if opts.colorbar_tick_values ~= nil then
    if opts.colorbar_ticks ~= nil then
      fail("polar heatmap colorbar_ticks and colorbar_tick_values cannot both be set")
    end
    local values = opts.colorbar_tick_values
    if type(values) ~= "table" then
      fail("polar heatmap colorbar_tick_values must be a table")
    end
    if #values < 2 or #values > 12 then
      fail("polar heatmap colorbar_tick_values must have 2 to 12 entries")
    end
    local tolerance = math.max(math.abs(maximum - minimum), 1) * 1e-9
    colorbar_tick_values = {}
    for index = 1, #values do
      local value = util.check_number(values[index],
        "polar heatmap colorbar_tick_values[" .. index .. "]")
      if index > 1 and value <= colorbar_tick_values[index - 1] then
        fail(string.format(
          "polar heatmap colorbar_tick_values[%d] must be greater than colorbar_tick_values[%d]",
          index, index - 1))
      end
      if value < minimum - tolerance or value > maximum + tolerance then
        fail(string.format(
          "polar heatmap colorbar_tick_values[%d] must be within vmin and vmax",
          index))
      end
      colorbar_tick_values[index] = value
    end
  end

  local state = ensure_polar_state(self)
  state.heatmaps[#state.heatmaps + 1] = {
    kind = "heatmap",
    rows = rows,
    cols = cols,
    values = matrix,
    vmin = minimum,
    vmax = maximum,
    rmin = rmin,
    rmax = rmax,
    theta_min = theta_min,
    theta_max = theta_max,
    alpha = alpha,
    label = opts.label,
    colorbar = colorbar,
    colorbar_label = opts.colorbar_label,
    colorbar_ticks = colorbar_ticks,
    colorbar_tick_values = colorbar_tick_values,
  }
  return self
end

-- Project contour isolines of a rectangular value matrix onto the polar axes.
-- The matrix shares the heatmap orientation: rows run from the inner radius to
-- the outer radius and columns sweep from theta_min to theta_max.  Marching
-- squares runs over the matrix corners, so the contours span the full field
-- extent and can be overlaid on a heatmap from the same matrix.
function Figure:polar_contour(values, opts)
  opts = util.check_options(opts, POLAR_CONTOUR_OPTIONS, "polar contour")
  local rows, cols, matrix = data.matrix(values, "polar contour values")
  if rows < 2 or cols < 2 then
    fail("polar contour values must be at least 2x2")
  end

  local minimum, maximum = math.huge, -math.huge
  for row = 1, rows do
    for col = 1, cols do
      local value = matrix[row][col]
      if value < minimum then minimum = value end
      if value > maximum then maximum = value end
    end
  end
  if opts.vmin ~= nil then
    minimum = util.check_number(opts.vmin, "polar contour vmin")
  end
  if opts.vmax ~= nil then
    maximum = util.check_number(opts.vmax, "polar contour vmax")
  end
  if maximum <= minimum then maximum = minimum + 1 end

  local levels = opts.levels
  if levels == nil then levels = 5 end
  if type(levels) == "number" then
    levels = util.check_integer(levels, "polar contour levels", 1, 50)
    local list = {}
    for index = 1, levels do
      list[index] = minimum + (maximum - minimum) * index / (levels + 1)
    end
    levels = list
  elseif type(levels) ~= "table" or #levels == 0 then
    fail("polar contour levels must be a positive count or a non-empty table")
  end
  local checked_levels = {}
  for index = 1, #levels do
    checked_levels[index] = util.check_number(levels[index],
      "polar contour levels[" .. index .. "]")
  end

  local linewidth = 1.5
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "polar contour linewidth", 0)
  end
  local linestyle = opts.linestyle or "solid"
  if type(linestyle) ~= "string" or not LINESTYLES[linestyle] then
    fail("polar contour linestyle must be one of solid, dashed, dotted, or none")
  end
  local alpha = 1
  if opts.alpha ~= nil then
    alpha = util.check_alpha(opts.alpha, "polar contour alpha")
  end
  if opts.labels ~= nil then
    util.check_boolean(opts.labels, "polar contour labels")
  end
  if opts.label ~= nil then
    util.check_string(opts.label, "polar contour label", true)
  end

  local color = opts.color and
    util.check_color(opts.color, "polar contour color") or
    colors.next(self._color_serial)
  if opts.color == nil then self._color_serial = self._color_serial + 1 end

  local rmin, rmax, theta_min, theta_max =
    checked_field_extent(opts, "polar contour")

  -- Segment endpoints are stored in normalized field coordinates (0..1 on
  -- both axes) so a later polar_config.rmax stretches contours and heatmaps
  -- together.  The renderer and scene exporter map them to data radians and
  -- radii.
  local column_scale = cols - 1
  local row_scale = rows - 1
  local level_data = {}
  for level_index = 1, #checked_levels do
    local level = checked_levels[level_index]
    local segments = {}
    local function crossing(a, b, x0, y0, x1, y1)
      local da, db = a - level, b - level
      if da == 0 or db == 0 or da * db > 0 then return nil end
      local t = da / (da - db)
      return {
        (x0 + (x1 - x0) * t) / column_scale,
        (y0 + (y1 - y0) * t) / row_scale,
      }
    end
    for row = 1, rows - 1 do
      for col = 1, cols - 1 do
        local x0, y0 = col - 1, row - 1
        local v0, v1 = matrix[row][col], matrix[row][col + 1]
        local v2, v3 = matrix[row + 1][col + 1], matrix[row + 1][col]
        local intersections = {}
        local function add(point)
          if point ~= nil then intersections[#intersections + 1] = point end
        end
        add(crossing(v0, v1, x0, y0, x0 + 1, y0))
        add(crossing(v1, v2, x0 + 1, y0, x0 + 1, y0 + 1))
        add(crossing(v2, v3, x0 + 1, y0 + 1, x0, y0 + 1))
        add(crossing(v3, v0, x0, y0 + 1, x0, y0))
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
    level_data[#level_data + 1] = {
      level = level,
      segments = segments,
    }
  end

  local state = ensure_polar_state(self)
  state.contours[#state.contours + 1] = {
    kind = "contour",
    rows = rows,
    cols = cols,
    levels = level_data,
    vmin = minimum,
    vmax = maximum,
    rmin = rmin,
    rmax = rmax,
    theta_min = theta_min,
    theta_max = theta_max,
    labels = opts.labels == true,
    style = {
      color = color,
      label = opts.label,
      linewidth = linewidth,
      linestyle = linestyle,
      alpha = alpha,
    },
  }
  return self
end

-- Matplotlib-style alias: a heatmap is the natural pcolormesh projection for
-- a polar axes because every cell is already a (theta, r) quad.
function Figure:polar_pcolormesh(values, opts)
  return self:polar_heatmap(values, opts)
end

-- Add text at a data (theta, r) position.  `xytext` optionally moves the text
-- to another polar coordinate and draws a leader arrow back to the target;
-- degrees/theta_unit apply to both angles.
function Figure:polar_annotate(text, theta, r, opts)
  util.check_string(text, "polar annotate text", true)
  if r == nil then
    fail("polar annotate requires text, theta, and r")
  end
  opts = util.check_options(opts, POLAR_ANNOTATE_OPTIONS, "polar annotate")
  local target_theta = checked_theta_scalar(theta, opts, "polar annotate theta")
  local target_r = util.check_number(r, "polar annotate r")

  local xytext = checked_xytext(opts.xytext)
  if xytext ~= nil then
    local text_theta = util.check_number(xytext[1],
      "polar annotate xytext theta")
    local text_r = util.check_number(xytext[2], "polar annotate xytext r")
    if checked_theta_unit(opts, "polar annotate") == "degrees" then
      text_theta = text_theta * math.pi / 180
    end
    xytext = { text_theta, text_r }
  end

  local color = DEFAULT_ANNOTATION_COLOR
  if opts.color ~= nil then
    color = util.check_color(opts.color, "polar annotate color")
  end
  local fontsize = DEFAULT_ANNOTATION_FONTSIZE
  if opts.fontsize ~= nil then
    fontsize = util.check_number(opts.fontsize, "polar annotate fontsize", 0.1)
  end
  local align = opts.align or "left"
  if type(align) ~= "string" or not ANNOTATION_ALIGNS[align] then
    fail("polar annotate align must be one of left, center, or right")
  end

  local state = ensure_polar_state(self)
  state.annotations[#state.annotations + 1] = {
    text = text,
    theta = target_theta,
    r = target_r,
    xytext = xytext,
    color = color,
    fontsize = fontsize,
    align = align,
    rotation = checked_annotation_rotation(opts, "polar annotate"),
    arrow = checked_arrow(opts.arrow, color),
    background = checked_annotation_background(opts, "polar annotate"),
  }
  return self
end

-- Configure polar orientation, radial limits, and explicit angular/radial
-- grids.  Theta grid values are in degrees of the data theta coordinate;
-- theta_zero accepts E/N/W/S or a display offset in radians.
function Figure:polar_config(opts)
  if self._pie ~= nil then
    fail("cannot combine pie and polar plots in one figure")
  end
  if #self._series > 0 then
    fail("cannot mix cartesian and polar series in one figure; create a separate figure")
  end
  if #self._annotations > 0 then
    fail("cannot mix cartesian annotations and polar axes in one figure; create a separate figure")
  end
  polar.configure(self, opts)
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

  local point_linewidths
  local linewidth = 1
  if type(opts.linewidth) == "table" then
    if #opts.linewidth ~= #xv then
      fail("scatter linewidth array must match the number of points")
    end
    point_linewidths = {}
    for index = 1, #opts.linewidth do
      point_linewidths[index] = util.check_number(opts.linewidth[index],
        "scatter linewidth[" .. index .. "]", 0)
    end
    linewidth = point_linewidths[1] or 1
  elseif opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "scatter linewidth", 0)
  end

  local point_colors
  local style_opts = opts
  local color_values, color_vmin, color_vmax
  local colorbar, colorbar_label, colorbar_ticks, colorbar_tick_values
  local c_option = opts.vmin ~= nil or opts.vmax ~= nil or
    opts.colorbar ~= nil or opts.colorbar_label ~= nil or
    opts.colorbar_ticks ~= nil or opts.colorbar_tick_values ~= nil

  if opts.c ~= nil then
    if opts.color ~= nil then
      fail("scatter color and c cannot both be set")
    end
    if type(opts.c) ~= "table" then
      fail("scatter c must be a table of numeric values")
    end
    if #opts.c ~= #xv then
      fail("scatter c must match the number of points")
    end
    color_values = {}
    local minimum, maximum
    for i = 1, #opts.c do
      local value = util.check_number(opts.c[i],
        "scatter c[" .. i .. "]")
      color_values[i] = value
      if minimum == nil or value < minimum then minimum = value end
      if maximum == nil or value > maximum then maximum = value end
    end
    color_vmin, color_vmax = checked_value_range(opts, minimum, maximum,
      "scatter")
    colorbar, colorbar_label, colorbar_ticks, colorbar_tick_values =
      checked_colorbar_options(opts, "scatter", true)
    point_colors = {}
    for i = 1, #color_values do
      point_colors[i] = colors.heat(color_values[i], color_vmin, color_vmax)
    end
    style_opts = {}
    for key, value in pairs(opts) do style_opts[key] = value end
    style_opts.color = point_colors[1]
    style_opts.c = nil
  elseif c_option then
    fail("scatter vmin, vmax, and colorbar options require c")
  elseif type(opts.color) == "table" then
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
  local point_edgecolors
  if type(opts.edgecolor) == "table" then
    if #opts.edgecolor ~= #xv then
      fail("scatter edgecolor array must match the number of points")
    end
    point_edgecolors = {}
    for index = 1, #opts.edgecolor do
      point_edgecolors[index] = util.check_color(opts.edgecolor[index],
        "scatter edgecolor[" .. index .. "]")
    end
    if style_opts == opts then
      style_opts = {}
      for key, value in pairs(opts) do style_opts[key] = value end
    end
    style_opts.edgecolor = point_edgecolors[1]
  end
  local point_alphas
  if type(opts.alpha) == "table" then
    if #opts.alpha ~= #xv then
      fail("scatter alpha array must match the number of points")
    end
    point_alphas = {}
    for index = 1, #opts.alpha do
      point_alphas[index] = util.check_alpha(opts.alpha[index],
        "scatter alpha[" .. index .. "]")
    end
    if style_opts == opts then
      style_opts = {}
      for key, value in pairs(opts) do style_opts[key] = value end
    end
    style_opts.alpha = 1
  end
  local style = checked_style(self, style_opts, "scatter")
  local marker_list, marker = checked_markers(opts.marker, #xv, "scatter")
  style.marker = marker
  style.markers = marker_list
  style.radius = radius
  style.radii = radii
  style.colors = point_colors
  style.edgecolors = point_edgecolors
  style.alphas = point_alphas
  style.linewidth = linewidth
  style.linewidths = point_linewidths

  if colorbar then self._colorbar = true end
  self._series[#self._series + 1] = {
    kind = "scatter",
    x = xv,
    y = yv,
    style = style,
    color_values = color_values,
    vmin = color_vmin,
    vmax = color_vmax,
    colorbar = colorbar,
    colorbar_label = colorbar_label,
    colorbar_ticks = colorbar_ticks,
    colorbar_tick_values = colorbar_tick_values,
  }
  return self
end

local EVENT_OPTIONS = {
  color = true, colors = true, eventcolors = true,
  label = true, labels = true,
  linewidth = true, linestyle = true, alpha = true,
  orientation = true, lineoffsets = true, linelengths = true,
}

-- Normalize one eventplot layout value into one entry per event row. A scalar
-- is repeated for every row; a table must already have one entry per row.
local function event_layout(value, count, name, default, minimum)
  local result = {}
  if value == nil then
    for index = 1, count do result[index] = default(index) end
  elseif type(value) == "number" then
    local checked = util.check_number(value, "eventplot " .. name, minimum)
    for index = 1, count do result[index] = checked end
  elseif type(value) == "table" then
    if #value ~= count then
      fail(string.format("eventplot %s must have one entry per row (%d ~= %d)",
        name, #value, count))
    end
    for index = 1, count do
      result[index] = util.check_number(value[index],
        string.format("eventplot %s[%d]", name, index), minimum)
    end
  else
    fail("eventplot " .. name .. " must be a number or a table")
  end
  return result
end

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
  local orientation = opts.orientation or "vertical"
  if orientation ~= "vertical" and orientation ~= "horizontal" then
    fail("eventplot orientation must be 'vertical' or 'horizontal'")
  end
  local lineoffsets = event_layout(opts.lineoffsets, #rows, "lineoffsets",
    function(index) return index end)
  local linelengths = event_layout(opts.linelengths, #rows, "linelengths",
    function() return 0.8 end, 0.000001)
  local row_labels = nil
  if opts.labels ~= nil then
    row_labels = data.labels(opts.labels, "eventplot labels")
    if #row_labels ~= #rows then
      fail("eventplot labels must have one entry per row")
    end
  end
  local row_colors = nil
  if opts.colors ~= nil then
    if opts.color ~= nil then
      fail("eventplot colors and color cannot both be set")
    end
    if type(opts.colors) ~= "table" or #opts.colors ~= #rows then
      fail("eventplot colors must have one entry per row")
    end
    row_colors = {}
    for index = 1, #rows do
      row_colors[index] = util.check_color(opts.colors[index],
        "eventplot colors[" .. index .. "]")
    end
  end
  local event_colors = nil
  if opts.eventcolors ~= nil then
    local total_events = 0
    for index = 1, #rows do total_events = total_events + #rows[index] end
    if type(opts.eventcolors) ~= "table" or
        #opts.eventcolors ~= total_events then
      fail("eventplot eventcolors must have one entry per event")
    end
    event_colors = {}
    for index = 1, total_events do
      event_colors[index] = util.check_color(opts.eventcolors[index],
        "eventplot eventcolors[" .. index .. "]")
    end
  end
  local row_linewidths
  local row_alphas
  local alpha_value = 1
  if type(opts.alpha) == "table" then
    if #opts.alpha ~= #rows then
      fail("eventplot alpha array must have one entry per row")
    end
    row_alphas = {}
    for index = 1, #opts.alpha do
      row_alphas[index] = util.check_alpha(opts.alpha[index],
        "eventplot alpha[" .. index .. "]")
    end
    alpha_value = row_alphas[1]
  elseif opts.alpha ~= nil then
    alpha_value = util.check_alpha(opts.alpha, "eventplot alpha")
  end
  local linewidth = opts.linewidth
  if type(linewidth) == "table" then
    if #linewidth ~= #rows then
      fail("eventplot linewidth array must have one entry per row")
    end
    row_linewidths = {}
    for index = 1, #linewidth do
      row_linewidths[index] = util.check_number(linewidth[index],
        "eventplot linewidth[" .. index .. "]", 0)
    end
    linewidth = row_linewidths[1]
  elseif linewidth == nil then
    linewidth = 2
  else
    linewidth = util.check_number(linewidth, "eventplot linewidth", 0)
  end
  local linestyle = opts.linestyle or "solid"
  if type(linestyle) ~= "string" or not LINESTYLES[linestyle] then
    fail("eventplot linestyle must be one of solid, dashed, dotted, or none")
  end
  local style_opts = opts
  if type(opts.alpha) == "table" then
    style_opts = {}
    for key, value in pairs(opts) do style_opts[key] = value end
    style_opts.alpha = alpha_value
  end
  local style = checked_style(self, style_opts, "eventplot")
  style.linewidth = linewidth
  style.linewidths = row_linewidths
  style.alpha = alpha_value
  style.alphas = row_alphas
  style.linestyle = linestyle
  if row_colors ~= nil then style.color = row_colors[1] end
  self._series[#self._series + 1] = {
    kind = "eventplot", rows = rows, orientation = orientation,
    lineoffsets = lineoffsets, linelengths = linelengths,
    colors = row_colors, eventcolors = event_colors,
    labels = row_labels, style = style,
  }
  if row_labels ~= nil then
    local ticks = {}
    for index = 1, #rows do
      ticks[index] = { position = lineoffsets[index], label = row_labels[index] }
    end
    self._category_ticks = ticks
    self._category_axis = orientation == "horizontal" and "x" or "y"
  end
  return self
end

function Figure:ecdf(values, opts)
  opts = util.check_options(opts, ECDF_OPTIONS, "ecdf")
  local sorted = data.sequence(values, "ecdf values")
  table.sort(sorted)
  local count = #sorted
  if count == 0 then fail("ecdf requires at least one value") end
  local complementary = opts.complementary == true
  if opts.complementary ~= nil then
    util.check_boolean(opts.complementary, "ecdf complementary")
  end
  local xs, ys = {}, {}
  for i = 1, count do
    xs[i] = sorted[i]
    ys[i] = complementary and (count - i + 1) / count or i / count
  end
  local style = checked_style(self, opts, "ecdf")
  style.linewidth = opts.linewidth or 2
  self._series[#self._series + 1] = {
    kind = "step", x = xs, y = ys, where = "post",
    ecdf = true, complementary = complementary, style = style,
  }
  return self
end

function Figure:hist(values, opts)
  opts = util.check_options(opts, HIST_OPTIONS, "hist")
  local values_v = data.sequence(values, "hist values")

  local bins = 10
  local explicit_edges
  if opts.bins ~= nil then
    if type(opts.bins) == "table" then
      if #opts.bins < 2 then
        fail("hist bins must be a count or at least two explicit edges")
      end
      explicit_edges = {}
      for index = 1, #opts.bins do
        explicit_edges[index] = util.check_number(opts.bins[index],
          "hist bins[" .. index .. "]")
        if index > 1 and explicit_edges[index] <= explicit_edges[index - 1] then
          fail("hist bin edges must be strictly increasing")
        end
      end
      bins = #explicit_edges - 1
    else
      bins = util.check_integer(opts.bins, "hist bins", 1, 1000)
    end
  end

  local lo, hi
  if explicit_edges ~= nil then
    if opts.range ~= nil then
      fail("hist range cannot be combined with explicit bin edges")
    end
    lo, hi = explicit_edges[1], explicit_edges[#explicit_edges]
  elseif opts.range ~= nil then
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
  local orientation = "vertical"
  if opts.orientation ~= nil then
    if opts.orientation ~= "vertical" and opts.orientation ~= "horizontal" then
      fail("hist orientation must be 'vertical' or 'horizontal'")
    end
    orientation = opts.orientation
  end
  local histtype = opts.histtype or "bar"
  if histtype ~= "bar" and histtype ~= "step" and histtype ~= "stepfilled" then
    fail("hist histtype must be 'bar', 'step', or 'stepfilled'")
  end
  local linewidth = histtype == "step" and 1.5 or 1
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "hist linewidth", 0)
  end
  local hatch = opts.hatch
  if hatch ~= nil then
    if type(hatch) ~= "string" or not HATCH_TYPES[hatch] then
      fail("hist hatch must be /, \\, |, -, +, x, ., or o")
    end
    if histtype == "step" then
      fail("hist hatch requires bar or stepfilled histtype")
    end
  end
  local edgecolors = nil
  if opts.edgecolors ~= nil then
    if histtype ~= "bar" then
      fail("hist edgecolors require histtype bar")
    end
    if type(opts.edgecolors) ~= "table" or
        #opts.edgecolors ~= bins then
      fail("hist edgecolors must have one color per bin")
    end
    edgecolors = {}
    for index = 1, #opts.edgecolors do
      edgecolors[index] = util.check_color(opts.edgecolors[index],
        "hist edgecolors[" .. index .. "]")
    end
  end
  local edges = {}
  if explicit_edges ~= nil then
    for index = 1, #explicit_edges do edges[index] = explicit_edges[index] end
  else
    local bin_width = (hi - lo) / bins
    for i = 0, bins do edges[i + 1] = lo + i * bin_width end
  end
  local counts = {}
  for i = 1, bins do counts[i] = 0 end
  for i = 1, #values_v do
    local value = values_v[i]
    if value >= lo and value <= hi then
      local index = 1
      while index < bins and value >= edges[index + 1] do
        index = index + 1
      end
      counts[index] = counts[index] + 1
    end
  end

  if density then
    local total = 0
    for i = 1, bins do total = total + counts[i] end
    if total > 0 then
      for i = 1, bins do
        local width = edges[i + 1] - edges[i]
        counts[i] = counts[i] / (total * width)
      end
    end
  end
  if cumulative then
    for i = 2, bins do counts[i] = counts[i] + counts[i - 1] end
  end

  local style = checked_style(self, opts, "hist")
  style.bins = bins
  style.linewidth = linewidth
  style.hatch = hatch
  style.edgecolors = edgecolors

  self._series[#self._series + 1] = {
    kind = "hist",
    edges = edges,
    counts = counts,
    density = density,
    cumulative = cumulative,
    orientation = orientation,
    histtype = histtype,
    style = style,
  }
  return self
end

-- Rectangular two-dimensional histogram.  Paired samples are counted into a
-- regular x/y grid and non-empty cells are colored with the shared heat
-- palette.  `bins` is a count or `{ nx, ny }`; `range` may pin the rectangle to
-- `{ xmin, xmax, ymin, ymax }`.  Density normalizes each cell by the in-range
-- sample count and cell area.  Empty bins are omitted.
function Figure:hist2d(x, y, opts)
  opts = util.check_options(opts, HIST2D_OPTIONS, "hist2d")
  local xv = data.sequence(x, "hist2d x")
  local yv = data.sequence(y, "hist2d y")
  if #xv ~= #yv then
    fail(string.format("hist2d x and y must have the same length (%d ~= %d)",
      #xv, #yv))
  end
  if #xv == 0 then
    fail("hist2d requires at least one point")
  end

  local bins_x, bins_y = 10, 10
  local explicit_x_edges, explicit_y_edges
  if opts.bins ~= nil then
    if type(opts.bins) == "table" then
      if #opts.bins ~= 2 then
        fail("hist2d bins must be a count, {nx, ny}, or edge tables")
      end
      local function read_edges(value, name)
        if type(value) ~= "table" then return nil end
        if #value < 2 then
          fail(name .. " must have at least two explicit edges")
        end
        local edges = {}
        for index = 1, #value do
          edges[index] = util.check_number(value[index],
            name .. "[" .. index .. "]")
          if index > 1 and edges[index] <= edges[index - 1] then
            fail(name .. " must be strictly increasing")
          end
        end
        return edges
      end
      explicit_x_edges = read_edges(opts.bins[1], "hist2d x bin edges")
      explicit_y_edges = read_edges(opts.bins[2], "hist2d y bin edges")
      if explicit_x_edges ~= nil then
        bins_x = #explicit_x_edges - 1
      else
        bins_x = util.check_integer(opts.bins[1], "hist2d bins x", 1, 200)
      end
      if explicit_y_edges ~= nil then
        bins_y = #explicit_y_edges - 1
      else
        bins_y = util.check_integer(opts.bins[2], "hist2d bins y", 1, 200)
      end
    else
      bins_x = util.check_integer(opts.bins, "hist2d bins", 1, 200)
      bins_y = bins_x
    end
  end
  if opts.range ~= nil and
      (explicit_x_edges ~= nil or explicit_y_edges ~= nil) then
    fail("hist2d range cannot be combined with explicit bin edges")
  end

  local minimum_x, maximum_x = xv[1], xv[1]
  local minimum_y, maximum_y = yv[1], yv[1]
  for index = 2, #xv do
    if xv[index] < minimum_x then minimum_x = xv[index] end
    if xv[index] > maximum_x then maximum_x = xv[index] end
    if yv[index] < minimum_y then minimum_y = yv[index] end
    if yv[index] > maximum_y then maximum_y = yv[index] end
  end

  if opts.range ~= nil then
    if type(opts.range) ~= "table" or #opts.range ~= 4 then
      fail("hist2d range must be a {xmin, xmax, ymin, ymax} table")
    end
    minimum_x = util.check_number(opts.range[1], "hist2d range xmin")
    maximum_x = util.check_number(opts.range[2], "hist2d range xmax")
    minimum_y = util.check_number(opts.range[3], "hist2d range ymin")
    maximum_y = util.check_number(opts.range[4], "hist2d range ymax")
    if maximum_x <= minimum_x then
      fail("hist2d range xmax must be greater than xmin")
    end
    if maximum_y <= minimum_y then
      fail("hist2d range ymax must be greater than ymin")
    end
  else
    if minimum_x == maximum_x then
      local pad = math.abs(minimum_x) * 0.5
      if pad == 0 then pad = 0.5 end
      minimum_x, maximum_x = minimum_x - pad, maximum_x + pad
    end
    if minimum_y == maximum_y then
      local pad = math.abs(minimum_y) * 0.5
      if pad == 0 then pad = 0.5 end
      minimum_y, maximum_y = minimum_y - pad, maximum_y + pad
    end
  end

  local density = opts.density == true
  if opts.density ~= nil then
    util.check_boolean(opts.density, "hist2d density")
  end
  local show_empty = opts.show_empty == true
  if opts.show_empty ~= nil then
    util.check_boolean(opts.show_empty, "hist2d show_empty")
  end

  local edges_x, edges_y = {}, {}
  if explicit_x_edges ~= nil then
    for index = 1, #explicit_x_edges do edges_x[index] = explicit_x_edges[index] end
    minimum_x, maximum_x = edges_x[1], edges_x[#edges_x]
  else
    local span_x = maximum_x - minimum_x
    local width_x = span_x / bins_x
    for index = 0, bins_x do
      edges_x[index + 1] = minimum_x + index * width_x
    end
  end
  if explicit_y_edges ~= nil then
    for index = 1, #explicit_y_edges do edges_y[index] = explicit_y_edges[index] end
    minimum_y, maximum_y = edges_y[1], edges_y[#edges_y]
  else
    local span_y = maximum_y - minimum_y
    local width_y = span_y / bins_y
    for index = 0, bins_y do
      edges_y[index + 1] = minimum_y + index * width_y
    end
  end
  local function bin_index(edges, value)
    local index = 1
    while index < #edges - 1 and value >= edges[index + 1] do
      index = index + 1
    end
    return index
  end

  local counts = {}
  for row = 1, bins_y do
    counts[row] = {}
    for column = 1, bins_x do counts[row][column] = 0 end
  end
  local inside = 0
  for index = 1, #xv do
    local px, py = xv[index], yv[index]
    if px >= minimum_x and px <= maximum_x and
        py >= minimum_y and py <= maximum_y then
      local column = bin_index(edges_x, px)
      local row = bin_index(edges_y, py)
      if column < 1 then column = 1 elseif column > bins_x then column = bins_x end
      if row < 1 then row = 1 elseif row > bins_y then row = bins_y end
      counts[row][column] = counts[row][column] + 1
      inside = inside + 1
    end
  end

  local function cell_value(count, area)
    if not density then return count end
    if inside == 0 then return 0 end
    return count / (inside * area)
  end

  local cells = {}
  local maximum_value = 0
  for row = 1, bins_y do
    for column = 1, bins_x do
      local count = counts[row][column]
      if count > 0 or show_empty then
        local area = (edges_x[column + 1] - edges_x[column]) *
          (edges_y[row + 1] - edges_y[row])
        local value = cell_value(count, area)
        if value > maximum_value then maximum_value = value end
        cells[#cells + 1] = {
          row = row,
          column = column,
          count = count,
          value = value,
          x0 = edges_x[column],
          x1 = edges_x[column + 1],
          y0 = edges_y[row],
          y1 = edges_y[row + 1],
        }
      end
    end
  end

  if maximum_value == 0 then maximum_value = 1 end
  local vmin, vmax = checked_value_range(opts, 0, maximum_value, "hist2d")
  local color_norm = opts.color_norm or "linear"
  if color_norm ~= "linear" and color_norm ~= "log" then
    fail("hist2d color_norm must be 'linear' or 'log'")
  end
  if color_norm == "log" and vmin < 0 then
    fail("hist2d log color_norm requires vmin >= 0")
  end
  local color_vmin = color_norm == "log" and math.log(1 + vmin) or vmin
  local color_vmax = color_norm == "log" and math.log(1 + vmax) or vmax
  if color_vmax <= color_vmin then
    fail("hist2d color range must be positive")
  end
  for _, cell in ipairs(cells) do
    cell.color_value = color_norm == "log" and math.log(1 + cell.value) or
      cell.value
  end
  local colorbar, colorbar_label, colorbar_ticks, colorbar_tick_values =
    checked_colorbar_options(opts, "hist2d", true)
  if color_norm == "log" and colorbar_tick_values ~= nil then
    for _, value in ipairs(colorbar_tick_values) do
      if value < 0 then
        fail("hist2d log color_norm requires non-negative colorbar tick values")
      end
    end
  end

  local style = checked_style(self, opts, "hist2d")
  local edgecolor = opts.edgecolor
  if edgecolor ~= nil then
    edgecolor = util.check_color(edgecolor, "hist2d edgecolor")
  else
    edgecolor = "#ffffff"
  end
  local linewidth = 0.5
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "hist2d linewidth", 0)
  end
  if colorbar then self._colorbar = true end

  self._series[#self._series + 1] = {
    kind = "hist2d",
    x = xv,
    y = yv,
    cells = cells,
    edges_x = edges_x,
    edges_y = edges_y,
    bins_x = bins_x,
    bins_y = bins_y,
    point_count = #xv,
    inside_count = inside,
    density = density,
    show_empty = show_empty,
    explicit_edges = explicit_x_edges ~= nil or explicit_y_edges ~= nil,
    vmin = vmin,
    vmax = vmax,
    color_norm = color_norm,
    color_vmin = color_vmin,
    color_vmax = color_vmax,
    colorbar = colorbar,
    colorbar_label = colorbar_label,
    colorbar_ticks = colorbar_ticks,
    colorbar_tick_values = colorbar_tick_values,
    style = style,
    edgecolor = edgecolor,
    linewidth = linewidth,
  }
  return self
end

-- Aggregate scattered points into regular pointy-top hexagons.  `gridsize`
-- is the number of hexagons across the x span; rows are derived from the
-- y span so every cell stays regular in data coordinates.  Cell counts are
-- rendered with the shared heat palette and can add a vertical colorbar.
function Figure:hexbin(x, y, opts)
  opts = util.check_options(opts, HEXBIN_OPTIONS, "hexbin")
  local xv = data.sequence(x, "hexbin x")
  local yv = data.sequence(y, "hexbin y")
  if #xv ~= #yv then
    fail(string.format("hexbin x and y must have the same length (%d ~= %d)",
      #xv, #yv))
  end
  if #xv == 0 then
    fail("hexbin requires at least one point")
  end

  local gridsize = 20
  if opts.gridsize ~= nil then
    gridsize = util.check_integer(opts.gridsize, "hexbin gridsize", 2, 200)
  end
  local mincnt = 1
  if opts.mincnt ~= nil then
    mincnt = util.check_integer(opts.mincnt, "hexbin mincnt", 1, #xv)
  end

  local minimum_x, maximum_x = xv[1], xv[1]
  local minimum_y, maximum_y = yv[1], yv[1]
  for index = 2, #xv do
    if xv[index] < minimum_x then minimum_x = xv[index] end
    if xv[index] > maximum_x then maximum_x = xv[index] end
    if yv[index] < minimum_y then minimum_y = yv[index] end
    if yv[index] > maximum_y then maximum_y = yv[index] end
  end
  if minimum_x == maximum_x then
    local pad = math.abs(minimum_x) * 0.5
    if pad == 0 then pad = 0.5 end
    minimum_x, maximum_x = minimum_x - pad, maximum_x + pad
  end
  if minimum_y == maximum_y then
    local pad = math.abs(minimum_y) * 0.5
    if pad == 0 then pad = 0.5 end
    minimum_y, maximum_y = minimum_y - pad, maximum_y + pad
  end

  local span_x = maximum_x - minimum_x
  local span_y = maximum_y - minimum_y
  local width = span_x / gridsize
  local radius = width / math.sqrt(3)
  local row_step = 1.5 * radius
  local rows = math.ceil(span_y / row_step) + 3

  local bins = {}
  local bin_order = {}
  local function bin_for(row, column)
    local key = tostring(row) .. ":" .. tostring(column)
    local bin = bins[key]
    if bin == nil then
      bin = {
        row = row,
        column = column,
        x = minimum_x + width / 2 + (row % 2) * width / 2 + column * width,
        y = minimum_y + radius + row * row_step,
        count = 0,
      }
      bins[key] = bin
      bin_order[#bin_order + 1] = bin
    end
    return bin
  end

  for index = 1, #xv do
    local px, py = xv[index], yv[index]
    local row_guess = math.floor((py - (minimum_y + radius)) / row_step)
    local best, best_distance
    for row = row_guess - 1, row_guess + 1 do
      if row >= 0 and row < rows then
        local offset = (row % 2) * width / 2
        local column_guess = math.floor((px - (minimum_x + width / 2 + offset)) /
          width)
        for column = column_guess - 1, column_guess + 1 do
          local cx = minimum_x + width / 2 + offset + column * width
          local cy = minimum_y + radius + row * row_step
          local dx, dy = px - cx, py - cy
          local distance = dx * dx + dy * dy
          if best_distance == nil or distance < best_distance then
            best_distance = distance
            best = bin_for(row, column)
          end
        end
      end
    end
    best.count = best.count + 1
  end

  local cells = {}
  local count_minimum, count_maximum
  for _, bin in ipairs(bin_order) do
    if bin.count >= mincnt and bin.count > 0 then
      cells[#cells + 1] = bin
      if count_minimum == nil or bin.count < count_minimum then
        count_minimum = bin.count
      end
      if count_maximum == nil or bin.count > count_maximum then
        count_maximum = bin.count
      end
    end
  end

  local vmin = count_minimum
  local vmax = count_maximum
  if vmin == nil then
    vmin = 0
    vmax = 1
  elseif vmin == vmax then
    vmin = vmin - 0.5
    vmax = vmax + 0.5
  end
  if opts.vmin ~= nil then
    vmin = util.check_number(opts.vmin, "hexbin vmin")
  end
  if opts.vmax ~= nil then
    vmax = util.check_number(opts.vmax, "hexbin vmax")
  end
  if vmax <= vmin then
    fail("hexbin vmax must be greater than vmin")
  end
  local norm = opts.norm or "linear"
  if norm ~= "linear" and norm ~= "log" then
    fail("hexbin norm must be 'linear' or 'log'")
  end
  if norm == "log" and vmin < 0 then
    fail("hexbin log norm requires vmin >= 0")
  end
  local color_vmin = norm == "log" and math.log(1 + vmin) or vmin
  local color_vmax = norm == "log" and math.log(1 + vmax) or vmax
  if color_vmax <= color_vmin then
    fail("hexbin color range must be positive")
  end
  for _, bin in ipairs(cells) do
    bin.color_value = norm == "log" and math.log(1 + bin.count) or bin.count
  end

  local colorbar = opts.colorbar
  if colorbar == nil then colorbar = true end
  util.check_boolean(colorbar, "hexbin colorbar")
  local colorbar_label = opts.colorbar_label
  if colorbar_label ~= nil then
    util.check_string(colorbar_label, "hexbin colorbar_label", true)
  end
  local colorbar_ticks = nil
  if opts.colorbar_ticks ~= nil then
    colorbar_ticks = util.check_integer(opts.colorbar_ticks,
      "hexbin colorbar_ticks", 2, 10)
  end
  local colorbar_tick_values = nil
  if opts.colorbar_tick_values ~= nil then
    if colorbar_ticks ~= nil then
      fail("hexbin colorbar_ticks and colorbar_tick_values cannot both be set")
    end
    if type(opts.colorbar_tick_values) ~= "table" or
        #opts.colorbar_tick_values == 0 then
      fail("hexbin colorbar_tick_values must be a non-empty table")
    end
    colorbar_tick_values = {}
    for index = 1, #opts.colorbar_tick_values do
      colorbar_tick_values[index] = util.check_number(
        opts.colorbar_tick_values[index],
        "hexbin colorbar_tick_values[" .. index .. "]")
      if norm == "log" and colorbar_tick_values[index] < 0 then
        fail("hexbin log norm requires non-negative colorbar tick values")
      end
    end
  end

  local style = checked_style(self, opts, "hexbin")
  local edgecolor = opts.edgecolor
  if edgecolor ~= nil then
    edgecolor = util.check_color(edgecolor, "hexbin edgecolor")
  else
    edgecolor = "#ffffff"
  end
  local linewidth = 0.5
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "hexbin linewidth", 0)
  end

  self._colorbar = colorbar
  self._series[#self._series + 1] = {
    kind = "hexbin",
    cells = cells,
    vmin = vmin,
    vmax = vmax,
    norm = norm,
    color_vmin = color_vmin,
    color_vmax = color_vmax,
    gridsize = gridsize,
    mincnt = mincnt,
    width = width,
    radius = radius,
    point_count = #xv,
    x = xv,
    y = yv,
    colorbar = colorbar,
    colorbar_label = colorbar_label,
    colorbar_ticks = colorbar_ticks,
    colorbar_tick_values = colorbar_tick_values,
    style = style,
    edgecolor = edgecolor,
    linewidth = linewidth,
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
  local bar_linewidth = 1
  if opts.linewidth ~= nil then
    bar_linewidth = util.check_number(opts.linewidth, "bar linewidth", 0)
  end

  local bar_colors_series = nil
  if opts.bar_colors ~= nil then
    if type(opts.bar_colors) ~= "table" then
      fail("bar bar_colors must be a table")
    end
    local nested = type(opts.bar_colors[1]) == "table"
    if nested then
      if #opts.bar_colors ~= series_count then
        fail(string.format(
          "bar bar_colors must have one color list per series (%d ~= %d)",
          #opts.bar_colors, series_count))
      end
      bar_colors_series = {}
      for series_index = 1, series_count do
        local list = opts.bar_colors[series_index]
        if type(list) ~= "table" or #list ~= #xv then
          fail(string.format(
            "bar bar_colors[%d] must have one color per bar (%d)",
            series_index, #xv))
        end
        local colors = {}
        for i = 1, #list do
          colors[i] = util.check_color(list[i],
            string.format("bar bar_colors[%d][%d]", series_index, i))
        end
        bar_colors_series[series_index] = colors
      end
    else
      if series_count ~= 1 then
        fail("bar bar_colors for multiple series must contain one color list per series")
      end
      if #opts.bar_colors ~= #xv then
        fail(string.format(
          "bar bar_colors must have one color per bar (%d ~= %d)",
          #opts.bar_colors, #xv))
      end
      local colors = {}
      for i = 1, #opts.bar_colors do
        colors[i] = util.check_color(opts.bar_colors[i],
          "bar bar_colors[" .. i .. "]")
      end
      bar_colors_series = { colors }
    end
  end
  local bar_edgecolors_series
  if opts.edgecolors ~= nil then
    if type(opts.edgecolors) ~= "table" then
      fail("bar edgecolors must be a table")
    end
    local nested = type(opts.edgecolors[1]) == "table"
    bar_edgecolors_series = {}
    if nested then
      if #opts.edgecolors ~= series_count then
        fail("bar edgecolors must have one color list per series")
      end
      for series_index = 1, series_count do
        local list = opts.edgecolors[series_index]
        if type(list) ~= "table" or #list ~= #xv then
          fail("bar edgecolors per-series lists must match the number of bars")
        end
        local colors_list = {}
        for i = 1, #list do
          colors_list[i] = util.check_color(list[i],
            string.format("bar edgecolors[%d][%d]", series_index, i))
        end
        bar_edgecolors_series[series_index] = colors_list
      end
    else
      if #opts.edgecolors ~= #xv then
        fail("bar edgecolors must have one color per bar")
      end
      local colors_list = {}
      for i = 1, #opts.edgecolors do
        colors_list[i] = util.check_color(opts.edgecolors[i],
          "bar edgecolors[" .. i .. "]")
      end
      for series_index = 1, series_count do
        bar_edgecolors_series[series_index] = colors_list
      end
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
      if type(value) ~= "string" or not HATCH_TYPES[value] then
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

  local yerr_components
  local bar_ecolor, bar_elinewidth, bar_capsize
  if opts.yerr ~= nil then
    local raw_yerr
    if series_count == 1 then
      raw_yerr = { opts.yerr }
    else
      if type(opts.yerr) ~= "table" or #opts.yerr ~= series_count then
        fail("bar yerr must have one entry per value series")
      end
      raw_yerr = opts.yerr
    end
    yerr_components = {}
    for i = 1, series_count do
      local lower, upper, asymmetric = error_components(raw_yerr[i], #positions,
        "bar yerr[" .. i .. "]")
      yerr_components[i] = {
        lower = lower, upper = upper, asymmetric = asymmetric,
      }
    end
    if opts.ecolor ~= nil then
      bar_ecolor = util.check_color(opts.ecolor, "bar ecolor")
    end
    bar_elinewidth = 1
    if opts.elinewidth ~= nil then
      bar_elinewidth = util.check_number(opts.elinewidth,
        "bar elinewidth", 0)
    end
    bar_capsize = 4
    if opts.capsize ~= nil then
      bar_capsize = util.check_number(opts.capsize, "bar capsize", 0)
    end
  elseif opts.ecolor ~= nil or opts.elinewidth ~= nil or
      opts.capsize ~= nil then
    fail("bar ecolor, elinewidth, and capsize require yerr")
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
    style.linewidth = bar_linewidth
    if bar_edgecolors_series ~= nil then
      style.edgecolors = bar_edgecolors_series[i]
    end
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
    self._category_axis = "x"
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
      bar_colors = bar_colors_series and bar_colors_series[i] or nil,
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
    if yerr_components ~= nil then
      local errors = yerr_components[i]
      entry.yerr_lower = errors.lower
      entry.yerr_upper = errors.upper
      entry.yerr_asymmetric = errors.asymmetric
      entry.ecolor = bar_ecolor or styles[i].color
      entry.elinewidth = bar_elinewidth
      entry.capsize = bar_capsize
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

-- Image extents use the matplotlib order {left, right, bottom, top}.  The
-- rectangle must be ordered so row/column cells have a positive width/height.
local function checked_extent(value, name)
  if value == nil then return nil end
  if type(value) ~= "table" or #value ~= 4 then
    fail(name .. " extent must be a {left, right, bottom, top} table")
  end
  local left = util.check_number(value[1], name .. " extent left")
  local right = util.check_number(value[2], name .. " extent right")
  local bottom = util.check_number(value[3], name .. " extent bottom")
  local top = util.check_number(value[4], name .. " extent top")
  if right <= left then
    fail(name .. " extent right must be greater than left")
  end
  if top <= bottom then
    fail(name .. " extent top must be greater than bottom")
  end
  return { left, right, bottom, top }
end

local function checked_origin(value, name)
  if value == nil then return "upper" end
  if value ~= "upper" and value ~= "lower" then
    fail(name .. " origin must be 'upper' or 'lower'")
  end
  return value
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
    _legend_opts = {
      loc = "upper right", frame = true, framealpha = 0.92,
      facecolor = "#ffffff", edgecolor = "#bbbbbb",
      borderpad = 8, handlelength = 20, fontsize = 11,
    },
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

function Figure:ytick_rotation(angle)
  if type(angle) ~= "number" or angle % 1 ~= 0 or angle < -90 or angle > 90 then
    fail("ytick_rotation must be an integer in [-90, 90]")
  end
  self._ytick_rotation = angle
  return self
end

function Figure:ticklabelsize(size)
  self._ticklabelsize = util.check_number(size, "ticklabelsize", 0.1)
  return self
end

function Figure:ticklabelcolor(color)
  self._ticklabelcolor = util.check_color(color, "ticklabelcolor")
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

-- Fill masks are boolean arrays with one entry per band sample.
local function checked_where(value, count, name)
  if value == nil then return nil end
  if type(value) ~= "table" then
    fail(name .. " must be a table of booleans")
  end
  if #value ~= count then
    fail(string.format("%s must have one boolean per sample (%d ~= %d)",
      name, #value, count))
  end
  local result = {}
  for index = 1, count do
    if type(value[index]) ~= "boolean" then
      fail(string.format("%s[%d] must be a boolean", name, index))
    end
    result[index] = value[index]
  end
  return result
end

local function checked_interpolate(value, name)
  if value == nil then return false end
  util.check_boolean(value, name)
  return value
end

function Figure:fill_between(x, y1, y2, opts)
  opts = util.check_options(opts, FILL_OPTIONS, "fill_between")
  local xv = data.sequence(x, "fill_between x")
  local lower = data.sequence(y1, "fill_between y1")
  local upper = data.sequence(y2 or y1, "fill_between y2")
  if #xv ~= #lower or #xv ~= #upper then
    fail("fill_between x, y1, and y2 must have the same length")
  end
  local where = checked_where(opts.where, #xv, "fill_between where")
  local interpolate = checked_interpolate(opts.interpolate,
    "fill_between interpolate")
  local style = checked_style(self, opts, "fill_between")
  style.linewidth = 0
  if opts.hatch ~= nil then
    if type(opts.hatch) ~= "string" or not HATCH_TYPES[opts.hatch] then
      fail("fill_between hatch must be /, \\, |, -, +, x, ., or o")
    end
    style.hatch = opts.hatch
  end
  self._series[#self._series + 1] = {
    kind = "fill", x = xv, y1 = lower, y2 = upper,
    where = where, interpolate = interpolate, style = style,
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
  local where = checked_where(opts.where, #yv, "fill_betweenx where")
  local interpolate = checked_interpolate(opts.interpolate,
    "fill_betweenx interpolate")
  local style = checked_style(self, opts, "fill_betweenx")
  style.linewidth = 0
  if opts.hatch ~= nil then
    if type(opts.hatch) ~= "string" or not HATCH_TYPES[opts.hatch] then
      fail("fill_betweenx hatch must be /, \\, |, -, +, x, ., or o")
    end
    style.hatch = opts.hatch
  end
  self._series[#self._series + 1] = {
    kind = "fillx", y = yv, x1 = left, x2 = right,
    where = where, interpolate = interpolate, style = style,
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
  local fill = opts.fill == true
  if opts.fill ~= nil then util.check_boolean(opts.fill, "step fill") end
  local fillalpha = 0.2
  if opts.fillalpha ~= nil then
    fillalpha = util.check_alpha(opts.fillalpha, "step fillalpha")
  end
  local style = checked_style(self, opts, "step")
  style.linewidth = linewidth
  style.linestyle = linestyle
  self._series[#self._series + 1] = {
    kind = "step", x = xv, y = yv, where = where,
    fill = fill, fillalpha = fillalpha, style = style,
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
  local marker = "circle"
  if opts.marker ~= nil then marker = checked_marker(opts.marker, "stem") end
  local linestyle = opts.linestyle or "solid"
  if not LINESTYLES[linestyle] then
    fail("stem linestyle must be one of solid, dashed, dotted, or none")
  end
  local base = 0
  if opts.base ~= nil then
    base = util.check_number(opts.base, "stem base")
  end
  local orientation = opts.orientation or "vertical"
  if orientation ~= "vertical" and orientation ~= "horizontal" then
    fail("stem orientation must be 'vertical' or 'horizontal'")
  end
  local style = checked_style(self, opts, "stem")
  style.linewidth = linewidth
  style.linestyle = linestyle
  style.marker = marker
  style.markersize = markersize
  checked_marker_style(opts, "stem", style)
  self._series[#self._series + 1] = {
    kind = "stem", x = xv, y = yv, base = base,
    orientation = orientation, style = style,
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
  local baseline = opts.baseline or "zero"
  if baseline ~= "zero" and baseline ~= "sym" and baseline ~= "wiggle" then
    fail("stackplot baseline must be 'zero', 'sym', or 'wiggle'")
  end

  local values_list = {}
  for index, values in ipairs(series) do
    local yv = data.sequence(values, "stackplot series " .. index)
    if #yv ~= #xv then fail("stackplot series must match x length") end
    values_list[index] = yv
  end

  -- The baseline modes shift the complete stack at each x while preserving
  -- every layer's thickness.  "sym" centers the total; "wiggle" centers the
  -- average of the cumulative layer boundaries.
  local shifts = {}
  for point = 1, #xv do shifts[point] = 0 end
  if baseline ~= "zero" then
    for point = 1, #xv do
      local total = 0
      local cumulative = 0
      local cumulative_sum = 0
      for index = 1, #values_list do
        total = total + values_list[index][point]
        if index < #values_list then
          cumulative = cumulative + values_list[index][point]
          cumulative_sum = cumulative_sum + cumulative
        end
      end
      if baseline == "sym" then
        shifts[point] = -total / 2
      else
        shifts[point] = -(total + cumulative_sum) / (#values_list + 1)
      end
    end
  end

  local bottom = {}
  for i = 1, #xv do bottom[i] = shifts[i] end
  for index, yv in ipairs(values_list) do
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
      stack_baseline = baseline,
      stack_index = index,
      stack_shift = shifts,
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
  local explode = {}
  if opts.explode == nil then
    for index = 1, #values_v do explode[index] = 0 end
  elseif type(opts.explode) == "number" then
    local amount = util.check_number(opts.explode, "pie explode", 0, 0.5)
    for index = 1, #values_v do explode[index] = amount end
  elseif type(opts.explode) == "table" then
    if #opts.explode ~= #values_v then
      fail("pie explode must have one entry per value")
    end
    for index = 1, #values_v do
      explode[index] = util.check_number(opts.explode[index],
        "pie explode[" .. index .. "]", 0, 0.5)
    end
  else
    fail("pie explode must be a number or a table")
  end
  local shadow = opts.shadow == true
  if opts.shadow ~= nil then
    util.check_boolean(opts.shadow, "pie shadow")
  end
  local edgecolor = opts.edgecolor and
    util.check_color(opts.edgecolor, "pie edgecolor") or "#ffffff"
  local linewidth = 1.5
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "pie linewidth", 0)
  end
  local labelsize = 12
  if opts.labelsize ~= nil then
    labelsize = util.check_number(opts.labelsize, "pie labelsize", 0.1)
  end
  local labelcolor = opts.labelcolor and
    util.check_color(opts.labelcolor, "pie labelcolor") or "#222222"
  local pctsize = 12
  if opts.pctsize ~= nil then
    pctsize = util.check_number(opts.pctsize, "pie pctsize", 0.1)
  end
  local pctcolor = opts.pctcolor and
    util.check_color(opts.pctcolor, "pie pctcolor") or "#ffffff"
  local labeldistance = 1.08
  if opts.labeldistance ~= nil then
    labeldistance = util.check_number(opts.labeldistance,
      "pie labeldistance", 0.01, 2)
  end
  local pctdistance = 0.64
  if opts.pctdistance ~= nil then
    pctdistance = util.check_number(opts.pctdistance,
      "pie pctdistance", 0.01, 2)
  end
  local rotatelabels = opts.rotatelabels == true
  if opts.rotatelabels ~= nil then
    util.check_boolean(opts.rotatelabels, "pie rotatelabels")
  end
  local counterclock = opts.counterclock == true
  if opts.counterclock ~= nil then
    util.check_boolean(opts.counterclock, "pie counterclock")
  end
  local direction = counterclock and 1 or -1
  local slices = {}
  local angle = startangle
  for index, value in ipairs(values_v) do
    local sweep = 360 * value / total
    slices[index] = {
      value = value,
      percent = 100 * value / total,
      start_angle = angle,
      end_angle = angle + direction * sweep,
      color = colors_list[index],
      label = labels and labels[index] or ("slice " .. index),
      explode = explode[index],
    }
    angle = angle + direction * sweep
  end
  self._pie = {
    slices = slices, radius = radius, inner_radius = inner,
    autopct = autopct, shadow = shadow, legend = legend,
    edgecolor = edgecolor, linewidth = linewidth,
    labelsize = labelsize, labelcolor = labelcolor,
    pctsize = pctsize, pctcolor = pctcolor,
    labeldistance = labeldistance, pctdistance = pctdistance,
    rotatelabels = rotatelabels, counterclock = counterclock,
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
  local linewidth = 1
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "barh linewidth", 0)
  end
  local hatch = opts.hatch
  if hatch ~= nil then
    if type(hatch) ~= "string" or not HATCH_TYPES[hatch] then
      fail("barh hatch must be /, \\, |, -, +, x, ., or o")
    end
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
  local edgecolors = nil
  if opts.edgecolors ~= nil then
    if type(opts.edgecolors) ~= "table" or
        #opts.edgecolors ~= #values_v then
      fail("barh edgecolors must have one color per bar")
    end
    edgecolors = {}
    for i = 1, #opts.edgecolors do
      edgecolors[i] = util.check_color(opts.edgecolors[i],
        "barh edgecolors[" .. i .. "]")
    end
  end
  if opts.show_values ~= nil then
    util.check_boolean(opts.show_values, "barh show_values")
  end
  self._series[#self._series + 1] = {
    kind = "barh", x = values_v, y = positions, height = height,
    bar_colors = bar_colors, show_values = opts.show_values == true,
    style = { color = color, label = opts.label, alpha = alpha,
      edgecolor = edgecolor, edgecolors = edgecolors,
      linewidth = linewidth, hatch = hatch },
  }
  return self
end

-- Draw a horizontal broken bar (Gantt-style) made of one or more x ranges at
-- a fixed y interval. Ranges are {start, width} pairs; yrange is {y, height}.
function Figure:broken_barh(xranges, yrange, opts)
  opts = util.check_options(opts, BROKEN_BARH_OPTIONS, "broken_barh")
  if type(xranges) ~= "table" or #xranges == 0 then
    fail("broken_barh xranges must be a non-empty table")
  end
  local ranges = {}
  for index = 1, #xranges do
    local range = xranges[index]
    if type(range) ~= "table" or #range ~= 2 then
      fail(string.format(
        "broken_barh xranges[%d] must be a {start, width} table", index))
    end
    local start = util.check_number(range[1],
      string.format("broken_barh xranges[%d] start", index))
    local width = util.check_number(range[2],
      string.format("broken_barh xranges[%d] width", index), 0.000001)
    ranges[index] = { start, width }
  end
  if type(yrange) ~= "table" or #yrange ~= 2 then
    fail("broken_barh yrange must be a {y, height} table")
  end
  local y = util.check_number(yrange[1], "broken_barh yrange y")
  local height = util.check_number(yrange[2],
    "broken_barh yrange height", 0.000001)
  local linewidth = 1
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth,
      "broken_barh linewidth", 0)
  end
  local style = checked_style(self, opts, "broken_barh")
  style.linewidth = linewidth
  self._series[#self._series + 1] = {
    kind = "broken_barh", ranges = ranges, y = y, height = height,
    style = style,
  }
  return self
end

function Figure:imshow(values, opts)
  opts = util.check_options(opts, IMAGE_OPTIONS, "imshow")
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
  local colorbar, colorbar_label, colorbar_ticks, colorbar_tick_values =
    checked_colorbar_options(opts, "imshow", true)
  if colorbar_tick_values ~= nil then
    for index = 1, #colorbar_tick_values do
      local value = colorbar_tick_values[index]
      if value < minimum or value > maximum then
        fail(string.format(
          "imshow colorbar_tick_values[%d] must be within vmin and vmax",
          index))
      end
      if index > 1 and value <= colorbar_tick_values[index - 1] then
        fail(string.format(
          "imshow colorbar_tick_values[%d] must be strictly increasing",
          index))
      end
    end
  end
  local extent = checked_extent(opts.extent, "imshow")
  local origin = checked_origin(opts.origin, "imshow")
  local alpha = 1
  if opts.alpha ~= nil then
    alpha = util.check_alpha(opts.alpha, "imshow alpha")
  end
  self._colorbar = colorbar
  self._series[#self._series + 1] = {
    kind = "image", values = matrix, rows = rows, cols = cols,
    vmin = minimum, vmax = maximum, extent = extent, origin = origin,
    colorbar_label = colorbar_label,
    colorbar_ticks = colorbar_ticks,
    colorbar_tick_values = colorbar_tick_values,
    style = { color = "#000000", label = opts.label, alpha = alpha },
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

  local x_coords, y_coords = {}, {}
  for column = 1, cols do x_coords[column] = column - 1 end
  for row = 1, rows do y_coords[row] = rows - row + 1 end
  local explicit_coords = opts.x ~= nil or opts.y ~= nil
  if opts.x ~= nil then
    if type(opts.x) ~= "table" or #opts.x ~= cols then
      fail(string.format(
        "contour x must have one coordinate per column (%d)", cols))
    end
    for column = 1, cols do
      x_coords[column] = util.check_number(opts.x[column],
        "contour x[" .. column .. "]")
    end
  end
  if opts.y ~= nil then
    if type(opts.y) ~= "table" or #opts.y ~= rows then
      fail(string.format(
        "contour y must have one coordinate per row (%d)", rows))
    end
    for row = 1, rows do
      y_coords[row] = util.check_number(opts.y[row],
        "contour y[" .. row .. "]")
    end
  end

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
        local x0, x1 = x_coords[c], x_coords[c + 1]
        local y0, y1 = y_coords[r], y_coords[r + 1]
        local v0, v1 = matrix[r][c], matrix[r][c + 1]
        local v2, v3 = matrix[r + 1][c + 1], matrix[r + 1][c]
        local intersections = {}
        local function add(point)
          if point ~= nil then intersections[#intersections + 1] = point end
        end
        add(crossing(v0, v1, x0, y0, x1, y0))
        add(crossing(v1, v2, x1, y0, x1, y1))
        add(crossing(v2, v3, x1, y1, x0, y1))
        add(crossing(v3, v0, x0, y1, x0, y0))
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
      x_coords = explicit_coords and x_coords or nil,
      y_coords = explicit_coords and y_coords or nil,
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
  local widths
  local width = 0.6
  if type(opts.width) == "table" then
    if #opts.width ~= #samples then
      fail("boxplot width array must match the number of samples")
    end
    widths = {}
    for index = 1, #opts.width do
      widths[index] = util.check_number(opts.width[index],
        "boxplot width[" .. index .. "]", 0.01, 1)
    end
    width = widths[1]
  elseif opts.width ~= nil then
    width = util.check_number(opts.width, "boxplot width", 0.01, 1)
  end
  local orientation = opts.orientation or "vertical"
  if orientation ~= "vertical" and orientation ~= "horizontal" then
    fail("boxplot orientation must be 'vertical' or 'horizontal'")
  end
  local showmeans = opts.showmeans == true
  if opts.showmeans ~= nil then
    util.check_boolean(opts.showmeans, "boxplot showmeans")
  end
  local meanline = opts.meanline == true
  if opts.meanline ~= nil then
    util.check_boolean(opts.meanline, "boxplot meanline")
  end
  local notch = opts.notch == true
  if opts.notch ~= nil then
    util.check_boolean(opts.notch, "boxplot notch")
  end
  local whis = 1.5
  if opts.whis ~= nil then
    whis = util.check_number(opts.whis, "boxplot whis", 0)
  end
  local showfliers = opts.showfliers
  if showfliers == nil then showfliers = true end
  util.check_boolean(showfliers, "boxplot showfliers")
  local function optional_boolean(value, default, name)
    if value == nil then return default end
    util.check_boolean(value, name)
    return value
  end
  local showbox = optional_boolean(opts.showbox, true, "boxplot showbox")
  local showwhiskers = optional_boolean(opts.showwhiskers, true,
    "boxplot showwhiskers")
  local showcaps = optional_boolean(opts.showcaps, true, "boxplot showcaps")
  local labels = opts.labels
  if labels ~= nil then
    if type(labels) ~= "table" or #labels ~= #samples then
      fail("boxplot labels must have one entry per sample")
    end
  end
  local color_list
  if opts.colors ~= nil then
    if type(opts.colors) ~= "table" or #opts.colors ~= #samples then
      fail("boxplot colors must have one entry per sample")
    end
    color_list = {}
    for index = 1, #opts.colors do
      color_list[index] = util.check_color(opts.colors[index],
        "boxplot colors[" .. index .. "]")
    end
  end
  local alpha_list
  local alpha_value = 1
  if type(opts.alpha) == "table" then
    if #opts.alpha ~= #samples then
      fail("boxplot alpha array must have one entry per sample")
    end
    alpha_list = {}
    for index = 1, #opts.alpha do
      alpha_list[index] = util.check_alpha(opts.alpha[index],
        "boxplot alpha[" .. index .. "]")
    end
    alpha_value = alpha_list[1]
  elseif opts.alpha ~= nil then
    alpha_value = util.check_alpha(opts.alpha, "boxplot alpha")
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
    local mean = 0
    for _, value in ipairs(sorted) do mean = mean + value end
    mean = mean / #sorted
    local q1, median, q3 = quantile(0.25), quantile(0.5), quantile(0.75)
    local iqr = q3 - q1
    local low_limit, high_limit = q1 - whis * iqr, q3 + whis * iqr
    local whisker_low, whisker_high = q1, q3
    for _, value in ipairs(sorted) do
      if value >= low_limit then
        whisker_low = value
        break
      end
    end
    for index = #sorted, 1, -1 do
      local value = sorted[index]
      if value <= high_limit then
        whisker_high = value
        break
      end
    end
    local outliers = {}
    for _, value in ipairs(sorted) do
      if value < whisker_low or value > whisker_high then
        outliers[#outliers + 1] = value
      end
    end
    local notch_low, notch_high
    if notch then
      local delta = 1.57 * iqr / math.sqrt(#sorted)
      notch_low = math.max(q1, median - delta)
      notch_high = math.min(q3, median + delta)
      if notch_low > notch_high then
        notch_low, notch_high = q1, q3
      end
    end
    self._series[#self._series + 1] = {
      kind = "box", position = index,
      width = widths and widths[index] or width,
      orientation = orientation, mean = mean,
      showmeans = showmeans, meanline = meanline,
      notch = notch, notch_low = notch_low, notch_high = notch_high,
      whis = whis, showfliers = showfliers,
      showbox = showbox, showwhiskers = showwhiskers, showcaps = showcaps,
      q1 = q1, median = median, q3 = q3,
      low = whisker_low, high = whisker_high, outliers = outliers,
      style = { color = color_list and color_list[index] or color,
        label = opts.label,
        alpha = alpha_list and alpha_list[index] or alpha_value },
    }
    ticks[#ticks + 1] = {
      position = index,
      label = labels and tostring(labels[index]) or ("sample " .. index),
    }
  end
  self._category_ticks = ticks
  self._category_axis = orientation == "horizontal" and "y" or "x"
  return self
end

-- Kernel-density violins for one or more numeric samples.  Each body is a
-- normalized Gaussian KDE evaluated between the sample extrema; quartile,
-- median, center, and extrema marks are exposed as separate SVG elements.
function Figure:violinplot(values, opts)
  opts = util.check_options(opts, VIOLIN_OPTIONS, "violinplot")
  if type(values) ~= "table" or #values == 0 then
    fail("violinplot expects a non-empty table of samples")
  end
  local samples
  if data.is_tensor_like(values) or type(values[1]) == "number" then
    samples = { values }
  else
    samples = values
  end
  local sample_count = #samples

  local width_fractions
  local width_fraction = 0.5
  if type(opts.width) == "table" then
    if #opts.width ~= sample_count then
      fail("violinplot width array must match the number of samples")
    end
    width_fractions = {}
    for index = 1, #opts.width do
      width_fractions[index] = util.check_number(opts.width[index],
        "violinplot width[" .. index .. "]", 0.01, 1)
    end
    width_fraction = width_fractions[1]
  elseif opts.width ~= nil then
    width_fraction = util.check_number(opts.width,
      "violinplot width", 0.01, 1)
  end
  local points = 50
  if opts.points ~= nil then
    points = util.check_integer(opts.points, "violinplot points", 10, 500)
  end
  local explicit_bandwidth
  if opts.bandwidth ~= nil then
    explicit_bandwidth = util.check_number(opts.bandwidth,
      "violinplot bandwidth", 0.000001)
  end
  local showextrema = opts.showextrema
  if showextrema == nil then showextrema = true end
  util.check_boolean(showextrema, "violinplot showextrema")
  local showmedians = opts.showmedians
  if showmedians == nil then showmedians = true end
  util.check_boolean(showmedians, "violinplot showmedians")
  local showquartiles = opts.showquartiles
  if showquartiles == nil then showquartiles = true end
  util.check_boolean(showquartiles, "violinplot showquartiles")
  local showmeans = opts.showmeans == true
  if opts.showmeans ~= nil then
    util.check_boolean(opts.showmeans, "violinplot showmeans")
  end
  local meanline = opts.meanline == true
  if opts.meanline ~= nil then
    util.check_boolean(opts.meanline, "violinplot meanline")
  end
  local orientation = opts.orientation or "vertical"
  if orientation ~= "vertical" and orientation ~= "horizontal" then
    fail("violinplot orientation must be 'vertical' or 'horizontal'")
  end

  local positions = {}
  if opts.positions ~= nil then
    if type(opts.positions) ~= "table" or #opts.positions ~= sample_count then
      fail("violinplot positions must match the number of samples")
    end
    for index = 1, sample_count do
      positions[index] = util.check_number(opts.positions[index],
        "violinplot positions[" .. index .. "]")
    end
  else
    for index = 1, sample_count do positions[index] = index end
  end
  local sorted_positions = {}
  for index = 1, sample_count do sorted_positions[index] = positions[index] end
  table.sort(sorted_positions)
  local spacing
  for index = 2, #sorted_positions do
    local delta = sorted_positions[index] - sorted_positions[index - 1]
    if delta > 0 and (spacing == nil or delta < spacing) then spacing = delta end
  end
  spacing = spacing or 1
  local base_width = spacing * width_fraction

  local labels = opts.labels
  if labels ~= nil then
    if type(labels) ~= "table" or #labels ~= sample_count then
      fail("violinplot labels must have one entry per sample")
    end
  end
  local color_list
  if opts.colors ~= nil then
    if opts.color ~= nil then
      fail("violinplot colors and color cannot both be set")
    end
    if type(opts.colors) ~= "table" or #opts.colors ~= sample_count then
      fail("violinplot colors must have one entry per sample")
    end
    color_list = {}
    for index = 1, sample_count do
      color_list[index] = util.check_color(opts.colors[index],
        "violinplot colors[" .. index .. "]")
    end
  elseif opts.color ~= nil then
    color_list = {}
    for index = 1, sample_count do
      color_list[index] = util.check_color(opts.color, "violinplot color")
    end
  end

  local alpha_list
  local alpha = opts.alpha
  if type(alpha) == "table" then
    if #alpha ~= sample_count then
      fail("violinplot alpha array must have one entry per sample")
    end
    alpha_list = {}
    for index = 1, #alpha do
      alpha_list[index] = util.check_alpha(alpha[index],
        "violinplot alpha[" .. index .. "]")
    end
    alpha = alpha_list[1]
  elseif alpha == nil then
    alpha = 0.65
  else
    alpha = util.check_alpha(alpha, "violinplot alpha")
  end
  local linewidth = 1
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth,
      "violinplot linewidth", 0)
  end

  local ticks = {}
  for index = 1, sample_count do
    local series_width = spacing *
      (width_fractions and width_fractions[index] or width_fraction)
    local values_v = data.sequence(samples[index],
      "violinplot sample " .. index)
    if #values_v == 0 then fail("violinplot samples must be non-empty") end
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
    local minimum, maximum = sorted[1], sorted[#sorted]
    if minimum == maximum then
      local pad = math.abs(minimum) * 0.5
      if pad == 0 then pad = 0.5 end
      minimum, maximum = minimum - pad, maximum + pad
    end
    local span = maximum - minimum
    local mean = 0
    for _, value in ipairs(sorted) do mean = mean + value end
    mean = mean / #sorted
    local bandwidth = explicit_bandwidth
    if bandwidth == nil then
      local variance = 0
      if #sorted > 1 then
        for _, value in ipairs(sorted) do
          local delta = value - mean
          variance = variance + delta * delta
        end
        variance = variance / (#sorted - 1)
      end
      bandwidth = 1.06 * math.sqrt(variance) * ((#sorted) ^ (-0.2))
      if bandwidth <= 0 then bandwidth = span / 4 end
      if bandwidth <= 0 then bandwidth = 0.5 end
    end

    local densities = {}
    local maximum_density = 0
    local normalizer = 1 / (bandwidth * math.sqrt(2 * math.pi) * #sorted)
    for point = 1, points do
      local y = minimum + span * (point - 1) / (points - 1)
      local total = 0
      for _, value in ipairs(sorted) do
        local z = (y - value) / bandwidth
        total = total + math.exp(-0.5 * z * z)
      end
      local density = total * normalizer
      densities[point] = density
      if density > maximum_density then maximum_density = density end
    end
    if maximum_density <= 0 then maximum_density = 1 end
    for point = 1, points do
      densities[point] = densities[point] / maximum_density
    end
    -- Taper the tips so every violin closes cleanly at the data extrema.
    densities[1] = 0
    densities[points] = 0

    local body_x, body_y = {}, {}
    for point = 1, points do
      local value = minimum + span * (point - 1) / (points - 1)
      local offset = series_width * 0.5 * densities[point]
      if orientation == "horizontal" then
        body_x[#body_x + 1] = value
        body_y[#body_y + 1] = positions[index] + offset
      else
        body_x[#body_x + 1] = positions[index] + offset
        body_y[#body_y + 1] = value
      end
    end
    for point = points - 1, 2, -1 do
      local value = minimum + span * (point - 1) / (points - 1)
      local offset = series_width * 0.5 * densities[point]
      if orientation == "horizontal" then
        body_x[#body_x + 1] = value
        body_y[#body_y + 1] = positions[index] - offset
      else
        body_x[#body_x + 1] = positions[index] - offset
        body_y[#body_y + 1] = value
      end
    end

    local color = color_list and color_list[index] or
      colors.next(self._color_serial)
    if color_list == nil then self._color_serial = self._color_serial + 1 end
    local edgecolor = opts.edgecolor
    if edgecolor ~= nil then
      edgecolor = util.check_color(edgecolor, "violinplot edgecolor")
    else
      edgecolor = color
    end
    local style = checked_style(self, {
      color = color,
      label = labels and labels[index] or opts.label,
      alpha = alpha_list and alpha_list[index] or alpha,
      edgecolor = edgecolor,
    }, "violinplot")
    style.linewidth = linewidth
    style.edgecolor = edgecolor

    self._series[#self._series + 1] = {
      kind = "violin",
      position = positions[index],
      width = series_width,
      points = points,
      bandwidth = bandwidth,
      values = sorted,
      densities = densities,
      body_x = body_x,
      body_y = body_y,
      minimum = minimum,
      maximum = maximum,
      mean = mean,
      q1 = quantile(0.25),
      median = quantile(0.5),
      q3 = quantile(0.75),
      showextrema = showextrema,
      showmedians = showmedians,
      showquartiles = showquartiles,
      showmeans = showmeans,
      meanline = meanline,
      orientation = orientation,
      style = style,
    }
    ticks[#ticks + 1] = {
      position = positions[index],
      label = labels and tostring(labels[index]) or ("sample " .. index),
    }
  end
  self._category_ticks = ticks
  self._category_axis = orientation == "horizontal" and "y" or "x"
  return self
end

function Figure:errorbar(x, y, yerr, xerr, opts)
  -- Allow the common four-argument form: errorbar(x, y, yerr, opts).  An
  -- asymmetric xerr table is recognized before the options form so that
  -- { lower = ..., upper = ... } can be passed as the fourth argument.
  if opts == nil and type(xerr) == "table" then
    local asymmetric_xerr = xerr.lower ~= nil or xerr.upper ~= nil or
      type(xerr[1]) == "table" or type(xerr[2]) == "table"
    if not asymmetric_xerr then
      local has_string_key = false
      for key in pairs(xerr) do
        if type(key) == "string" then has_string_key = true; break end
      end
      if has_string_key then
        opts, xerr = xerr, nil
      end
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

  local yerr_lower, yerr_upper, yerr_asymmetric =
    error_components(yerr, #xv, "errorbar yerr")
  local xerr_lower, xerr_upper, xerr_asymmetric
  if xerr ~= nil then
    xerr_lower, xerr_upper, xerr_asymmetric =
      error_components(xerr, #xv, "errorbar xerr")
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
  local markersizes
  local markersize = 4
  if type(opts.markersize) == "table" then
    if #opts.markersize ~= #xv then
      fail("errorbar markersize array must match the number of points")
    end
    markersizes = {}
    for index = 1, #opts.markersize do
      markersizes[index] = util.check_number(opts.markersize[index],
        "errorbar markersize[" .. index .. "]", 0.1)
    end
    markersize = markersizes[1]
  elseif opts.markersize ~= nil then
    markersize = util.check_number(opts.markersize, "errorbar markersize", 0.1)
  end
  local capsize = 4
  if opts.capsize ~= nil then
    capsize = util.check_number(opts.capsize, "errorbar capsize", 0)
  end
  local elinewidths
  local elinewidth = 1
  if type(opts.elinewidth) == "table" then
    if #opts.elinewidth ~= #xv then
      fail("errorbar elinewidth array must match the number of points")
    end
    elinewidths = {}
    for index = 1, #opts.elinewidth do
      elinewidths[index] = util.check_number(opts.elinewidth[index],
        "errorbar elinewidth[" .. index .. "]", 0)
    end
    elinewidth = elinewidths[1]
  elseif opts.elinewidth ~= nil then
    elinewidth = util.check_number(opts.elinewidth, "errorbar elinewidth", 0)
  end
  local errorevery = 1
  if opts.errorevery ~= nil then
    errorevery = util.check_integer(opts.errorevery,
      "errorbar errorevery", 1)
  end
  local lolims = checked_limit_flags(opts.lolims, #xv, "errorbar lolims")
  local uplims = checked_limit_flags(opts.uplims, #xv, "errorbar uplims")
  local xlolims = checked_limit_flags(opts.xlolims, #xv,
    "errorbar xlolims")
  local xuplims = checked_limit_flags(opts.xuplims, #xv,
    "errorbar xuplims")

  local style_opts = opts
  local point_ecolors
  if type(opts.ecolor) == "table" then
    if #opts.ecolor ~= #xv then
      fail("errorbar ecolor array must match the number of points")
    end
    point_ecolors = {}
    for index = 1, #opts.ecolor do
      point_ecolors[index] = util.check_color(opts.ecolor[index],
        "errorbar ecolor[" .. index .. "]")
    end
    style_opts = {}
    for key, value in pairs(opts) do style_opts[key] = value end
    style_opts.ecolor = point_ecolors[1]
  end
  local style = checked_style(self, style_opts, "errorbar")
  style.linewidth = linewidth
  style.linestyle = linestyle
  style.marker = marker
  style.markersize = markersize
  style.markersizes = markersizes
  checked_marker_style(style_opts, "errorbar", style)
  style.capsize = capsize
  style.elinewidth = elinewidth
  style.elinewidths = elinewidths
  if style_opts.ecolor ~= nil then
    style.ecolor = util.check_color(style_opts.ecolor, "errorbar ecolor")
  else
    style.ecolor = style.color
  end
  style.ecolors = point_ecolors

  self._series[#self._series + 1] = {
    kind = "errorbar",
    x = xv,
    y = yv,
    yerr = yerr_upper,
    yerr_lower = yerr_lower,
    yerr_upper = yerr_upper,
    yerr_asymmetric = yerr_asymmetric,
    xerr = xerr_upper,
    xerr_lower = xerr_lower,
    xerr_upper = xerr_upper,
    xerr_asymmetric = xerr_asymmetric,
    errorevery = errorevery,
    lolims = lolims,
    uplims = uplims,
    xlolims = xlolims,
    xuplims = xuplims,
    style = style,
  }
  return self
end

-- Add a text annotation anchored at data coordinates (x, y). If xytext is
-- supplied, the text is drawn there and an optional arrow points from the text
-- to (x, y). Options are validated eagerly; axis-scale checks happen at render
-- time, when the axes are known.
function Figure:annotate(text, x, y, opts)
  -- In polar mode the same call annotates a (theta, r) position, which keeps
  -- the familiar annotate API usable for both coordinate systems.
  if self._polar ~= nil then
    return self:polar_annotate(text, x, y, opts)
  end
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
    rotation = checked_annotation_rotation(opts, "annotate"),
    arrow = checked_arrow(opts.arrow, color),
    background = checked_annotation_background(opts, "annotate"),
  }
  return self
end

function Figure:title(text, opts)
  util.check_string(text, "title", true)
  local loc = self._title_loc or "center"
  local fontsize = self._title_fontsize or 18
  local color = self._title_color or "#222222"
  if opts ~= nil then
    opts = util.check_options(opts,
      { loc = true, fontsize = true, color = true }, "title")
    if opts.loc ~= nil then
      if type(opts.loc) ~= "string" or not TITLE_LOCATIONS[opts.loc] then
        fail("title loc must be left, center, or right")
      end
      loc = opts.loc
    end
    if opts.fontsize ~= nil then
      fontsize = util.check_number(opts.fontsize, "title fontsize", 0.1)
    end
    if opts.color ~= nil then
      color = util.check_color(opts.color, "title color")
    end
  end
  self._title = text
  self._title_loc = loc
  self._title_fontsize = fontsize
  self._title_color = color
  return self
end

function Figure:xlabel(text, opts)
  util.check_string(text, "xlabel", true)
  local pad = self._xlabel_pad or 0
  local fontsize = self._xlabel_fontsize or 13
  local color = self._xlabel_color or "#222222"
  if opts ~= nil then
    opts = util.check_options(opts,
      { labelpad = true, fontsize = true, color = true }, "xlabel")
    if opts.labelpad ~= nil then
      pad = util.check_number(opts.labelpad, "xlabel labelpad", 0)
    end
    if opts.fontsize ~= nil then
      fontsize = util.check_number(opts.fontsize, "xlabel fontsize", 0.1)
    end
    if opts.color ~= nil then
      color = util.check_color(opts.color, "xlabel color")
    end
  end
  self._xlabel = text
  self._xlabel_pad = pad
  self._xlabel_fontsize = fontsize
  self._xlabel_color = color
  return self
end

function Figure:ylabel(text, opts)
  util.check_string(text, "ylabel", true)
  local pad = self._ylabel_pad or 0
  local fontsize = self._ylabel_fontsize or 13
  local color = self._ylabel_color or "#222222"
  if opts ~= nil then
    opts = util.check_options(opts,
      { labelpad = true, fontsize = true, color = true }, "ylabel")
    if opts.labelpad ~= nil then
      pad = util.check_number(opts.labelpad, "ylabel labelpad", 0)
    end
    if opts.fontsize ~= nil then
      fontsize = util.check_number(opts.fontsize, "ylabel fontsize", 0.1)
    end
    if opts.color ~= nil then
      color = util.check_color(opts.color, "ylabel color")
    end
  end
  self._ylabel = text
  self._ylabel_pad = pad
  self._ylabel_fontsize = fontsize
  self._ylabel_color = color
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

-- Constrain the plot box so one y unit is `value` times one x unit on screen.
-- "equal" is shorthand for 1 and "auto" restores the adaptive box.  The box is
-- centered inside the normal layout margins, so labels and legends continue to
-- use the same outside area.
function Figure:aspect(value)
  if value == nil or value == "auto" then
    self._aspect = nil
    return self
  end
  if value == "equal" then
    self._aspect = 1
    return self
  end
  if type(value) == "number" then
    value = util.check_number(value, "aspect")
    if value <= 0 then
      fail("aspect must be positive")
    end
    self._aspect = value
    return self
  end
  fail("aspect must be 'auto', 'equal', or a positive number")
end

local REFERENCE_OPTIONS = {
  color = true, linewidth = true, linestyle = true, alpha = true, label = true,
}

local function reference_style(figure, opts, name, extra_options)
  local allowed = REFERENCE_OPTIONS
  if extra_options ~= nil then
    allowed = {}
    for key in pairs(REFERENCE_OPTIONS) do allowed[key] = true end
    for key in pairs(extra_options) do allowed[key] = true end
  end
  opts = util.check_options(opts, allowed, name)
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

-- Resolve the axes-fraction endpoints used by axhline/axvline. The defaults
-- span the whole axes; explicit spans must be ordered and inside [0, 1].
local function checked_fraction_span(opts, name, minimum_key, maximum_key)
  if opts ~= nil and type(opts) ~= "table" then
    fail(name .. " options must be a table")
  end
  opts = opts or {}
  local minimum = 0
  local maximum = 1
  if opts[minimum_key] ~= nil then
    minimum = util.check_number(opts[minimum_key],
      name .. " " .. minimum_key, 0, 1)
  end
  if opts[maximum_key] ~= nil then
    maximum = util.check_number(opts[maximum_key],
      name .. " " .. maximum_key, 0, 1)
  end
  if minimum >= maximum then
    fail(name .. " " .. minimum_key .. " must be less than " .. maximum_key)
  end
  return minimum, maximum
end

local SPAN_OPTIONS = { color = true, alpha = true, label = true, hatch = true }

function Figure:axhspan(y1, y2, opts)
  if type(y1) ~= "number" or type(y2) ~= "number" then
    fail("axhspan bounds must be numbers")
  end
  if y1 > y2 then y1, y2 = y2, y1 end
  opts = util.check_options(opts, SPAN_OPTIONS, "axhspan")
  if opts.hatch ~= nil and
      (type(opts.hatch) ~= "string" or not HATCH_TYPES[opts.hatch]) then
    fail("axhspan hatch must be /, \\, |, -, +, x, ., or o")
  end
  self._series[#self._series + 1] = {
    kind = "axhspan", y1 = y1, y2 = y2,
    style = {
      color = util.check_color(opts.color or "#cccccc", "axhspan color"),
      alpha = opts.alpha and util.check_alpha(opts.alpha, "axhspan alpha") or 0.3,
      label = opts.label,
      hatch = opts.hatch,
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
  if opts.hatch ~= nil and
      (type(opts.hatch) ~= "string" or not HATCH_TYPES[opts.hatch]) then
    fail("axvspan hatch must be /, \\, |, -, +, x, ., or o")
  end
  self._series[#self._series + 1] = {
    kind = "axvspan", x1 = x1, x2 = x2,
    style = {
      color = util.check_color(opts.color or "#cccccc", "axvspan color"),
      alpha = opts.alpha and util.check_alpha(opts.alpha, "axvspan alpha") or 0.3,
      label = opts.label,
      hatch = opts.hatch,
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
  local xmin, xmax = checked_fraction_span(opts, "axhline", "xmin", "xmax")
  local style = reference_style(self, opts, "axhline",
    { xmin = true, xmax = true })
  self._series[#self._series + 1] = {
    kind = "axhline", y = y, xmin = xmin, xmax = xmax, style = style,
  }
  return self
end

function Figure:axvline(x, opts)
  if type(x) ~= "number" or x ~= x or x == math.huge or x == -math.huge then
    fail("axvline x must be a finite number")
  end
  local ymin, ymax = checked_fraction_span(opts, "axvline", "ymin", "ymax")
  local style = reference_style(self, opts, "axvline",
    { ymin = true, ymax = true })
  self._series[#self._series + 1] = {
    kind = "axvline", x = x, ymin = ymin, ymax = ymax, style = style,
  }
  return self
end

-- Draw an infinite line through two finite data points, clipped to the axes
-- rectangle. The two defining points participate in automatic ranging; the
-- clipped extensions do not.
function Figure:axline(x1, y1, x2, y2, opts)
  if y2 == nil then
    fail("axline requires x1, y1, x2, and y2")
  end
  x1 = util.check_number(x1, "axline x1")
  y1 = util.check_number(y1, "axline y1")
  x2 = util.check_number(x2, "axline x2")
  y2 = util.check_number(y2, "axline y2")
  if x1 == x2 and y1 == y2 then
    fail("axline requires two distinct points")
  end
  local style = reference_style(self, opts, "axline")
  self._series[#self._series + 1] = {
    kind = "axline", x1 = x1, y1 = y1, x2 = x2, y2 = y2, style = style,
  }
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
      linestyle = true, alpha = true, axis = true, minor = true,
      minor_color = true, minor_linewidth = true, minor_linestyle = true,
      minor_alpha = true }, "grid")
    if opts.axis ~= nil then
      if opts.axis ~= "x" and opts.axis ~= "y" and opts.axis ~= "both" then
        fail("grid axis must be x, y, or both")
      end
      self._grid_opts.axis = opts.axis
    end
    if opts.minor ~= nil then
      util.check_boolean(opts.minor, "grid minor")
      self._grid_opts.minor = opts.minor
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
    if opts.alpha ~= nil then
      self._grid_opts.alpha = util.check_alpha(opts.alpha, "grid alpha")
    end
    if opts.minor_color ~= nil then
      self._grid_opts.minor_color = util.check_color(opts.minor_color,
        "grid minor_color")
    end
    if opts.minor_linewidth ~= nil then
      self._grid_opts.minor_linewidth = util.check_number(opts.minor_linewidth,
        "grid minor_linewidth", 0)
    end
    if opts.minor_linestyle ~= nil then
      if opts.minor_linestyle ~= "solid" and
          opts.minor_linestyle ~= "dashed" and
          opts.minor_linestyle ~= "dotted" then
        fail("grid minor_linestyle must be solid, dashed, or dotted")
      end
      self._grid_opts.minor_linestyle = opts.minor_linestyle
    end
    if opts.minor_alpha ~= nil then
      self._grid_opts.minor_alpha = util.check_alpha(opts.minor_alpha,
        "grid minor_alpha")
    end
  end
  self._grid = enabled
  return self
end

-- Toggle minor tick marks independently from minor grid lines. opts.axis
-- restricts the marks to "x", "y", or "both"; opts.subdivisions controls how
-- many equal parts each linear major interval is split into (2..10, default 5).
function Figure:minorticks(enabled, opts)
  if type(enabled) == "table" and opts == nil then
    opts, enabled = enabled, true
  end
  if enabled == nil then enabled = true end
  util.check_boolean(enabled, "minorticks")
  local axis = self._minorticks.axis
  local subdivisions = self._minorticks.subdivisions or 5
  if opts ~= nil then
    opts = util.check_options(opts,
      { axis = true, subdivisions = true }, "minorticks")
    if opts.axis ~= nil then
      if opts.axis ~= "x" and opts.axis ~= "y" and opts.axis ~= "both" then
        fail("minorticks axis must be x, y, or both")
      end
      axis = opts.axis
    end
    if opts.subdivisions ~= nil then
      subdivisions = util.check_integer(opts.subdivisions,
        "minorticks subdivisions", 2, 10)
    end
  end
  self._minorticks = {
    enabled = enabled, axis = axis, subdivisions = subdivisions,
  }
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
      framealpha = true,
      facecolor = true,
      edgecolor = true,
      borderpad = true,
      handlelength = true,
      fontsize = true,
      title_fontsize = true,
      ncol = true,
      title = true,
    }, "legend")
    if opts.loc ~= nil then
      util.check_string(opts.loc, "legend loc")
      if not LEGEND_LOCATIONS[opts.loc] then
        fail("legend loc must be one of 'upper right', 'upper left', 'lower right', 'lower left', 'upper center', 'lower center', 'center left', 'center right', 'center', or 'best'")
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
    local framealpha = self._legend_opts.framealpha or 0.92
    if opts.framealpha ~= nil then
      framealpha = util.check_alpha(opts.framealpha, "legend framealpha")
    end
    local facecolor = self._legend_opts.facecolor or "#ffffff"
    if opts.facecolor ~= nil then
      facecolor = util.check_color(opts.facecolor, "legend facecolor")
    end
    local edgecolor = self._legend_opts.edgecolor or "#bbbbbb"
    if opts.edgecolor ~= nil then
      edgecolor = util.check_color(opts.edgecolor, "legend edgecolor")
    end
    local borderpad = self._legend_opts.borderpad or 8
    if opts.borderpad ~= nil then
      borderpad = util.check_number(opts.borderpad, "legend borderpad", 0)
    end
    local handlelength = self._legend_opts.handlelength or 20
    if opts.handlelength ~= nil then
      handlelength = util.check_number(opts.handlelength,
        "legend handlelength", 0)
    end
    local fontsize = self._legend_opts.fontsize or 11
    if opts.fontsize ~= nil then
      fontsize = util.check_number(opts.fontsize, "legend fontsize", 0.1)
    end
    local title_fontsize = self._legend_opts.title_fontsize
    if opts.title_fontsize ~= nil then
      title_fontsize = util.check_number(opts.title_fontsize,
        "legend title_fontsize", 0.1)
    end
    self._legend_opts = {
      loc = opts.loc or self._legend_opts.loc,
      frame = opts.frame == nil and self._legend_opts.frame or opts.frame,
      framealpha = framealpha,
      facecolor = facecolor,
      edgecolor = edgecolor,
      borderpad = borderpad,
      handlelength = handlelength,
      fontsize = fontsize,
      title_fontsize = title_fontsize,
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
