local plt = require("luaplotlib")

test("scatter maps numeric c values through the heat palette", function()
  local fig = plt.figure({ width = 720, height = 460 })
  fig:scatter({ 1, 2, 3, 4 }, { 2, 4, 3, 5 }, {
    c = { 0, 2, 5, 10 }, colorbar_label = "intensity", label = "samples",
  })
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)
  assert_contains(svg,
    'class="series series-scatter" data-label="samples" ' ..
    'data-color-values="true" data-vmin="0" data-vmax="10"')
  assert_contains(svg, 'class="colorbar scatter-colorbar"')
  assert_contains(svg, 'data-norm="linear"')
  assert_contains(svg, 'class="colorbar-title"')
  assert_contains(svg, '>intensity</text>')
  assert_equal(count_occurrences(svg, 'class="colorbar-label"'), 3)
  assert_equal(count_occurrences(svg, 'class="point"'), 4)
  local fills = {}
  for fill in svg:gmatch('<circle class="point"[^>]*fill="([^"]+)"') do
    fills[#fills + 1] = fill
  end
  assert_equal(#fills, 4)
  assert_true(fills[1] ~= fills[4], "different values should map to colors")

  local scene = fig:to_scene().series[1]
  assert_equal(scene.kind, "scatter")
  assert_equal(scene.c[3], 5)
  assert_equal(scene.color_values[4], 10)
  assert_equal(scene.vmin, 0)
  assert_equal(scene.vmax, 10)
  assert_equal(scene.colorbar, true)
  assert_equal(scene.colorbar_label, "intensity")
  assert_equal(scene.colors[4], fills[4])
end)

test("scatter c supports explicit ranges, ticks, and no colorbar", function()
  local fig = plt.figure({ width = 640, height = 440 })
  fig:scatter({ 1, 2 }, { 3, 4 }, {
    c = { -2, 8 }, vmin = -4, vmax = 12, colorbar = false,
    edgecolor = "#222222", linewidth = 1.5,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-vmin="-4" data-vmax="12"')
  assert_not_contains(svg, 'class="colorbar"')
  assert_contains(svg, 'stroke="#222222" stroke-width="1.5"')
  local scene = fig:to_scene().series[1]
  assert_equal(scene.vmin, -4)
  assert_equal(scene.vmax, 12)
  assert_equal(scene.colorbar, false)
  assert_true(scene.colors[1] ~= scene.colors[2])
end)

test("scatter c pads a degenerate numeric range", function()
  local fig = plt.figure()
  fig:scatter({ 1, 2 }, { 2, 3 }, { c = { 5, 5 } })
  local scene = fig:to_scene().series[1]
  assert_equal(scene.vmin, 4.5)
  assert_equal(scene.vmax, 5.5)
  assert_contains(fig:to_svg(), 'data-vmin="4.5" data-vmax="5.5"')
end)

test("scatter per-point color arrays keep their original behavior", function()
  local fig = plt.figure()
  fig:scatter({ 1, 2 }, { 2, 3 }, { color = { "#112233", "#445566" } })
  local svg = fig:to_svg()
  assert_contains(svg, 'fill="#112233"')
  assert_contains(svg, 'fill="#445566"')
  assert_not_contains(svg, 'data-color-values')
  assert_not_contains(svg, 'class="colorbar"')
  local scene = fig:to_scene().series[1]
  assert_equal(scene.colors[2], "#445566")
  assert_equal(scene.c, nil)
end)

test("scatter color mapping validates c and colorbar options", function()
  local fig = plt.figure()
  assert_error("c must match", function()
    fig:scatter({ 1, 2 }, { 1, 2 }, { c = { 1 } })
  end)
  assert_error("c must be a table", function()
    fig:scatter({ 1 }, { 1 }, { c = 2 })
  end)
  assert_error("cannot both be set", function()
    fig:scatter({ 1, 2 }, { 1, 2 }, { c = { 1, 2 }, color = "#000000" })
  end)
  assert_error("require c", function()
    fig:scatter({ 1 }, { 1 }, { vmin = 0 })
  end)
  assert_error("require c", function()
    fig:scatter({ 1 }, { 1 }, { colorbar = true })
  end)
  assert_error("vmax must be greater", function()
    fig:scatter({ 1 }, { 1 }, { c = { 1 }, vmin = 3, vmax = 2 })
  end)
  assert_error("colorbar_ticks", function()
    fig:scatter({ 1 }, { 1 }, { c = { 1 }, colorbar_ticks = 1 })
  end)
  assert_error("cannot both be set", function()
    fig:scatter({ 1 }, { 1 }, {
      c = { 1 }, colorbar_ticks = 2, colorbar_tick_values = { 0, 1 },
    })
  end)
  assert_error("c%[2%]", function()
    fig:scatter({ 1, 2 }, { 1, 2 }, { c = { 1, 0 / 0 } })
  end)
end)
