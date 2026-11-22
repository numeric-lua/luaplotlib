# luaplotlib 4.19.0

- polar streamplot arrows are now anchored by arc length rather than by point
  index. The new `arrow_fraction` option (default `0.5`, constrained to
  [0.05, 0.95]) selects the fraction of the integrated polyline that carries
  the glyph, so uneven RK spacing, boundary fallbacks, and trimmed tails cannot
  pull it away from the requested position. `arrows = false` and `head = 0`
  still remove it;
- `polar_streamplot` accepts `linestyle = "solid" | "dashed" | "dotted" |
  "none"`. Dashed and dotted paths get matching `stroke-dasharray` values,
  `"none"` hides the path while keeping the directional arrows, and the polar
  legend swatch follows the same dash pattern;
- closed-orbit seeding was redrawing the same loop from every angular seed
  column because only the seed bin was tested. A candidate line that now falls
  more than 50% into already-covered occupancy bins is dropped before it
  consumes the point budget. Every distinct orbit is kept, while the bundled
  streamplot examples shrink from 15 to 12 and 13 to 9 lines; integration,
  deterministic ordering, and the line/point/arrow caps are unchanged;
- SVG metadata now mirrors the scene export. The series adds `data-linestyle`,
  `data-arrow-fraction`, `data-closed-lines`, and
  `data-arc-length-unit="data_radius_units"`. Each `polar-streamline` group
  reports `data-closed`, `data-seed-theta`, `data-seed-r`, and
  `data-arc-length`, and each `polar-stream-arrow` polygon reports
  `data-fraction` in addition to its anchor `data-index`, `data-angle`,
  `data-theta`, and `data-r`;
- `to_scene()` exports `arrow_fraction`, `closed_line_count`,
  `arc_length_unit = "data_radius_units"`, per-line `closed`, `seed_theta`,
  `seed_r`, and `arc_length`, and per-arrow `index` and `fraction` alongside
  the existing point arrays and angle anchors. Rendering and scene export use
  the same deterministic build, so their line, point, arrow, and closed counts
  agree;
- `examples/polar_streamplot.lua` writes a second output,
  `examples/output/polar-streamplot-styles.svg`, showing a dashed field with
  `arrow_fraction = 0.65`. README and API docs describe the new options and
  metadata, `scripts/visual-qa.sh` validates both examples for line-style,
  arc-length, seed, closed-orbit, and arrow-anchor integrity, and Cartesian
  isolation tests cover the new options. The suite has 239 dependency-free
  tests; there are no Cartesian rendering changes and no new runtime
  dependencies.
