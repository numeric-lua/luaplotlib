# luaplotlib 4.15.0

- `fig:polar_contour` projects marching-squares isolines over the polar frame.
  It accepts automatic or explicit `levels`, color/linewidth/linestyle/alpha,
  optional level labels, `rmin`/`rmax` and `theta_min`/`theta_max` (with degrees
  input), extends the automatic radial limit, joins polar legends, and exports
  `polar.contours` for non-SVG backends;
- polar heatmaps accept `colorbar = true` with `colorbar_label` and
  `colorbar_ticks`; the renderer reserves a canvas column, draws a vertical
  stepped bar with compact tick labels, keeps the legend out of that column,
  and exports `polar.colorbar`;
- polar polish: the outer radial tick is clamped inside the frame, heatmap
  legend swatches are stepped gradients with `vmin`/`vmax` in the scene,
  colorbar labels use three significant digits, and contour labels choose the
  farthest segment and stay inside the circular clip;
- new `examples/polar_contour.lua`, `make examples` and visual-QA coverage,
  expanded API/README documentation, and 203 tests.
