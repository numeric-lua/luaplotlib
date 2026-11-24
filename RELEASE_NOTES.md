# luaplotlib 4.27.0

This release adds five additive renderer/API features. Existing Cartesian APIs
remain compatible, polar rendering is unchanged, and there are no new runtime
dependencies.

- **Broken horizontal bars.** New `fig:broken_barh(xranges, yrange, opts)`
  draws Gantt-style `{start, width}` intervals at one `{y, height}` band, with
  automatic ranging, legend support, SVG range metadata, and scene export.
- **Event lane labels.** `fig:eventplot` accepts `labels`, one tick label per
  lane. Horizontal lanes label x; vertical lanes label y, using the lane
  offsets as category positions. Scenes export the labels and category axis.
- **Exploded pies and shadows.** `fig:pie`/`fig:donut` accept `explode` (one
  offset or one per slice, up to half the radius) and `shadow`. Shifted slices
  keep their labels, leader lines, and percentage text; scene export carries
  the shadow flag and per-slice offsets.
- **Histogram outline widths.** `fig:hist` accepts `linewidth` for all three
  outline styles (`bar`, `step`, and `stepfilled`), defaulting to one pixel.
- **Title alignment.** `fig:title` accepts `loc = "left"`, `"center"`, or
  `"right"` for Cartesian figures, pies, polar figures, and subplot grids.
  Scenes export `title_align`.

Examples: new `examples/broken_barh.lua` and `examples/pie_explode.lua`, plus
updated eventplot, histogram, and title demonstrations. `make examples` and
`scripts/visual-qa.sh` exercise the new geometry and metadata, then rasterize
the affected examples when `rsvg-convert` is available.

Tests: `./scripts/test.sh` runs 391 dependency-free tests, all passing.
