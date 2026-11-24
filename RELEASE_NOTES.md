# luaplotlib 4.25.0

This release adds five additive Cartesian renderer/API features. Existing
Cartesian APIs remain compatible, polar rendering is unchanged, and there are
no new runtime dependencies. The boxplot lower-whisker correction is the only
intentional visual change to an existing chart.

- **Configurable minor ticks.** `fig:minorticks(true, { subdivisions = n })`
  splits each linear major interval into 2–10 parts (five by default), and the
  minor grid follows the same count. Log axes keep their 2–9 mantissa ticks.
  SVG roots and scenes expose the resolved subdivision count.
- **Eventplot layouts.** `fig:eventplot` gains `orientation`, `lineoffsets`, and
  `linelengths`. Event rows can be vertical or horizontal, lanes can sit at
  arbitrary offsets, and each row can have its own span. Eventplot scenes now
  export the rows, orientation, offsets, and lengths.
- **Histogram step styles.** `fig:hist` accepts `histtype = "bar"`, `"step"`,
  or `"stepfilled"`. Step histograms draw one stepped outline; stepfilled
  histograms fill the same staircase. Both work with horizontal orientation,
  density, cumulative counts, alpha, and scene export.
- **Horizontal boxplots.** `fig:boxplot` accepts
  `orientation = "horizontal"`, placing categories on y and measurements on x.
  The shared 1.5×IQR calculation now makes the lower whisker reach the lowest
  inlier instead of stopping at Q1.
- **Image colorbars.** `fig:imshow` accepts `colorbar_label`,
  `colorbar_ticks`, and `colorbar_tick_values` within `vmin`/`vmax`. Supplying
  any of these selects the shared ticked colorbar with per-tick metadata and a
  title; the compact legacy bar remains the default.

Examples: `examples/minor_subdivisions.lua`, `examples/eventplot_layout.lua`,
`examples/hist_styles.lua`, `examples/boxplot_horizontal.lua`, and
`examples/imshow_colorbar.lua`. `make examples` and `scripts/visual-qa.sh`
exercise all five features, including minor subdivision and lane metadata,
histogram outline geometry, horizontal category labels, and explicit image
colorbar ticks, then rasterize the new examples when `rsvg-convert` is
available.

Tests: `./scripts/test.sh` runs 356 dependency-free tests, all passing.
