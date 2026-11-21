-- Polar annotation limits and canvas clipping tests.

local plt = require("luaplotlib")
local text = require("luaplotlib.text")

local function number_attr(svg, name)
  return tonumber(svg:match('data%-' .. name .. '="([%d%.%-]+)"'))
end

local function annotation_groups(svg)
  local result = {}
  for index, theta, r, clamped in svg:gmatch(
      '<g class="annotation" data%-index="(%d+)" data%-theta="([^"]+)" data%-r="([^"]+)" data%-clamped="([^"]+)">') do
    result[#result + 1] = {
      index = tonumber(index),
      theta = tonumber(theta),
      r = tonumber(r),
      clamped = clamped,
    }
  end
  return result
end

local function annotation_text(svg, index)
  local block = svg:match(
    '<g class="annotation" data%-index="' .. index .. '"[^>]*>(.-)</g>')
  assert_true(block ~= nil, "expected annotation " .. index)
  local x, y, fontsize, anchor, value = block:match(
    '<text class="annotation%-text" x="([^"]+)" y="([^"]+)" font%-size="([^"]+)"[^>]*text%-anchor="([^"]+)"[^>]*>(.-)</text>')
  assert_true(x ~= nil, "expected annotation text")
  return {
    x = tonumber(x),
    y = tonumber(y),
    fontsize = tonumber(fontsize),
    anchor = anchor,
    text = value,
  }
end

test("annotation target radii extend the automatic polar limit", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar({ 0, math.pi / 2 }, { 2, 4 })
  figure:polar_annotate("far target", math.pi / 4, 9, { arrow = true })
  local svg = figure:to_svg()
  local rmax = number_attr(svg, "rmax")
  assert_true(rmax >= 9, "automatic rmax should cover the annotation target")
  assert_contains(svg, 'class="annotation-layer" data-clip="canvas"')
  assert_well_formed_svg(svg)

  local scene = figure:to_scene()
  assert_equal(scene.annotations[1].r, 9)
  assert_true(scene.polar.rmax >= 9)
end)

test("negative annotation targets contribute their absolute radius", function()
  local figure = plt.figure({ width = 500, height = 500 })
  figure:polar({ 0 }, { 2 })
  figure:polar_annotate("negative", 0, -7)
  local svg = figure:to_svg()
  assert_true(number_attr(svg, "rmax") >= 7)
  local groups = annotation_groups(svg)
  assert_equal(#groups, 1)
  assert_equal(groups[1].r, -7)
end)

test("text positions do not extend rmax and may sit outside the circle",
    function()
  local figure = plt.figure({ width = 500, height = 500 })
  figure:polar({ 0 }, { 2 })
  figure:polar_annotate("outside", math.pi / 2, 2, {
    xytext = { math.pi / 2, 3 },
  })
  local svg = figure:to_svg()
  local rmax = number_attr(svg, "rmax")
  assert_true(rmax < 5, "xytext must not drive the automatic radial limit")
  local groups = annotation_groups(svg)
  assert_equal(#groups, 1)
  assert_equal(groups[1].clamped, "false")
  local cx, cy = number_attr(svg, "cx"), number_attr(svg, "cy")
  local radius = number_attr(svg, "radius")
  local annotation = annotation_text(svg, 1)
  local fraction = 3 / rmax
  assert_true(fraction > 1, "test setup expects text outside the circle")
  assert_true(annotation.y < cy - radius + 1e-6,
    "text should be above the polar circle when xytext r exceeds rmax")
  assert_true(math.abs(annotation.x - cx) < 1e-6)
  assert_well_formed_svg(svg)
end)

test("explicit polar rmax rejects out-of-range annotation targets", function()
  local figure = plt.figure({ width = 500, height = 500 })
  figure:polar_config({ rmax = 5 })
  figure:polar({ 0 }, { 2 })
  figure:polar_annotate("too far", 0, 6)
  assert_error("polar annotate r 6 exceeds the configured rmax 5", function()
    figure:to_svg()
  end)
  assert_error("polar annotate r 6 exceeds", function()
    figure:to_scene()
  end)
end)

test("annotation text is clamped to the canvas and its arrow follows", function()
  local figure = plt.figure({ width = 500, height = 500 })
  figure:polar({ 0 }, { 2 })
  figure:polar_annotate("long edge label", 0, 2, {
    xytext = { 0, 100 },
    align = "right",
    arrow = { color = "#333333", linewidth = 1.5, head = 8 },
  })
  local svg = figure:to_svg()
  local groups = annotation_groups(svg)
  assert_equal(#groups, 1)
  assert_equal(groups[1].clamped, "true")

  local annotation = annotation_text(svg, 1)
  local box = text.bounds(annotation.x, annotation.y, annotation.text,
    annotation.fontsize, annotation.anchor)
  assert_true(box.x >= 2 - 1e-6, "annotation text starts left of the canvas")
  assert_true(box.x + box.width <= 500 - 2 + 1e-6,
    "annotation text runs past the canvas")
  assert_true(box.y >= 2 - 1e-6, "annotation text starts above the canvas")
  assert_true(box.y + box.height <= 500 - 2 + 1e-6,
    "annotation text runs below the canvas")

  local x1, y1, x2, y2 = svg:match(
    '<line class="annotation%-arrow" x1="([^"]+)" y1="([^"]+)" x2="([^"]+)" y2="([^"]+)"')
  assert_true(x1 ~= nil, "expected a leader arrow")
  local cx, cy = number_attr(svg, "cx"), number_attr(svg, "cy")
  local radius = number_attr(svg, "radius")
  local dx, dy = tonumber(x2) - cx, tonumber(y2) - cy
  assert_true(math.sqrt(dx * dx + dy * dy) <= radius + 1e-6,
    "leader arrow target should stay inside the polar frame")
  assert_true(math.abs(tonumber(x1) - annotation.x) < 1e-6,
    "leader arrow should start at the clamped text position")
  assert_well_formed_svg(svg)
end)

test("annotations inside the canvas are not marked as clamped", function()
  local figure = plt.figure({ width = 600, height = 600 })
  figure:polar({ 0 }, { 2 })
  figure:polar_annotate("center", math.pi / 2, 1, {
    xytext = { math.pi / 2, 1.2 },
    align = "center",
  })
  local svg = figure:to_svg()
  local groups = annotation_groups(svg)
  assert_equal(groups[1].clamped, "false")
  assert_well_formed_svg(svg)
end)

test("plt.polar annotation helper still supports degree input", function()
  local figure = plt.figure({ width = 500, height = 500 })
  figure:polar_config({ rmax = 5 })
  figure:polar({ 0 }, { 5 })
  figure:annotate("north", 90, 5, { degrees = true })
  local svg = figure:to_svg()
  local annotation = annotation_text(svg, 1)
  local cx, cy = number_attr(svg, "cx"), number_attr(svg, "cy")
  local radius = number_attr(svg, "radius")
  assert_true(math.abs(annotation.x - cx) < 1e-6)
  assert_true(math.abs(annotation.y - (cy - radius)) < 1e-6)
  assert_well_formed_svg(svg)
end)
