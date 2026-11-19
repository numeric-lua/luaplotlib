# Changelog

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
