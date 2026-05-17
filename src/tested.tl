local type types = require("tested.types")
local assert_table = require("tested.assert_table")

local tested: types.Tested = { tests = {}, run_only_tests = false }

local options_set: {string: boolean} = {tags = true, expected = true, run_when = true}

local function validate_options(test_name: string, options: types.TestedOptions, test_src: string)
   local error_prefix = test_src .. " in \"" .. test_name .. "\": "

   for k, _ in pairs(options as {string: any}) do
      if not options_set[k] then
         error(error_prefix .. "options includes unknown value '" .. k .. "'. Options must be one of: " .. "'tags', 'expected', or 'run_when'")
      end
   end

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

   if options.tags ~= nil then
      if type(options.tags) ~= "table" then
         error(error_prefix .. "options.tags takes in a '{string}', but received '" .. type(options.tags) .. "'", 0)
      end
      for i, tag in ipairs(options.tags as {string}) do
         if type(tag) ~= "string" then
            error(error_prefix .. "options.tags[" .. i .. "] should be a 'string', but received '" .. type(tag) .. "'", 0)
         end
         if tag == "and" or tag == "or" or tag == "not" then
            error(error_prefix .. "options.tags[" .. i .. "] appears to be a reserved keyword: 'and', 'or', or 'not'. Please change to a different tag name", 0)
         end
      end
   end
end

local function extract_fn_and_options(test_name: string, fn_or_options: function() | types.TestedOptions, fn?: function(), test_src?: string): function(), types.TestedOptions
   local options: types.TestedOptions = {}
   if type(fn_or_options) == "function" then
      fn = fn_or_options as function()

   elseif type(fn_or_options) == "table" then
      options = fn_or_options as types.TestedOptions
      if not fn then error("a function must be provided to run a unit test") end
      fn = fn
   end

   tested.filename = test_src

   validate_options(test_name, options, test_src or "?")

   return fn, options
end

-- teal currently doesn't support polymorphism, so we gotta kinda handle it ourselves
function tested.test(name: string, fn_or_options: function() | types.TestedOptions, fn?: function())
   local test_src = debug.getinfo(2, "S").short_src
   local func, options = extract_fn_and_options(name, fn_or_options, fn, test_src)
   table.insert(tested.tests, {name=name, fn=func, options=options, kind="test"})
end

function tested.skip(name: string, fn_or_options: function() | types.TestedOptions, fn?: function())
   local test_src = debug.getinfo(2, "S").short_src
   local func, options = extract_fn_and_options(name, fn_or_options, fn, test_src)
   table.insert(tested.tests, {name=name, fn=func, options=options, kind="skip"})
end

function tested.only(name: string, fn_or_options: function() | types.TestedOptions, fn?: function())
   local test_src = debug.getinfo(2, "S").short_src
   local func, options = extract_fn_and_options(name, fn_or_options, fn, test_src)
   table.insert(tested.tests, {name=name, fn=func, options=options, kind="only"})
   tested.run_only_tests = true
end

function tested.before(fn: function())
   tested.before_fn = fn
end

function tested.after(fn: function())
   tested.after_fn = fn
end

function tested.before_each(fn: function())
   tested.before_each_fn = fn
end

function tested.after_each(fn: function())
   tested.after_each_fn = fn
end

function tested.assert<T>(assertion: types.Assertion<T>): boolean, string
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
      actual_type .."'). Expected: " .. tostring(assertion.expected) .. " (as '" .. expected_type .. "')"
   end

   -- perform table comparison first, so we can explicitly handle __eq
   -- as opposed to it being handles in the assertion compare below
   if actual_type == "table" and expected_type == "table" then
      return assert_table(assertion.expected as table, assertion.actual as table)
   end

   if assertion.actual == assertion.expected then
      return true, ""
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
            return {ok, err:match("^.+:%d+: (.+)$") or err}
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

local function should_skip_test(test: types.Test, run_only: boolean, options: types.TestRunnerOptions): types.TestResult, string
   if run_only and test.kind ~= "only" then
      return "SKIP", "Only running 'tested.only' tests"

   elseif test.kind == "skip" then
      return "SKIP", "Test marked with 'tested.skip'"

   elseif test.options.run_when ~= nil and test.options.run_when == false then
      return "SKIP", "Condition in `tested.conditional_skip` returned false. Skipping test."

   elseif options and options.filter ~= nil and not string.find(test.name, options.filter) then
      return "FILTERED", "Test name does not match filter pattern '" .. options.filter .. "'"

   elseif options and options.tags_filter ~= nil then
      -- only need to create if tags have been set
      local tag_set: {string: boolean} = {}
      if test.options.tags then
         for _, tag in ipairs(test.options.tags) do tag_set[tag] = true end
      end

      if not options.tags_filter(tag_set) then
         return "FILTERED", "Test tags do not match tag filter expression"
      end
   end
   return nil, nil  -- not a skip
end

local function captured_os_exit(code: integer | boolean | nil)
   local prefix = "os.exit()"
   if code then prefix = "os.exit(" .. tostring(code) .. ")" end
   error(prefix .. " intercepted — something tried to exit out of the process", 0)
end

local function set_result(ok: boolean, err: string, total_assertions: integer, assert_failed_count: integer, test_output: types.TestOutput)
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

local function adjust_for_expected(expected: types.ExpectedTestResult, test_output: types.TestOutput)
   if expected ~= nil then
      if test_output.result == expected as types.TestResult then
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

local function add_up_test_results(test_output: types.TestOutput, test_counts: types.TestCounts)
   if test_output.result == "PASS" then
      test_counts.passed = test_counts.passed + 1

   elseif test_output.result == "FAIL" then
      test_counts.failed = test_counts.failed + 1

   elseif test_output.result == "EXPECTED_FAIL" or test_output.result == "EXPECTED_EXCEPTION" or test_output.result == "EXPECTED_UNKNOWN" then
      test_counts.expected = test_counts.expected + 1

   elseif test_output.result == "EXCEPTION" or test_output.result == "UNKNOWN" or test_output.result == "UNEXPECTED" then
      test_counts.invalid = test_counts.invalid + 1

   elseif test_output.result == "SKIP" then
      test_counts.skipped = test_counts.skipped + 1

   elseif test_output.result == "FILTERED" then
      test_counts.filtered = test_counts.filtered + 1

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
      counts = {passed=0, failed=0, expected=0, skipped=0, filtered=0, invalid=0},
      tests = {},
      filename = filename,
      fully_tested = false,
      total_time = 0
   }

   if tested.before_fn then
      tested.before_fn()
   end

   local function xpcall_handler(e: any): string
      local msg = type(e) == "string" and (e as string) or tostring(e)
      return msg .. debug.traceback("", 2)
   end

   for i, test in ipairs(self.tests) do

      test_results.tests[i] = {assertion_results = {}, name = test.name, options = test.options}

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

         -- wrap the original assert so we can do some handling here
         local original_assert = self.assert
         self.assert = function<T>(assertion: types.Assertion<T>): boolean, string
            local ok, err = original_assert(assertion)

            total_assertions = total_assertions + 1

            local assertion_result: types.AssertionResult = {}
            local file_info = debug.getinfo(2, "l")
            assertion_result.filename = tested.filename
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

         -- run the test
         local start = os.clock()

         local original_os_exit: function(code: integer | boolean | nil)
         if _VERSION == "Lua 5.1" then
            global getfenv: function(any): {string:{string:function}}
            original_os_exit = getfenv(test.fn).os.exit
            getfenv(test.fn).os.exit = captured_os_exit
         else
            original_os_exit = os.exit
            os.exit = captured_os_exit
         end


         local ok, err = xpcall(test.fn, xpcall_handler) as (boolean, string)
         test_results.tests[i].time = os.clock() - start
         test_results.total_time = test_results.total_time + test_results.tests[i].time

         -- put things back
         self.assert = original_assert

         -- again luajit or lua 5.1
         if _VERSION == "Lua 5.1" then
            getfenv(test.fn).os.exit = original_os_exit
         else
            os.exit = original_os_exit
         end

         set_result(ok, err, total_assertions, assert_failed_count, test_results.tests[i])

         -- only adjust for tests that are run. Otherwise the skips when filtering or tested.skip will trigger
         adjust_for_expected(test.options.expected, test_results.tests[i])

         if tested.after_each_fn then
            tested.after_each_fn()
         end
      end

      -- always add up at the end!
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
