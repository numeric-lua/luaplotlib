# luaplotlib 0.4.0

Pure-Lua, matplotlib-inspired SVG plotting.

## Highlights

- grid subplots with nested axes figures, configurable gap/margin, parent title,
  and explicit shared limits;
- heatmaps (`imshow`) with a viridis-like colorbar;
- box-and-whisker plots with outliers;
- marching-squares contour lines;
- rotated x tick labels for crowded categorical axes;
- 85 tests.

## Notes

Each subplot is an independent Figure rendered into a parent SVG grid. Shared
limits are opt-in with `subplot:share_limits("x" or "y"[, index])`. The layout is
adaptive, not a full text-measurement engine.

## Install

```sh
luarocks --lua-version=5.1 install luaplotlib
```
