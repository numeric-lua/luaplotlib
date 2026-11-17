-- Series geometry: lines, scatter, histogram, bars, limits, and adapters.

local plt = require("luaplotlib")

test("line plot renders a polyline with automatic range and default color", function()
  local fig = plt.figure()
  fig:plot({ 0, 1, 2, 3 }, { 0, 1, 4, 9 })
  local svg = fig:to_svg()
  assert_contains(svg, '<polyline class="line"')
  assert_contains(svg, 'stroke="#1f77b4"')
  assert_equal(count_occurrences(svg, '<polyline class="line"'), 1)
  assert_contains(svg, '<g class="ticks x-ticks">')
  assert_contains(svg, '<g class="ticks y-ticks">')
  assert_well_formed_svg(svg)
end)

test("line markers, dashes, linewidth, and alpha are rendered", function()
  local fig = plt.figure()
  fig:plot({ 1, 2, 3 }, { 3, 1, 2 }, {
    color = "#123456",
    linewidth = 3.5,
    linestyle = "dashed",
    marker = "o",
    markersize = 5,
    alpha = 0.5,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'stroke="#123456"')
  assert_contains(svg, 'stroke-width="3.5"')
  assert_contains(svg, 'stroke-dasharray="6 4"')
  assert_equal(count_occurrences(svg, 'class="marker"'), 3)
  assert_contains(svg, 'stroke-opacity="0.5"')
end)

test("single-point line remains visible", function()
  local fig = plt.figure()
  fig:plot({ 2 }, { 5 })
  local svg = fig:to_svg()
  assert_contains(svg, '<polyline class="line"')
  assert_equal(count_occurrences(svg, 'class="marker"'), 1)
end)

test("scatter produces one circle per point", function()
  local fig = plt.figure()
  fig:scatter({ 1, 2, 3, 4 }, { 4, 3, 2, 1 }, {
    color = "#d62728",
    size = 6,
    label = "samples",
    alpha = 0.75,
  })
  local svg = fig:to_svg()
  assert_equal(count_occurrences(svg, '<circle class="point"'), 4)
  assert_contains(svg, 'r="6"')
  assert_contains(svg, 'fill="#d62728"')
  assert_contains(svg, 'fill-opacity="0.75"')
  assert_contains(svg, 'data-label="samples"')
  assert_not_contains(svg, '<polyline class="line"')
  assert_well_formed_svg(svg)
end)

test("scatter edge color and width are emitted", function()
  local fig = plt.figure()
  fig:scatter({ 1, 2 }, { 1, 2 }, {
    edgecolor = "#000000",
    linewidth = 2,
  })
  local svg = fig:to_svg()
  assert_contains(svg, 'stroke="#000000" stroke-width="2"')
end)

test("multiple series use distinct palette colors and legend labels", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 1, 2 }, { label = "first" })
  fig:plot({ 1, 2 }, { 2, 1 }, { label = "second" })
  fig:legend()
  local svg = fig:to_svg()
  assert_contains(svg, 'stroke="#1f77b4"')
  assert_contains(svg, 'stroke="#ff7f0e"')
  assert_contains(svg, '<g class="legend">')
  assert_contains(svg, '>first</text>')
  assert_contains(svg, '>second</text>')
  assert_well_formed_svg(svg)
end)

test("histogram counts values into bins and draws bars", function()
  local fig = plt.figure()
  fig:hist({ 1, 1, 2, 3 }, { bins = 2, color = "#2ca02c", label = "values" })
  local svg = fig:to_svg()
  assert_equal(count_occurrences(svg, 'class="hist-bin"'), 2)
  assert_contains(svg, 'fill="#2ca02c"')
  assert_contains(svg, 'data-label="values"')
  -- Counts are [2, 2]; the zero baseline is part of the automatic y range.
  assert_contains(svg, '>0</text>')
  assert_contains(svg, '>2</text>')
  assert_well_formed_svg(svg)
end)

test("histogram range, empty bins, and non-integer values work", function()
  local fig = plt.figure()
  fig:hist({ 0.1, 0.2, 0.2, 0.9, 5.0 }, { bins = 4, range = { 0, 1 } })
  local svg = fig:to_svg()
  -- Counts are [3, 0, 0, 1], and values outside range are ignored. Empty bins
  -- are omitted from the SVG.
  assert_equal(count_occurrences(svg, 'class="hist-bin"'), 2)
  assert_contains(svg, '>0</text>')
  assert_contains(svg, '>3</text>')
end)

test("categorical bars place labels and use category ticks", function()
  local fig = plt.figure()
  fig:bar({ "alpha", "beta", "gamma" }, { 3, 5, 2 }, { label = "bars" })
  local svg = fig:to_svg()
  assert_equal(count_occurrences(svg, '<rect class="bar"'), 3)
  assert_contains(svg, '>alpha</text>')
  assert_contains(svg, '>beta</text>')
  assert_contains(svg, '>gamma</text>')
  assert_contains(svg, 'class="series series-bar"')
  assert_well_formed_svg(svg)
end)

test("numeric bars, negative values, and explicit bar width work", function()
  local fig = plt.figure()
  fig:bar({ 0.1, 0.2, 0.3 }, { 2, -1, 3 }, { width = 0.5 })
  local svg = fig:to_svg()
  assert_equal(count_occurrences(svg, '<rect class="bar"'), 3)
  -- Baseline zero should appear on the y axis.
  assert_contains(svg, '>0</text>')
  assert_well_formed_svg(svg)
end)

test("explicit limits control the ticks", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 3, 4 })
  fig:xlim(100, 200)
  fig:ylim(10, 20)
  local svg = fig:to_svg()
  assert_contains(svg, '>100</text>')
  assert_contains(svg, '>200</text>')
  assert_contains(svg, '>10</text>')
  assert_contains(svg, '>20</text>')
  assert_well_formed_svg(svg)
end)

test("duck-typed tensor input works without luatorch", function()
  local x_values = { 1, 2, 3, 4 }
  local y_values = { 2, 4, 3, 5 }
  local function fake(values)
    return setmetatable({}, {
      __index = function(_, key)
        if key == "nDimension" then
          return function() return 1 end
        elseif key == "nElement" then
          return function() return #values end
        elseif key == "size" then
          return function() return #values end
        elseif type(key) == "number" then
          return values[key]
        end
      end,
    })
  end
  local fig = plt.figure()
  fig:plot(fake(x_values), fake(y_values))
  local svg = fig:to_svg()
  assert_contains(svg, '<polyline class="line"')
  assert_well_formed_svg(svg)
end)

test("array-wrapper input with data and n fields works", function()
  local fig = plt.figure()
  fig:plot({ data = { 1, 2, 3 }, n = 3 },
           { data = { 3, 2, 1 }, n = 3 })
  local svg = fig:to_svg()
  assert_contains(svg, '<polyline class="line"')
end)

test("empty figures still render a valid default axis", function()
  local fig = plt.figure()
  fig:title("empty")
  local svg = fig:to_svg()
  assert_contains(svg, 'class="title"')
  assert_contains(svg, '>0</text>')
  assert_contains(svg, '>1</text>')
  assert_well_formed_svg(svg)
end)

test("errorbar renders bars, caps, line, and markers", function()
  local fig = plt.figure({ width = 480, height = 320 })
  fig:errorbar({ 1, 2, 3 }, { 2, 4, 3 }, { 0.25, 0.5, 0.75 }, {
    label = "measurement", color = "#336699", capsize = 6,
  })
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)
  assert_contains(svg, 'class="series series-errorbar"')
  assert_contains(svg, 'class="errorbar"')
  assert_contains(svg, 'class="errorbar-cap"')
  assert_equal(count_occurrences(svg, 'class="errorbar-cap"'), 6)
  assert_contains(svg, 'class="series series-line"')
  assert_contains(svg, 'class="marker"')
  assert_contains(svg, 'stroke="#336699"')
end)

test("errorbar accepts scalar yerr and horizontal xerr", function()
  local fig = plt.figure({ width = 480, height = 320 })
  fig:errorbar({ 1, 2 }, { 3, 4 }, 0.5, { 0.1, 0.2 }, {
    label = "errors", marker = false, linestyle = "none",
  })
  local svg = fig:to_svg()
  assert_well_formed_svg(svg)
  assert_equal(count_occurrences(svg, 'class="errorbar-cap"'), 8)
  assert_not_contains(svg, 'class="marker"')
  assert_contains(svg, "data-label")
end)
