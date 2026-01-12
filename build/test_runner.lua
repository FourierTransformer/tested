local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local debug = _tl_compat and _tl_compat.debug or debug; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local os = _tl_compat and _tl_compat.os or os; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local tested_class = require("src.tested_class")
local Tested, _, Assertion = tested_class.Tested, tested_class.Test, tested_class.Assertion


































local test_runner = {}

local function fisher_yates_shuffle(t)
   for i = #t, 2, -1 do
      local j = math.random(i)
      t[i], t[j] = t[j], t[i]
   end
end

function test_runner.run(tested, options)

   if options and options.shuffle then
      math.randomseed(os.time())
      fisher_yates_shuffle(tested.tests)
   end

   if tested.run_only_tests then
      print("Only running tests with 'tested.only'")
   end

   local test_results = {}


   for i, test in ipairs(tested.tests) do

      test_results[i] = { assertion_results = {}, name = test.name }

      if tested.run_only_tests and test.kind ~= "only" then
         test_results[i].result = "SKIP"
         test_results[i].message = "Only running 'tested.only' tests"

      elseif test.kind == "skip" then
         test_results[i].result = "SKIP"
         test_results[i].message = "Test marked with 'tested.skip'"

      elseif test.kind == "conditional_skip" then
         test_results[i].result = "CNDSKIP"
         test_results[i].message = "Test condition returned false. Skipping test."

      else
         local assert_failed_count = 0
         local total_assertions = 0
         local filename = debug.getinfo(2, "S").short_src


         local original_assert = tested.assert
         tested.assert = function(assertion)
            local ok, err = original_assert(assertion)

            total_assertions = total_assertions + 1

            local assertion_result = {}
            local file_info = debug.getinfo(2, "l")
            assertion_result.filename = filename
            assertion_result.line_number = file_info.currentline

            assertion_result.given = assertion.given
            assertion_result.should = assertion.should

            if ok == false then
               assert_failed_count = assert_failed_count + 1
               assertion_result.result = "FAIL"
               assertion_result.error_message = err
            else
               assertion_result.result = "PASS"
            end
            table.insert(test_results[i].assertion_results, assertion_result)

            return ok, err
         end

         local ok, err = pcall(test.fn), string

         if ok == false then

            print("exception", err)

         end

         if total_assertions == 0 then
            test_results[i].result = "UNKNOWN"
            test_results[i].message = "No assertions were specified in the test"

         elseif assert_failed_count == 0 then
            test_results[i].result = "PASS"
            test_results[i].message = "All assertions have passed"

         else
            test_results[i].result = "FAIL"
            test_results[i].message = assert_failed_count .. " assertions have failed"
         end
      end
   end


   for _, test_result in ipairs(test_results) do
      print(test_result.result, test_result.name, test_result.message)
      if test_result.result == "FAIL" then

         for _, assertion_result in ipairs(test_result.assertion_results) do
            if assertion_result.result == "FAIL" then
               print("  ", assertion_result.result, assertion_result.filename .. ":" .. assertion_result.line_number .. " - In '" .. test_result.name .. "' given '" .. assertion_result.given .. "'. Should be '" .. assertion_result.should .. "'")
               print("", assertion_result.error_message)
               print()
            end
         end
      end
   end
end

return test_runner
