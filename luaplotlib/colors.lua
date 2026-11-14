-- Matplotlib-inspired default color cycle.

local M = {}

M.palette = {
  "#1f77b4",
  "#ff7f0e",
  "#2ca02c",
  "#d62728",
  "#9467bd",
  "#8c564b",
  "#e377c2",
  "#7f7f7f",
  "#bcbd22",
  "#17becf",
}

function M.next(index)
  -- index is zero-based so the first requested color is palette[1].
  return M.palette[(index % #M.palette) + 1]
end

return M
