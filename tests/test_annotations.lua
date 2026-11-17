-- Annotations: escaping, placement, arrows, log coordinates, and scene IR.

local plt = require("luaplotlib")
local scene = require("luaplotlib.scene")
local util = require("luaplotlib.util")

local function layout(fig)
  local width, height = fig.width, fig.height
  local left = math.min(72, math.max(36, width * 0.14))
  local right = width - math.min(28, math.max(12, width * 0.04))
  local top = math.min(48, math.max(24, height * 0.10))
  local bottom = height - math.min(66, math.max(36, height * 0.16))
  return {
    left = left,
    right = right,
    top = top,
    bottom = bottom,
    plot_width = right - left,
    plot_height = bottom - top,
  }
end

local function map_point(fig, x, y, xlim, ylim, xscale, yscale)
  local geom = layout(fig)
  local xmin, xmax = xlim[1], xlim[2]
  local ymin, ymax = ylim[1], ylim[2]
  if xscale == "log" then
    x, xmin, xmax = util.log10(x), util.log10(xmin), util.log10(xmax)
  end
  if yscale == "log" then
    y, ymin, ymax = util.log10(y), util.log10(ymin), util.log10(ymax)
  end
  local px = geom.left + (x - xmin) / (xmax - xmin) * geom.plot_width
  local py = geom.bottom - (y - ymin) / (ymax - ymin) * geom.plot_height
  return px, py
end

local function annotation_text(svg, index)
  local found = 0
  for x, y, fontsize, fill, anchor, align, text in svg:gmatch(
      '<text class="annotation%-text" x="([^"]+)" y="([^"]+)" font%-size="([^"]+)" fill="([^"]+)" text%-anchor="([^"]+)" data%-align="([^"]+)">(.-)</text>') do
    found = found + 1
    if found == (index or 1) then
      return {
        x = tonumber(x), y = tonumber(y), fontsize = tonumber(fontsize),
        fill = fill, anchor = anchor, align = align, text = text,
      }
    end
  end
  error("missing annotation text")
end

local function annotation_arrow(svg, index)
  local found = 0
  for x1, y1, x2, y2, stroke, width in svg:gmatch(
      '<line class="annotation%-arrow" x1="([^"]+)" y1="([^"]+)" x2="([^"]+)" y2="([^"]+)" stroke="([^"]+)" stroke%-width="([^"]+)"') do
    found = found + 1
    if found == (index or 1) then
      return {
        x1 = tonumber(x1), y1 = tonumber(y1), x2 = tonumber(x2), y2 = tonumber(y2),
        stroke = stroke, linewidth = tonumber(width),
      }
    end
  end
  error("missing annotation arrow")
end

local function close(actual, expected, label)
  assert_true(math.abs(actual - expected) < 0.01,
    string.format("%s: expected %s, got %s", label, expected, actual))
end

test("annotate is chainable and plain text has no arrow", function()
  local fig = plt.figure({ width = 640, height = 480 })
  assert_equal(fig:annotate("note", 2, 3), fig)
  fig:plot({ 0, 4 }, { 0, 6 })
  local svg = fig:to_svg()
  assert_contains(svg, '<g class="annotation-layer"')
  assert_contains(svg, '<g class="annotation"')
  assert_contains(svg, '<text class="annotation-text"')
  assert_contains(svg, ">note</text>")
  assert_not_contains(svg, 'class="annotation-arrow"')
  assert_well_formed_svg(svg)
end)

test("annotation text is XML-escaped", function()
  local fig = plt.figure()
  fig:annotate([[A & B <C> "D" 'E']], 1, 1)
  local svg = fig:to_svg()
  assert_contains(svg, "A &amp; B &lt;C&gt; &quot;D&quot; &apos;E&apos;")
  assert_not_contains(svg, "<C>")
  assert_not_contains(svg, [[A & B <C>]])
  assert_well_formed_svg(svg)
end)

test("annotation placement follows data coordinates and alignment", function()
  local fig = plt.figure({ width = 640, height = 480 }):xlim(0, 10):ylim(0, 10)
  fig:plot({ 0, 10 }, { 0, 10 })
  fig:annotate("placed", 2, 3, { xytext = { 4, 5 }, align = "center" })
  local svg = fig:to_svg()
  local text = annotation_text(svg)
  local expected_x, expected_y = map_point(fig, 4, 5, { 0, 10 }, { 0, 10 })
  close(text.x, expected_x, "annotation x")
  close(text.y, expected_y, "annotation y")
  assert_equal(text.anchor, "middle")
  assert_equal(text.align, "center")
  assert_well_formed_svg(svg)
end)

test("annotation color and font size options are rendered", function()
  local fig = plt.figure():xlim(0, 10):ylim(0, 10)
  fig:annotate("styled", 1, 1, {
    xytext = { 2, 2 }, color = "#123456", fontsize = 17, align = "right",
  })
  local svg = fig:to_svg()
  local text = annotation_text(svg)
  assert_equal(text.fill, "#123456")
  assert_equal(text.fontsize, 17)
  assert_equal(text.anchor, "end")
  assert_equal(text.align, "right")
  assert_well_formed_svg(svg)
end)

test("arrow endpoints connect xytext to the annotated point", function()
  local fig = plt.figure({ width = 640, height = 480 }):xlim(0, 10):ylim(0, 10)
  fig:plot({ 0, 10 }, { 0, 10 })
  fig:annotate("peak", 2, 3, {
    xytext = { 4, 5 }, arrow = { color = "#abcdef", linewidth = 2.5, head = 10 },
  })
  local svg = fig:to_svg()
  local arrow = annotation_arrow(svg)
  local text_x, text_y = map_point(fig, 4, 5, { 0, 10 }, { 0, 10 })
  local target_x, target_y = map_point(fig, 2, 3, { 0, 10 }, { 0, 10 })
  close(arrow.x1, text_x, "arrow start x")
  close(arrow.y1, text_y, "arrow start y")
  close(arrow.x2, target_x, "arrow end x")
  close(arrow.y2, target_y, "arrow end y")
  assert_equal(arrow.stroke, "#abcdef")
  assert_equal(arrow.linewidth, 2.5)
  assert_contains(svg, '<polygon class="annotation-arrow-head"')
  assert_well_formed_svg(svg)
end)

test("arrow without xytext offsets the label and still points at the target", function()
  local fig = plt.figure({ width = 640, height = 480 }):xlim(0, 10):ylim(0, 10)
  fig:plot({ 0, 10 }, { 0, 10 })
  fig:annotate("offset", 5, 5, { arrow = true })
  local svg = fig:to_svg()
  local arrow = annotation_arrow(svg)
  local target_x, target_y = map_point(fig, 5, 5, { 0, 10 }, { 0, 10 })
  close(arrow.x1, target_x + 12, "offset arrow start x")
  close(arrow.y1, target_y - 12, "offset arrow start y")
  close(arrow.x2, target_x, "offset arrow end x")
  close(arrow.y2, target_y, "offset arrow end y")
  assert_well_formed_svg(svg)
end)

test("annotations render above series and inside the plot clip", function()
  local fig = plt.figure():xlim(0, 10):ylim(0, 10)
  fig:plot({ 0, 10 }, { 0, 10 })
  fig:annotate("above", 5, 5)
  local svg = fig:to_svg()
  local series_at = svg:find('<g class="series-layer"', 1, true)
  local annotation_at = svg:find('<g class="annotation-layer"', 1, true)
  local axes_at = svg:find('<g class="axes"', 1, true)
  assert_true(series_at ~= nil and annotation_at ~= nil and axes_at ~= nil)
  assert_true(series_at < annotation_at, "annotations must follow series")
  assert_true(annotation_at < axes_at, "annotations must precede axes")
  assert_match(svg, '<g class="annotation%-layer" clip%-path="url%([^)]+%)">')
  assert_well_formed_svg(svg)
end)

test("annotation coordinates are transformed on logarithmic axes", function()
  local fig = plt.figure({ width = 640, height = 480, xscale = "log", yscale = "log" })
  fig:xlim(1, 1000):ylim(1, 1000)
  fig:plot({ 1, 1000 }, { 1, 1000 })
  fig:annotate("decade", 10, 100, {
    xytext = { 100, 10 }, arrow = true,
  })
  local svg = fig:to_svg()
  local arrow = annotation_arrow(svg)
  local text_x, text_y = map_point(fig, 100, 10, { 1, 1000 }, { 1, 1000 },
    "log", "log")
  local target_x, target_y = map_point(fig, 10, 100, { 1, 1000 }, { 1, 1000 },
    "log", "log")
  close(arrow.x1, text_x, "log arrow start x")
  close(arrow.y1, text_y, "log arrow start y")
  close(arrow.x2, target_x, "log arrow end x")
  close(arrow.y2, target_y, "log arrow end y")
  assert_well_formed_svg(svg)
end)

test("annotations do not change SVG output when unused", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 2, 1 })
  local svg = fig:to_svg()
  assert_not_contains(svg, "annotation")
  assert_well_formed_svg(svg)
end)

test("scene export includes annotation geometry and style", function()
  local fig = plt.figure():xlim(0, 10):ylim(0, 10)
  fig:plot({ 0, 10 }, { 0, 10 })
  fig:annotate("scene", 2, 3, {
    xytext = { 4, 5 }, color = "#123456", fontsize = 15, align = "center",
    arrow = { color = "#654321", linewidth = 2, head = 9 },
  })
  local exported = scene.from_figure(fig)
  assert_equal(#exported.annotations, 1)
  local annotation = exported.annotations[1]
  assert_equal(annotation.kind, "annotation")
  assert_equal(annotation.text, "scene")
  assert_equal(annotation.x, 2)
  assert_equal(annotation.y, 3)
  assert_equal(annotation.xytext[1], 4)
  assert_equal(annotation.xytext[2], 5)
  assert_equal(annotation.xytext.x, 4)
  assert_equal(annotation.xytext.y, 5)
  assert_equal(annotation.style.color, "#123456")
  assert_equal(annotation.style.fontsize, 15)
  assert_equal(annotation.style.align, "center")
  assert_true(annotation.arrow ~= nil)
  assert_equal(annotation.arrow.enabled, true)
  assert_equal(annotation.arrow.color, "#654321")
  assert_equal(annotation.arrow.linewidth, 2)
  assert_equal(annotation.arrow.head, 9)

  -- The exported scene is an independent copy.
  exported.annotations[1].xytext[1] = 99
  assert_equal(fig._annotations[1].xytext[1], 4)
end)

test("invalid annotation options are rejected", function()
  local fig = plt.figure()
  assert_error("annotate text", function() fig:annotate(nil, 1, 2) end)
  assert_error("annotate x", function() fig:annotate("x", "1", 2) end)
  assert_error("annotate requires", function() fig:annotate("x", 1, nil) end)
  assert_error("annotate y", function() fig:annotate("x", 1, 0 / 0) end)
  assert_error("unsupported annotate option", function()
    fig:annotate("x", 1, 2, { colour = "red" })
  end)
  assert_error("annotate color", function()
    fig:annotate("x", 1, 2, { color = "not a color!" })
  end)
  assert_error("annotate fontsize", function()
    fig:annotate("x", 1, 2, { fontsize = 0 })
  end)
  assert_error("annotate align", function()
    fig:annotate("x", 1, 2, { align = "top" })
  end)
  assert_error("annotate xytext", function()
    fig:annotate("x", 1, 2, { xytext = "there" })
  end)
  assert_error("annotate xytext", function()
    fig:annotate("x", 1, 2, { xytext = { 1 } })
  end)
  assert_error("annotate xytext", function()
    fig:annotate("x", 1, 2, { xytext = { 1, 2, 3 } })
  end)
  assert_error("annotate xytext requires", function()
    fig:annotate("x", 1, 2, { xytext = { x = 1 } })
  end)
  assert_error("annotate arrow", function()
    fig:annotate("x", 1, 2, { arrow = "yes" })
  end)
  assert_error("unsupported annotate arrow option", function()
    fig:annotate("x", 1, 2, { arrow = { bogus = true } })
  end)
  assert_error("annotate arrow linewidth", function()
    fig:annotate("x", 1, 2, { arrow = { linewidth = -1 } })
  end)
  assert_error("annotate arrow head", function()
    fig:annotate("x", 1, 2, { arrow = { head = -1 } })
  end)
end)

test("annotations reject non-positive coordinates on log axes", function()
  assert_error("positive", function()
    plt.figure({ xscale = "log" }):xlim(1, 10):annotate("bad", 0, 1):to_svg()
  end)
  assert_error("positive", function()
    plt.figure({ yscale = "log" }):ylim(1, 10):annotate("bad", 1, 0):to_svg()
  end)
  assert_error("positive", function()
    plt.figure({ xscale = "log" }):xlim(1, 10)
      :annotate("bad", 2, 1, { xytext = { 0, 2 } }):to_svg()
  end)
  assert_error("positive", function()
    plt.figure({ yscale = "log" }):ylim(1, 10)
      :annotate("bad", 2, 1, { xytext = { 2, -1 } }):to_svg()
  end)
end)
