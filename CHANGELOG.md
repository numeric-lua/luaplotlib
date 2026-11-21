# Changelog

## 4.14.0

- `fig:polar_heatmap` (alias `fig:polar_pcolormesh`) projects a rows-by-columns
  matrix into annular/sector cells with `vmin`/`vmax`, `rmin`/`rmax`,
  `theta_min`/`theta_max`, alpha, labels, degree input, legend entries, and
  `polar.heatmaps` scene export;
- polar annotation targets now extend the automatic radial limit, while an
  explicit `rmax` rejects out-of-range targets; annotation text is clamped to
  the canvas (`data-clip`/`data-clamped` metadata) and its leader arrow
  follows;
- measured UTF-8-aware Helvetica/Arial text metrics size polar legend columns,
  titles, and frames; wide and narrow glyphs now receive different widths and
  `data-text-width` exposes the measured label width;
- polar radial tick labels render above series with a white contrast halo, so
  filled bars and heatmaps no longer hide them;
- new `examples/polar_heatmap.lua` and optional `scripts/visual-qa.sh`
  rasterization check; expanded API/README documentation and 188 tests.

## 4.13.0

- label-aware polar legend placement that avoids theta and radial tick labels,
  with `loc = "best"` and `data-*` geometry on the legend group;
- `fig:polar_errorbar` for radial and angular uncertainty, including caps,
  line/marker styling, automatic rmax coverage, and scene export;
- `fig:polar_annotate` at `(theta, r)` coordinates, with polar dispatch from
  `fig:annotate`, leader arrows, and degrees input;
- polar scene export for error-bar series, annotations, legend entries, and
  radius fractions, with mixed-content export guards;
- new `polar_annotations` example, API docs, README updates, and 165 tests.

## 4.12.0

- polar axes (`plt.polar` / `fig:polar`) with circular grid and theta/r ticks;
- polar scatter with per-point markers, sizes, colors, and legend support;
- polar bar wedges with scalar or per-bar widths and per-bar colors;
- `fig:polar_config` for zero location, direction, radial limits, and custom
  angular/radial grids;
- degrees input (`degrees = true` / `theta_unit = "degrees"`) for polar series;
- polar scene export and subplot composition;
- 149 tests.

## 4.11.0

- bar `hatch` patterns (`/`, `\`, `|`, `-`, `+`, `x`, `.`, `o`);
- generated SVG pattern definitions and validation;
- 131 tests.

## 4.10.0

- contour level labels and linestyles;
- tests for labels, dashes, and invalid styles;
- 130 tests.

## 4.9.0

- `eventplot` raster series;
- `ecdf` empirical CDF step curve;
- tests for both;
- 129 tests.

## 4.8.0

- subplot `savefig` format dispatch and unknown-extension errors;
- `Axes3D:to_scene()` for renderer-agnostic 3-D scene export;
- tests for subplot dispatch and 3-D scene contents;
- 128 tests.

## 4.7.0

- `axhspan` / `axvspan` shaded data bands;
- `loglog`, `semilogx`, and `semilogy` convenience wrappers;
- 126 tests.

## 4.6.0

- per-point scatter radii and fill colors;
- histogram `density` and `cumulative` options;
- legend `ncol` and `title`;
- square/triangle/diamond/cross/x markers for line and scatter series;
- 3-D `savefig` SVG/PNG/PDF dispatch;
- 125 tests.

## 4.5.0

- fixed 3-D automatic bounds producing NaN coordinates;
- corrected 1-D surface x/y mapping and validation;
- format-aware `savefig` for `.svg`, `.png`, and `.pdf`;
- axis-specific grid lines;
- `axhline` / `axvline` reference lines;
- refreshed API/README docs; 120 tests.

## 4.4.0

- optional PNG/PDF export through the system `rsvg-convert`;
- 117 tests.

## 4.3.0

- 3-D surface/mesh wireframes;
- 116 tests.

## 4.2.0

- 3-D axis ticks, x/y/z labels, view control, explicit limits, and depth-sorted series;
- 115 tests.

## 4.1.0

- true 3-D axes (`plt.figure3d`) with orthographic box projection, line/scatter, title, and axis labels;
- 114 tests.

## 4.0.0

- gridspec-style width/height ratios for subplots;
- 113 tests.

## 3.0.0

- basic projected 3-D line/scatter (`plot3`, `scatter3`);
- 112 tests.

## 2.2.0

- automatic shared x/y limits in subplots (`sharex`, `sharey`);
- 111 tests.

## 2.1.0

- subplot-level grid/facecolor propagation and first-axes plot/scatter delegates;
- 110 tests.

## 2.0.0

- configurable grid color/width/linestyle;
- figure facecolor and ARIA labels;
- 109 tests.

## 1.5.0

- `contourf` filled contours with optional overlay lines;
- 108 tests.

## 1.4.0

- `fill_betweenx` horizontal bands and `pcolormesh` heatmap alias;
- 107 tests.

## 1.3.0

- `fill_between`, `step`, `stem`, and `stackplot`;
- scene export for the new series;
- 106 tests.

## 1.2.0

- secondary x axis via `fig:twiny()` with top ticks, label, and independent
  limits/scale;
- twiny line/scatter/error-bar series and scene metadata;
- 104 tests.

## 1.1.0

- pie and donut charts with labels, colors, percentages, start angle, radius,
  inner radius, and optional legend;
- pie scene export;
- 103 tests.

## 1.0.0

- scene export parity for image, box, contour, barh, and twin-axis series;
- documented API stability and semantic-versioning policy;
- 99 tests.

## 0.9.0

- secondary y axis via `fig:twinx()`;
- twin line/scatter/error-bar/bar series with independent y limits, scale, and
  label;
- right-side ticks and title integrated into layout;
- 97 tests.

## 0.8.0

- calendar-date x-axis labels via `xdate`;
- standalone HTML export with `to_html`/`save_html`;
- `imshow` accepts 2-D tensor-like matrices;
- 95 tests.

## 0.7.0

- horizontal bar charts (`barh`) with category labels, per-bar colors, options,
  and value labels;
- 91 tests.

## 0.6.0

- per-bar colors for single-series bar charts;
- optional value labels on bars;
- 89 tests.

## 0.5.0

- custom `xticks`/`yticks` with optional labels;
- `xtick_format`/`ytick_format` callbacks for generated and custom ticks;
- 87 tests.

## 0.4.0

- `plt.subplots(rows, cols)` grid figures with configurable gap/margin, parent
  title, per-axes figures, and `share_limits`;
- `imshow` heatmaps with a viridis-like colorbar;
- boxplots with quartiles, whiskers, caps, and outliers;
- marching-squares contour lines;
- `xtick_rotation` for crowded categorical axes;
- 85 tests.

## 0.3.0

- logarithmic x/y axes with decade ticks and positive-value validation;
- annotations with optional leader arrows;
- stacked and grouped bar charts;
- renderer-agnostic scene export (`figure:to_scene()`);
- 76 tests.

## 0.2.0

- error-bar plots, CI, and initial release.

## 0.1.0

- initial line/scatter/histogram SVG plotting.
