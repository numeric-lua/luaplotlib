local plt = require("luaplotlib")

test("accepts a 2-D tensor-like matrix for imshow", function()
  local proxy = setmetatable({}, {
    __index = {
      dim = function() return 2 end,
      numel = function() return 4 end,
      totable = function() return { { 1, 2 }, { 3, 4 } } end,
    },
  })
  local fig = plt.figure({ width = 400, height = 300 })
  fig:imshow(proxy, { colorbar = false })
  assert_equal(select(2, fig:to_svg():gsub('class="heatmap%-cell"', "")), 4)
end)

test("rejects non-2-D tensor-like input", function()
  local proxy = setmetatable({}, {
    __index = {
      dim = function() return 1 end,
      numel = function() return 2 end,
      totable = function() return { 1, 2 } end,
    },
  })
  assert_error("2%-D tensor", function()
    plt.figure():imshow(proxy)
  end)
end)
