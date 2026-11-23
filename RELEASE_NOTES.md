# luaplotlib 4.24.0

This release adds five additive Cartesian renderer/API features. Existing
Cartesian defaults are preserved, polar rendering is unchanged, and there are
no new runtime dependencies.

- **Rectangular 2-D histograms.** `fig:hist2d(x, y, opts)` counts paired
  samples into `bins = n` or `{ nx, ny }`, supports an explicit
  `{ xmin, xmax, ymin, ymax }` range and density normalization, and colors
  non-empty cells with the shared heat palette. Colorbars accept a title,
  uniform tick counts, or explicit tick values. Groups and scene export carry
  grids, edges, point/inside counts, per-cell counts/values, and norm metadata.
- **Numeric scatter colors.** `fig:scatter` accepts `c`, `vmin`/`vmax`, and
  colorbar options. Values map through the heat palette, a vertical colorbar is
  enabled by default, and per-point colors plus the original numeric values are
  available in scene export. `c` and `color` are mutually exclusive.
- **Violin distributions.** `fig:violinplot(samples, opts)` draws normalized
  Gaussian-kernel bodies with Silverman or explicit bandwidth, configurable
  positions/width/KDE resolution, per-sample colors, and independent extrema,
  median, and quartile marks. Scene export preserves sorted samples, densities,
  polygon geometry, and summary statistics.
- **Stackplot baselines.** `fig:stackplot` adds `baseline = "zero"`, `"sym"`,
  and `"wiggle"`. Stack layers retain their thickness and existing `y1`/`y2`
  geometry; SVG and scene export add baseline/index/shift metadata.
- **Bar error bars.** `fig:bar` adds `yerr`, `ecolor`, `elinewidth`, and
  `capsize` for symmetric or asymmetric errors on single, grouped, and stacked
  bars. Error extents participate in automatic ranging, and scene export
  preserves both lower/upper arrays and styling.

Examples: `examples/hist2d.lua`, `examples/scatter_colors.lua`,
`examples/violinplot.lua`, `examples/stack_baseline.lua`, and
`examples/bar_errors.lua`. `make examples` and `scripts/visual-qa.sh` exercise
all five features, including cell/count consistency, mapped scatter colors,
violin marks, stack baseline metadata, and bar error/cap counts, then rasterize
the new examples when `rsvg-convert` is available.

Tests: `./scripts/test.sh` runs 335 dependency-free tests, all passing.
