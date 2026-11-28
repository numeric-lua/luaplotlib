# luaplotlib

**A small, pure-Lua, matplotlib-inspired plotting library with an SVG backend.**

luaplotlib turns numeric data into standalone, dependency-free SVG files. It is
designed for the LuaJIT/numeric-lua ecosystem, but the basic path accepts plain
Lua tables and has no required runtime dependencies: no Lua rocks, no C
libraries, no GUI toolkit, and no network access.

```lua
local plt = require("luaplotlib")

local x, y = {}, {}
for i = 1, 120 do
  x[i] = (i - 1) * 2 * math.pi / 119
  y[i] = math.sin(x[i])
end

local fig = plt.figure({ width = 800, height = 500 })
fig:plot(x, y, { label = "sin(x)" })
fig:title("Sine wave")
fig:xlabel("x")
fig:ylabel("sin(x)")
fig:grid(true)
fig:legend()
fig:savefig("line.svg")
```

## Requirements

- LuaJIT 2.1 (the primary target). The library uses only standard Lua 5.1/LuaJIT
  features and has also been smoke-tested with PUC Lua 5.5.
- PNG/PDF export optionally uses the system `rsvg-convert`; SVG/HTML remain dependency-free.
- A browser or converter is only needed to *view* the SVG; luaplotlib itself
  never renders or displays images interactively.

## Install / LUA_PATH

This repository is `numeric-lua/luaplotlib`. To use it from the checkout, add
the repository root to `LUA_PATH`:

```sh
# run these from the repository root
export LUA_PATH="$PWD/?.lua;$PWD/?/init.lua;;"

luajit examples/line.lua
luajit examples/histogram.lua
luajit examples/errorbar.lua
luajit examples/ecdf_complementary.lua
luajit examples/annotations.lua
luajit examples/axline.lua
luajit examples/cartesian_controls.lua
luajit examples/histogram_horizontal.lua
luajit examples/stem.lua
luajit examples/stem_horizontal.lua
luajit examples/quiver.lua
luajit examples/quiver_uv.lua
luajit examples/hexbin.lua
luajit examples/field_coordinates.lua
luajit examples/aspect.lua
luajit examples/bars.lua
luajit examples/bar_linewidth.lua
luajit examples/barh_hatch.lua
luajit examples/broken_barh.lua
luajit examples/pie_explode.lua
luajit examples/pie_rotated.lua
luajit examples/pie_counterclock.lua
luajit examples/heatmap.lua
luajit examples/minor_subdivisions.lua
luajit examples/eventplot_layout.lua
luajit examples/hist_styles.lua
luajit examples/hist_edges.lua
luajit examples/step_fill.lua
luajit examples/violinplot.lua
luajit examples/violin_horizontal.lua
luajit examples/boxplot_horizontal.lua
luajit examples/imshow_colorbar.lua
luajit examples/subplots.lua
luajit examples/polar.lua
luajit examples/polar_bars.lua
luajit examples/polar_annotations.lua
luajit examples/polar_heatmap.lua
luajit examples/polar_contour.lua
luajit examples/polar_quiver.lua
luajit examples/polar_streamplot.lua
```

The trailing `;;` preserves the interpreter's default module path. The same
tree can be copied or symlinked to any directory on `LUA_PATH`; there is no
build step.

Install from LuaRocks:

```sh
luarocks --lua-version=5.1 install luaplotlib
```

The examples write SVGs to `examples/output/`, which is gitignored.

## Quick start

Save this as `quick.lua` in the repository root, or adapt the examples:

```lua
local plt = require("luaplotlib")

local x, y1, y2 = {}, {}, {}
for i = 1, 101 do
  x[i] = (i - 1) / 10
  y1[i] = math.sin(x[i])
  y2[i] = math.cos(x[i])
end

local fig = plt.figure({ width = 720, height = 480, dpi = 100 })
fig:plot(x, y1, { label = "sin", color = "#1f77b4" })
fig:plot(x, y2, { label = "cos", color = "#ff7f0e", linestyle = "dashed" })
fig:scatter({ 0, 1, 2 }, { 0, 0.84, 0.91 }, { color = "#d62728", label = "samples" })
fig:title("Line and scatter")
fig:xlabel("x")
fig:ylabel("value")
fig:grid(true)
fig:legend()
fig:savefig("quick.svg")
```

The SVG can also be kept in memory:

```lua
local svg = fig:to_svg()
```

Logarithmic axes use base-10 scaling and automatically generate decade ticks:

```lua
local fig = plt.figure({ width = 720, height = 480 })
fig:plot({ 1, 10, 100, 1000 }, { 1, 100, 10000, 1000000 })
fig:xscale("log")
fig:yscale("log")
fig:grid(true)
fig:savefig("log.svg")
```

Log axes require strictly positive values; zero or negative data raises a
`luaplotlib:` error when the figure is rendered. The scales can also be set in
the figure options: `plt.figure({ xscale = "log", yscale = "log" })`.

Minor ticks, decimated markers, rotated y labels, and clipped infinite
reference lines are available without changing existing plots:

```lua
fig:plot(x, y, { marker = true, markevery = 5, label = "sampled" })
fig:minorticks(true)
fig:grid(true, { minor = true })
fig:ytick_rotation(30)
fig:axline(0, 0, 1, 1, { label = "y = x", linestyle = "dashed" })
```

`markevery` accepts a positive integer stride or a table of 1-based point
indices; it decimates markers while keeping every line vertex. Minor ticks
subdivide linear major intervals into five parts by default (2–10 with
`minorticks(..., { subdivisions = n })`) and use the 2–9 mantissas on log axes,
and `fig:grid(true, { minor = true })` adds their fainter grid. An `axline` is
clipped to the plot rectangle and participates in automatic ranging only
through its two defining points.

Cartesian controls are additive and keep the existing defaults:

```lua
-- Reference lines can be limited to axes fractions (0..1).
fig:axhline(0.5, { xmin = 0.10, xmax = 0.60 })
fig:axvline(2.0, { ymin = 0.20, ymax = 0.90 })

-- A boolean mask splits a filled band; interpolation joins the cut edges.
fig:fill_between(x, lower, upper, { where = mask, interpolate = true })

-- Major and minor grids accept independent color, width, dash, and alpha.
fig:grid(true, {
  alpha = 0.7,
  minor = true,
  minor_color = "#e2e8f0",
  minor_linestyle = "dotted",
  minor_alpha = 0.4,
})

-- Histograms can grow horizontally, and stems can use a custom base/marker.
fig:hist(values, { orientation = "horizontal" })
fig:stem(x, samples, { base = 0.5, marker = "diamond", linestyle = "dashed" })
```

A `where` mask must be a table with one boolean per band sample. With
`interpolate = true`, each visible run gains a midpoint where it meets a hidden
sample. Reference spans, fill runs, horizontal bins, and stem bases participate
in automatic ranging as expected.

Axis, event, histogram, box, and image controls remain additive:

```lua
-- Subdivide each linear major interval into four minor parts.
fig:minorticks(true, { subdivisions = 4 })

-- Flatten event rows into horizontal lanes with per-row offsets and lengths.
fig:eventplot({ { 0.4, 1.1, 1.8 }, { 0.8, 1.4, 2.1 } }, {
  orientation = "horizontal",
  lineoffsets = { 1, 4 },
  linelengths = { 0.7, 1.0 },
})

-- Outline or fill the same histogram bins.
fig:hist(values, { histtype = "step" })       -- "bar" (default), "stepfilled"
fig:boxplot(samples, { orientation = "horizontal", labels = names })
fig:imshow(matrix, {
  colorbar_label = "value",
  colorbar_tick_values = { 0, 0.25, 0.5, 0.75, 1 },
})
```

`subdivisions` applies to linear minor tick marks and minor grid lines; log
axes keep their 2–9 mantissa ticks. Eventplot values are vertical (default) or
horizontal, and the scalar or per-row `lineoffsets`/`linelengths` control lane
placement. Horizontal boxplots put category labels on y. Image colorbars now
mirror the other heat-style colorbars: a title, uniform `colorbar_ticks`, or
explicit `colorbar_tick_values` (mutually exclusive).

Distribution means, per-row event colors, bar outlines, and image opacity are
also additive:

```lua
fig:eventplot(rows, { colors = { "#2ca02c", "#d62728", "#9467bd" } })
fig:boxplot(samples, { showmeans = true })            -- mean marker
fig:boxplot(samples, { showmeans = true, meanline = true })
fig:violinplot(samples, { showmeans = true })         -- or meanline = true
fig:bar(roles, scores, { linewidth = 3 })             -- also barh
fig:imshow(matrix, { alpha = 0.8 })
```

`colors` supplies one event color per lane. `showmeans` adds a mean marker,
and `meanline` replaces it with a dashed line across the box or violin;
`to_scene()` exports the mean and both flags. `linewidth` sets the bar outline
stroke, and image `alpha` fades every heatmap cell while leaving the colorbar
fully opaque.

Schedules, event labels, pie offsets, histogram outlines, and title alignment
round out the Cartesian controls:

```lua
-- One rectangle per {start, width} range at a fixed y interval.
fig:broken_barh({ { 0, 3 }, { 5, 2 } }, { 2, 0.6 }, { label = "build" })

-- Label event lanes; horizontal labels become x categories, vertical y.
fig:eventplot(rows, { labels = { "fast", "nominal", "slow" } })

-- Shift slices outward and draw soft shadows behind them.
fig:pie(values, { explode = { 0.08, 0, 0.12 }, shadow = true })

-- Thicker histogram outlines work for bar, step, and stepfilled styles.
fig:hist(values, { histtype = "step", linewidth = 2.5 })

fig:title("Aligned left", { loc = "left" })
```

`explode` accepts one offset or one per slice in [0, 0.5] of the radius.
`shadow` draws behind each wedge. `broken_barh` participates in automatic
ranging and legend/scene export, and histogram `linewidth` resolves through the
series style. `title` accepts `loc = "left"`, `"center"` (default), or
`"right"` for Figures, SubplotFigures, pies, and polar figures; scenes export
`title_align`. Axis labels accept `fontsize` and `color`; both values are
exported in scenes. Legend `borderpad` and `handlelength` tune frame padding
and swatch width on Cartesian and polar figures.

Legends, markers, error bars, and ECDF curves add the final control set:

```lua
fig:legend({
  loc = "center right",     -- also upper/lower center, center left/right
  framealpha = 0.75,
  facecolor = "#f8fafc",
  edgecolor = "#94a3b8",
})

fig:plot(x, y, {
  marker = "circle",
  markerfacecolor = "#ffffff",
  markeredgecolor = "#1f77b4",
  markeredgewidth = 1.2,
})

fig:errorbar(x, y, yerr, { errorevery = 3 })
fig:ecdf(values, { complementary = true })
```

`center` and the four edge-centre legend locations work on Cartesian and polar
figures, and the frame accepts opacity plus face/edge colors. Marker face and
edge options apply to filled marker shapes. `errorevery` keeps every line
vertex and marker but draws error bars only at the first point and every Nth
point after it. `ecdf(..., { complementary = true })` plots `1 - F_n(x)`.

Per-bar color lists, annotation boxes, label padding, pie distances, and empty
hist2d cells are also available:

```lua
fig:bar(quarters, { product, services }, {
  bar_colors = {
    { "#9ecae1", "#6baed6", "#4292c6", "#2171b5" },
    { "#fdae6b", "#fd8d3c", "#f16913", "#d94801" },
  },
})

fig:annotate("peak", 2.5, 4.1, {
  backgroundcolor = "#ffffff",
  backgroundedgecolor = "#d62728",
  backgroundalpha = 0.9,
  backgroundpad = 4,
})

fig:xlabel("x", { labelpad = 10 })
fig:ylabel("y", { labelpad = 8 })

fig:pie(values, { labeldistance = 1.14, pctdistance = 0.55 })
fig:hist2d(x, y, { show_empty = true })
```

`bar_colors` now accepts one flat list for a single series or one list per
series for grouped/stacked bars. Annotation backgrounds use approximate
Helvetica/Arial metrics to size the box; `backgroundpad` expands it around the
text. Axis label padding increases the corresponding layout margin, moving the
plot box away from the label. Pie distances are radius multipliers, and
`hist2d` includes zero-count cells when `show_empty` is true.

Markers, annotations, events, and horizontal hatches add more styling:

```lua
fig:scatter(x, y, { marker = { "circle", "square", "triangle", "diamond" } })
fig:annotate("slope", 1.2, 2.4, { rotation = -12 })
fig:errorbar(x, y, yerr, {
  markerfacecolor = "#ffffff", markeredgecolor = "#1f77b4",
})
fig:stem(x, y, { markerfacecolor = "#ffffff", markeredgecolor = "#8c564b" })
fig:eventplot(rows, { linestyle = "dashed" })
fig:barh(phases, effort, { hatch = "/" })
```

`scatter` accepts one marker or one marker per point (Cartesian and polar).
`rotation` applies to Cartesian and polar annotation text around its anchor.
Errorbar and stem markers now accept the same face/edge styling as line
markers. Eventplot lines support solid, dashed, dotted, and hidden styles, and
`barh` supports the shared hatch patterns. Scenes export per-point markers and
hatch styles.

Horizontal violins, rotated pie labels, fill/span hatches, and styled titles
complete the layout controls:

```lua
fig:violinplot(samples, { orientation = "horizontal", labels = names })
fig:pie(values, { labels = names, rotatelabels = true })
fig:fill_between(x, lower, upper, { hatch = "/" })
fig:axhspan(-0.2, 0.2, { hatch = "." })
fig:title("Styled title", { fontsize = 20, color = "#0f172a" })
```

Horizontal violins put cohort labels on y and measured values on x. Rotated pie
labels follow their slice angle, staying upright on the left half. Fill bands
and shaded spans use the shared hatch patterns. `title` now accepts
`fontsize`/`color` for Cartesian, pie, polar, and subplot titles; scenes export
the resolved style.

Axis-label typography, legend metrics, x limit arrows, scatter outline widths,
and logarithmic hexbin counts are additive:

```lua
fig:xlabel("x", { fontsize = 15, color = "#334155" })
fig:ylabel("y", { fontsize = 15, color = "#334155" })
fig:legend({ borderpad = 11, handlelength = 26 })
fig:errorbar(x, y, yerr, xerr, { xlolims = true, xuplims = { false, true } })
fig:scatter(x, y, { edgecolor = "#0f172a", linewidth = { 0.5, 1.2 } })
fig:hexbin(x, y, { norm = "log", colorbar = true })
```

`borderpad` expands the legend frame, and `handlelength` sets the swatch run
length. `xlolims`/`xuplims` replace horizontal caps with arrowheads. Scatter
`linewidth` may be one value or one per point. Hexbin `norm = "log"` colors by
`log(1 + count)` while colorbar labels remain counts.

Wedge outlines, per-point scatter edges, limit arrows, filled steps, and
explicit histogram edges are also additive:

```lua
fig:pie(values, { edgecolor = "#1f2937", linewidth = 1.2 })
fig:scatter(x, y, { edgecolor = { "#ffffff", "#0f172a" } })
fig:errorbar(x, y, yerr, {
  lolims = { true, false, false }, uplims = { false, true, false },
})
fig:step(x, y, { fill = true, fillalpha = 0.28 })
fig:hist(values, { bins = { 0, 1, 2.5, 4, 6 } })
```

`edgecolor` on scatter may be a per-point array. Errorbar `lolims`/`uplims`
replace the corresponding caps with arrowheads. Filled steps draw an area to
the zero baseline. Histogram `bins` may be a count or an explicit increasing
edge list; density accounts for each bin's actual width.

Scatter alpha, horizontal stems, quiver projection, tick styling, and histogram
hatches are also additive:

```lua
fig:scatter(x, y, { alpha = { 0.3, 0.6, 0.9 } })
fig:stem(positions, values, { orientation = "horizontal", base = 0.5 })
fig:quiver(x, y, u, v, { angles = "uv" })
fig:ticklabelsize(12)
fig:ticklabelcolor("#334155")
fig:hist(values, { histtype = "stepfilled", hatch = "/" })
```

Per-point alpha arrays work on Cartesian and polar scatter and export through
the scene style. Horizontal stems read values from `y` and positions from `x`,
growing from a base on the x axis. Quiver `angles = "uv"` draws directions in
screen space instead of through the data-axis transforms. Tick label size/color
adjust the Cartesian layout margins automatically, and histogram hatches work
for `bar` and `stepfilled` styles.

Box notches, per-arrow and per-event colors, pie text styling, and logarithmic
2-D histogram colors are also available:

```lua
fig:boxplot(samples, { notch = true, showmeans = true })
fig:quiver(x, y, u, v, { color = { "#1f77b4", "#f28e2b" } })
fig:eventplot(rows, { eventcolors = per_event_colors })
fig:pie(values, {
  labels = names, autopct = true,
  labelsize = 14, labelcolor = "#1f2937",
  pctsize = 11, pctcolor = "#f8fafc",
})
fig:hist2d(x, y, { color_norm = "log", colorbar = true })
```

Boxplot notches narrow the box around the median using the 1.57 * IQR / sqrt(n)
interval. Quiver `color` and eventplot `eventcolors` accept one color per
vector/event. Pie `labelsize`/`labelcolor` and `pctsize`/`pctcolor` style slice
and percentage text independently. Hist2d `color_norm = "log"` colors cells by
`log(1 + value)` while colorbar labels remain values.

Whisker controls, pie direction, explicit 2-D bin edges, per-point error colors,
and legend typography are additive:

```lua
fig:boxplot(samples, { whis = 1.0, showfliers = false })
fig:pie(values, { counterclock = true, startangle = 0 })
fig:hist2d(x, y, { bins = { x_edges, y_edges } })
fig:errorbar(x, y, yerr, { ecolor = { "#d62728", "#7c3aed" } })
fig:legend({ fontsize = 13 })
```

`whis` scales the IQR fences and `showfliers = false` hides outlier markers.
`counterclock` reverses pie slice order. Hist2d `bins` accepts explicit x/y edge
tables (or one edge table plus one count) and computes density with each cell's
actual area. Errorbar `ecolor` may contain one color per point. Legend
`fontsize` scales text and frame geometry on Cartesian and polar figures.

Per-sample box/violin widths, per-point errorbar sizes, and per-row event widths
are additive:

```lua
fig:boxplot(samples, { width = { 0.45, 0.62, 0.52 } })
fig:violinplot(samples, { width = { 0.55, 0.68, 0.60 } })
fig:errorbar(x, y, yerr, {
  markersize = { 4, 6, 5 },
  elinewidth = { 1, 2, 3 },
})
fig:eventplot(rows, { linewidth = { 2, 3, 4 } })
```

Box and violin widths accept one value per sample. Errorbar `markersize` and
`elinewidth` accept one value per point, applied to marker radii and error
strokes/caps. Eventplot `linewidth` accepts one value per row.

Box component visibility, quiver head shape, legend titles, and per-bar/bin
outline colors are additive:

```lua
fig:boxplot(samples, { showbox = true, showwhiskers = true, showcaps = false })
fig:quiver(x, y, u, v, { head = 7, headwidth = 1.4 })
fig:legend({ title = "series", title_fontsize = 15 })
fig:bar(labels, values, { edgecolors = { "#1f2937", "#7c3aed" } })
fig:barh(labels, values, { edgecolors = per_bar_colors })
fig:hist(values, { edgecolors = per_bin_colors })
```

`showbox`, `showwhiskers`, and `showcaps` toggle boxplot components. Quiver
`headwidth` controls the full head width relative to `head`. Legend
`title_fontsize` styles the title independently from `fontsize`. `edgecolors`
supplies one outline color per bar, per horizontal bar, or per histogram bin.

Per-sample box colors/opacity, violin opacity, quiver widths, and event opacity
are also available:

```lua
fig:boxplot(samples, {
  colors = { "#4c78a8", "#f58518", "#54a24b" },
  alpha = { 0.75, 0.6, 0.9 },
})
fig:violinplot(samples, { alpha = { 0.45, 0.6, 0.75 } })
fig:quiver(x, y, u, v, { linewidth = arrow_widths })
fig:eventplot(rows, { alpha = { 0.5, 0.75, 1 } })
```

Box `colors` accepts one color per sample, and `alpha` scales each box body
between fully transparent and the normal quarter-opacity fill. Violin
`alpha` accepts one body opacity per sample. Quiver `linewidth` may contain one
width per vector, and eventplot `alpha` one opacity per row.

Per-bar/bin outline widths, per-sample box/violin edges, and pie opacity are
also available:

```lua
fig:bar(labels, values, { linewidth = { 1, 2, 3, 4 } })
fig:barh(labels, values, { linewidth = per_bar_widths })
fig:hist(values, { bins = edges, linewidth = per_bin_widths })
fig:boxplot(samples, { edgecolors = { "#1e3a8a", "#7c2d12", "#14532d" } })
fig:violinplot(samples, { edgecolors = per_sample_edges })
fig:pie(values, { alpha = { 0.65, 0.75, 0.85, 0.95, 1 } })
```

Bar `linewidth` accepts one value per bar or one list per series, barh and hist
accept one value per bar/bin, and `hist` restricts width arrays to
`histtype = "bar"`. Box/violin `edgecolors` accept one outline color per
sample. Pie `alpha` accepts one value per slice.

Polar error/vector arrays, bold titles/labels, and legend layout controls are
also available:

```lua
fig:polar_errorbar(theta, r, rerr, {
  ecolor = per_point_colors, markersize = sizes, elinewidth = widths,
})
fig:polar_quiver(theta, r, u, v, {
  color = arrow_colors, linewidth = arrow_widths,
})
fig:title("Bold title", { fontweight = "bold" })
fig:xlabel("x", { fontweight = "bold" })
fig:ylabel("y", { fontweight = "bold" })
fig:legend({ markerfirst = false })
```

Polar errorbars accept per-point `ecolor`, `markersize`, and `elinewidth`
arrays; polar quiver accepts per-vector `color` and `linewidth` arrays. Titles
and axis labels accept `fontweight = "normal" | "bold"`, including pie, polar,
and subplot titles. Legend `markerfirst = false` places labels before swatches
on Cartesian and polar figures.

Polar bar outlines/opacity, pie text weights, and legend title alignment are
also available:

```lua
fig:polar_bar(theta, r, {
  edgecolors = per_bar_edges,
  linewidth = per_bar_widths,
  alpha = per_bar_alphas,
})
fig:pie(values, {
  labels = names, autopct = true,
  labelweight = "bold", pctweight = "bold",
})
fig:legend({ title = "series", title_align = "center" })
```

Polar bars accept one outline color, width, and opacity per bar. Pie
`labelweight`/`pctweight` style label and percentage text independently. Legend
`title_align = "left" | "center" | "right"` aligns the title within the frame.

Cartesian vector fields, hexagonal binning, explicit field coordinates, and
aspect constraints are also additive:

```lua
-- u/v are data-coordinate components; the largest glyph is auto-scaled.
fig:quiver(x, y, u, v, { pivot = "middle", max_arrows = 256, label = "flow" })

-- Count points per hexagon and add a labeled count colorbar.
fig:hexbin(x, y, {
  gridsize = 20,
  mincnt = 2,
  colorbar = true,
  colorbar_label = "points per cell",
})

-- Map a raster onto data coordinates and place row 1 at the bottom.
fig:imshow(values, { extent = { 100, 280, 20, 70 }, origin = "lower" })

-- Contours accept explicit column/row coordinates instead of matrix indices.
fig:contour(values, { levels = { 0.2, 0.4, 0.8 }, x = xs, y = ys })

-- Equal data units make one unit circle round on a rectangular canvas.
fig:aspect("equal")   -- or a positive number, or "auto" to reset
```

`gridsize` is the number of hexagons across x; rows are derived to keep regular
hexagons. Contour `x`/`y` vectors must match the matrix columns/rows. Aspect
constraints shrink and center the plot box inside the normal label margins;
extreme ratios that leave too little drawing area raise an error at render
time.

Error bars can use independent lower and upper errors:

```lua
fig:errorbar({ 1, 2, 3 }, { 10, 12, 11 }, {
  lower = { 0.5, 0.8, 0.6 },
  upper = { 1.2, 1.5, 1.0 },
}, { label = "asymmetric uncertainty" })
```

Symmetric numbers and flat arrays continue to work exactly as before.

Polar plots use radians for theta and accept negative radii, which are drawn on
the opposite side of the origin:

```lua
local theta, r = {}, {}
for i = 1, 181 do
  theta[i] = (i - 1) * 2 * math.pi / 180
  r[i] = 3 + math.sin(4 * theta[i])
end

local fig = plt.figure({ width = 620, height = 620 })
fig:polar(theta, r, { label = "3 + sin(4*theta)" })
fig:title("Polar rose")
fig:savefig("polar.svg")
```

`plt.polar(theta, r, opts)` is a shorthand that returns a figure with the
default 640x480 canvas. Polar figures draw concentric radial grid circles and
angular spokes with degree labels; the radial limit automatically covers the
largest absolute radius, including error-bar extents. `fig:polar_scatter` adds
polar markers with per-point sizes and colors, `fig:polar_bar` draws radial bar
wedges with optional per-bar widths and colors, and
`fig:polar_errorbar(theta, r, rerr, opts)` draws radial and optional angular
uncertainty. `fig:polar_quiver(theta, r, u, v, opts)` draws a vector field:
`u` is the local tangential component toward increasing theta and `v` is the
radial component, and both are projected into arrow glyphs whose lengths use
`scale` (or an automatic scale). Large fields are capped with `max_arrows`
(512 by default) and the SVG exposes `data-drawn`/`data-stride` metadata.
`fig:polar_streamplot(theta, r, u, v, opts)` integrates the same local-basis
field into curved streamlines: `theta` and `r` are strictly increasing grid
coordinates and `u`/`v` are rows-by-columns matrices sampled at every grid
node. Integration uses a fixed physical step (`step`, or an automatic step
from the radial span) with deterministic seeding, closed-orbit detection, and
`density`/`max_lines`/`max_points` caps. A grid whose theta span is one full
turn is treated as periodic, so lines wrap continuously across theta=0; a
partial sector stops at its edges. `linestyle` supports solid, dashed, dotted,
and hidden paths, and the single directional arrow is anchored by arc length:
`arrow_fraction` (0.5 by default, constrained to [0.05, 0.95]) moves it along
the integrated line. Arrow triangles are built in screen space, so a large
`head` or a late `arrow_fraction` can push a vertex past the polar circle; the
renderer projects such vertices back onto the circle and reports the result.
The series exposes `data-lines`, `data-points`, `data-step`, `data-periodic`,
`data-truncated`, `data-linestyle`, `data-arrow-fraction`,
`data-closed-lines`, `data-clip="polar-circle"`, and
`data-clipped-arrow-count`; each line carries
`data-points`/`data-arrows`/`data-clipped-arrows`/`data-closed` plus its seed
and `data-arc-length`, and each arrow carries `data-angle`, `data-fraction`,
and `data-clipped`. `to_scene()` exports the matching `cols`/`rows`,
`arrow_count`, `clipped_arrow_count`, `clip`, and per-line/per-arrow clipping
fields.
`fig:polar_heatmap(values, opts)` (alias `polar_pcolormesh`)
projects a rows-by-columns matrix as annular cells between `rmin`/`rmax` and
`theta_min`/`theta_max`; it renders beneath the other series, so lines and
annotations can be overlaid. Pass `colorbar = true` to a heatmap to add a
vertical colorbar with `colorbar_label`; `colorbar_ticks` chooses an even tick
count, while `colorbar_tick_values` accepts explicit (for example "nice")
values and exposes `data-value`/`data-fraction` metadata plus matching scene
arrays.
`fig:polar_contour(values, opts)` draws marching-squares isolines of the same
matrix, projected as curved paths; explicit or automatic `levels`, `labels`,
and the shared heatmap extent options keep contours aligned with the field.
Contour labels follow the local tangent, stay inside the circular clip, avoid
earlier labels and annotations, and are skipped rather than overlapped when the
frame is crowded.
`fig:polar_annotate` (or `fig:annotate` on a polar figure) places text and
leader arrows at `(theta, r)` coordinates.
Annotation target radii extend the automatic `rmax`; with an explicit limit, a
target outside it raises an error. Annotation text may sit outside the circle
but is shifted back inside the canvas when it would leave the viewport.
`fig:polar_config` sets the zero location (`"E"`, `"N"`, `"W"`, `"S"`),
clockwise/counterclockwise direction, explicit `rmax`, and custom
angular/radial grids; pass `degrees = true` to any polar series method to
supply theta in degrees. Labelled polar series, quivers, streamplots, heatmaps,
and contours participate in `fig:legend()`, which is placed so it does not cover
the angular
tick labels or the reserved colorbar column (`loc = "best"` searches for the
least obstructed spot). Heatmap legend swatches are stepped gradients.
Legend columns and titles are sized from UTF-8-aware Helvetica/Arial advance
widths, so wide glyphs reserve more room than narrow ones. `fig:to_scene()`
exports the polar grid, series (including vector fields), heatmaps, contours,
colorbar, annotations, and legend entries for non-SVG backends.
A figure cannot mix Cartesian and polar content.

```lua
fig:polar_errorbar({ 0, math.pi / 4 }, { 3.5, 3.8 }, { 0.35, 0.4 }, {
  thetaerr = { 0.12, 0.1 },
  label = "uncertainty",
})
fig:polar_annotate("maximum", math.pi / 2, 4.2, {
  xytext = { 1.85, 5.3 },
  align = "center",
  arrow = true,
})
local field = {
  { 0.2, 0.7, 0.4 },
  { 0.6, 1.0, 0.8 },
}
fig:polar_heatmap(field, {
  rmax = 6,
  label = "projected field",
  colorbar = true,
  colorbar_label = "value",
  colorbar_tick_values = { 0.2, 0.6, 1.0 },
})
fig:polar_contour(field, {
  levels = { 0.4, 0.8 },
  color = "#111111",
  labels = true,
  label = "isolines",
})
fig:polar_quiver({ 0, math.pi / 2 }, { 3, 3 }, { 1, 0 }, { 0, 1 }, {
  label = "flow",
})

-- Grid-sampled vector field: theta and r are coordinates, u and v are
-- rows-by-columns matrices of tangential/radial components at every node.
local theta_grid = { 0, math.pi, 2 * math.pi }
local r_grid = { 1, 2, 3 }
fig:polar_streamplot(theta_grid, r_grid, {
  { 1, 1, 1 },
  { 1, 1, 1 },
  { 1, 1, 1 },
}, {
  { 0.3, 0.3, 0.3 },
  { 0, 0, 0 },
  { -0.3, -0.3, -0.3 },
}, { label = "streamlines", density = 0.8, arrow_fraction = 0.6 })
```

Annotations use data coordinates and can include a leader arrow:

```lua
fig:annotate("local maximum", 2.5, 4.1, {
  xytext = { 3.5, 5.0 },
  align = "center",
  arrow = { color = "#d62728", linewidth = 1.5, head = 8 },
})
```

The label is drawn above the series and clipped to the Cartesian plot area.
Pass `arrow = true` for the default leader style, or omit `arrow` for plain
text. On polar figures `fig:annotate` accepts `(theta, r)` and isn't clipped to
the circle.

Bars accept several value series in one call. Grouped bars share category
centers, while stacked bars accumulate positive and negative values separately:

```lua
local quarters = { "Q1", "Q2", "Q3", "Q4" }
local fig = plt.figure()
fig:bar(quarters, {
  { 14, 18, 16, 22 },
  { 9, 11, 13, 12 },
}, { labels = { "Product", "Services" }, grouped = true })

local stacked = plt.figure()
stacked:bar(quarters, {
  { 14, 18, 16, 22 },
  { 9, 11, 13, 12 },
  { 2, -3, -2, 4 },
}, { labels = { "Product", "Services", "Adjustment" }, stacked = true })
```

`labels` (or a `label` in each series descriptor) adds one legend entry per
series. Series descriptors can also set `color`, `edgecolor`, and `alpha`.

## What works (MVP)

- `figure({width, height, dpi, xscale, yscale})` and `fig:to_svg()` /
  `fig:savefig(path)`
- Line plots with colors, dashes, marker face/edge styling, labels, and alpha
- Scatter plots with per-point markers, colors, edge colors, outline widths,
  sizes, and alpha, or numeric `c` values mapped through the heat palette and
  an optional colorbar
- Histograms with configurable counts/ranges or explicit bin edges,
  `bar`/`step`/`stepfilled` outlines, widths, and hatches, plus rectangular
  `hist2d` counts/densities with explicit grids, optional empty cells, value
  limits, and colorbars
- Vertical and horizontal bars with numeric positions or categorical labels,
  including multi-series grouped and stacked bars, per-bar color lists,
  configurable outline widths and hatches, and symmetric/asymmetric error bars
- Pie and donut charts with exploded slices, soft shadows, per-slice opacity,
  configurable clockwise/counterclockwise direction, wedge outlines,
  styled/weighted/rotated labels, and distance-tuned percentage annotations
- Empirical CDFs with post-step rendering and an optional complementary curve
- Vertical or horizontal box-and-whisker plots with optional notches, mean
  markers, or mean lines
- Vertical or horizontal Gaussian-kernel violin plots with per-sample widths,
  colors, edge colors, and opacity, configurable bandwidth, positions,
  quartiles, medians, extrema, and optional mean marks
- Vertical or horizontal event lanes with per-row offsets, lengths, colors,
  axis labels, line styles, and scene export
- Horizontal broken bars for schedules and Gantt-style intervals
- Polar line, scatter, bar, error-bar, quiver, heatmap, and contour plots with
  circular grid, theta/r ticks, configurable orientation and limits, rotated
  collision-aware contour labels, explicit colorbar ticks, measured-text
  label-aware legends, polar annotations with canvas clamping, and polar scene
  export
- Text annotations with optional leader arrows, rotation, and background boxes
  at Cartesian or polar data coordinates
- Symmetric or asymmetric vertical/horizontal error bars with independent lower
  and upper extents, optional `errorevery` decimation, configurable caps, and
  lower/upper and left/right limit arrowheads plus per-point error colors,
  marker sizes, and error line widths; polar errorbars support the same
  per-point arrays
- Linear or base-10 logarithmic `xscale` / `yscale` with automatic decade ticks
  and optional minor tick marks
- Auto-ranging, 5% data margins, and "nice" 1/2/2.5/5 based linear ticks
- Explicit `xlim` / `ylim`, optional major/minor grid, aligned and styled
  titles and axis labels with configurable weight, label padding/size/color,
  and legends with nine locations, frame alpha/colors, border padding,
  configurable handle lengths, independent label/title font sizes,
  marker-first ordering, and left/center/right title alignment
- Clipped infinite `axline` reference lines, full or fractional
  `axhline`/`axvline` spans, and marker decimation through `markevery`
- Masked or interpolated `fill_between`/`fill_betweenx` bands with optional
  hatch fills, plus hatched `axhspan`/`axvspan` bands
- Histograms with optional hatch fills, per-bin outline colors/widths, and
  styled stems with custom bases,
  markers, marker face/edge styling, and vertical or horizontal orientation
- Stacked areas with `zero`, `sym`, and `wiggle` baselines
- Cartesian and polar quiver vector fields with data-space or screen-space
  (`uv`) angles, automatic/explicit scaling, pivots, adjustable head width,
  per-vector colors/line widths, normalization, deterministic arrow caps, and
  legend/scene metadata
- Hexagonal and rectangular 2-D binning with minimum counts, value limits,
  explicit or count-based rectangular edges, linear or log count colors,
  explicit or uniform colorbar ticks, and renderer-agnostic cell/count export
- Image `extent`/`origin` mapping, image colorbar titles and explicit or
  uniform ticks, cell alpha, and explicit contour column/row coordinates
- Optional equal or numeric data-unit aspect ratios that center the plot box
- Independent major/minor grid color, width, dash, and opacity
- X/y tick-label rotation, size, and color, including twin axes
- XML-escaped text, no scripts, no external references, standalone SVG 1.1
- Plain Lua tables, plus optional duck-typed 1-D tensor/array inputs
  (luatorch/numlua style); neither library is required

See [docs/api.md](docs/api.md) for the full API and option tables.

## Tests

The suite is dependency-free and checks the generated SVG as text. It does not
need luatorch, numlua, xmllint, Python, or an image library.

```sh
./scripts/test.sh
# equivalent:
luajit tests/run.lua
# or:
make test
```

For an optional visual check, `scripts/visual-qa.sh` runs every example, checks
polar/colorbar/quiver metadata, verifies the Cartesian minor-tick,
marker-decimation, asymmetric-error, rotated-label, `axline`, fractional-span,
masked-fill, horizontal-histogram, styled-stem, grid-style, Cartesian-quiver,
hexbin-count, image-extent/origin, contour-coordinate, minor-subdivision,
horizontal-event, histogram-step, horizontal-box, image-colorbar, event-color,
event-label, distribution-mean, bar-outline, broken-bar, pie-explode,
histogram-outline, title-align, legend-location, legend-frame, marker-style,
errorbar-stride, ecdf-complementary, per-bar-color, annotation-background,
label-padding, pie-distance, hist2d-empty, scatter-marker, annotation-rotation,
error-stem-marker, event-linestyle, barh-hatch, scatter-alpha, stem-horizontal,
quiver-uv, tick-style, hist-hatch, violin-horizontal, pie-rotation,
fill-hatch, span-hatch, title-style, pie-edge, scatter-edge, errorbar-limit,
step-fill, hist-edges, label/legend styling, errorbar x limits, scatter
outline widths, log hexbin/hist2d counts, notched/whisker boxplots,
counterclockwise pie direction, per-arrow/event/error colors,
box/violin/error/event size arrays, pie text styling, legend title sizing,
box component visibility/colors/opacity/edges, violin edges, quiver
head/line widths, per-bar/bin outline colors/widths, pie opacity, polar error/vector arrays, bold titles/labels,
legend marker ordering, polar bar outlines/opacity, pie text weight, legend
title alignment, event
opacity, image-alpha, and equal-aspect metadata, and confirms that Cartesian
examples stay Cartesian.
When
`rsvg-convert` is installed it also rasterizes the polar SVGs and the affected
Cartesian examples for manual inspection. Rasterized files stay under the
ignored `examples/output/` directory.

To run the examples through the Makefile:

```sh
make examples
# examples/output/line.svg
# examples/output/histogram.svg
# examples/output/errorbar.svg
# examples/output/ecdf-complementary.svg
# examples/output/annotations.svg
# examples/output/axline.svg
# examples/output/cartesian-controls.svg
# examples/output/histogram-horizontal.svg
# examples/output/stem.svg
# examples/output/stem-horizontal.svg
# examples/output/quiver.svg
# examples/output/quiver-uv.svg
# examples/output/hexbin.svg
# examples/output/hist2d.svg
# examples/output/scatter-colors.svg
# examples/output/violinplot.svg
# examples/output/violin-horizontal.svg
# examples/output/stack-baseline.svg
# examples/output/bar-errors.svg
# examples/output/bar-linewidth.svg
# examples/output/barh-hatch.svg
# examples/output/broken-barh.svg
# examples/output/pie-explode.svg
# examples/output/pie-rotated.svg
# examples/output/pie-counterclock.svg
# examples/output/heatmap-extent.svg
# examples/output/contour-coords.svg
# examples/output/aspect.svg
# examples/output/minor-subdivisions.svg
# examples/output/eventplot-layout.svg
# examples/output/hist-styles.svg
# examples/output/hist-edges.svg
# examples/output/step-fill.svg
# examples/output/boxplot-horizontal.svg
# examples/output/imshow-colorbar.svg
# examples/output/bars-grouped.svg
# examples/output/bars-stacked.svg
# examples/output/polar.svg
# examples/output/polar-bars.svg
# examples/output/polar-annotations.svg
# examples/output/polar-heatmap.svg
# examples/output/polar-contour.svg
# examples/output/polar-quiver.svg
# examples/output/polar-streamplot.svg
# examples/output/polar-streamplot-styles.svg
# examples/output/polar-streamplot-clip.svg
```

Generated output and scratch files are ignored. There are no committed SVGs.

## Status

`4.28.0`. The SVG/HTML backend supports line/scatter/histogram/hist2d/bar/barh/
fill/step/stem/stack/fillx/pcolormesh/hexbin/violin/pie/donut/error-bar/box/
heatmap/contour/contourf plots, Cartesian quiver fields, image extents/origins,
explicit
contour coordinate grids, equal or numeric aspect ratios, polar
line/scatter/bar/error-bar/quiver/streamplot/heatmap/contour plots with
configurable orientation and grids, polar heatmap colorbars with explicit nice
ticks, rotated collision-aware polar contour labels, polar annotations with
canvas clamping, measured-text polar legends, annotations, asymmetric error
bars, linear/log/date axes, twin x/y axes, configurable minor subdivisions,
per-row event colors, event lane labels, box/violin means, broken horizontal
bars, pie explode/shadow, configurable bar/histogram outlines, marker
face/edge styling, per-point scatter markers/alpha/edges, annotation
rotation/backgrounds, horizontal stems, quiver uv angles, tick/title label
styling, horizontal violins, rotated pie labels, pie wedge outlines,
fill/span/step hatches and fills, errorbar x/y limit arrows, explicit
histogram edges, explicit 2-D edges, log hexbin/hist2d colors, box
notches/whisker controls, per-sample box/violin widths, counterclockwise pies,
per-arrow/event/error colors, per-point error marker/line sizes, per-row event
widths, box colors/opacity/edges and component visibility, violin
opacity/edges, quiver head widths/line widths, event opacity, bar/bin outline
colors/widths, pie opacity,
pie text styling, axis-label/legend typography, independent legend title sizes,
legend spacing, per-point scatter outline widths,
error-bar and stem marker styling, event line styles, barh/hist hatches,
error-bar decimation, complementary ECDFs, per-bar
multi-series colors, label padding, pie label/pct
distances, hist2d empty cells, image alpha, aligned titles, expanded legend
locations and frame styling, minor ticks and minor grids, clipped `axline`
reference lines, marker
decimation, x/y tick-label rotation, 3-D
line/scatter/surface/mesh, subplots, custom ticks, per-bar colors, value labels,
legends, reference lines, axis-specific grid lines, fractional reference
spans, masked fill bands, horizontal histograms, styled stems, independently
styled minor grids, 3-D scene export, per-point scatter sizes/colors, numeric
scatter color mapping with colorbars, rectangular 2-D histogram grids, KDE
violins, horizontal boxplots, box/violin mean marks, step/stepfilled
histograms, horizontal event lanes with per-row colors, configurable stack
baselines, bar error bars and outline widths, histogram density, image
colorbar titles, explicit ticks and cell alpha, multi-column legends, marker
shapes, shaded spans, log helpers, optional PNG/PDF export, and scene export.
See
[docs/stability.md](docs/stability.md) for the API policy.

## Limitations

- **SVG primary; PNG/PDF optional.** PNG/PDF export requires the system
  `rsvg-convert`; there is no interactive window or display server integration.
- **Polar axes are focused.** Polar figures support line, scatter, bar,
  error-bar, quiver, streamplot, heatmap, and contour projections plus
  annotations, with
  automatic or explicit radial limits, configurable zero location/direction,
  custom angular and radial grids, one vertical heatmap colorbar per figure with
  uniform or explicit tick values, rotated collision-aware contour labels, and
  measured-text label-aware legends; Cartesian and polar content cannot share
  a figure. Quiver glyphs are screen-space arrows capped at `max_arrows` (512
  by default), not data-unit extents. Polar twin axes are not implemented,
  contour labels may be skipped when the frame is too crowded, and contour
  levels that exactly equal a matrix sample can miss that degenerate contour
  branch. Streamlines use a fixed integration step rather than vector
  magnitude as speed, and their screen-space arrow glyphs are clipped to the
  polar frame circle.
- **Linear, log, and date-x axes.** Twin axes are supported.
- **3-D is basic.** Line, scatter, surface, and mesh rendering are available;
  full camera/lighting controls are not.
- **Basic layout.** Margins are adaptive, `xtick_rotation`/`ytick_rotation`
  help crowded labels, minor ticks subdivide major intervals, custom
  ticks/formatters are available, and subplot gap/margin are configurable.
  There is no full text-measurement layout engine yet. `aspect` centers a
  constrained plot box but does not change data limits or support
  `adjustable = "datalim"`.
- **Cartesian quiver glyphs are screen-space.** `scale` is a multiplier on the
  projected component displacement, `normalize` replaces magnitudes with unit
  directions, and arrow tips can be clipped at the axes rectangle. `angles =
  "uv"` uses screen-space components instead of data-axis transforms. The input
  `x`/`y` anchors define automatic ranging.
- **Distribution/color helpers are focused.** `violinplot` uses a Gaussian KDE
  (no alternate kernels, split violins, or per-sample bandwidth arrays), and
  numeric scatter colors always use the shared heat palette. `hist2d` omits
  empty cells unless `show_empty = true`, and bar `yerr` takes one error
  specification per value series rather than a freely mixed per-bar error
  matrix. Histogram hatching is unavailable for stepped outlines, which have no
  fill, and explicit histogram edges cannot be combined with `range`.
  Fill/span hatches use one shared pattern per series; rotated pie labels may
  still need a larger canvas or label distance for crowded slices. Axis-label
  font sizes and legend padding/handle length alter layout, but very large
  values can still crowd or clip within a fixed canvas. Box notches use the
  normal-approximation interval and clamp to the quartiles for small samples.
  Hidden fliers stay in scene `outliers` but no longer affect automatic
  ranges. Per-element widths, colors, opacity, outlines, and marker sizes must
  match the sample/point/row/bin count, and very large marker sizes can overlap
  neighboring points. Box `alpha` scales the filled body only; outlines and
  median/whisker marks remain fully opaque. Histogram width arrays are
  restricted to `histtype = "bar"`. Font weight supports normal/bold only;
  marker-first reversal uses estimated/measured label widths and can leave
  extra space in sparse columns. Polar bar arrays must match the full bar
  count, and pie text weights support normal/bold only.
- **Hexbin uses a regular x-grid.** `gridsize` is a single integer across x and
  rows are derived to keep regular cells; tuple grids, log-count normalization,
  and callback reductions are not supported.
- **Reference lines are clipped, not data series.** `axline` never expands the
  axes beyond its two defining points, and logarithmic axes draw it straight in
  transformed space. `axhline`/`axvline` fractional spans only change their
  screen extent; their data coordinate still defines automatic ranging. Minor
  ticks use 2–10 linear subdivisions (five by default) and skip logarithmic
  spans wider than 12 decades.
- **Fill masks are boolean tables.** `where` does not accept a callback or a
  numeric alpha mask, and interpolation uses the midpoint between adjacent
  samples. Horizontal histograms still use the same bin/density/cumulative
  calculation as vertical ones.
- **Bar color granularity.** `bar` accepts per-bar lists for each series, but
  categorical series with different label sets still share one categorical
  x-axis; `barh` remains single-series and accepts one hatch per call.
- **Heuristic tensor interop.** luatorch/numlua-style one-dimensional objects
  are detected from accessor methods (`dim`, `numel`, `get`, `totable`,
  `nDimension`, `nElement`, `size`, etc.). Multi-dimensional data must be
  flattened by the caller.
- **DPI is mostly metadata.** `dpi` determines the default 6.4 x 4.8 inch canvas
  and is emitted as `data-dpi`; explicit `width`/`height` are SVG user units and
  are not rescaled.
- **No font embedding.** SVG text uses a generic Helvetica/Arial/sans-serif
  stack and depends on the viewer's fonts.

## License

BSD-3-Clause. See [LICENSE](LICENSE).


## Renderer-agnostic scene export

`luaplotlib.scene.from_figure(figure)` (also `figure:to_scene()`) converts a
figure into plain JSON-compatible tables for non-SVG backends:

```lua
local figure = luaplotlib.figure()
figure:plot({1, 2, 3}, {2, 4, 3}, { label = "line" })
local scene = figure:to_scene()
-- scene.series, scene.xlim, scene.ylim, scene.title, ...
```

The scene contains series geometry, styles, axes labels, scales, explicit
limits, category ticks, and annotation geometry/styles. Cartesian scenes also
export asymmetric error extents, clipped `axline` anchors, fractional
`axhline`/`axvline` spans, normalized `markevery` lists, masked fill runs,
horizontal histogram orientation, stem bases, tick rotations, and resolved
major/minor grid styles. Cartesian quiver scenes add component arrays, scale
mode, pivot, decimation, and drawn counts; hexbin scenes add filtered cells,
counts, value limits, and colorbar settings; image scenes add `extent`/`origin`;
contour scenes add explicit coordinate arrays; and aspect-constrained roots add
`aspect`, `aspect_mode`, and `aspect_adjustable`. Polar figures export a
`polar` block with resolved theta/r ticks, series (including error bars and
vector fields), heatmap cells and value ranges, annotations, and legend entries
under `orientation = "polar"`. Streamplot lines add `closed`, `seed_theta`,
`seed_r`, and `arc_length`, while each arrow exports its anchor `index`,
arc-length `fraction`, direction `angle`, and data position. The export does not
depend on LÖVR or any graphics toolkit.
