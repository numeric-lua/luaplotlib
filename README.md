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
luajit examples/annotations.lua
luajit examples/axline.lua
luajit examples/cartesian_controls.lua
luajit examples/histogram_horizontal.lua
luajit examples/stem.lua
luajit examples/quiver.lua
luajit examples/hexbin.lua
luajit examples/field_coordinates.lua
luajit examples/aspect.lua
luajit examples/bars.lua
luajit examples/heatmap.lua
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
subdivide linear major intervals into five parts and use the 2–9 mantissas on
log axes, and `fig:grid(true, { minor = true })` adds their fainter grid. An
`axline` is clipped to the plot rectangle and participates in automatic ranging
only through its two defining points.

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
- Line plots with colors, dashes, markers, labels, and alpha
- Scatter plots rendered as SVG circles
- Histograms with configurable bins and ranges
- Vertical bars with numeric positions or categorical labels, including
  multi-series grouped and stacked bars
- Polar line, scatter, bar, error-bar, quiver, heatmap, and contour plots with
  circular grid, theta/r ticks, configurable orientation and limits, rotated
  collision-aware contour labels, explicit colorbar ticks, measured-text
  label-aware legends, polar annotations with canvas clamping, and polar scene
  export
- Text annotations with optional leader arrows at Cartesian or polar data
  coordinates
- Symmetric or asymmetric vertical/horizontal error bars with independent lower
  and upper extents
- Linear or base-10 logarithmic `xscale` / `yscale` with automatic decade ticks
  and optional minor tick marks
- Auto-ranging, 5% data margins, and "nice" 1/2/2.5/5 based linear ticks
- Explicit `xlim` / `ylim`, optional major/minor grid, titles, axis labels, and
  legends
- Clipped infinite `axline` reference lines, full or fractional
  `axhline`/`axvline` spans, and marker decimation through `markevery`
- Masked or interpolated `fill_between`/`fill_betweenx` bands
- Horizontal histograms and styled stems with custom bases and markers
- Cartesian quiver vector fields with automatic/explicit scaling, pivots,
  normalization, deterministic arrow caps, and legend/scene metadata
- Hexagonal binning with minimum counts, value limits, explicit or uniform
  colorbar ticks, and renderer-agnostic cell/count export
- Image `extent`/`origin` mapping and explicit contour column/row coordinates
- Optional equal or numeric data-unit aspect ratios that center the plot box
- Independent major/minor grid color, width, dash, and opacity
- X/y tick-label rotation, including twin y axes
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
hexbin-count, image-extent/origin, contour-coordinate, and equal-aspect
metadata, and confirms that Cartesian examples stay Cartesian. When
`rsvg-convert` is installed it also rasterizes the polar SVGs and the affected
Cartesian examples for manual inspection. Rasterized files stay under the
ignored `examples/output/` directory.

To run the examples through the Makefile:

```sh
make examples
# examples/output/line.svg
# examples/output/histogram.svg
# examples/output/errorbar.svg
# examples/output/annotations.svg
# examples/output/axline.svg
# examples/output/cartesian-controls.svg
# examples/output/histogram-horizontal.svg
# examples/output/stem.svg
# examples/output/quiver.svg
# examples/output/hexbin.svg
# examples/output/heatmap-extent.svg
# examples/output/contour-coords.svg
# examples/output/aspect.svg
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

`4.23.0`. The SVG/HTML backend supports line/scatter/histogram/bar/barh/
fill/step/stem/stack/fillx/pcolormesh/hexbin/pie/donut/error-bar/box/heatmap/
contour/contourf plots, Cartesian quiver fields, image extents/origins, explicit
contour coordinate grids, equal or numeric aspect ratios, polar
line/scatter/bar/error-bar/quiver/streamplot/heatmap/contour plots with
configurable orientation and grids, polar heatmap colorbars with explicit nice
ticks, rotated collision-aware polar contour labels, polar annotations with
canvas clamping, measured-text polar legends, annotations, asymmetric error
bars, linear/log/date axes, twin x/y axes, minor ticks and minor grids, clipped
`axline` reference lines, marker decimation, x/y tick-label rotation, 3-D
line/scatter/surface/mesh, subplots, custom ticks, per-bar colors, value labels,
legends, reference lines, axis-specific grid lines, fractional reference
spans, masked fill bands, horizontal histograms, styled stems, independently
styled minor grids, 3-D scene export, per-point scatter sizes/colors,
histogram density, multi-column legends, marker shapes, shaded spans, log
helpers, optional PNG/PDF export, and scene export. See
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
  directions, and arrow tips can be clipped at the axes rectangle. The input
  `x`/`y` anchors define automatic ranging.
- **Hexbin uses a regular x-grid.** `gridsize` is a single integer across x and
  rows are derived to keep regular cells; tuple grids, log-count normalization,
  and callback reductions are not supported.
- **Reference lines are clipped, not data series.** `axline` never expands the
  axes beyond its two defining points, and logarithmic axes draw it straight in
  transformed space. `axhline`/`axvline` fractional spans only change their
  screen extent; their data coordinate still defines automatic ranging. Minor
  ticks use a fixed five-way linear subdivision and skip logarithmic spans wider
  than 12 decades.
- **Fill masks are boolean tables.** `where` does not accept a callback or a
  numeric alpha mask, and interpolation uses the midpoint between adjacent
  samples. Horizontal histograms still use the same bin/density/cumulative
  calculation as vertical ones.
- **One color per bar series.** Colors are not split per bar, and categorical
  series with different label sets share one categorical x-axis.
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
