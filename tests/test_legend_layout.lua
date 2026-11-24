local plt = require("luaplotlib")

test("cartesian legends support center locations", function()
  local locations = {
    "upper center", "lower center", "center left", "center right", "center",
  }
  for _, loc in ipairs(locations) do
    local fig = plt.figure()
    fig:plot({ 1, 2 }, { 1, 2 }, { label = "line" })
    fig:legend({ loc = loc })
    local svg = fig:to_svg()
    assert_contains(svg, 'class="legend-meta" data-loc="' .. loc .. '"')
    assert_equal(fig:to_scene().legend_style.loc, loc)
  end
end)

test("polar legends support center locations", function()
  local locations = {
    "upper center", "lower center", "center left", "center right", "center",
  }
  for _, loc in ipairs(locations) do
    local fig = plt.figure({ width = 520, height = 520 })
    fig:polar({ 0, 1 }, { 1, 1 }, { label = "line" })
    fig:legend({ loc = loc })
    local svg = fig:to_svg()
    assert_contains(svg, 'class="polar-legend" data-loc="' .. loc .. '"')
    assert_equal(fig:to_scene().polar.legend.loc, loc)
  end
end)

test("legend locations validate accepted names", function()
  local fig = plt.figure()
  assert_error("legend loc must be one of", function()
    fig:legend({ loc = "diagonal" })
  end)
end)
