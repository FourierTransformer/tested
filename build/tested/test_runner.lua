local tested_types = require("tested.tested_types")
local Tested, Assertion = tested_types.Tested, tested_types.Assertion





local TestRunner = {}






















local TestOutput = {}






local function fisher_yates_shuffle(t)
   for i = #t, 2, -1 do
      local j = math.random(i)
      t[i], t[j] = t[j], t[i]
   end
end

function TestRunner.run(tested, options)
   if options and options.randomize then
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
         test_results[i].result = "CONDITIONAL_SKIP"
         test_results[i].message = "Condition in `tested.conditional_skip` returned false. Skipping test."

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

         local ok, err = pcall(test.fn)
         if ok == false then
            test_results[i].result = "EXCEPTION"
            test_results[i].message = err


         elseif total_assertions == 0 then
            test_results[i].result = "UNKNOWN"
            test_results[i].message = "No assertions run during the test"

         elseif assert_failed_count == 0 then
            test_results[i].result = "PASS"
            test_results[i].message = "All assertions have passed"

         else
            test_results[i].result = "FAIL"
            test_results[i].message = assert_failed_count .. " assertions have failed"
         end
      end
   end
   return test_results
end

return { TestRunner = TestRunner, TestResult = TestResult, TestOutput = TestOutput }
