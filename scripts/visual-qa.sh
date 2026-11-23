#!/usr/bin/env bash
# Render the examples, inspect polar and Cartesian output structurally, then
# rasterize the SVGs for manual visual inspection when rsvg-convert is
# available. This is a developer QA helper, not part of the dependency-free
# test suite.
set -euo pipefail

cd "$(dirname "$0")/.."

LUA_BIN="${LUA:-luajit}"
if ! command -v "$LUA_BIN" >/dev/null 2>&1; then
  echo "error: Lua interpreter not found: $LUA_BIN" >&2
  echo "set LUA=/path/to/luajit if it is installed under another name" >&2
  exit 127
fi

fail() {
  echo "error: $*" >&2
  exit 1
}

make examples

POLAR_SVGS=(
  examples/output/polar.svg
  examples/output/polar-bars.svg
  examples/output/polar-annotations.svg
  examples/output/polar-heatmap.svg
  examples/output/polar-contour.svg
  examples/output/polar-quiver.svg
  examples/output/polar-streamplot.svg
  examples/output/polar-streamplot-styles.svg
  examples/output/polar-streamplot-clip.svg
)

for svg in "${POLAR_SVGS[@]}"; do
  [ -s "$svg" ] || fail "missing example output: $svg"
  grep -q 'data-polar="true"' "$svg" || fail "$svg is not a polar SVG"
done

# The contour example must keep its projected lines, colorbar, rotated labels,
# and explicit "nice" colorbar ticks.
CONTOUR=examples/output/polar-contour.svg
grep -q 'class="series series-polar-contour"' "$CONTOUR" ||
  fail "$CONTOUR has no contour series"
grep -q 'class="polar-colorbar"' "$CONTOUR" ||
  fail "$CONTOUR has no colorbar"
grep -q 'data-tick-source="explicit"' "$CONTOUR" ||
  fail "$CONTOUR should use explicit colorbar ticks"

label_count=$(grep -o 'class="polar-contour-label"' "$CONTOUR" | wc -l | tr -d ' ')
rotated_count=$(grep -o \
  'class="polar-contour-label"[^>]*transform="rotate([^"]*)"' "$CONTOUR" |
  wc -l | tr -d ' ')
[ "$label_count" -gt 0 ] || fail "$CONTOUR has no contour labels"
[ "$rotated_count" -eq "$label_count" ] ||
  fail "$CONTOUR has $label_count contour labels but only $rotated_count are rotated"

level_count=$(grep -o 'data-levels="[0-9]*"' "$CONTOUR" | head -1 |
  tr -dc '0-9')
[ -n "$level_count" ] || fail "$CONTOUR has no contour level count"
[ "$label_count" -le "$level_count" ] ||
  fail "$CONTOUR has more labels than levels"

# Every colorbar label should carry the exact tick value it annotates.
for svg in examples/output/polar-heatmap.svg "$CONTOUR"; do
  tick_count=$(grep -o 'data-ticks="[0-9]*"' "$svg" | head -1 |
    tr -dc '0-9')
  [ -n "$tick_count" ] || fail "$svg has no colorbar tick count"
  bar_labels=$(grep -o 'class="colorbar-label"' "$svg" | wc -l | tr -d ' ')
  [ "$bar_labels" -eq "$tick_count" ] ||
    fail "$svg has $tick_count colorbar ticks but $bar_labels labels"
  value_labels=$(grep -o 'class="colorbar-label"[^>]*data-value="[^"]*"' \
    "$svg" | wc -l | tr -d ' ')
  [ "$value_labels" -eq "$bar_labels" ] ||
    fail "$svg colorbar labels are missing data-value metadata"
done

# The quiver example must keep one arrow group per drawn vector, each with a
# direction and magnitude, while staying under the configured field cap.
QUIVER=examples/output/polar-quiver.svg
grep -q 'class="series series-polar-quiver"' "$QUIVER" ||
  fail "$QUIVER has no quiver series"
quiver_total=$(grep -o 'data-count="[0-9]*"' "$QUIVER" | head -1 | tr -dc '0-9')
quiver_drawn=$(grep -o 'data-drawn="[0-9]*"' "$QUIVER" | head -1 | tr -dc '0-9')
quiver_max=$(grep -o 'data-max-arrows="[0-9]*"' "$QUIVER" | head -1 |
  tr -dc '0-9')
[ -n "$quiver_total" ] && [ -n "$quiver_drawn" ] && [ -n "$quiver_max" ] ||
  fail "$QUIVER is missing quiver count metadata"
quiver_arrows=$(grep -o 'class="polar-quiver-arrow"' "$QUIVER" |
  wc -l | tr -d ' ')
[ "$quiver_arrows" -eq "$quiver_drawn" ] ||
  fail "$QUIVER has $quiver_drawn drawn vectors but $quiver_arrows arrow groups"
[ "$quiver_drawn" -le "$quiver_total" ] ||
  fail "$QUIVER drew more arrows than its input"
[ "$quiver_drawn" -le "$quiver_max" ] ||
  fail "$QUIVER exceeded the configured max_arrows cap"
for part in shaft head; do
  part_count=$(grep -o "class=\"polar-quiver-$part\"" "$QUIVER" |
    wc -l | tr -d ' ')
  [ "$part_count" -eq "$quiver_drawn" ] ||
    fail "$QUIVER has $quiver_drawn arrows but $part_count $part parts"
done
angled=$(grep -o 'class="polar-quiver-arrow"[^>]*data-angle="[^"]*"' \
  "$QUIVER" | wc -l | tr -d ' ')
[ "$angled" -eq "$quiver_drawn" ] ||
  fail "$QUIVER arrow groups are missing data-angle metadata"
grep -q 'class="polar-legend"' "$QUIVER" ||
  fail "$QUIVER has no polar legend"

# Streamplot examples must keep their integrated line groups, stay inside the
# configured caps, and expose arc-length, seed, closed-orbit, arrow-anchor, and
# polar-circle clipping metadata.  Every example covers a full turn, so the
# series must be periodic and none should hit an integration cap.
STREAM=examples/output/polar-streamplot.svg
STREAM_STYLES=examples/output/polar-streamplot-styles.svg
STREAM_CLIP=examples/output/polar-streamplot-clip.svg

# Every streamline and arrow vertex must lie inside the frame circle.  The
# renderer projects clipped arrow triangles back onto the circle, so exported
# coordinates stay inside even when the glyph would have crossed the frame.
check_streamplot_geometry() {
  local svg="$1" cx cy radius
  local polar_line
  polar_line=$(grep -m1 'class="polar" ' "$svg" || true)
  cx=$(printf '%s\n' "$polar_line" |
    sed -n 's/.*data-cx="\([^"]*\)".*/\1/p')
  cy=$(printf '%s\n' "$polar_line" |
    sed -n 's/.*data-cy="\([^"]*\)".*/\1/p')
  radius=$(printf '%s\n' "$polar_line" |
    sed -n 's/.*data-radius="\([^"]*\)".*/\1/p')
  [ -n "$cx" ] && [ -n "$cy" ] && [ -n "$radius" ] ||
    fail "$svg is missing polar clip geometry"

  grep -E 'class="polar-streamline-path"|class="polar-stream-arrow"' "$svg" |
    awk -v cx="$cx" -v cy="$cy" -v radius="$radius" '
      function checkpair(x, y,   dx, dy) {
        dx = x - cx
        dy = y - cy
        if (dx * dx + dy * dy > (radius + 0.002) * (radius + 0.002)) {
          bad = 1
        }
      }
      /class="polar-streamline-path"/ {
        if (match($0, / d="[^"]*"/)) {
          d = substr($0, RSTART + 4, RLENGTH - 5)
          count = split(d, token, " ")
          for (i = 2; i + 1 <= count; i += 3) {
            checkpair(token[i] + 0, token[i + 1] + 0)
          }
        }
      }
      /class="polar-stream-arrow"/ {
        if (match($0, / points="[^"]*"/)) {
          points = substr($0, RSTART + 9, RLENGTH - 10)
          count = split(points, vertex, " ")
          for (i = 1; i <= count; i++) {
            split(vertex[i], xy, ",")
            checkpair(xy[1] + 0, xy[2] + 0)
          }
        }
      }
      END { exit bad }
    ' || fail "$svg has streamplot geometry outside the polar circle"
}

check_streamplot() {
  local svg="$1" expected_style="$2" expected_fraction="$3"
  local expected_clipped="$4"
  local expected_step_mode="${5:-auto}"
  local stream_lines stream_points stream_max_lines stream_max_points
  local stream_arrows stream_closed stream_closed_attr
  local stream_clipped_attr stream_clipped_drawn
  local line_groups path_count arrow_polygons seed_meta arc_meta

  grep -q 'class="series series-polar-streamplot"' "$svg" ||
    fail "$svg has no streamplot series"
  grep -q 'data-periodic="true"' "$svg" ||
    fail "$svg should use a periodic theta grid"
  grep -q "data-step-mode=\"$expected_step_mode\"" "$svg" ||
    fail "$svg should advertise the $expected_step_mode integration step"
  grep -q "data-linestyle=\"$expected_style\"" "$svg" ||
    fail "$svg should use the $expected_style line style"
  grep -q "data-arrow-fraction=\"$expected_fraction\"" "$svg" ||
    fail "$svg should advertise arrow_fraction = $expected_fraction"
  grep -q 'data-arc-length-unit="data_radius_units"' "$svg" ||
    fail "$svg should advertise arc-length units"
  grep -q 'data-clip="polar-circle"' "$svg" ||
    fail "$svg should advertise its polar-circle clip"

  stream_lines=$(grep -o 'data-lines="[0-9]*"' "$svg" | head -1 |
    tr -dc '0-9')
  stream_points=$(grep -o 'data-points="[0-9]*"' "$svg" | head -1 |
    tr -dc '0-9')
  stream_max_lines=$(grep -o 'data-max-lines="[0-9]*"' "$svg" | head -1 |
    tr -dc '0-9')
  stream_max_points=$(grep -o 'data-max-points="[0-9]*"' "$svg" | head -1 |
    tr -dc '0-9')
  stream_arrows=$(grep -o 'data-arrow-count="[0-9]*"' "$svg" | head -1 |
    tr -dc '0-9')
  stream_closed_attr=$(grep -o 'data-closed-lines="[0-9]*"' "$svg" |
    head -1 | tr -dc '0-9')
  stream_clipped_attr=$(grep -o 'data-clipped-arrow-count="[0-9]*"' "$svg" |
    head -1 | tr -dc '0-9')
  [ -n "$stream_lines" ] && [ -n "$stream_points" ] &&
    [ -n "$stream_max_lines" ] && [ -n "$stream_max_points" ] &&
    [ -n "$stream_arrows" ] && [ -n "$stream_closed_attr" ] &&
    [ -n "$stream_clipped_attr" ] ||
    fail "$svg is missing streamplot metadata"
  [ "$stream_lines" -ge 2 ] || fail "$svg has too few streamlines"
  [ "$stream_lines" -le "$stream_max_lines" ] ||
    fail "$svg exceeded the configured max_lines cap"
  [ "$stream_points" -le "$stream_max_points" ] ||
    fail "$svg exceeded the configured max_points cap"
  grep -q 'data-truncated="false"' "$svg" ||
    fail "$svg example should not hit an integration cap"

  line_groups=$(grep -o 'class="polar-streamline"' "$svg" |
    wc -l | tr -d ' ')
  [ "$line_groups" -eq "$stream_lines" ] ||
    fail "$svg has $stream_lines streamlines but $line_groups line groups"
  path_count=$(grep -o 'class="polar-streamline-path"' "$svg" |
    wc -l | tr -d ' ')
  [ "$path_count" -eq "$stream_lines" ] ||
    fail "$svg has $stream_lines streamlines but $path_count paths"
  arrow_polygons=$(grep -o 'class="polar-stream-arrow"' "$svg" |
    wc -l | tr -d ' ')
  [ "$arrow_polygons" -eq "$stream_arrows" ] ||
    fail "$svg has $stream_arrows arrows but $arrow_polygons polygons"

  sum_points=$(grep -o \
    'class="polar-streamline" data-index="[0-9]*" data-points="[0-9]*"' \
    "$svg" | sed -E 's/.*data-points="([0-9]+)"/\1/' |
    awk '{ total += $1 } END { print total + 0 }')
  [ "$sum_points" -eq "$stream_points" ] ||
    fail "$svg line points sum to $sum_points, expected $stream_points"

  seed_meta=$(grep -o \
    'class="polar-streamline"[^>]*data-seed-theta="[^"]*"[^>]*data-seed-r="[^"]*"' \
    "$svg" | wc -l | tr -d ' ')
  [ "$seed_meta" -eq "$stream_lines" ] ||
    fail "$svg is missing per-line seed metadata"
  arc_meta=$(grep -o \
    'class="polar-streamline"[^>]*data-arc-length="[^"]*"' "$svg" |
    wc -l | tr -d ' ')
  [ "$arc_meta" -eq "$stream_lines" ] ||
    fail "$svg is missing per-line arc-length metadata"
  grep -o 'data-arc-length="[0-9.]*"' "$svg" |
    sed -E 's/.*="([0-9.]+)"/\1/' |
    awk '$1 <= 0 { exit 1 }' ||
    fail "$svg has a non-positive streamline arc length"

  stream_closed=$(grep -o 'data-closed="true"' "$svg" | wc -l |
    tr -d ' ' || true)
  [ "$stream_closed" -eq "$stream_closed_attr" ] ||
    fail "$svg reports $stream_closed_attr closed lines but draws $stream_closed"

  if [ "$expected_clipped" = "positive" ]; then
    [ "$stream_clipped_attr" -gt 0 ] ||
      fail "$svg should report clipped boundary arrow glyphs"
  else
    [ "$stream_clipped_attr" -eq "$expected_clipped" ] ||
      fail "$svg reports $stream_clipped_attr clipped arrows, expected $expected_clipped"
  fi
  stream_clipped_drawn=$(grep -o 'data-clipped="true"' "$svg" | wc -l |
    tr -d ' ' || true)
  [ "$stream_clipped_drawn" -eq "$stream_clipped_attr" ] ||
    fail "$svg reports $stream_clipped_attr clipped arrows but marks $stream_clipped_drawn"
  stream_clipped_lines=$(grep -o \
    'class="polar-streamline"[^>]*data-clipped-arrows="[0-9]*"' "$svg" |
    sed -E 's/.*data-clipped-arrows="([0-9]+)"/\1/' |
    awk '{ total += $1 } END { print total + 0 }')
  [ "$stream_clipped_lines" -eq "$stream_clipped_attr" ] ||
    fail "$svg line clipping counts sum to $stream_clipped_lines, expected $stream_clipped_attr"

  stream_angled=$(grep -o \
    'class="polar-stream-arrow"[^>]*data-angle="[^"]*"' "$svg" |
    wc -l | tr -d ' ')
  [ "$stream_angled" -eq "$stream_arrows" ] ||
    fail "$svg arrows are missing data-angle metadata"
  stream_fractioned=$(grep -o \
    'class="polar-stream-arrow"[^>]*data-fraction="[^"]*"' "$svg" |
    wc -l | tr -d ' ')
  [ "$stream_fractioned" -eq "$stream_arrows" ] ||
    fail "$svg arrows are missing data-fraction metadata"
  stream_clipped_meta=$(grep -o \
    'class="polar-stream-arrow"[^>]*data-clipped="' "$svg" |
    wc -l | tr -d ' ')
  [ "$stream_clipped_meta" -eq "$stream_arrows" ] ||
    fail "$svg arrows are missing data-clipped metadata"

  grep -E 'class="polar-streamline"|class="polar-stream-arrow"' "$svg" |
    awk '
      /class="polar-streamline"/ {
        points = 0
        if (match($0, /data-points="[0-9]+"/)) {
          value = substr($0, RSTART, RLENGTH)
          gsub(/[^0-9]/, "", value)
          points = value + 0
        }
      }
      /class="polar-stream-arrow"/ {
        anchor = -1
        fraction = -1
        if (match($0, /data-index="[0-9]+"/)) {
          value = substr($0, RSTART, RLENGTH)
          gsub(/[^0-9]/, "", value)
          anchor = value + 0
        }
        if (match($0, /data-fraction="[0-9.]+"/)) {
          value = substr($0, RSTART, RLENGTH)
          gsub(/[^0-9.]/, "", value)
          fraction = value + 0
        }
        if (points < 3 || anchor < 1 || anchor >= points ||
            fraction < 0 || fraction > 1) bad = 1
      }
      END { exit bad }
    ' || fail "$svg has an arrow anchor outside its streamline"

  if grep -Eqi 'nan|inf' "$svg"; then
    fail "$svg contains non-finite geometry"
  fi
  check_streamplot_geometry "$svg"
  grep -q 'class="polar-legend"' "$svg" ||
    fail "$svg has no polar legend"
}

check_streamplot "$STREAM" solid 0.5 0
check_streamplot "$STREAM_STYLES" dashed 0.65 0
check_streamplot "$STREAM_CLIP" solid 0.95 positive explicit

# Cartesian examples must stay Cartesian: no polar marker, no polar layer.
for svg in \
  examples/output/line.svg \
  examples/output/histogram.svg \
  examples/output/errorbar.svg \
  examples/output/annotations.svg \
  examples/output/axline.svg \
  examples/output/cartesian-controls.svg \
  examples/output/histogram-horizontal.svg \
  examples/output/stem.svg \
  examples/output/quiver.svg \
  examples/output/hexbin.svg \
  examples/output/heatmap-extent.svg \
  examples/output/contour-coords.svg \
  examples/output/aspect.svg \
  examples/output/bars-grouped.svg \
  examples/output/bars-stacked.svg
do
  [ -s "$svg" ] || fail "missing cartesian example output: $svg"
  grep -q 'class="background"' "$svg" || fail "$svg has no figure background"
  if grep -q 'data-polar="true"' "$svg"; then
    fail "$svg unexpectedly contains polar output"
  fi
done

# Marker decimation, minor ticks, and minor grid share the line example.
LINE=examples/output/line.svg
grep -q 'data-markevery="true"' "$LINE" ||
  fail "$LINE should demonstrate markevery"
grep -q 'data-marker-count="[0-9]*"' "$LINE" ||
  fail "$LINE is missing marker-count metadata"
grep -q 'data-minorticks="both"' "$LINE" ||
  fail "$LINE should enable minor ticks"
grep -q 'data-minor-grid="true"' "$LINE" ||
  fail "$LINE should enable the minor grid"
grep -q 'class="grid-minor"' "$LINE" ||
  fail "$LINE has no minor grid group"
grep -q 'class="minor-tick-mark"' "$LINE" ||
  fail "$LINE has no minor tick marks"

# Asymmetric error bars must expose both modes.
ERRORBAR=examples/output/errorbar.svg
grep -q 'data-yerr-mode="asymmetric"' "$ERRORBAR" ||
  fail "$ERRORBAR should use asymmetric y errors"
grep -q 'data-xerr-mode="asymmetric"' "$ERRORBAR" ||
  fail "$ERRORBAR should use asymmetric x errors"

# axline must be clipped, omit polar output, and rotate y tick labels.
AXLINE=examples/output/axline.svg
grep -q 'class="series series-axline"' "$AXLINE" ||
  fail "$AXLINE has no axline series"
grep -q 'class="reference axline"' "$AXLINE" ||
  fail "$AXLINE has no clipped reference line"
grep -q 'data-clipped="true"' "$AXLINE" ||
  fail "$AXLINE axline should be clipped to the plot"
grep -q 'transform="rotate(30 ' "$AXLINE" ||
  fail "$AXLINE should rotate y tick labels"
grep -q 'class="series series-axhline" data-xmin="0" data-xmax="1"' "$AXLINE" ||
  fail "$AXLINE default axhline should still span the full axes"
grep -q 'class="series series-axvline" data-ymin="0" data-ymax="1"' "$AXLINE" ||
  fail "$AXLINE default axvline should still span the full axes"
if grep -Eqi 'nan|inf' "$AXLINE"; then
  fail "$AXLINE contains non-finite geometry"
fi

# Fractional reference spans, masked fill bands, and independent grid styles.
CONTROLS=examples/output/cartesian-controls.svg
grep -q 'class="series series-fill" data-where="masked" data-interpolate="true"' \
  "$CONTROLS" || fail "$CONTROLS has no masked fill series"
fill_segments=$(grep -o 'data-segments="[0-9]*"' "$CONTROLS" | head -1 |
  tr -dc '0-9')
[ -n "$fill_segments" ] || fail "$CONTROLS has no fill segment count"
[ "$fill_segments" -ge 2 ] ||
  fail "$CONTROLS masked fill should split into multiple bands"
fill_polygons=$(grep -o 'class="fill-between"' "$CONTROLS" | wc -l |
  tr -d ' ')
[ "$fill_polygons" -eq "$fill_segments" ] ||
  fail "$CONTROLS has $fill_segments fill segments but $fill_polygons polygons"
grep -q 'class="series series-axhline" data-xmin="0.06" data-xmax="0.4"' \
  "$CONTROLS" || fail "$CONTROLS has no fractional axhline span"
grep -q 'class="series series-axvline" data-ymin="0.18" data-ymax="0.82"' \
  "$CONTROLS" || fail "$CONTROLS has no fractional axvline span"
grep -q '<g class="grid" stroke="#cbd5e1" stroke-width="1" stroke-opacity="0.75">' \
  "$CONTROLS" || fail "$CONTROLS has no custom-opacity major grid"
grep -q '<g class="grid-minor" stroke="#e2e8f0" stroke-width="0.6" stroke-dasharray="2 3" stroke-opacity="0.4">' \
  "$CONTROLS" || fail "$CONTROLS has no independently styled minor grid"
grep -E 'class="reference"' "$CONTROLS" | head -1 | awk '
  {
    if (!match($0, /x1="[^"]*"/)) exit 1
    x1 = substr($0, RSTART + 4, RLENGTH - 5) + 0
    if (!match($0, /x2="[^"]*"/)) exit 1
    x2 = substr($0, RSTART + 4, RLENGTH - 5) + 0
    if (x2 <= x1 || x2 - x1 >= 696) exit 1
  }
' || fail "$CONTROLS fractional axhline should be shorter than the plot width"

# Horizontal histograms place counts on x and bin edges on y.
HIST_H=examples/output/histogram-horizontal.svg
grep -q 'class="series series-hist" data-label="1800 samples" data-orientation="horizontal"' \
  "$HIST_H" || fail "$HIST_H is not a horizontal histogram"
hist_bins=$(grep -o 'class="hist-bin"' "$HIST_H" | wc -l | tr -d ' ')
[ "$hist_bins" -gt 0 ] || fail "$HIST_H has no histogram bins"
grep -o '<rect class="hist-bin"[^>]*/>' "$HIST_H" | awk '
  {
    if (!match($0, /width="[^"]*"/)) exit 1
    width = substr($0, RSTART + 7, RLENGTH - 8) + 0
    if (!match($0, /height="[^"]*"/)) exit 1
    height = substr($0, RSTART + 8, RLENGTH - 9) + 0
    if (width <= 0 || height <= 0) exit 1
  }
' || fail "$HIST_H has a degenerate horizontal histogram bin"

# Styled stems expose their base and marker/line style and draw both parts.
STEM=examples/output/stem.svg
grep -q 'class="series series-stem" data-base="0.5" data-marker="diamond" data-linestyle="dashed"' \
  "$STEM" || fail "$STEM is missing styled stem metadata"
stem_lines=$(grep -o 'class="stem-line"' "$STEM" | wc -l | tr -d ' ')
stem_markers=$(grep -o 'class="stem-marker"' "$STEM" | wc -l | tr -d ' ')
[ "$stem_lines" -gt 0 ] && [ "$stem_lines" -eq "$stem_markers" ] ||
  fail "$STEM should draw one marker per stem line"
grep -q 'stroke-dasharray="6 4"' "$STEM" ||
  fail "$STEM should use the dashed stem style"
grep -q '<polygon class="stem-marker"' "$STEM" ||
  fail "$STEM should use diamond stem markers"

# Cartesian quiver glyph groups must agree with their decimation metadata.
QUIVER_CART=examples/output/quiver.svg
grep -q 'class="series series-quiver"' "$QUIVER_CART" ||
  fail "$QUIVER_CART has no quiver series"
quiver_count=$(grep -o 'data-count="[0-9]*"' "$QUIVER_CART" | head -1 |
  tr -dc '0-9')
quiver_drawn=$(grep -o 'data-drawn="[0-9]*"' "$QUIVER_CART" | head -1 |
  tr -dc '0-9')
quiver_heads=$(grep -o 'class="quiver-head"' "$QUIVER_CART" | wc -l |
  tr -d ' ')
[ -n "$quiver_count" ] && [ -n "$quiver_drawn" ] ||
  fail "$QUIVER_CART is missing quiver count metadata"
[ "$quiver_heads" -eq "$quiver_drawn" ] ||
  fail "$QUIVER_CART has $quiver_drawn drawn vectors but $quiver_heads heads"
[ "$quiver_drawn" -le "$quiver_count" ] ||
  fail "$QUIVER_CART drew more arrows than its input"
grep -q 'data-scale-mode="auto"' "$QUIVER_CART" ||
  fail "$QUIVER_CART should advertise its automatic scale"
grep -q 'data-pivot="middle"' "$QUIVER_CART" ||
  fail "$QUIVER_CART should advertise its middle pivot"
grep -q 'class="legend"' "$QUIVER_CART" ||
  fail "$QUIVER_CART has no legend"
angled=$(grep -o 'class="quiver-arrow"[^>]*data-angle="[^"]*"' "$QUIVER_CART" |
  wc -l | tr -d ' ')
[ "$angled" -eq "$quiver_drawn" ] ||
  fail "$QUIVER_CART arrows are missing data-angle metadata"
if grep -Eqi 'nan|inf' "$QUIVER_CART"; then
  fail "$QUIVER_CART contains non-finite geometry"
fi

# Hexbin cells, counts, and colorbar labels must stay consistent.
HEXBIN=examples/output/hexbin.svg
grep -q 'class="series series-hexbin"' "$HEXBIN" ||
  fail "$HEXBIN has no hexbin series"
hexbin_points=$(grep -o 'data-points="[0-9]*"' "$HEXBIN" | head -1 |
  tr -dc '0-9')
hexbin_cells=$(grep -o 'class="hexbin-cell"' "$HEXBIN" | wc -l |
  tr -d ' ')
hexbin_bins=$(grep -o 'data-bins="[0-9]*"' "$HEXBIN" | head -1 |
  tr -dc '0-9')
[ -n "$hexbin_points" ] && [ -n "$hexbin_bins" ] ||
  fail "$HEXBIN is missing hexbin metadata"
[ "$hexbin_cells" -eq "$hexbin_bins" ] ||
  fail "$HEXBIN reports $hexbin_bins bins but draws $hexbin_cells cells"
[ "$hexbin_cells" -gt 0 ] || fail "$HEXBIN has no drawn cells"
hexbin_sum=$(grep -o 'class="hexbin-cell"[^>]*data-count="[0-9]*"' "$HEXBIN" |
  sed -E 's/.*data-count="([0-9]+)"/\1/' |
  awk '{ total += $1 } END { print total + 0 }')
[ "$hexbin_sum" -gt 0 ] && [ "$hexbin_sum" -le "$hexbin_points" ] ||
  fail "$HEXBIN cell counts do not fit its input point count"
grep -q 'class="colorbar hexbin-colorbar"' "$HEXBIN" ||
  fail "$HEXBIN has no count colorbar"
hexbin_ticks=$(grep -o 'data-ticks="[0-9]*"' "$HEXBIN" | head -1 |
  tr -dc '0-9')
hexbin_labels=$(grep -o 'class="colorbar-label"' "$HEXBIN" | wc -l |
  tr -d ' ')
[ "$hexbin_labels" -eq "$hexbin_ticks" ] ||
  fail "$HEXBIN has $hexbin_ticks colorbar ticks but $hexbin_labels labels"
if grep -Eqi 'nan|inf' "$HEXBIN"; then
  fail "$HEXBIN contains non-finite geometry"
fi

# Custom image extents and origins must survive into the SVG contract.
HEATMAP_EXTENT=examples/output/heatmap-extent.svg
grep -q 'class="heatmap" data-origin="lower" data-extent="100,280,20,70"' \
  "$HEATMAP_EXTENT" || fail "$HEATMAP_EXTENT is missing extent/origin metadata"
extent_cells=$(grep -o 'class="heatmap-cell"' "$HEATMAP_EXTENT" | wc -l |
  tr -d ' ')
[ "$extent_cells" -eq 54 ] ||
  fail "$HEATMAP_EXTENT should draw 54 extent-mapped cells"
grep -q 'class="colorbar"' "$HEATMAP_EXTENT" ||
  fail "$HEATMAP_EXTENT has no colorbar"

# Explicit contour coordinates must produce real isolines and labels.
CONTOUR_COORDS=examples/output/contour-coords.svg
grep -q 'class="contour"' "$CONTOUR_COORDS" ||
  fail "$CONTOUR_COORDS has no contour series"
contour_segments=$(grep -o 'class="contour-segment"' "$CONTOUR_COORDS" |
  wc -l | tr -d ' ')
[ "$contour_segments" -gt 0 ] ||
  fail "$CONTOUR_COORDS has no contour segments"
contour_labels=$(grep -o 'class="contour-label"' "$CONTOUR_COORDS" |
  wc -l | tr -d ' ')
[ "$contour_labels" -gt 0 ] ||
  fail "$CONTOUR_COORDS has no contour labels"

# Equal aspect must produce a square plot box.
ASPECT=examples/output/aspect.svg
grep -q 'data-aspect="equal"' "$ASPECT" ||
  fail "$ASPECT does not advertise equal aspect"
aspect_width=$(grep -o 'data-plot-width="[0-9.]*"' "$ASPECT" | head -1 |
  tr -dc '0-9.')
aspect_height=$(grep -o 'data-plot-height="[0-9.]*"' "$ASPECT" | head -1 |
  tr -dc '0-9.')
[ -n "$aspect_width" ] && [ -n "$aspect_height" ] ||
  fail "$ASPECT is missing plot-box metadata"
awk -v width="$aspect_width" -v height="$aspect_height" \
  'BEGIN { difference = width - height; if (difference < 0) difference = -difference; exit difference > 0.002 }' ||
  fail "$ASPECT plot box should be square for equal data spans"

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "rsvg-convert not found; polar SVGs are in examples/output/"
  exit 0
fi

for svg in "${POLAR_SVGS[@]}"; do
  png="${svg%.svg}.png"
  rsvg-convert -z 2 "$svg" -o "$png"
  [ -s "$png" ] || fail "rasterization produced no output for $svg"
  echo "wrote $png"
done

# Rasterize the Cartesian feature examples too, so a reviewer can inspect
# marker density, minor grids, asymmetric caps, vector glyphs, hexagons,
# extent/origin placement, explicit contour coordinates, and equal aspect.
for svg in "$LINE" "$ERRORBAR" "$AXLINE" "$CONTROLS" "$HIST_H" "$STEM" \
  "$QUIVER_CART" "$HEXBIN" "$HEATMAP_EXTENT" "$CONTOUR_COORDS" "$ASPECT"; do
  png="${svg%.svg}.png"
  rsvg-convert -z 2 "$svg" -o "$png"
  [ -s "$png" ] || fail "rasterization produced no output for $svg"
  echo "wrote $png"
done
