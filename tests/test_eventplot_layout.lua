local plt = require("luaplotlib")

local function event_attrs(svg)
  local result = {}
  for line in svg:gmatch('<line class="event"[^>]*/>') do
    local attrs = {}
    for key, value in line:gmatch('([%w:-]+)="([^"]*)"') do
      attrs[key] = value
    end
    result[#result + 1] = attrs
  end
  return result
end

test("eventplot preserves vertical defaults and exports scene data", function()
  local fig = plt.figure()
  fig:eventplot({ { 1, 2 }, { 3 } })
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)
  assert_contains(svg,
    'class="series series-eventplot" data-orientation="vertical" data-rows="2"')
  local events = event_attrs(svg)
  assert_equal(#events, 3)
  for _, event in ipairs(events) do
    assert_equal(event.x1, event.x2, "vertical events should be vertical lines")
    assert_true(tonumber(event["data-length"]) > 0)
  end
  local scene = fig:to_scene().series[1]
  assert_equal(scene.kind, "eventplot")
  assert_equal(scene.orientation, "vertical")
  assert_equal(#scene.rows, 2)
  assert_equal(scene.rows[2][1], 3)
  assert_equal(scene.lineoffsets[1], 1)
  assert_equal(scene.lineoffsets[2], 2)
  assert_equal(scene.linelengths[1], 0.8)
end)

test("eventplot horizontal layout uses y values and row offsets", function()
  local fig = plt.figure({ width = 700, height = 450 })
  fig:eventplot({ { 1, 2 }, { 3 } }, {
    orientation = "horizontal",
    lineoffsets = { 5, 6 },
    linelengths = { 0.5, 1 },
    label = "events",
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-orientation="horizontal"')
  assert_contains(svg, 'data-label="events"')
  local events = event_attrs(svg)
  assert_equal(#events, 3)
  for _, event in ipairs(events) do
    assert_equal(event.y1, event.y2, "horizontal events should be horizontal")
  end
  assert_equal(events[1]["data-row"], "1")
  assert_equal(events[1]["data-offset"], "5")
  assert_equal(events[1]["data-length"], "0.5")
  assert_equal(events[3]["data-row"], "2")
  assert_equal(events[3]["data-offset"], "6")

  local scene = fig:to_scene()
  assert_equal(scene.series[1].orientation, "horizontal")
  assert_equal(scene.series[1].lineoffsets[1], 5)
  assert_equal(scene.series[1].linelengths[1], 0.5)
  assert_true(scene.xlim[1] <= 4.75)
  assert_true(scene.xlim[2] >= 6.5)
  assert_true(scene.ylim[1] <= 1)
  assert_true(scene.ylim[2] >= 3)
end)

test("eventplot layout validates orientation, rows, and lengths", function()
  local fig = plt.figure()
  assert_error("orientation must be 'vertical' or 'horizontal'", function()
    fig:eventplot({ 1, 2 }, { orientation = "diagonal" })
  end)
  assert_error("one entry per row", function()
    fig:eventplot({ { 1 }, { 2 } }, { lineoffsets = { 1 } })
  end)
  assert_error("one entry per row", function()
    fig:eventplot({ { 1 }, { 2 } }, { linelengths = { 1, 2, 3 } })
  end)
  assert_error("linelengths must be >=", function()
    fig:eventplot({ 1, 2 }, { linelengths = 0 })
  end)
  assert_error("lineoffsets must be a number", function()
    fig:eventplot({ 1, 2 }, { lineoffsets = true })
  end)
end)
