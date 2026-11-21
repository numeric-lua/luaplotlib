-- Dependency-free approximate text metrics for layout decisions.
--
-- luaplotlib does not embed or load fonts.  Layout code still needs a better
-- estimate than "one width for every character" so that labels containing
-- wide glyphs (M, W, m, w) or narrow glyphs (i, l, punctuation) do not spill
-- out of their legend or annotation boxes.  The advance widths below are
-- rounded Helvetica/Arial values in units of 1/1000 em; they are estimates,
-- not a font engine, and the renderer continues to leave final shaping to the
-- SVG viewer.

local M = {}

local ADVANCE = {
  [" "] = 278, ["!"] = 278, ['"'] = 355, ["#"] = 556, ["$"] = 556,
  ["%"] = 889, ["&"] = 667, ["'"] = 191, ["("] = 333, [")"] = 333,
  ["*"] = 389, ["+"] = 584, [","] = 278, ["-"] = 333, ["."] = 278,
  ["/"] = 278, [":"] = 278, [";"] = 278, ["<"] = 584, ["="] = 584,
  [">"] = 584, ["?"] = 556, ["@"] = 1015, ["["] = 278, ["\\"] = 278,
  ["]"] = 278, ["^"] = 469, ["_"] = 556, ["`"] = 333, ["{"] = 334,
  ["|"] = 260, ["}"] = 334, ["~"] = 584,
}

local UPPER = {
  A = 667, B = 667, C = 722, D = 722, E = 667, F = 611, G = 778, H = 722,
  I = 278, J = 500, K = 667, L = 556, M = 833, N = 722, O = 778, P = 667,
  Q = 778, R = 722, S = 667, T = 611, U = 722, V = 667, W = 944, X = 667,
  Y = 667, Z = 611,
}

local LOWER = {
  a = 556, b = 556, c = 500, d = 556, e = 556, f = 278, g = 556, h = 556,
  i = 222, j = 222, k = 500, l = 222, m = 833, n = 556, o = 556, p = 556,
  q = 556, r = 333, s = 500, t = 278, u = 556, v = 500, w = 722, x = 500,
  y = 500, z = 500,
}

for code = string.byte("0"), string.byte("9") do
  ADVANCE[string.char(code)] = 556
end
for letter, width in pairs(UPPER) do ADVANCE[letter] = width end
for letter, width in pairs(LOWER) do ADVANCE[letter] = width end

local DEGREE = 0x00B0
local MULTIPLICATION = 0x00D7
local MINUS = 0x2212
local REPLACEMENT = 0xFFFD

-- Return the codepoint and byte length of the UTF-8 sequence starting at `i`.
-- Malformed bytes are treated as one replacement-width character so layout
-- never loops forever on bad input.
local function decode(text, index)
  local byte = text:byte(index)
  if byte == nil then return nil, 0 end
  if byte < 0x80 then return byte, 1 end
  if byte >= 0xC2 and byte <= 0xDF then
    local second = text:byte(index + 1)
    if second ~= nil and second >= 0x80 and second <= 0xBF then
      return (byte - 0xC0) * 0x40 + (second - 0x80), 2
    end
  elseif byte >= 0xE0 and byte <= 0xEF then
    local second = text:byte(index + 1)
    local third = text:byte(index + 2)
    if second ~= nil and third ~= nil and second >= 0x80 and second <= 0xBF
        and third >= 0x80 and third <= 0xBF then
      return (byte - 0xE0) * 0x1000 + (second - 0x80) * 0x40 +
        (third - 0x80), 3
    end
  elseif byte >= 0xF0 and byte <= 0xF4 then
    local second = text:byte(index + 1)
    local third = text:byte(index + 2)
    local fourth = text:byte(index + 3)
    if second ~= nil and third ~= nil and fourth ~= nil
        and second >= 0x80 and second <= 0xBF
        and third >= 0x80 and third <= 0xBF
        and fourth >= 0x80 and fourth <= 0xBF then
      return (byte - 0xF0) * 0x40000 + (second - 0x80) * 0x1000 +
        (third - 0x80) * 0x40 + (fourth - 0x80), 4
    end
  end
  return REPLACEMENT, 1
end

M.decode = decode

-- Number of Unicode codepoints (not bytes).  Kept for callers that only need
-- a count, such as debugging metadata.
function M.count(text)
  if type(text) ~= "string" then return 0 end
  local count, index = 0, 1
  while index <= #text do
    local _, length = decode(text, index)
    if length == 0 then break end
    count = count + 1
    index = index + length
  end
  return count
end

local function advance(codepoint)
  if codepoint < 0x80 then
    return ADVANCE[string.char(codepoint)] or 556
  elseif codepoint == DEGREE then
    return 400
  elseif codepoint == MULTIPLICATION or codepoint == MINUS then
    return 584
  elseif codepoint < 0x0300 then
    return 500
  elseif codepoint < 0x2000 or codepoint == REPLACEMENT then
    return 600
  elseif codepoint >= 0x2E80 then
    -- CJK/Hangul/full-width forms are approximately one em wide.
    return 1000
  end
  return 600
end

-- Estimated advance width of `text` in SVG user units at `fontsize`.
function M.measure(text, fontsize)
  if type(text) ~= "string" or text == "" then return 0 end
  if fontsize == nil then fontsize = 12 end
  local total = 0
  local index = 1
  while index <= #text do
    local codepoint, length = decode(text, index)
    if length == 0 then break end
    total = total + advance(codepoint)
    index = index + length
  end
  return total * fontsize / 1000
end

-- Approximate box around a single-line SVG `<text>` element.  `baseline` is
-- the SVG y coordinate and `anchor` is "start", "middle", or "end".
function M.bounds(x, baseline, value, fontsize, anchor)
  local width = M.measure(value, fontsize)
  local left = x
  if anchor == "middle" then
    left = x - width / 2
  elseif anchor == "end" then
    left = x - width
  end
  return {
    x = left,
    y = baseline - fontsize * 0.85,
    width = width,
    height = fontsize * 1.15,
  }
end

return M
