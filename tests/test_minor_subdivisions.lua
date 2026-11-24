local plt = require("luaplotlib")
local ticks = require("luaplotlib.ticks")

local function minor_marks(svg)
  local count = 0
  for _ in svg:gmatch('<line class="minor%-tick%-mark"[^>]*/>') do
    count = count + 1
  end
  return count
end

test("minor tick subdivisions default to five and report metadata", function()
  local fig = plt.figure()
  fig:plot({ 1, 2, 3 }, { 1, 4, 9 })
  fig:minorticks(true)
  local svg = fig:to_svg()
  assert_contains(svg, 'data-minor-subdivisions="5"')
  assert_equal(fig:to_scene().minor_subdivisions, 5)
  local defaults = ticks.generate_minor(0, 10, { 0, 5, 10 }, "linear")
  assert_equal(#defaults, 8)
  for index, expected in ipairs({ 1, 2, 3, 4, 6, 7, 8, 9 }) do
    assert_equal(defaults[index], expected)
  end
end)

test("minor tick subdivisions control linear spacing", function()
  local values = ticks.generate_minor(0, 10, { 0, 5, 10 }, "linear", 4)
  assert_equal(#values, 6)
  for index, expected in ipairs({ 1.25, 2.5, 3.75, 6.25, 7.5, 8.75 }) do
    assert_true(math.abs(values[index] - expected) < 1e-9,
      "unexpected subdivision tick " .. tostring(values[index]))
  end

  local fig = plt.figure({ width = 700, height = 450 })
  fig:plot({ 1, 2, 3 }, { 1, 4, 9 })
  fig:minorticks(true, { subdivisions = 4 })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-minor-subdivisions="4"')
  assert_true(minor_marks(svg) > 0, "expected minor tick marks")
  assert_equal(fig:to_scene().minor_subdivisions, 4)
end)

test("minor grid uses the configured subdivision count", function()
  local fig = plt.figure({ width = 700, height = 450 })
  fig:plot({ 0, 5, 10 }, { 0, 5, 10 })
  fig:minorticks(true, { axis = "x", subdivisions = 3 })
  fig:grid(true, { minor = true, axis = "x" })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-minor-subdivisions="3"')
  local marks = 0
  local grid_lines = 0
  for _ in svg:gmatch('<line class="minor%-tick%-mark"[^>]*/>') do
    marks = marks + 1
  end
  for _ in svg:gmatch('<line class="minor%-grid%-line"[^>]*/>') do
    grid_lines = grid_lines + 1
  end
  assert_true(marks > 0, "expected minor tick marks")
  assert_equal(grid_lines, marks)
end)

test("minor subdivisions preserve logarithmic mantissa ticks", function()
  local values = ticks.generate_minor(1, 100, { 1, 10, 100 }, "log", 4)
  local seen = {}
  for _, value in ipairs(values) do seen[value] = true end
  assert_true(seen[2] and seen[5] and seen[20] and seen[90],
    "log minor ticks must keep every mantissa")
  assert_false(seen[1.25], "log axes should not use linear subdivisions")
end)

test("minor subdivisions validate their range and type", function()
  local fig = plt.figure()
  assert_error("subdivisions must be an integer", function()
    fig:minorticks(true, { subdivisions = 2.5 })
  end)
  assert_error("subdivisions must be >= 2", function()
    fig:minorticks(true, { subdivisions = 1 })
  end)
  assert_error("subdivisions must be <= 10", function()
    fig:minorticks(true, { subdivisions = 11 })
  end)
  assert_error("unsupported minorticks option", function()
    fig:minorticks(true, { step = 4 })
  end)
end)
