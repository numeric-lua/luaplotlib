-- Contiguous visible runs for fill_between and fill_betweenx.
--
-- The renderer, scene exporter, and automatic-ranging code share this module so
-- a `where` mask always describes the same band geometry everywhere.

local M = {}

local function new_run(kind)
  if kind == "fillx" then
    return { kind = "fillx", y = {}, x1 = {}, x2 = {} }
  end
  return { kind = "fill", x = {}, y1 = {}, y2 = {} }
end

local function append_point(run, series, index)
  if run.kind == "fillx" then
    run.y[#run.y + 1] = series.y[index]
    run.x1[#run.x1 + 1] = series.x1[index]
    run.x2[#run.x2 + 1] = series.x2[index]
  else
    run.x[#run.x + 1] = series.x[index]
    run.y1[#run.y1 + 1] = series.y1[index]
    run.y2[#run.y2 + 1] = series.y2[index]
  end
end

-- Add the midpoint of an edge next to a masked-out sample. The caller enables
-- this with `interpolate = true`, matching matplotlib's mask transition
-- behaviour with boolean masks.
local function append_boundary(run, series, left, right)
  if run.kind == "fillx" then
    run.y[#run.y + 1] = (series.y[left] + series.y[right]) / 2
    run.x1[#run.x1 + 1] = (series.x1[left] + series.x1[right]) / 2
    run.x2[#run.x2 + 1] = (series.x2[left] + series.x2[right]) / 2
  else
    run.x[#run.x + 1] = (series.x[left] + series.x[right]) / 2
    run.y1[#run.y1 + 1] = (series.y1[left] + series.y1[right]) / 2
    run.y2[#run.y2 + 1] = (series.y2[left] + series.y2[right]) / 2
  end
end

-- Return one semantic run per contiguous true region of the mask. Without a
-- mask, the whole series is one run. Interpolated boundaries are inserted only
-- where a visible run touches a masked-out sample.
function M.segments(series)
  local kind = series.kind
  if kind ~= "fill" and kind ~= "fillx" then
    return {}
  end
  local count = kind == "fillx" and #series.y or #series.x
  local ranges = {}
  if series.where == nil then
    if count > 0 then ranges[1] = { 1, count } end
  else
    local index = 1
    while index <= count do
      if series.where[index] then
        local first = index
        while index <= count and series.where[index] do
          index = index + 1
        end
        ranges[#ranges + 1] = { first, index - 1 }
      else
        index = index + 1
      end
    end
  end

  local result = {}
  for _, range in ipairs(ranges) do
    local run = new_run(kind)
    if series.interpolate and range[1] > 1 then
      append_boundary(run, series, range[1] - 1, range[1])
    end
    for index = range[1], range[2] do
      append_point(run, series, index)
    end
    if series.interpolate and range[2] < count then
      append_boundary(run, series, range[2], range[2] + 1)
    end
    result[#result + 1] = run
  end
  return result
end

return M
