# luaplotlib API

Version: `0.2.0` (MVP). This document describes the public Lua API implemented
by `luaplotlib.lua` and the modules under `luaplotlib/`.

```lua
local plt = require("luaplotlib")
```

The module exposes:

- `plt.figure(opts)` → `Figure`
- `plt.Figure` — the Figure class table
- `plt._VERSION` — currently `"0.2.0"`

Requiring `luaplotlib` does not load luatorch, numlua, C libraries, or a GUI.

## Data inputs

The basic path accepts a non-empty, one-based Lua array of finite numbers:

```lua
local x = { 0, 1, 2, 3 }
local y = { 0, 1, 4, 9 }
```

Optional interop also accepts one-dimensional tensor/array objects with
luatorch-style accessors (`dim`/`numel`/`get`/`totable`/`shape`),
Torch7-style accessors (`nDimension`/`nElement`/`size`), or common
`n`/`size`/`shape` + `data` wrappers. Values are copied into a Lua table at
call time. Multi-dimensional objects are rejected with an error; flatten them
before plotting.

Category labels for `bar` are ordinary one-based tables containing strings
and/or finite numbers.

All data values must be finite. Empty data, `NaN`, infinities, and mismatched
x/y lengths raise errors.

## `plt.figure(opts)`

```lua
local fig = plt.figure({ width = 800, height = 500, dpi = 100 })
```

| Option | Type | Default | Meaning |
| --- | --- | --- | --- |
| `width` | number > 0 | `6.4 * dpi` | SVG canvas width in user units (pixels) |
| `height` | number > 0 | `4.8 * dpi` | SVG canvas height in user units (pixels) |
| `dpi` | number > 0 | `100` | Metadata and default-canvas scale |
| `xscale` | `"linear"` or `"log"` | `"linear"` | X-axis scale |
| `yscale` | `"linear"` or `"log"` | `"linear"` | Y-axis scale |

The default canvas is 640×480 at 100 dpi. `width` and `height` are explicit
SVG user units; `dpi` does not rescale an explicitly sized canvas. The SVG root
contains matching `width`, `height`, and `viewBox="0 0 width height"`
attributes plus `data-dpi`.

A figure that is too small to leave a usable plot area raises an error when
rendered.

## Figure methods

All configuration/drawing methods return the figure for chaining, except
`to_svg()` and `savefig()`.

### `fig:plot(x, y, opts)`

Draw a connected line series.

| Option | Type | Default |
| --- | --- | --- |
| `color` | `#RGB`, `#RRGGBB`, or CSS color name | next palette color |
| `label` | string | no legend entry |
| `linewidth` | number ≥ 0 | `2` |
| `linestyle` | `"solid"`, `"dashed"`, `"dotted"`, `"none"` | `"solid"` |
| `marker` | `"circle"`, `"o"`, `"point"`, `"dot"`, `true`, or `false` | `false` |
| `markersize` | number > 0 | `4` |
| `alpha` | number in [0, 1] | `1` |

A single-point line still renders its point. Unknown options, invalid colors,
and malformed data raise errors.

### `fig:barh(labels_or_y, values, opts)`

Horizontal bars for a single numeric series. Category labels are placed on the
y axis; `bar_colors` and `show_values` behave like `bar`.

### `fig:errorbar(x, y, yerr[, xerr][, opts])`

Draw a connected line and markers with symmetric vertical error bars, plus
optional horizontal error bars.

| Option | Type | Default |
| --- | --- | --- |
| `color` | color string | next palette color |
| `label` | string | no legend entry |
| `linewidth` | number ≥ 0 | `1.5` |
| `linestyle` | `"solid"`, `"dashed"`, `"dotted"`, `"none"` | `"solid"` |
| `marker` | marker name, `true`, or `false` | `"circle"` |
| `markersize` | number > 0 | `4` |
| `alpha` | number in [0, 1] | `1` |
| `capsize` | number ≥ 0, in SVG user units | `4` |
| `elinewidth` | number ≥ 0 | `1` |
| `ecolor` | color string | same as `color` |

`yerr` is required; `xerr` is optional. Either can be a single non-negative
number applied to every point, or an array with one non-negative value per
point. The four-argument form is accepted when the fourth argument is an
options table with string keys.

### `fig:scatter(x, y, opts)`

Draw one SVG circle per point.

| Option | Type | Default |
| --- | --- | --- |
| `color` | color string | next palette color |
| `label` | string | no legend entry |
| `size` | number > 0 | `4` |
| `markersize` | number > 0 | alias/precedence after `size` |
| `s` | number > 0 | additional size alias |
| `alpha` | number in [0, 1] | `1` |
| `edgecolor` | color string | no outline |
| `linewidth` | number ≥ 0 | `1` when an outline is present |

`size`/`markersize`/`s` are a circle **radius in SVG user units**, not
matplotlib's area-in-points-squared convention. The last listed aliases are
only used when the earlier ones are absent. Use `color` and `edgecolor`
deliberately: `color` is the fill.

### `fig:hist(values, opts)`

Draw a histogram as adjacent filled rectangles.

| Option | Type | Default |
| --- | --- | --- |
| `bins` | integer in [1, 1000] | `10` |
| `range` | `{ min, max }` with `min < max` | data min/max |
| `color` | color string | next palette color |
| `label` | string | no legend entry |
| `alpha` | number in [0, 1] | `1` |
| `edgecolor` | color string | `#ffffff` |

If all values are equal, the default range is padded around that value. Values
outside an explicit `range` are ignored. Counts are integers, and the automatic
y-axis includes zero. Empty bins are not emitted as rectangles.

### `fig:imshow(values, opts)`

Renders a rectangular matrix as a heatmap. Accepts a plain 2-D table or a
2-D tensor-like object exposing `dim()` and `totable()`. `opts.vmin`/`vmax` set the color
range; `colorbar` defaults to true. Values must be finite.

### `fig:boxplot(samples, opts)`

Draws box-and-whisker plots for one or more numeric samples. `opts.labels`
names the samples; whiskers use 1.5×IQR and outliers are drawn separately.

### `fig:contour(values, opts)`

Draws marching-squares contour lines. `opts.levels` is a level count or an
explicit level table.

### `fig:bar(labels_or_x, values, opts)`

Draw vertical bars. If `labels_or_x` is a table containing any strings, it is
treated as categorical labels positioned at 1, 2, 3, … and those labels become
the x-axis tick labels. If it is numeric, it contains x positions.

`values` can be one numeric sequence, a list of numeric sequences, a list of
series descriptors, or a label -> sequence map. A descriptor has the form
`{ values = {...}, label = "...", color = "...", edgecolor = "...", alpha = ... }`.
All series must have the same length as `labels_or_x`. Additional value series
may also be passed as separate arguments before the options table.

```lua
fig:bar({ "Q1", "Q2" }, {
  { 12, 15 },
  { 8, 11 },
}, {
  labels = { "North", "South" },
  grouped = true,
})
```

| Option | Type | Default |
| --- | --- | --- |
| `width` | number in [0.01, 1] | `0.8` |
| `color` | color string | next palette color |
| `colors` | table of color strings, one per series | palette colors |
| `label` | string | no legend entry |
| `labels` | table of strings, one per series | descriptor labels or none |
| `alpha` | number in [0, 1] | `1` |
| `edgecolor` | color string | `#ffffff` |
| `grouped` | boolean | `true` for multiple series |
| `stacked` | boolean | `false` |

`width` is a fraction of the smallest spacing between x positions (or 1 for a
single bar / categorical position). In grouped mode that width is shared by all
series in a group, so every group stays centered on its category position. In
stacked mode positive and negative values accumulate separately from zero.
`stacked = true` and `grouped = true` are mutually exclusive. `label` applies to
a single series; use `labels` (or descriptor labels) for multiple series. The
`labels` and `colors` tables must have exactly one entry per value series.

Negative values draw downward from zero. The automatic x extent includes grouped
offsets, and the automatic y extent includes stacked bottoms and total heights.
The y-axis includes zero. Category ticks are emitted once per call, even when the
call contains several series.

### `fig:xticks(values[, labels])` / `fig:yticks(values[, labels])`

Replace the automatically generated ticks with explicit data values and
optional labels. Labels must match the number of values.

### `fig:xtick_format(fn)` / `fig:ytick_format(fn)`

Set a formatter callback for generated and custom tick labels. The callback
receives the data value and returns a string.

### `fig:xdate([format])`

Formats x tick labels as calendar dates from Unix timestamps. `format` uses
`os.date` syntax and defaults to `"%Y-%m-%d"`.

### `fig:to_html([title])` / `fig:save_html(path[, title])`

Embed the SVG in a standalone HTML document.

### `fig:xtick_rotation(angle)`

Rotates x tick labels by an integer in `[-90, 90]`. Useful for long categorical
labels.

### Labels and titles

```lua
fig:title("text")
fig:xlabel("text")
fig:ylabel("text")
```

Arguments must be strings (empty strings are allowed). Text is XML-escaped and
invalid XML control characters are replaced. The y label is rotated -90°.

### Annotations and arrows

```lua
fig:annotate("peak", 2.5, 4.1)
fig:annotate("peak", 2.5, 4.1, {
  xytext = { 3.5, 5.0 },
  color = "#444444",
  fontsize = 13,
  align = "center",
  arrow = { color = "#d62728", linewidth = 1.5, head = 8 },
})
```

Add a text label anchored at data coordinates `(x, y)`. With no `xytext`, the
text is drawn at the anchor. With `xytext = { tx, ty }`, the text is drawn at
that data position instead and can be connected to `(x, y)` with an arrow.
Annotations are rendered above the series and clipped to the plot rectangle.

| Option | Type | Default |
| --- | --- | --- |
| `xytext` | `{ x, y }` data coordinates | same as `(x, y)`; offset up-right when `arrow` is set |
| `color` | color string | `#222222` |
| `fontsize` | number > 0, in SVG user units | `12` |
| `align` | `"left"`, `"center"`, or `"right"` | `"left"` |
| `arrow` | boolean or options table | no arrow |

`arrow = true` draws a leader line from the text to `(x, y)` using the
annotation color. It also accepts a table with `color`, `linewidth` (or
`width`), and `head` (or `headsize`) values; `head` is the arrowhead length in
SVG user units and defaults to `8`. Set `arrow = false` or omit it for plain
text. If `arrow` is enabled without `xytext`, the label is offset slightly
up-right so the leader line is visible.

Annotation coordinates use the same data space and log transformations as
series. On a logarithmic axis, both the annotated point and any `xytext`
coordinates must be strictly positive. Annotations do not affect automatic axis
ranging; use `xlim`/`ylim` if a label needs to sit outside the data extents.
Unknown options, invalid colors/alignment/font sizes, and malformed `xytext` or
`arrow` tables raise a `luaplotlib:` error.

### `fig:twinx()`

Create a secondary y axis sharing the x axis. The returned object supports
`plot`, `scatter`, `errorbar`, and `bar`, plus `ylim`, `yscale`, and `ylabel`.
It renders on the right with independent ticks and a right-side label.

### Limits

```lua
fig:xlim(minimum, maximum)
fig:ylim(minimum, maximum)
```

Both values must be finite and `minimum < maximum`. Explicit limits replace
auto-ranging for that axis. Data outside the limits is clipped to the axes
rectangle. Tick values are chosen with "nice" linear spacing inside the limits,
or with logarithmic decade ticks when that axis uses a log scale. Log limits
must be strictly positive.

### Axis scales

```lua
fig:xscale("log")
fig:yscale("log")
fig:xscale("linear")   -- restore the default
fig:yscale("linear")
```

| Method | Type | Default |
| --- | --- | --- |
| `xscale` | `"linear"` or `"log"` | `"linear"` |
| `yscale` | `"linear"` or `"log"` | `"linear"` |

The same values can be supplied in `plt.figure({ xscale = "log", yscale = "log" })`.
Logarithmic axes are base 10. They require strictly positive data on the scaled
axis; zero, negative, `NaN`, and infinite values raise a `luaplotlib:` error at
render time. For `xscale = "log"`, bar positions and histogram edges must also
be positive; a bar's derived left edge is clipped to the axis if it would cross
zero. On a log y axis, zero-count histogram bins are omitted rather than treated
as data, and bars grow from the bottom of the visible plot area because zero is
not representable.

### Grid

```lua
fig:grid(true)
fig:grid(false)
fig:grid()       -- same as true
```

Grid is off by default. Grid lines align with the rendered x and y ticks and are
drawn behind series.

### Legend

```lua
fig:legend()
fig:legend({ loc = "lower left", frame = false })
```

No options are required.

| Option | Type | Default |
| --- | --- | --- |
| `loc` | `"upper right"`, `"upper left"`, `"lower right"`, `"lower left"` | `"upper right"` |
| `frame` | boolean | `true` |

Only series with a non-empty `label` appear. Swatches reflect the series type
(line, point, or bar). Calling `legend()` with no labeled series produces no
legend box.

### `fig:to_svg()`

Returns the complete SVG document as a string. There is no I/O. Repeated calls
on an unchanged figure are deterministic.

### `fig:savefig(path)`

Writes the same SVG returned by `to_svg()` to `path` in binary mode and returns
the path. It does not create parent directories. Use `to_svg()` if you need the
string instead. File-open and write failures raise a `luaplotlib:` error.

## Subplots

`plt.subplots(rows, cols, opts)` returns a subplot figure and a row-major matrix
of independent axes figures:

```lua
local fig, axes = plt.subplots(2, 2, { width = 900, height = 700 })
axes[1][1]:plot(x, y)
axes[2][2]:imshow(matrix)
fig:title("Grid")
fig:savefig("grid.svg")
```

The subplot figure supports `title`, `savefig`, `to_svg`, `axes_at`, and
`share_limits("x" or "y"[, index])`. `gap` and `margin` are configurable.

## Automatic ranging and ticks

- Automatic limits cover all series extents plus a 5% margin.
- Bars and histograms keep their zero baseline at the axis edge rather than
  padding into negative space when all values are on one side of zero.
- Linear tick spacing is a "nice" multiple: 1, 2, 2.5, or 5 times a power of ten.
- Log axes range in base-10 space and prefer decade ticks (`0.1`, `1`, `10`,
  `100`, …). Narrow ranges fall back to 1/2/2.5/5 mantissas, and very large
  spans are thinned so labels do not collide.
- The number of ticks adapts to the axes size (roughly 3–8 per axis).
- Tick labels use compact decimal/scientific formatting.
- Categorical bar positions replace numeric x tick labels.
- Linear and base-10 logarithmic x/y axes are supported. There are no date,
  twin, or polar axes yet.

## Color cycle

The default color cycle is Matplotlib tab10-inspired:

`#1f77b4`, `#ff7f0e`, `#2ca02c`, `#d62728`, `#9467bd`, `#8c564b`, `#e377c2`,
`#7f7f7f`, `#bcbd22`, `#17becf`.

Colors can be given as `#RGB`, `#RRGGBB`, or CSS color names. Values that do not
match these forms raise errors.

## SVG contract

`to_svg()` produces a standalone SVG 1.1 document:

- XML declaration and `xmlns="http://www.w3.org/2000/svg"`
- Root `width`, `height`, and `viewBox`, plus `data-dpi`, `data-xscale`, and
  `data-yscale` metadata
- White background rectangle
- A clip path limiting series and annotations to the axes rectangle
- Groups with classes such as `figure`, `grid`, `series-layer`, `series-line`,
  `series-scatter`, `series-hist`, `series-bar`, `annotation-layer`,
  `annotation`, `annotation-text`, `annotation-arrow`, `axes`, `ticks`,
  `xlabel`, `ylabel`, `title`, and `legend`
- No scripts, embedded images, or external references/hrefs
- User text XML-escaped; invalid control characters replaced with U+FFFD
- No external fonts; text uses a generic Helvetica/Arial/sans-serif stack

The output is intended for browsers, SVG viewers, and conversion tools. It has
no raster dependencies and no JavaScript.

## Errors

Errors are raised as Lua errors with a `luaplotlib:` prefix. Invalid input
includes, but is not limited to:

- non-positive/non-finite figure dimensions or dpi
- unknown option keys
- invalid colors, line styles, markers, alpha, or legend locations
- invalid axis scale names (anything other than `"linear"` or `"log"`)
- non-positive data or limits on a logarithmic axis
- empty/non-numeric/multi-dimensional data
- mismatched x/y or labels/values lengths
- `NaN`/infinite values
- reversed or empty axis limits
- writing to a nonexistent directory

## Limitations

- SVG only; no interactive display yet.
- No date axes, 3-D plots, images, or subplots.
- Basic fixed/adaptive margins; crowded category labels can overlap.
- One color per series; per-bar color arrays are not supported.
- Only one categorical x-axis mapping is used per figure.
- Tensor/array interop is heuristic and reader-only; optional integrations are
  not required to use the library.


## Scene export

### `luaplotlib.scene.from_figure(figure)`

Returns a renderer-agnostic scene table:

```lua
{
  version = 1,
  type = "luaplotlib",
  width = 640, height = 480, dpi = 100,
  title = "...", xlabel = "...", ylabel = "...",
  xscale = "linear", yscale = "linear",
  xlim = { min, max }, ylim = { min, max },
  grid = false, legend = false,
  category_ticks = nil,
  series = {
    { kind = "line", x = {...}, y = {...}, style = {...} },
    { kind = "scatter", x = {...}, y = {...}, style = {...} },
    { kind = "bar", x = {...}, y = {...}, width = 0.8 },
    -- Grouped bars keep category centers in x and add a per-series offset:
    { kind = "bar", x = {...}, y = {...}, width = 0.4, mode = "grouped",
      grouped = true, offset = -0.2, offsets = {...} },
    -- Stacked bars add the bottom/top interval for every bar:
    { kind = "bar", x = {...}, y = {...}, width = 0.8, mode = "stacked",
      stacked = true, bottom = {...}, top = {...}, stack = {...} },
    { kind = "hist", edges = {...}, counts = {...} },
  },
  annotations = {
    {
      kind = "annotation", text = "peak", x = 2.5, y = 4.1,
      xytext = { 3.5, 5.0, x = 3.5, y = 5.0 },
      color = "#444444", fontsize = 13, align = "center",
      style = { color = "#444444", fontsize = 13, align = "center" },
      arrow = { enabled = true, color = "#444444", linewidth = 1.5, head = 8 },
    },
  },
}
```

`Figure:to_scene()` is a convenience wrapper.  Limits default to the data range
with 5% padding, or the explicit `xlim`/`ylim` values. Log-axis limits are
padded in log space and remain positive. Annotations retain data coordinates
and style so another backend can apply its own coordinate transform; they do not
affect the exported limits. Bar series always keep category centers in `x`.
Grouped series also expose a scalar `offset` plus an `offsets` array; stacked
series expose the per-bar `bottom`, `top`, and `stack` arrays so a backend does
not have to infer the layout from the rendered SVG.
