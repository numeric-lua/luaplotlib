-- luaplotlib test runner.
--
-- Run from the repository root:
--   luajit tests/run.lua
--   ./scripts/test.sh
--
-- The suite is dependency-free and inspects generated SVG as strings. It does
-- not load luatorch, numlua, or any image library.

local script = (arg and arg[0]) or "tests/run.lua"
script = script:gsub("\\", "/")
local prefix = script:match("^(.*)/tests/run%.lua$")
local root = prefix
if root == nil or root == "" then
  root = "."
end

package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

local total = 0
local passed = 0
local failed = 0
local failures = {}
local current_file = "?"

local function show(value)
  if type(value) == "string" then
    return string.format("%q", value)
  end
  return tostring(value)
end

function assert_true(condition, message)
  if not condition then
    error(message or "expected a truthy value", 2)
  end
end

function assert_false(condition, message)
  if condition then
    error(message or "expected a falsy value", 2)
  end
end

function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s",
      message or "values differ", show(expected), show(actual)), 2)
  end
end

function assert_contains(haystack, needle, message)
  if type(haystack) ~= "string" or not haystack:find(needle, 1, true) then
    error((message or "expected text to be present: ") .. show(needle), 2)
  end
end

function assert_not_contains(haystack, needle, message)
  if type(haystack) == "string" and haystack:find(needle, 1, true) then
    error((message or "expected text to be absent: ") .. show(needle), 2)
  end
end

function assert_match(haystack, pattern, message)
  if type(haystack) ~= "string" or not haystack:match(pattern) then
    error(string.format("%s: %s did not match pattern %q",
      message or "pattern mismatch", show(haystack), pattern), 2)
  end
end

function assert_error(pattern, fn, message)
  local ok, err = pcall(fn)
  if ok then
    error((message or "expected an error") .. ", but the call succeeded", 2)
  end
  err = tostring(err)
  if not err:find(pattern) then
    error(string.format("%s: error %s did not match pattern %q",
      message or "unexpected error text", show(err), pattern), 2)
  end
end

function count_occurrences(text, needle)
  local count = 0
  local start_at = 1
  while true do
    local found = text:find(needle, start_at, true)
    if not found then
      break
    end
    count = count + 1
    start_at = found + #needle
  end
  return count
end

-- A small XML well-formedness check tailored to generated SVG. This is not a
-- full XML parser, but it catches mismatched tags, unbalanced roots, and
-- unescaped ampersands without external tools.
function assert_well_formed_svg(svg)
  assert_true(svg:match("^<%?xml") ~= nil, "missing XML declaration")
  assert_true(svg:sub(-1) == "\n", "generated SVG should end with a newline")
  assert_true(svg:sub(-7) == "</svg>\n", "generated SVG should close its root")

  local stack = {}
  local position = 1
  local roots = 0
  while true do
    local lt = svg:find("<", position, true)
    if not lt then
      break
    end
    local gt = svg:find(">", lt, true)
    assert_true(gt ~= nil, "unterminated XML tag")
    local raw = svg:sub(lt + 1, gt - 1)
    local first = raw:sub(1, 1)

    if first == "?" or first == "!" then
      -- XML declaration, doctype, or comment.
    else
      local closing = first == "/"
      local self_closing = raw:sub(-1) == "/"
      local name
      if closing then
        name = raw:match("^/%s*([%w:_%-%.]+)")
      else
        name = raw:match("^%s*([%w:_%-%.]+)")
      end
      assert_true(name ~= nil, "could not parse tag name from <" .. raw .. ">")
      if closing then
        assert_true(#stack > 0, "closing tag without an open element: " .. name)
        assert_equal(stack[#stack], name, "mismatched closing tag")
        stack[#stack] = nil
      else
        if #stack == 0 then
          roots = roots + 1
          assert_equal(name, "svg", "document root must be svg")
        end
        if not self_closing then
          stack[#stack + 1] = name
        end
      end
    end
    position = gt + 1
  end

  assert_equal(#stack, 0, "unclosed XML elements")
  assert_equal(roots, 1, "expected exactly one SVG root")

  local without_entities = svg
  without_entities = without_entities:gsub("&amp;", "")
  without_entities = without_entities:gsub("&lt;", "")
  without_entities = without_entities:gsub("&gt;", "")
  without_entities = without_entities:gsub("&quot;", "")
  without_entities = without_entities:gsub("&apos;", "")
  assert_not_contains(without_entities, "&", "unescaped XML ampersand")

  assert_not_contains(svg, "<script", "SVG must not contain scripts")
  assert_not_contains(svg, "href=", "SVG must be standalone (no external hrefs)")
end

function test(name, fn)
  total = total + 1
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    io.write(".")
  else
    failed = failed + 1
    io.write("F")
    failures[#failures + 1] = string.format("[%s] %s\n  %s",
      current_file, name, tostring(err):gsub("\n", "\n  "))
  end
  io.flush()
end

local output_dir = root .. "/tests/output"
local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end
os.execute("mkdir -p " .. shell_quote(output_dir))
TEST_OUTPUT_DIR = output_dir

local test_files = {
  "test_api.lua",
  "test_series.lua",
  "test_svg.lua",
  "test_scene.lua",
  "test_annotations.lua",
  "test_errors.lua",
  "test_subplots.lua",
  "test_heatmap.lua",
  "test_boxplot.lua",
  "test_contour.lua",
  "test_ticks.lua",
  "test_bar_polish.lua",
  "test_barh.lua",
  "test_date_html.lua",
  "test_tensor_matrix.lua",
  "test_twin.lua",
  "test_pie.lua",
  "test_polar.lua",
  "test_polar_polish.lua",
  "test_polar_heatmap.lua",
  "test_polar_annotations.lua",
  "test_polar_contour.lua",
  "test_polar_colorbar.lua",
  "test_polar_quiver.lua",
  "test_polar_streamplot.lua",
  "test_cartesian_isolation.lua",
  "test_polar_text.lua",
  "test_area_step_stem.lua",
  "test_errorbar_asymmetric.lua",
  "test_axline.lua",
  "test_markevery.lua",
  "test_tick_rotation.lua",
  "test_minorticks.lua",
  "test_reference_spans.lua",
  "test_grid_style.lua",
  "test_fill_where.lua",
  "test_hist_orientation.lua",
  "test_stem_style.lua",
  "test_twiny.lua",
  "test_style.lua",
  "test_axes3d.lua",
  "test_quiver.lua",
  "test_hexbin.lua",
  "test_hist2d.lua",
  "test_scatter_colors.lua",
  "test_violinplot.lua",
  "test_stack_baseline.lua",
  "test_bar_errors.lua",
  "test_field_coordinates.lua",
  "test_aspect.lua",
  "test_minor_subdivisions.lua",
  "test_eventplot_layout.lua",
  "test_hist_styles.lua",
  "test_boxplot_orientation.lua",
  "test_imshow_colorbar.lua",
  "test_eventplot_colors.lua",
  "test_boxplot_means.lua",
  "test_violin_means.lua",
  "test_bar_linewidth.lua",
  "test_imshow_alpha.lua",
  "test_broken_barh.lua",
  "test_eventplot_labels.lua",
  "test_pie_explode.lua",
  "test_hist_linewidth.lua",
  "test_title_loc.lua",
  "test_legend_layout.lua",
  "test_legend_frame.lua",
  "test_errorbar_errorevery.lua",
  "test_marker_style.lua",
  "test_ecdf_complementary.lua",
  "test_bar_multicolor.lua",
  "test_annotation_background.lua",
  "test_labelpad.lua",
  "test_pie_distances.lua",
  "test_hist2d_empty.lua",
  "test_scatter_markers.lua",
  "test_annotation_rotation.lua",
  "test_error_stem_markers.lua",
  "test_eventplot_linestyle.lua",
  "test_barh_hatch.lua",
  "test_stem_horizontal.lua",
  "test_scatter_alpha.lua",
  "test_quiver_angles.lua",
  "test_tick_style.lua",
  "test_hist_hatch.lua",
  "test_violin_horizontal.lua",
  "test_pie_rotatelabels.lua",
  "test_fill_hatch.lua",
  "test_span_hatch.lua",
  "test_title_style.lua",
  "test_pie_edge.lua",
  "test_scatter_edgecolors.lua",
  "test_errorbar_limits.lua",
  "test_step_fill.lua",
  "test_hist_edges.lua",
  "test_axis_label_style.lua",
  "test_legend_spacing.lua",
  "test_errorbar_xlimits.lua",
  "test_scatter_linewidths.lua",
  "test_hexbin_norm.lua",
  "test_hist2d_lognorm.lua",
  "test_pie_label_style.lua",
  "test_quiver_colors.lua",
  "test_boxplot_notch.lua",
  "test_eventplot_eventcolors.lua",
  "test_export.lua",
}

print("luaplotlib test suite")
for _, file in ipairs(test_files) do
  current_file = file
  print("  " .. file)
  local path = root .. "/tests/" .. file
  local ok, err = pcall(dofile, path)
  if not ok then
    failed = failed + 1
    total = total + 1
    io.write("F")
    failures[#failures + 1] = string.format("[%s] unable to load test file\n  %s",
      file, tostring(err):gsub("\n", "\n  "))
  end
end
io.write("\n")

if #failures > 0 then
  io.write("\nfailures:\n")
  for i, failure in ipairs(failures) do
    io.write(string.format("%d. %s\n", i, failure))
  end
end

io.write(string.format("\n%d tests, %d passed, %d failed\n", total, passed, failed))
if failed > 0 then
  os.exit(1)
end
os.exit(0)
