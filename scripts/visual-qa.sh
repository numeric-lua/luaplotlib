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
# Polar bars expose per-bar outlines, widths, and opacity.
POLAR_BARS=examples/output/polar-bars.svg
grep -q 'class="series series-polar-bar" data-edgecolors="true" data-linewidths="true" data-alphas="true"' \
  "$POLAR_BARS" || fail "$POLAR_BARS should expose per-bar style arrays"
polar_bar_edges=$(grep -o 'class="polar-bar"[^>]*stroke="[^"]*"' "$POLAR_BARS" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$polar_bar_edges" -ge 3 ] ||
  fail "$POLAR_BARS should vary bar edge colors"
polar_bar_widths=$(grep -o 'class="polar-bar"[^>]*stroke-width="[^"]*"' "$POLAR_BARS" |
  sed -E 's/.*stroke-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$polar_bar_widths" -ge 2 ] ||
  fail "$POLAR_BARS should vary bar outline widths"
polar_bar_alphas=$(grep -o 'class="polar-bar"[^>]*fill-opacity="[^"]*"' "$POLAR_BARS" |
  sed -E 's/.*fill-opacity="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$polar_bar_alphas" -ge 3 ] ||
  fail "$POLAR_BARS should vary bar opacity"

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
quiver_field_colors=$(grep -o 'class="polar-quiver-shaft"[^>]*stroke="[^"]*"' "$QUIVER" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$quiver_field_colors" -ge 2 ] ||
  fail "$QUIVER should vary colors per arrow"
quiver_field_widths=$(grep -o 'class="polar-quiver-shaft"[^>]*stroke-width="[^"]*"' "$QUIVER" |
  sed -E 's/.*stroke-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$quiver_field_widths" -ge 2 ] ||
  fail "$QUIVER should vary widths per arrow"

# Polar errorbars use Cartesian-parity per-point styling arrays.
POLAR_ANNOT=examples/output/polar-annotations.svg
polar_err_colors=$(grep -o 'class="polar-errorbar[^"]*"[^>]*stroke="[^"]*"' "$POLAR_ANNOT" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$polar_err_colors" -ge 2 ] ||
  fail "$POLAR_ANNOT should vary polar error colors"
polar_err_widths=$(grep -o 'class="polar-errorbar[^"]*"[^>]*stroke-width="[^"]*"' "$POLAR_ANNOT" |
  sed -E 's/.*stroke-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$polar_err_widths" -ge 2 ] ||
  fail "$POLAR_ANNOT should vary polar error widths"
polar_err_sizes=$(grep -o 'class="marker"[^>]*r="[^"]*"' "$POLAR_ANNOT" |
  sed -E 's/.*r="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$polar_err_sizes" -ge 2 ] ||
  fail "$POLAR_ANNOT should vary polar marker sizes"

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
  examples/output/ecdf-complementary.svg \
  examples/output/annotations.svg \
  examples/output/axline.svg \
  examples/output/cartesian-controls.svg \
  examples/output/histogram-horizontal.svg \
  examples/output/hist-edges.svg \
  examples/output/step-fill.svg \
  examples/output/stem.svg \
  examples/output/stem-horizontal.svg \
  examples/output/quiver.svg \
  examples/output/quiver-uv.svg \
  examples/output/hexbin.svg \
  examples/output/hist2d.svg \
  examples/output/scatter-colors.svg \
  examples/output/violinplot.svg \
  examples/output/violin-horizontal.svg \
  examples/output/stack-baseline.svg \
  examples/output/bar-errors.svg \
  examples/output/bar-linewidth.svg \
  examples/output/barh-hatch.svg \
  examples/output/broken-barh.svg \
  examples/output/pie-explode.svg \
  examples/output/pie-rotated.svg \
  examples/output/pie-counterclock.svg \
  examples/output/heatmap-extent.svg \
  examples/output/contour-coords.svg \
  examples/output/aspect.svg \
  examples/output/minor-subdivisions.svg \
  examples/output/eventplot-layout.svg \
  examples/output/hist-styles.svg \
  examples/output/boxplot-horizontal.svg \
  examples/output/imshow-colorbar.svg \
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
grep -q 'class="legend-meta" data-loc="upper center" data-framealpha="0.85"' \
  "$LINE" || fail "$LINE should use a centered, translucent legend"
grep -q 'fill="#f8fafc" fill-opacity="0.85" stroke="#94a3b8"' "$LINE" ||
  fail "$LINE should style its legend frame"
marker_line=$(grep -o '<circle class="marker"[^>]*/>' "$LINE" | head -1)
[ -n "$marker_line" ] || fail "$LINE has no circle markers"
printf '%s\n' "$marker_line" | grep -q 'fill="#ffffff"' ||
  fail "$LINE markers should have a white face"
printf '%s\n' "$marker_line" | grep -q 'stroke="#1f77b4"' ||
  fail "$LINE markers should have a blue edge"
printf '%s\n' "$marker_line" | grep -q 'stroke-width="1.2"' ||
  fail "$LINE markers should have a 1.2-pixel edge"
grep -q 'data-xlabel-pad="10" data-ylabel-pad="8"' "$LINE" ||
  fail "$LINE should expose axis label padding"
grep -q 'data-ticklabelsize="12" data-ticklabelcolor="#334155"' "$LINE" ||
  fail "$LINE should expose tick label styling"
grep -q 'data-ticklabelweight="bold"' "$LINE" ||
  fail "$LINE should expose bold tick labels"
grep -q 'class="tick-label"[^>]*font-weight="bold"' "$LINE" ||
  fail "$LINE should render bold tick labels"
grep -q 'class="tick-label"[^>]*font-size="12" fill="#334155"' "$LINE" ||
  fail "$LINE should render styled tick labels"
grep -q 'class="title" x="[^"]*" y="[^"]*" font-size="20" fill="#0f172a"' \
  "$LINE" || fail "$LINE should render a styled title"
grep -q 'class="xlabel"[^>]*font-size="15" fill="#334155"' "$LINE" ||
  fail "$LINE should render a styled x label"
grep -q 'class="ylabel"[^>]*font-size="15" fill="#334155"' "$LINE" ||
  fail "$LINE should render a styled y label"
grep -q 'data-borderpad="11" data-handlelength="26"' "$LINE" ||
  fail "$LINE should render legend spacing controls"
grep -q 'data-fontsize="13"' "$LINE" ||
  fail "$LINE should render the legend font size"
grep -q 'data-title-fontsize="15"' "$LINE" ||
  fail "$LINE should render the legend title font size"
grep -q 'class="legend-title"[^>]*font-size="15"' "$LINE" ||
  fail "$LINE should style its legend title"
grep -q 'data-title-align="center"' "$LINE" ||
  fail "$LINE should center its legend title"
grep -q 'class="legend-title"[^>]*text-anchor="middle"' "$LINE" ||
  fail "$LINE should anchor its legend title in the center"
grep -q 'data-fontweight="bold"' "$LINE" ||
  fail "$LINE should expose bold legend labels"
grep -q 'class="legend"[^>]*' "$LINE" ||
  fail "$LINE has no legend"
grep -q 'class="title"[^>]*font-weight="bold"' "$LINE" ||
  fail "$LINE should render a bold title"
grep -q 'class="xlabel"[^>]*font-weight="bold"' "$LINE" ||
  fail "$LINE should render a bold x label"
grep -q 'class="ylabel"[^>]*font-weight="bold"' "$LINE" ||
  fail "$LINE should render a bold y label"
grep -q 'data-markerfirst="false"' "$LINE" ||
  fail "$LINE should place labels before legend swatches"

# Configurable minor ticks must subdivide each major interval into four parts.
MINOR_SUB=examples/output/minor-subdivisions.svg
grep -q 'data-minor-subdivisions="4"' "$MINOR_SUB" ||
  fail "$MINOR_SUB does not use four minor subdivisions"
grep -q 'data-minorticks="both"' "$MINOR_SUB" ||
  fail "$MINOR_SUB should enable minor ticks"
minor_marks=$(grep -o 'class="minor-tick-mark"' "$MINOR_SUB" | wc -l |
  tr -d ' ')
[ "$minor_marks" -gt 0 ] || fail "$MINOR_SUB has no minor tick marks"

# Horizontal event lanes must expose offsets/lengths and draw horizontal lines.
EVENT=examples/output/eventplot-layout.svg
grep -q 'class="series series-eventplot" data-orientation="horizontal"' \
  "$EVENT" || fail "$EVENT has no horizontal event series"
event_lines=$(grep -o 'class="event"' "$EVENT" | wc -l | tr -d ' ')
[ "$event_lines" -eq 12 ] ||
  fail "$EVENT should draw twelve event marks"
for offset in 1 4 7; do
  grep -q "data-offset=\"$offset\"" "$EVENT" ||
    fail "$EVENT is missing lane offset $offset"
done
grep -o '<line class="event"[^>]*/>' "$EVENT" | awk '
  {
    if (!match($0, /y1="[^"]*"/)) exit 1
    y1 = substr($0, RSTART + 4, RLENGTH - 5) + 0
    if (!match($0, /y2="[^"]*"/)) exit 1
    y2 = substr($0, RSTART + 4, RLENGTH - 5) + 0
    if (y1 != y2) exit 1
  }
' || fail "$EVENT contains a non-horizontal event mark"
grep -q 'data-eventcolors="true"' "$EVENT" ||
  fail "$EVENT should advertise per-event colors"
event_colors=$(grep -o '<line class="event"[^>]*stroke="[^"]*"' "$EVENT" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$event_colors" -ge 2 ] ||
  fail "$EVENT should vary colors per event"
grep -q 'data-colors="true"' "$EVENT" ||
  fail "$EVENT should use per-row event colors"
grep -q 'data-labels="true"' "$EVENT" ||
  fail "$EVENT should expose lane labels"
for label in fast nominal slow; do
  grep -q ">$label<" "$EVENT" || fail "$EVENT is missing the $label lane label"
done
grep -q 'data-linestyle="dashed"' "$EVENT" ||
  fail "$EVENT should use dashed event lines"
grep -q 'stroke-dasharray="6 4"' "$EVENT" ||
  fail "$EVENT is missing its dashed event pattern"
grep -q 'data-linestyles="true"' "$EVENT" ||
  fail "$EVENT should expose per-row line styles"
grep -q 'stroke-dasharray="1.5 3"' "$EVENT" ||
  fail "$EVENT is missing its dotted event pattern"
event_colors=$(grep -o '<line class="event"[^>]*stroke="[^"]*"' "$EVENT" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$event_colors" -ge 3 ] ||
  fail "$EVENT should use at least three distinct event colors"
event_widths=$(grep -o '<line class="event"[^>]*stroke-width="[^"]*"' "$EVENT" |
  sed -E 's/.*stroke-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$event_widths" -eq 3 ] ||
  fail "$EVENT should use three distinct row line widths"
event_alphas=$(grep -o '<line class="event"[^>]*stroke-opacity="[^"]*"' "$EVENT" |
  sed -E 's/.*stroke-opacity="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$event_alphas" -ge 2 ] ||
  fail "$EVENT should vary row opacity"

# Histogram step styles must render the outline and filled staircase variants.
HIST_STYLES=examples/output/hist-styles.svg
grep -q 'data-histtype="stepfilled"' "$HIST_STYLES" ||
  fail "$HIST_STYLES has no stepfilled histogram"
grep -q 'data-histtype="step"' "$HIST_STYLES" ||
  fail "$HIST_STYLES has no step histogram"
hist_steps=$(grep -o 'class="hist-step"' "$HIST_STYLES" | wc -l | tr -d ' ')
hist_filled=$(grep -o 'class="hist-step-filled"' "$HIST_STYLES" |
  wc -l | tr -d ' ')
[ "$hist_steps" -eq 1 ] && [ "$hist_filled" -eq 1 ] ||
  fail "$HIST_STYLES should draw one outline and one filled staircase"
hist_thick=$(grep -o 'class="hist-step"[^>]*stroke-width="2.5"' "$HIST_STYLES" |
  wc -l | tr -d ' ')
hist_filled_thick=$(grep -o   'class="hist-step-filled"[^>]*stroke-width="2.5"' "$HIST_STYLES" |
  wc -l | tr -d ' ')
[ "$hist_thick" -eq 1 ] && [ "$hist_filled_thick" -eq 1 ] ||
  fail "$HIST_STYLES should use a 2.5-pixel outline"

STEP_FILL=examples/output/step-fill.svg
grep -q 'class="series series-step"[^>]*data-fill="true"' "$STEP_FILL" ||
  fail "$STEP_FILL is not a filled step series"
grep -q 'class="step-fill"' "$STEP_FILL" ||
  fail "$STEP_FILL has no step area polygon"
grep -q 'class="step-fill"[^>]*fill-opacity="0.28"' "$STEP_FILL" ||
  fail "$STEP_FILL should use its configured fill opacity"

HIST_EDGES=examples/output/hist-edges.svg
hist_edge_bins=$(grep -o 'class="hist-bin"' "$HIST_EDGES" | wc -l |
  tr -d ' ')
[ "$hist_edge_bins" -eq 5 ] ||
  fail "$HIST_EDGES should draw five explicit-edge bins"
grep -q '<pattern id="hatch-' "$HIST_EDGES" ||
  fail "$HIST_EDGES has no histogram hatch"
hist_edge_colors=$(grep -o 'class="hist-bin"[^>]*stroke="[^"]*"' "$HIST_EDGES" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$hist_edge_colors" -ge 3 ] ||
  fail "$HIST_EDGES should vary per-bin edge colors"
hist_edge_widths=$(grep -o 'class="hist-bin"[^>]*stroke-width="[^"]*"' "$HIST_EDGES" |
  sed -E 's/.*stroke-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$hist_edge_widths" -ge 3 ] ||
  fail "$HIST_EDGES should vary per-bin outline widths"
grep -q '<pattern id="hatch-' "$HIST_STYLES" ||
  fail "$HIST_STYLES has no histogram hatch definition"
grep -q 'class="hist-step-filled"[^>]*fill="url(#hatch-' "$HIST_STYLES" ||
  fail "$HIST_STYLES stepfilled body should use its hatch pattern"

# Horizontal boxplots keep their category labels on the y axis.
BOX_H=examples/output/boxplot-horizontal.svg
box_groups=$(grep -o 'class="series series-box"[^>]*data-orientation="horizontal"' \
  "$BOX_H" | wc -l | tr -d ' ')
[ "$box_groups" -eq 3 ] ||
  fail "$BOX_H should draw three horizontal box groups"
for label in control treatment follow-up; do
  grep -q ">$label<" "$BOX_H" ||
    fail "$BOX_H is missing the $label category label"
done
box_means=$(grep -o 'class="box-mean-marker"' "$BOX_H" | wc -l | tr -d ' ')
[ "$box_means" -eq 3 ] ||
  fail "$BOX_H should draw one mean marker per box"
grep -q 'data-showmeans="true"' "$BOX_H" ||
  fail "$BOX_H should advertise its mean markers"
grep -q 'data-notch="true"' "$BOX_H" ||
  fail "$BOX_H should advertise notched boxes"
box_notches=$(grep -o 'class="box box-notch"' "$BOX_H" | wc -l | tr -d ' ')
[ "$box_notches" -eq 3 ] ||
  fail "$BOX_H should draw three notched box polygons"
box_widths=$(grep -o 'class="series series-box"[^>]*data-width="[^"]*"' "$BOX_H" |
  sed -E 's/.*data-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$box_widths" -eq 3 ] ||
  fail "$BOX_H should use three distinct box widths"
grep -q 'data-whis="1" data-showfliers="false"' "$BOX_H" ||
  fail "$BOX_H should expose whisker and flier controls"
box_fliers=$(grep -o 'class="box-outlier"' "$BOX_H" | wc -l | tr -d ' ' || true)
[ "$box_fliers" -eq 0 ] ||
  fail "$BOX_H should hide its outliers"
grep -q 'data-showcaps="false"' "$BOX_H" ||
  fail "$BOX_H should hide its caps"
box_caps=$(grep -o 'class="box-cap"' "$BOX_H" | wc -l | tr -d ' ' || true)
[ "$box_caps" -eq 0 ] ||
  fail "$BOX_H should draw no box caps"
box_colors=$(grep -o 'class="box box-notch"[^>]*stroke="[^"]*"' "$BOX_H" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$box_colors" -eq 3 ] ||
  fail "$BOX_H should use three box colors"
box_edges=$(grep -o 'class="box box-notch"[^>]*stroke="[^"]*"' "$BOX_H" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$box_edges" -eq 3 ] ||
  fail "$BOX_H should use three box edge colors"
box_alphas=$(grep -o 'class="box box-notch"[^>]*fill-opacity="[^"]*"' "$BOX_H" |
  sed -E 's/.*fill-opacity="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$box_alphas" -eq 3 ] ||
  fail "$BOX_H should use three box fill opacities"

# Image colorbars accept a title and explicit tick values.
IMSHOW=examples/output/imshow-colorbar.svg
grep -q 'class="colorbar imshow-colorbar"' "$IMSHOW" ||
  fail "$IMSHOW has no extended image colorbar"
grep -q 'data-tick-source="explicit"' "$IMSHOW" ||
  fail "$IMSHOW should use explicit colorbar ticks"
grep -q 'data-ticks="5"' "$IMSHOW" ||
  fail "$IMSHOW should draw five colorbar ticks"
imshow_labels=$(grep -o 'class="colorbar-label"' "$IMSHOW" | wc -l |
  tr -d ' ')
[ "$imshow_labels" -eq 5 ] ||
  fail "$IMSHOW has five ticks but $imshow_labels labels"
grep -q 'class="colorbar-title"' "$IMSHOW" ||
  fail "$IMSHOW has no colorbar title"
grep -q 'class="heatmap" data-alpha="0.8"' "$IMSHOW" ||
  fail "$IMSHOW should apply an 0.8 heatmap alpha"
imshow_faded=$(grep -o 'class="heatmap-cell"[^>]*fill-opacity="0.8"' "$IMSHOW" |
  wc -l | tr -d ' ')
[ "$imshow_faded" -gt 0 ] ||
  fail "$IMSHOW heatmap cells should carry the alpha opacity"

# Asymmetric error bars must expose both modes.
ERRORBAR=examples/output/errorbar.svg
grep -q 'data-yerr-mode="asymmetric"' "$ERRORBAR" ||
  fail "$ERRORBAR should use asymmetric y errors"
grep -q 'data-xerr-mode="asymmetric"' "$ERRORBAR" ||
  fail "$ERRORBAR should use asymmetric x errors"
grep -q 'data-errorevery="2" data-error-points="3"' "$ERRORBAR" ||
  fail "$ERRORBAR should draw every second error bar"
errorbar_lines=$(grep -o 'class="errorbar"' "$ERRORBAR" | wc -l | tr -d ' ')
[ "$errorbar_lines" -eq 6 ] ||
  fail "$ERRORBAR should draw six error-bar segments for three points"
errorbar_marker=$(grep -o '<circle class="marker"[^>]*/>' "$ERRORBAR" | head -1)
[ -n "$errorbar_marker" ] || fail "$ERRORBAR has no markers"
printf '%s\n' "$errorbar_marker" | grep -q 'fill="#ffffff"' ||
  fail "$ERRORBAR markers should have a white face"
printf '%s\n' "$errorbar_marker" | grep -q 'stroke="#1f77b4"' ||
  fail "$ERRORBAR markers should have a blue edge"
errorbar_sizes=$(grep -o 'class="marker"[^>]*r="[^"]*"' "$ERRORBAR" |
  sed -E 's/.*r="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$errorbar_sizes" -ge 2 ] ||
  fail "$ERRORBAR should vary marker sizes per point"
errorbar_widths=$(grep -o 'class="errorbar"[^>]*stroke-width="[^"]*"' "$ERRORBAR" |
  sed -E 's/.*stroke-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$errorbar_widths" -ge 2 ] ||
  fail "$ERRORBAR should vary error line widths per point"
grep -q 'data-lolims="true" data-uplims="true"' "$ERRORBAR" ||
  fail "$ERRORBAR should expose limit flags"
errorbar_limits=$(grep -o 'class="errorbar-limit-[a-z]*"' "$ERRORBAR" |
  wc -l | tr -d ' ')
[ "$errorbar_limits" -eq 5 ] ||
  fail "$ERRORBAR should draw five limit arrowheads"
errorbar_caps=$(grep -o 'class="errorbar-cap"' "$ERRORBAR" | wc -l |
  tr -d ' ')
[ "$errorbar_caps" -eq 7 ] ||
  fail "$ERRORBAR should draw seven ordinary caps after limits"
grep -q 'data-xlolims="true" data-xuplims="true"' "$ERRORBAR" ||
  fail "$ERRORBAR should expose x limit flags"
errorbar_colors=$(grep -o 'class="errorbar"[^>]*stroke="[^"]*"' "$ERRORBAR" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$errorbar_colors" -ge 2 ] ||
  fail "$ERRORBAR should vary error colors per point"
errorbar_xlimits=$(grep -o 'class="errorbar-limit-\(left\|right\)"' "$ERRORBAR" |
  wc -l | tr -d ' ')
[ "$errorbar_xlimits" -eq 2 ] ||
  fail "$ERRORBAR should draw two horizontal limit arrowheads"

# Complementary ECDF steps count down and expose their mode.
ECDF=examples/output/ecdf-complementary.svg
grep -q 'class="series series-step" data-ecdf="true" data-complementary="true"' \
  "$ECDF" || fail "$ECDF is not a complementary ECDF"
grep -q 'class="series series-step"' "$ECDF" ||
  fail "$ECDF has no step series"
grep -q 'class="legend"' "$ECDF" ||
  fail "$ECDF has no legend"

# Annotations with a background expose a box behind the text.
ANNOTATIONS=examples/output/annotations.svg
grep -q 'class="annotation-background"' "$ANNOTATIONS" ||
  fail "$ANNOTATIONS has no annotation background"
grep -q 'class="annotation-text"[^>]*font-weight="bold"' "$ANNOTATIONS" ||
  fail "$ANNOTATIONS should render a bold annotation"
grep -q 'class="annotation-background" x="[^"]*" y="[^"]*" width="[^"]*" height="[^"]*" rx="2" fill="#ffffff" fill-opacity="0.9" stroke="#d62728"' \
  "$ANNOTATIONS" || fail "$ANNOTATIONS background styling is incomplete"
grep -q 'class="annotation-text"[^>]*transform="rotate(-12 ' "$ANNOTATIONS" ||
  fail "$ANNOTATIONS has no rotated annotation"

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
grep -q '<pattern id="hatch-' "$CONTROLS" ||
  fail "$CONTROLS has no hatch pattern definitions"
fill_hatched=$(grep -o 'class="fill-between"[^>]*fill="url(#hatch-' "$CONTROLS" |
  wc -l | tr -d ' ')
[ "$fill_hatched" -eq "$fill_segments" ] ||
  fail "$CONTROLS fill segments should use their hatch pattern"
span_hatched=$(grep -o 'class="span ax[hv]span"[^>]*fill="url(#hatch-' \
  "$CONTROLS" | wc -l | tr -d ' ')
[ "$span_hatched" -eq 2 ] ||
  fail "$CONTROLS should hatch both shaded spans"
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
grep -q '<polygon class="stem-marker"[^>]*fill="#ffffff" stroke="#8c564b" stroke-width="1.2"' \
  "$STEM" || fail "$STEM should style its diamond markers"

# Horizontal stems grow along x and expose their orientation.
STEM_H=examples/output/stem-horizontal.svg
grep -q 'class="series series-stem"[^>]*data-orientation="horizontal"' \
  "$STEM_H" || fail "$STEM_H is not a horizontal stem plot"
stem_h_lines=$(grep -o '<line class="stem-line"[^>]*/>' "$STEM_H" | wc -l |
  tr -d ' ')
[ "$stem_h_lines" -eq 6 ] || fail "$STEM_H should draw six stems"
grep -o '<line class="stem-line"[^>]*/>' "$STEM_H" | awk '
  {
    if (!match($0, /y1="[^"]*"/)) exit 1
    y1 = substr($0, RSTART + 4, RLENGTH - 5) + 0
    if (!match($0, /y2="[^"]*"/)) exit 1
    y2 = substr($0, RSTART + 4, RLENGTH - 5) + 0
    if (y1 != y2) exit 1
  }
' || fail "$STEM_H contains a non-horizontal stem"
grep -q '<polygon class="stem-marker"[^>]*fill="#ffffff" stroke="#0f766e"' \
  "$STEM_H" || fail "$STEM_H markers are not styled"

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
grep -q 'data-headwidth="1.3"' "$QUIVER_CART" ||
  fail "$QUIVER_CART should expose its head width"
quiver_colors=$(grep -o 'class="quiver-shaft"[^>]*stroke="[^"]*"' "$QUIVER_CART" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$quiver_colors" -ge 2 ] ||
  fail "$QUIVER_CART should vary colors per arrow"
quiver_widths=$(grep -o 'class="quiver-shaft"[^>]*stroke-width="[^"]*"' "$QUIVER_CART" |
  sed -E 's/.*stroke-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$quiver_widths" -ge 2 ] ||
  fail "$QUIVER_CART should vary widths per arrow"
grep -q 'class="legend"' "$QUIVER_CART" ||
  fail "$QUIVER_CART has no legend"
angled=$(grep -o 'class="quiver-arrow"[^>]*data-angle="[^"]*"' "$QUIVER_CART" |
  wc -l | tr -d ' ')
[ "$angled" -eq "$quiver_drawn" ] ||
  fail "$QUIVER_CART arrows are missing data-angle metadata"
if grep -Eqi 'nan|inf' "$QUIVER_CART"; then
  fail "$QUIVER_CART contains non-finite geometry"
fi

QUIVER_UV=examples/output/quiver-uv.svg
grep -q 'class="series series-quiver"[^>]*data-angles="uv"' "$QUIVER_UV" ||
  fail "$QUIVER_UV should use uv angles"
quiver_uv_drawn=$(grep -o 'data-drawn="[0-9]*"' "$QUIVER_UV" | head -1 |
  tr -dc '0-9')
quiver_uv_heads=$(grep -o 'class="quiver-head"' "$QUIVER_UV" | wc -l |
  tr -d ' ')
[ -n "$quiver_uv_drawn" ] && [ "$quiver_uv_heads" -eq "$quiver_uv_drawn" ] ||
  fail "$QUIVER_UV arrow heads do not match its drawn count"

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
grep -q 'class="series series-hexbin"[^>]*data-norm="log"' "$HEXBIN" ||
  fail "$HEXBIN should use log count normalization"
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

# Rectangular hist2d cells must agree with the reported grid and input.
HIST2D=examples/output/hist2d.svg
grep -q 'class="series series-hist2d"' "$HIST2D" ||
  fail "$HIST2D has no hist2d series"
hist2d_points=$(grep -o 'data-points="[0-9]*"' "$HIST2D" | head -1 |
  tr -dc '0-9')
hist2d_inside=$(grep -o 'data-inside="[0-9]*"' "$HIST2D" | head -1 |
  tr -dc '0-9')
hist2d_bins_x=$(grep -o 'data-bins-x="[0-9]*"' "$HIST2D" | head -1 |
  tr -dc '0-9')
hist2d_bins_y=$(grep -o 'data-bins-y="[0-9]*"' "$HIST2D" | head -1 |
  tr -dc '0-9')
[ -n "$hist2d_points" ] && [ -n "$hist2d_inside" ] &&
  [ -n "$hist2d_bins_x" ] && [ -n "$hist2d_bins_y" ] ||
  fail "$HIST2D is missing hist2d metadata"
[ "$hist2d_inside" -gt 0 ] && [ "$hist2d_inside" -le "$hist2d_points" ] ||
  fail "$HIST2D inside count does not fit its input"
hist2d_cells=$(grep -o 'class="hist2d-cell"' "$HIST2D" | wc -l |
  tr -d ' ')
[ "$hist2d_cells" -gt 0 ] ||
  fail "$HIST2D has no hist2d cells"
[ "$hist2d_cells" -le $((hist2d_bins_x * hist2d_bins_y)) ] ||
  fail "$HIST2D draws more cells than its grid"
grep -q 'data-show-empty="true"' "$HIST2D" ||
  fail "$HIST2D should include empty cells"
grep -q 'data-color-norm="log"' "$HIST2D" ||
  fail "$HIST2D should use log color normalization"
grep -q 'data-explicit-bins="true"' "$HIST2D" ||
  fail "$HIST2D should use explicit bin edges"
grep -q 'class="colorbar hist2d-colorbar"' "$HIST2D" ||
  fail "$HIST2D should keep its colorbar"
[ "$hist2d_cells" -eq $((hist2d_bins_x * hist2d_bins_y)) ] ||
  fail "$HIST2D should draw the complete hist2d grid"
hist2d_sum=$(grep -o 'class="hist2d-cell"[^>]*data-count="[0-9]*"' "$HIST2D" |
  sed -E 's/.*data-count="([0-9]+)"/\1/' |
  awk '{ total += $1 } END { print total + 0 }')
[ "$hist2d_sum" -eq "$hist2d_inside" ] ||
  fail "$HIST2D cell counts sum to $hist2d_sum, expected $hist2d_inside"
grep -q 'class="colorbar hist2d-colorbar"' "$HIST2D" ||
  fail "$HIST2D has no hist2d colorbar"
hist2d_ticks=$(grep -o 'data-ticks="[0-9]*"' "$HIST2D" | head -1 |
  tr -dc '0-9')
hist2d_labels=$(grep -o 'class="colorbar-label"' "$HIST2D" | wc -l |
  tr -d ' ')
[ "$hist2d_labels" -eq "$hist2d_ticks" ] ||
  fail "$HIST2D has $hist2d_ticks colorbar ticks but $hist2d_labels labels"

# Numeric scatter colors must produce mapped points and a colorbar.
SCATTER_COLORS=examples/output/scatter-colors.svg
grep -q 'class="series series-scatter"[^>]*data-color-values="true"' \
  "$SCATTER_COLORS" || fail "$SCATTER_COLORS has no numeric color mapping"
scatter_points=$(grep -o 'class="point"' "$SCATTER_COLORS" | wc -l |
  tr -d ' ')
[ "$scatter_points" -gt 100 ] ||
  fail "$SCATTER_COLORS has too few colored points"
scatter_fills=$(grep -o 'class="point"[^>]*fill="[^"]*"' "$SCATTER_COLORS" |
  sed -E 's/.*fill="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$scatter_fills" -gt 1 ] ||
  fail "$SCATTER_COLORS maps every point to the same color"
scatter_shapes=$(grep -oE '<(circle|rect|polygon) class="point"' "$SCATTER_COLORS" |
  sed -E 's/<([a-z]+).*/\1/' | sort -u | wc -l | tr -d ' ')
[ "$scatter_shapes" -eq 3 ] ||
  fail "$SCATTER_COLORS should mix circles, squares, and polygon markers"
scatter_alphas=$(grep -o 'class="point"[^>]*fill-opacity="[^"]*"' "$SCATTER_COLORS" |
  sed -E 's/.*fill-opacity="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$scatter_alphas" -gt 3 ] ||
  fail "$SCATTER_COLORS should vary per-point alpha"
scatter_edges=$(grep -o 'class="point"[^>]*stroke="[^"]*"' "$SCATTER_COLORS" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$scatter_edges" -ge 2 ] ||
  fail "$SCATTER_COLORS should vary per-point edge colors"
scatter_widths=$(grep -o 'class="point"[^>]*stroke-width="[^"]*"' "$SCATTER_COLORS" |
  sed -E 's/.*stroke-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$scatter_widths" -ge 2 ] ||
  fail "$SCATTER_COLORS should vary per-point outline widths"
grep -q 'class="colorbar scatter-colorbar"' "$SCATTER_COLORS" ||
  fail "$SCATTER_COLORS has no scatter colorbar"
scatter_ticks=$(grep -o 'data-ticks="[0-9]*"' "$SCATTER_COLORS" | head -1 |
  tr -dc '0-9')
scatter_labels=$(grep -o 'class="colorbar-label"' "$SCATTER_COLORS" | wc -l |
  tr -d ' ')
[ "$scatter_labels" -eq "$scatter_ticks" ] ||
  fail "$SCATTER_COLORS has $scatter_ticks colorbar ticks but $scatter_labels labels"

# Violin bodies, medians, quartiles, and extrema must stay consistent.
VIOLIN=examples/output/violinplot.svg
grep -q 'class="series series-violin"' "$VIOLIN" ||
  fail "$VIOLIN has no violin series"
violin_groups=$(grep -o 'class="series series-violin"' "$VIOLIN" | wc -l |
  tr -d ' ')
violin_bodies=$(grep -o 'class="violin-body"' "$VIOLIN" | wc -l |
  tr -d ' ')
violin_medians=$(grep -o 'class="violin-median"' "$VIOLIN" | wc -l |
  tr -d ' ')
violin_quartiles=$(grep -o 'class="violin-quartile"' "$VIOLIN" | wc -l |
  tr -d ' ')
violin_extrema=$(grep -o 'class="violin-extrema"' "$VIOLIN" | wc -l |
  tr -d ' ')
[ "$violin_groups" -eq 3 ] && [ "$violin_bodies" -eq 3 ] ||
  fail "$VIOLIN should draw three violin bodies"
[ "$violin_medians" -eq 3 ] ||
  fail "$VIOLIN should draw one median per violin"
[ "$violin_quartiles" -eq 6 ] ||
  fail "$VIOLIN should draw two quartile marks per violin"
[ "$violin_extrema" -eq 6 ] ||
  fail "$VIOLIN should draw two extrema per violin"
grep -q 'data-points="80"' "$VIOLIN" ||
  fail "$VIOLIN should use 80 KDE points"

VIOLIN_H=examples/output/violin-horizontal.svg
grep -q 'class="series series-violin"[^>]*data-orientation="horizontal"' \
  "$VIOLIN_H" || fail "$VIOLIN_H is not a horizontal violin plot"
for label in control shifted wide; do
  grep -q ">$label<" "$VIOLIN_H" ||
    fail "$VIOLIN_H is missing the $label category label"
done
violin_h_means=$(grep -o 'class="violin-mean-marker"' "$VIOLIN_H" | wc -l |
  tr -d ' ')
[ "$violin_h_means" -eq 3 ] ||
  fail "$VIOLIN_H should draw one mean marker per violin"
violin_widths=$(grep -o 'class="series series-violin"[^>]*data-width="[^"]*"' "$VIOLIN_H" |
  sed -E 's/.*data-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$violin_widths" -eq 3 ] ||
  fail "$VIOLIN_H should use three distinct violin widths"
violin_alphas=$(grep -o 'class="violin-body"[^>]*fill-opacity="[^"]*"' "$VIOLIN_H" |
  sed -E 's/.*fill-opacity="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$violin_alphas" -eq 3 ] ||
  fail "$VIOLIN_H should use three violin opacities"
violin_edges=$(grep -o 'class="violin-body"[^>]*stroke="[^"]*"' "$VIOLIN_H" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$violin_edges" -eq 3 ] ||
  fail "$VIOLIN_H should use three violin edge colors"
violin_means=$(grep -o 'class="violin-mean-marker"' "$VIOLIN" | wc -l |
  tr -d ' ')
[ "$violin_means" -eq 3 ] ||
  fail "$VIOLIN should draw one mean marker per violin"
grep -q 'data-showmeans="true"' "$VIOLIN" ||
  fail "$VIOLIN should advertise its mean markers"
if grep -Eqi 'nan|inf' "$VIOLIN"; then
  fail "$VIOLIN contains non-finite geometry"
fi

# Stackplot baseline metadata and all three layers must survive.
STACK_BASELINE=examples/output/stack-baseline.svg
grep -q 'class="fill-between" data-stack="true" data-baseline="wiggle"' \
  "$STACK_BASELINE" || fail "$STACK_BASELINE has no wiggle baseline metadata"
stack_polygons=$(grep -o 'class="fill-between"' "$STACK_BASELINE" | wc -l |
  tr -d ' ')
[ "$stack_polygons" -eq 3 ] ||
  fail "$STACK_BASELINE should draw three stacked layers"
for index in 1 2 3; do
  grep -q "data-baseline=\"wiggle\" data-index=\"$index\"" "$STACK_BASELINE" ||
    fail "$STACK_BASELINE is missing stack layer $index"
done

# Horizontal bars expose hatch patterns in defs and fills.
BARH_HATCH=examples/output/barh-hatch.svg
grep -q '<pattern id="hatch-' "$BARH_HATCH" ||
  fail "$BARH_HATCH has no hatch pattern definition"
barh_hatched=$(grep -o 'class="barh"[^>]*fill="url(#hatch-' "$BARH_HATCH" |
  wc -l | tr -d ' ')
[ "$barh_hatched" -eq 4 ] ||
  fail "$BARH_HATCH should fill four bars with a hatch pattern"
barh_heights=$(grep -o 'class="barh"[^>]*height="[^"]*"' "$BARH_HATCH" |
  sed -E 's/.*height="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$barh_heights" -ge 3 ] ||
  fail "$BARH_HATCH should vary bar heights"
barh_edge_colors=$(grep -o 'class="barh"[^>]*stroke="[^"]*"' "$BARH_HATCH" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$barh_edge_colors" -ge 3 ] ||
  fail "$BARH_HATCH should vary bar edge colors"
barh_widths=$(grep -o 'class="barh"[^>]*stroke-width="[^"]*"' "$BARH_HATCH" |
  sed -E 's/.*stroke-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$barh_widths" -ge 3 ] ||
  fail "$BARH_HATCH should vary bar outline widths"

# Grouped bars support one color per bar within each series.
BARS_GROUPED=examples/output/bars-grouped.svg
grep -q 'class="series series-bar"[^>]*data-per-bar-colors="true"' \
  "$BARS_GROUPED" || fail "$BARS_GROUPED has no per-bar colors"
bar_fills=$(grep -o 'class="bar"[^>]*fill="[^"]*"' "$BARS_GROUPED" |
  sed -E 's/.*fill="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$bar_fills" -eq 8 ] ||
  fail "$BARS_GROUPED should use eight distinct bar fills"
grouped_edges=$(grep -o 'class="bar"[^>]*stroke="[^"]*"' "$BARS_GROUPED" |
  sed -E 's/.*stroke="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$grouped_edges" -ge 4 ] ||
  fail "$BARS_GROUPED should vary per-series bar edge colors"

# Grouped bars must carry both symmetric and asymmetric error geometry.
BAR_ERRORS=examples/output/bar-errors.svg
grep -q '<g class="series series-bar"[^>]*data-yerr="true"' "$BAR_ERRORS" ||
  fail "$BAR_ERRORS has no bar error metadata"
grep -q 'data-yerr-mode="asymmetric"' "$BAR_ERRORS" ||
  fail "$BAR_ERRORS has no asymmetric bar errors"
bar_rects=$(grep -o 'class="bar"' "$BAR_ERRORS" | wc -l | tr -d ' ')
bar_error_lines=$(grep -o 'class="bar-error"' "$BAR_ERRORS" | wc -l |
  tr -d ' ')
bar_error_caps=$(grep -o 'class="bar-error-cap"' "$BAR_ERRORS" | wc -l |
  tr -d ' ')
[ "$bar_rects" -eq 8 ] ||
  fail "$BAR_ERRORS should draw eight bars"
[ "$bar_error_lines" -eq "$bar_rects" ] ||
  fail "$BAR_ERRORS should draw one error line per bar"
[ "$bar_error_caps" -eq $((bar_rects * 2)) ] ||
  fail "$BAR_ERRORS should draw two caps per bar"
if grep -Eqi 'nan|inf' "$BAR_ERRORS"; then
  fail "$BAR_ERRORS contains non-finite geometry"
fi

# Bar outlines use the requested three-pixel stroke.
BAR_WIDTH=examples/output/bar-linewidth.svg
bar_width_rects=$(grep -o 'class="bar"' "$BAR_WIDTH" | wc -l | tr -d ' ')
[ "$bar_width_rects" -eq 8 ] ||
  fail "$BAR_WIDTH should draw eight bars"
bar_widths=$(grep -o 'class="bar"[^>]*stroke-width="[^"]*"' "$BAR_WIDTH" |
  sed -E 's/.*stroke-width="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$bar_widths" -ge 4 ] ||
  fail "$BAR_WIDTH should use per-bar outline widths"

# Broken horizontal bars expose one rectangle per range and an aligned title.
BROKEN_BARH=examples/output/broken-barh.svg
grep -q 'class="series series-broken-barh"' "$BROKEN_BARH" ||
  fail "$BROKEN_BARH has no broken-bar series"
broken_rects=$(grep -o 'class="broken-barh"' "$BROKEN_BARH" | wc -l |
  tr -d ' ')
[ "$broken_rects" -eq 7 ] ||
  fail "$BROKEN_BARH should draw seven range rectangles"
grep -q 'text-anchor="end">Project schedule</text>' "$BROKEN_BARH" ||
  fail "$BROKEN_BARH should use a right-aligned title"
grep -q 'class="legend"' "$BROKEN_BARH" ||
  fail "$BROKEN_BARH has no legend"

# Exploded pie slices must carry offsets, shadows, and percentage labels.
PIE_EXPLODE=examples/output/pie-explode.svg
grep -q 'data-pie="true"' "$PIE_EXPLODE" ||
  fail "$PIE_EXPLODE is not a pie SVG"
pie_slices=$(grep -o 'class="pie-slice"' "$PIE_EXPLODE" | wc -l | tr -d ' ')
pie_shadows=$(grep -o 'class="pie-shadow"' "$PIE_EXPLODE" | wc -l | tr -d ' ')
[ "$pie_slices" -eq 4 ] && [ "$pie_shadows" -eq 4 ] ||
  fail "$PIE_EXPLODE should draw four slices and four shadows"
grep -q 'data-explode="0"' "$PIE_EXPLODE" ||
  fail "$PIE_EXPLODE should keep at least one slice unshifted"
grep -q 'data-explode="0.12"' "$PIE_EXPLODE" ||
  fail "$PIE_EXPLODE should shift its largest slice"
pie_percent=$(grep -o 'class="pie-percent"' "$PIE_EXPLODE" | wc -l |
  tr -d ' ')
[ "$pie_percent" -eq 4 ] ||
  fail "$PIE_EXPLODE should label every slice percentage"

PIE_ROTATED=examples/output/pie-rotated.svg
grep -q 'data-rotatelabels="true"' "$PIE_ROTATED" ||
  fail "$PIE_ROTATED should rotate its labels"
pie_rotated_labels=$(grep -o 'class="pie-label"[^>]*transform="rotate(' \
  "$PIE_ROTATED" | wc -l | tr -d ' ')
[ "$pie_rotated_labels" -eq 5 ] ||
  fail "$PIE_ROTATED should rotate all five pie labels"
grep -q 'class="pie-slice"[^>]*stroke="#1f2937" stroke-width="1.2"' \
  "$PIE_ROTATED" || fail "$PIE_ROTATED should style its wedge edges"
grep -q 'data-labelsize="14" data-labelcolor="#1f2937" data-pctsize="11" data-pctcolor="#f8fafc"' \
  "$PIE_ROTATED" || fail "$PIE_ROTATED should expose styled slice text"
grep -q 'class="pie-label"[^>]*font-size="14" fill="#1f2937"' "$PIE_ROTATED" ||
  fail "$PIE_ROTATED should style its slice labels"
grep -q 'class="pie-percent"[^>]*font-size="11" fill="#f8fafc"' "$PIE_ROTATED" ||
  fail "$PIE_ROTATED should style its percentage labels"
grep -q 'class="pie-label"[^>]*font-weight="bold"' "$PIE_ROTATED" ||
  fail "$PIE_ROTATED should render bold slice labels"
grep -q 'class="pie-percent"[^>]*font-weight="bold"' "$PIE_ROTATED" ||
  fail "$PIE_ROTATED should render bold percentage labels"

# Counterclockwise pies keep every slice and advance angles upward.
PIE_COUNTER=examples/output/pie-counterclock.svg
grep -q 'data-counterclock="true"' "$PIE_COUNTER" ||
  fail "$PIE_COUNTER should run counterclockwise"
pie_counter_slices=$(grep -o 'class="pie-slice"' "$PIE_COUNTER" | wc -l |
  tr -d ' ')
[ "$pie_counter_slices" -eq 5 ] ||
  fail "$PIE_COUNTER should draw all five slices"
grep -q 'data-alpha="true"' "$PIE_COUNTER" ||
  fail "$PIE_COUNTER should advertise per-slice alpha"
pie_alphas=$(grep -o 'class="pie-slice"[^>]*fill-opacity="[^"]*"' "$PIE_COUNTER" |
  sed -E 's/.*fill-opacity="([^"]*)"/\1/' | sort -u | wc -l | tr -d ' ')
[ "$pie_alphas" -ge 3 ] ||
  fail "$PIE_COUNTER should vary slice opacity"
grep -q 'data-labeldistance="1.14" data-pctdistance="0.55"' "$PIE_EXPLODE" ||
  fail "$PIE_EXPLODE should expose its label and percentage distances"

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
for svg in "$LINE" "$ERRORBAR" "$ECDF" "$AXLINE" "$CONTROLS" "$HIST_H" \
  "$STEM" "$STEM_H" "$QUIVER_CART" "$QUIVER_UV" "$HEXBIN" "$HIST2D" \
  "$SCATTER_COLORS" "$VIOLIN" "$VIOLIN_H" "$STACK_BASELINE" "$BAR_ERRORS" \
  "$STEP_FILL" "$HIST_EDGES" \
  "$BAR_WIDTH" "$BARS_GROUPED" "$BARH_HATCH" "$ANNOTATIONS" "$BROKEN_BARH" \
  "$PIE_EXPLODE" "$PIE_ROTATED" "$PIE_COUNTER" "$HEATMAP_EXTENT" \
  "$CONTOUR_COORDS" \
  "$ASPECT" "$MINOR_SUB" "$EVENT" "$HIST_STYLES" "$BOX_H" "$IMSHOW"; do
  png="${svg%.svg}.png"
  rsvg-convert -z 2 "$svg" -o "$png"
  [ -s "$png" ] || fail "rasterization produced no output for $svg"
  echo "wrote $png"
done
