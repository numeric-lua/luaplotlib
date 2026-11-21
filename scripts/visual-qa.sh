#!/usr/bin/env bash
# Render the polar examples and, when available, rasterize them for manual
# visual inspection.  This is a developer QA helper, not part of the
# dependency-free test suite.
set -euo pipefail

cd "$(dirname "$0")/.."

LUA_BIN="${LUA:-luajit}"
if ! command -v "$LUA_BIN" >/dev/null 2>&1; then
  echo "error: Lua interpreter not found: $LUA_BIN" >&2
  exit 127
fi

make examples

for svg in \
  examples/output/polar.svg \
  examples/output/polar-bars.svg \
  examples/output/polar-annotations.svg \
  examples/output/polar-heatmap.svg \
  examples/output/polar-contour.svg
do
  if [ ! -s "$svg" ]; then
    echo "error: missing example output: $svg" >&2
    exit 1
  fi
  if ! grep -q 'data-polar="true"' "$svg"; then
    echo "error: $svg is not a polar SVG" >&2
    exit 1
  fi
done

# The contour example must keep both the projected lines and the colorbar.
if ! grep -q 'class="series series-polar-contour"' \
    examples/output/polar-contour.svg; then
  echo "error: polar-contour.svg has no contour series" >&2
  exit 1
fi
if ! grep -q 'class="polar-colorbar"' examples/output/polar-contour.svg; then
  echo "error: polar-contour.svg has no colorbar" >&2
  exit 1
fi

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "rsvg-convert not found; polar SVGs are in examples/output/"
  exit 0
fi

for svg in \
  examples/output/polar.svg \
  examples/output/polar-bars.svg \
  examples/output/polar-annotations.svg \
  examples/output/polar-heatmap.svg \
  examples/output/polar-contour.svg
do
  png="${svg%.svg}.png"
  rsvg-convert -z 2 "$svg" -o "$png"
  echo "wrote $png"
done
