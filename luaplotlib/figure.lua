-- Public Figure object and series construction.

local colors = require("luaplotlib.colors")
local data = require("luaplotlib.data")
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

local SCATTER_OPTIONS = {
  color = true,
  label = true,
  size = true,
  s = true,
  markersize = true,
  alpha = true,
  edgecolor = true,
  linewidth = true,
}

local HIST_OPTIONS = {
  bins = true,
  color = true,
  label = true,
  alpha = true,
  edgecolor = true,
  range = true,
}

local BAR_OPTIONS = {
  color = true,
  label = true,
  width = true,
  alpha = true,
  edgecolor = true,
}

local MARKERS = {
  circle = true,
  o = true,
  point = true,
  dot = true,
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

local function fail(message)
  util.fail(message, 3)
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
    fail(context .. " marker must be one of circle, o, point, dot, true, or false")
  end
  return value
end

function Figure.new(opts)
  opts = util.check_options(opts, {
    width = true,
    height = true,
    dpi = true,
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
    _color_serial = 0,
    _title = nil,
    _xlabel = nil,
    _ylabel = nil,
    _xlim = nil,
    _ylim = nil,
    _grid = false,
    _legend_requested = false,
    _legend_opts = { loc = "upper right", frame = true },
    _category_ticks = nil,
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

function Figure:scatter(x, y, opts)
  opts = util.check_options(opts, SCATTER_OPTIONS, "scatter")
  local xv = data.sequence(x, "scatter x")
  local yv = data.sequence(y, "scatter y")
  if #xv ~= #yv then
    fail(string.format("scatter x and y must have the same length (%d ~= %d)", #xv, #yv))
  end

  local radius = 4
  local radius_arg = opts.size
  if radius_arg == nil then
    radius_arg = opts.markersize
  end
  if radius_arg == nil then
    radius_arg = opts.s
  end
  if radius_arg ~= nil then
    radius = util.check_number(radius_arg, "scatter size", 0.1)
  end

  local linewidth = 1
  if opts.linewidth ~= nil then
    linewidth = util.check_number(opts.linewidth, "scatter linewidth", 0)
  end

  local style = checked_style(self, opts, "scatter")
  style.radius = radius
  style.linewidth = linewidth

  self._series[#self._series + 1] = {
    kind = "scatter",
    x = xv,
    y = yv,
    style = style,
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
    style = style,
  }
  return self
end

function Figure:bar(labels_or_x, values, opts)
  opts = util.check_options(opts, BAR_OPTIONS, "bar")
  if values == nil then
    fail("bar requires values as its second argument")
  end
  local yv = data.sequence(values, "bar values")

  local kind, xv
  if type(labels_or_x) == "table" and #labels_or_x > 0 then
    kind, xv = data.bar_x(labels_or_x, "bar labels_or_x")
  else
    kind = "numeric"
    xv = data.sequence(labels_or_x, "bar x")
  end
  if #xv ~= #yv then
    fail(string.format("bar labels/x and values must have the same length (%d ~= %d)",
      #xv, #yv))
  end

  local width_fraction = 0.8
  if opts.width ~= nil then
    width_fraction = util.check_number(opts.width, "bar width", 0.01, 1)
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
  local bar_width = (spacing or 1) * width_fraction

  local style = checked_style(self, opts, "bar")
  style.width_fraction = width_fraction

  if kind == "categories" then
    self._category_ticks = {}
    for i = 1, #xv do
      self._category_ticks[i] = { position = i, label = xv[i] }
    end
  end

  self._series[#self._series + 1] = {
    kind = "bar",
    x = positions,
    y = yv,
    width = bar_width,
    category = kind == "categories",
    style = style,
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

function Figure:grid(enabled)
  if enabled == nil then
    enabled = true
  end
  util.check_boolean(enabled, "grid")
  self._grid = enabled
  return self
end

function Figure:legend(opts)
  if opts ~= nil then
    opts = util.check_options(opts, {
      loc = true,
      frame = true,
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
    self._legend_opts = {
      loc = opts.loc or self._legend_opts.loc,
      frame = opts.frame == nil and self._legend_opts.frame or opts.frame,
    }
  end
  self._legend_requested = true
  return self
end

function Figure:to_svg()
  -- Required lazily so that the renderer can evolve without a require cycle.
  local render = require("luaplotlib.render")
  return render.to_svg(self)
end

function Figure:savefig(path)
  util.check_string(path, "savefig path", false)
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
