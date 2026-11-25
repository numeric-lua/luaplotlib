local plt = require("luaplotlib")

local function stem_lines(svg)
  local result = {}
  for line in svg:gmatch('<line class="stem%-line"[^>]*/>') do
    local attrs = {}
    for key, value in line:gmatch('([%w:-]+)="([^"]*)"') do
      attrs[key] = value
    end
    result[#result + 1] = attrs
  end
  return result
end

test("stem is vertical by default", function()
  local fig = plt.figure()
  fig:stem({ 1, 2 }, { 3, 4 })
  local lines = stem_lines(fig:to_svg())
  assert_equal(#lines, 2)
  assert_equal(lines[1].x1, lines[1].x2)
  assert_equal(fig:to_scene().series[1].orientation, "vertical")
end)

test("horizontal stems grow along x from the base", function()
  local fig = plt.figure()
  fig:stem({ 1, 2 }, { 3, 4 }, { base = 0.5, orientation = "horizontal" })
  local svg = fig:to_svg()
  local lines = stem_lines(svg)
  assert_equal(#lines, 2)
  for _, line in ipairs(lines) do
    assert_equal(line.y1, line.y2, "horizontal stems should be horizontal")
  end
  assert_contains(svg, 'data-orientation="horizontal"')
  local scene = fig:to_scene()
  assert_equal(scene.series[1].orientation, "horizontal")
  assert_equal(scene.series[1].base, 0.5)
  assert_true(scene.xlim[1] <= 0.5)
  assert_true(scene.xlim[2] >= 4)
  assert_true(scene.ylim[1] <= 1)
  assert_true(scene.ylim[2] >= 2)
end)

test("stem orientation validates accepted values", function()
  local fig = plt.figure()
  assert_error("orientation must be 'vertical' or 'horizontal'", function()
    fig:stem({ 1, 2 }, { 1, 2 }, { orientation = "diagonal" })
  end)
end)
