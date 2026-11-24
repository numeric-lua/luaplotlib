local plt = require("luaplotlib")

local function colorbar_labels(svg)
  local labels = {}
  for label in svg:gmatch('<text class="colorbar%-label"[^>]*>[^<]*</text>') do
    local value = label:match('data%-value="([^"]*)"')
    labels[#labels + 1] = value
  end
  return labels
end

test("imshow keeps its legacy colorbar without explicit options", function()
  local fig = plt.figure()
  fig:imshow({ { 1, 2 }, { 3, 4 } })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="colorbar"')
  assert_not_contains(svg, "imshow-colorbar")
  assert_not_contains(svg, 'class="colorbar-label"')
  assert_equal(#colorbar_labels(svg), 0)
end)

test("imshow supports a title and explicit colorbar ticks", function()
  local fig = plt.figure({ width = 700, height = 480 })
  fig:imshow({ { 1, 2 }, { 3, 4 } }, {
    colorbar_label = "value", colorbar_tick_values = { 1.5, 2.5, 3.5 },
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="colorbar imshow-colorbar"')
  assert_contains(svg, 'data-tick-source="explicit"')
  assert_contains(svg, 'data-ticks="3"')
  assert_contains(svg, 'class="colorbar-title"')
  local labels = colorbar_labels(svg)
  assert_equal(#labels, 3)
  assert_equal(labels[1], "1.5")
  assert_equal(labels[3], "3.5")
  local image = fig:to_scene().series[1]
  assert_equal(image.colorbar, true)
  assert_equal(image.colorbar_label, "value")
  assert_equal(image.colorbar_tick_values[2], 2.5)
end)

test("imshow supports uniform colorbar tick counts", function()
  local fig = plt.figure()
  fig:imshow({ { 0, 1 }, { 2, 3 } }, {
    vmin = 0, vmax = 4, colorbar_ticks = 4, colorbar_label = "density",
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-tick-source="uniform"')
  assert_contains(svg, 'data-ticks="4"')
  assert_equal(#colorbar_labels(svg), 4)
  assert_equal(fig:to_scene().series[1].colorbar_ticks, 4)
end)

test("imshow colorbar options validate ranges and combinations", function()
  local fig = plt.figure()
  assert_error("colorbar_ticks and colorbar_tick_values cannot both be set",
    function()
      fig:imshow({ { 1, 2 }, { 3, 4 } }, {
        colorbar_ticks = 3, colorbar_tick_values = { 1, 2, 3 },
      })
    end)
  assert_error("colorbar_tick_values%[1%] must be within vmin and vmax",
    function()
      fig:imshow({ { 1, 2 }, { 3, 4 } }, {
        colorbar_tick_values = { 0, 5 },
      })
    end)
  assert_error("colorbar_tick_values%[2%] must be strictly increasing",
    function()
      fig:imshow({ { 1, 2 }, { 3, 4 } }, {
        colorbar_tick_values = { 3, 2 },
      })
    end)
  assert_error("colorbar_ticks must be an integer", function()
    fig:imshow({ { 1, 2 }, { 3, 4 } }, { colorbar_ticks = 2.5 })
  end)
  assert_error("colorbar_label must be a string", function()
    fig:imshow({ { 1, 2 }, { 3, 4 } }, { colorbar_label = 7 })
  end)
end)
