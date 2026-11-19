-- luaplotlib: a small, pure-Lua, matplotlib-inspired plotting library.
--
-- The public entry point intentionally has no eager dependencies: requiring
-- this module does not load luatorch, numlua, C libraries, or a GUI toolkit.

local Figure = require("luaplotlib.figure")
local Scene = require("luaplotlib.scene")
local SubplotFigure = require("luaplotlib.subplots")

local M = {
  _NAME = "luaplotlib",
  _VERSION = "1.5.0",
  Figure = Figure,
  SubplotFigure = SubplotFigure,
  scene = Scene,
}

-- Create a new figure.
--
-- opts.width, opts.height: SVG canvas dimensions in user units (pixels).
-- opts.dpi: dots per inch metadata; also determines the default canvas size
--            (6.4 x 4.8 inches) when width/height are omitted.
function M.figure(opts)
  return Figure.new(opts)
end

-- Create a grid of independent axes.  Returns the subplot figure and a
-- row-major matrix of axes figures.
function M.subplots(rows, cols, opts)
  local figure = SubplotFigure.new(rows, cols, opts)
  return figure, figure.axes
end

return M
