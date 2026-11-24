-- "Nice" linear and logarithmic tick selection for the SVG backend.

local util = require("luaplotlib.util")

local M = {}

local NICE = { 1, 2, 2.5, 5, 10 }

local LOG_EPSILON = 1e-9
local LOG_MANTISSAS = {
  { 1 },
  { 1, 2, 5 },
  { 1, 2, 2.5, 5 },
  { 1, 2, 3, 5 },
  { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
}

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

local function positive_finite(value)
  return type(value) == "number" and value == value and value > 0
    and value ~= math.huge
end

local function append_unique(values, value)
  if #values > 0 then
    local previous = values[#values]
    local scale = math.max(math.abs(value), math.abs(previous), 1)
    if math.abs(value - previous) <= scale * 1e-12 then
      return
    end
  end
  values[#values + 1] = value
end

local function integer_nice_step(raw)
  local power = 1
  while true do
    if power >= raw then return power end
    if 2 * power >= raw then return 2 * power end
    if 5 * power >= raw then return 5 * power end
    power = power * 10
  end
end

-- Return tick values at integer powers of ten between lo and hi. Large spans
-- are thinned with 1/2/5-style exponent steps so labels do not collide.
local function decade_ticks(lo, hi, target)
  local tlo = util.log10(lo)
  local thi = util.log10(hi)
  local first = math.ceil(tlo - LOG_EPSILON)
  local last = math.floor(thi + LOG_EPSILON)
  if last < first then
    return {}
  end

  local exponents = {}
  for exponent = first, last do
    exponents[#exponents + 1] = exponent
  end

  local max_ticks = math.max(target, 2) * 2
  local step = 1
  if #exponents > max_ticks then
    step = integer_nice_step((#exponents - 1) / math.max(math.max(target, 2) - 1, 1))
  end

  local values = {}
  local tolerance = 1e-12
  local selected_index = 1
  for index = 1, #exponents, step do
    local exponent = exponents[index]
    local value = 10 ^ exponent
    if value >= lo * (1 - tolerance) and value <= hi * (1 + tolerance) then
      append_unique(values, value)
    end
    selected_index = index
  end

  -- Keep the upper endpoint represented when a thinned sequence would stop
  -- short of the top decade.
  if step > 1 and selected_index < #exponents then
    local value = 10 ^ exponents[#exponents]
    if value >= lo * (1 - tolerance) and value <= hi * (1 + tolerance) then
      append_unique(values, value)
    end
  end
  return values
end

local function mantissa_ticks(lo, hi, mantissas)
  local first = math.floor(util.log10(lo) - LOG_EPSILON)
  local last = math.ceil(util.log10(hi) + LOG_EPSILON)
  local values = {}
  local tolerance = 1e-12
  for exponent = first, last do
    local base = 10 ^ exponent
    for index = 1, #mantissas do
      local value = mantissas[index] * base
      if value >= lo * (1 - tolerance) and value <= hi * (1 + tolerance) then
        append_unique(values, value)
      end
    end
  end
  return values
end

-- Return major tick values for a positive logarithmic range. Decade ticks
-- (1, 10, 100, ...) are preferred; narrow ranges fall back to 1/2/2.5/5
-- mantissas, and a range with no interior candidate uses its endpoints.
function M.generate_log(lo, hi, target)
  if not positive_finite(lo) or not positive_finite(hi) then
    return {}
  end
  if hi < lo then
    lo, hi = hi, lo
  end
  target = target or 6
  if type(target) ~= "number" or target < 2 then
    target = 2
  end
  target = math.min(math.floor(target), 20)

  local decades = decade_ticks(lo, hi, target)
  if #decades >= 2 then
    return decades
  end

  local best
  local best_score
  for _, mantissas in ipairs(LOG_MANTISSAS) do
    local values = mantissa_ticks(lo, hi, mantissas)
    if #values >= 2 then
      local score = math.abs(#values - target)
      if best == nil or score < best_score then
        best = values
        best_score = score
      end
    end
  end
  if best ~= nil then
    return best
  end

  if hi > lo then
    return { lo, hi }
  end
  return { lo }
end

local function sorted_major_values(major, lo, hi)
  local result = {}
  for index = 1, #(major or {}) do
    local value = major[index]
    if type(value) == "number" and value == value and value ~= math.huge and
        value ~= -math.huge and value >= lo and value <= hi then
      result[#result + 1] = value
    end
  end
  table.sort(result)
  return result
end

-- Return minor tick positions between the supplied major tick values. Linear
-- axes are subdivided into `subdivisions` equal parts per major interval
-- (five by default); logarithmic axes use the 2..9 mantissas of each decade.
-- Values that duplicate a major tick are omitted so major labels and major
-- grid lines remain unambiguous.
function M.generate_minor(lo, hi, major, scale, subdivisions)
  if type(lo) ~= "number" or type(hi) ~= "number" or lo ~= lo or hi ~= hi or
      lo == math.huge or hi == -math.huge or hi <= lo then
    return {}
  end
  local majors = sorted_major_values(major, lo, hi)
  if #majors == 0 then
    return {}
  end

  subdivisions = subdivisions or 5
  local values = {}
  local function append(value, tolerance)
    if value < lo - tolerance or value > hi + tolerance then
      return
    end
    if value < lo then value = lo end
    if value > hi then value = hi end
    for index = 1, #majors do
      local scale_value = math.max(1, math.abs(value), math.abs(majors[index]))
      if math.abs(value - majors[index]) <= tolerance * scale_value then
        return
      end
    end
    for index = 1, #values do
      local scale_value = math.max(1, math.abs(value), math.abs(values[index]))
      if math.abs(value - values[index]) <= tolerance * scale_value then
        return
      end
    end
    values[#values + 1] = value
  end

  if scale == "log" then
    if lo <= 0 or hi <= 0 then return {} end
    if util.log10(hi) - util.log10(lo) > 12 then return {} end
    local first = math.floor(util.log10(lo)) - 1
    local last = math.ceil(util.log10(hi))
    for exponent = first, last do
      local base = 10 ^ exponent
      for mantissa = 2, 9 do
        append(mantissa * base, 1e-10)
      end
    end
  else
    local minimum_step
    for index = 2, #majors do
      local delta = majors[index] - majors[index - 1]
      if delta > 0 and (minimum_step == nil or delta < minimum_step) then
        minimum_step = delta
      end
    end
    if minimum_step == nil or minimum_step <= 0 then
      return {}
    end
    local tolerance = minimum_step * 1e-9
    for index = 1, #majors - 1 do
      local span = majors[index + 1] - majors[index]
      if span > 0 then
        for part = 1, subdivisions - 1 do
          append(majors[index] + span * part / subdivisions, tolerance)
        end
      end
    end
    local delta = minimum_step / subdivisions
    local value = majors[1] - delta
    local guard = 0
    while value >= lo - tolerance and guard < 1000 do
      append(value, tolerance)
      value = value - delta
      guard = guard + 1
    end
    value = majors[#majors] + delta
    guard = 0
    while value <= hi + tolerance and guard < 1000 do
      append(value, tolerance)
      value = value + delta
      guard = guard + 1
    end
  end

  table.sort(values)
  return values
end

return M
