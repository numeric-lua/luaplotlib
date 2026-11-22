local plt = require("luaplotlib")

local function cap_y_values(svg)
  local values = {}
  for value in svg:gmatch('class="errorbar%-cap"[^>]-y1="([^"]+)"') do
    values[#values + 1] = value
  end
  table.sort(values, function(a, b) return tonumber(a) < tonumber(b) end)
  return values
end

local function cap_x_values(svg)
  local values = {}
  for value in svg:gmatch('class="errorbar%-cap"[^>]-x1="([^"]+)"') do
    values[#values + 1] = value
  end
  table.sort(values, function(a, b) return tonumber(a) < tonumber(b) end)
  return values
end

local function single_errorbar(yerr, xerr, opts)
  local fig = plt.figure({ width = 600, height = 400 })
  fig:errorbar({ 1 }, { 10 }, yerr, xerr, opts or {
    marker = false,
    capsize = 4,
  })
  fig:xlim(0, 2)
  fig:ylim(0, 15)
  return fig:to_svg()
end

test("asymmetric yerr uses independent lower and upper extents", function()
  local asymmetric = single_errorbar({ lower = { 1 }, upper = { 3 } })
  assert_contains(asymmetric, 'data-yerr-mode="asymmetric"')
  local symmetric_lower = cap_y_values(single_errorbar(1))
  local symmetric_upper = cap_y_values(single_errorbar(3))
  local actual = cap_y_values(asymmetric)
  assert_equal(#actual, 2, "asymmetric yerr should draw two caps")
  assert_equal(actual[1], symmetric_upper[1],
    "upper cap should match a symmetric error of 3")
  assert_equal(actual[2], symmetric_lower[2],
    "lower cap should match a symmetric error of 1")
end)

test("asymmetric errors accept scalar, pair, and named forms", function()
  local named = single_errorbar({ lower = 1, upper = 3 })
  local pair = single_errorbar({ { 1 }, { 3 } })
  assert_equal(cap_y_values(named)[1], cap_y_values(pair)[1],
    "named and two-sequence yerr forms should agree")
  assert_contains(pair, 'data-yerr-mode="asymmetric"')
end)

test("asymmetric xerr works in the four-argument form", function()
  local fig = plt.figure({ width = 600, height = 400 })
  fig:errorbar({ 5 }, { 10 }, { lower = 1, upper = 3 },
    { lower = 1, upper = 2 }, { marker = false })
  fig:xlim(0, 10)
  fig:ylim(0, 15)
  local svg = fig:to_svg()
  assert_contains(svg, 'data-xerr-mode="asymmetric"')
  assert_contains(svg, 'data-yerr-mode="asymmetric"')

  local symmetric = plt.figure({ width = 600, height = 400 })
  symmetric:errorbar({ 5 }, { 10 }, { 1 }, { 1 }, { marker = false })
  symmetric:xlim(0, 10)
  symmetric:ylim(0, 15)
  assert_equal(cap_x_values(svg)[1], cap_x_values(symmetric:to_svg())[1],
    "left cap should use the lower xerr")
end)

test("scene export preserves asymmetric error arrays", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2 }, { 5, 6 }, {
    lower = { 1, 2 },
    upper = { 3, 4 },
  }, {
    lower = { 0.1, 0.2 },
    upper = { 0.3, 0.4 },
  })
  local scene = fig:to_scene()
  local series = scene.series[1]
  assert_equal(series.kind, "errorbar", "scene series kind")
  assert_equal(series.yerr_lower[1], 1, "scene lower yerr")
  assert_equal(series.yerr_upper[1], 3, "scene upper yerr")
  assert_equal(series.yerr[1], 3, "legacy yerr field tracks the upper side")
  assert_equal(series.yerr_asymmetric, true, "scene asymmetric flag")
  assert_equal(series.xerr_lower[2], 0.2, "scene lower xerr")
  assert_equal(series.xerr_upper[2], 0.4, "scene upper xerr")
  assert_true(scene.ylim[1] < 4, "scene ylim should include the lower extent")
  assert_true(scene.ylim[2] > 10, "scene ylim should include the upper extent")
end)

test("symmetric error bars remain unchanged", function()
  local fig = plt.figure()
  fig:errorbar({ 1, 2 }, { 3, 4 }, 0.5, { label = "plain" })
  local svg = fig:to_svg()
  assert_not_contains(svg, "data-yerr-mode", "symmetric yerr metadata")
  assert_not_contains(svg, "data-xerr-mode", "symmetric xerr metadata")
  assert_contains(svg, 'data-label="plain"')
  local scene = fig:to_scene()
  assert_equal(scene.series[1].yerr_lower[1], 0.5, "symmetric lower scene value")
  assert_equal(scene.series[1].yerr_upper[1], 0.5, "symmetric upper scene value")
  assert_equal(scene.series[1].yerr_asymmetric, nil, "symmetric scene flag")
end)

test("asymmetric error input is validated", function()
  local fig = plt.figure()
  assert_error("requires both lower and upper", function()
    fig:errorbar({ 1 }, { 1 }, { lower = 1 })
  end)
  assert_error("same length", function()
    fig:errorbar({ 1, 2 }, { 1, 2 }, { lower = { 1 }, upper = { 2, 3 } })
  end)
  assert_error("non%-negative", function()
    fig:errorbar({ 1 }, { 1 }, { lower = { -0.1 }, upper = { 1 } })
  end)
  assert_error("not both", function()
    fig:errorbar({ 1 }, { 1 }, { lower = { 1 }, upper = { 1 }, { 1 } })
  end)
  assert_error("exactly two sequences", function()
    fig:errorbar({ 1 }, { 1 }, { { 1 }, { 2 }, { 3 } })
  end)
  assert_error("must be a number", function()
    fig:errorbar({ 1 }, { 1 }, "wide")
  end)
  assert_error("requires both lower and upper", function()
    fig:errorbar({ 1 }, { 1 }, 1, { lower = 1 })
  end)
end)
