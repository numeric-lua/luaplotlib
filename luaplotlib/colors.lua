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


-- A compact viridis-like palette for heatmaps.  Values outside [0,1] clamp.
local HEAT_ANCHORS = {
  { 0.267, 0.005, 0.329 },
  { 0.188, 0.407, 0.554 },
  { 0.128, 0.567, 0.551 },
  { 0.369, 0.789, 0.383 },
  { 0.993, 0.906, 0.144 },
}

function M.heat(value, minimum, maximum)
  local t
  if maximum <= minimum then t = 0 else t = (value - minimum) / (maximum - minimum) end
  if t < 0 then t = 0 elseif t > 1 then t = 1 end
  local scaled = t * (#HEAT_ANCHORS - 1)
  local index = math.floor(scaled) + 1
  if index >= #HEAT_ANCHORS then index = #HEAT_ANCHORS - 1 end
  local fraction = scaled - (index - 1)
  local a = HEAT_ANCHORS[index]
  local b = HEAT_ANCHORS[index + 1]
  local function channel(left, right)
    return math.floor((left + (right - left) * fraction) * 255 + 0.5)
  end
  return string.format("#%02x%02x%02x", channel(a[1], b[1]),
    channel(a[2], b[2]), channel(a[3], b[3]))
end

return M
