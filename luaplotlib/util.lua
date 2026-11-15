-- Small dependency-free helpers shared by luaplotlib modules.

local M = {}

local function fail(message, level)
  error("luaplotlib: " .. tostring(message), level or 2)
end

M.fail = fail

local function finite(n)
  return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

M.is_finite = finite

-- Base-10 logarithm implemented via math.log so the result is available on
-- every supported Lua version (math.log10 is not present everywhere).
function M.log10(value)
  return math.log(value) / math.log(10)
end

function M.check_number(value, name, min, max)
  if type(value) ~= "number" then
    fail(name .. " must be a number, got " .. type(value), 3)
  end
  if not finite(value) then
    fail(name .. " must be finite", 3)
  end
  if min ~= nil and value < min then
    fail(string.format("%s must be >= %s, got %s", name, tostring(min), tostring(value)), 3)
  end
  if max ~= nil and value > max then
    fail(string.format("%s must be <= %s, got %s", name, tostring(max), tostring(value)), 3)
  end
  return value
end

function M.check_integer(value, name, min, max)
  if type(value) ~= "number" or not finite(value) or value ~= math.floor(value) then
    fail(name .. " must be an integer, got " .. tostring(value), 3)
  end
  return M.check_number(value, name, min, max)
end

function M.check_boolean(value, name)
  if type(value) ~= "boolean" then
    fail(name .. " must be a boolean, got " .. type(value), 3)
  end
  return value
end

function M.check_string(value, name, allow_empty)
  if type(value) ~= "string" then
    fail(name .. " must be a string, got " .. type(value), 3)
  end
  if value == "" and not allow_empty then
    fail(name .. " must not be empty", 3)
  end
  return value
end

function M.check_options(opts, allowed, context)
  if opts == nil then
    return {}
  end
  if type(opts) ~= "table" then
    fail(context .. " options must be a table, got " .. type(opts), 3)
  end
  for key in pairs(opts) do
    if not allowed[key] then
      fail(string.format("unsupported %s option %q", context, tostring(key)), 3)
    end
  end
  return opts
end

function M.check_color(color, name)
  if type(color) ~= "string" then
    fail(name .. " must be a color string, got " .. type(color), 3)
  end
  local hex3 = color:match("^#%x%x%x$")
  local hex6 = color:match("^#%x%x%x%x%x%x$")
  local named = color:match("^[%a][%a%-]*$")
  if not (hex3 or hex6 or named) then
    fail(name .. " must be a #RGB, #RRGGBB, or CSS color name, got " .. string.format("%q", color), 3)
  end
  return color
end

function M.check_alpha(alpha, name)
  return M.check_number(alpha, name, 0, 1)
end

-- Format a coordinate or pixel size for SVG. Keep the output compact and
-- avoid locale-sensitive formatting.
function M.fmt(n)
  if type(n) ~= "number" or not finite(n) then
    fail("internal error: tried to format a non-finite SVG number", 2)
  end
  if math.abs(n) < 0.0005 then
    n = 0
  end
  local s = string.format("%.3f", n)
  s = s:gsub("0+$", ""):gsub("%.$", "")
  if s == "-0" then
    return "0"
  end
  return s
end

-- A short human-readable tick label without unnecessary trailing zeros.
function M.fmt_tick(n)
  if type(n) ~= "number" or not finite(n) then
    return ""
  end
  if n == 0 or math.abs(n) < 1e-12 then
    return "0"
  end
  local s = string.format("%.6g", n)
  s = s:gsub("e%+0*", "e"):gsub("e%-0*", "e-")
  if s == "-0" then
    s = "0"
  end
  return s
end

-- Escape user-controlled text for XML text nodes and quoted attributes.
-- Invalid XML 1.0 control bytes are replaced with U+FFFD. Valid UTF-8 bytes
-- are preserved so labels can be written in any language.
function M.escape_xml(value)
  if type(value) ~= "string" then
    fail("XML text must be a string", 2)
  end
  local cleaned = {}
  for i = 1, #value do
    local b = value:byte(i)
    if (b < 32 and b ~= 9 and b ~= 10 and b ~= 13) or b == 127 then
      cleaned[#cleaned + 1] = "\239\191\189" -- U+FFFD replacement character
    else
      cleaned[#cleaned + 1] = string.char(b)
    end
  end
  local text = table.concat(cleaned)
  local entities = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&apos;",
  }
  return (text:gsub("[&<>\"']", entities))
end

return M
