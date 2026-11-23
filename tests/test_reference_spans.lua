local plt = require("luaplotlib")

local LEFT, TOP, RIGHT, BOTTOM = 72, 40, 576, 336

local function attrs(tag)
  local result = {}
  for key, value in tag:gmatch('(%w+)="([^"]*)"') do result[key] = value end
  return result
end

local function reference_line(svg, kind)
  local group = assert(svg:match('<g class="series series%-' .. kind .. '"[^>]*>'))
  local block = assert(svg:match('<g class="series series%-' .. kind ..
    '"[^>]*>(.-)</g>'))
  local line = assert(block:match('<line class="reference"[^>]*/>'))
  return attrs(group), attrs(line)
end

test("axhline and axvline default to full axes spans", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:axhline(2, { color = "#123456" })
  fig:axvline(3, { color = "#654321" })
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)

  local hline, hline_attrs = reference_line(svg, "axhline")
  assert_equal(hline.xmin, "0", "axhline default xmin")
  assert_equal(hline.xmax, "1", "axhline default xmax")
  assert_equal(tonumber(hline_attrs.x1), LEFT, "full axhline left endpoint")
  assert_equal(tonumber(hline_attrs.x2), RIGHT, "full axhline right endpoint")

  local vline, vline_attrs = reference_line(svg, "axvline")
  assert_equal(vline.ymin, "0", "axvline default ymin")
  assert_equal(vline.ymax, "1", "axvline default ymax")
  assert_equal(tonumber(vline_attrs.y1), BOTTOM, "full axvline bottom endpoint")
  assert_equal(tonumber(vline_attrs.y2), TOP, "full axvline top endpoint")
end)

test("axhline xmin/xmax use axes fractions", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:axhline(2, { xmin = 0.25, xmax = 0.75 })
  local group, line = reference_line(fig:to_svg(), "axhline")
  assert_equal(group.xmin, "0.25")
  assert_equal(group.xmax, "0.75")
  assert_equal(tonumber(line.x1), LEFT + 0.25 * (RIGHT - LEFT))
  assert_equal(tonumber(line.x2), LEFT + 0.75 * (RIGHT - LEFT))
end)

test("axvline ymin/ymax use axes fractions from the bottom", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:axvline(2, { ymin = 0.2, ymax = 0.8 })
  local group, line = reference_line(fig:to_svg(), "axvline")
  assert_equal(group.ymin, "0.2")
  assert_equal(group.ymax, "0.8")
  assert_true(math.abs(tonumber(line.y1) - (BOTTOM - 0.2 * (BOTTOM - TOP))) < 0.001,
    "partial axvline bottom endpoint")
  assert_true(math.abs(tonumber(line.y2) - (BOTTOM - 0.8 * (BOTTOM - TOP))) < 0.001,
    "partial axvline top endpoint")
end)

test("reference span scene export carries the resolved fractions", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:axhline(2, { xmin = 0.1, xmax = 0.4, label = "partial" })
  fig:axvline(3, { ymin = 0.3, ymax = 0.9 })
  local scene = fig:to_scene()
  local hline, vline = scene.series[1], scene.series[2]
  assert_equal(hline.kind, "axhline")
  assert_equal(hline.y, 2)
  assert_equal(hline.xmin, 0.1)
  assert_equal(hline.xmax, 0.4)
  assert_equal(hline.style.label, "partial")
  assert_equal(vline.kind, "axvline")
  assert_equal(vline.x, 3)
  assert_equal(vline.ymin, 0.3)
  assert_equal(vline.ymax, 0.9)
  assert_true(scene.ylim[1] < 2 and scene.ylim[2] > 2,
    "axhline should extend the scene y range")
  assert_true(scene.xlim[1] < 3 and scene.xlim[2] > 3,
    "axvline should extend the scene x range")
end)

test("reference spans reject malformed fractions", function()
  local fig = plt.figure()
  assert_error("options must be a table", function()
    fig:axhline(1, "left")
  end)
  assert_error("xmin must be >= 0", function()
    fig:axhline(1, { xmin = -0.1 })
  end)
  assert_error("xmax must be <= 1", function()
    fig:axhline(1, { xmax = 1.1 })
  end)
  assert_error("xmin must be less than xmax", function()
    fig:axhline(1, { xmin = 0.7, xmax = 0.7 })
  end)
  assert_error("ymin must be less than ymax", function()
    fig:axvline(1, { ymin = 0.8, ymax = 0.2 })
  end)
  assert_error("unsupported axhline option", function()
    fig:axhline(1, { ymin = 0 })
  end)
  assert_error("unsupported axvline option", function()
    fig:axvline(1, { xmin = 0 })
  end)
end)
