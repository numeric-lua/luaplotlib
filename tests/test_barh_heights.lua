local plt = require("luaplotlib")

test("barh accepts one height per bar", function()
  local fig = plt.figure()
  fig:barh({ "a", "b", "c" }, { 1, 2, 3 }, { height = { 0.2, 0.5, 0.8 } })
  local scene = fig:to_scene().series[1]
  assert_equal(scene.heights[2], 0.5)
  assert_equal(scene.height, 0.2)
  local heights = {}
  for height in fig:to_svg():gmatch('class="barh"[^>]*height="([^"]*)"') do
    heights[#heights + 1] = tonumber(height)
  end
  assert_true(heights[3] > heights[1])
end)

test("barh height arrays validate length and values", function()
  local fig = plt.figure()
  assert_error("one entry per bar", function()
    fig:barh({ "a", "b" }, { 1, 2 }, { height = { 0.5 } })
  end)
  assert_error("height%[2%] must be <= 1", function()
    fig:barh({ "a", "b" }, { 1, 2 }, { height = { 0.5, 2 } })
  end)
end)
