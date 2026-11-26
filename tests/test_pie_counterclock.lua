local plt = require("luaplotlib")

test("pie defaults to clockwise slices", function()
  local fig = plt.figure()
  fig:pie({ 1, 1 })
  local scene = fig:to_scene().pie
  assert_equal(scene.counterclock, false)
  assert_true(scene.slices[1].end_angle < scene.slices[1].start_angle)
  assert_contains(fig:to_svg(), 'data-counterclock="false"')
end)

test("pie can run counterclockwise without dropping slices", function()
  local fig = plt.figure()
  fig:pie({ 1, 1, 2 }, { counterclock = true })
  local svg = fig:to_svg()
  assert_contains(svg, 'data-counterclock="true"')
  local slices = select(2, svg:gsub('class="pie%-slice"', ""))
  assert_equal(slices, 3)
  local scene = fig:to_scene().pie
  assert_equal(scene.counterclock, true)
  assert_true(scene.slices[1].end_angle > scene.slices[1].start_angle)
end)

test("pie counterclock validates the boolean", function()
  local fig = plt.figure()
  assert_error("counterclock must be a boolean", function()
    fig:pie({ 1, 2 }, { counterclock = "yes" })
  end)
end)
