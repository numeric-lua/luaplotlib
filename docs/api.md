# luaplotlib API

Version: `4.28.0`. This document describes the public Lua API implemented
by `luaplotlib.lua` and the modules under `luaplotlib/`.

```lua
local plt = require("luaplotlib")
```

The module exposes:

- `plt.figure(opts)` → `Figure`
- `plt.subplots(rows, cols, opts)` → `SubplotFigure, axes`
- `plt.polar(theta, r, opts)` → `Figure`
- `plt.Figure` — the Figure class table
- `plt._VERSION` — currently `"4.28.0"`

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
| `marker` | marker name, `true`/`false`, or array of marker names | `false` |
| `markersize` | number > 0 | `4` |
| `markevery` | positive integer stride or table of 1-based point indices | draw every marker |
| `markerfacecolor` | color string | series color |
| `markeredgecolor` | color string | no outline |
| `markeredgewidth` | number ≥ 0 | `1` when an outline is present |
| `alpha` | number in [0, 1] | `1` |

`markevery` decimates markers without dropping line vertices. An integer draws
the first point and then every Nth point; a table lists the 1-based point
indices to mark. Index tables are sorted and duplicate entries are ignored.
The line group exposes `data-marker-count` and, when decimation is requested,
`data-markevery="true"`. A single-point line still renders its point.
`markerfacecolor` fills filled marker shapes (circle, square, triangle,
diamond), while `markeredgecolor`/`markeredgewidth` add their outline. Cross and
x markers are stroke-only and use the marker color for their strokes. Scenes
export the three marker style fields through the series style.

Unknown options, invalid colors, and malformed data raise errors.

### `fig:pie(values[, opts])` / `fig:donut(values[, opts])`

Pie and donut charts. Values must be non-negative with a positive total.
`donut` defaults `inner_radius` to 0.55.

| Option | Type | Default |
| --- | --- | --- |
| `labels` | one label per value | `slice N` |
| `colors` | one color per value | palette |
| `startangle` | finite number, degrees | `90` |
| `counterclock` | boolean | `false` |
| `radius` | number in [0.05, 0.5] | `0.34` |
| `inner_radius` | number in [0, 0.95] | `0` (`0.55` for donut) |
| `explode` | number or per-slice array in [0, 0.5] | `0` |
| `shadow` | boolean | `false` |
| `edgecolor` | color string | `#ffffff` |
| `linewidth` | number ≥ 0 | `1.5` |
| `labelsize` / `pctsize` | number > 0 | `12` |
| `labelcolor` / `pctcolor` | color string | `#222222` / `#ffffff` |
| `labeldistance` | number in [0.01, 2], radius multiplier | `1.08` |
| `pctdistance` | number in [0.01, 2], radius multiplier | `0.64` |
| `rotatelabels` | boolean | `false` |
| `autopct` | `false`, `true`, or a format string | `false` |
| `legend` | boolean | `true` |

`counterclock = true` lays slices out in increasing-angle order; the default
keeps the existing clockwise order. `explode` shifts each wedge outward by that
fraction of the radius along its mid-angle, and `shadow` draws a soft offset wedge behind each slice. Exploded
wedges keep their labels, leader lines, and percentage text attached to the
shifted slice. `edgecolor`/`linewidth` style each wedge outline, defaulting to
the existing white 1.5-pixel stroke. `labelsize`/`labelcolor` style slice
labels, while `pctsize`/`pctcolor` style percentage annotations independently.
`labeldistance`/`pctdistance` place the slice labels and percentage text as
radius multipliers. `rotatelabels = true` rotates each label
to its slice angle while keeping left-half labels upright. `to_scene()` exports
`pie.shadow`, the two distances, `rotatelabels`, `counterclock`, and each
slice's `explode` value.

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
| `color` | color string or per-vector array | next palette color |
| `label` | string | no legend entry |
| `linewidth` | number ≥ 0 | `1.5` |
| `linestyle` | `"solid"`, `"dashed"`, `"dotted"`, or `"none"` | `"solid"` |
| `marker` | marker name, `true`, or `false` | `"circle"` |
| `markersize` | number > 0 | `4` |
| `alpha` | number in [0, 1] | `1` |
| `capsize` | number ≥ 0 | `4` |
| `elinewidth` | number ≥ 0 | `1` |
| `ecolor` | color string or per-point array | same as `color` |
| `lolims` / `uplims` | boolean or one boolean per point | `false` |
| `xlolims` / `xuplims` | boolean or one boolean per point | `false` |
| `errorevery` | positive integer | `1` (every point) |
| `lolims` | boolean or one boolean per point | `false` |
| `uplims` | boolean or one boolean per point | `false` |

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
`data-points`, `data-arrow-count`, `data-clipped-arrow-count`,
`data-step`, `data-step-mode` (`"auto"` or `"explicit"`), `data-density`,
`data-max-steps`, `data-max-lines`, `data-max-points`, `data-arrows`,
`data-head`, `data-linestyle`, `data-arrow-fraction`, `data-closed-lines`,
`data-arc-length-unit` (`"data_radius_units"`), `data-clip`
(`"polar-circle"`), `data-periodic`, and `data-truncated`. Each
`polar-streamline` group reports `data-index`, `data-points`, `data-arrows`,
`data-clipped-arrows`, `data-closed`, `data-seed-theta`, `data-seed-r`, and
`data-arc-length`; its path uses `polar-streamline-path` (with
`stroke-dasharray` for dashed/dotted styles) and each arrow is a
`polar-stream-arrow` polygon with `data-index` (the 1-based point index used
as its anchor), `data-fraction` (the anchor's arc length divided by the line
length), `data-angle`, `data-theta`, `data-r`, and `data-clipped`. Streamlines
are clipped to the polar circle and draw in series order above heatmaps,
contours, and other series. Arrow triangles are built in screen space, so a
large `head` or a late `arrow_fraction` can push a vertex past the frame
circle; that vertex is projected back onto the circle, which keeps the SVG
polygon itself inside the frame and sets the corresponding clipping metadata.
Labelled streamplots participate in `fig:legend()` with a curved swatch that
follows the configured line style.
Scene export under `polar.series` uses `kind = "streamplot"`, `cols`/`rows`,
copied `u`/`v` matrices, the `theta`/`r` grid coordinates,
`components = "tangential_radial"`, `periodic`, requested and resolved step
metadata, density/caps, `arrow_fraction`, `arrow_count`,
`clipped_arrow_count`, `closed_line_count`, `clip = "polar_circle"`, and
`arc_length_unit`; its `lines` array carries `theta`, `r`, `points`, `closed`,
`seed_theta`, `seed_r`, `arc_length`, `arrow_count`, `clipped_arrows`, and
`arrows`, where every arrow exports `index`, `fraction`, `theta`, `r`,
`angle`, and `clipped`. Clipping flags follow the rendered luaplotlib frame,
so a backend that chooses a different frame layout may recompute them. Exported
line theta values are continuous and may exceed the grid range by whole turns
for periodic fields.

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
y axis; `bar_colors`, `edgecolors` (one outline color per bar), `show_values`,
`linewidth`, and the one-per-call `hatch` pattern behave like `bar`.

### `fig:errorbar(x, y, yerr[, xerr][, opts])`

Draw a connected line and markers with vertical error bars, plus optional
horizontal error bars. Errors may be symmetric or independent on the lower and
upper sides.

| Option | Type | Default |
| --- | --- | --- |
| `color` | color string or array of color strings | next palette color |
| `label` | string | no legend entry |
| `linewidth` | number ≥ 0 | `1.5` |
| `linestyle` | `"solid"`, `"dashed"`, `"dotted"`, `"none"` | `"solid"` |
| `marker` | marker name, `true`, or `false` | `"circle"` |
| `markersize` | number > 0 or per-point array | `4` |
| `markerfacecolor` | color string | series color |
| `markeredgecolor` | color string | no outline |
| `markeredgewidth` | number ≥ 0 | `1` when an outline is present |
| `alpha` | number in [0, 1] | `1` |
| `capsize` | number ≥ 0, in SVG user units | `4` |
| `elinewidth` | number ≥ 0 or per-point array | `1` |
| `ecolor` | color string or per-point array | same as `color` |

`yerr` is required; `xerr` is optional. Each accepts one of three forms:

- a single non-negative number applied to every point;
- a flat array with one non-negative value per point (symmetric);
- an asymmetric table, either `{ lower = ..., upper = ... }` or
  `{ lower_sequence, upper_sequence }`, where each side is a scalar or an array
  of one non-negative value per point.

```lua
fig:errorbar({ 1, 2, 3 }, { 10, 12, 11 }, {
  lower = { 0.5, 0.8, 0.6 },
  upper = { 1.2, 1.5, 1.0 },
})
```

Asymmetric groups add `data-yerr-mode="asymmetric"` and/or
`data-xerr-mode="asymmetric"`. The scene export exposes `yerr_lower`/
`yerr_upper` and `xerr_lower`/`xerr_upper`; the legacy `yerr`/`xerr` arrays
track the upper side for compatibility, and `yerr_asymmetric`/
`xerr_asymmetric` are set when the input was asymmetric. The four-argument form
`errorbar(x, y, yerr, opts)` is accepted when the fourth argument is an options
table; an asymmetric `xerr` table in that position is treated as error data.
Errorbar markers accept the same `markerfacecolor`, `markeredgecolor`, and
`markeredgewidth` options as line markers. `errorevery = n` keeps every line
vertex and marker but draws error bars only at
the first point and every nth point after it. The group exposes
`data-errorevery`, `data-error-points`, and limit flags; scenes export
`errorevery` plus the four limit arrays. `ecolor`, `markersize`, and `elinewidth` may contain one value per point. `lolims`/`uplims`
replace vertical caps with down/up arrowheads; `xlolims`/`xuplims` replace horizontal caps with
left/right arrowheads. Automatic limits cover the drawn error extents plus
every point position.

### `fig:scatter(x, y, opts)`

Draw one marker per point. `marker` selects circle (default), square,
triangle, diamond, cross, or x, or a table with one marker name per point.

| Option | Type | Default |
| --- | --- | --- |
| `color` | color string | next palette color |
| `label` | string | no legend entry |
| `marker` | marker name, or array of marker names | `"circle"` |
| `size` | number > 0 or array of numbers | `4` |
| `markersize` | number > 0 | alias/precedence after `size` |
| `s` | number > 0 | additional size alias |
| `alpha` | number or per-point array in [0, 1] | `1` |
| `edgecolor` | color string or per-point color array | no outline |
| `linewidth` | number ≥ 0 or per-point array | `1` when an outline is present |
| `c` | numeric array matching the points | unset |
| `vmin` / `vmax` | finite numbers with `vmax > vmin` | `c` minimum / maximum |
| `colorbar` | boolean | `true` when `c` is set |
| `colorbar_label` | string | no title |
| `colorbar_ticks` | integer in [2, 10] | `3` |
| `colorbar_tick_values` | non-empty numeric table | uniform ticks |

`size`/`markersize`/`s` are a circle **radius in SVG user units**, not
matplotlib's area-in-points-squared convention. Arrays must match the number
of points. `marker` may be one marker name or a table with one marker per
point; marker tables must match the point count and are exported in scenes.
`color` may also be an array of fill colors. The last listed size aliases are
only used when the earlier ones are absent.

When `c` is supplied, every numeric value is mapped through the shared heat
palette (`colors.heat`) using `vmin`/`vmax`, and a vertical scatter colorbar is
drawn by default. `c` may contain negative values; a degenerate automatic
range is padded by 0.5 on each side. `c` and `color` are mutually exclusive,
and `vmin`, `vmax`, `colorbar`, or colorbar text/tick options require `c`.
The scatter group exposes `data-color-values="true"`, `data-vmin`, and
`data-vmax`; the colorbar uses class `colorbar scatter-colorbar` and carries
the usual `data-value`/`data-fraction` tick metadata. `to_scene()` exports
`c`/`color_values`, the resolved limits, and the colorbar settings in addition
to the mapped `colors` array.

### `fig:quiver(x, y, u, v, opts)`

Draw one vector glyph per point. `u` and `v` are the components in data
coordinates; the renderer projects them through the current x/y transforms so
the arrows stay legible on linear and log axes.

| Option | Type | Default |
| --- | --- | --- |
| `color` | color string | next palette color |
| `label` | string | no legend entry |
| `linewidth` | number ≥ 0 | `1.2` |
| `head` | number ≥ 0 (SVG user units) | `6` |
| `headwidth` | number ≥ 0, head width relative to `head` | `0.9` |
| `scale` | positive number | automatic |
| `pivot` | `"tail"`, `"middle"`, or `"tip"` | `"tail"` |
| `max_arrows` | integer in [1, 4096] | `512` |
| `normalize` | boolean | `false` |
| `angles` | `"xy"` or `"uv"` | `"xy"` |
| `alpha` | number in [0, 1] | `1` |

With `scale` omitted, the largest glyph is automatically drawn 18 SVG units
long. An explicit `scale` multiplies the screen-space displacement produced by
the unit components. `angles = "xy"` projects components through the data
transforms; `angles = "uv"` treats `u`/`v` as screen-space components instead,
so anisotropic axes do not skew the arrow directions. `normalize = true` gives
every nonzero vector a unit direction before scaling. Zero-magnitude vectors
are skipped. When the input
is larger than `max_arrows`, indices are decimated deterministically with
`stride = ceil(count / max_arrows)`.

The series group exposes `data-count`, `data-drawn`, `data-stride`,
`data-max-arrows`, `data-scale`, `data-scale-mode`, `data-pivot`,
`data-normalize`, `data-headwidth`, and `data-angles`. Per-vector `color` arrays are exported as
`style.colors`. Scenes export `angles`. Each `quiver-arrow` group carries `data-index`,
`data-magnitude`, `data-x`, `data-y`, and `data-angle`, with `quiver-shaft`
and `quiver-head` children. Labelled quivers join the regular legend with an
arrow swatch. `to_scene()` exports the component arrays, scale mode, pivot,
decimation stride, and drawn count.

### `fig:hist(values, opts)`

Draw a histogram as adjacent filled rectangles.

| Option | Type | Default |
| --- | --- | --- |
| `bins` | integer in [1, 1000] or increasing edge table | `10` |
| `range` | `{ min, max }` with `min < max` | data min/max |
| `orientation` | `"vertical"` or `"horizontal"` | `"vertical"` |
| `histtype` | `"bar"`, `"step"`, or `"stepfilled"` | `"bar"` |
| `linewidth` | number ≥ 0, outline stroke | `1` (`1.5` for step) |
| `hatch` | shared hatch pattern string | no hatch |
| `color` | color string | next palette color |
| `label` | string | no legend entry |
| `alpha` | number in [0, 1] | `1` |
| `edgecolor` | color string | `#ffffff` |
| `edgecolors` | one outline color per bin | `edgecolor` |
| `density` | boolean | `false` |
| `cumulative` | boolean | `false` |

`bins` may be an explicit increasing edge list with at least two entries; the
bin count is derived and `range` cannot also be supplied. `density` divides
each bin by its own width for non-uniform edges. `cumulative`
accumulates counts or density left-to-right. `orientation = "horizontal"` keeps
the same bin edges and counts but draws each bin along x from the zero count
baseline, with the data value on y. Horizontal groups carry
`data-orientation="horizontal"`, and the scene exports `orientation` with the
axis ranges swapped accordingly.

`edgecolors` supplies one outline color per bin and requires `histtype = "bar"`.
`histtype = "bar"` is the existing adjacent-rectangle rendering. `"step"`
draws a single stepped outline (`hist-step`) through every bin edge, including
empty bins, and closes to the zero baseline at both ends. `"stepfilled"` draws
the same staircase as one filled polygon (`hist-step-filled`) using `color` as
its fill and `edgecolor` (or the series color) as its stroke. Both outlines
respect `orientation`, `density`, `cumulative`, `alpha`, and the automatic
count range. `linewidth` sets the outline stroke for all three styles and is
exported through the series style; `to_scene()` also exports `histtype`
alongside the edges/counts. `hatch` fills `bar` and `stepfilled` histograms with
one of the shared patterns; stepped outlines have no fill and reject `hatch`.
The resolved hatch is exported through the series style.

If all values are equal, the default range is padded around that value. Values
outside an explicit `range` are ignored. Counts are integers, and the automatic
count axis includes zero. Empty bins are not emitted as rectangles.

### `fig:hist2d(x, y, opts)`

Count paired samples into a rectangular x/y grid and color non-empty cells with
the shared heat palette.

| Option | Type | Default |
| --- | --- | --- |
| `bins` | count, `{ nx, ny }`, or explicit edge tables | `10` |
| `range` | `{ xmin, xmax, ymin, ymax }` with ordered limits | data min/max |
| `density` | boolean | `false` |
| `vmin` / `vmax` | finite numbers with `vmax > vmin` | value range |
| `color_norm` | `"linear"` or `"log"` | `"linear"` |
| `colorbar` | boolean | `true` |
| `colorbar_label` | string | no title |
| `colorbar_ticks` | integer in [2, 10] | `3` |
| `colorbar_tick_values` | non-empty numeric table | uniform ticks |
| `edgecolor` | color string | `#ffffff` |
| `linewidth` | number ≥ 0 | `0.5` |
| `show_empty` | boolean | `false` |
| `color`, `label`, `alpha` | normal series style | palette/`1` |

`bins = { nx, ny }` controls the x and y cell counts independently. Either
entry may instead be an increasing edge table, so `{ x_edges, y_edges }` and
`{ x_edges, ny }` are accepted; explicit edges cannot be combined with
`range`. An explicit
`range` clips samples outside the rectangle and fixes the cell edges; the
default range uses the sample extrema, padded when an axis is degenerate.
`density = true` divides each cell count by the in-range sample count and that
cell's actual area. `color_norm = "log"` colors by `log(1 + value)` while vmin/vmax and
colorbar labels remain counts; log color norm requires `vmin >= 0`. Empty bins are omitted from the SVG and scene cell lists by default;
`show_empty = true` emits every cell in the grid with count/value zero so the
full rectangular field is visible. Grid edges and bin counts are always
preserved. `colorbar_ticks` and
`colorbar_tick_values` are mutually exclusive.

The series group exposes `data-points`, `data-inside`, `data-bins-x`,
`data-bins-y`, `data-explicit-bins`, `data-norm` (`count` or `density`),
`data-color-norm`, `data-show-empty`, `data-vmin`, and `data-vmax`.
Each `hist2d-cell` rectangle carries `data-row`, `data-col`, `data-count`,
`data-value`, and its source cell bounds. The colorbar group
(`colorbar hist2d-colorbar`) reports the same norm and value range. Scene export
includes the input arrays, edges, cells, counts, values, density flag, limits,
and colorbar settings plus `explicit_edges`, `color_norm`, `color_vmin`, and
`color_vmax`.

### `fig:hexbin(x, y, opts)`

Aggregate paired samples into regular pointy-top hexagons and color each cell
by its point count.

| Option | Type | Default |
| --- | --- | --- |
| `gridsize` | integer in [2, 200] | `20` |
| `mincnt` | integer ≥ 1 | `1` |
| `vmin` / `vmax` | finite numbers with `vmax > vmin` | count range |
| `norm` | `"linear"` or `"log"` | `"linear"` |
| `colorbar` | boolean | `true` |
| `colorbar_label` | string | no title |
| `colorbar_ticks` | integer in [2, 10] | `3` |
| `colorbar_tick_values` | non-empty numeric table | uniform ticks |
| `edgecolor` | color string | `#ffffff` |
| `linewidth` | number ≥ 0 | `0.5` |
| `color`, `label`, `alpha` | normal series style | palette/`1` |

`gridsize` is the number of hexagons across the x span; the row count is
derived from the y span so cells stay regular in data coordinates. Cells with
fewer than `mincnt` points are omitted. Counts use the shared heat palette.
`norm = "log"` colors by `log(1 + count)` while vmin/vmax and colorbar labels
remain counts; log norm requires `vmin >= 0`. `colorbar_ticks` and
`colorbar_tick_values` are mutually exclusive.

The series group exposes `data-bins`, `data-points`, `data-gridsize`,
`data-mincnt`, `data-norm`, `data-vmin`, and `data-vmax`. Each `hexbin-cell` polygon carries
`data-row`, `data-col`, `data-count`, `data-x`, and `data-y`. A labeled
colorbar group (`colorbar hexbin-colorbar`) reports its value range, tick
count/source, geometry, and per-tick `data-value`/`data-fraction`. Scene export
includes the point arrays, filtered cells, counts, limits, `norm`,
`color_vmin`/`color_vmax`, and colorbar settings.

### `fig:eventplot(positions[, opts])`

Draw event ticks. `positions` is one list of values or a list of rows; each row
becomes one lane, and rows are offset at `1, 2, 3, ...` by default.

| Option | Type | Default |
| --- | --- | --- |
| `orientation` | `"vertical"` or `"horizontal"` | `"vertical"` |
| `lineoffsets` | number or array, one offset per row | row index |
| `linelengths` | positive number or array, one length per row | `0.8` |
| `colors` | array with one color per row | series `color` |
| `eventcolors` | array with one color per event | row colors |
| `labels` | array with one axis label per row | no labels |
| `linestyle` | `"solid"`, `"dashed"`, `"dotted"`, or `"none"` | `"solid"` |
| `linewidth` | number ≥ 0 or one value per row | `2` |
| `color`, `label`, `alpha` | normal series style | palette / `1` |

In the default vertical orientation each value is an x coordinate and the mark
is a vertical line centered on its row's offset. With `orientation =
"horizontal"` each value is a y coordinate and the mark is a horizontal line
centered on its row's x offset. `lineoffsets` place the lane centers and
`linelengths` set each lane's span in data units. `colors` gives one stroke
color per row and cannot be combined with `color`; `eventcolors` overrides row
colors with one entry per event across all rows. `linewidth` accepts one value
per row. Offsets and
lengths participate in automatic ranging, and a row's length may differ from
its neighbors'. Setting `linestyle = "none"` hides event marks while keeping
the lane group and axis labels. `to_scene()` exports `orientation`, `rows`,
`lineoffsets`, `linelengths`, `colors` when row colors were supplied,
`eventcolors` when per-event colors were supplied, and `labels` when lane
labels were supplied.

### `fig:ecdf(values[, opts])`

Draw the empirical CDF as a post-step curve over the sorted values. Accepts the
usual step styling options plus `complementary = true`, which plots
`1 - F_n(x)` (the exceedance curve) instead of `F_n(x)`. ECDF step groups expose
`data-ecdf="true"` and, for complementary curves, `data-complementary="true"`;
scenes export `ecdf` and `complementary` on the step series.

### `fig:fill_between(x, y1, y2[, opts])` / `fig:fill_betweenx(y, x1, x2[, opts])`

Filled band between two y sequences (or two x sequences). In addition to
`color`, `label`, `alpha`, and `edgecolor`, both methods accept a boolean mask
and an interpolation switch:

| Option | Type | Default |
| --- | --- | --- |
| `hatch` | shared hatch pattern string | no hatch |
| `where` | table with one boolean per sample | no mask |
| `interpolate` | boolean | `false` |

A contiguous run of `true` mask entries becomes one polygon. With
`interpolate = true`, a run that begins or ends next to a hidden sample gains a
midpoint between the visible and hidden samples for the band edges, so the
cut is interpolated rather than abrupt. Hidden samples do not contribute to
automatic ranging. A masked group carries `data-where="masked"`,
`data-interpolate`, and `data-segments`; each polygon carries `data-index`.
`to_scene()` exports `where`, `interpolate`, and resolved `segments` arrays
when a mask is present. Masks must match the sample count and contain only
booleans; callbacks and numeric alpha masks are not supported. `hatch` fills
each polygon with a shared pattern, including masked runs; the resolved hatch
is exported through the series style and participates in `hatch_defs`.

### `fig:step(x, y[, opts])`

Step plot with `opts.where = "pre" | "post" | "mid"` (default `pre`). Add
`fill = true` to draw a `step-fill` area to the zero baseline; `fillalpha`
controls that area's opacity (default `0.2`). Scenes export `fill` and
`fillalpha`.

### `fig:stem(x, y[, opts])`

Stem plot with vertical lines and markers at each point.

| Option | Type | Default |
| --- | --- | --- |
| `base` | finite number, data y coordinate | `0` |
| `orientation` | `"vertical"` or `"horizontal"` | `"vertical"` |
| `marker` | marker name, `true`, or `false` | `"circle"` |
| `markersize` | number > 0 | `4` |
| `markerfacecolor` | color string | series color |
| `markeredgecolor` | color string | no outline |
| `markeredgewidth` | number ≥ 0 | `1` when an outline is present |
| `linestyle` | `"solid"`, `"dashed"`, `"dotted"`, or `"none"` | `"solid"` |
| `linewidth` | number ≥ 0 | `1.5` |
| `color` | color string | next palette color |
| `alpha` | number in [0, 1] | `1` |
| `label` | string | no legend entry |

Vertical stems use `x` as positions and `y` as values; horizontal stems swap
that mapping, placing positions on y and growing from `base` along x. The stem
group exposes `data-base`, `data-marker`, `data-linestyle`, and
`data-orientation`. A non-zero `base` participates in automatic ranging,
`linestyle = "none"` keeps only the markers, and `marker = false` keeps only the
stems. Marker face and
edge styling matches `plot`, and scenes export the three marker style fields. `to_scene()`
exports the base plus the marker/line style through the normal series style.

### `fig:stackplot(x, series[, opts])`

Stacked filled areas. `opts.labels` and `opts.colors` match the series list.

| Option | Type | Default |
| --- | --- | --- |
| `labels` | one legend label per series | no legend entries |
| `colors` | one color per series | palette colors |
| `baseline` | `"zero"`, `"sym"`, or `"wiggle"` | `"zero"` |
| `alpha` | number in [0, 1] | `0.8` |
| `edgecolor` | color string | series color |

`zero` starts every stack at y=0. `sym` shifts each complete stack so it is
centered on zero. `wiggle` shifts each stack by the average of its cumulative
layer boundaries, which centers the visual mass while preserving every layer's
thickness. Each fill polygon carries `data-stack="true"`, `data-baseline`, and
its layer `data-index`; scene export adds `stack_baseline`, `stack_index`, and
the per-sample `stack_shift` array while the legacy `y1`/`y2` geometry remains
the canonical band shape.

### `fig:contourf(values[, opts])`

Filled contour-style field with optional overlay contour lines (`opts.contours = false` disables them).

### `fig:broken_barh(xranges, yrange[, opts])`

Draw horizontal broken bars at one y interval. `xranges` is a non-empty list of
`{ start, width }` pairs with positive widths; `yrange` is a single
`{ y, height }` pair with a positive height. Each range becomes one
`broken-barh` rectangle, so a call can describe gaps or multiple phases.

| Option | Type | Default |
| --- | --- | --- |
| `color` | color string | next palette color |
| `label` | string | no legend entry |
| `alpha` | number in [0, 1] | `1` |
| `edgecolor` | color string | `#ffffff` |
| `linewidth` | number ≥ 0 | `1` |

All ranges and the y interval participate in automatic ranging. The series
group carries `data-y` and `data-height`, each rectangle carries
`data-index`/`data-start`/`data-width`, and labelled calls join the normal
legend with a rectangle swatch. `to_scene()` exports `ranges`, `y`, `height`,
and the resolved style.

### `fig:imshow(values, opts)`

Renders a rectangular matrix as a heatmap. Accepts a plain 2-D table or a
2-D tensor-like object exposing `dim()` and `totable()`. `opts.vmin`/`vmax` set
the color range; `colorbar` defaults to true. Values must be finite.
`pcolormesh` and `pcolor` are aliases.

| Option | Type | Default |
| --- | --- | --- |
| `vmin` / `vmax` | finite number | matrix minimum / maximum |
| `colorbar` | boolean | `true` |
| `colorbar_label` | string | no colorbar title |
| `colorbar_ticks` | integer in [2, 10] | `3` when a title/explicit mode uses the extended bar |
| `colorbar_tick_values` | increasing numeric table within `vmin`/`vmax` | uniform ticks |
| `alpha` | number in [0, 1] | `1` |
| `extent` | `{ left, right, bottom, top }` | `{0, cols, 0, rows}` |
| `origin` | `"upper"` or `"lower"` | `"upper"` |

`opts.extent = { left, right, bottom, top }` maps the matrix onto explicit data
coordinates instead of the default index rectangle `{0, cols, 0, rows}`. The
rectangle must be ordered. `opts.origin` is `"upper"` (default, row 1 at the
top) or `"lower"` (row 1 at the bottom). The extent participates in automatic
ranging. Explicit extent/origin output adds `data-origin` and `data-extent` to
the heatmap group plus `data-row`/`data-col` on each cell; default output keeps
the legacy markup.

When `colorbar_label`, `colorbar_ticks`, or `colorbar_tick_values` is supplied,
the image uses the shared ticked colorbar (`colorbar imshow-colorbar`) instead
of the compact legacy bar. It exposes `data-tick-source`, `data-ticks`, and
per-tick `data-value`/`data-fraction` metadata plus `colorbar-title` and
`colorbar-label` text. `colorbar_ticks` and `colorbar_tick_values` are mutually
exclusive, and explicit values must lie within the resolved `vmin`/`vmax`.
`alpha` sets the cell fill opacity; the heatmap group then carries
`data-alpha`, every cell carries `fill-opacity`, and the colorbar remains fully
opaque. `to_scene()` exports `extent`, `origin`, `style.alpha`, and the colorbar
label/tick settings.

### `fig:boxplot(samples, opts)`

Draws box-and-whisker plots for one or more numeric samples. `opts.labels`
names the samples; whiskers use 1.5×IQR and outliers are drawn separately.

| Option | Type | Default |
| --- | --- | --- |
| `orientation` | `"vertical"` or `"horizontal"` | `"vertical"` |
| `labels` | one label per sample | `sample N` |
| `width` | number in [0.01, 1] or per-sample array | `0.6` |
| `showmeans` | boolean, draw the sample mean | `false` |
| `meanline` | boolean, draw a dashed mean line instead of a marker | `false` |
| `notch` | boolean | `false` |
| `whis` | number ≥ 0, IQR fence multiplier | `1.5` |
| `showfliers` | boolean | `true` |
| `showbox`, `showwhiskers`, `showcaps` | boolean | `true` |
| `color`, `label` | series style | palette / no legend entry |

`width` may be one scalar or one value per sample. Vertical boxes place
categories on x and values on y. Horizontal boxes swap
that mapping, put the category labels on the y axis, and carry
`data-orientation="horizontal"` on each `series-box` group. Both orientations
use `whis` (default 1.5×IQR): the lower whisker reaches the smallest sample value
at or above the lower fence and the upper whisker reaches the largest value at
or below the upper fence; values outside the fences become `box-outlier`
circles. `showfliers = false` hides outlier markers and excludes them from
automatic ranges while keeping the outlier array in scenes. `notch = true`
replaces the box with a `box-notch` polygon narrowed
around the median by `1.57 * IQR / sqrt(n)`, clamped to the quartiles.
`showmeans = true` adds a `box-mean-marker` circle at the sample mean;
combining it with `meanline = true` draws a dashed `box-mean-line` across the
box instead. The group exposes `data-width`, `data-mean`, `data-showmeans`, and
`data-meanline`, `data-notch`, `data-whis`, `data-showfliers`, `data-showbox`,
`data-showwhiskers`, and `data-showcaps`. `to_scene()` exports `orientation`, `mean`,
`showmeans`, `meanline`, `notch`, `notch_low`, `notch_high`, `whis`,
`showfliers`, `showbox`, `showwhiskers`, and `showcaps`, and the scene root reports `category_axis = "x"` or `"y"`.

### `fig:violinplot(samples, opts)`

Draw kernel-density violins for one or more numeric samples. `samples` is one
numeric sequence or a list of sequences. A Gaussian KDE is evaluated between
each sample's extrema and normalized to the widest body.

| Option | Type | Default |
| --- | --- | --- |
| `positions` | numeric array matching the samples | `1, 2, ...` |
| `width` | number or per-sample array in [0.01, 1], fraction of the minimum position spacing | `0.5` |
| `points` | integer in [10, 500], KDE samples per body | `50` |
| `bandwidth` | positive number | Silverman's rule |
| `showextrema` | boolean | `true` |
| `showmedians` | boolean | `true` |
| `showquartiles` | boolean | `true` |
| `showmeans` | boolean, draw the sample mean | `false` |
| `meanline` | boolean, draw a dashed mean line instead of a marker | `false` |
| `orientation` | `"vertical"` or `"horizontal"` | `"vertical"` |
| `colors` | one color per sample | palette colors |
| `color` | single color for every sample | palette colors |
| `labels` | one tick/legend label per sample | `sample N` |
| `label` | shared legend label | no legend entry |
| `alpha` | number in [0, 1] | `0.65` |
| `edgecolor` | color string | sample color |
| `linewidth` | number ≥ 0 | `1` |

`width` may be one scalar or one fraction per sample. Each violin is a separate
series with class `series-violin` and exposes `data-width`. Bodies are
`violin-body` polygons; medians are `violin-median` lines, quartiles are
`violin-quartile` dashed lines, the center is a `violin-center` line, and
sample extrema are `violin-extrema` circles. With `showmeans = true`, each
violin gains a `violin-mean-marker` circle at its mean; `meanline = true`
draws a dashed `violin-mean-line` across the body instead. The group exposes
`data-position`, `data-points`, `data-bandwidth`, `data-min`, `data-max`,
`data-mean`, `data-q1`, `data-median`, `data-q3`, `data-showmeans`, and
`data-meanline`, and `data-orientation`. Vertical violins put categories on x;
horizontal violins put them on y, with values on x and the category ticks moved
accordingly. Sample labels become category ticks and are also used as legend
labels. Scene export includes `orientation`, the sorted sample, normalized
density array, polygon body coordinates, quartiles, mean, and display flags.

### `fig:contour(values, opts)`

Draws marching-squares contour lines. `opts.levels` is a level count or an
explicit level table. `opts.x` and `opts.y` optionally give explicit coordinate
vectors for the matrix columns and rows; they must have `cols` and `rows`
entries respectively. When either is supplied, contour geometry and automatic
ranging use the coordinate values instead of the default index grid, and
`to_scene()` exports the coordinate arrays. `opts.labels = true` places one
level label per contour level; `opts.linestyle` accepts the shared line styles.

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
| `linewidth` | number ≥ 0, bar outline stroke | `1` |
| `color` | color string | next palette color |
| `colors` | table of color strings, one per series | palette colors |
| `bar_colors` | flat color list (single series) or one list per series | series colors |
| `label` | string | no legend entry |
| `labels` | table of strings, one per series | descriptor labels or none |
| `alpha` | number in [0, 1] | `1` |
| `edgecolor` | color string | `#ffffff` |
| `edgecolors` | flat per-bar list or one list per series | `edgecolor` |
| `grouped` | boolean | `true` for multiple series |
| `stacked` | boolean | `false` |
| `yerr` | error specification (see below) | no error bars |
| `ecolor` | color string | series fill color |
| `elinewidth` | number ≥ 0 | `1` |
| `capsize` | number ≥ 0, SVG user units | `4` |

`width` is a fraction of the smallest spacing between x positions (or 1 for a
single bar / categorical position). `linewidth` controls the shared outline
stroke width of every bar in the call without changing its fill or the
automatic range. In grouped mode that width is shared by all series in a group,
so every group stays centered on its category position. In
stacked mode positive and negative values accumulate separately from zero.
`stacked = true` and `grouped = true` are mutually exclusive. `label` applies to
a single series; use `labels` (or descriptor labels) for multiple series. The
`labels` and `colors` tables must have exactly one entry per value series.
`bar_colors` is a flat list with one color per bar for a single series, or a
nested list with one color list per series for grouped/stacked bars; each nested
list must contain one color per bar. `edgecolors` follows the same shape and
sets one outline color per bar. Bar scene series export their resolved
`bar_colors` and `edgecolors` arrays.

`yerr` mirrors `errorbar` error specifications. For a single series it may be a
non-negative number, a flat per-bar sequence, or an asymmetric
`{ lower = ..., upper = ... }` / `{ lower_sequence, upper_sequence }` table. For
multiple series it must contain exactly one such specification per series.
Errors are anchored at each bar's top (or each stacked segment's top), and the
automatic y range includes both error extents. Groups with errors add
`data-yerr="true"` plus `data-yerr-mode="asymmetric"` when lower and upper
errors differ. Error lines use `bar-error` and caps use `bar-error-cap`.
Scene export includes `yerr_lower`, `yerr_upper`, the asymmetric flag,
`ecolor`, `elinewidth`, and `capsize`.

Negative values draw downward from zero. The automatic x extent includes grouped
offsets, and the automatic y extent includes stacked bottoms, total heights, and
bar error extents. The y-axis includes zero. Category ticks are emitted once per
call, even when the call contains several series.

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

Shade a horizontal or vertical data-coordinate band. Options: `color`,
`alpha`, `label`, and `hatch`. The span extends the reduced axis range and the
resolved hatch is exported through the series style.

### `fig:loglog(x, y[, opts])` / `semilogx` / `semilogy`

Convenience wrappers that select log scales and then call `plot`. `loglog` sets
both axes, `semilogx` sets x, and `semilogy` sets y.

### `fig:axhline(y[, opts])` / `fig:axvline(x[, opts])`

Draw a horizontal or vertical reference line in data coordinates. Options:
`color`, `linewidth`, `linestyle` (`solid`, `dashed`, `dotted`, `none`),
`alpha`, and `label`. A horizontal line extends the y range; a vertical line
extends the x range. `axhline` also accepts `xmin`/`xmax` and `axvline` accepts
`ymin`/`ymax` as axes-fraction endpoints in `[0, 1]` (defaults `0` and `1`).
The fractions only change the visible screen span; they do not change the data
coordinate used for automatic ranging. Each endpoint pair must be ordered.

The group exposes `data-xmin`/`data-xmax` for `axhline` and
`data-ymin`/`data-ymax` for `axvline`; `to_scene()` exports the same fields
with the data coordinate.

### `fig:axline(x1, y1, x2, y2[, opts])`

Draw the infinite line through two distinct data points, clipped to the plot
rectangle. Options are the same as `axhline`: `color`, `linewidth`,
`linestyle`, `alpha`, and `label`. On logarithmic axes the line is straight in
the transformed (screen) space. The two defining points participate in
automatic ranging, but the clipped extensions do not.

The series group exposes `data-x1`, `data-y1`, `data-x2`, `data-y2`, and
`data-clipped` (whether the visible segment extends beyond the defining
points). `to_scene()` exports the same anchors with `kind = "axline"`.

### `fig:to_html([title])` / `fig:save_html(path[, title])`

Embed the SVG in a standalone HTML document.

### `fig:xtick_rotation(angle)` / `fig:ytick_rotation(angle)`

Rotate x or y tick labels by an integer in `[-90, 90]`. Useful for long
categorical labels and for wide y labels. Rotated labels keep the existing
right/left alignment and pivot around their text anchor. Both settings are
exported as `xtick_rotation` / `ytick_rotation` in the scene. On figures with a
twin y axis, `ytick_rotation` applies to both right-hand label columns.

### `fig:ticklabelsize(size)` / `fig:ticklabelcolor(color)`

Set the Cartesian tick-label font size and color for both axes (including twin
axes). Defaults remain `11` and `#222222`. Larger sizes expand the left and
bottom layout margins; SVG roots expose `data-ticklabelsize` and
`data-ticklabelcolor` when changed, and scenes export both values.

### Labels and titles

```lua
fig:title("text")
fig:title("left aligned", { loc = "left" })
fig:title("right aligned", { loc = "right" })
fig:title("styled", { fontsize = 20, color = "#0f172a" })
fig:xlabel("text")
fig:xlabel("x", { labelpad = 10, fontsize = 15, color = "#334155" })
fig:ylabel("y", { labelpad = 8, fontsize = 15, color = "#334155" })
```

Arguments must be strings (empty strings are allowed). `xlabel` and `ylabel`
accept `labelpad` (number ≥ 0, default `0`) to increase the corresponding layout
margin and move the axis label away from the plot box; `fontsize` (number >
0) and `color` style the label text. Root SVG metadata and scenes report
`xlabel_pad`/`ylabel_pad`, plus the resolved `*_fontsize`/`*_color` values. `title` accepts
`loc = "left"`, `"center"` (default), or `"right"` and aligns the title to the
axes box (Cartesian), canvas (pie/polar), or outer grid (subplots). Calling
`title(text)` without options keeps the last alignment. Scenes export the
resolved `title_align`. `fontsize` (number > 0) and `color` style the title;
the resolved values are exported as `title_fontsize`/`title_color`, including
pie, polar, and subplot scenes. Text is XML-escaped and invalid XML control
characters are replaced. The y label is rotated -90°.

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
| `backgroundcolor` | color string | no background |
| `backgroundedgecolor` | color string | no border |
| `backgroundalpha` | number in [0, 1] | `1` |
| `backgroundpad` | number ≥ 0 | `3` |
| `rotation` | number in [-180, 180], degrees | `0` |

`rotation` rotates the text around its anchor; background boxes stay
axis-aligned. `backgroundcolor` draws a rounded `annotation-background` box behind the text
using approximate Helvetica/Arial metrics; the edge, opacity, and padding are
optional, and the other background options require `backgroundcolor`.
Background boxes work for Cartesian and polar annotations and are exported in
scenes. `arrow = true` draws a leader line from the text to `(x, y)` using the
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

### Aspect ratio

```lua
fig:aspect("auto")    -- restore the adaptive plot box
fig:aspect("equal")   -- one x unit equals one y unit on screen
fig:aspect(0.5)       -- one y unit is half as tall as one x unit is wide
```

The optional aspect constraint shrinks the plot box inside the normal layout
margins and centers it; labels, ticks, legends, and colorbars keep their usual
outside positions. `"equal"` is shorthand for `1`, and `"auto"` clears the
constraint. Numeric values must be positive. An extreme ratio that leaves less
than a drawable plot box raises an error when the figure is rendered. On log
axes the constraint uses the transformed (decade) spans. Only the primary x/y
axes define the ratio when twin axes are present. SVG roots add `data-aspect`,
`data-plot-width`, and `data-plot-height` when aspect is active; scene export
adds `aspect`, `aspect_mode`, and `aspect_adjustable = "box"`.

### Grid

```lua
fig:grid(true)
fig:grid(false)
fig:grid()       -- same as true
fig:grid(true, { axis = "x" })
fig:grid(true, { axis = "both", minor = true })
```

Grid is off by default. Grid lines align with the rendered x and y ticks and are
drawn behind series. `axis` selects `"x"`, `"y"`, or `"both"`; `minor = true`
adds a fainter minor grid at the minor tick intervals. Minor grid lines use the
`grid-minor` group and `minor-grid-line` class, and the SVG root reports
`data-minor-grid="true"`.

`alpha` sets the major-grid stroke opacity. Minor lines inherit the major
color, width, and dash pattern, defaulting to 65% of the major width and 60% of
its opacity. Override them independently with `minor_color`,
`minor_linewidth`, `minor_linestyle`, and `minor_alpha`; the minor style still
requires `minor = true` to draw. `to_scene()` exports resolved `grid_style` and,
when the minor grid is enabled, `minor_grid_style` objects with color, width,
style, alpha, and (for the major style) axis.

### `fig:minorticks([enabled[, opts]])`

```lua
fig:minorticks(true)
fig:minorticks(false)
fig:minorticks(true, { axis = "y" })
```

Minor tick marks are off by default. On linear axes each major interval is
divided into five parts by default; `opts.subdivisions` accepts an integer in
[2, 10] to choose a different count. On logarithmic axes the 2–9 mantissas of
each decade are always used, regardless of `subdivisions`. Values that coincide
with a major tick are omitted. `opts.axis` can be `"x"`, `"y"`, or `"both"` and
is independent from the minor grid setting. Minor marks and minor grid lines
use the same subdivision count. The SVG root exposes `data-minor-subdivisions`
and the scene reports `minor_subdivisions`; marks use the `minor-tick-mark`
class. Minor marks are skipped for categorical axes.

### Legend

```lua
fig:legend()
fig:legend({ loc = "lower left", frame = false })
```

No options are required.

| Option | Type | Default |
| --- | --- | --- |
| `loc` | corners, edge centers, `"center"`, or `"best"` | `"upper right"` |
| `frame` | boolean | `true` |
| `framealpha` | number in [0, 1] | `0.92` |
| `facecolor` | color string | `#ffffff` |
| `edgecolor` | color string | `#bbbbbb` |
| `borderpad` | number ≥ 0 | `8` |
| `handlelength` | number ≥ 0 | `20` |
| `fontsize` | number > 0 | `11` |
| `title_fontsize` | number > 0 | `fontsize` |
| `ncol` | integer in [1, 6] | `1` |
| `title` | string | none |

The accepted locations are the four corners, `"upper center"`,
`"lower center"`, `"center left"`, `"center right"`, `"center"`, and `"best"`.
`framealpha`, `facecolor`, and `edgecolor` style the frame independently.
`borderpad` expands the frame around its contents, `handlelength` sets the
swatch length, and `fontsize` scales labels and frame geometry on Cartesian and
polar legends. `title_fontsize` styles only the title, independently of labels. Only series with a non-empty
`label` appear. Swatches reflect the series type
(line, point, bar, or error bar). Calling `legend()` with no labeled series
produces no legend box. In polar figures `"best"` searches for the placement
that covers the fewest labels and data points; Cartesian figures currently
resolve `"best"` to the upper-right corner. Cartesian scene roots export a
`legend_style` object when a legend was requested, and polar scene legends carry
the same frame and spacing fields.

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
- Minor ticks subdivide each linear major interval into five parts, or use the
  2–9 mantissas per decade on log axes, and never duplicate a major value.
- Tick labels use compact decimal/scientific formatting.
- Categorical bar positions replace numeric x tick labels.
- Linear and base-10 logarithmic x/y axes, date-formatted x labels, twin axes,
  and polar axes are supported.

## Color cycle

The default color cycle is Matplotlib tab10-inspired:

`#1f77b4`, `#ff7f0e`, `#2ca02c`, `#d62728`, `#9467bd`, `#8c564b`, `#e377c2`,
`#7f7f7f`, `#bcbd22`, `#17becf`.

Colors can be given as `#RGB`, `#RRGGBB`, or CSS color names. Values that do not
match these forms raise errors.

## SVG contract

`to_svg()` produces a standalone SVG 1.1 document:

- XML declaration and `xmlns="http://www.w3.org/2000/svg"`
- Root `width`, `height`, and `viewBox`, plus `data-dpi`, `data-xscale`,
  `data-yscale`, `data-minorticks`, `data-minor-subdivisions`, and
  `data-minor-grid` metadata. Aspect-
  constrained figures also add `data-aspect`, `data-plot-width`, and
  `data-plot-height`
- White background rectangle
- A clip path limiting series and annotations to the axes rectangle
- Groups with classes such as `figure`, `grid`, `grid-minor`, `series-layer`,
  `series-line`, `series-scatter`, `series-hist`, `series-bar`, `series-axline`,
  `series-fill`, `series-fillx`, `series-stem`, `series-quiver`,
  `series-hexbin`, `series-eventplot`, `series-box`, `series-violin`,
  `hist-step`, `hist-step-filled`, `step-fill`, `event`,
  `errorbar-limit-lower`, `errorbar-limit-upper`, `errorbar-limit-left`,
  `errorbar-limit-right`, `box-mean-marker`,
  `box-mean-line`, `box-notch`, `violin-mean-marker`, `violin-mean-line`,
  `annotation-layer`, `annotation`,
  `annotation-text`, `annotation-arrow`, `axes`, `ticks`, `minor-tick-mark`,
  `xlabel`, `ylabel`, `title`, and `legend`
- Quiver groups add `quiver-arrow`, `quiver-shaft`, and `quiver-head`; hexbin
  groups add `hexbin-cell` and, when enabled, a `hexbin-colorbar` group
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
- unordered image extents or unknown image origins
- contour coordinate vectors whose lengths do not match the matrix
- non-positive aspect ratios that leave no drawable plot box
- invalid quiver pivots, scales, arrow caps, or vector lengths
- invalid hexbin grids, minimum counts, value ranges, or colorbar ticks
- invalid eventplot orientations, row offset/length arrays, or non-positive
  lengths
- invalid histogram histtype names
- invalid boxplot orientations or non-boolean mean options
- invalid violin mean options
- eventplot color or label arrays whose length does not match the rows
- negative bar, barh, broken_barh, or histogram line widths
- malformed broken_barh ranges or non-positive broken_barh widths/heights
- pie explode values outside [0, 0.5] or non-boolean shadow options
- invalid image colorbar tick counts, labels, out-of-range tick values, or alpha
- unknown title alignment or legend location values
- negative marker edge widths or invalid marker face/edge colors
- non-positive errorbar `errorevery` values
- non-boolean ECDF complementary values
- malformed multi-series bar color lists
- annotation background options without a background color
- negative axis label padding, non-positive axis label font sizes, or invalid label colors
- negative or malformed legend border padding/handle lengths
- pie label/percentage distances outside [0.01, 2]
- invalid pie wedge edge colors or negative line widths
- non-positive pie label/percentage sizes or invalid text colors
- quiver color arrays with wrong lengths or invalid colors
- eventplot event color arrays with wrong lengths or invalid colors
- non-boolean boxplot notch flags, negative `whis`, or non-boolean
  `showfliers`
- non-boolean pie `counterclock` flags
- hist2d edge tables that are too short, non-increasing, or combined with
  `range`
- errorbar `ecolor` arrays with wrong lengths or invalid colors
- non-positive legend font sizes
- box/violin width arrays with wrong lengths or out-of-range values
- errorbar markersize/elinewidth arrays with wrong lengths or invalid values
- eventplot linewidth arrays with wrong lengths or negative values
- non-boolean box component visibility flags
- negative quiver head widths, non-positive legend title sizes
- bar/barh/hist edge-color arrays with wrong lengths or invalid colors
- scatter edgecolor arrays whose length does not match the points
- malformed errorbar y or x limit flags
- non-boolean step fill flags or alpha values outside [0, 1]
- non-increasing or too-short explicit histogram bin edges, or bins combined with range
- per-point scatter linewidth arrays with wrong lengths or negative values
- unsupported hexbin/hist2d color norms or log norm with negative vmin
- non-boolean hist2d show_empty values
- scatter alpha arrays whose length does not match the points
- stem orientations outside vertical/horizontal
- quiver angles outside xy/uv
- non-positive tick label sizes or invalid tick label colors
- histogram hatches on stepped outlines or unsupported patterns
- violin orientations other than vertical/horizontal
- non-boolean pie rotatelabels values
- unsupported fill/span hatch patterns
- non-positive title font sizes or invalid title colors
- scatter marker arrays whose length does not match the points
- annotation rotations outside [-180, 180]
- invalid errorbar/stem marker face/edge colors or widths
- eventplot linestyles outside the shared set
- barh hatch patterns outside the shared set
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
  lengths. Streamplot arrow glyphs are screen-space triangles clipped to the
  polar frame circle. Contour levels that exactly equal a matrix sample can
  drop that degenerate branch. Legend placement uses estimated text metrics,
  not a full text-measurement engine.
- 3-D axes support line/scatter/surface/mesh, not full camera/lighting.
- Basic fixed/adaptive margins; crowded category labels can overlap.
- Fill masks are boolean tables; callbacks and numeric alpha masks are not
  supported. Interpolation uses the midpoint between adjacent samples.
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
  title = "...", title_align = "center",
  title_fontsize = 18, title_color = "#222222",
  xlabel = "...", ylabel = "...",
  xlabel_pad = 0, ylabel_pad = 0,
  xlabel_fontsize = 13, ylabel_fontsize = 13,
  xlabel_color = "#222222", ylabel_color = "#222222",
  xscale = "linear", yscale = "linear",
  xtick_rotation = 0, ytick_rotation = 0,
  ticklabelsize = 11, ticklabelcolor = "#222222",
  minorticks = false, minor_tick_axis = "both", minor_subdivisions = 5,
  minor_grid = false,
  xlim = { min, max }, ylim = { min, max },
  grid = false, legend = false,
  legend_style = { loc = "upper right", frame = true, framealpha = 0.92,
                   facecolor = "#ffffff", edgecolor = "#bbbbbb",
                   borderpad = 8, handlelength = 20, fontsize = 11,
                   title_fontsize = 11, ncol = 1, title = nil },
  grid_style = { color = "#d9d9d9", linewidth = 1, linestyle = "solid",
                 alpha = 1, axis = "both" },
  minor_grid_style = { color = "#d9d9d9", linewidth = 0.65,
                       linestyle = "solid", alpha = 0.6 },
  category_axis = "x", category_ticks = nil,
  series = {
    { kind = "line", x = {...}, y = {...}, style = {...} },
    { kind = "scatter", x = {...}, y = {...},
      style = { marker = "circle", markers = { "circle", "square" },
                alphas = { 0.4, 0.8 } } },
    { kind = "quiver", x = {...}, y = {...}, u = {...}, v = {...},
      scale = nil, scale_mode = "auto", scale_unit = "screen_multiplier",
      auto_length = 18, pivot = "tail", max_arrows = 512,
      normalize = false, angles = "xy", stride = 1, drawn = 63,
      style = {...} },
    { kind = "hexbin", x = {...}, y = {...}, cells = {
        { row = 1, column = 1, x = 0.5, y = 0.25, count = 4 }, ...
      }, counts = { 4, ... }, gridsize = 20, mincnt = 1,
      width = 0.2, radius = 0.115, point_count = 240, vmin = 1, vmax = 9,
      colorbar = true, colorbar_label = "points", colorbar_ticks = 3,
      style = {...} },
    { kind = "image", rows = 2, cols = 3, values = {...}, vmin = 1,
      vmax = 6, extent = { 10, 40, 100, 300 }, origin = "lower",
      colorbar = true, colorbar_label = "value",
      colorbar_tick_values = { 1, 3, 5 }, style = {...} },
    { kind = "contour", rows = 3, cols = 3, level = 0.5,
      segments = { { x1, y1, x2, y2 }, ... },
      x = { 10, 20, 30 }, y = { 100, 200, 300 }, style = {...} },
    { kind = "errorbar", x = {...}, y = {...}, errorevery = 1,
      lolims = { true, false }, uplims = { false, true },
      xlolims = { false, true }, xuplims = { true, false },
      yerr = {...}, yerr_lower = {...}, yerr_upper = {...},
      xerr = {...}, xerr_lower = {...}, xerr_upper = {...} },
    { kind = "axline", x1 = 0, y1 = 0, x2 = 1, y2 = 1, style = {...} },
    { kind = "axhline", y = 2, xmin = 0.1, xmax = 0.6, style = {...} },
    { kind = "axvline", x = 2, ymin = 0.2, ymax = 0.9, style = {...} },
    { kind = "fill", x = {...}, y1 = {...}, y2 = {...},
      where = { true, true, false, ... }, interpolate = true,
      segments = { { x = {...}, y1 = {...}, y2 = {...} }, ... },
      style = {...} },
    { kind = "fillx", y = {...}, x1 = {...}, x2 = {...}, style = {...} },
    { kind = "stem", x = {...}, y = {...}, base = 0.5,
      orientation = "vertical", style = {...} },
    { kind = "eventplot", orientation = "horizontal",
      rows = { { 0.4, 1.1 }, { 0.8, 1.4 } },
      lineoffsets = { 1, 4 }, linelengths = { 0.7, 1.0 },
      colors = { "#2ca02c", "#d62728" },
      eventcolors = { "#166534", "#4ade80", "#991b1b", "#f87171" },
      labels = { "fast", "slow" }, style = {...} },
    { kind = "broken_barh",
      ranges = { { 0, 3 }, { 5, 2 } }, y = 2, height = 0.6,
      style = {...} },
    { kind = "box", position = 1, width = 0.6, orientation = "horizontal",
      mean = 3, showmeans = true, meanline = false,
      q1 = 2, median = 3, q3 = 4, low = 1, high = 5, outliers = { 9 },
      style = {...} },
    { kind = "violin", position = 1, width = 0.5, mean = 3,
      orientation = "vertical", showmeans = true, meanline = false,
      q1 = 2, median = 3, q3 = 4, notch = false,
      notch_low = nil, notch_high = nil,
      whis = 1.5, showfliers = true,
      showbox = true, showwhiskers = true, showcaps = true,
      style = {...} },
    { kind = "bar", x = {...}, y = {...}, width = 0.8,
      bar_colors = { "#9ecae1", ... } },
    -- Grouped bars keep category centers in x and add a per-series offset:
    { kind = "bar", x = {...}, y = {...}, width = 0.4, mode = "grouped",
      grouped = true, offset = -0.2, offsets = {...} },
    -- Stacked bars add the bottom/top interval for every bar:
    { kind = "bar", x = {...}, y = {...}, width = 0.8, mode = "stacked",
      stacked = true, bottom = {...}, top = {...}, stack = {...} },
    { kind = "hist", edges = {...}, counts = {...},
      orientation = "horizontal", histtype = "stepfilled" },
    { kind = "hist2d", x = {...}, y = {...}, bins_x = 10, bins_y = 10,
      show_empty = true, edges_x = {...}, edges_y = {...}, cells = {...} },
    { kind = "step", x = {...}, y = {...}, where = "post",
      fill = true, fillalpha = 0.2, style = {...} },
  },
  annotations = {
    {
      kind = "annotation", text = "peak", x = 2.5, y = 4.1,
      xytext = { 3.5, 5.0, x = 3.5, y = 5.0 },
      color = "#444444", fontsize = 13, align = "center", rotation = -12,
      style = { color = "#444444", fontsize = 13, align = "center",
                rotation = -12 },
      arrow = { enabled = true, color = "#444444", linewidth = 1.5, head = 8 },
      background = { color = "#ffffff", edgecolor = "#d62728",
                     alpha = 0.9, pad = 4 },
    },
  },
}
```

`Figure:to_scene()` is a convenience wrapper.  Limits default to the data range
with 5% padding, or the explicit `xlim`/`ylim` values. Log-axis limits are
padded in log space and remain positive. Annotations retain data coordinates
and style so another backend can apply its own coordinate transform; they do not
affect the exported limits. Cartesian root scenes also export `grid_style` and,
when enabled, `minor_grid_style`. `axhline`/`axvline` scenes carry their data
coordinate plus `xmin`/`xmax` or `ymin`/`ymax`; masked fill scenes carry
`where`, `interpolate`, and resolved `segments`; histogram scenes carry
`orientation` and `histtype`; eventplot scenes carry `orientation`, `rows`,
`lineoffsets`, `linelengths`, and optional `colors`/`eventcolors`/`labels`;
broken-bar scenes
carry their `ranges`, `y`, and `height`; box scenes carry `mean`, `showmeans`,
and `meanline`; violin scenes also carry `orientation`; stem scenes carry
`base` and `orientation`; and
ECDF step scenes
carry `ecdf` plus `complementary`. Cartesian scene roots export `title_align`
and, when requested, `legend_style`. Error-bar scenes always carry
`errorevery`, optional `lolims`/`uplims`/`xlolims`/`xuplims`, and quiver scenes
carry `angles`;
marker-capable line, errorbar, and stem styles may include `markerfacecolor`,
`markeredgecolor`, and `markeredgewidth`. Scatter styles may include per-point
`markers`, `alphas`, `edgecolors`, and `linewidths` arrays. Errorbar styles may
include per-point `ecolors`, `markersizes`, and `elinewidths`, and eventplot
styles may include per-row `linewidths`; bar/barh/hist/fill/span styles may
include per-bar/bin `edgecolors`; include `hatch` when a pattern is active. Step scenes export `fill` and
`fillalpha`; scene roots export `title_fontsize`/`title_color`, and pie scenes
export `rotatelabels`, `edgecolor`, `linewidth`, and the slice text sizes/colors.
Hist2d scenes export `explicit_edges`, `color_norm`, `color_vmin`, and
`color_vmax`. Bar series always keep category centers in `x`. The scene
root exposes `category_axis` (`"x"` or `"y"`) so a backend knows which axis owns
the `category_ticks` positions.
Grouped series also expose a scalar `offset` plus an `offsets` array; stacked
series expose the per-bar `bottom`, `top`, and `stack` arrays so a backend does
not have to infer the layout from the rendered SVG. Error-bar scenes always
carry `yerr_lower`/`yerr_upper` and, when horizontal errors are present,
`xerr_lower`/`xerr_upper`; `yerr`/`xerr` mirror the upper side for older
backends. `axline` scenes carry the four defining anchors and do not include
the clipped extensions. Line styles carry the normalized `markevery` index
list when marker decimation is active. Minor tick, subdivision, and minor grid
settings are reported at the scene root.

Quiver scenes export the component arrays plus the resolved scale mode,
`scale_unit = "screen_multiplier"`, `auto_length = 18`, pivot, arrow cap,
normalization flag, decimation stride, and drawn count. Hexbin scenes export the
input points, filtered cell records, counts, regular-cell width/radius, value
limits, and colorbar settings. Image scenes add `extent` and `origin` when the
image uses explicit field coordinates, plus `colorbar_label`, `colorbar_ticks`,
and `colorbar_tick_values` when the extended colorbar is active. Pie scenes use
a separate `pie` block with `radius`, `inner_radius`, `shadow`, `rotatelabels`,
`counterclock`, `edgecolor`, `linewidth`, the slice text sizes/colors, and
per-slice `value`, `percent`, `start_angle`, `end_angle`, `color`, `label`, and
`explode` fields. Contour scenes export `x`/`y` coordinate
arrays when the figure supplied them and keep the per-level `segments`. Aspect
constraints appear at the root as `aspect`, `aspect_mode`, and
`aspect_adjustable = "box"`.

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
  title = "Polar rose", title_align = "center",
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
      loc = "best", frame = true, framealpha = 0.92,
      facecolor = "#ffffff", edgecolor = "#bbbbbb",
      title = nil, ncol = 1,
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
        cols = 37, rows = 21,
        u = { {...}, ... }, v = { {...}, ... },
        components = "tangential_radial", periodic = true,
        density = 1, step = nil, step_mode = "auto",
        resolved_step = 0.2, step_unit = "data_radius_units",
        max_steps = 300, max_lines = 64, max_points = 8000,
        arrows = true, arrow_fraction = 0.5, head = 6, truncated = false,
        linestyle = "solid", closed_line_count = 9,
        arc_length_unit = "data_radius_units",
        clip = "polar_circle", arrow_count = 12,
        clipped_arrow_count = 0,
        line_count = 12, point_count = 960,
        lines = {
          { theta = {...}, r = {...}, points = 84, closed = false,
            seed_theta = 0.5, seed_r = 1.4, arc_length = 6.28,
            arrow_count = 1, clipped_arrows = 0,
            arrows = {
              { index = 33, fraction = 0.5, theta = 1.2, r = 2.4,
                angle = -71.3, clipped = false },
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
`theta`/`r` as the grid coordinates, `cols`/`rows` for their counts, copied
`u`/`v` matrices, `components = "tangential_radial"`, `periodic`, `density`,
the requested `step`, `step_mode`, `resolved_step`, `step_unit =
"data_radius_units"`, caps and `truncated`, `arrow_fraction`, `arrow_count`,
`clipped_arrow_count`, `closed_line_count`, `clip = "polar_circle"`, and
`arc_length_unit = "data_radius_units"`, plus a `lines` array whose entries
carry `theta`, `r`, `points`, `closed`, `seed_theta`, `seed_r`, `arc_length`,
`arrow_count`, `clipped_arrows`, and `arrows` (each with the 1-based anchor
point `index`, its arc-length
`fraction`, `theta`, `r`, the screen-space `angle`, and a `clipped` flag).
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
reconstructed, and series legend entries include `linestyle` when the series
defines one (for example a dashed streamplot swatch).
Polar `annotations` use theta/r coordinates instead of Cartesian x/y, mirroring
the Cartesian annotation schema. The `rmax`, tick arrays, and labels reflect the
same resolution rules as the SVG renderer, so another backend does not need to
reimplement automatic limits or "nice" tick selection. Exporting a figure that
mixes Cartesian and polar series or annotations raises an error, matching
`to_svg()`.
