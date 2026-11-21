-- Polar legend text-metric tests.  Wide glyphs must produce wider legend
-- columns than narrow glyphs, and every label/title must fit inside the
-- resolved frame with padding.

local plt = require("luaplotlib")
local text = require("luaplotlib.text")

local function legend_geometry(svg)
  local loc, placement, x, y, width, height, text_width = svg:match(
    '<g class="polar%-legend" data%-loc="([^"]*)" data%-placement="([^"]*)" data%-x="([^"]+)" data%-y="([^"]+)" data%-width="([^"]+)" data%-height="([^"]+)" data%-text%-width="([^"]+)"')
  assert_true(x ~= nil, "expected polar legend geometry")
  return {
    loc = loc,
    placement = placement,
    x = tonumber(x),
    y = tonumber(y),
    width = tonumber(width),
    height = tonumber(height),
    text_width = tonumber(text_width),
  }
end

local function legend_body(svg)
  local body = svg:match('<g class="polar%-legend".-</g>')
  assert_true(body ~= nil, "expected a polar legend group")
  return body
end

local function legend_labels(svg)
  local labels = {}
  for x, value in legend_body(svg):gmatch(
      '<text x="([^"]+)" y="[^"]+" font%-size="11"[^>]*>(.-)</text>') do
    labels[#labels + 1] = { x = tonumber(x), text = value }
  end
  return labels
end

local function legend_title(svg)
  local x, value = legend_body(svg):match(
    '<text class="legend%-title" x="([^"]+)"[^>]*>(.-)</text>')
  if x == nil then return nil end
  return { x = tonumber(x), text = value }
end

local function assert_labels_fit(svg)
  local legend = legend_geometry(svg)
  local labels = legend_labels(svg)
  assert_true(#labels > 0, "expected legend entry labels")
  for index, label in ipairs(labels) do
    local right = label.x + text.measure(label.text, 11)
    assert_true(right <= legend.x + legend.width - 4 + 0.01,
      string.format("label %d (%q) overflows the polar legend frame",
        index, label.text))
    assert_true(label.x >= legend.x + 8 - 0.01,
      "label starts left of the legend frame padding")
  end
  local title = legend_title(svg)
  if title ~= nil then
    local right = title.x + text.measure(title.text, 11)
    assert_true(right <= legend.x + legend.width - 4 + 0.01,
      "legend title overflows the polar legend frame")
  end
  return legend
end

local function legend_for(label, ncol, title)
  local figure = plt.figure({ width = 640, height = 480 })
  figure:polar({ 0, 1 }, { 2, 3 }, { label = label })
  figure:legend({ loc = "best", ncol = ncol, title = title })
  return figure:to_svg()
end

test("text metrics distinguish narrow, wide, and degree glyphs", function()
  assert_true(text.measure("WWWW", 10) > 2 * text.measure("iiii", 10),
    "W should be much wider than i")
  assert_true(text.measure("MMMM", 10) > text.measure("....", 10))
  assert_true(math.abs(text.measure("\194\176", 10) - 4) < 1e-6,
    "degree sign should use its Helvetica advance")
  assert_equal(text.count("\194\176C"), 2)
  assert_equal(text.count("plain"), 5)
  assert_equal(text.measure("", 10), 0)
end)

test("wide polar legend labels widen the frame instead of overflowing",
    function()
  local wide = legend_for("WWWWWWWWWW")
  local narrow = legend_for("iiiiiiiiii")
  local wide_legend = assert_labels_fit(wide)
  local narrow_legend = assert_labels_fit(narrow)
  assert_true(wide_legend.width > narrow_legend.width + 30,
    "wide glyph labels should reserve a wider legend frame")
  assert_true(wide_legend.text_width >
    narrow_legend.text_width + 30,
    "legend should expose measured text width")
  assert_well_formed_svg(wide)
  assert_well_formed_svg(narrow)
end)

test("multi-column polar legend keeps every measured label inside the frame",
    function()
  local figure = plt.figure({ width = 700, height = 550 })
  figure:polar({ 0, 1 }, { 2, 3 }, { label = "WWWW first" })
  figure:polar({ 0, 1 }, { 3, 2 }, { label = "iiii second" })
  figure:polar({ 0, 1 }, { 1, 4 }, { label = "medium third" })
  figure:polar({ 0, 1 }, { 4, 1 }, { label = "MMMM fourth" })
  figure:legend({ loc = "best", ncol = 2 })
  local svg = figure:to_svg()
  local legend = assert_labels_fit(svg)
  local labels = legend_labels(svg)
  assert_equal(#labels, 4)
  local columns = {}
  for _, label in ipairs(labels) do
    columns[label.x] = true
  end
  local count = 0
  for _ in pairs(columns) do count = count + 1 end
  assert_equal(count, 2, "expected two legend columns")
  assert_true(legend.width <= 700 - 16 + 1e-6)
  assert_well_formed_svg(svg)
end)

test("wide polar legend titles reserve room and stay inside the frame",
    function()
  local svg = legend_for("x", 1,
    "WWWWWWWWWWWWWWWWWWWWWWWW")
  local legend = assert_labels_fit(svg)
  assert_true(legend.width >= text.measure(
    "WWWWWWWWWWWWWWWWWWWWWWWW", 11) + 16 - 0.01,
    "legend frame should be wide enough for its title")
  assert_well_formed_svg(svg)
end)

test("UTF-8 polar labels use codepoint metrics without corrupting text",
    function()
  local svg = legend_for("temperatura \194\176C")
  local legend = assert_labels_fit(svg)
  assert_contains(legend_body(svg), "temperatura \194\176C")
  assert_true(legend.text_width >= text.measure(
    "temperatura \194\176C", 11) - 0.01)
  assert_well_formed_svg(svg)
end)

test("long polar titles are avoided by legend placement", function()
  local figure = plt.figure({ width = 640, height = 480 })
  figure:polar({ 0, 1 }, { 2, 3 }, { label = "series" })
  figure:title("a long polar title that takes most of the top margin")
  figure:legend({ loc = "upper right" })
  local svg = figure:to_svg()
  local legend = legend_geometry(svg)
  local tx, ty, anchor, title = svg:match(
    '<text class="title" x="([^"]+)" y="([^"]+)"[^>]*text%-anchor="([^"]+)">(.-)</text>')
  assert_true(tx ~= nil, "expected a title")
  local title_box = text.bounds(tonumber(tx), tonumber(ty), title, 18, anchor)
  local overlaps = not (legend.x + legend.width <= title_box.x or
    title_box.x + title_box.width <= legend.x or
    legend.y + legend.height <= title_box.y or
    title_box.y + title_box.height <= legend.y)
  assert_false(overlaps, "legend should not overlap the title")
  assert_well_formed_svg(svg)
end)

test("legend placement avoids clamped annotation text boxes", function()
  local figure = plt.figure({ width = 720, height = 520 })
  figure:polar_config({ rmax = 5 })
  figure:polar({ 0, 1.2, 2.5 }, { 2, 3, 4 }, {
    label = "WWWW wide glyph series",
  })
  figure:polar({ 0, 1.2, 2.5 }, { 4, 2, 3 }, {
    label = "iiii narrow glyph series",
  })
  figure:polar_annotate("edge label that must not leave the canvas", 0, 5, {
    arrow = { head = 8 },
  })
  figure:legend({ loc = "best", ncol = 2 })
  local svg = figure:to_svg()
  local legend = assert_labels_fit(svg)

  local x, y, fontsize, anchor, value = svg:match(
    '<text class="annotation%-text" x="([^"]+)" y="([^"]+)" font%-size="([^"]+)"[^>]*text%-anchor="([^"]+)"[^>]*>(.-)</text>')
  assert_true(x ~= nil, "expected an annotation")
  local annotation = text.bounds(tonumber(x), tonumber(y), value,
    tonumber(fontsize), anchor)
  local overlaps = not (legend.x + legend.width <= annotation.x or
    annotation.x + annotation.width <= legend.x or
    legend.y + legend.height <= annotation.y or
    annotation.y + annotation.height <= legend.y)
  assert_false(overlaps, "legend should not cover clamped annotation text")
  assert_well_formed_svg(svg)
end)
