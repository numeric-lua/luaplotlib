local plt = require("luaplotlib")

test("quiver renders decimated Cartesian arrows and scene metadata", function()
  local x, y, u, v = {}, {}, {}, {}
  for index = 1, 10 do
    x[index], y[index] = index, index % 3
    u[index], v[index] = 1, (index % 2 == 0) and 1 or -1
  end
  local fig = plt.figure({ width = 640, height = 420 })
  fig:quiver(x, y, u, v, {
    color = "#1f77b4", label = "vectors", max_arrows = 3,
    pivot = "middle", normalize = true,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'class="series series-quiver" data-count="10" data-drawn="3" data-stride="4"')
  assert_contains(svg, 'data-max-arrows="3"')
  assert_contains(svg, 'data-scale-mode="auto"')
  assert_contains(svg, 'data-pivot="middle"')
  assert_contains(svg, 'data-normalize="true"')
  assert_contains(svg, 'data-label="vectors"')
  assert_equal(count_occurrences(svg, 'class="quiver-arrow"'), 3)
  assert_equal(count_occurrences(svg, 'class="quiver-shaft"'), 3)
  assert_equal(count_occurrences(svg, 'class="quiver-head"'), 3)
  assert_contains(svg, 'data-magnitude="1.414"')
  assert_well_formed_svg(svg)

  local scene = fig:to_scene()
  assert_equal(#scene.series, 1)
  local exported = scene.series[1]
  assert_equal(exported.kind, "quiver")
  assert_equal(exported.x[4], 4)
  assert_equal(exported.u[4], 1)
  assert_equal(exported.v[4], 1)
  assert_equal(exported.scale_mode, "auto")
  assert_equal(exported.scale_unit, "screen_multiplier")
  assert_equal(exported.pivot, "middle")
  assert_equal(exported.max_arrows, 3)
  assert_equal(exported.stride, 4)
  assert_equal(exported.drawn, 3)
  assert_equal(exported.normalize, true)
end)

test("quiver honors explicit scale, zero vectors, and log axes", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:quiver({ 1, 10, 100, 1000 }, { 1, 2, 3, 4 },
    { 1, 1, 0, 1 }, { 0, 0, 0, 1 }, {
      scale = 20, pivot = "tip", label = "flow",
    })
  fig:xscale("log")
  fig:legend()
  local svg = fig:to_svg()
  assert_contains(svg, 'data-count="4" data-drawn="3" data-stride="1"')
  assert_contains(svg, 'data-scale="20" data-scale-mode="explicit"')
  assert_contains(svg, 'data-pivot="tip"')
  assert_contains(svg, 'class="legend"')
  assert_equal(count_occurrences(svg, 'class="quiver-arrow"'), 3)
  assert_well_formed_svg(svg)
end)

test("quiver validates vector lengths and options", function()
  local fig = plt.figure()
  assert_error("same length", function()
    fig:quiver({ 1, 2 }, { 1, 2 }, { 1 }, { 0, 1 })
  end)
  assert_error("pivot", function()
    fig:quiver({ 1 }, { 1 }, { 1 }, { 0 }, { pivot = "center" })
  end)
  assert_error("positive", function()
    fig:quiver({ 1 }, { 1 }, { 1 }, { 0 }, { scale = 0 })
  end)
  assert_error("max_arrows", function()
    fig:quiver({ 1 }, { 1 }, { 1 }, { 0 }, { max_arrows = 0 })
  end)
  assert_error("normalize", function()
    fig:quiver({ 1 }, { 1 }, { 1 }, { 0 }, { normalize = "yes" })
  end)
  assert_error("unsupported quiver option", function()
    fig:quiver({ 1 }, { 1 }, { 1 }, { 0 }, { width = 3 })
  end)
  assert_error("head", function()
    fig:quiver({ 1 }, { 1 }, { 1 }, { 0 }, { head = -1 })
  end)
end)
