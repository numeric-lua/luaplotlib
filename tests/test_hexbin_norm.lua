local plt = require("luaplotlib")

test("hexbin defaults to linear count colors", function()
  local fig = plt.figure()
  fig:hexbin({ 1, 1, 2, 3 }, { 1, 2, 2, 3 }, { colorbar = false })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-norm="linear"')
  local series = fig:to_scene().series[1]
  assert_equal(series.norm, "linear")
  assert_equal(series.cells[1].color_value, series.cells[1].count)
end)

test("hexbin log norm transforms cell colors and colorbar ticks", function()
  local fig = plt.figure()
  fig:hexbin({ 1, 1, 1, 2, 3, 3 }, { 1, 1, 2, 2, 3, 3 }, {
    norm = "log", colorbar = true, colorbar_ticks = 3,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-norm="log"')
  local series = fig:to_scene().series[1]
  assert_equal(series.norm, "log")
  assert_true(series.color_vmin < series.vmin or series.vmin == 0)
  for _, cell in ipairs(series.cells) do
    assert_true(math.abs(cell.color_value - math.log(1 + cell.count)) < 1e-12)
  end
  assert_contains(svg, 'class="colorbar hexbin-colorbar"')
  assert_contains(svg, 'class="colorbar-label"')
end)

test("hexbin log norm validates norm and non-negative vmin", function()
  local fig = plt.figure()
  assert_error("norm must be 'linear' or 'log'", function()
    fig:hexbin({ 1, 2 }, { 1, 2 }, { norm = "sqrt" })
  end)
  assert_error("requires vmin >= 0", function()
    fig:hexbin({ 1, 2 }, { 1, 2 }, { norm = "log", vmin = -1 })
  end)
end)
