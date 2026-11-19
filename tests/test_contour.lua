local plt = require("luaplotlib")

test("renders marching-squares contour lines", function()
  local fig = plt.figure({ width = 640, height = 480 })
  fig:contour({
    { 0, 0, 0 },
    { 0, 1, 0 },
    { 0, 0, 0 },
  }, { levels = 2, color = "#d62728", label = "level" })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="contour"')
  assert_true(select(2, svg:gsub('class="contour%-segment"', "")) > 0)
  local path = (TMPDIR or "/tmp") .. "/luaplotlib-contour.svg"
  assert_equal(fig:savefig(path), path)
  os.remove(path)
end)

test("contour validates matrix and level inputs", function()
  local fig = plt.figure()
  assert_error("equal length", function() fig:contour({ { 1, 2 }, { 3 } }) end)
  assert_error("levels must be", function()
    fig:contour({ { 1, 2 }, { 3, 4 } }, { levels = 0 })
  end)
  assert_error("non%-empty", function()
    fig:contour({ { 1, 2 }, { 3, 4 } }, { levels = {} })
  end)
end)
