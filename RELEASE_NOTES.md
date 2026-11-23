# luaplotlib 4.23.0

This release adds five Cartesian renderer/API features. Existing Cartesian
defaults are preserved, polar rendering is unchanged, and there are no new
runtime dependencies.

- **Cartesian quiver.** `fig:quiver(x, y, u, v, opts)` projects data-coordinate
  vector components through the current axes and draws capped arrow glyphs.
  `scale` is automatic unless supplied, `normalize`, `pivot`, `head`, and
  `linewidth` control the glyphs, and `max_arrows` decimates large fields
  deterministically. Groups expose count/drawn/stride/scale/pivot metadata and
  each arrow carries its magnitude, position, and angle; scene export includes
  the component arrays and resolved scaling.
- **Hexagonal binning.** `fig:hexbin(x, y, opts)` groups samples into regular
  pointy-top hexagons, filters with `mincnt`, maps counts through the shared heat
  palette, and optionally adds a labeled count colorbar with uniform or explicit
  ticks. Cells and scene export carry counts, row/column indices, values, and
  geometry.
- **Image extents and origins.** `fig:imshow` (also `pcolormesh`/`pcolor`) accepts
  `extent = { left, right, bottom, top }` and `origin = "upper" | "lower"`.
  Extents participate in automatic ranging, explicit output carries
  `data-extent`/`data-origin` plus per-cell row/column metadata, and scene export
  preserves both. Default index geometry is unchanged.
- **Contour coordinate grids.** `fig:contour` accepts `x` and `y` coordinate
  vectors matching the matrix columns and rows. Marching-squares intersections,
  labels, automatic ranging, and scene export use the supplied coordinates; the
  default index grid remains compatible.
- **Aspect ratios.** `fig:aspect("equal")`, `fig:aspect(number)`, and
  `fig:aspect("auto")` constrain, set, or clear the plot-box ratio. The box
  shrinks and centers inside the normal label margins and reports
  `data-aspect`/`data-plot-width`/`data-plot-height`; scene export adds `aspect`,
  `aspect_mode`, and `aspect_adjustable`. Unconstrained figures render as before.

Examples: `examples/quiver.lua` draws a rotation field with a middle pivot and
legend swatch, `examples/hexbin.lua` renders clustered samples with a labeled
count colorbar, `examples/field_coordinates.lua` writes both the extent/origin
heatmap and a coordinate-aware Gaussian contour, and `examples/aspect.lua` shows
a genuinely round unit circle. `make examples` and `scripts/visual-qa.sh`
exercise all five features, including structural checks for arrow counts,
hexbin cells/colorbar labels, image extents, contour coordinates, and a square
equal-aspect box, then rasterize the new examples when `rsvg-convert` is
available.

Tests: `./scripts/test.sh` runs 312 dependency-free tests, all passing.
