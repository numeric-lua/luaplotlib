# luaplotlib development targets. No build step is required.

LUA ?= luajit

.PHONY: all test examples clean

all: test

test:
	@LUA="$(LUA)" ./scripts/test.sh

examples:
	@$(LUA) examples/line.lua
	@$(LUA) examples/histogram.lua
	@$(LUA) examples/errorbar.lua
	@$(LUA) examples/annotations.lua
	@$(LUA) examples/bars.lua
	@$(LUA) examples/polar.lua
	@$(LUA) examples/polar_bars.lua
	@$(LUA) examples/polar_annotations.lua

clean:
	@rm -rf -- examples/output tests/output
