# luaplotlib 4.21.0

This release adds five Cartesian renderer/API features. Cartesian behavior is
additive, polar rendering is unchanged, and there are no new runtime
dependencies.

- **Asymmetric error bars.** `fig:errorbar` accepts independent lower and upper
  errors as `{ lower = ..., upper = ... }` or `{ lower_sequence,
  upper_sequence }` for either `yerr` or `xerr`. Scalar and flat-array inputs
  remain symmetric. Geometry and automatic ranging use both extents; SVG groups
  report `data-yerr-mode` / `data-xerr-mode`, and `to_scene()` adds
  `yerr_lower`, `yerr_upper`, `xerr_lower`, `xerr_upper`, and asymmetric flags
  while retaining the legacy upper-side arrays.
- **Clipped `axline`.** `fig:axline(x1, y1, x2, y2, opts)` draws the infinite
  line through two distinct points, clipped to the axes rectangle. The defining
  anchors drive automatic ranging, the SVG group exposes them plus
  `data-clipped`, and the same anchors are exported by `to_scene()`.
- **Marker decimation.** `fig:plot(..., { markevery = n })` draws every Nth
  marker; an index table selects explicit one-based points. The line keeps all
  vertices. Line groups expose `data-marker-count`/`data-markevery`, and scene
  styles carry the normalized index list.
- **Y tick rotation.** `fig:ytick_rotation(angle)` mirrors `xtick_rotation`,
  pivots labels around the existing right-aligned anchor, also applies to twin
  y-axis labels, and is exported as `ytick_rotation` in the scene.
- **Minor ticks and minor grid.** `fig:minorticks([enabled[, opts]])` draws
  minor marks on `"x"`, `"y"`, or `"both"`. Linear intervals split into five
  parts; log axes use the 2–9 mantissas per decade, never duplicating majors.
  `fig:grid(true, { minor = true })` adds the fainter minor grid independently.
  SVG roots expose `data-minorticks`/`data-minor-grid`, and the scene reports
  the same settings.

Examples: `examples/line.lua` demonstrates `markevery` plus minor ticks/grid,
`examples/errorbar.lua` uses asymmetric errors, and the new
`examples/axline.lua` covers clipped reference lines and y tick rotation.
`make examples` and `scripts/visual-qa.sh` exercise all three, including
structural checks for the new metadata and rasterization with `rsvg-convert`
when available.

Tests: `./scripts/test.sh` runs 267 dependency-free tests, all passing.
