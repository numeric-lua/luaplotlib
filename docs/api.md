# luaplotlib API

Version: `4.18.0`. This document describes the public Lua API implemented
by `luaplotlib.lua` and the modules under `luaplotlib/`.

```lua
local plt = require("luaplotlib")
```

The module exposes:

- `plt.figure(opts)` → `Figure`
- `plt.subplots(rows, cols, opts)` → `SubplotFigure, axes`
- `plt.polar(theta, r, opts)` → `Figure`
- `plt.Figure` — the Figure class table
- `plt._VERSION` — currently `"4.18.0"`

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
| `marker` | `"circle"`, `"square"`, `"triangle"`, `"diamond"`, `"cross"`, `"x"`, aliases, `true`, or `false` | `false` |
| `markersize` | number > 0 | `4` |
| `alpha` | number in [0, 1] | `1` |

A single-point line still renders its point. Unknown options, invalid colors,
and malformed data raise errors.

### `fig:pie(values[, opts])` / `fig:donut(values[, opts])`

Pie and donut charts. Values must be non-negative with a positive total.
Options include `labels`, `colors`, `startangle`, `radius`, `inner_radius`,
`autopct`, and `legend`. `donut` defaults `inner_radius` to 0.55.

### `plt.polar(theta, r[, opts])` / `fig:polar(theta, r[, opts])`

Draw a polar line series. `theta` is in radians; negative `r` values are drawn
on the opposite side of the origin. Both arrays must be non-empty, finite, and
the same length. Options are `color`, `label`, `linewidth`, `linestyle`,
`marker`, `markersize`, and `alpha`, with the same validation as `plot`.
`degrees = true` (or `theta_unit = "degrees"`) interprets the theta values as
degrees and converts them to radians immediately; the two options cannot be
combined.

`plt.polar` creates a default 640x480 figure and returns it. `fig:polar` adds a
series to an existing figure; calling it more than once adds more polar line
series. A figure cannot contain both Cartesian and polar series. Polar figures
draw eight angular spokes at 45-degree intervals with degree labels, concentric
radial grid circles, and an automatically chosen radial limit covering the
largest absolute radius (including radial error bars when present). `to_svg`,
`to_html`, and `savefig` work as usual.

### `fig:polar_scatter(theta, r, opts)`

Draw one marker per polar point. `theta` and `r` must be the same length and
finite. `marker` selects circle (the default), square, triangle, diamond, cross,
or x. `size` (or its `markersize`/`s` aliases) is a marker radius in SVG user
units and may be a single number or an array with one radius per point. `color`
may be a single color or an array with one fill color per point; `alpha`,
`edgecolor`, and `linewidth` behave like Cartesian `scatter`. Sizes and color
arrays must match the number of points. `degrees`/`theta_unit` are accepted as
in `fig:polar`.

Polar line, scatter, bar, error-bar, and heatmap entries with labels
participate in `fig:legend()`. The polar legend supports the same `loc`,
`frame`, `ncol`, and `title` options as the Cartesian renderer, plus
`loc = "best"`. Placement is label-aware: the renderer estimates the angular
and radial tick-label boxes and prefers a frame position that covers none of
them, falling back to the least obstructed candidate when the canvas is too
small. Column, frame, and title widths use estimated Helvetica/Arial advance
widths for each UTF-8 codepoint instead of counting characters, so wide glyphs
(`M`, `W`, `m`, `w`) reserve more space than narrow ones (`i`, `l`, `.`). The
legend group exposes `data-x`, `data-y`, `data-width`, `data-height`,
`data-text-width`, `data-loc`, and `data-placement` (`"inside"` or
`"outside"`) so tests and tooling can inspect the resolved box. `data-text-width`
is the widest measured entry label at the legend font size. For Cartesian
figures `"best"` currently resolves to the upper-right corner.

### `fig:polar_bar(theta, r, opts)`

Draw radial bar wedges. `theta` and `r` must be the same length; `r` values must
be non-negative. `width` is the angular span of each bar in radians and defaults
to `0.8`; it may be a single number or an array with one width per bar. Widths
must be greater than zero and at most `2*pi`; a full-turn bar is rendered as a
disk. `colors` may provide one fill color per bar, while `color`, `alpha`,
`edgecolor`, and `label` behave like Cartesian bars. `color` and `colors` cannot
be combined. `degrees`/`theta_unit` are accepted as in `fig:polar`.

### `fig:polar_heatmap(values, opts)` / `fig:polar_pcolormesh(values, opts)`

Project a rectangular value matrix onto the polar axes as annular cells. The
matrix is a non-empty 2-D table (or a 2-D tensor with `totable()`); `rows` map
linearly from `rmin` to `rmax` and `cols` map linearly from `theta_min` to
`theta_max`. Rows increase outward and columns increase with data theta, so
`theta_direction` and `theta_zero` rotate the projected field together with
the grid. Cells use the same viridis-like palette as Cartesian heatmaps.

| Option | Type | Default |
| --- | --- | --- |
| `vmin` | finite number | matrix minimum |
| `vmax` | finite number | matrix maximum |
| `rmin` | number ≥ 0 | `0` |
| `rmax` | number > `rmin` | configured polar `rmax`, else `rows` |
| `theta_min` | finite number | `0` (`0` degrees) |
| `theta_max` | finite number, span ≤ `2*pi` | `2*pi` (`360` degrees) |
| `degrees` / `theta_unit` | boolean / `"radians"` or `"degrees"` | radians |
| `alpha` | number in [0, 1] | `1` |
| `label` | string | no legend entry |
| `colorbar` | boolean | `false` |
| `colorbar_label` | string | no colorbar title |
| `colorbar_ticks` | integer in [2, 9] | `3` |
| `colorbar_tick_values` | strictly increasing number array, 2–12 entries within `vmin`/`vmax` | evenly spaced `colorbar_ticks` values |

The optional `rmax` fixes the heatmap's own outer radius. If it is omitted, a
configured `polar_config.rmax` is used; without either, each matrix row is one
radial unit. Heatmaps render beneath line/scatter/bar/error-bar series, so a
curve or annotation can be overlaid. A full-turn heatmap is drawn as a disk
for its innermost band and as annuli otherwise; partial sweeps draw sector
cells. Heatmaps participate in `fig:legend()` with a stepped gradient swatch
and in scene export under `polar.heatmaps`. Explicit `rmax` values that do not
cover a heatmap or data extent raise an error when rendered.

`colorbar = true` reserves a canvas column to the right of the polar circle and
draws a vertical `polar-colorbar` group with a stepped palette, a frame, tick
marks, and an optional rotated `colorbar_label`. Ticks are evenly spaced from
`vmin` to `vmax` by default, or placed at explicit `colorbar_tick_values` (for
example `{ -1, -0.5, 0, 0.5, 1 }`) when supplied; `colorbar_ticks` and
`colorbar_tick_values` cannot be combined. Tick labels use three significant
digits, and the SVG exposes `data-value`/`data-fraction` on each tick and label
plus `data-tick-source = "uniform" | "explicit"` on the group. The polar circle
is reduced to make room, and the legend planner treats the colorbar column as
occupied. At most one heatmap per polar figure can request a colorbar;
`fig:to_scene()` exports it as `polar.colorbar` with exact tick values, labels,
and fractions.

### `fig:polar_contour(values, opts)`

Draw isolines of a rectangular matrix over the polar axes. The matrix has the
same orientation as `fig:polar_heatmap` (rows run outward, columns sweep with
data theta) and must be at least 2x2. Marching squares runs over the matrix
corners, so a contour from the same matrix overlays the heatmap extent. The
projected segments are sampled in `(theta, r)` space and rendered as curved
paths, clipped to the polar circle. Contours render above heatmaps and below
line/scatter/bar/error-bar series.

| Option | Type | Default |
| --- | --- | --- |
| `levels` | positive integer ≤ 50 or non-empty number array | `5` |
| `color` | color string | next palette color |
| `linewidth` | number ≥ 0 | `1.5` |
| `linestyle` | `"solid"`, `"dashed"`, `"dotted"`, or `"none"` | `"solid"` |
| `alpha` | number in [0, 1] | `1` |
| `labels` | boolean | `false` |
| `label` | string | no legend entry |
| `vmin` / `vmax` | finite number | matrix minimum / maximum |
| `rmin` / `rmax` | number ≥ 0 / number > `rmin` | `0` / configured `rmax`, else `rows` |
| `theta_min` / `theta_max` | finite numbers, span ≤ `2*pi` | `0` / `2*pi` |
| `degrees` / `theta_unit` | boolean / `"radians"` or `"degrees"` | radians |

`labels = true` draws white-haloed level labels along the contour lines. Each
label is rotated to the local tangent (kept upright), pulled inside the circular
clip, and placed on the farthest segment that does not collide with earlier
labels, radial tick labels, or annotations. If every candidate would overlap,
that level is skipped rather than drawn unreadably. The SVG exposes
`data-level` and `data-angle` on each label. Contours extend the automatic
radial limit exactly like heatmaps; an explicit `polar_config.rmax` must cover
them. Labelled contours participate in `fig:legend()` (the legend planner also
avoids their labels) and scene export under `polar.contours`; each scene level
carries a `label` table with the preferred `text`, `theta`, `r`, `u`, `v`, and
upright `angle` when labels are enabled. Levels that exactly equal a matrix
sample are ambiguous in marching squares and can drop that degenerate branch;
use a level between sample values.

### `fig:polar_errorbar(theta, r, rerr, opts)`

Draw polar error bars. `rerr` is a non-negative radial error, either one number
for every point or an array matching `theta`. `thetaerr` optionally adds
angular errors in the same unit as `theta` (radians by default, degrees with
`degrees = true`/`theta_unit = "degrees"`); it also accepts a scalar or an array
and must be at most `2*pi`. Angular errors at or above `pi` render as a full
circle around the data point. `capsize = 0` suppresses the end caps.

| Option | Type | Default |
| --- | --- | --- |
| `rerr` | number ≥ 0 or array (required) | — |
| `thetaerr` | number ≥ 0 or array, ≤ `2*pi` radians | no angular error |
| `color` | color string | next palette color |
| `label` | string | no legend entry |
| `linewidth` | number ≥ 0 | `1.5` |
| `linestyle` | `"solid"`, `"dashed"`, `"dotted"`, or `"none"` | `"solid"` |
| `marker` | marker name, `true`, or `false` | `"circle"` |
| `markersize` | number > 0 | `4` |
| `alpha` | number in [0, 1] | `1` |
| `capsize` | number ≥ 0 | `4` |
| `elinewidth` | number ≥ 0 | `1` |
| `ecolor` | color string | same as `color` |

The connecting line is drawn unless `linestyle = "none"`. Automatic radial
limits include `abs(r) + rerr`, so error bars are never clipped by the default
frame. Explicit `rmax` values that do not cover the error extents raise an
error when rendered.

### `fig:polar_quiver(theta, r, u, v, opts)`

Draw one arrow per `(theta, r)` position. `u` is the component in the
direction of increasing data theta and `v` is the radial component pointing
outward; both are data-space components in the local orthonormal polar basis
and may be negative. The renderer rotates that pair into screen space using
the configured `theta_zero`/`theta_direction`, so clockwise axes flip the
tangential direction while radial arrows keep pointing outward. `theta`, `r`,
`u`, and `v` must be non-empty, finite arrays of equal length.

Arrow glyphs are sized in SVG user units rather than data units, so a vector
field remains readable when the radial limit changes. `scale` is the glyph
length in user units per unit of vector magnitude; omit it for an automatic
scale whose longest arrow is 18 user units. `normalize = true` draws every
non-zero vector at the same length (unit direction), which is useful for
direction fields. `pivot` chooses the data point within the glyph:
`"tail"` (default), `"middle"`, or `"tip"`.

| Option | Type | Default |
| --- | --- | --- |
| `u`, `v` | non-empty finite arrays matching `theta` | — (required) |
| `scale` | number > 0, SVG user units per magnitude | automatic (longest arrow 18 units) |
| `normalize` | boolean | `false` |
| `pivot` | `"tail"`, `"middle"`, or `"tip"` | `"tail"` |
| `max_arrows` | integer in [1, 4096] | `512` |
| `color` | color string | next palette color |
| `label` | string | no legend entry |
| `linewidth` | number ≥ 0 | `1.2` |
| `head` | number ≥ 0, SVG user units | `5` |
| `alpha` | number in [0, 1] | `1` |
| `degrees` / `theta_unit` | boolean / `"radians"` or `"degrees"` | radians |

Large fields are decimated deterministically: when the input has more vectors
than `max_arrows`, the renderer keeps indices 1, 1+stride, 1+2*stride, ... with
`stride = ceil(count / max_arrows)`, so at most `max_arrows` glyphs are drawn.
Zero-magnitude vectors have no direction and are skipped. The series group
reports `data-count`, `data-drawn`, `data-stride`, `data-max-arrows`,
`data-scale`, `data-scale-mode` (`"auto"` or `"explicit"`), `data-pivot`, and
`data-normalize`; each `polar-quiver-arrow` group reports `data-index`,
`data-magnitude`, `data-theta`, `data-r`, and the screen-space `data-angle`.
Arrows are clipped to the polar circle and drawn in series order above
heatmaps and contours. Labelled quivers participate in `fig:legend()` with an
arrow swatch and scene export under `polar.series` with `kind = "quiver"`.

### `fig:polar_streamplot(theta, r, u, v, opts)`

Integrate streamlines through a vector field sampled on a regular polar grid.
`theta` and `r` are strictly increasing coordinate arrays with at least two
values; `u` and `v` are `#r`-by-`#theta` matrices of the local
tangential/radial components at every grid node. `u` points toward increasing
data theta and `v` points outward, and the `theta_zero`/`theta_direction`
configuration rotates the field with the axes. `theta` may be supplied in
degrees with `degrees = true` or `theta_unit = "degrees"`.

The field is bilinearly interpolated and integrated in the physical plane with
fixed-step fourth-order Runge-Kutta, so one `step` is isotropic even when the
angular and radial grid spacings differ. A theta grid spanning one full turn
(within `1e-9` of `2*pi`) is periodic and wraps across `theta = 0`; a partial
sector stops a line at its theta edges. A line also stops at the radial grid
bounds, at a zero-magnitude sample, after `max_steps` in either direction, or
when a closed orbit returns to its seed. Seeding is deterministic: a staggered
grid scaled by `density`, with coarse occupancy bins that suppress lines which
would retrace earlier coverage.

| Option | Type | Default |
| --- | --- | --- |
| `density` | number in [0.1, 10] | `1` |
| `step` | number > 0, data-radius units | automatic: radial span / 25 |
| `max_steps` | integer in [10, 5000] | `300` |
| `max_lines` | integer in [1, 512] | `64` |
| `max_points` | integer in [100, 200000] | `8000` |
| `arrows` | boolean | `true` |
| `arrow_fraction` | number in [0.05, 0.95], fraction of arc length | `0.5` |
| `head` | number ≥ 0, SVG user units | `6` |
| `color` | color string | next palette color |
| `label` | string | no legend entry |
| `linewidth` | number ≥ 0 | `1.5` |
| `linestyle` | `"solid"`, `"dashed"`, `"dotted"`, or `"none"` | `"solid"` |
| `alpha` | number in [0, 1] | `1` |
| `degrees` / `theta_unit` | boolean / `"radians"` or `"degrees"` | radians |

Each line carries one directional arrow, anchored at `arrow_fraction` of the
line's integrated arc length rather than at a point index, so uneven spacing
and trimmed tails cannot pull it away from the requested position. Arrows are
omitted when `arrows = false` or `head = 0`.

The series group reports `data-cols`, `data-rows`, `data-lines`,
`data-points`, `data-arrow-count`, `data-step`, `data-step-mode` (`"auto"` or
`"explicit"`), `data-density`, `data-max-steps`, `data-max-lines`,
`data-max-points`, `data-arrows`, `data-head`, `data-linestyle`,
`data-arrow-fraction`, `data-closed-lines`, `data-arc-length-unit`
(`"data_radius_units"`), `data-periodic`, and `data-truncated`. Each
`polar-streamline` group reports `data-index`, `data-points`, `data-arrows`,
`data-closed`, `data-seed-theta`, `data-seed-r`, and `data-arc-length`; its
path uses `polar-streamline-path` (with `stroke-dasharray` for dashed/dotted
styles) and each arrow is a `polar-stream-arrow` polygon with `data-index` (the
1-based point index used as its anchor), `data-fraction` (the anchor's arc
length divided by the line length), `data-angle`, `data-theta`, and `data-r`.
Streamlines are clipped to the polar circle and draw in series order above
heatmaps, contours, and other series. Labelled streamplots participate in
`fig:legend()` with a curved swatch that follows the configured line style.
Scene export under `polar.series` uses `kind = "streamplot"`, copied `u`/`v`
matrices, the `theta`/`r` grid coordinates,
`components = "tangential_radial"`, `periodic`, requested and resolved step
metadata, density/caps, `arrow_fraction`, `closed_line_count`, and
`arc_length_unit`; its `lines` array carries `theta`, `r`, `points`, `closed`,
`seed_theta`, `seed_r`, `arc_length`, and `arrows`, where every arrow exports
`index`, `fraction`, `theta`, `r`, and `angle`. Exported line theta values are
continuous and may exceed the grid range by whole turns for periodic fields.

### `fig:polar_annotate(text, theta, r, opts)` / `fig:annotate(text, theta, r, opts)`

Add a text annotation at a polar `(theta, r)` position. In a polar figure the
regular `fig:annotate` method dispatches to `polar_annotate`, so the Cartesian
annotation examples work unchanged. Options match Cartesian annotations:
`xytext = { theta, r }` places the text at another polar coordinate,
`align`/`color`/`fontsize` style the text, and `arrow = true` or an arrow
options table draws a leader line from the text to the target. `degrees` and
`theta_unit` apply to the target angle and to `xytext[1]`. Annotation target
radii extend the automatic radial limit, so an arrow always points at a target
inside the frame. With an explicit `polar_config.rmax`, a target outside that
limit raises an error instead of drawing outside the axes; `xytext` positions
do not extend the limit. Polar annotation text is not clipped to the circle,
so labels may extend into the canvas margins, but the renderer shifts a text
box that would leave the canvas back inside the viewport (and the leader arrow
follows the shifted text). The annotation layer carries
`data-clip="canvas"`, and each annotation group reports `data-theta`, `data-r`,
and `data-clamped`.

### `fig:polar_config(opts)`

Configure a polar figure before or after adding series. It returns the figure
for chaining.

| Option | Type | Default | Meaning |
| --- | --- | --- | --- |
| `theta_zero` | `"E"`, `"N"`, `"W"`, `"S"`, or number | `"E"` | Display location of theta=0; a number is a display offset in radians |
| `theta_direction` | `"counterclockwise"`, `"ccw"`, `"clockwise"`, or `"cw"` | `"counterclockwise"` | Direction of increasing theta |
| `rmax` | number > 0 | automatic | Explicit radial limit; series, error-bar extents, annotation targets, heatmaps, and `rgrids` above it raise an error when rendered |
| `thetagrids` | non-empty array of numbers | 0, 45, ..., 315 | Angular grid positions in **degrees of the data theta coordinate** |
| `thetagrid_labels` | array of strings | `"0°"`, `"45°"`, ... | Labels matching `thetagrids` |
| `rgrids` | non-empty array of positive numbers | automatic | Explicit radial grid circles |
| `rgrid_labels` | array of strings | formatted values | Labels matching `rgrids` |

`thetagrid_labels` requires `thetagrids` and `rgrid_labels` requires `rgrids`;
the label array must match the corresponding grid length. `theta_zero` rotates
the display without changing the theta data or the degree labels. A figure
cannot switch between Cartesian and polar mode, so `polar_config` rejects a
figure that already has Cartesian series or annotations.

### `fig:barh(labels_or_y, values, opts)`

Horizontal bars for a single numeric series. Category labels are placed on the
y axis; `bar_colors` and `show_values` behave like `bar`.

### `fig:errorbar(x, y, yerr[, xerr][, opts])`

Draw a connected line and markers with symmetric vertical error bars, plus
optional horizontal error bars.

| Option | Type | Default |
| --- | --- | --- |
| `color` | color string or array of color strings | next palette color |
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

Draw one marker per point. `marker` selects circle (default), square,
triangle, diamond, cross, or x.

| Option | Type | Default |
| --- | --- | --- |
| `color` | color string | next palette color |
| `label` | string | no legend entry |
| `size` | number > 0 or array of numbers | `4` |
| `markersize` | number > 0 | alias/precedence after `size` |
| `s` | number > 0 | additional size alias |
| `alpha` | number in [0, 1] | `1` |
| `edgecolor` | color string | no outline |
| `linewidth` | number ≥ 0 | `1` when an outline is present |

`size`/`markersize`/`s` are a circle **radius in SVG user units**, not
matplotlib's area-in-points-squared convention. Arrays must match the number
of points. `color` may also be an array of fill colors. The last listed size
aliases are only used when the earlier ones are absent.

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
| `density` | boolean | `false` |
| `cumulative` | boolean | `false` |

`density` normalizes bin heights by total count and bin width. `cumulative`
accumulates counts or density left-to-right.

If all values are equal, the default range is padded around that value. Values
outside an explicit `range` are ignored. Counts are integers, and the automatic
y-axis includes zero. Empty bins are not emitted as rectangles.

### `fig:eventplot(positions[, opts])`

Draw vertical event ticks. `positions` is one list of x values or a list of rows;
each row becomes a horizontal lane. Options: `color`, `label`, `linewidth`,
`alpha`.

### `fig:ecdf(values[, opts])`

Draw the empirical CDF as a post-step curve over the sorted values. Accepts the
usual step styling options.

### `fig:fill_between(x, y1, y2[, opts])`

Filled band between two y sequences.

### `fig:step(x, y[, opts])`

Step plot with `opts.where = "pre" | "post" | "mid"` (default `pre`).

### `fig:stem(x, y[, opts])`

Stem plot with vertical lines and markers at each point.

### `fig:stackplot(x, series[, opts])`

Stacked filled areas; `opts.labels` and `opts.colors` match the series list.

### `fig:contourf(values[, opts])`

Filled contour-style field with optional overlay contour lines (`opts.contours = false` disables them).

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

### `fig:axhspan(y1, y2[, opts])` / `fig:axvspan(x1, x2[, opts])`

Shade a horizontal or vertical data-coordinate band. Options: `color`, `alpha`,
and `label`. The span extends the reduced axis range.

### `fig:loglog(x, y[, opts])` / `semilogx` / `semilogy`

Convenience wrappers that select log scales and then call `plot`. `loglog` sets
both axes, `semilogx` sets x, and `semilogy` sets y.

### `fig:axhline(y[, opts])` / `fig:axvline(x[, opts])`

Draw a horizontal or vertical reference line in data coordinates. Options:
`color`, `linewidth`, `linestyle` (`solid`, `dashed`, `dotted`, `none`),
`alpha`, and `label`. A horizontal line extends the y range; a vertical line
extends the x range.

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

### `fig:twiny()`

Create a secondary x axis sharing the y axis. The returned object supports
`plot`, `scatter`, and `errorbar`, plus `xlim`, `xscale`, `xlabel`, and
`xtick_format`. It renders on the top with independent ticks and label.

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
fig:grid(true, { axis = "x" })
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
| `loc` | `"upper right"`, `"upper left"`, `"lower right"`, `"lower left"`, `"best"` | `"upper right"` |
| `frame` | boolean | `true` |
| `ncol` | integer in [1, 6] | `1` |
| `title` | string | none |

Only series with a non-empty `label` appear. Swatches reflect the series type
(line, point, bar, or error bar). Calling `legend()` with no labeled series
produces no legend box. In polar figures `"best"` searches for the placement
that covers the fewest labels and data points; Cartesian figures currently
resolve `"best"` to the upper-right corner.

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

## Polar axes

Polar figures are created with `plt.polar(theta, r, opts)` or by calling
`fig:polar(theta, r, opts)`. `theta` is in radians unless `degrees = true` or
`theta_unit = "degrees"` is passed; `r` may be negative. `fig:polar_scatter`,
`fig:polar_bar`, and `fig:polar_errorbar` add markers, radial wedges, and
radial/angular uncertainty; `fig:polar_quiver` draws local-basis vector arrows;
`fig:polar_streamplot` integrates grid-sampled vector fields into streamlines;
`fig:polar_heatmap` projects a matrix as annular cells; `fig:polar_contour`
overlays projected isolines of the same matrix.
`fig:polar_annotate` (or `fig:annotate` on a polar figure) adds text and
optional arrows at `(theta, r)` coordinates. `fig:polar_config` changes the
zero location, theta direction, radial limit, and explicit grids.

The radial limit is selected automatically from the largest absolute radius,
including the extents of radial error bars, annotation targets, heatmaps,
contours, and streamplot grids; the default angular grid has spokes every 45
degrees and the radial
grid uses "nice" steps. An explicit `rmax` must cover every series value,
error-bar extent, annotation target, heatmap/contour extent, and `rgrids`
entry. The polar renderer draws the grid and tick labels itself, so `grid`,
`xlim`/`ylim`, `xscale`/`yscale`, and twin axes do not apply. Radial tick
numbers draw above the series with a white halo so filled bars and heatmaps do
not hide them; the outermost baseline is clamped inside the frame. The title,
facecolor, ARIA label, `to_html`, and `savefig` remain available, and
`to_scene()` exports the polar schema described below.

The SVG root sets `data-polar="true"`, `data-theta-unit="radians"`,
`data-theta-zero`, and `data-theta-direction`. The `polar` group exposes
`data-cx`, `data-cy`, `data-radius`, and `data-rmax` for tests and for
coordinate-aware tooling. Series are clipped to the polar circle and rendered
with classes `polar-line`, `polar-scatter`, `polar-bar`,
`polar-errorbar-r`, `polar-errorbar-theta`, `polar-errorbar-cap`,
`polar-quiver-arrow`, `polar-quiver-shaft`, `polar-quiver-head`,
`polar-streamline`, `polar-streamline-path`, `polar-stream-arrow`,
`polar-contour-line`, `polar-contour-label`, and `polar-frame`, plus
`polar-spoke`, `polar-circle`, `theta-tick`, `r-tick`, `annotation-text`,
`polar-legend`, and `polar-colorbar` for the grid, annotations, legend, and
colorbar. Heatmap legend swatches use `legend-swatch-step`.

## 3-D axes

`plt.figure3d(opts)` returns an orthographic 3-D figure with `plot(x,y,z)`,
`scatter(x,y,z)`, `surface(x,y,z)`, `mesh(x,y,z)`, `view(elev,azim)`,
`xlim/ylim/zlim`, labels, title, `to_scene()`, and `savefig(path)`. Surface 1-D `x` maps
across columns and 1-D `y` across rows. `.png`/`.pdf` require `rsvg-convert`.

## Limitations

- SVG is the primary backend; PNG/PDF require the optional `rsvg-convert`.
- Polar axes support line/scatter/bar/error-bar/quiver/streamplot series,
  heatmaps with one colorbar, contours, and annotations; polar twin axes are
  not implemented. Quiver glyphs are screen-space arrows (decimated to
  `max_arrows`), not magnitude-scaled data extents. Streamlines follow the
  interpolated direction field at a fixed integration step; the step is not a
  physical speed and the sampled component magnitudes do not scale line
  lengths. Contour levels that exactly equal a matrix sample can drop that
  degenerate branch. Legend placement uses estimated text metrics, not a full
  text-measurement engine.
- 3-D axes support line/scatter/surface/mesh, not full camera/lighting.
- Basic fixed/adaptive margins; crowded category labels can overlap.
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

### Polar scenes

Polar figures export a different scene shape. `orientation = "polar"` marks the
schema, the Cartesian `series` array is empty, and geometry lives under
`polar`:

```lua
{
  version = 1,
  type = "luaplotlib",
  orientation = "polar",
  width = 620, height = 620, dpi = 100,
  title = "Polar rose",
  grid = true,
  legend = true,
  series = {},
  annotations = {
    {
      kind = "annotation", text = "peak", theta = 1.5708, r = 5,
      xytext = { 1.2, 6, theta = 1.2, r = 6 },
      color = "#d62728", fontsize = 13, align = "center",
      style = { color = "#d62728", fontsize = 13, align = "center" },
      arrow = { enabled = true, color = "#d62728", linewidth = 1.5, head = 9 },
    },
  },
  polar = {
    theta_unit = "radians",
    theta_zero = 0,                     -- display offset in radians
    theta_direction = "counterclockwise",
    rmin = 0,
    rmax = 6,
    theta_ticks = {
      { value = 0, degrees = 0, label = "0°" },
      { value = 0.7853981633974483, degrees = 45, label = "45°" },
      -- ...
    },
    r_ticks = {
      { value = 1.2, fraction = 0.2, label = "1.2" },
      { value = 2.4, fraction = 0.4, label = "2.4" },
      -- ...
    },
    legend = {
      loc = "best", frame = true, title = nil, ncol = 1,
      entries = {
        { kind = "line", label = "line", color = "#1f77b4" },
        { kind = "errorbar", label = "errors", color = "#ff7f0e" },
      },
    },
    colorbar = {
      orientation = "vertical",
      vmin = 11, vmax = 48,
      ticks = { 11, 23.5, 36, 48 },
      tick_labels = { "11", "23.5", "36", "48" },
      tick_fractions = { 0, 0.338, 0.676, 1 },
      tick_source = "uniform",          -- or "explicit"
      label = "value",
    },
    heatmaps = {
      { kind = "heatmap", rows = 4, cols = 8, values = {...},
        vmin = 11, vmax = 48, rmin = 0, rmax = 4,
        theta_min = 0, theta_max = 6.283, alpha = 1,
        label = "field", colorbar = true,
        colorbar_ticks = 3, colorbar_tick_values = nil },
    },
    contours = {
      { kind = "contour", rows = 4, cols = 8,
        vmin = 11, vmax = 48, rmin = 0, rmax = 4,
        theta_min = 0, theta_max = 6.283, labels = false,
        style = { color = "#111111", linewidth = 1.5,
          linestyle = "solid", alpha = 1 },
        levels = {
          { level = 18.2, segments = { { theta0, r0, theta1, r1 }, ... },
            label = nil },
          -- ...
        } },
    },
    series = {
      { kind = "line", theta = {...}, r = {...}, style = {...} },
      { kind = "scatter", theta = {...}, r = {...},
        radii = {...}, colors = {...}, style = {...} },
      { kind = "bar", theta = {...}, r = {...},
        widths = {...}, colors = {...}, style = {...} },
      { kind = "errorbar", theta = {...}, r = {...}, rerr = {...},
        thetaerr = {...}, style = {...} },
      { kind = "quiver", theta = {...}, r = {...},
        u = {...}, v = {...}, components = "tangential_radial",
        scale = nil, auto_scale = true, resolved_scale = 19.608,
        scale_unit = "svg_user_units_per_magnitude",
        pivot = "tail", max_arrows = 512, normalize = false,
        stride = 1, drawn = 320, style = {...} },
      { kind = "streamplot", theta = {...}, r = {...},
        u = { {...}, ... }, v = { {...}, ... },
        components = "tangential_radial", periodic = true,
        density = 1, step = nil, step_mode = "auto",
        resolved_step = 0.2, step_unit = "data_radius_units",
        max_steps = 300, max_lines = 64, max_points = 8000,
        arrows = true, arrow_fraction = 0.5, head = 6, truncated = false,
        linestyle = "solid", closed_line_count = 9,
        arc_length_unit = "data_radius_units",
        line_count = 12, point_count = 960,
        lines = {
          { theta = {...}, r = {...}, points = 84, closed = false,
            seed_theta = 0.5, seed_r = 1.4, arc_length = 6.28,
            arrows = {
              { index = 33, fraction = 0.5, theta = 1.2, r = 2.4,
                angle = -71.3 },
            } },
          -- ...
        }, style = {...} },
    },
  },
}
```

`theta_ticks` values are data theta radians; `degrees` is included for display.
`theta_zero` is the display offset in radians (`"N"` becomes `pi/2`) and
`theta_direction` is always the string `"counterclockwise"` or `"clockwise"`.
Scatter series include `radii`/`colors` only when per-point arrays were
supplied, and bar series always include `widths` plus `colors` when per-bar
colors were supplied. Error-bar series always include `rerr`; `thetaerr` is
present only when angular errors were requested. Quiver series include `u` and
`v` (copied arrays), `components = "tangential_radial"`, `scale` (nil when
automatic), `auto_scale`, the resolved `resolved_scale`, `scale_unit =
"svg_user_units_per_magnitude"`, `pivot`, `max_arrows`, `normalize`, the
decimation `stride`, and the number of `drawn` arrows. Streamplot series use
`theta`/`r` as the grid coordinates, copied `u`/`v` matrices,
`components = "tangential_radial"`, `periodic`, `density`, the requested
`step`, `step_mode`, `resolved_step`, `step_unit = "data_radius_units"`, caps
and `truncated`, `arrow_fraction`, `closed_line_count`, and
`arc_length_unit = "data_radius_units"`, plus a `lines` array whose entries
carry `theta`, `r`, `points`, `closed`, `seed_theta`, `seed_r`, `arc_length`,
and `arrows` (each with the 1-based anchor point `index`, its arc-length
`fraction`, `theta`, `r`, and the screen-space `angle`).
Streamplot line theta values are continuous, so a periodic line may run past
the grid range by whole turns. `r_ticks` include `fraction`
(the radius as a fraction of `rmax`) so a backend can draw rings without
dividing. `polar.legend` is present only when a non-empty legend was requested;
top-level `legend` remains a boolean for compatibility with earlier scenes.
`polar.heatmaps` is present when the figure contains projected heatmaps. Each
entry carries `kind = "heatmap"`, `rows`, `cols`, `values` (a row-major copy),
`vmin`, `vmax`, `rmin`, the effective `rmax`, `theta_min`, `theta_max`,
`alpha`, the optional `label`, `colorbar = true` when that heatmap owns the
figure colorbar, and the resolved `colorbar_ticks`/`colorbar_tick_values`
inputs. Values are copied, so later mutation of the caller's matrix does not
change an exported scene.
`polar.colorbar` is present when a heatmap requested one; it carries
`orientation = "vertical"`, `vmin`, `vmax`, the exact `ticks` values (ascending),
matching `tick_labels` and `tick_fractions` arrays, the `tick_source`
(`"uniform"` or `"explicit"`), and the optional `label`. `polar.contours` is
present when the figure contains contours. Each entry carries `kind =
"contour"`, `rows`, `cols`, `vmin`, `vmax`, `rmin`, the effective `rmax`,
`theta_min`, `theta_max`, `labels`, `style`, and `levels`. Each level has a
`level` value and `segments`; every segment is a flat `{ theta0, r0, theta1,
r1 }` array in data units, ready for a backend to project. When `labels` is
true, a level also exposes the preferred `label` anchor (`text`, `theta`, `r`,
`u`, `v`, and upright `angle`); the SVG renderer may skip a colliding label, so
the scene anchor is a placement hint rather than a one-to-one mirror. Heatmap
legend entries also carry `vmin`/`vmax` so a gradient swatch can be
reconstructed.
Polar `annotations` use theta/r coordinates instead of Cartesian x/y, mirroring
the Cartesian annotation schema. The `rmax`, tick arrays, and labels reflect the
same resolution rules as the SVG renderer, so another backend does not need to
reimplement automatic limits or "nice" tick selection. Exporting a figure that
mixes Cartesian and polar series or annotations raises an error, matching
`to_svg()`.
