

local types = require("tested.types")


local shared = {}







local cli_to_display = {
   ["skip"] = "SKIP",
   ["pass"] = "PASS",
   ["fail"] = "FAIL",
   ["exception"] = "EXCEPTION",
   ["unknown"] = "UNKNOWN",
   ["unexpected"] = "UNEXPECTED",

}

shared.version = "tested v0.5.0"

shared.blocking_sleep = function(s) local end_time = os.clock() + s; repeat until os.clock() > end_time end

function shared.create_tags_function(tags)
   if tags:match("[^a-zA-Z0-9_ ()]") then
      error("Invalid --tags expression: only letters, digits, underscores, spaces, and parentheses are allowed", 0)
   end
   local lua_expr = (tags:gsub("([a-zA-Z_][a-zA-Z0-9_]*)", function(word)
      if word == "and" or word == "or" or word == "not" then return word end
      return 'tags["' .. word .. '"]'
   end))
   local tag_filter = "local tags = ... \nreturn " .. lua_expr


   local string_loader = loadstring or load
   local loaded = string_loader(tag_filter)
   if not loaded then
      error("Invalid --tags expression '" .. tags .. "': Be sure to use boolean expressions ('or', 'and', 'not', etc) when combining tags", 0)
   end
   return loaded
end

function shared.display_types(options)
   local to_display = {}
   for _, cli_option in ipairs(options) do
      if cli_to_display[cli_option] then
         to_display[cli_to_display[cli_option]] = true
         if cli_option == "skip" then
            to_display["SKIP"] = true
         end
      else
         if cli_option == "invalid" then
            to_display["EXCEPTION"] = true
            to_display["UNKNOWN"] = true
            to_display["TIMEOUT"] = true
            to_display["UNEXPECTED"] = true
         elseif cli_option == "valid" then
            to_display["PASS"] = true
            to_display["SKIP"] = true
            to_display["FILTERED"] = true
            to_display["FAIL"] = true
            to_display["EXPECTED_FAIL"] = true
            to_display["EXPECTED_EXCEPTION"] = true
            to_display["EXPECTED_UNKNOWN"] = true
         elseif cli_option == "expected" then
            to_display["EXPECTED_FAIL"] = true
            to_display["EXPECTED_EXCEPTION"] = true
            to_display["EXPECTED_UNKNOWN"] = true
         end
      end
   end
   return to_display
end

function shared.combine_results(tests_output)
   local output = {
      total_time = 0,
      total_tests = 0,
      all_fully_tested = true,
      total_counts = { passed = 0, failed = 0, expected = 0, skipped = 0, filtered = 0, invalid = 0 },
      module_results = {},
   }

   for i, test_output in ipairs(tests_output) do
      output.module_results[i] = test_output

      if test_output.fully_tested == false then output.all_fully_tested = false end
      output.total_counts.passed = output.total_counts.passed + test_output.counts.passed
      output.total_counts.failed = output.total_counts.failed + test_output.counts.failed
      output.total_counts.expected = output.total_counts.expected + test_output.counts.expected
      output.total_counts.skipped = output.total_counts.skipped + test_output.counts.skipped
      output.total_counts.filtered = output.total_counts.filtered + test_output.counts.filtered
      output.total_counts.invalid = output.total_counts.invalid + test_output.counts.invalid
      output.total_time = output.total_time + test_output.total_time
      output.total_tests = output.total_tests + #test_output.tests
   end

   return output
end

return shared
