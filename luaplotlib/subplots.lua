--
-- Grid subplots built as independent figure axes embedded in a parent SVG.
--
-- This keeps the existing single-axes renderer unchanged: each cell is a
-- full Figure, and the parent composes the child SVGs into a grid.
--
local Figure = require("luaplotlib.figure")
local util = require("luaplotlib.util")

local SubplotFigure = {}
SubplotFigure.__index = SubplotFigure

local DEFAULT_WIDTH = 900
local DEFAULT_HEIGHT = 600
local DEFAULT_GAP = 14
local DEFAULT_MARGIN = 10
local TITLE_SPACE = 42

local function check_count(value, name)
  if type(value) ~= "number" or value % 1 ~= 0 or value < 1 then
    util.fail(name .. " must be a positive integer", 3)
  end
  return value
end

function SubplotFigure.new(rows, cols, opts)
  opts = util.check_options(opts, {
    width = true, height = true, dpi = true, title = true,
    gap = true, margin = true, xscale = true, yscale = true,
    sharex = true, sharey = true,
  }, "subplots")

  rows = check_count(rows, "subplots rows")
  cols = check_count(cols, "subplots cols")

  local width = opts.width or DEFAULT_WIDTH
  local height = opts.height or DEFAULT_HEIGHT
  local dpi = opts.dpi or 100
  local gap = opts.gap or DEFAULT_GAP
  local margin = opts.margin or DEFAULT_MARGIN
  if type(width) ~= "number" or width < 1 then
    util.fail("subplots width must be positive", 3)
  end
  if type(height) ~= "number" or height < 1 then
    util.fail("subplots height must be positive", 3)
  end
  if type(dpi) ~= "number" or dpi < 1 then
    util.fail("subplots dpi must be positive", 3)
  end
  if type(gap) ~= "number" or gap < 0 then
    util.fail("subplots gap must be non-negative", 3)
  end
  if type(margin) ~= "number" or margin < 0 then
    util.fail("subplots margin must be non-negative", 3)
  end

  local title = opts.title
  if title ~= nil then util.check_string(title, "subplots title", true) end
  local top = margin + (title ~= nil and TITLE_SPACE or 0)
  local cell_width = (width - 2 * margin - (cols - 1) * gap) / cols
  local cell_height = (height - top - margin - (rows - 1) * gap) / rows
  if cell_width < 40 or cell_height < 40 then
    util.fail("subplots canvas is too small for the requested grid", 3)
  end

  local axes = {}
  for row = 1, rows do
    axes[row] = {}
    for col = 1, cols do
      axes[row][col] = Figure.new({
        width = cell_width, height = cell_height, dpi = dpi,
        xscale = opts.xscale, yscale = opts.yscale,
      })
    end
  end

  return setmetatable({
    width = width, height = height, dpi = dpi,
    rows = rows, cols = cols,
    axes = axes,
    _title = title,
    _gap = gap, _margin = margin, _top = top,
    _cell_width = cell_width, _cell_height = cell_height,
    _facecolor = "#ffffff", _sharex = opts.sharex == true,
    _sharey = opts.sharey == true,
  }, SubplotFigure)
end

function SubplotFigure:title(text)
  if text ~= nil then util.check_string(text, "subplots title", false) end
  self._title = text
  return self
end

SubplotFigure.suptitle = SubplotFigure.title

function SubplotFigure:grid(enabled, opts)
  for row = 1, self.rows do
    for col = 1, self.cols do self.axes[row][col]:grid(enabled, opts) end
  end
  return self
end

function SubplotFigure:facecolor(color)
  self._facecolor = util.check_color(color, "subplots facecolor")
  for row = 1, self.rows do
    for col = 1, self.cols do self.axes[row][col]:facecolor(color) end
  end
  return self
end

function SubplotFigure:plot(...)
  self.axes[1][1]:plot(...)
  return self
end

function SubplotFigure:scatter(...)
  self.axes[1][1]:scatter(...)
  return self
end

function SubplotFigure:axes_at(row, col)
  row = check_count(row, "subplot row")
  col = check_count(col, "subplot column")
  if row > self.rows or col > self.cols then
    util.fail("subplot index is outside the grid", 3)
  end
  return self.axes[row][col]
end

-- Align the x/y limits of a row or column explicitly.  This is opt-in because
-- the individual figures infer limits independently.
function SubplotFigure:share_limits(axis, index)
  axis = axis or "x"
  if axis ~= "x" and axis ~= "y" then
    util.fail("share_limits axis must be 'x' or 'y'", 3)
  end
  local values = {}
  local function collect(figure)
    local limit = axis == "x" and figure._xlim or figure._ylim
    if limit ~= nil then values[#values + 1] = limit end
  end
  if index ~= nil then
    index = check_count(index, "share_limits index")
    for row = 1, self.rows do
      if axis == "x" then collect(self.axes[row][index])
      else collect(self.axes[index][row]) end
    end
  else
    for row = 1, self.rows do
      for col = 1, self.cols do collect(self.axes[row][col]) end
    end
  end
  if #values == 0 then return self end
  local lo, hi = values[1][1], values[1][2]
  for _, limit in ipairs(values) do
    lo = math.min(lo, limit[1])
    hi = math.max(hi, limit[2])
  end
  for row = 1, self.rows do
    for col = 1, self.cols do
      if index == nil or (axis == "x" and col == index) or
          (axis == "y" and row == index) then
        local figure = self.axes[row][col]
        if axis == "x" then figure._xlim = { lo, hi }
        else figure._ylim = { lo, hi } end
      end
    end
  end
  return self
end

local function apply_shared_limits(self)
  if not self._sharex and not self._sharey then return end
  local render = require("luaplotlib.render")
  local xmin, xmax, ymin, ymax
  for row = 1, self.rows do
    for col = 1, self.cols do
      local child = self.axes[row][col]
      local extents = render.data_extents(child, child._xscale or "linear",
        child._yscale or "linear")
      if extents ~= nil then
        if self._sharex and extents.has_x then
          if xmin == nil or extents.min_x < xmin then xmin = extents.min_x end
          if xmax == nil or extents.max_x > xmax then xmax = extents.max_x end
        end
        if self._sharey and extents.has_y then
          if ymin == nil or extents.min_y < ymin then ymin = extents.min_y end
          if ymax == nil or extents.max_y > ymax then ymax = extents.max_y end
        end
      end
    end
  end
  for row = 1, self.rows do
    for col = 1, self.cols do
      local child = self.axes[row][col]
      if xmin ~= nil and xmin < xmax and child._xlim == nil then
        child._xlim = { xmin, xmax }
      end
      if ymin ~= nil and ymin < ymax and child._ylim == nil then
        child._ylim = { ymin, ymax }
      end
    end
  end
end

function SubplotFigure:to_svg()
  apply_shared_limits(self)
  local buffers = {}
  buffers[#buffers + 1] = '<?xml version="1.0" encoding="UTF-8"?>'
  buffers[#buffers + 1] = string.format(
    '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" ' ..
    'viewBox="0 0 %s %s" version="1.1" data-dpi="%s" data-subplots="%dx%d">',
    util.fmt(self.width), util.fmt(self.height), util.fmt(self.width),
    util.fmt(self.height), util.fmt(self.dpi), self.rows, self.cols)
  buffers[#buffers + 1] = string.format(
    ' <rect class="figure-background" width="%s" height="%s" fill="%s"/>',
    util.fmt(self.width), util.fmt(self.height), self._facecolor or "#ffffff")
  if self._title ~= nil then
    buffers[#buffers + 1] = string.format(
      ' <text class="suptitle" x="%s" y="%s" font-size="20" fill="#222222" ' ..
      'text-anchor="middle">%s</text>', util.fmt(self.width / 2),
      util.fmt(self._margin + 26), util.escape_xml(self._title))
  end
  for row = 1, self.rows do
    for col = 1, self.cols do
      local x = self._margin + (col - 1) * (self._cell_width + self._gap)
      local y = self._top + (row - 1) * (self._cell_height + self._gap)
      local child = self.axes[row][col]:to_svg()
      child = child:gsub("^<%?xml[^>]*%>%s*", "")
      buffers[#buffers + 1] = string.format(
        ' <g class="subplot" data-row="%d" data-col="%d" ' ..
        'transform="translate(%s %s)">', row, col, util.fmt(x), util.fmt(y))
      buffers[#buffers + 1] = child
      buffers[#buffers + 1] = ' </g>'
    end
  end
  buffers[#buffers + 1] = '</svg>'
  return table.concat(buffers, "\n") .. "\n"
end

function SubplotFigure:savefig(path)
  util.check_string(path, "savefig path", false)
  local svg = self:to_svg()
  local handle, err = io.open(path, "wb")
  if handle == nil then
    util.fail("could not open " .. string.format("%q", path) .. ": " ..
      tostring(err), 3)
  end
  local ok, write_err = handle:write(svg)
  local closed, close_err = handle:close()
  if not ok then util.fail("could not write SVG: " .. tostring(write_err), 3) end
  if not closed then util.fail("could not close SVG: " .. tostring(close_err), 3) end
  return path
end

function SubplotFigure:to_scene()
  local axes = {}
  for row = 1, self.rows do
    for col = 1, self.cols do
      axes[#axes + 1] = {
        row = row, col = col, scene = self.axes[row][col]:to_scene(),
      }
    end
  end
  return {
    version = 1, type = "luaplotlib.subplots", width = self.width,
    height = self.height, dpi = self.dpi, title = self._title, axes = axes,
  }
end

return SubplotFigure
