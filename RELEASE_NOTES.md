# luaplotlib 0.8.0

Pure-Lua, matplotlib-inspired SVG/HTML plotting.

## Highlights

- date-formatted x axes (`fig:xdate("%Y-%m-%d")`);
- standalone HTML export (`fig:to_html`, `fig:save_html`);
- `imshow` accepts 2-D tensor-like objects through `totable()`;
- 95 tests.

The 0.7 surface remains: horizontal/vertical bars, subplots, heatmaps,
boxplots, contours, custom ticks, log axes, and scene export.

## Install

```sh
luarocks --lua-version=5.1 install luaplotlib
```
