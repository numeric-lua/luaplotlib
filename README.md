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
- No external Lua rocks, C modules, Python packages, or fonts are needed.
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

Annotations use data coordinates and can include a leader arrow:

```lua
fig:annotate("local maximum", 2.5, 4.1, {
  xytext = { 3.5, 5.0 },
  align = "center",
  arrow = { color = "#d62728", linewidth = 1.5, head = 8 },
})
```

The label is drawn above the series and clipped to the plot area. Pass
`arrow = true` for the default leader style, or omit `arrow` for plain text.

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
- Text annotations with optional leader arrows at data coordinates
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

To run the examples through the Makefile:

```sh
make examples
# examples/output/line.svg
# examples/output/histogram.svg
# examples/output/errorbar.svg
# examples/output/annotations.svg
# examples/output/bars-grouped.svg
# examples/output/bars-stacked.svg
```

Generated output and scratch files are ignored. There are no committed SVGs.

## Status

`4.0.0`. The SVG/HTML backend supports line/scatter/histogram/bar/barh/
fill/step/stem/stack/fillx/pcolormesh/pie/donut/error-bar/box/heatmap/contour/contourf plots,
annotations, linear/log/date axes, twin x/y axes, subplots, custom ticks,
per-bar colors, value labels, legends, and scene export. See
[docs/stability.md](docs/stability.md) for the API policy.

## Limitations

- **SVG only.** There is no interactive window, HTML widget, PNG/PDF output, or
  display server integration yet.
- **Linear and log axes only.** Date axes, twin axes, and polar plots are not
  implemented.
- **No 3-D or pie charts yet.** Heatmaps, contours, and boxplots are available;
  pie charts and 3-D plots are not.
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
limits, category ticks, and annotation geometry/styles.  It does not depend on
LÖVR or any graphics toolkit.
