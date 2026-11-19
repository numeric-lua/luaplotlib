local plt = require("luaplotlib")
test("exports PNG and PDF when rsvg-convert is available", function()
  local available = os.execute("command -v rsvg-convert >/dev/null 2>&1")
  if not (available == 0 or available == true) then return end
  local fig = plt.figure({ width = 200, height = 120 }); fig:plot({1,2},{1,2})
  local dir = TMPDIR or "/tmp"
  local png, pdf = dir .. "/luaplotlib-test.png", dir .. "/luaplotlib-test.pdf"
  fig:save_png(png); fig:save_pdf(pdf)
  for _, path in ipairs({png, pdf}) do local f=assert(io.open(path,"rb")); assert(#f:read("*a")>0); f:close(); os.remove(path) end
end)
