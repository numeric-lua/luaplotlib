local plt = require("luaplotlib")

local function count(svg, pattern)
  return select(2, svg:gsub(pattern, ""))
end

test("violin means are opt-in and exported in the scene", function()
  local fig = plt.figure()
  fig:violinplot({ { 1, 2, 3, 4, 5 } })
  local svg = fig:to_svg()
  assert_not_contains(svg, "violin-mean-marker")
  assert_not_contains(svg, "violin-mean-line")
  local violin = fig:to_scene().series[1]
  assert_equal(violin.mean, 3)
  assert_equal(violin.showmeans, false)
  assert_equal(violin.meanline, false)
end)

test("violin showmeans draws one marker per sample", function()
  local fig = plt.figure()
  fig:violinplot({ { 1, 2, 3, 4, 5 }, { 2, 3, 4 } }, { showmeans = true })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-showmeans="true"')
  assert_equal(count(svg, 'class="violin%-mean%-marker"'), 2)
  assert_equal(count(svg, 'class="violin%-mean%-line"'), 0)
  local violins = fig:to_scene().series
  assert_equal(violins[1].mean, 3)
  assert_equal(violins[2].mean, 3)
  assert_equal(violins[1].showmeans, true)
end)

test("violin meanline draws a dashed width line", function()
  local fig = plt.figure()
  fig:violinplot({ { 1, 2, 3, 4, 5 } }, {
    showmeans = true, meanline = true,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-meanline="true"')
  assert_equal(count(svg, 'class="violin%-mean%-line"'), 1)
  assert_equal(count(svg, 'class="violin%-mean%-marker"'), 0)
  assert_contains(svg, 'stroke-dasharray="4 2"')
  local violin = fig:to_scene().series[1]
  assert_equal(violin.meanline, true)
end)

test("violin mean options validate booleans", function()
  local fig = plt.figure()
  assert_error("boolean", function()
    fig:violinplot({ { 1, 2 } }, { showmeans = "yes" })
  end)
  assert_error("boolean", function()
    fig:violinplot({ { 1, 2 } }, { meanline = 0 })
  end)
end)
