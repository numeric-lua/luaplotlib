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
	@$(LUA) examples/annotations.lua
	@$(LUA) examples/axline.lua
	@$(LUA) examples/cartesian_controls.lua
	@$(LUA) examples/histogram_horizontal.lua
	@$(LUA) examples/stem.lua
	@$(LUA) examples/quiver.lua
	@$(LUA) examples/hexbin.lua
	@$(LUA) examples/field_coordinates.lua
	@$(LUA) examples/aspect.lua
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
