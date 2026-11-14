-- "Nice" linear tick selection for the SVG backend.

local M = {}

local NICE = { 1, 2, 2.5, 5, 10 }

local function nice_step(raw)
  if type(raw) ~= "number" or raw ~= raw or raw <= 0 or raw == math.huge then
    return 1
  end
  local exponent = math.floor(math.log(raw) / math.log(10))
  local scale = 10 ^ exponent
  local fraction = raw / scale
  local chosen = 10
  for i = 1, #NICE do
    if fraction <= NICE[i] + 1e-12 then
      chosen = NICE[i]
      break
    end
  end
  return chosen * scale
end

M.nice_step = nice_step

-- Return tick positions inside [lo, hi]. The count is approximate; tick
-- spacing is always 1, 2, 2.5, or 5 times a power of ten.
function M.generate(lo, hi, target)
  if hi < lo then
    lo, hi = hi, lo
  end
  if hi == lo then
    hi = lo + 1
  end
  target = target or 6
  if type(target) ~= "number" or target < 2 then
    target = 2
  end
  target = math.min(math.floor(target), 20)

  local step = nice_step((hi - lo) / target)
  local tolerance = step * 1e-8
  local first = math.ceil(lo / step - 1e-9) * step
  local values = {}
  for i = 0, 1000 do
    local value = first + i * step
    if value > hi + tolerance then
      break
    end
    if math.abs(value) < tolerance then
      value = 0
    end
    -- Guard against pathological floating-point growth.
    if #values > 0 and math.abs(value - values[#values]) <= step * 1e-8 then
      -- skip a duplicate
    else
      values[#values + 1] = value
    end
  end

  -- A range narrower than floating-point resolution still deserves a label.
  if #values == 0 then
    values[1] = lo
  end
  return values, step
end

return M
