# luaplotlib 4.28.0

This release adds five additive renderer/API features. Existing Cartesian APIs
remain compatible, polar rendering is unchanged, and there are no new runtime
dependencies.

- **More legend locations.** Cartesian and polar legends now accept
  `upper center`, `lower center`, `center left`, `center right`, and `center`
  in addition to the four corners and `best`.
- **Legend frame styling.** `fig:legend` accepts `framealpha`, `facecolor`, and
  `edgecolor`, defaulting to the existing translucent white frame. Scene export
  carries the resolved style.
- **Error-bar decimation.** `fig:errorbar` accepts `errorevery`, keeping the
  full line and marker series while drawing error bars at every Nth point.
  Metadata and scene export report the stride.
- **Marker face and edge styling.** `fig:plot` accepts `markerfacecolor`,
  `markeredgecolor`, and `markeredgewidth` for filled marker shapes.
- **Complementary ECDFs.** `fig:ecdf(..., { complementary = true })` plots
  `1 - F_n(x)` with the same post-step geometry and exports the mode.

Examples: new `examples/ecdf_complementary.lua`; the line and error-bar
examples demonstrate styled markers/legend frames and decimated errors. `make
examples` and `scripts/visual-qa.sh` exercise all five features, then rasterize
the affected examples when `rsvg-convert` is available.

Tests: `./scripts/test.sh` runs 410 dependency-free tests, all passing.
