local plt = require("luaplotlib")
local ticks = require("luaplotlib.ticks")

local function line_attrs(line)
  local attrs = {}
  for key, value in line:gmatch('(%w+)="([^"]*)"') do
    attrs[key] = value
  end
  return attrs
end

local function minor_tick_lines(svg)
  local result = {}
  for line in svg:gmatch('<line class="minor%-tick%-mark"[^>]*/>') do
    result[#result + 1] = line_attrs(line)
  end
  return result
end

local function minor_grid_lines(svg)
  local result = {}
  for line in svg:gmatch('<line class="minor%-grid%-line"[^>]*/>') do
    result[#result + 1] = line_attrs(line)
  end
  return result
end

test("minor ticks and minor grids are off by default", function()
  local fig = plt.figure()
  fig:plot({ 1, 2, 3 }, { 1, 2, 3 })
  fig:grid(true)
  local svg = fig:to_svg()
  assert_not_contains(svg, "minor-tick-mark")
  assert_not_contains(svg, "grid-minor")
  assert_contains(svg, 'data-minorticks="none"')
  assert_contains(svg, 'data-minor-grid="false"')
  local scene = fig:to_scene()
  assert_equal(scene.minorticks, false, "scene minorticks default")
  assert_equal(scene.minor_grid, false, "scene minor grid default")
end)

test("minorticks draws marks on both axes and reports metadata", function()
  local fig = plt.figure({ width = 700, height = 450 })
  fig:plot({ 1, 2, 3 }, { 1, 4, 9 })
  fig:minorticks(true)
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)
  assert_contains(svg, 'data-minorticks="both"')
  local marks = minor_tick_lines(svg)
  assert_true(#marks > 0, "expected minor tick marks")
  local vertical, horizontal = 0, 0
  for _, attrs in ipairs(marks) do
    if attrs.x1 == attrs.x2 then vertical = vertical + 1 end
    if attrs.y1 == attrs.y2 then horizontal = horizontal + 1 end
  end
  assert_true(vertical > 0, "expected x minor ticks")
  assert_true(horizontal > 0, "expected y minor ticks")
  local scene = fig:to_scene()
  assert_equal(scene.minorticks, true, "scene minorticks flag")
  assert_equal(scene.minor_tick_axis, "both", "scene minor tick axis")
end)

test("minorticks axis filtering only draws the requested axis", function()
  local fig = plt.figure()
  fig:plot({ 1, 2, 3 }, { 1, 2, 3 })
  fig:minorticks(true, { axis = "x" })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-minorticks="x"')
  local marks = minor_tick_lines(svg)
  assert_true(#marks > 0, "expected x minor ticks")
  for _, attrs in ipairs(marks) do
    assert_equal(attrs.x1, attrs.x2, "x-only minor ticks should be vertical")
  end

  local y_fig = plt.figure()
  y_fig:plot({ 1, 2, 3 }, { 1, 2, 3 })
  y_fig:minorticks({ axis = "y" })
  assert_contains(y_fig:to_svg(), 'data-minorticks="y"')
  for _, attrs in ipairs(minor_tick_lines(y_fig:to_svg())) do
    assert_equal(attrs.y1, attrs.y2, "y-only minor ticks should be horizontal")
  end
end)

test("minor grid lines are separate from minor tick marks", function()
  local fig = plt.figure()
  fig:plot({ 1, 2, 3 }, { 1, 2, 3 })
  fig:grid(true, { axis = "y", minor = true })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-minor-grid="true"')
  assert_contains(svg, 'data-minorticks="none"')
  assert_contains(svg, 'class="grid-minor"')
  assert_not_contains(svg, "minor-tick-mark")
  local lines = minor_grid_lines(svg)
  assert_true(#lines > 0, "expected minor grid lines")
  for _, attrs in ipairs(lines) do
    assert_equal(attrs.y1, attrs.y2, "y-axis minor grid lines should be horizontal")
  end
  assert_equal(fig:to_scene().minor_grid, true, "scene minor grid flag")
end)

test("minor tick generation excludes major values on linear and log axes", function()
  local linear = ticks.generate_minor(0, 10, { 0, 5, 10 }, "linear")
  local seen = {}
  for _, value in ipairs(linear) do seen[value] = true end
  for _, expected in ipairs({ 1, 2, 3, 4, 6, 7, 8, 9 }) do
    assert_true(seen[expected], "missing linear minor tick " .. expected)
  end
  assert_false(seen[0], "major value 0 must not become a minor tick")
  assert_false(seen[5], "major value 5 must not become a minor tick")
  assert_false(seen[10], "major value 10 must not become a minor tick")

  local logarithmic = ticks.generate_minor(1, 100, { 1, 10, 100 }, "log")
  local log_seen = {}
  for _, value in ipairs(logarithmic) do log_seen[value] = true end
  assert_true(log_seen[2] and log_seen[20] and log_seen[90],
    "log minor ticks should cover 2..9 mantissas")
  assert_false(log_seen[1], "log major value 1 must not repeat")
  assert_false(log_seen[10], "log major value 10 must not repeat")
end)

test("minorticks validates options and errors clearly", function()
  local fig = plt.figure()
  assert_error("boolean", function() fig:minorticks("yes") end)
  assert_error("axis must be x, y, or both", function()
    fig:minorticks(true, { axis = "z" })
  end)
  assert_error("unsupported minorticks option", function()
    fig:minorticks(true, { color = "#000000" })
  end)
  assert_error("boolean", function() fig:grid(true, { minor = "yes" }) end)
end)
