local plt = require("luaplotlib")

local function rect_attrs(svg)
  local result = {}
  for rect in svg:gmatch('<rect class="broken%-barh"[^>]*/>') do
    local attrs = {}
    for key, value in rect:gmatch('([%w:-]+)="([^"]*)"') do
      attrs[key] = value
    end
    result[#result + 1] = attrs
  end
  return result
end

test("broken_barh draws one rectangle per x range", function()
  local fig = plt.figure({ width = 720, height = 460 })
  fig:broken_barh({ { 0, 2 }, { 3, 1.5 } }, { 1, 0.6 }, {
    color = "#4c78a8", label = "phase", linewidth = 2,
  })
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)
  assert_contains(svg,
    'class="series series-broken-barh" data-y="1" data-height="0.6"')
  assert_contains(svg, 'data-label="phase"')
  local rects = rect_attrs(svg)
  assert_equal(#rects, 2)
  assert_equal(rects[1]["data-start"], "0")
  assert_equal(rects[1]["data-width"], "2")
  assert_equal(rects[2]["data-start"], "3")
  assert_equal(rects[2]["data-width"], "1.5")
  assert_equal(rects[1]["stroke-width"], "2")
  assert_true(tonumber(rects[1].width) > 0)
  assert_true(tonumber(rects[1].height) > 0)
end)

test("broken_barh exports ranges and participates in automatic ranging", function()
  local fig = plt.figure()
  fig:broken_barh({ { 10, 5 }, { 20, 4 } }, { 3, 2 })
  local scene = fig:to_scene()
  local series = scene.series[1]
  assert_equal(series.kind, "broken_barh")
  assert_equal(#series.ranges, 2)
  assert_equal(series.ranges[1][1], 10)
  assert_equal(series.ranges[1][2], 5)
  assert_equal(series.ranges[2][1], 20)
  assert_equal(series.y, 3)
  assert_equal(series.height, 2)
  assert_true(scene.xlim[1] <= 10)
  assert_true(scene.xlim[2] >= 24)
  assert_true(scene.ylim[1] <= 3)
  assert_true(scene.ylim[2] >= 5)
end)

test("broken_barh validates ranges, y range, and width", function()
  local fig = plt.figure()
  assert_error("non%-empty", function() fig:broken_barh({}, { 1, 1 }) end)
  assert_error("{start, width}", function()
    fig:broken_barh({ { 1 } }, { 1, 1 })
  end)
  assert_error("must be >= 1e%-06", function()
    fig:broken_barh({ { 1, 0 } }, { 1, 1 })
  end)
  assert_error("{y, height}", function() fig:broken_barh({ { 1, 1 } }, { 1 }) end)
  assert_error("height must be >= 1e%-06", function()
    fig:broken_barh({ { 1, 1 } }, { 1, 0 })
  end)
  assert_error("linewidth must be >= 0", function()
    fig:broken_barh({ { 1, 1 } }, { 1, 1 }, { linewidth = -1 })
  end)
end)
