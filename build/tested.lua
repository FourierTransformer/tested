
local assert_table = require("tested.assert_table")

local tested = { tests = {}, run_only_tests = false }

local function validate_options(test_name, options, test_src)
   local error_prefix = test_src .. " in \"" .. test_name .. "\": "
   if options.expected ~= nil then
      if type(options.expected) ~= "string" then
         error(error_prefix .. "options.expected takes in a 'string', but received '" .. type(options.expected) .. "'", 0)
      end
      if not (options.expected == "FAIL" or options.expected == "EXCEPTION" or options.expected == "UNKNOWN") then
         error(error_prefix .. "options.expected should be one of 'FAIL', 'EXCEPTION', or 'UNKNOWN'", 0)
      end
   end

   if options.run_when ~= nil then
      if type(options.run_when) ~= "boolean" then
         error(error_prefix .. "options.run_when takes in a 'boolean', but received '" .. type(options.run_when) .. "'", 0)
      end
   end
end

local function extract_fn_and_options(test_name, fn_or_options, fn, test_src)
   local options = {}
   if type(fn_or_options) == "function" then
      fn = fn_or_options

   elseif type(fn_or_options) == "table" then
      options = fn_or_options
      if not fn then error("a function must be provided to run a unit test") end
      fn = fn
   end

   validate_options(test_name, options, test_src or "?")

   return fn, options
end


function tested.test(name, fn_or_options, fn)
   local test_src = debug.getinfo(2, "S").short_src
   local func, options = extract_fn_and_options(name, fn_or_options, fn, test_src)
   table.insert(tested.tests, { name = name, fn = func, options = options, kind = "test" })
end

function tested.skip(name, fn_or_options, fn)
   local test_src = debug.getinfo(2, "S").short_src
   local func, options = extract_fn_and_options(name, fn_or_options, fn, test_src)
   table.insert(tested.tests, { name = name, fn = func, options = options, kind = "skip" })
end

function tested.only(name, fn_or_options, fn)
   local test_src = debug.getinfo(2, "S").short_src
   local func, options = extract_fn_and_options(name, fn_or_options, fn, test_src)
   table.insert(tested.tests, { name = name, fn = func, options = options, kind = "only" })
end

function tested.before(fn)
   tested.before_fn = fn
end

function tested.after(fn)
   tested.after_fn = fn
end

function tested.before_each(fn)
   tested.before_each_fn = fn
end

function tested.after_each(fn)
   tested.after_each_fn = fn
end

function tested.assert(assertion)
   local errors = {}
   if assertion.expected == nil then table.insert(errors, "'expected'") end
   if assertion.actual == nil then table.insert(errors, "'actual'") end
   if #errors ~= 0 then error("The assertion table must include 'expected' and 'actual' whose values cannot be 'nil'. Missing (or 'nil') fields: " .. table.concat(errors, ", "), 0) end
   if assertion.given and type(assertion.given) ~= "string" then
      table.insert(errors, "In assertion, 'given' should be a 'string'. It appears to be a '" .. type(assertion.given) .. "' with value: '" .. tostring(assertion.given))
   end
   if assertion.should and type(assertion.should) ~= "string" then
      table.insert(errors, "In assertion, 'should' should be a 'string'. It appears to be a '" .. type(assertion.should) .. "' with value: " .. tostring(assertion.should))
   end
   if #errors ~= 0 then error(table.concat(errors, ". "), 0) end
   local expected_type = type(assertion.expected)
   local actual_type = type(assertion.actual)

   if actual_type ~= expected_type then
      return false, "Actual: " .. tostring(assertion.actual) .. " (as '" ..
      actual_type .. "'). Expected: " .. tostring(assertion.expected) .. " (as '" .. expected_type .. "')"
   end



   if actual_type == "table" and expected_type == "table" then
      return assert_table(assertion.expected, assertion.actual)
   end

   if assertion.actual == assertion.expected then
      return true, ""
   end

   return false, "Actual: " .. tostring(assertion.actual) .. "\nExpected: " .. tostring(assertion.expected)
end

function tested.assert_truthy(assertion)
   return tested.assert({ given = assertion.given, should = assertion.should or "be truthy", expected = true, actual = (not not (assertion.actual)) })
end

function tested.assert_falsy(assertion)
   return tested.assert({ given = assertion.given, should = assertion.should or "be falsy", expected = false, actual = (not not (assertion.actual)) })
end

function tested.assert_throws_exception(assertion)
   if assertion.expected then
      local function wrapped_pcall()
         local ok, err = pcall(function() assertion.actual() end)
         if type(err) == "string" then
            return { ok, err:match(" (.-)$") }
         else
            return { ok, err }
         end
      end

      return tested.assert({
         given = assertion.given,
         should = assertion.should or "throw exception with error message",
         expected = { false, assertion.expected },
         actual = wrapped_pcall(),
      })
   else
      return tested.assert({
         given = assertion.given,
         should = assertion.should or "throw exception",
         expected = false,
         actual = pcall(function() assertion.actual() end),
      })
   end
end

local function fisher_yates_shuffle(t)
   for i = #t, 2, -1 do
      local j = math.random(i)
      t[i], t[j] = t[j], t[i]
   end
end

local function should_skip_test(test, run_only, options)
   if run_only and test.kind ~= "only" then
      return "SKIP", "Only running 'tested.only' tests"
   elseif test.kind == "skip" then
      return "SKIP", "Test marked with 'tested.skip'"
   elseif options and options.filter ~= nil and not string.find(test.name, options.filter) then
      return "CONDITIONAL_SKIP", "Test name does not match filter pattern '" .. options.filter .. "'"
   elseif test.options.run_when ~= nil and test.options.run_when == false then
      return "CONDITIONAL_SKIP", "Condition in `tested.conditional_skip` returned false. Skipping test."
   end
   return nil, nil
end

local function set_result(ok, err, total_assertions, assert_failed_count, test_output)
   if ok == false then
      test_output.result = "EXCEPTION"
      test_output.message = err

   elseif total_assertions == 0 then
      test_output.result = "UNKNOWN"
      test_output.message = "No assertions run during test"

   elseif assert_failed_count == 0 then
      test_output.result = "PASS"
      test_output.message = "All assertions have passed"

   else
      test_output.result = "FAIL"
      test_output.message = assert_failed_count .. " assertions have failed"
   end
end

local function adjust_for_expected(expected, test_output)
   if expected ~= nil then
      if test_output.result == expected then
         if expected == "EXCEPTION" then
            test_output.result = "EXPECTED_EXCEPTION"
         elseif expected == "UNKNOWN" then
            test_output.result = "EXPECTED_UNKNOWN"
         elseif expected == "FAIL" then
            test_output.result = "EXPECTED_FAIL"
         end
      else
         test_output.message = "Expected test result to be " .. expected .. ", but came back as " .. test_output.result .. "\n" .. test_output.message
         test_output.result = "UNEXPECTED"
      end
   end
end

local function add_up_test_results(test_output, test_counts)
   if test_output.result == "PASS" then
      test_counts.passed = test_counts.passed + 1

   elseif test_output.result == "FAIL" then
      test_counts.failed = test_counts.failed + 1

   elseif test_output.result == "EXPECTED_FAIL" or test_output.result == "EXPECTED_EXCEPTION" or test_output.result == "EXPECTED_UNKNOWN" then
      test_counts.expected = test_counts.expected + 1

   elseif test_output.result == "EXCEPTION" or test_output.result == "UNKNOWN" or test_output.result == "UNEXPECTED" then
      test_counts.invalid = test_counts.invalid + 1

   elseif test_output.result == "SKIP" or test_output.result == "CONDITIONAL_SKIP" then
      test_counts.skipped = test_counts.skipped + 1

   end
end


function tested:run(filename, options)
   if options and options.random then
      math.randomseed(os.time())
      fisher_yates_shuffle(self.tests)
   end

   if self.run_only_tests then
      print("Only running tests with 'tested.only'")
   end

   local test_results = {
      counts = { passed = 0, failed = 0, expected = 0, skipped = 0, invalid = 0 },
      tests = {},
      filename = filename,
      fully_tested = false,
      total_time = 0,
   }

   if tested.before_fn then
      tested.before_fn()
   end

   local function xpcall_handler(e)
      local msg = type(e) == "string" and (e) or tostring(e)
      return msg .. debug.traceback("", 2)
   end

   for i, test in ipairs(self.tests) do

      test_results.tests[i] = { assertion_results = {}, name = test.name }

      local skip_result, skip_message = should_skip_test(test, self.run_only_tests, options)
      if skip_result then
         test_results.tests[i].result = skip_result
         test_results.tests[i].message = skip_message
         test_results.tests[i].time = 0

      else
         if tested.before_each_fn then
            tested.before_each_fn()
         end

         local assert_failed_count = 0
         local total_assertions = 0


         local original_assert = self.assert
         self.assert = function(assertion)
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


         local original_os_exit = os.exit
         os.exit = function(code)
            local prefix = "os.exit()"
            if code then prefix = "os.exit(" .. tostring(code) .. ")" end
            error(prefix .. " intercepted — something tried to exit out of the process", 0)
         end


         local start = os.clock()
         local ok, err = xpcall(test.fn, xpcall_handler)
         test_results.tests[i].time = os.clock() - start
         test_results.total_time = test_results.total_time + test_results.tests[i].time


         self.assert = original_assert
         os.exit = original_os_exit

         set_result(ok, err, total_assertions, assert_failed_count, test_results.tests[i])


         adjust_for_expected(test.options.expected, test_results.tests[i])

         if tested.after_each_fn then
            tested.after_each_fn()
         end
      end


      add_up_test_results(test_results.tests[i], test_results.counts)
   end
   if test_results.counts.failed == 0 and test_results.counts.invalid == 0 then
      test_results.fully_tested = true
   end

   if tested.after_fn then
      tested.after_fn()
   end

   return test_results
end

return tested
