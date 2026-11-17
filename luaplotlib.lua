-- luaplotlib: a small, pure-Lua, matplotlib-inspired plotting library.
--
-- The public entry point intentionally has no eager dependencies: requiring
-- this module does not load luatorch, numlua, C libraries, or a GUI toolkit.

local Figure = require("luaplotlib.figure")
local Scene = require("luaplotlib.scene")

local M = {
  _NAME = "luaplotlib",
  _VERSION = "0.2.0",
  Figure = Figure,
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

return M
