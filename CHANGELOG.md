# Changelog

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
