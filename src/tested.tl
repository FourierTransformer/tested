local type types = require("tested.types")
local assert_table = require("tested.assert_table")

local tested: types.Tested = { tests = {}, run_only_tests = false }

function tested.test(name: string, fn: function())
   table.insert(tested.tests, {name=name, fn=fn, kind="test"})
end

function tested.skip(name: string, fn: function())
   table.insert(tested.tests, {name=name, fn=fn, kind="skip"})
end

function tested.only(name: string, fn: function())
   tested.run_only_tests = true
   table.insert(tested.tests, {name=name, fn=fn, kind="only"})
end

function tested.conditional_test(name: string, condition: boolean, fn: function())
   if condition then
      table.insert(tested.tests, {name=name, fn=fn, kind="conditional_test"})
   else
      table.insert(tested.tests, {name=name, fn=fn, kind="conditional_skip"})
   end
end


function tested.assert<T>(assertion: types.Assertion<T>): boolean, string
   local errors = {}
   if assertion.expected == nil then table.insert(errors, "'expected'") end
   if assertion.actual == nil then table.insert(errors, "'actual'") end
   assert(#errors == 0, "The assertion table must include 'expected' and 'actual'. Missing: " .. table.concat(errors, ", "))
   if assertion.given and type(assertion.given) ~= "string" then 
      table.insert(errors, "In assertion, 'given' should be a 'string'. It appears to be a '" .. type(assertion.given) .. "' with value: '" .. tostring(assertion.given))
   end
   if assertion.should and type(assertion.should) ~= "string" then
      table.insert(errors, "In assertion, 'should' should be a 'string'. It appears to be a '" .. type(assertion.should) .. "' with value: " .. tostring(assertion.should))
   end
   assert(#errors == 0, table.concat(errors, ". "))
   local expected_type = type(assertion.expected)
   local actual_type = type(assertion.actual)
   
   if actual_type ~= expected_type then
      return false, "Actual: " .. tostring(assertion.actual) .. " (as '" .. 
      actual_type .."'). Expected: " .. tostring(assertion.expected) .. " (as '" .. expected_type .. "')"
   end

   if assertion.actual == assertion.expected then
      return true, ""
   end

   if actual_type == "table" and expected_type == "table" then
      return assert_table(assertion.expected as table, assertion.actual as table)
   end

   return false, "Actual: " .. tostring(assertion.actual) .. "\nExpected: " .. tostring(assertion.expected)
end

function tested.assert_truthy(assertion: types.TruthyAssertion): boolean, string
   return tested.assert({given=assertion.given, should=assertion.should or "be truthy", expected=true, actual=(not not (assertion.actual)) })
end

function tested.assert_falsy(assertion: types.FalsyAssertion): boolean, string
   return tested.assert({given=assertion.given, should=assertion.should or "be falsy", expected=false, actual=(not not (assertion.actual)) })
end

function tested.assert_throws_exception(assertion: types.ExceptionAssertion): boolean, string
   if assertion.expected then
      local function wrapped_pcall(): {boolean, string | any}
         local ok, err: boolean, string | any = pcall(function() assertion.actual() end)
         if err is string then
            return {ok, err:match(" (.-)$")}
         else
            return {ok, err}
         end
      end

      return tested.assert({
         given=assertion.given,
         should=assertion.should or "throw exception with error message",
         expected={false, assertion.expected}, 
         actual=wrapped_pcall()
      })
   else
      return tested.assert({
         given=assertion.given,
         should=assertion.should or "throw exception",
         expected=false, 
         actual=pcall(function() assertion.actual() end) 
      })
   end
end

local function fisher_yates_shuffle(t: {any})
   for i = #t, 2, -1 do
      local j = math.random(i)
      t[i], t[j] = t[j], t[i]
   end
end

-- moved in here for hopes of one day being able to run a test from here directly
function tested:run(filename: string, options: types.TestRunnerOptions): types.TestedOutput
   if options and options.random then
      math.randomseed(os.time())
      fisher_yates_shuffle(self.tests)
   end

   if self.run_only_tests then
      print("Only running tests with 'tested.only'")
   end

   local test_results: types.TestedOutput = {
      counts = {passed=0, failed=0, skipped=0, invalid=0}, 
      tests = {}, 
      filename = filename,
      fully_tested = false,
      total_time = 0
   }

   for i, test in ipairs(self.tests) do

      test_results.tests[i] = {assertion_results = {}, name = test.name}

      if self.run_only_tests and test.kind ~= "only" then
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

         -- wrap the original assert so we can do some handling here
         local original_assert = self.assert
         self.assert = function<T>(assertion: types.Assertion<T>): boolean, string
            local ok, err = original_assert(assertion)

            total_assertions = total_assertions + 1

            local assertion_result: types.AssertionResult = {}
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
         local ok, err = pcall(test.fn) as (boolean, string)
         test_results.tests[i].time = os.clock() - start
         test_results.total_time = test_results.total_time + test_results.tests[i].time
         self.assert = original_assert

         if ok == false then
            test_results.tests[i].result = "EXCEPTION"
            test_results.tests[i].message = err .. "\n" .. debug.traceback()
            test_results.counts.invalid = test_results.counts.invalid + 1

         elseif total_assertions == 0 then
            test_results.tests[i].result = "UNKNOWN"
            test_results.tests[i].message = "No assertions run during test"
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

return tested
