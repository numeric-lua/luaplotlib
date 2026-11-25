local plt = require("luaplotlib")

local function hatched(svg, klass)
  return select(2, svg:gsub('class="' .. klass .. '"[^>]*fill="url%(#hatch%-', ""))
end

test("histograms are unhatched by default", function()
  local fig = plt.figure()
  fig:hist({ 1, 2, 2, 3 }, { bins = 2, range = { 1, 3 } })
  local svg = fig:to_svg()
  assert_not_contains(svg, '<pattern id="hatch-')
  assert_equal(fig:to_scene().series[1].style.hatch, nil)
end)

test("bar and stepfilled histograms support hatch patterns", function()
  local bars = plt.figure()
  bars:hist({ 1, 2, 2, 3 }, { bins = 2, range = { 1, 3 }, hatch = "/" })
  assert_contains(bars:to_svg(), '<pattern id="hatch-')
  assert_equal(hatched(bars:to_svg(), "hist%-bin"), 2)
  assert_equal(bars:to_scene().series[1].style.hatch, "/")

  local filled = plt.figure()
  filled:hist({ 1, 2, 2, 3 }, {
    bins = 2, range = { 1, 3 }, histtype = "stepfilled", hatch = ".",
  })
  assert_contains(filled:to_svg(), '<pattern id="hatch-')
  assert_equal(hatched(filled:to_svg(), "hist%-step%-filled"), 1)
  assert_equal(filled:to_scene().series[1].style.hatch, ".")
end)

test("hist hatch rejects step outlines and invalid patterns", function()
  local fig = plt.figure()
  assert_error("requires bar or stepfilled", function()
    fig:hist({ 1, 2 }, { histtype = "step", hatch = "/" })
  end)
  assert_error("hatch must be", function()
    fig:hist({ 1, 2 }, { hatch = "*" })
  end)
end)
