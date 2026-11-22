#!/usr/bin/env bash
# Render the examples and inspect the polar output structurally, then
# rasterize the polar SVGs for manual visual inspection when rsvg-convert is
# available.  This is a developer QA helper, not part of the dependency-free
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

# Cartesian examples must stay Cartesian: no polar marker, no polar layer.
for svg in \
  examples/output/line.svg \
  examples/output/histogram.svg \
  examples/output/errorbar.svg \
  examples/output/annotations.svg \
  examples/output/bars-grouped.svg \
  examples/output/bars-stacked.svg
do
  [ -s "$svg" ] || fail "missing cartesian example output: $svg"
  grep -q 'class="background"' "$svg" || fail "$svg has no figure background"
  if grep -q 'data-polar="true"' "$svg"; then
    fail "$svg unexpectedly contains polar output"
  fi
done

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
