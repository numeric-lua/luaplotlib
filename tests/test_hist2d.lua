local plt = require("luaplotlib")

local function sum_attribute(text, class, attribute)
  local total = 0
  local name = attribute:gsub("%-", "%%-")
  local escaped_class = class:gsub("%-", "%%-")
  for value in text:gmatch('class="' .. escaped_class .. '"[^>]*' .. name ..
      '="([0-9.]+)"') do
    total = total + tonumber(value)
  end
  return total
end

local function sample_points()
  local x, y = {}, {}
  local pairs_ = {
    { 0.2, 0.2 }, { 0.4, 0.3 }, { 0.8, 0.4 }, { 1.2, 0.7 },
    { 1.4, 1.1 }, { 1.6, 1.3 }, { 1.8, 1.5 }, { 1.9, 1.8 },
    { 0.6, 1.6 }, { 1.1, 1.9 }, { 0.9, 0.9 }, { 1.5, 0.9 },
  }
  for index, pair in ipairs(pairs_) do
    x[index], y[index] = pair[1], pair[2]
  end
  return x, y
end

test("hist2d counts paired samples into rectangular cells", function()
  local x, y = sample_points()
  local fig = plt.figure({ width = 720, height = 480 })
  fig:hist2d(x, y, {
    bins = { 4, 3 }, label = "samples", colorbar_label = "count",
  })
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)
  assert_contains(svg,
    'class="series series-hist2d" data-points="12" data-inside="12" ' ..
    'data-bins-x="4" data-bins-y="3" data-norm="count"')
  assert_contains(svg, 'data-label="samples"')
  local cells = count_occurrences(svg, 'class="hist2d-cell"')
  assert_true(cells > 0 and cells <= 12)
  assert_equal(sum_attribute(svg, "hist2d-cell", "data-count"), 12)
  assert_contains(svg, 'class="colorbar hist2d-colorbar"')
  assert_contains(svg, 'data-norm="count"')
  assert_contains(svg, 'class="colorbar-title"')
  assert_contains(svg, '>count</text>')
  local ticks = tonumber(svg:match('data%-ticks="([0-9]+)"'))
  assert_equal(ticks, 3)
  assert_equal(count_occurrences(svg, 'class="colorbar-label"'), ticks)

  local scene = fig:to_scene()
  local exported = scene.series[1]
  assert_equal(exported.kind, "hist2d")
  assert_equal(exported.bins_x, 4)
  assert_equal(exported.bins_y, 3)
  assert_equal(exported.point_count, 12)
  assert_equal(exported.inside_count, 12)
  assert_equal(#exported.edges_x, 5)
  assert_equal(#exported.edges_y, 4)
  assert_equal(#exported.cells, cells)
  assert_equal(#exported.counts, cells)
  local total = 0
  for _, count in ipairs(exported.counts) do total = total + count end
  assert_equal(total, 12)
  assert_equal(exported.colorbar, true)
  assert_equal(exported.colorbar_label, "count")
  assert_true(scene.xlim[1] < 0.2 and scene.xlim[2] > 1.9)
  assert_true(scene.ylim[1] < 0.2 and scene.ylim[2] > 1.9)
end)

test("hist2d density normalizes by in-range count and cell area", function()
  local fig = plt.figure({ width = 640, height = 440 })
  fig:hist2d({ 0.5, 0.5, 0.5, 1.5 }, { 0.5, 0.5, 0.5, 1.5 }, {
    bins = { 2, 2 }, range = { 0, 2, 0, 2 }, density = true,
  })
  local scene = fig:to_scene().series[1]
  assert_equal(scene.density, true)
  assert_equal(#scene.cells, 2)
  local values = {}
  for _, cell in ipairs(scene.cells) do
    values[cell.row .. ":" .. cell.column] = cell.value
  end
  assert_true(math.abs(values["1:1"] - 0.75) < 1e-12)
  assert_true(math.abs(values["2:2"] - 0.25) < 1e-12)
  local svg = fig:to_svg()
  assert_contains(svg, 'data-norm="density"')
  assert_contains(svg, 'data-value="0.75"')
end)

test("hist2d range, explicit values, and lone bins are supported", function()
  local fig = plt.figure({ width = 640, height = 440 })
  fig:hist2d({ -5, 0.2, 0.4, 0.8, 1.1, 9 }, { -5, 0.3, 0.4, 0.7, 1.2, 9 }, {
    bins = 2, range = { 0, 1, 0, 1 }, vmin = 1, vmax = 4,
    colorbar_tick_values = { 1, 2, 4 },
  })
  local scene = fig:to_scene().series[1]
  assert_equal(scene.inside_count, 3)
  assert_equal(scene.point_count, 6)
  assert_equal(scene.edges_x[1], 0)
  assert_equal(scene.edges_x[3], 1)
  assert_equal(scene.vmin, 1)
  assert_equal(scene.vmax, 4)
  assert_equal(scene.colorbar_tick_values[3], 4)
  local svg = fig:to_svg()
  assert_contains(svg, 'data-tick-source="explicit"')
  assert_equal(count_occurrences(svg, 'class="colorbar-label"'), 3)

  local lone = plt.figure()
  lone:hist2d({ 2 }, { 3 }, { bins = 1, colorbar = false })
  local lone_svg = lone:to_svg()
  assert_not_contains(lone_svg, 'class="colorbar"')
  assert_equal(count_occurrences(lone_svg, 'class="hist2d-cell"'), 1)
  assert_equal(lone:to_scene().series[1].colorbar, false)
end)

test("hist2d validation rejects malformed grids and options", function()
  local fig = plt.figure()
  assert_error("same length", function() fig:hist2d({ 1, 2 }, { 1 }) end)
  assert_error("must not be empty", function() fig:hist2d({}, {}) end)
  assert_error("bins", function() fig:hist2d({ 1 }, { 1 }, { bins = 0 }) end)
  assert_error("bins", function()
    fig:hist2d({ 1 }, { 1 }, { bins = { 2 } })
  end)
  assert_error("range", function()
    fig:hist2d({ 1 }, { 1 }, { range = { 0, 1 } })
  end)
  assert_error("xmax", function()
    fig:hist2d({ 1 }, { 1 }, { range = { 1, 1, 0, 1 } })
  end)
  assert_error("ymax", function()
    fig:hist2d({ 1 }, { 1 }, { range = { 0, 1, 1, 1 } })
  end)
  assert_error("density", function()
    fig:hist2d({ 1 }, { 1 }, { density = "yes" })
  end)
  assert_error("cannot both be set", function()
    fig:hist2d({ 1 }, { 1 }, {
      colorbar_ticks = 2, colorbar_tick_values = { 1, 2 },
    })
  end)
  assert_error("colorbar_tick_values", function()
    fig:hist2d({ 1 }, { 1 }, { colorbar_tick_values = {} })
  end)
  assert_error("linewidth", function()
    fig:hist2d({ 1 }, { 1 }, { linewidth = -1 })
  end)
  assert_error("edgecolor", function()
    fig:hist2d({ 1 }, { 1 }, { edgecolor = "not a color!" })
  end)
end)
