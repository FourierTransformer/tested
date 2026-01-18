





local TestRunner = {}



local function fisher_yates_shuffle(t)
   for i = #t, 2, -1 do
      local j = math.random(i)
      t[i], t[j] = t[j], t[i]
   end
end

function TestRunner.run(filename, tested, options)
   if options and options.randomize then
      math.randomseed(os.time())
      fisher_yates_shuffle(tested.tests)
   end

   if tested.run_only_tests then
      print("Only running tests with 'tested.only'")
   end

   local test_results = {
      counts = { passed = 0, failed = 0, skipped = 0, invalid = 0 },
      tests = {},
      filename = filename,
      fully_tested = false,
      total_time = 0,
   }


   for i, test in ipairs(tested.tests) do

      test_results.tests[i] = { assertion_results = {}, name = test.name }

      if tested.run_only_tests and test.kind ~= "only" then
         test_results.tests[i].result = "SKIP"
         test_results.tests[i].message = "Only running 'tested.only' tests"
         test_results.tests[i].time = 0
         test_results.counts.skipped = test_results.counts.skipped + 1

      elseif test.kind == "skip" then
         test_results.tests[i].result = "SKIP"
         test_results.tests[i].message = "Test marked with 'tested.skip'"
         test_results.tests[i].time = 0
         test_results.counts.skipped = test_results.counts.skipped + 1

      elseif test.kind == "conditional_skip" then
         test_results.tests[i].result = "CONDITIONAL_SKIP"
         test_results.tests[i].message = "Condition in `tested.conditional_skip` returned false. Skipping test."
         test_results.tests[i].time = 0
         test_results.counts.skipped = test_results.counts.skipped + 1

      else
         local assert_failed_count = 0
         local total_assertions = 0


         local original_assert = tested.assert
         tested.assert = function(assertion)
            local ok, err = original_assert(assertion)

            total_assertions = total_assertions + 1

            local assertion_result = {}
            local file_info = debug.getinfo(2, "Sl")
            assertion_result.filename = file_info.short_src
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
            table.insert(test_results.tests[i].assertion_results, assertion_result)

            return ok, err
         end

         local start = os.clock()
         local ok, err = pcall(test.fn)
         test_results.tests[i].time = os.clock() - start
         test_results.total_time = test_results.total_time + test_results.tests[i].time
         tested.assert = original_assert

         if ok == false then
            test_results.tests[i].result = "EXCEPTION"
            test_results.tests[i].message = err .. "\n" .. debug.traceback()
            test_results.counts.invalid = test_results.counts.invalid + 1

         elseif total_assertions == 0 then
            test_results.tests[i].result = "UNKNOWN"
            test_results.tests[i].message = "No assertions run during the test"
            test_results.counts.invalid = test_results.counts.invalid + 1

         elseif assert_failed_count == 0 then
            test_results.tests[i].result = "PASS"
            test_results.tests[i].message = "All assertions have passed"
            test_results.counts.passed = test_results.counts.passed + 1

         else
            test_results.tests[i].result = "FAIL"
            test_results.tests[i].message = assert_failed_count .. " assertions have failed"
            test_results.counts.failed = test_results.counts.failed + 1
         end
      end
   end
   if test_results.counts.failed == 0 and test_results.counts.invalid == 0 then
      test_results.fully_tested = true
   end
   return test_results
end

function TestRunner.run_tests(test_modules, options)

   local output = {
      total_time = 0,
      all_fully_tested = true,
      total_counts = { passed = 0, failed = 0, skipped = 0, invalid = 0 },
      module_results = {},
   }

   local i = 0

   return function()
      i = i + 1
      if i > #test_modules then
         return nil, output
      end

      local module = test_modules[i]


      local pre_test_loaded_packages = {}
      for package_name, _ in pairs(package.loaded) do pre_test_loaded_packages[package_name] = true end

      local test_module = require(module)
      assert(type(test_module) == "table" and type(test_module.tests) == "table" and type(test_module.run_only_tests) == "boolean", "It does not appear that '" .. module .. "' returns the 'tested' module")

      local test_output = TestRunner.run(module, test_module, options)


      for package_name, _ in pairs(package.loaded) do
         if not pre_test_loaded_packages[package_name] then
            package.loaded[package_name] = nil
            collectgarbage()
         end
      end
      collectgarbage()

      output.module_results[i] = test_output

      if test_output.fully_tested == false then output.all_fully_tested = false end
      output.total_counts.passed = output.total_counts.passed + test_output.counts.passed
      output.total_counts.failed = output.total_counts.failed + test_output.counts.failed
      output.total_counts.skipped = output.total_counts.skipped + test_output.counts.skipped
      output.total_counts.invalid = output.total_counts.invalid + test_output.counts.invalid
      output.total_time = output.total_time + test_output.total_time

      return test_output, output
   end

end

return TestRunner
