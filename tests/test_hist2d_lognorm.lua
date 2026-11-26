local plt = require("luaplotlib")

test("hist2d defaults to linear color normalization", function()
  local fig = plt.figure()
  fig:hist2d({ 1, 1, 2, 3 }, { 1, 1, 2, 2 }, { colorbar = false })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-color-norm="linear"')
  local series = fig:to_scene().series[1]
  assert_equal(series.color_norm, "linear")
  assert_equal(series.cells[1].color_value, series.cells[1].value)
end)

test("hist2d log color norm transforms cell colors", function()
  local fig = plt.figure()
  fig:hist2d({ 1, 1, 1, 2, 3, 3 }, { 1, 1, 2, 2, 3, 3 }, {
    color_norm = "log", colorbar = true, colorbar_ticks = 3,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-color-norm="log"')
  local series = fig:to_scene().series[1]
  assert_equal(series.color_norm, "log")
  for _, cell in ipairs(series.cells) do
    assert_true(math.abs(cell.color_value - math.log(1 + cell.value)) < 1e-12)
  end
  assert_contains(svg, 'class="colorbar hist2d-colorbar"')
end)

test("hist2d log color norm validates norm and range", function()
  local fig = plt.figure()
  assert_error("color_norm must be 'linear' or 'log'", function()
    fig:hist2d({ 1, 2 }, { 1, 2 }, { color_norm = "sqrt" })
  end)
  assert_error("requires vmin >= 0", function()
    fig:hist2d({ 1, 2 }, { 1, 2 }, { color_norm = "log", vmin = -1 })
  end)
end)
