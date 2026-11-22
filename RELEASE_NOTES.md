# luaplotlib 4.17.0

- new `fig:polar_quiver(theta, r, u, v, opts)` draws a polar vector field.
  `u` is the local tangential component toward increasing data theta and `v`
  is the radial component; both are rotated by the configured
  `theta_zero`/`theta_direction`, so clockwise axes flip tangential arrows
  while radial arrows keep pointing outward. Arrows are clipped to the polar
  circle and draw in series order above heatmaps and contours;
- glyph lengths use SVG user units rather than data units. `scale` sets user
  units per unit magnitude, while the default automatic scale makes the longest
  arrow 18 units; `normalize = true` draws unit-length direction arrows and
  `pivot = "tail" | "middle" | "tip"` chooses where the data point sits in the
  glyph;
- large fields stay bounded: `max_arrows` (default 512, maximum 4096) selects
  indices 1, 1+stride, ... with `stride = ceil(count / max_arrows)`, zero
  vectors are skipped, and `data-count`, `data-drawn`, `data-stride`,
  `data-max-arrows`, `data-scale`, `data-scale-mode`, `data-pivot`, and
  `data-normalize` make the result inspectable. Every arrow group also exposes
  `data-index`, `data-magnitude`, `data-theta`, `data-r`, and `data-angle`;
- labelled quivers get an arrow legend swatch, and `to_scene()` exports
  `kind = "quiver"` series with copied `u`/`v` arrays,
  `components = "tangential_radial"`, `auto_scale`/`resolved_scale`,
  `scale_unit = "svg_user_units_per_magnitude"`, `pivot`, `normalize`,
  `max_arrows`, `stride`, and `drawn`;
- new `examples/polar_quiver.lua`, expanded README/API documentation, and
  `scripts/visual-qa.sh` checks for arrow counts, cap compliance, and direction
  metadata; 219 dependency-free tests and no Cartesian rendering or dependency
  changes.
