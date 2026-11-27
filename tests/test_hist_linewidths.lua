local plt = require("luaplotlib")

test("hist accepts one outline width per bin", function()
  local fig = plt.figure()
  fig:hist({ 1, 1, 2, 2, 3, 3 }, {
    bins = { 0.5, 1.5, 2.5, 3.5 },
    linewidth = { 0.5, 1.5, 3 },
  })
  local widths = {}
  for width in fig:to_svg():gmatch('class="hist%-bin"[^>]*stroke%-width="([^"]*)"') do
    widths[#widths + 1] = tonumber(width)
  end
  assert_equal(widths[1], 0.5)
  assert_equal(widths[3], 3)
  local style = fig:to_scene().series[1].style
  assert_equal(style.linewidths[2], 1.5)
end)

test("hist linewidth arrays validate type, length, and values", function()
  local fig = plt.figure()
  assert_error("one value per bin", function()
    fig:hist({ 1, 2 }, { bins = { 0, 1, 2 }, linewidth = { 1 } })
  end)
  assert_error("require histtype bar", function()
    fig:hist({ 1, 2 }, {
      bins = { 0, 1, 2 }, histtype = "step",
      linewidth = { 1, 1 },
    })
  end)
  assert_error("linewidth%[2%] must be >= 0", function()
    fig:hist({ 1, 2 }, {
      bins = { 0, 1, 2 }, linewidth = { 1, -1 },
    })
  end)
end)
