local plt = require("luaplotlib")

local function count(svg, pattern)
  return select(2, svg:gsub(pattern, ""))
end

test("errorbar draws every error bar by default", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2, 3, 4 }, { 1, 2, 3, 4 }, { 0.1, 0.2, 0.3, 0.4 })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-errorevery="1"')
  assert_contains(svg, 'data-error-points="4"')
  assert_equal(count(svg, 'class="errorbar"'), 4)
  assert_equal(fig:to_scene().series[1].errorevery, 1)
end)

test("errorbar errorevery decimates error bars but keeps the line", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2, 3, 4, 5 }, { 1, 2, 3, 4, 5 },
    { 0.1, 0.2, 0.3, 0.4, 0.5 }, { errorevery = 2 })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-errorevery="2"')
  assert_contains(svg, 'data-error-points="3"')
  assert_equal(count(svg, 'class="errorbar"'), 3)
  assert_equal(count(svg, 'class="errorbar%-cap"'), 6)
  local line = svg:match('<polyline class="line" points="([^"]*)"')
  assert_true(line ~= nil, "the connected line should still be drawn")
  local vertices = 0
  for _ in line:gmatch("[^ ]+") do vertices = vertices + 1 end
  assert_equal(vertices, 5)
  assert_equal(fig:to_scene().series[1].errorevery, 2)
end)

test("errorbar errorevery works with horizontal errors", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2, 3, 4 }, { 1, 2, 3, 4 }, 0.2, 0.15, {
    errorevery = 3,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-error-points="2"')
  assert_equal(count(svg, 'class="errorbar"'), 4)
  assert_equal(count(svg, 'class="errorbar%-cap"'), 8)
end)

test("errorbar errorevery validates positive integers", function()
  local fig = plt.figure()
  assert_error("errorevery must be an integer", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, { errorevery = 1.5 })
  end)
  assert_error("errorevery must be >= 1", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, 0.1, { errorevery = 0 })
  end)
end)
