-- Input normalization.
--
-- luaplotlib's core path accepts ordinary one-based Lua arrays. For optional
-- interop, luatorch-style tensors (`dim`, `numel`, `get`, `totable`, `shape`),
-- Torch7-style tensors (`nDimension`, `nElement`, numeric indexing), and small
-- array wrappers (`n`/`size` plus `data` or 1-based indexing) are also accepted.
-- Nothing from luatorch or numlua is required or loaded.

local util = require("luaplotlib.util")

local M = {}

local function fail(message)
  util.fail(message, 3)
end

local function finite(value)
  return util.is_finite(value)
end

local function checked_value(value, name, index)
  if type(value) ~= "number" then
    fail(string.format("%s[%d] must be a number, got %s", name, index, type(value)))
  end
  if not finite(value) then
    fail(string.format("%s[%d] must be finite", name, index))
  end
  return value
end

local function callable(obj, name)
  local ok, fn = pcall(function()
    return obj[name]
  end)
  if not ok or type(fn) ~= "function" then
    return false
  end
  return true, fn
end

local function method(obj, name, ...)
  local has, fn = callable(obj, name)
  if not has then
    return false
  end
  local ok_call, result = pcall(fn, obj, ...)
  if not ok_call then
    return false
  end
  return true, result
end

local function try_index(obj, index)
  local ok, value = pcall(function()
    return obj[index]
  end)
  if ok and value ~= nil then
    return value
  end
  return nil
end

-- Read a named field without assuming that the object's metatable allows
-- arbitrary field access (luatorch tensors raise for unknown fields).
local function field(obj, name)
  if type(obj) ~= "table" then
    return nil
  end
  local ok, value = pcall(function()
    return obj[name]
  end)
  if ok then
    return value
  end
  return nil
end

local TENSOR_METHODS = {
  "dim",
  "ndimension",
  "nDimension",
  "numel",
  "nElement",
  "get",
  "totable",
  "sizes",
  "shape",
  "size",
}

-- True for userdata objects and for table-backed proxies that expose a known
-- tensor/array accessor. Plain table arrays always take the plain-table path
-- and have no metatable in normal use.
function M.is_tensor_like(value)
  if type(value) == "userdata" then
    return true
  end
  if type(value) ~= "table" then
    return false
  end
  if getmetatable(value) == nil then
    return false
  end
  for i = 1, #TENSOR_METHODS do
    if callable(value, TENSOR_METHODS[i]) then
      return true
    end
  end
  return false
end

local function parse_shape(shape)
  if type(shape) ~= "table" or #shape == 0 then
    return nil
  end
  if #shape == 1 and type(shape[1]) == "number" then
    return shape[1]
  end
  if #shape > 1 then
    return nil, "only one-dimensional values are supported"
  end
  return nil
end

local function tensor_dimensions(obj)
  for _, name in ipairs({ "dim", "ndimension", "nDimension" }) do
    local ok, dimensions = method(obj, name)
    if ok and type(dimensions) == "number" then
      return dimensions
    end
  end
  if type(obj) == "table" then
    local ndim = field(obj, "ndim")
    if type(ndim) == "number" then
      return ndim
    end
    local dim = field(obj, "dim")
    if type(dim) == "number" then
      return dim
    end
  end
  return nil
end

local function get_n(obj)
  -- Prefer element counts. luatorch exposes numel(); Torch7 exposes
  -- nElement(); some array wrappers use n / size / shape fields.
  local ok, n = method(obj, "nElement")
  if ok and type(n) == "number" then
    return n, nil
  end

  ok, n = method(obj, "numel")
  if ok and type(n) == "number" then
    return n, nil
  end

  ok, n = method(obj, "size", 1)
  if ok and type(n) == "number" then
    return n, nil
  end

  ok, n = method(obj, "size")
  if ok then
    if type(n) == "number" then
      return n, nil
    elseif type(n) == "table" then
      local count, reason = parse_shape(n)
      if count ~= nil then
        return count, nil
      elseif reason ~= nil then
        return nil, reason
      end
    end
  end

  for _, name in ipairs({ "sizes", "shape" }) do
    local ok_shape, shape = method(obj, name)
    if ok_shape and type(shape) == "table" then
      local count, reason = parse_shape(shape)
      if count ~= nil then
        return count, nil
      elseif reason ~= nil then
        return nil, reason
      end
    end
  end

  if type(obj) == "table" then
    local raw_n = field(obj, "n")
    if type(raw_n) == "number" then
      return raw_n, nil
    end
    local raw_size = field(obj, "size")
    if type(raw_size) == "number" then
      return raw_size, nil
    elseif type(raw_size) == "table" then
      local count, reason = parse_shape(raw_size)
      if count ~= nil then
        return count, nil
      elseif reason ~= nil then
        return nil, reason
      end
    end
    local raw_shape = field(obj, "shape")
    if type(raw_shape) == "table" then
      local count, reason = parse_shape(raw_shape)
      if count ~= nil then
        return count, nil
      elseif reason ~= nil then
        return nil, reason
      end
    end
    local raw_data = field(obj, "data")
    if type(raw_data) == "table" and #raw_data > 0 then
      return #raw_data, "data"
    end
  end

  return nil, "could not determine its length"
end

local function read_tensor_values(obj, n, source, name)
  -- Prefer a single bulk conversion when the object provides one. This keeps
  -- luatorch's per-element FFI `get` dispatch off the hot path.
  local converted
  local ok_totable, table_value = method(obj, "totable")
  if ok_totable and type(table_value) == "table" and #table_value == n then
    converted = table_value
  end

  local has_get, get_fn
  if converted == nil then
    has_get, get_fn = callable(obj, "get")
  end
  local raw_data = field(obj, "data")
  local fallback_data = type(raw_data) == "table" or nil

  local out = {}
  for i = 1, n do
    local item
    if converted ~= nil then
      item = converted[i]
    elseif has_get then
      local ok_get, value = pcall(get_fn, obj, i)
      if ok_get and type(value) == "number" then
        item = value
      end
    elseif source == "data" then
      item = raw_data[i]
    else
      item = try_index(obj, i)
    end

    if item == nil and fallback_data then
      item = raw_data[i]
    end
    out[i] = checked_value(item, name, i)
  end
  return out
end

local function plain_sequence(value, name)
  local n = #value
  local out = {}
  for i = 1, n do
    out[i] = checked_value(value[i], name, i)
  end
  return out
end

-- Return a freshly allocated one-based Lua array of finite numbers.
function M.sequence(value, name)
  name = name or "value"
  local value_type = type(value)

  if value_type == "table" and not M.is_tensor_like(value) then
    if #value > 0 and type(value[1]) == "number" then
      return plain_sequence(value, name)
    end
    -- A plain empty table is empty data. Fieldless tables with metatables were
    -- handled by the tensor check above, so anything left is an ordinary data
    -- table (possibly with data/n fields) rather than a proxy.
    if next(value) == nil and getmetatable(value) == nil then
      fail(name .. " must not be empty")
    end
  end

  if value_type ~= "table" and value_type ~= "userdata" then
    fail(name .. " must be a non-empty numeric sequence, got " .. value_type)
  end

  -- Reject multi-dimensional values up front for a clear error.
  local dimensions = tensor_dimensions(value)
  if dimensions ~= nil and dimensions ~= 1 then
    if dimensions == 0 then
      fail(name .. " must be a one-dimensional sequence, not a scalar tensor")
    end
    fail(name .. " must be one-dimensional, got " .. tostring(dimensions) ..
      " dimensions")
  end

  local n, source = get_n(value)
  if type(n) ~= "number" or not finite(n) or n ~= math.floor(n) or n <= 0 then
    local reason = source or "invalid or empty length"
    fail(name .. " must be a non-empty numeric sequence (" .. reason .. ")")
  end
  if n > 10000000 then
    fail(name .. " is unreasonably large for SVG output (more than 10,000,000 values)")
  end

  return read_tensor_values(value, n, source, name)
end

-- Validate the category labels used by fig:bar. Mixed string/number labels
-- are accepted because categories are only ever rendered as text.
-- Validate a rectangular 2-D numeric table and return rows, cols, values.
function M.matrix(value, name)
  if M.is_tensor_like(value) then
    local dimensions = tensor_dimensions(value)
    if dimensions ~= 2 then
      error("luaplotlib: " .. name .. " must be a 2-D tensor", 3)
    end
    local ok, converted = method(value, "totable")
    if not ok or type(converted) ~= "table" then
      error("luaplotlib: " .. name .. " tensor does not expose totable()", 3)
    end
    value = converted
  end
  if type(value) ~= "table" then
    error("luaplotlib: " .. name .. " must be a 2-D table", 3)
  end
  local rows = #value
  if rows == 0 then
    error("luaplotlib: " .. name .. " must contain at least one row", 3)
  end
  local cols
  local result = {}
  for r = 1, rows do
    local row = value[r]
    if type(row) ~= "table" then
      error("luaplotlib: " .. name .. " row " .. r .. " must be a table", 3)
    end
    if cols == nil then
      cols = #row
      if cols == 0 then
        error("luaplotlib: " .. name .. " rows must be non-empty", 3)
      end
    elseif #row ~= cols then
      error("luaplotlib: " .. name .. " rows must have equal length", 3)
    end
    result[r] = {}
    for c = 1, cols do
      local v = row[c]
      if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
        error("luaplotlib: " .. name .. " contains a non-finite value at " ..
          r .. "," .. c, 3)
      end
      result[r][c] = v
    end
  end
  return rows, cols, result
end

function M.labels(value, name)
  name = name or "labels"
  if type(value) ~= "table" or #value == 0 then
    fail(name .. " must be a non-empty list")
  end
  local out = {}
  for i = 1, #value do
    local item = value[i]
    if type(item) == "string" then
      out[i] = item
    elseif type(item) == "number" and finite(item) then
      out[i] = tostring(item)
    else
      fail(string.format("%s[%d] must be a string or finite number, got %s",
        name, i, type(item)))
    end
  end
  return out
end

-- Inspect a bar x argument that is an ordinary table. Returns either
-- ("categories", labels) or ("numeric", values).
function M.bar_x(value, name)
  name = name or "x"
  if type(value) ~= "table" or M.is_tensor_like(value) then
    return "numeric", M.sequence(value, name)
  end

  if #value == 0 then
    fail(name .. " must not be empty")
  end

  local has_string = false
  for i = 1, #value do
    local item = value[i]
    if type(item) == "string" then
      has_string = true
      break
    elseif type(item) ~= "number" then
      fail(string.format("%s[%d] must be a string or number, got %s", name, i, type(item)))
    end
  end

  if has_string then
    return "categories", M.labels(value, name)
  end
  return "numeric", M.sequence(value, name)
end

return M
