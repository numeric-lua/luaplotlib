# luaplotlib 4.18.0

- new `fig:polar_streamplot(theta, r, u, v, opts)` integrates a grid-sampled
  polar vector field into streamlines. `theta` and `r` are strictly increasing
  coordinate arrays, while `u` and `v` are rows-by-columns matrices holding the
  local tangential and radial components at every grid node. The field is
  bilinearly interpolated and integrated in the physical plane with fixed-step
  fourth-order Runge-Kutta, so a step is isotropic even when the angular and
  radial grid spacings differ;
- a theta grid spanning one full turn is periodic: streamlines wrap
  continuously across theta=0 instead of drawing a chord, and closed orbits are
  detected when a line returns to its seed. Partial sectors stop at their theta
  edges, the radial grid bounds, zero-magnitude samples, or `max_steps`.
  `theta_zero` and `theta_direction` rotate the flow with the axes;
- seeding is deterministic and scaled by `density`, with coarse occupancy bins
  that suppress streamlines retracing earlier coverage. The automatic `step` is
  radial span / 25; `max_steps` (300), `max_lines` (64), and `max_points`
  (8000) bound SVG size, and `data-truncated` reports whether a cap was hit.
  Each line carries a mid-line arrow that can be disabled with
  `arrows = false` or resized with `head`;
- the series group reports `data-cols`, `data-rows`, `data-lines`,
  `data-points`, `data-arrow-count`, `data-step`, `data-step-mode`,
  `data-density`, cap values, `data-periodic`, and `data-truncated`. Every
  `polar-streamline` group reports `data-points`/`data-arrows`, and arrow
  polygons carry `data-angle`, `data-theta`, and `data-r`;
- labelled streamplots join the polar legend with a curved swatch.
  `to_scene()` exports `kind = "streamplot"` series with copied `u`/`v`
  matrices, grid coordinates, `components = "tangential_radial"`, periodic and
  resolved-step metadata, caps, and a `lines` array of `theta`/`r` point
  arrays plus arrow anchors;
- new `examples/polar_streamplot.lua`, expanded README and API documentation,
  `scripts/visual-qa.sh` checks for line/path/arrow/point-count agreement, and
  Cartesian isolation regressions that pin Cartesian SVG output, Cartesian
  scene shape, quiver scene metadata, and per-figure palette behavior. The
  suite now has 236 dependency-free tests; there are no Cartesian rendering or
  runtime dependency changes.
