# luaplotlib 4.26.0

This release adds five additive Cartesian renderer/API features. Existing
Cartesian APIs remain compatible, polar rendering is unchanged, and there are
no new runtime dependencies.

- **Per-row event colors.** `fig:eventplot` accepts `colors`, one stroke color
  per lane. The first color seeds the legend swatch and the scene exports the
  optional color array.
- **Boxplot means.** `fig:boxplot` gains `showmeans` and `meanline`. Means can
  be drawn as a marker or as a dashed line across the box, and the scene
  exports the calculated mean plus both display flags.
- **Violin means.** `fig:violinplot` gains the same `showmeans`/`meanline`
  controls, with `violin-mean-marker` and `violin-mean-line` output and scene
  metadata.
- **Bar outline widths.** `fig:bar` and `fig:barh` accept `linewidth`. The
  default remains one pixel, and grouped/stacked series in a call share the
  requested outline width.
- **Image alpha.** `fig:imshow` accepts `alpha` in [0, 1]. Cells are rendered
  translucent, the group reports `data-alpha`, and the colorbar stays opaque.

Examples: updated `examples/eventplot_layout.lua`,
`examples/boxplot_horizontal.lua`, `examples/violinplot.lua`, and
`examples/imshow_colorbar.lua`, plus new `examples/bar_linewidth.lua`.
`make examples` and `scripts/visual-qa.sh` exercise the new row colors, mean
marks, outline width, and cell alpha, then rasterize the affected examples when
`rsvg-convert` is available.

Tests: `./scripts/test.sh` runs 373 dependency-free tests, all passing.
