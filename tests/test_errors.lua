-- Invalid input must fail early with clear luaplotlib-prefixed errors.

local plt = require("luaplotlib")

local function bad(fn, label)
  assert_error("luaplotlib:", fn, label)
end

test("invalid figure options are rejected", function()
  bad(function() plt.figure(640) end, "non-table options")
  bad(function() plt.figure({ width = "640" }) end, "string width")
  bad(function() plt.figure({ width = 0 }) end, "zero width")
  bad(function() plt.figure({ height = -10 }) end, "negative height")
  bad(function() plt.figure({ dpi = 0 }) end, "zero dpi")
  bad(function() plt.figure({ dpi = 0 / 0 }) end, "NaN dpi")
  bad(function() plt.figure({ width = 640, height = 480, colour = "red" }) end,
    "unknown option")
  bad(function() plt.figure({ width = 60, height = 60 }):to_svg() end,
    "too-small canvas")
end)

test("plot rejects malformed data", function()
  local fig = plt.figure()
  bad(function() fig:plot(nil, { 1 }) end, "missing x")
  bad(function() fig:plot({}, {}) end, "empty data")
  bad(function() fig:plot({ 1, 2 }, { 1 }) end, "length mismatch")
  bad(function() fig:plot({ 1, "two" }, { 1, 2 }) end, "non-numeric value")
  bad(function() fig:plot({ 1, 0 / 0 }, { 1, 2 }) end, "NaN value")
  bad(function() fig:plot({ 1, math.huge }, { 1, 2 }) end, "infinite value")
  bad(function() fig:plot({ 1, 2 }, { 1, 2 }, { colour = "red" }) end,
    "unknown series option")
  bad(function() fig:plot({ 1, 2 }, { 1, 2 }, { color = "url(#evil)" }) end,
    "invalid color")
  bad(function() fig:plot({ 1, 2 }, { 1, 2 }, { color = "#12" }) end,
    "short hex color")
  bad(function() fig:plot({ 1, 2 }, { 1, 2 }, { alpha = 2 }) end, "alpha > 1")
  bad(function() fig:plot({ 1, 2 }, { 1, 2 }, { linewidth = -1 }) end,
    "negative linewidth")
  bad(function() fig:plot({ 1, 2 }, { 1, 2 }, { linestyle = "zigzag" }) end,
    "unknown linestyle")
  bad(function() fig:plot({ 1, 2 }, { 1, 2 }, { marker = "square" }) end,
    "unknown marker")
  bad(function() fig:plot({ 1, 2 }, { 1, 2 }, { label = 12 }) end,
    "non-string label")
end)

test("scatter rejects malformed data and options", function()
  local fig = plt.figure()
  bad(function() fig:scatter({ 1, 2 }, { 1 }) end, "length mismatch")
  bad(function() fig:scatter({ 1, 2 }, { 1, 2 }, { size = 0 }) end,
    "zero marker size")
  bad(function() fig:scatter({ 1, 2 }, { 1, 2 }, { markersize = -1 }) end,
    "negative marker size")
  bad(function() fig:scatter({ 1, 2 }, { 1, 2 }, { edgecolor = "not a color" }) end,
    "bad edge color")
  bad(function() fig:scatter({ 1, 2 }, { 1, 2 }, { width = 1 }) end,
    "unknown option")
end)

test("histogram rejects malformed data and options", function()
  local fig = plt.figure()
  bad(function() fig:hist({}) end, "empty histogram")
  bad(function() fig:hist({ 1, 2 }, { bins = 0 }) end, "zero bins")
  bad(function() fig:hist({ 1, 2 }, { bins = 2.5 }) end, "fractional bins")
  bad(function() fig:hist({ 1, 2 }, { bins = 1001 }) end, "too many bins")
  bad(function() fig:hist({ 1, 2 }, { range = { 0 } }) end, "malformed range")
  bad(function() fig:hist({ 1, 2 }, { range = { 2, 2 } }) end, "empty range")
  bad(function() fig:hist({ 1, 2 }, { range = { 0, math.huge } }) end,
    "infinite range")
  bad(function() fig:hist({ 1, 2 }, { range = { 2, 0 } }) end, "reversed range")
  bad(function() fig:hist({ 1, "two" }) end, "non-numeric histogram")
end)

test("bar rejects malformed data and options", function()
  local fig = plt.figure()
  bad(function() fig:bar({ "a" }) end, "missing values")
  bad(function() fig:bar({ "a", "b" }, { 1 }) end, "length mismatch")
  bad(function() fig:bar({ "a", true }, { 1, 2 }) end, "invalid category")
  bad(function() fig:bar({ "a" }, { 0 / 0 }) end, "NaN bar value")
  bad(function() fig:bar({ "a" }, { 1 }, { width = 0 }) end, "zero width")
  bad(function() fig:bar({ "a" }, { 1 }, { width = 1.5 }) end, "width > 1")
  bad(function() fig:bar({ "a" }, { 1 }, { color = "bad color!" }) end,
    "invalid bar color")
  bad(function() fig:bar({ "a", "b" }, { { 1, 2 }, { 3 } }) end,
    "series length mismatch")
  bad(function() fig:bar({ "a", "b" }, { { 1 }, { 2 }, { 3, 4 } }) end,
    "third series length mismatch")
  bad(function() fig:bar({ "a", "b" }, { { 1, 2 }, { 3, 4 } },
    { labels = { "only one" } }) end, "series labels length mismatch")
  bad(function() fig:bar({ "a", "b" }, { { 1, 2 }, { 3, 4 } },
    { label = "ambiguous" }) end, "single label with several series")
  bad(function() fig:bar({ "a" }, { { 1 } }, { stacked = "yes" }) end,
    "non-boolean stacked")
  bad(function() fig:bar({ "a" }, { { 1 } }, { grouped = 1 }) end,
    "non-boolean grouped")
  bad(function() fig:bar({ "a" }, { { 1 } }, { stacked = true, grouped = true }) end,
    "stacked and grouped together")
  bad(function() fig:bar({ "a" }, { { 1 } }, { colors = {} }) end,
    "series colors length mismatch")
end)

test("axis limit validation and bad control arguments", function()
  local fig = plt.figure()
  bad(function() fig:xlim(1) end, "xlim missing maximum")
  bad(function() fig:ylim(1) end, "ylim missing maximum")
  bad(function() fig:xlim(2, 1) end, "reversed xlim")
  bad(function() fig:ylim(1, 1) end, "equal ylim")
  bad(function() fig:xlim(0 / 0, 1) end, "NaN xlim")
  bad(function() fig:ylim(0, math.huge) end, "infinite ylim")
  bad(function() fig:grid("yes") end, "non-boolean grid")
  bad(function() fig:legend({ loc = "middle" }) end, "invalid legend location")
  bad(function() fig:legend({ frame = "yes" }) end, "non-boolean legend frame")
  bad(function() fig:legend({ side = "top" }) end, "unknown legend option")
  bad(function() fig:title(42) end, "non-string title")
  bad(function() fig:xlabel(nil) end, "nil xlabel")
  bad(function() fig:ylabel({}) end, "table ylabel")
end)

test("log scales reject invalid names and non-positive values", function()
  bad(function() plt.figure({ xscale = "log2" }) end, "invalid figure xscale")
  bad(function() plt.figure({ yscale = 10 }) end, "non-string figure yscale")
  bad(function() plt.figure():xscale("symlog") end, "invalid xscale")
  bad(function() plt.figure():yscale(nil) end, "missing yscale")

  assert_error("positive", function()
    plt.figure():xscale("log"):plot({ 0, 1 }, { 1, 2 }):to_svg()
  end, "zero x on log axis")
  assert_error("positive", function()
    plt.figure():xscale("log"):plot({ -1, 1 }, { 1, 2 }):to_svg()
  end, "negative x on log axis")
  assert_error("positive", function()
    plt.figure():yscale("log"):plot({ 1, 2 }, { 1, 0 }):to_svg()
  end, "zero y on log axis")
  assert_error("positive", function()
    plt.figure():yscale("log"):plot({ 1, 2 }, { 1, -5 }):to_svg()
  end, "negative y on log axis")

  assert_error("positive", function()
    plt.figure():xscale("log"):xlim(0, 10):to_svg()
  end, "non-positive xlim on log axis")
  assert_error("positive", function()
    plt.figure():yscale("log"):ylim(-1, 10):to_svg()
  end, "non-positive ylim on log axis")

  assert_error("positive", function()
    plt.figure():xscale("log"):bar({ 0 }, { 1 }):to_svg()
  end, "bar edge at zero on log axis")
end)

test("unsupported tensor shapes fail clearly", function()
  local two_dimensional = setmetatable({}, {
    __index = function(_, key)
      if key == "nDimension" then
        return function() return 2 end
      elseif key == "nElement" then
        return function() return 4 end
      elseif type(key) == "number" then
        return 0
      end
    end,
  })
  local fig = plt.figure()
  bad(function() fig:plot(two_dimensional, { 1, 2, 3, 4 }) end,
    "two-dimensional input")
end)

test("savefig rejects bad paths and unwritable locations", function()
  local fig = plt.figure()
  fig:plot({ 1, 2 }, { 1, 2 })
  bad(function() fig:savefig(123) end, "non-string path")
  bad(function() fig:savefig("") end, "empty path")
  bad(function() fig:savefig(TEST_OUTPUT_DIR .. "/missing-dir/out.svg") end,
    "missing parent directory")
  bad(function() fig:savefig(TEST_OUTPUT_DIR .. "/out.jpg") end,
    "unsupported extension")
  local png_path = TEST_OUTPUT_DIR .. "/auto.png"
  local ok, png_err = pcall(function() fig:savefig(png_path) end)
  os.remove(png_path)
  if not ok then
    assert_true(tostring(png_err):find("rsvg", 1, true) ~= nil,
      "png dispatch should fail only for a missing converter")
  end
end)

test("methods fail on absent figure state without crashing the process", function()
  local fig = plt.figure()
  bad(function() fig:savefig(TEST_OUTPUT_DIR) end, "directory as file")
end)

test("errorbar rejects malformed errors", function()
  local fig = plt.figure()
  bad(function() fig:errorbar({ 1 }, { 1 }, nil) end, "missing yerr")
  bad(function() fig:errorbar({ 1, 2 }, { 1, 2 }, { 1 }) end,
    "yerr length mismatch")
  bad(function() fig:errorbar({ 1 }, { 1 }, -1) end, "negative yerr")
  bad(function() fig:errorbar({ 1 }, { 1 }, { 1 }, { 2, 3 }) end,
    "xerr length mismatch")
end)
