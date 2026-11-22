# luaplotlib 4.16.0

- polar contour labels rotate along the local tangent and stay upright. Label
  placement searches every marching-squares segment and avoids earlier labels,
  radial tick text, annotations, and the legend; text is clamped inside the
  circular clip and a level is skipped rather than overlapped when no clear
  anchor exists. SVG labels expose `data-level`/`data-angle`, and contour scene
  levels carry a preferred `label` anchor for non-SVG backends;
- polar heatmap colorbars accept `colorbar_tick_values`, an explicit array of
  2-12 strictly increasing values within `vmin`/`vmax` (mutually exclusive with
  `colorbar_ticks`). This makes "nice" ticks such as `{ -1, -0.5, 0, 0.5, 1 }`
  possible instead of an even split of an arbitrary range. SVG ticks and labels
  expose `data-value`/`data-fraction` plus `data-tick-source`, and
  `to_scene()` adds `tick_labels`, `tick_fractions`, and `tick_source` while
  keeping the existing numeric `ticks` array;
- `examples/polar_heatmap.lua` now demonstrates a colorbar with explicit nice
  ticks, and `examples/polar_contour.lua` uses explicit colorbar ticks;
  `scripts/visual-qa.sh` additionally checks rotated contour labels, colorbar
  label metadata, and that Cartesian examples remain Cartesian;
- expanded README/API documentation, 208 tests, and no Cartesian rendering or
  scene changes.
