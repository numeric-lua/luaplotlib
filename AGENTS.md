# AGENTS.md

Local instructions for coding agents working in `luaplotlib`. The
organization-wide rules in the parent `../AGENTS.md` still apply, but this file
has the repository-specific details.

## Scope

- Pure-Lua, dependency-free, matplotlib-inspired plotting with a text SVG
  backend.
- Target LuaJIT 2.1. The core path must keep working with plain Lua tables.
- No external Lua rocks, C/FFI dependencies, GUI toolkits, image libraries,
  network calls, or runtime font/asset downloads.
- Optional luatorch and numlua interop must remain duck-typed and optional; do
  not require either library from `luaplotlib.lua` or the core rendering path.
- Keep the public API documented in `README.md` and `docs/api.md`.

## Commands

Run from the repository root:

```sh
./scripts/test.sh          # canonical dependency-free test command
luajit tests/run.lua       # same suite directly
make test                  # same suite via Makefile
make examples              # write ignored SVGs under examples/output/
make clean                 # remove examples/output/ and tests/output/
```

`LUA=/path/to/luajit ./scripts/test.sh` selects another interpreter. The test
suite must never require luatorch, numlua, xmllint, Python, or image tools.

## Rules

- **Do not run `git commit`, `git push`, `git tag`, or any release/publish
  command** unless the coordinator asks. Leave changes uncommitted for review.
- **Do not create the GitHub organization, open pull requests, publish a rock,
  create a release, or change repository visibility.** Those are coordinator
  actions.
- **No network access** is needed for development or tests; do not add network
  dependencies.
- **Do not modify sibling repositories** such as `../luatorch`, `../numlua`, or
  `../numeric-lua-agents`. Read them only for API compatibility when needed.
- Keep generated SVGs and scratch output under `examples/output/`,
  `tests/output/`, or another gitignored path. Never commit generated plots,
  binaries, logs, or caches.
- Add or update a test for every behavior change, including error paths. Run
  the canonical test command before reporting completion.
- Do not add secrets, credentials, personal tokens, or machine-specific paths
  to source, tests, examples, docs, or commits.
- Keep SVG text XML-escaped and the document standalone. No `<script>`, no
  external `href`, and no unescaped user text.
- Keep the Lua-facing indexing and labels 1-based, matching the numeric-lua
  convention.

## Reporting handoffs

Report files changed, the exact test command and result, known limitations, and
any uncommitted changes. Do not include raw secrets or environment dumps.
