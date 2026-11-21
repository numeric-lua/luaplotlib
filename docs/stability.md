# API stability and versioning

luaplotlib follows semantic versioning for its documented Lua API.

- **Major** versions may change or remove documented APIs.
- **Minor** versions add chart types, options, and methods without removing
  existing documented behavior.
- **Patch** versions fix rendering, validation, or packaging without changing
  the documented surface.

The public surface is the README plus `docs/api.md`: `plt.figure`,
`plt.subplots`, Figure/SubplotFigure methods, scene export, and the documented
options. Internal modules `luaplotlib.render`, `luaplotlib.ticks`, etc. are
implementation details unless a document names them as public.

## Compatibility policy

- Existing 0.x APIs remain available across minor releases unless a documented
  deprecation says otherwise.
- Deprecated APIs remain functional for one minor release before removal.
- SVG element class names and the scene schema are versioned; backends should
  prefer the scene export over scraping SVG.
- The scene format is `version = 1`; additive fields may appear in minor
  releases. Polar figures set `orientation = "polar"` and store geometry under
  `polar` while Cartesian scenes keep their existing shape. Polar scenes may
also gain additive fields such as `polar.heatmaps` in minor releases.

## Scope

luaplotlib is a dependency-free SVG/HTML plotting library. It does not provide
interactive windows, a full 3-D camera/lighting model, or a full
text-measurement layout engine. Those are documented limits, not accidental
omissions.
