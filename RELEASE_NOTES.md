# luaplotlib 4.22.0

This release adds five Cartesian renderer/API features. Existing Cartesian
defaults are preserved, polar rendering is unchanged, and there are no new
runtime dependencies.

- **Fractional reference spans.** `fig:axhline(y, { xmin = ..., xmax = ... })`
  and `fig:axvline(x, { ymin = ..., ymax = ... })` clip a reference line to
  axes fractions in `[0, 1]`. The endpoints default to the full axes and must
  be ordered. SVG groups expose `data-xmin`/`data-xmax` or
  `data-ymin`/`data-ymax`, and `to_scene()` carries the data coordinate plus
  the resolved fractions.
- **Independent grid styling.** `fig:grid` adds `alpha` and `minor_color`,
  `minor_linewidth`, `minor_linestyle`, and `minor_alpha`. Minor lines inherit
  the major color, width, and dash by default, so existing grids keep their
  appearance. Scene export includes resolved `grid_style` and
  `minor_grid_style` objects.
- **Masked fill bands.** `fig:fill_between` and `fig:fill_betweenx` accept a
  boolean `where` mask and `interpolate`. Each contiguous true run becomes a
  polygon; interpolation adds midpoint edges at mask transitions. Hidden
  samples are excluded from automatic ranging. Masked groups expose segment
  metadata, and scene export includes the mask and resolved segments.
- **Horizontal histograms.** `fig:hist(values, { orientation = "horizontal" })`
  draws counts along x and bin edges along y while sharing the existing bin,
  density, and cumulative calculations. The SVG group reports its orientation
  and the scene swaps the automatic axis ranges accordingly.
- **Styled stems.** `fig:stem` adds `base`, `marker`, and `linestyle`. Stems can
  grow from any finite baseline, use any supported marker (or none), and hide
  their lines independently. The base participates in automatic ranging and
  scene export.

Examples: `examples/cartesian_controls.lua` combines fractional reference
spans, a three-run masked fill band, and independent major/minor grid styling.
`examples/histogram_horizontal.lua` demonstrates horizontal bins, and
`examples/stem.lua` shows a non-zero base with diamond markers and dashed
stems. `make examples` and `scripts/visual-qa.sh` exercise all five features,
including structural checks for the new metadata and rasterization with
`rsvg-convert` when available.

Tests: `./scripts/test.sh` runs 293 dependency-free tests, all passing.
