# luaplotlib development targets. No build step is required.

LUA ?= luajit

.PHONY: all test examples visual-qa clean

all: test

test:
	@LUA="$(LUA)" ./scripts/test.sh

examples:
	@$(LUA) examples/line.lua
	@$(LUA) examples/histogram.lua
	@$(LUA) examples/errorbar.lua
	@$(LUA) examples/ecdf_complementary.lua
	@$(LUA) examples/annotations.lua
	@$(LUA) examples/axline.lua
	@$(LUA) examples/cartesian_controls.lua
	@$(LUA) examples/histogram_horizontal.lua
	@$(LUA) examples/stem.lua
	@$(LUA) examples/stem_horizontal.lua
	@$(LUA) examples/quiver.lua
	@$(LUA) examples/quiver_uv.lua
	@$(LUA) examples/hexbin.lua
	@$(LUA) examples/hist2d.lua
	@$(LUA) examples/scatter_colors.lua
	@$(LUA) examples/violinplot.lua
	@$(LUA) examples/violin_horizontal.lua
	@$(LUA) examples/stack_baseline.lua
	@$(LUA) examples/bar_errors.lua
	@$(LUA) examples/bar_linewidth.lua
	@$(LUA) examples/barh_hatch.lua
	@$(LUA) examples/broken_barh.lua
	@$(LUA) examples/pie_explode.lua
	@$(LUA) examples/pie_rotated.lua
	@$(LUA) examples/field_coordinates.lua
	@$(LUA) examples/aspect.lua
	@$(LUA) examples/minor_subdivisions.lua
	@$(LUA) examples/eventplot_layout.lua
	@$(LUA) examples/hist_styles.lua
	@$(LUA) examples/boxplot_horizontal.lua
	@$(LUA) examples/imshow_colorbar.lua
	@$(LUA) examples/bars.lua
	@$(LUA) examples/polar.lua
	@$(LUA) examples/polar_bars.lua
	@$(LUA) examples/polar_annotations.lua
	@$(LUA) examples/polar_heatmap.lua
	@$(LUA) examples/polar_contour.lua
	@$(LUA) examples/polar_quiver.lua
	@$(LUA) examples/polar_streamplot.lua

visual-qa:
	@./scripts/visual-qa.sh

clean:
	@rm -rf -- examples/output tests/output
