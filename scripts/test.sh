#!/usr/bin/env bash
# Run the dependency-free luaplotlib test suite.
set -euo pipefail

cd "$(dirname "$0")/.."

LUA_BIN="${LUA:-luajit}"
if ! command -v "$LUA_BIN" >/dev/null 2>&1; then
  echo "error: Lua interpreter not found: $LUA_BIN" >&2
  echo "set LUA=/path/to/luajit if it is installed under another name" >&2
  exit 127
fi

exec "$LUA_BIN" tests/run.lua "$@"
