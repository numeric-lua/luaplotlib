# luaplotlib 0.2.0

Pure-Lua, dependency-free SVG plotting.

## Highlights

- `fig:errorbar(x, y, yerr[, xerr][, options])`;
- symmetric vertical and horizontal error bars with configurable caps and
  error-line styling;
- error-bar geometry included in the renderer-agnostic scene IR;
- 59 tests, including SVG structure, scene export, and invalid-input paths;
- first LuaRocks release.

The 0.1 feature set remains: line, scatter, histogram, and bar charts; linear
and logarithmic axes; automatic ranges/ticks; labels, legend, and grid; scene
export for non-SVG backends.

## Requirements

- LuaJIT 2.1 (also smoke-tested with PUC Lua 5.5)
- no runtime dependencies

## Install

```sh
luarocks --lua-version=5.1 install luaplotlib
```

## Verification

- 59 tests passed;
- CI green.
