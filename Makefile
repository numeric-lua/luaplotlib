# luaplotlib development targets. No build step is required.

LUA ?= luajit

.PHONY: all test examples clean

all: test

test:
	@LUA="$(LUA)" ./scripts/test.sh

examples:
	@$(LUA) examples/line.lua
	@$(LUA) examples/histogram.lua

clean:
	@rm -rf -- examples/output tests/output
