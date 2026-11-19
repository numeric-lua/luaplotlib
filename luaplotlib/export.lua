-- Optional raster/PDF export.  Uses rsvg-convert when available; the SVG path
-- remains dependency-free.
local M = {}
local function converter()
  local ok = os.execute("command -v rsvg-convert >/dev/null 2>&1")
  return ok == 0 or ok == true
end
local function convert(svg, path, format)
  if not converter() then
    error("luaplotlib: " .. format .. " export requires rsvg-convert on PATH", 3)
  end
  local tmp = os.tmpname() .. ".svg"
  local f = assert(io.open(tmp, "wb")); f:write(svg); f:close()
  local cmd = string.format("rsvg-convert -f %s -o '%s' '%s' 2>/dev/null",
    format, path:gsub("'", "'\\''"), tmp:gsub("'", "'\\''"))
  local status = os.execute(cmd)
  os.remove(tmp)
  if status ~= 0 and status ~= true then
    error("luaplotlib: rsvg-convert failed for " .. format, 3)
  end
  return path
end
function M.png(svg, path) return convert(svg, path, "png") end
function M.pdf(svg, path) return convert(svg, path, "pdf") end
return M
