# luaplotlib 4.20.0

- polar streamplot arrow glyphs are clipped directly to the polar circle in
  the SVG geometry, not only by the shared series-layer clip path. Arrow
  triangles are built in screen space, so a large `head` or a late
  `arrow_fraction` can push a vertex beyond the frame; the renderer now
  projects that vertex back onto the circle (with a small inward margin for
  three-decimal coordinate formatting). All streamline path vertices and all
  arrow polygon vertices therefore lie inside the frame, which keeps exported
  paths portable to consumers that ignore SVG clip paths;
- clipping is machine-readable. The streamplot series group adds
  `data-clip="polar-circle"` and `data-clipped-arrow-count`; each
  `polar-streamline` group reports `data-clipped-arrows`, and each
  `polar-stream-arrow` polygon reports `data-clipped`. Normal arrows remain
  byte-for-byte unchanged, while glyphs that needed shortening are marked;
- `to_scene()` mirrors the SVG metadata. Streamplot series add `cols`, `rows`,
  `arrow_count`, `clipped_arrow_count`, and `clip = "polar_circle"`; exported
  lines add `arrow_count` and `clipped_arrows`, and exported arrows add
  `clipped`. Polar legend entries now include `linestyle` when a series
  defines one, so a backend can reconstruct a dashed streamplot swatch.
  Clipping flags describe the rendered luaplotlib frame and fall back to
  unclipped when the canvas is too small to lay out;
- `examples/polar_streamplot.lua` writes a third output,
  `examples/output/polar-streamplot-clip.svg`, a radial field with
  `arrow_fraction = 0.95` and `head = 24` that demonstrates the boundary
  clipping. README and API docs describe the clip contract,
  `scripts/visual-qa.sh` verifies that every streamline and arrow vertex stays
  inside the frame, checks the series/line/arrow clipping counts, and
  rasterizes the new example, and Cartesian isolation tests cover the added
  metadata. The suite has 241 dependency-free tests; there are no Cartesian
  rendering changes and no new runtime dependencies.
