# luaplotlib 4.13.0

- polar legends now choose a frame position that avoids theta and radial tick
  labels, support `loc = "best"`, and expose their resolved geometry as
  `data-x`/`data-y`/`data-width`/`data-height`;
- `fig:polar_errorbar` draws radial error bars and optional angular errors with
  configurable caps, colors, line styles, and markers;
- `fig:polar_annotate` adds text and leader arrows at `(theta, r)` positions;
  `fig:annotate` dispatches automatically on polar figures;
- polar scene export includes error-bar series, annotations, resolved legend
  entries, and `r_ticks` fractions; mixed Cartesian/polar exports fail loudly;
- new `examples/polar_annotations.lua` and expanded API/README documentation;
- 165 tests.
