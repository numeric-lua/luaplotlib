local plt = require("luaplotlib")

test("annotations have no background by default", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 1, 2 })
  fig:annotate("peak", 1, 2)
  assert_not_contains(fig:to_svg(), "annotation-background")
  assert_equal(fig:to_scene().annotations[1].background, nil)
end)

test("cartesian annotation backgrounds render color, edge, alpha, and pad", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 1, 2 })
  fig:annotate("peak", 1, 2, {
    backgroundcolor = "#ffffff",
    backgroundedgecolor = "#334155",
    backgroundalpha = 0.55,
    backgroundpad = 5,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="annotation-background"')
  assert_contains(svg, 'fill="#ffffff" fill-opacity="0.55" stroke="#334155"')
  local background = fig:to_scene().annotations[1].background
  assert_equal(background.color, "#ffffff")
  assert_equal(background.edgecolor, "#334155")
  assert_equal(background.alpha, 0.55)
  assert_equal(background.pad, 5)
end)

test("polar annotations support the same background box", function()
  local fig = plt.figure({ width = 480, height = 480 })
  fig:polar({ 0, 1 }, { 1, 1 })
  fig:annotate("peak", 0.5, 2, {
    backgroundcolor = "#fef3c7", backgroundedgecolor = "#92400e",
    backgroundalpha = 0.8, backgroundpad = 4,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="annotation-background"')
  assert_contains(svg, 'fill="#fef3c7" fill-opacity="0.8" stroke="#92400e"')
  local scene = fig:to_scene()
  local annotation = scene.annotations[1]
  assert_equal(annotation.background.color, "#fef3c7")
  assert_equal(annotation.background.pad, 4)
end)

test("annotation background options validate color and dependent fields", function()
  local fig = plt.figure()
  assert_error("background options require backgroundcolor", function()
    fig:annotate("x", 1, 1, { backgroundpad = 4 })
  end)
  assert_error("backgroundcolor", function()
    fig:annotate("x", 1, 1, { backgroundcolor = "12bad" })
  end)
  assert_error("backgroundalpha must be <= 1", function()
    fig:annotate("x", 1, 1, {
      backgroundcolor = "#ffffff", backgroundalpha = 1.5,
    })
  end)
  assert_error("backgroundpad must be >= 0", function()
    fig:annotate("x", 1, 1, {
      backgroundcolor = "#ffffff", backgroundpad = -1,
    })
  end)
end)
