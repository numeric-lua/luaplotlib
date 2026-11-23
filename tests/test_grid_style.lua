local plt = require("luaplotlib")

local function attrs(tag)
  local result = {}
  for key, value in tag:gmatch('([%w:-]+)="([^"]*)"') do result[key] = value end
  return result
end

local function grid_groups(svg)
  local major = assert(svg:match('<g class="grid"[^>]*>'))
  local minor = assert(svg:match('<g class="grid%-minor"[^>]*>'))
  return attrs(major), attrs(minor)
end

test("default grid styling keeps the existing major and minor look", function()
  local fig = plt.figure()
  fig:plot({ 1, 2, 3 }, { 1, 3, 2 })
  fig:grid(true, { minor = true })
  local svg = fig:to_svg()
  local major, minor = grid_groups(svg)
  assert_equal(major.stroke, "#d9d9d9")
  assert_equal(major["stroke-width"], "1")
  assert_equal(major["stroke-opacity"], nil, "default major grid is opaque")
  assert_equal(minor.stroke, "#d9d9d9")
  assert_equal(minor["stroke-width"], "0.65")
  assert_equal(minor["stroke-opacity"], "0.6")
end)

test("grid alpha applies to major lines and scales the minor default", function()
  local fig = plt.figure()
  fig:plot({ 1, 2, 3 }, { 1, 3, 2 })
  fig:grid(true, { alpha = 0.5, minor = true })
  local major, minor = grid_groups(fig:to_svg())
  assert_equal(major["stroke-opacity"], "0.5")
  assert_equal(minor["stroke-opacity"], "0.3")
end)

test("minor grid accepts independent color, width, style, and alpha", function()
  local fig = plt.figure()
  fig:plot({ 1, 2, 3 }, { 1, 3, 2 })
  fig:grid(true, {
    color = "#334455",
    linewidth = 2,
    linestyle = "dashed",
    alpha = 0.8,
    minor = true,
    minor_color = "#aabbcc",
    minor_linewidth = 0.25,
    minor_linestyle = "dotted",
    minor_alpha = 0.4,
  })
  local major, minor = grid_groups(fig:to_svg())
  assert_equal(major.stroke, "#334455")
  assert_equal(major["stroke-width"], "2")
  assert_equal(major["stroke-dasharray"], "6 4")
  assert_equal(major["stroke-opacity"], "0.8")
  assert_equal(minor.stroke, "#aabbcc")
  assert_equal(minor["stroke-width"], "0.25")
  assert_equal(minor["stroke-dasharray"], "2 3")
  assert_equal(minor["stroke-opacity"], "0.4")
end)

test("grid scene export resolves major and minor styles", function()
  local fig = plt.figure()
  fig:plot({ 1, 2, 3 }, { 1, 3, 2 })
  fig:grid(true, {
    axis = "x", color = "#112233", linewidth = 1.5, alpha = 0.75,
    minor = true, minor_color = "#445566", minor_linewidth = 0.4,
    minor_linestyle = "dotted", minor_alpha = 0.2,
  })
  local scene = fig:to_scene()
  assert_equal(scene.grid, true)
  assert_equal(scene.minor_grid, true)
  assert_equal(scene.grid_style.axis, "x")
  assert_equal(scene.grid_style.color, "#112233")
  assert_equal(scene.grid_style.linewidth, 1.5)
  assert_equal(scene.grid_style.alpha, 0.75)
  assert_equal(scene.minor_grid_style.color, "#445566")
  assert_equal(scene.minor_grid_style.linewidth, 0.4)
  assert_equal(scene.minor_grid_style.linestyle, "dotted")
  assert_equal(scene.minor_grid_style.alpha, 0.2)

  local derived = plt.figure()
  derived:plot({ 1, 2 }, { 1, 2 })
  derived:grid(true, { color = "#000000", linewidth = 2, minor = true })
  local derived_scene = derived:to_scene()
  assert_equal(derived_scene.minor_grid_style.color, "#000000")
  assert_equal(derived_scene.minor_grid_style.linewidth, 1.3)
  assert_equal(derived_scene.minor_grid_style.alpha, 0.6)
end)

test("grid style validation rejects malformed values", function()
  local fig = plt.figure()
  assert_error("alpha must be <= 1", function()
    fig:grid(true, { alpha = 1.5 })
  end)
  assert_error("minor_alpha must be >= 0", function()
    fig:grid(true, { minor_alpha = -0.1 })
  end)
  assert_error("minor_linewidth must be >= 0", function()
    fig:grid(true, { minor_linewidth = -1 })
  end)
  assert_error("minor_linestyle must be solid, dashed, or dotted", function()
    fig:grid(true, { minor_linestyle = "zigzag" })
  end)
  assert_error("minor_color must be a #RGB", function()
    fig:grid(true, { minor_color = "not a color!" })
  end)
end)
