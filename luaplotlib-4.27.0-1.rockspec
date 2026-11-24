package = "luaplotlib"
version = "4.27.0-1"

source = {
  url = "git+https://github.com/numeric-lua/luaplotlib.git",
  tag = "v4.27.0",
}

description = {
  summary = "Pure-Lua matplotlib-inspired SVG plotting",
  detailed = [[
    Line, scatter with numeric color mapping, histogram, rectangular hist2d,
    violin distributions, bar with error bars, stacked areas with zero/sym/
    wiggle baselines, error-bar, box, heatmap, contour, hexbin, Cartesian
    quiver vector fields, image extents/origins, explicit contour
    coordinate grids, equal or numeric aspect ratios, polar line/scatter/bar/
    error-bar/quiver/heatmap/contour plots, polar heatmap and contour,
    polar quiver vector fields with capped glyph rendering, polar streamplots
    with deterministic RK4 streamline integration, arc-length arrow anchors,
    dashed/dotted or hidden paths, closed-orbit deduplication, periodic
    full-turn fields, bounded line/point caps, polar-circle arrow clipping with
    SVG/scene clip metadata, and seed/arc-length scene metadata, polar colorbar
    with explicit nice ticks, rotated collision-aware contour labels, and
    subplot figures with linear/log axes, measured-text legends, asymmetric
    error bars, clipped axline reference lines, fractional axhline/axvline
    spans, masked fill bands, horizontal histograms, histogram step/stepfilled
    styles, vertical/horizontal event lanes with per-row offsets and lengths,
    styled stems, horizontal boxplots, markevery marker decimation, x/y
    tick-label rotation, configurable minor subdivisions, minor ticks and minor
    grids, image colorbars with explicit ticks, resolved major/minor grid
    styling, and renderer-agnostic scene export. No runtime dependencies.
  ]],
  homepage = "https://github.com/numeric-lua/luaplotlib",
  license = "BSD-3-Clause",
}

dependencies = {
  "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    luaplotlib = "luaplotlib.lua",
    ["luaplotlib.area"] = "luaplotlib/area.lua",
    ["luaplotlib.colors"] = "luaplotlib/colors.lua",
    ["luaplotlib.data"] = "luaplotlib/data.lua",
    ["luaplotlib.figure"] = "luaplotlib/figure.lua",
    ["luaplotlib.grid"] = "luaplotlib/grid.lua",
    ["luaplotlib.markers"] = "luaplotlib/markers.lua",
    ["luaplotlib.polar"] = "luaplotlib/polar.lua",
    ["luaplotlib.render"] = "luaplotlib/render.lua",
    ["luaplotlib.scene"] = "luaplotlib/scene.lua",
    ["luaplotlib.subplots"] = "luaplotlib/subplots.lua",
    ["luaplotlib.text"] = "luaplotlib/text.lua",
    ["luaplotlib.axes3d"] = "luaplotlib/axes3d.lua",
    ["luaplotlib.export"] = "luaplotlib/export.lua",
    ["luaplotlib.ticks"] = "luaplotlib/ticks.lua",
    ["luaplotlib.util"] = "luaplotlib/util.lua",
  },
}
