local plt = require("luaplotlib")

local function sample_points(count)
  local x, y = {}, {}
  for index = 1, count do
    x[index] = 3 * math.sin(index * 0.37) + 0.2 * math.cos(index * 1.7)
    y[index] = 2 * math.cos(index * 0.23) + 0.1 * math.sin(index * 2.1)
  end
  return x, y
end

local function sum_attribute(text, attribute)
  local total = 0
  local name = attribute:gsub("%-", "%%-")
  for value in text:gmatch('class="hexbin%-cell"[^>]*' .. name ..
      '="([0-9]+)"') do
    total = total + tonumber(value)
  end
  return total
end

test("hexbin aggregates points into filled cells with a colorbar", function()
  local x, y = sample_points(240)
  local fig = plt.figure({ width = 640, height = 460 })
  fig:hexbin(x, y, {
    gridsize = 10, label = "density", colorbar_label = "count",
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="series series-hexbin" data-bins="')
  assert_contains(svg, 'data-points="240" data-gridsize="10" data-mincnt="1"')
  assert_contains(svg, 'data-label="density"')
  assert_true(count_occurrences(svg, 'class="hexbin-cell"') > 0)
  assert_equal(sum_attribute(svg, "data-count"), 240)
  assert_contains(svg, 'class="colorbar hexbin-colorbar"')
  assert_contains(svg, 'data-orientation="vertical"')
  assert_contains(svg, 'class="colorbar-title"')
  assert_contains(svg, '>count</text>')
  local ticks = tonumber(svg:match('data%-ticks="([0-9]+)"'))
  assert_equal(ticks, 3)
  assert_equal(count_occurrences(svg, 'class="colorbar-label"'), ticks)
  assert_well_formed_svg(svg)

  local scene = fig:to_scene()
  local exported = scene.series[1]
  assert_equal(exported.kind, "hexbin")
  assert_equal(exported.point_count, 240)
  assert_equal(exported.gridsize, 10)
  assert_equal(exported.mincnt, 1)
  assert_equal(exported.colorbar, true)
  assert_equal(exported.colorbar_label, "count")
  assert_true(#exported.cells > 0)
  assert_equal(#exported.cells, #exported.counts)
  local total = 0
  for _, count in ipairs(exported.counts) do total = total + count end
  assert_equal(total, 240)
  assert_true(scene.xlim[1] < -2)
  assert_true(scene.ylim[2] > 1)
end)

test("hexbin supports mincnt, explicit colors, and explicit ticks", function()
  local fig = plt.figure({ width = 620, height = 440 })
  fig:hexbin({ 1, 1.1, 1.2, 5, 5.1, 9 }, { 1, 1.1, 0.9, 5, 5.2, 9 }, {
    gridsize = 6, mincnt = 2, vmin = 2, vmax = 8,
    colorbar_tick_values = { 2, 4, 8 }, edgecolor = "#334455",
    linewidth = 1.2, alpha = 0.7,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-mincnt="2"')
  assert_contains(svg, 'data-vmin="2" data-vmax="8"')
  assert_contains(svg, 'data-tick-source="explicit"')
  assert_equal(count_occurrences(svg, 'class="colorbar-label"'), 3)
  assert_contains(svg, 'data-value="8"')
  assert_contains(svg, 'stroke="#334455" stroke-width="1.2" fill-opacity="0.7"')
  local scene = fig:to_scene()
  assert_equal(scene.series[1].colorbar_tick_values[3], 8)
  assert_equal(scene.series[1].style.alpha, 0.7)
end)

test("hexbin handles repeated points and can omit the colorbar", function()
  local fig = plt.figure({ width = 480, height = 320 })
  fig:hexbin({ 2, 2, 2, 2 }, { 3, 3, 3, 3 }, {
    gridsize = 4, colorbar = false,
  })
  local svg = fig:to_svg()
  assert_equal(count_occurrences(svg, 'class="hexbin-cell"'), 1)
  assert_contains(svg, 'data-count="4"')
  assert_contains(svg, 'data-vmin="3.5" data-vmax="4.5"')
  assert_not_contains(svg, 'class="colorbar"')
  local scene = fig:to_scene()
  assert_equal(scene.series[1].colorbar, false)
  assert_equal(scene.series[1].vmin, 3.5)
  assert_equal(scene.series[1].vmax, 4.5)
end)

test("hexbin validates grids, counts, and colorbar options", function()
  local fig = plt.figure()
  assert_error("same length", function()
    fig:hexbin({ 1, 2 }, { 1 })
  end)
  assert_error("must not be empty", function()
    fig:hexbin({}, {})
  end)
  assert_error("gridsize", function()
    fig:hexbin({ 1 }, { 1 }, { gridsize = 1 })
  end)
  assert_error("mincnt", function()
    fig:hexbin({ 1, 2 }, { 1, 2 }, { mincnt = 3 })
  end)
  assert_error("vmax must be greater", function()
    fig:hexbin({ 1 }, { 1 }, { vmin = 5, vmax = 5 })
  end)
  assert_error("cannot both be set", function()
    fig:hexbin({ 1 }, { 1 }, {
      colorbar_ticks = 2, colorbar_tick_values = { 1, 2 },
    })
  end)
  assert_error("colorbar", function()
    fig:hexbin({ 1 }, { 1 }, { colorbar = "yes" })
  end)
  assert_error("colorbar_tick_values", function()
    fig:hexbin({ 1 }, { 1 }, { colorbar_tick_values = {} })
  end)
end)
