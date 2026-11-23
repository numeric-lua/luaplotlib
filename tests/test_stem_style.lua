local plt = require("luaplotlib")

local function attrs(tag)
  local result = {}
  for key, value in tag:gmatch('([%w:-]+)="([^"]*)"') do result[key] = value end
  return result
end

local function stem_group(svg)
  local group = assert(svg:match('<g class="series series%-stem"[^>]*>'))
  local block = assert(svg:match('<g class="series series%-stem"[^>]*>(.-)</g>'))
  return attrs(group), block
end

test("stems default to a solid line with circular markers at zero", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:stem({ 1, 2 }, { 3, 4 })
  local group, block = stem_group(fig:to_svg())
  assert_equal(group["data-base"], "0")
  assert_equal(group["data-marker"], "circle")
  assert_equal(group["data-linestyle"], "solid")
  assert_equal(select(2, block:gsub('class="stem%-line"', "")), 2)
  assert_equal(select(2, block:gsub('class="stem%-marker"', "")), 2)
  assert_contains(block, '<circle class="stem-marker"')
end)

test("stem base controls both the drawn baseline and automatic range", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:stem({ 1, 2 }, { 6, 7 }, { base = 2, marker = false })
  fig:ylim(0, 10)
  local group, block = stem_group(fig:to_svg())
  assert_equal(group["data-base"], "2")
  assert_equal(group["data-marker"], "none")
  local line = assert(block:match('<line class="stem%-line"[^>]*/>'))
  local line_attrs = attrs(line)
  local expected = 336 - 2 / 10 * (336 - 40)
  assert_true(math.abs(tonumber(line_attrs.y1) - expected) < 0.001,
    "stem baseline should map the configured base value")

  local scene = fig:to_scene()
  assert_equal(scene.series[1].base, 2)
  assert_true(scene.ylim[1] <= 2, "scene range should include the base")
end)

test("stem markers and line styles are configurable", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:stem({ 1, 2, 3 }, { 2, 3, 2 }, {
    marker = "diamond", markersize = 6, linestyle = "dashed",
    linewidth = 2.5, alpha = 0.5,
  })
  local group, block = stem_group(fig:to_svg())
  assert_equal(group["data-marker"], "diamond")
  assert_equal(group["data-linestyle"], "dashed")
  assert_contains(block, '<polygon class="stem-marker"')
  assert_contains(block, 'stroke-dasharray="6 4"')
  assert_contains(block, 'stroke-width="2.5"')
  assert_contains(block, 'stroke-opacity="0.5"')
  assert_contains(block, 'fill-opacity="0.5"')
  local scene = fig:to_scene().series[1]
  assert_equal(scene.style.marker, "diamond")
  assert_equal(scene.style.markersize, 6)
  assert_equal(scene.style.linestyle, "dashed")
  assert_equal(scene.base, 0)
end)

test("stem linestyle none keeps markers and marker false hides them", function()
  local lines_hidden = plt.figure()
  lines_hidden:stem({ 1, 2 }, { 3, 4 }, { linestyle = "none" })
  local _, block = stem_group(lines_hidden:to_svg())
  assert_not_contains(block, 'class="stem-line"')
  assert_equal(select(2, block:gsub('class="stem%-marker"', "")), 2)

  local markers_hidden = plt.figure()
  markers_hidden:stem({ 1, 2 }, { 3, 4 }, { marker = false })
  _, block = stem_group(markers_hidden:to_svg())
  assert_equal(select(2, block:gsub('class="stem%-line"', "")), 2)
  assert_not_contains(block, 'class="stem-marker"')
end)

test("stem options reject malformed styles and bases", function()
  local fig = plt.figure()
  assert_error("stem base must be a number", function()
    fig:stem({ 1 }, { 1 }, { base = "zero" })
  end)
  assert_error("stem base must be finite", function()
    fig:stem({ 1 }, { 1 }, { base = 0 / 0 })
  end)
  assert_error("stem linestyle must be one of", function()
    fig:stem({ 1 }, { 1 }, { linestyle = "zigzag" })
  end)
  assert_error("stem marker must be circle", function()
    fig:stem({ 1 }, { 1 }, { marker = "star" })
  end)
  assert_error("stem markersize must be >= 0.1", function()
    fig:stem({ 1 }, { 1 }, { markersize = 0 })
  end)
end)
