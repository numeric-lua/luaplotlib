-- luaplotlib: a small, pure-Lua, matplotlib-inspired plotting library.
--
-- The public entry point intentionally has no eager dependencies: requiring
-- this module does not load luatorch, numlua, C libraries, or a GUI toolkit.

local Figure = require("luaplotlib.figure")
local Scene = require("luaplotlib.scene")
local SubplotFigure = require("luaplotlib.subplots")
local Axes3D = require("luaplotlib.axes3d")

local M = {
  _NAME = "luaplotlib",
  _VERSION = "4.18.0",
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

-- Convenience constructor for a polar line plot.  theta and r are one-based
-- arrays; theta is in radians.  Use plt.figure(...):polar(...) when a
-- different canvas size is needed.
function M.polar(theta, r, opts)
  local figure = Figure.new()
  figure:polar(theta, r, opts)
  return figure
end

-- Create a grid of independent axes.  Returns the subplot figure and a
-- row-major matrix of axes figures.
function M.subplots(rows, cols, opts)
  local figure = SubplotFigure.new(rows, cols, opts)
  return figure, figure.axes
end

function M.figure3d(opts) return Axes3D.new(opts) end
M.Axes3D = Axes3D

return M
