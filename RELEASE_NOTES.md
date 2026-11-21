# luaplotlib 4.14.0

- `fig:polar_heatmap` / `fig:polar_pcolormesh` project a value matrix as
  annular or sector cells, with explicit radial and angular ranges, a fixed
  heat palette, legends, and `polar.heatmaps` scene export;
- polar annotation target radii extend the automatic `rmax`; explicit limits
  reject out-of-range targets, and annotation text is shifted back inside the
  canvas when it would leave the viewport;
- polar legends use measured UTF-8 Helvetica/Arial advance widths for columns,
  titles, and frames, and expose `data-text-width`;
- radial tick labels draw above bars and heatmaps with a white contrast halo;
- new `examples/polar_heatmap.lua`, optional `scripts/visual-qa.sh`, expanded
  API/README documentation, and 188 tests.
