# luaplotlib 1.0.0

Pure-Lua, matplotlib-inspired SVG/HTML plotting.

## Milestone

The documented Lua API is now stable and follows semantic versioning. See
`docs/stability.md`.

## Included surface

- line, scatter, histogram, vertical/horizontal bars, error bars, boxplots,
  heatmaps, contours;
- linear, log, date, and twin y axes;
- subplots, custom ticks/formatters, tick rotation;
- annotations and arrows;
- SVG and standalone HTML output;
- renderer-agnostic scene export, including image/box/contour/barh/twin series.

## Verification

- 99 tests;
- CI green.

## Limits

No pie/donut or 3-D charts, no twin x axes, no PNG/PDF backend, and no full
text-measurement layout engine. These are documented scope limits.

## Install

```sh
luarocks --lua-version=5.1 install luaplotlib
```
