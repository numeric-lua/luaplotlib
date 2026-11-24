local plt = require("luaplotlib")

local function count(svg, pattern)
  return select(2, svg:gsub(pattern, ""))
end

local function polyline_points(svg, className)
  local body = svg:match('<polyline class="' .. className .. '" points="([^"]*)"')
  assert_true(body ~= nil, "missing polyline " .. className)
  local points = {}
  for pair in body:gmatch("[^ ]+") do
    local x, y = pair:match("([^,]+),([^,]+)")
    points[#points + 1] = { tonumber(x), tonumber(y) }
  end
  return points
end

test("histtype bar keeps the existing rectangle rendering", function()
  local fig = plt.figure()
  fig:hist({ 1, 2, 2, 3, 3, 3 }, { bins = 3, range = { 1, 3 } })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-histtype="bar"')
  assert_equal(count(svg, 'class="hist%-bin"'), 3)
  assert_not_contains(svg, "hist-step")
  assert_equal(fig:to_scene().series[1].histtype, "bar")
end)

test("histtype step draws one stepped outline", function()
  local fig = plt.figure()
  fig:hist({ 1, 2, 2, 3, 3, 3 }, {
    bins = 3, range = { 1, 3 }, histtype = "step", label = "step",
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-histtype="step"')
  assert_contains(svg, 'data-label="step"')
  assert_equal(count(svg, 'class="hist%-bin"'), 0)
  assert_equal(count(svg, 'class="hist%-step"'), 1)
  local points = polyline_points(svg, "hist%-step")
  assert_equal(#points, 2 + 3 * 2)
  assert_equal(points[1][2], points[#points][2],
    "the outline should start and end on the zero baseline")
  assert_equal(fig:to_scene().series[1].histtype, "step")
end)

test("histtype stepfilled draws a closed filled staircase", function()
  local fig = plt.figure()
  fig:hist({ 1, 2, 2, 3, 3, 3 }, {
    bins = 3, range = { 1, 3 }, histtype = "stepfilled",
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-histtype="stepfilled"')
  assert_equal(count(svg, 'class="hist%-bin"'), 0)
  assert_equal(count(svg, 'class="hist%-step%-filled"'), 1)
  assert_contains(svg, '<polygon class="hist-step-filled"')
  assert_equal(fig:to_scene().series[1].histtype, "stepfilled")
end)

test("horizontal step histograms use y edges and x counts", function()
  local fig = plt.figure({ width = 700, height = 450 })
  fig:hist({ 1, 2, 2, 3, 3, 3 }, {
    bins = 3, range = { 1, 3 }, orientation = "horizontal",
    histtype = "step",
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-orientation="horizontal"')
  local points = polyline_points(svg, "hist%-step")
  assert_equal(#points, 2 + 3 * 2)
  assert_equal(points[1][1], points[#points][1],
    "horizontal step outlines return to the x baseline")
end)

test("histtype validates accepted names", function()
  local fig = plt.figure()
  assert_error("histtype must be 'bar', 'step', or 'stepfilled'", function()
    fig:hist({ 1, 2, 3 }, { histtype = "line" })
  end)
end)
