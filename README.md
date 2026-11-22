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
partial sector stops at its edges. Streamlines expose `data-lines`,
`data-points`, `data-step`, `data-periodic`, and `data-truncated`, and each
line carries `data-points`/`data-arrows` plus per-arrow `data-angle` metadata.
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
}, { label = "streamlines", density = 0.8 })
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
- Linear or base-10 logarithmic `xscale` / `yscale` with automatic decade ticks
- Auto-ranging, 5% data margins, and "nice" 1/2/2.5/5 based linear ticks
- Explicit `xlim` / `ylim`, optional grid, titles, axis labels, and legends
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

For an optional visual check of the polar examples, `scripts/visual-qa.sh`
runs every example, checks polar/colorbar/quiver metadata and that Cartesian
examples stay Cartesian, and rasterizes the polar SVGs with `rsvg-convert` when
that tool is installed. Rasterized files stay under the ignored `examples/output/`
directory.

To run the examples through the Makefile:

```sh
make examples
# examples/output/line.svg
# examples/output/histogram.svg
# examples/output/errorbar.svg
# examples/output/annotations.svg
# examples/output/bars-grouped.svg
# examples/output/bars-stacked.svg
# examples/output/polar.svg
# examples/output/polar-bars.svg
# examples/output/polar-annotations.svg
# examples/output/polar-heatmap.svg
# examples/output/polar-contour.svg
# examples/output/polar-quiver.svg
# examples/output/polar-streamplot.svg
```

Generated output and scratch files are ignored. There are no committed SVGs.

## Status

`4.18.0`. The SVG/HTML backend supports line/scatter/histogram/bar/barh/
fill/step/stem/stack/fillx/pcolormesh/pie/donut/error-bar/box/heatmap/contour/contourf plots,
polar line/scatter/bar/error-bar/quiver/streamplot/heatmap/contour plots with configurable
orientation and grids, polar heatmap colorbars with explicit nice ticks, rotated
collision-aware polar contour labels, polar annotations with canvas
clamping, measured-text polar legends, annotations, linear/log/date axes, twin
x/y axes, 3-D line/scatter/surface/mesh, subplots, custom ticks, per-bar colors,
value labels, legends, reference lines, axis-specific grid lines, 3-D scene
export, per-point scatter sizes/colors, histogram density, multi-column legends,
marker shapes, shaded spans, log helpers, optional PNG/PDF export, and scene
export. See [docs/stability.md](docs/stability.md) for the API policy.

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
  magnitude as speed.
- **Linear, log, and date-x axes.** Twin axes are supported.
- **3-D is basic.** Line, scatter, surface, and mesh rendering are available;
  full camera/lighting controls are not.
- **Basic layout.** Margins are adaptive, `xtick_rotation` helps crowded
  categorical axes, custom ticks/formatters are available, and subplot
  gap/margin are configurable. There is no full text-measurement layout engine
  yet.
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
limits, category ticks, and annotation geometry/styles. Polar figures export a
`polar` block with resolved theta/r ticks, series (including error bars and
vector fields), heatmap cells and value ranges, annotations, and legend entries
under `orientation = "polar"`. The export does not depend on LÖVR or any graphics
toolkit.
