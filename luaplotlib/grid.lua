-- Shared grid style resolution for the SVG renderer and scene export.

local M = {}

M.DEFAULT_COLOR = "#d9d9d9"
M.DEFAULT_WIDTH = 1
M.DEFAULT_STYLE = "solid"
M.DEFAULT_ALPHA = 1
M.MINOR_WIDTH_SCALE = 0.65
M.MINOR_ALPHA_SCALE = 0.6

-- Resolve major and minor grid styles. Minor values inherit from the major
-- style unless the caller supplied an independent override.
function M.styles(opts)
  opts = opts or {}
  local color = opts.color or M.DEFAULT_COLOR
  local linewidth = opts.linewidth or M.DEFAULT_WIDTH
  local linestyle = opts.linestyle or M.DEFAULT_STYLE
  local alpha = opts.alpha or M.DEFAULT_ALPHA
  local minor_color = opts.minor_color or color
  local minor_linewidth = opts.minor_linewidth
  if minor_linewidth == nil then
    minor_linewidth = linewidth * M.MINOR_WIDTH_SCALE
  end
  local minor_linestyle = opts.minor_linestyle or linestyle
  local minor_alpha = opts.minor_alpha
  if minor_alpha == nil then
    minor_alpha = alpha * M.MINOR_ALPHA_SCALE
  end
  return {
    color = color,
    linewidth = linewidth,
    linestyle = linestyle,
    alpha = alpha,
    axis = opts.axis or "both",
  }, {
    color = minor_color,
    linewidth = minor_linewidth,
    linestyle = minor_linestyle,
    alpha = minor_alpha,
  }
end

return M
