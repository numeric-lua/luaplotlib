local plt = require("luaplotlib")

local function cell_count(svg)
  return select(2, svg:gsub('class="hist2d%-cell"', ""))
end

test("hist2d omits empty cells by default", function()
  local fig = plt.figure()
  fig:hist2d({ 1, 1, 2 }, { 1, 2, 3 }, {
    bins = { 2, 2 }, range = { 0, 3, 0, 4 }, colorbar = false,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-show-empty="false"')
  assert_true(cell_count(svg) < 4)
  assert_equal(fig:to_scene().series[1].show_empty, false)
end)

test("hist2d show_empty includes zero-count cells", function()
  local fig = plt.figure()
  fig:hist2d({ 1, 1, 2 }, { 1, 2, 3 }, {
    bins = { 2, 2 }, range = { 0, 3, 0, 4 },
    colorbar = false, show_empty = true,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-show-empty="true"')
  assert_equal(cell_count(svg), 4)
  local zero_cells = select(2, svg:gsub(
    'class="hist2d%-cell"[^>]*data%-count="0"', ""))
  assert_true(zero_cells > 0)
  local series = fig:to_scene().series[1]
  assert_equal(series.show_empty, true)
  assert_equal(#series.cells, 4)
  assert_true(series.cells[1].count == 0 or series.cells[2].count == 0)
end)

test("hist2d show_empty validates the boolean", function()
  local fig = plt.figure()
  assert_error("show_empty must be a boolean", function()
    fig:hist2d({ 1, 2 }, { 1, 2 }, { show_empty = "yes" })
  end)
end)
