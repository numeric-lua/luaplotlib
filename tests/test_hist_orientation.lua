local plt = require("luaplotlib")

local function attrs(tag)
  local result = {}
  for key, value in tag:gmatch('([%w:-]+)="([^"]*)"') do result[key] = value end
  return result
end

local function hist_bins(svg)
  local result = {}
  for rect in svg:gmatch('<rect class="hist%-bin"[^>]*/>') do
    result[#result + 1] = attrs(rect)
  end
  return result
end

test("horizontal histograms grow bins along x from zero", function()
  local fig = plt.figure({ width = 700, height = 450 })
  fig:hist({ 1, 2, 2, 3, 3, 3 }, {
    bins = 3, range = { 1, 3 }, orientation = "horizontal", label = "counts",
  })
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)
  assert_contains(svg, 'data-orientation="horizontal"')
  assert_contains(svg, 'data-label="counts"')
  local bins = hist_bins(svg)
  assert_equal(#bins, 3)
  assert_true(tonumber(bins[3].y) < tonumber(bins[1].y),
    "bins should progress upward with increasing data value")
  assert_true(tonumber(bins[1].height) > 0)
  assert_true(tonumber(bins[3].height) > 0)
  assert_true(tonumber(bins[3].width) > tonumber(bins[2].width),
    "the tallest count should produce the widest horizontal bin")
  assert_equal(tonumber(bins[1].x), tonumber(bins[2].x),
    "all horizontal bins share the zero baseline")

  local scene = fig:to_scene().series[1]
  assert_equal(scene.kind, "hist")
  assert_equal(scene.orientation, "horizontal")
  assert_equal(scene.counts[1], 1)
  assert_equal(scene.counts[2], 2)
  assert_equal(scene.counts[3], 3)
  assert_true(fig:to_scene().xlim[1] <= 0)
  assert_true(fig:to_scene().xlim[2] >= 3)
  assert_true(fig:to_scene().ylim[1] <= 1)
  assert_true(fig:to_scene().ylim[2] >= 3)
end)

test("vertical histograms keep their existing orientation and metadata", function()
  local fig = plt.figure()
  fig:hist({ 1, 2, 3 }, { bins = 2 })
  local svg = fig:to_svg()
  assert_not_contains(svg, 'data-orientation="horizontal"')
  local scene = fig:to_scene()
  assert_equal(scene.series[1].orientation, "vertical")
  assert_true(scene.xlim[1] <= 1 and scene.xlim[2] >= 3)
  assert_true(scene.ylim[1] <= 0, "vertical histograms include the zero baseline")
end)

test("horizontal histograms support density and cumulative counts", function()
  local density = plt.figure()
  density:hist({ 1, 1, 2, 3 }, {
    bins = 2, range = { 1, 3 }, density = true, orientation = "horizontal",
  })
  local values = density:to_scene().series[1].counts
  assert_true(math.abs(values[1] - 0.5) < 1e-9)
  assert_true(math.abs(values[2] - 0.5) < 1e-9)

  local cumulative = plt.figure()
  cumulative:hist({ 1, 1, 2, 3 }, {
    bins = 2, range = { 1, 3 }, cumulative = true,
    orientation = "horizontal",
  })
  local counts = cumulative:to_scene().series[1].counts
  assert_equal(counts[1], 2)
  assert_equal(counts[2], 4)
end)

test("horizontal histograms clip a log-x baseline to the plot edge", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:hist({ 1, 2, 3 }, { bins = 2, orientation = "horizontal" })
  fig:xscale("log")
  local svg = fig:to_svg()
  local bins = hist_bins(svg)
  assert_equal(#bins, 2)
  for _, bin in ipairs(bins) do
    assert_true(tonumber(bin.x) >= 72,
      "log-x histogram bins should start at the plot left edge")
    assert_true(tonumber(bin.width) > 0)
  end
end)

test("hist orientation validation rejects unknown values", function()
  local fig = plt.figure()
  assert_error("orientation must be 'vertical' or 'horizontal'", function()
    fig:hist({ 1, 2, 3 }, { orientation = "diagonal" })
  end)
  assert_error("orientation must be 'vertical' or 'horizontal'", function()
    fig:hist({ 1, 2, 3 }, { orientation = true })
  end)
end)
