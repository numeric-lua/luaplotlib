## Unreleased

- `fig:bar` accepts nested `bar_colors` for grouped/stacked multi-series bars:
  each series can now have its own per-bar color list while a single series
  keeps the existing flat list. Bar scenes export the resolved colors;
- `fig:annotate` and `fig:polar_annotate` accept `backgroundcolor`,
  `backgroundedgecolor`, `backgroundalpha`, and `backgroundpad`. A rounded
  `annotation-background` box is sized with the shared approximate text metrics
  and exported through scenes;
- `fig:xlabel` and `fig:ylabel` accept `labelpad` to enlarge the corresponding
  layout margin. SVG roots expose `data-xlabel-pad`/`data-ylabel-pad`, and
  scenes export `xlabel_pad`/`ylabel_pad`;
- `fig:pie`/`fig:donut` accept `labeldistance` and `pctdistance` radius
  multipliers for slice labels and percentage text. SVG roots and scenes expose
  both values;
- `fig:hist2d` accepts `show_empty = true`, which emits every grid cell with a
  zero count/value instead of omitting empty bins. The series group reports
  `data-show-empty`, and scenes export `show_empty`. Existing examples and
  visual QA cover per-bar colors, annotation backgrounds, label padding, pie
  distances, and complete hist2d grids. The dependency-free suite grows from
  410 to 427 tests. Existing Cartesian APIs remain compatible, polar rendering
  is unchanged, and there are no new runtime dependencies.

## 4.28.0

- `fig:legend` adds `upper center`, `lower center`, `center left`,
  `center right`, and `center` locations for Cartesian and polar figures. The
  Cartesian legend emits a `legend-meta` child with `data-loc`, polar planning
  keeps the existing label-avoidance scoring, and scenes report the resolved
  location;
- `fig:legend` accepts `framealpha`, `facecolor`, and `edgecolor` to style the
  frame independently. Defaults remain white at 0.92 opacity with a `#bbbbbb`
  edge; Cartesian scenes export `legend_style`, and polar scenes carry the same
  fields in `polar.legend`;
- `fig:errorbar` adds `errorevery`: every line vertex and marker stays visible,
  while error bars are drawn at the first point and every Nth point after it.
  Groups expose `data-errorevery`/`data-error-points`, automatic limits cover
  the drawn extents plus all point positions, and scenes export the stride;
- `fig:plot` adds `markerfacecolor`, `markeredgecolor`, and `markeredgewidth`
  for filled marker shapes. The marker fill defaults to the series color, the
  optional outline follows alpha, and the scene style exports all three fields;
- `fig:ecdf` adds `complementary = true`, which plots `1 - F_n(x)` while
  retaining the existing post-step geometry. ECDF groups expose
  `data-ecdf`/`data-complementary`, and scenes export both flags. A new
  `ecdf_complementary.lua` example and updated line/errorbar examples cover all
  five features. README, API docs, Makefile, and `scripts/visual-qa.sh`
  validate the new metadata. The dependency-free suite grows from 391 to 410
  tests. Existing Cartesian APIs remain compatible, polar rendering is
  unchanged, and there are no new runtime dependencies.

## 4.27.0

- new `fig:broken_barh(xranges, yrange, opts)` draws horizontal Gantt-style
  intervals. `xranges` holds one `{start, width}` pair per rectangle and
  `yrange` is `{y, height}`; ranges and the y interval participate in automatic
  ranging. The series exposes range/y/height metadata, joins the legend, and
  exports `ranges`/`y`/`height` through `to_scene()`;
- `fig:eventplot` accepts `labels`, one tick label per lane. Horizontal lanes
  label the x axis and vertical lanes label the y axis using `lineoffsets` as
  category positions; scenes export the labels and resolved
  `category_axis`/`category_ticks`;
- `fig:pie`/`fig:donut` add `explode` and `shadow`. `explode` shifts one or more
  wedges outward by up to half the radius, `shadow` draws a soft offset wedge
  behind each slice, and labels/leader lines/percentages follow the shifted
  geometry. Scenes export the shadow flag and per-slice explode values;
- `fig:hist` adds `linewidth` for the outline stroke across `bar`, `step`, and
  `stepfilled` styles. The default remains one pixel, and the resolved width is
  exported through the series style;
- `fig:title` accepts `loc = "left" | "center" | "right"`, aligned to the axes
  box for Cartesian figures, the canvas for pie/polar figures, and the outer
  grid for subplot figures. Scenes export `title_align`. New examples
  `broken_barh.lua` and `pie_explode.lua` plus updated eventplot, histogram, and
  title coverage demonstrate the features. README, API docs, Makefile, and
  `scripts/visual-qa.sh` validate the new metadata. The dependency-free suite
  grows from 373 to 391 tests. Existing Cartesian APIs remain compatible, polar
  rendering is unchanged, and there are no new runtime dependencies.

## 4.26.0

- `fig:eventplot` accepts `colors`, one stroke color per row. Row colors are
  used by SVG marks, the first color seeds the legend swatch, and
  `to_scene()` exports the optional `colors` array;
- `fig:boxplot` adds `showmeans` and `meanline`. `showmeans` draws a
  `box-mean-marker` at the sample mean; `meanline` replaces it with a dashed
  `box-mean-line` across the box. Groups export `data-mean`,
  `data-showmeans`, and `data-meanline`, and scenes carry the same values;
- `fig:violinplot` adds the same `showmeans`/`meanline` controls with
  `violin-mean-marker` / `violin-mean-line` marks and mean metadata in SVG and
  scene output;
- `fig:bar` and `fig:barh` accept `linewidth` for the bar outline stroke. The
  default remains one pixel, all series in a call share the requested width,
  and the resolved width is exported through the scene style;
- `fig:imshow` accepts `alpha` in [0, 1]. Cell fills become translucent, the
  heatmap group exposes `data-alpha`, and `to_scene()` carries `style.alpha`;
  the colorbar remains fully opaque. New example `bar_linewidth.lua` and
  updated eventplot, boxplot, violinplot, and imshow examples cover all five
  features. README, API docs, Makefile, and `scripts/visual-qa.sh` validate the
  new metadata. The dependency-free suite grows from 356 to 373 tests. Existing
  Cartesian APIs remain compatible, polar rendering is unchanged, and there
  are no new runtime dependencies.

## 4.25.0

- `fig:minorticks` accepts `subdivisions` (2–10, default 5) to control how many
  equal parts each linear major interval is split into. Minor grid lines use the
  same count, logarithmic axes keep their 2–9 mantissas, and SVG roots/scenes
  expose `data-minor-subdivisions` / `minor_subdivisions`;
- `fig:eventplot` adds `orientation = "vertical" | "horizontal"`, scalar or
  per-row `lineoffsets`, and scalar or per-row `linelengths`. Horizontal lanes
  use event values on y and offsets on x, both orientations participate in
  automatic ranging, and eventplot now exports `rows`, `orientation`,
  `lineoffsets`, and `linelengths` through `to_scene()`;
- `fig:hist` adds `histtype = "bar" | "step" | "stepfilled"`. `"step"` draws one
  stepped outline through every edge and `"stepfilled"` draws the same staircase
  as a filled polygon; both honor vertical/horizontal orientation, density,
  cumulative counts, alpha, and scene export while `"bar"` keeps the existing
  rectangles;
- `fig:boxplot` adds `orientation = "vertical" | "horizontal"`. Horizontal boxes
  put category labels on y, expose `data-orientation` on `series-box` groups,
  export orientation through the scene, and use a corrected 1.5×IQR lower
  whisker that reaches the lowest inlier instead of stopping at Q1;
- `fig:imshow` accepts `colorbar_label`, uniform `colorbar_ticks`, and explicit
  `colorbar_tick_values` within `vmin`/`vmax`. When any is supplied, the image
  switches to the shared ticked colorbar with `data-value`/`data-fraction`
  metadata, a title, and scene fields; the legacy compact bar remains the
  default. New examples `minor_subdivisions.lua`, `eventplot_layout.lua`,
  `hist_styles.lua`, `boxplot_horizontal.lua`, and `imshow_colorbar.lua` cover
  all five features. README, API docs, Makefile, and `scripts/visual-qa.sh`
  validate the new metadata. The dependency-free suite grows from 335 to 356
  tests. Existing Cartesian APIs remain compatible, polar rendering is
  unchanged, and there are no new runtime dependencies; the boxplot lower
  whisker correction is the only intentional visual change to an existing
  chart.

# Changelog

## 4.24.0

- new `fig:hist2d(x, y, opts)` counts paired samples into a rectangular grid.
  `bins` accepts a count or `{ nx, ny }`, `range` fixes
  `{ xmin, xmax, ymin, ymax }`, `density` normalizes by in-range count and cell
  area, and non-empty cells use the shared heat palette. A vertical count or
  density colorbar supports a title, uniform `colorbar_ticks`, or explicit
  `colorbar_tick_values`. Groups expose point/inside counts, grid dimensions,
  norm, and value limits; each cell carries its row, column, count, value, and
  source bounds. Scene export includes the input arrays, edges, cells, counts,
  values, density flag, and colorbar settings;
- `fig:scatter` accepts a numeric `c` array plus `vmin`/`vmax` and colorbar
  options. Values map through the shared heat palette, a colorbar is enabled by
  default, and per-point `colors` are generated for rendering and scene export.
  `c` and `color` are mutually exclusive; colorbar and limit options require
  `c`. The scatter group advertises mapped values and limits, the colorbar uses
  `colorbar scatter-colorbar`, and scene export adds `c`/`color_values`,
  resolved limits, and colorbar metadata;
- new `fig:violinplot(samples, opts)` draws normalized Gaussian-kernel
  violins for one or more samples. Sample-specific or explicit positions,
  width fractions, KDE resolution, Silverman or explicit bandwidth, per-sample
  colors, and extrema/median/quartile toggles are supported. Each body,
  center, median, quartile, and extrema element has a stable class and the
  group reports position, points, bandwidth, extrema, and quartiles. Scene
  export includes sorted samples, densities, polygon coordinates, and display
  flags;
- `fig:stackplot` adds `baseline = "zero" | "sym" | "wiggle"`. `sym` centers
  the complete stack; `wiggle` centers the average cumulative layer boundary.
  Every layer keeps its thickness and the existing `y1`/`y2` geometry remains
  canonical. Stack polygons expose baseline/index metadata and scene export
  adds `stack_baseline`, `stack_index`, and the per-sample `stack_shift`;
- `fig:bar` adds `yerr`, `ecolor`, `elinewidth`, and `capsize`. Errors may be
  symmetric or asymmetric, and multiple series accept one error specification
  per series. Bar errors are anchored at the bar top or stacked segment top and
  participate in automatic ranging. Groups report `data-yerr`/asymmetric mode,
  `bar-error` lines and `bar-error-cap` caps are emitted per bar, and scene
  export preserves both extents and styling;
- new examples `hist2d.lua`, `scatter_colors.lua`, `violinplot.lua`,
  `stack_baseline.lua`, and `bar_errors.lua`. README, API docs, the Makefile,
  and `scripts/visual-qa.sh` validate all five features, including cell/count
  consistency, color-mapped scatter points, violin marks, baseline metadata,
  and bar error/cap counts. The dependency-free suite grows from 312 to 335
  tests. Existing Cartesian defaults are preserved, polar rendering is
  unchanged, and there are no new runtime dependencies.

## 4.23.0

- new `fig:quiver(x, y, u, v, opts)` draws Cartesian vector fields. `u`/`v`
  are data-coordinate components projected through the current axis transforms;
  the largest glyph auto-scales to 18 SVG units unless `scale` is explicit.
  `pivot`, `normalize`, `head`, `linewidth`, `alpha`, `label`, and a
  deterministic `max_arrows` cap (512 by default) match the polar quiver
  vocabulary. The series exposes `data-count`, `data-drawn`, `data-stride`,
  `data-scale`, `data-scale-mode`, `data-pivot`, and `data-normalize`; each
  arrow carries index, magnitude, data position, and angle metadata, and
  `to_scene()` exports the components and resolved scaling;
- new `fig:hexbin(x, y, opts)` aggregates paired samples into regular
  pointy-top hexagons. `gridsize` (2–200) controls the x-cell count, `mincnt`
  filters sparse cells, `vmin`/`vmax` override the count range, and the shared
  heat palette colors each `hexbin-cell`. A vertical count colorbar supports a
  title, uniform `colorbar_ticks`, or explicit `colorbar_tick_values`, with
  `data-value`/`data-fraction` metadata. Scene export includes the filtered
  cells, counts, cell geometry, limits, and colorbar settings;
- `fig:imshow` (and `pcolormesh`/`pcolor`) accepts
  `extent = { left, right, bottom, top }` and `origin = "upper" | "lower"`.
  Cells map onto the explicit rectangle, the extent participates in automatic
  ranging, and `origin = "lower"` places row 1 at the bottom. Explicit
  extent/origin output adds `data-origin`, `data-extent`, and per-cell
  row/column metadata; `to_scene()` exports both fields while the default
  index geometry and markup are unchanged;
- `fig:contour` accepts explicit `x` and `y` coordinate vectors for matrix
  columns and rows. Marching-squares intersections, automatic ranging, labels,
  and scene export use the supplied coordinates; the default index geometry is
  byte-compatible with previous releases;
- new `fig:aspect(value)` constrains the plot box to `"equal"`, a positive
  numeric y-unit/x-unit ratio, or `"auto"` to reset. The box shrinks and centers
  inside the normal label margins, works on linear and log axes, and reports
  `data-aspect`, `data-plot-width`, and `data-plot-height` on the SVG root.
  Scene export adds `aspect`, `aspect_mode`, and `aspect_adjustable = "box"`;
  an unconstrained figure renders exactly as before;
- new examples `quiver.lua`, `hexbin.lua`, `field_coordinates.lua` (raster
  extent/origin and contour coordinates), and `aspect.lua`. README, API docs,
  the Makefile, and `scripts/visual-qa.sh` validate all five features,
  including arrow/count/colorbar consistency, extent metadata, contour
  coordinates, and a square equal-aspect box. The dependency-free suite grows
  from 293 to 312 tests. Polar rendering and existing Cartesian defaults are
  unchanged, and there are no new runtime dependencies.

## 4.22.0

- `fig:axhline` and `fig:axvline` now accept axes-fraction endpoints:
  `xmin`/`xmax` for horizontal references and `ymin`/`ymax` for vertical
  references. The endpoints default to the full axes, must lie in `[0, 1]`
  and be ordered, and only change the visible screen span. SVG groups expose
  `data-xmin`/`data-xmax` or `data-ymin`/`data-ymax`, and `to_scene()` exports
  the same fields with the data coordinate;
- `fig:grid` adds `alpha` plus independent minor-grid styling through
  `minor_color`, `minor_linewidth`, `minor_linestyle`, and `minor_alpha`.
  Minor lines inherit the major color/width/dash by default (65% width and 60%
  opacity), so existing default grids are unchanged. `to_scene()` exports
  resolved `grid_style` and `minor_grid_style` objects;
- `fig:fill_between` and `fig:fill_betweenx` accept a boolean `where` mask and
  `interpolate`. Each contiguous true run becomes its own polygon; interpolation
  adds midpoint edges where a visible run meets a hidden sample. Hidden samples
  do not contribute to automatic ranging. Masked groups report
  `data-where="masked"`, `data-interpolate`, and `data-segments`, each polygon
  reports `data-index`, and scene export includes the mask, interpolation flag,
  and resolved `segments`;
- `fig:hist` accepts `orientation = "horizontal"` to draw bins along x from the
  zero count baseline with data values on y. Bin edges, counts, density, and
  cumulative calculations are shared with vertical histograms; the SVG group
  reports `data-orientation="horizontal"` and scene export swaps the automatic
  axis ranges while carrying the orientation;
- `fig:stem` adds `base`, `marker`, and `linestyle`. Stems can grow from any
  finite data baseline, use every supported marker (or no marker), and hide
  their lines independently. The group exposes `data-base`, `data-marker`, and
  `data-linestyle`; base values participate in automatic ranging and scene
  export;
- new examples `cartesian_controls.lua`, `histogram_horizontal.lua`, and
  `stem.lua` cover the five features. README, API docs, the Makefile, and
  `scripts/visual-qa.sh` validate fractional spans, multiple masked fill runs,
  horizontal bins, styled stems, and resolved major/minor grid styles. The
  dependency-free suite grows to 293 tests. Polar rendering is unchanged, and
  there are no new runtime dependencies.

## 4.21.0

- `fig:errorbar` now accepts independent lower and upper errors. `yerr` and
  `xerr` may be a number, a flat per-point array, or an asymmetric table in
  either `{ lower = ..., upper = ... }` or `{ lower_sequence,
  upper_sequence }` form. Error-bar geometry, automatic ranging, and scene
  export all use the independent extents; asymmetric groups expose
  `data-yerr-mode` / `data-xerr-mode`, and scene series add `yerr_lower`,
  `yerr_upper`, `xerr_lower`, `xerr_upper`, and matching asymmetric flags while
  keeping the legacy upper-side `yerr`/`xerr` arrays;
- new `fig:axline(x1, y1, x2, y2, opts)` draws an infinite line through two
  distinct points, clipped to the plot rectangle with Liang-Barsky clipping.
  The series exposes its defining anchors plus `data-clipped`, participates in
  automatic ranging only through those anchors, supports the same color,
  width, style, alpha, and label options as `axhline`/`axvline`, and exports
  the same fields through `to_scene()`;
- `fig:plot` adds `markevery`: a positive integer stride or a table of
  one-based point indices. Markers are decimated while every line vertex is
  retained; index tables are sorted and de-duplicated. Line groups report
  `data-marker-count` and `data-markevery`, and scene styles carry the
  normalized index list;
- new `fig:ytick_rotation(angle)` mirrors `xtick_rotation` for y tick labels,
  including the right-hand labels of a twin y axis. Angles are integers in
  `[-90, 90]`; both rotations are exported in the scene;
- new `fig:minorticks([enabled[, opts]])` draws minor tick marks on `"x"`,
  `"y"`, or `"both"`, subdividing linear major intervals into five parts and
  using the 2–9 mantissas on log axes. `fig:grid(true, { minor = true })` adds
  a fainter minor grid independently. Major values are never duplicated;
  categorical x axes are skipped. SVG roots expose `data-minorticks` and
  `data-minor-grid`, minor elements use `minor-tick-mark`,
  `grid-minor`/`minor-grid-line`, and the scene reports the same settings;
- `examples/line.lua` now demonstrates `markevery`, minor ticks, and the minor
  grid; `examples/errorbar.lua` uses asymmetric y and x errors; the new
  `examples/axline.lua` covers clipped diagonal, horizontal, and vertical
  reference lines plus y tick rotation. README, API docs, the Makefile, and
  `scripts/visual-qa.sh` cover all five features. The dependency-free suite
  grows to 267 tests; polar rendering is unchanged and there are no new
  runtime dependencies.

## 4.20.0

- polar streamplot arrow glyphs are now clipped to the polar circle in the
  exported SVG geometry, not only by the shared series-layer clip path. Arrow
  triangles are built in screen space, so a large `head` or a late
  `arrow_fraction` can push a vertex past the frame; that vertex is projected
  back onto the circle (with a small inward margin for three-decimal
  coordinate formatting), and every streamline path and arrow vertex now lies
  inside the frame;
- the streamplot series group exposes `data-clip="polar-circle"` and
  `data-clipped-arrow-count`; each `polar-streamline` group reports
  `data-clipped-arrows`, and each `polar-stream-arrow` polygon reports
  `data-clipped`;
- `to_scene()` mirrors the new SVG metadata: streamplot series add `cols`,
  `rows`, `arrow_count`, `clipped_arrow_count`, and
  `clip = "polar_circle"`; every exported line adds `arrow_count` and
  `clipped_arrows`, and every arrow adds `clipped`. Polar legend entries now
  include `linestyle` when a series defines one, so dashed streamplot swatches
  survive export. Clipping flags describe the rendered luaplotlib frame; if
  the canvas is too small to lay out, they fall back to unclipped;
- `examples/polar_streamplot.lua` writes a third output,
  `examples/output/polar-streamplot-clip.svg`: a radial field with
  `arrow_fraction = 0.95` and `head = 24` whose boundary glyphs demonstrate the
  circle clipping. README and API docs describe the clip contract,
  `scripts/visual-qa.sh` checks that every streamline and arrow vertex stays
  inside the frame, validates the series/line/arrow clipping counts, and
  rasterizes the new example, and Cartesian isolation tests cover the added
  metadata. 241 dependency-free tests, with no Cartesian rendering changes and
  no new runtime dependencies.

## 4.19.0

- polar streamplot arrows are now anchored by arc length instead of by point
  index: the new `arrow_fraction` option (default `0.5`, constrained to
  [0.05, 0.95]) places the single directional glyph at that fraction of the
  integrated polyline, so uneven RK spacing, boundary fallbacks, and trimmed
  tails cannot pull it away from the requested position;
- `polar_streamplot` accepts `linestyle = "solid" | "dashed" | "dotted" |
  "none"`; dashed and dotted paths carry matching `stroke-dasharray` values,
  `"none"` hides the path while keeping arrows, and the polar legend swatch
  follows the same dash pattern;
- closed-orbit seeding no longer redraws the same loop from every angular
  seed column: a candidate line that falls more than 50% into already-covered
  occupancy bins is dropped before it consumes the point budget. The bundled
  streamplot examples shrink from 15 to 12 and 13 to 9 lines while keeping
  every distinct orbit, and line/point/arrow caps still apply;
- SVG metadata is now consistent with the scene export. The series adds
  `data-linestyle`, `data-arrow-fraction`, `data-closed-lines`, and
  `data-arc-length-unit="data_radius_units"`; every `polar-streamline` group
  reports `data-closed`, `data-seed-theta`, `data-seed-r`, and
  `data-arc-length`; every arrow reports `data-fraction` next to its existing
  anchor `data-index`, `data-angle`, `data-theta`, and `data-r`;
- `to_scene()` exports the same values: `arrow_fraction`,
  `closed_line_count`, `arc_length_unit`, per-line `closed`/`seed_theta`/
  `seed_r`/`arc_length`, and per-arrow `index`/`fraction` in addition to the
  existing point arrays and angle anchors;
- `examples/polar_streamplot.lua` now also writes
  `examples/output/polar-streamplot-styles.svg`, a dashed field with
  `arrow_fraction = 0.65`; README and API docs describe the new options and
  metadata, `scripts/visual-qa.sh` checks both streamplot examples for arc
  length, seed, closed-orbit, line-style, and arrow-anchor integrity, and
  Cartesian isolation guards cover the new options. 239 tests, with no
  Cartesian rendering changes and no new runtime dependencies.

## 4.18.0

- new `fig:polar_streamplot(theta, r, u, v, opts)` integrates grid-sampled
  polar vector fields into streamlines: `theta` and `r` are strictly increasing
  grid coordinates and `u`/`v` are rows-by-columns matrices of the local
  tangential/radial components at every node; bilinear interpolation and
  fixed-step fourth-order Runge-Kutta run in the physical plane so one step is
  isotropic even when the angular and radial spacings differ;
- a theta grid spanning one full turn is periodic and lines wrap continuously
  across theta=0, while partial sectors stop at their theta edges; lines also
  stop at the radial grid bounds, at zero-magnitude samples, after `max_steps`,
  or when a closed orbit returns to its seed; `theta_zero` and
  `theta_direction` rotate the field with the axes;
- seeding is deterministic and `density`-scaled with coarse occupancy bins that
  suppress retraced coverage; `step` defaults to radial span / 25,
  `max_steps` defaults to 300, `max_lines` to 64, and `max_points` to 8000, so
  SVG output stays bounded; arrows sit near each line midpoint and can be
  disabled with `arrows = false` or sized with `head`;
- the series group exposes `data-cols`, `data-rows`, `data-lines`,
  `data-points`, `data-arrow-count`, `data-step`, `data-step-mode`,
  `data-density`, `data-max-steps`, `data-max-lines`, `data-max-points`,
  `data-arrows`, `data-head`, `data-periodic`, and `data-truncated`; each
  `polar-streamline` group reports its own point/arrow counts and arrow
  polygons carry `data-angle`/`data-theta`/`data-r`;
- labelled streamplots join the measured-text polar legend with a curved
  swatch, and `to_scene()` exports `kind = "streamplot"` series with copied
  `u`/`v` matrices, grid coordinates, periodic/step/cap metadata, and resolved
  `lines` containing `theta`/`r` point arrays plus arrow anchors;
- new `examples/polar_streamplot.lua`, expanded README/API documentation,
  `scripts/visual-qa.sh` checks for line/path/arrow/point-count agreement and
  cap compliance, and Cartesian isolation regressions that pin SVG output,
  scene shape, quiver metadata, and per-figure palette behavior; 236 tests
  with no Cartesian rendering, scene-shape, or dependency changes.

## 4.17.0

- new `fig:polar_quiver(theta, r, u, v, opts)` renders a vector field: `u` is
  the local tangential component toward increasing data theta and `v` is the
  radial component, so `theta_zero`/`theta_direction` rotate arrows with the
  axes while radial arrows keep pointing outward; arrow glyphs are clipped to
  the polar circle and drawn in series order above heatmaps and contours;
- glyph lengths use SVG user units: `scale` sets units per unit magnitude and
  an automatic scale makes the longest arrow 18 units; `normalize = true`
  draws unit-length direction arrows, and `pivot = "tail" | "middle" | "tip"`
  places the data point within the glyph;
- large polar fields are capped deterministically (`max_arrows`, default 512,
  maximum 4096): indices 1, 1+stride, ... are drawn with
  `stride = ceil(count / max_arrows)`, zero-magnitude vectors are skipped, and
  the series group exposes `data-count`, `data-drawn`, `data-stride`,
  `data-max-arrows`, `data-scale`, `data-scale-mode`, `data-pivot`, and
  `data-normalize`, with `data-index`/`data-magnitude`/`data-angle` per arrow;
- labelled quivers participate in the measured-text polar legend with an arrow
  swatch, and `to_scene()` exports `kind = "quiver"` series with copied
  `u`/`v` arrays, `components = "tangential_radial"`, resolved scaling,
  decimation, and style metadata;
- new `examples/polar_quiver.lua`, expanded README/API docs, and
  `scripts/visual-qa.sh` checks that quiver arrow groups match `data-drawn`,
  stay within `max_arrows`, and carry angle metadata; 219 tests, with no
  Cartesian rendering, scene-shape, or dependency changes.

## 4.16.0

- polar contour labels now rotate to the local tangent (kept upright) and are
  placed by collision-aware search over every marching-squares segment; labels
  avoid earlier labels, radial tick text, annotations, and the legend, stay
  inside the circular clip, and are skipped when no clear anchor exists;
- each contour label exposes `data-level` and `data-angle`, and scene export
  adds a preferred `label` anchor (`text`, `theta`, `r`, `u`, `v`, `angle`) per
  level when labels are enabled;
- polar heatmap colorbars accept explicit `colorbar_tick_values` (2-12 strictly
  increasing values within `vmin`/`vmax`, mutually exclusive with
  `colorbar_ticks`) for readable "nice" ticks; SVG ticks and labels expose
  `data-value`/`data-fraction` plus `data-tick-source`, and
  `to_scene()` exports matching `tick_labels`, `tick_fractions`, and
  `tick_source` arrays;
- `examples/polar_heatmap.lua` now includes a colorbar with nice ticks and
  `examples/polar_contour.lua` uses explicit colorbar ticks; `visual-qa.sh`
  checks rotated labels, colorbar metadata, and that Cartesian examples stay
  Cartesian; expanded API/README docs and 208 tests.

## 4.15.0

- `fig:polar_contour` draws projected marching-squares isolines of a matrix,
  with count or explicit `levels`, palette/linewidth/linestyle/alpha styling,
  optional white-haloed level labels, the same `rmin`/`rmax` and
  `theta_min`/`theta_max` projections as `polar_heatmap`, automatic radial-limit
  coverage, legend entries, and `polar.contours` scene export;
- polar heatmaps accept `colorbar = true` with `colorbar_label` and
  `colorbar_ticks` (2-9), reserving a canvas column for a vertical stepped bar
  with compact tick labels; at most one colorbar is allowed per polar figure,
  the legend planner avoids it, and `to_scene()` exports `polar.colorbar`;
- polar polish: the outermost radial tick label is clamped inside the frame and
  exposes `data-fraction`/`data-clamped`, heatmap legend swatches render as
  five-step gradients with `vmin`/`vmax` scene metadata, colorbar ticks use
  three significant digits, and contour labels pick the farthest segment and
  clamp inside the circular clip;
- new `examples/polar_contour.lua`, `make examples`/`scripts/visual-qa.sh`
  coverage for the contour example, expanded API/README/docs, and 203 tests.

## 4.14.0

- `fig:polar_heatmap` (alias `fig:polar_pcolormesh`) projects a rows-by-columns
  matrix into annular/sector cells with `vmin`/`vmax`, `rmin`/`rmax`,
  `theta_min`/`theta_max`, alpha, labels, degree input, legend entries, and
  `polar.heatmaps` scene export;
- polar annotation targets now extend the automatic radial limit, while an
  explicit `rmax` rejects out-of-range targets; annotation text is clamped to
  the canvas (`data-clip`/`data-clamped` metadata) and its leader arrow
  follows;
- measured UTF-8-aware Helvetica/Arial text metrics size polar legend columns,
  titles, and frames; wide and narrow glyphs now receive different widths and
  `data-text-width` exposes the measured label width;
- polar radial tick labels render above series with a white contrast halo, so
  filled bars and heatmaps no longer hide them;
- new `examples/polar_heatmap.lua` and optional `scripts/visual-qa.sh`
  rasterization check; expanded API/README documentation and 188 tests.

## 4.13.0

- label-aware polar legend placement that avoids theta and radial tick labels,
  with `loc = "best"` and `data-*` geometry on the legend group;
- `fig:polar_errorbar` for radial and angular uncertainty, including caps,
  line/marker styling, automatic rmax coverage, and scene export;
- `fig:polar_annotate` at `(theta, r)` coordinates, with polar dispatch from
  `fig:annotate`, leader arrows, and degrees input;
- polar scene export for error-bar series, annotations, legend entries, and
  radius fractions, with mixed-content export guards;
- new `polar_annotations` example, API docs, README updates, and 165 tests.

## 4.12.0

- polar axes (`plt.polar` / `fig:polar`) with circular grid and theta/r ticks;
- polar scatter with per-point markers, sizes, colors, and legend support;
- polar bar wedges with scalar or per-bar widths and per-bar colors;
- `fig:polar_config` for zero location, direction, radial limits, and custom
  angular/radial grids;
- degrees input (`degrees = true` / `theta_unit = "degrees"`) for polar series;
- polar scene export and subplot composition;
- 149 tests.

## 4.11.0

- bar `hatch` patterns (`/`, `\`, `|`, `-`, `+`, `x`, `.`, `o`);
- generated SVG pattern definitions and validation;
- 131 tests.

## 4.10.0

- contour level labels and linestyles;
- tests for labels, dashes, and invalid styles;
- 130 tests.

## 4.9.0

- `eventplot` raster series;
- `ecdf` empirical CDF step curve;
- tests for both;
- 129 tests.

## 4.8.0

- subplot `savefig` format dispatch and unknown-extension errors;
- `Axes3D:to_scene()` for renderer-agnostic 3-D scene export;
- tests for subplot dispatch and 3-D scene contents;
- 128 tests.

## 4.7.0

- `axhspan` / `axvspan` shaded data bands;
- `loglog`, `semilogx`, and `semilogy` convenience wrappers;
- 126 tests.

## 4.6.0

- per-point scatter radii and fill colors;
- histogram `density` and `cumulative` options;
- legend `ncol` and `title`;
- square/triangle/diamond/cross/x markers for line and scatter series;
- 3-D `savefig` SVG/PNG/PDF dispatch;
- 125 tests.

## 4.5.0

- fixed 3-D automatic bounds producing NaN coordinates;
- corrected 1-D surface x/y mapping and validation;
- format-aware `savefig` for `.svg`, `.png`, and `.pdf`;
- axis-specific grid lines;
- `axhline` / `axvline` reference lines;
- refreshed API/README docs; 120 tests.

## 4.4.0

- optional PNG/PDF export through the system `rsvg-convert`;
- 117 tests.

## 4.3.0

- 3-D surface/mesh wireframes;
- 116 tests.

## 4.2.0

- 3-D axis ticks, x/y/z labels, view control, explicit limits, and depth-sorted series;
- 115 tests.

## 4.1.0

- true 3-D axes (`plt.figure3d`) with orthographic box projection, line/scatter, title, and axis labels;
- 114 tests.

## 4.0.0

- gridspec-style width/height ratios for subplots;
- 113 tests.

## 3.0.0

- basic projected 3-D line/scatter (`plot3`, `scatter3`);
- 112 tests.

## 2.2.0

- automatic shared x/y limits in subplots (`sharex`, `sharey`);
- 111 tests.

## 2.1.0

- subplot-level grid/facecolor propagation and first-axes plot/scatter delegates;
- 110 tests.

## 2.0.0

- configurable grid color/width/linestyle;
- figure facecolor and ARIA labels;
- 109 tests.

## 1.5.0

- `contourf` filled contours with optional overlay lines;
- 108 tests.

## 1.4.0

- `fill_betweenx` horizontal bands and `pcolormesh` heatmap alias;
- 107 tests.

## 1.3.0

- `fill_between`, `step`, `stem`, and `stackplot`;
- scene export for the new series;
- 106 tests.

## 1.2.0

- secondary x axis via `fig:twiny()` with top ticks, label, and independent
  limits/scale;
- twiny line/scatter/error-bar series and scene metadata;
- 104 tests.

## 1.1.0

- pie and donut charts with labels, colors, percentages, start angle, radius,
  inner radius, and optional legend;
- pie scene export;
- 103 tests.

## 1.0.0

- scene export parity for image, box, contour, barh, and twin-axis series;
- documented API stability and semantic-versioning policy;
- 99 tests.

## 0.9.0

- secondary y axis via `fig:twinx()`;
- twin line/scatter/error-bar/bar series with independent y limits, scale, and
  label;
- right-side ticks and title integrated into layout;
- 97 tests.

## 0.8.0

- calendar-date x-axis labels via `xdate`;
- standalone HTML export with `to_html`/`save_html`;
- `imshow` accepts 2-D tensor-like matrices;
- 95 tests.

## 0.7.0

- horizontal bar charts (`barh`) with category labels, per-bar colors, options,
  and value labels;
- 91 tests.

## 0.6.0

- per-bar colors for single-series bar charts;
- optional value labels on bars;
- 89 tests.

## 0.5.0

- custom `xticks`/`yticks` with optional labels;
- `xtick_format`/`ytick_format` callbacks for generated and custom ticks;
- 87 tests.

## 0.4.0

- `plt.subplots(rows, cols)` grid figures with configurable gap/margin, parent
  title, per-axes figures, and `share_limits`;
- `imshow` heatmaps with a viridis-like colorbar;
- boxplots with quartiles, whiskers, caps, and outliers;
- marching-squares contour lines;
- `xtick_rotation` for crowded categorical axes;
- 85 tests.

## 0.3.0

- logarithmic x/y axes with decade ticks and positive-value validation;
- annotations with optional leader arrows;
- stacked and grouped bar charts;
- renderer-agnostic scene export (`figure:to_scene()`);
- 76 tests.

## 0.2.0

- error-bar plots, CI, and initial release.

## 0.1.0

- initial line/scatter/histogram SVG plotting.
