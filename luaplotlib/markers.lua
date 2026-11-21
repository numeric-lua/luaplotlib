-- Shared SVG marker shapes for the Cartesian and polar renderers.

local util = require("luaplotlib.util")

local M = {}

function M.svg(kind, klass, cx, cy, size, color, opacity, outline)
  if kind == "square" or kind == "s" then
    return string.format(
      '   <rect class="%s" x="%s" y="%s" width="%s" height="%s" fill="%s"%s%s/>',
      klass, util.fmt(cx - size), util.fmt(cy - size), util.fmt(size * 2),
      util.fmt(size * 2), color, opacity, outline)
  elseif kind == "triangle" or kind == "^" then
    return string.format(
      '   <polygon class="%s" points="%s,%s %s,%s %s,%s" fill="%s"%s%s/>',
      klass, util.fmt(cx), util.fmt(cy - size), util.fmt(cx - size),
      util.fmt(cy + size), util.fmt(cx + size), util.fmt(cy + size), color,
      opacity, outline)
  elseif kind == "diamond" or kind == "D" then
    return string.format(
      '   <polygon class="%s" points="%s,%s %s,%s %s,%s %s,%s" fill="%s"%s%s/>',
      klass, util.fmt(cx), util.fmt(cy - size), util.fmt(cx + size),
      util.fmt(cy), util.fmt(cx), util.fmt(cy + size), util.fmt(cx - size),
      util.fmt(cy), color, opacity, outline)
  elseif kind == "cross" or kind == "+" or kind == "x" or kind == "X" then
    local s = size
    if kind == "cross" or kind == "+" then
      return string.format(
        '   <path class="%s" d="M%s,%s L%s,%s M%s,%s L%s,%s" stroke="%s" stroke-width="2" fill="none"%s/>',
        klass, util.fmt(cx - s), util.fmt(cy), util.fmt(cx + s), util.fmt(cy),
        util.fmt(cx), util.fmt(cy - s), util.fmt(cx), util.fmt(cy + s), color,
        opacity)
    end
    return string.format(
      '   <path class="%s" d="M%s,%s L%s,%s M%s,%s L%s,%s" stroke="%s" stroke-width="2" fill="none"%s/>',
      klass, util.fmt(cx - s), util.fmt(cy - s), util.fmt(cx + s),
      util.fmt(cy + s), util.fmt(cx + s), util.fmt(cy - s),
      util.fmt(cx - s), util.fmt(cy + s), color, opacity)
  end
  return string.format(
    '   <circle class="%s" cx="%s" cy="%s" r="%s" fill="%s"%s%s/>',
    klass, util.fmt(cx), util.fmt(cy), util.fmt(size), color, opacity, outline)
end

return M
