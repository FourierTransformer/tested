
local assert_table = require("tested.assert_table")
local inspect = require("tested.libs.inspect")
local shared = require("tested.libs.shared")

local tested_class = {}
local tested = {}

local options_set = { tags = true, expected = true, run_when = true, retries = true, retry_delay = true }


function tested_class.new(filename)
   if filename == nil then
      filename = debug.getinfo(2, "S").short_src
   end

   local self = {
      tests = {},
      run_only_tests = false,
      filename = filename,
   }
   setmetatable(self, { __index = tested })

   return self
end

function tested_class.assert(assertion)
   local errors = {}
   if assertion.expected == nil then table.insert(errors, "In assertion table, 'expected' is currently 'nil'.") end
   if assertion.actual == nil then table.insert(errors, "In assertion table, 'actual' is currently 'nil'.") end
   if #errors ~= 0 then return false, table.concat(errors, "\n") .. "\nCannot perform comparisons with 'nil' - use 'tested.assert_nil' for 'nil' comparison." end
   if assertion.given and type(assertion.given) ~= "string" then
      table.insert(errors, "In assertion table, 'given' should be a 'string'. It appears to be a '" .. type(assertion.given) .. "' with value: '" .. tostring(assertion.given) .. "'.")
   end
   if assertion.should and type(assertion.should) ~= "string" then
      table.insert(errors, "In assertion table, 'should' should be a 'string'. It appears to be a '" .. type(assertion.should) .. "' with value: " .. tostring(assertion.should) .. "'.")
   end
   if #errors ~= 0 then return false, table.concat(errors, "\n") end
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


function tested_class.assert_nil(assertion)
   assertion.should = assertion.should or "be nil"
   if assertion.actual == nil then
      return true, ""
   end

   return false, "Actual: " .. tostring(assertion.actual) .. "\nExpected: nil"
end

function tested_class.assert_truthy(assertion)
   return tested_class.assert({ given = assertion.given, should = assertion.should or "be truthy", expected = true, actual = (not not (assertion.actual)), debug_var = assertion.debug_var })
end

function tested_class.assert_falsy(assertion)
   return tested_class.assert({ given = assertion.given, should = assertion.should or "be falsy", expected = false, actual = (not not (assertion.actual)), debug_var = assertion.debug_var })
end

function tested_class.assert_throws_exception(assertion)
   if assertion.expected then
      local function wrapped_pcall()
         local ok, err = pcall(function() assertion.actual() end)
         if type(err) == "string" then
            return { ok, err:match("^.+:%d+: (.+)$") or err }
         else
            return { ok, err }
         end
      end

      return tested_class.assert({
         given = assertion.given,
         should = assertion.should or "throw exception with error message",
         expected = { false, assertion.expected },
         actual = wrapped_pcall(),
         debug_var = assertion.debug_var,
      })
   else
      return tested_class.assert({
         given = assertion.given,
         should = assertion.should or "throw exception",
         expected = false,
         actual = pcall(function() assertion.actual() end),
         debug_var = assertion.debug_var,
      })
   end
end




local tested_object_call_error = "on your tested object ensure you are calling ':test' and not '.test'"

local function validate_options(test_name, options, filename)
   local error_prefix = filename .. " in \"" .. test_name .. "\": "

   for k, _ in pairs(options) do
      if not options_set[k] then
         error(error_prefix .. "options includes unknown value '" .. k .. "'. Options must be one of: " .. "'tags', 'expected', 'run_when', 'retries', or 'retry_delay'")
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
      for i, tag in ipairs(options.tags) do
         if type(tag) ~= "string" then
            error(error_prefix .. "options.tags[" .. i .. "] should be a 'string', but received '" .. type(tag) .. "'", 0)
         end
         if tag == "and" or tag == "or" or tag == "not" then
            error(error_prefix .. "options.tags[" .. i .. "] appears to be a reserved keyword: 'and', 'or', or 'not'. Please change to a different tag name", 0)
         end
      end
   end

   if options.retries ~= nil then
      if type(options.retries) ~= "number" or (options.retries) ~= math.floor(options.retries) or (options.retries) < 0 then
         error(error_prefix .. "options.retries takes in a non-negative integer, but received '" .. tostring(options.retries) .. "'", 0)
      end
   end

   if options.retry_delay ~= nil then
      if type(options.retry_delay) ~= "number" or (options.retry_delay) < 0 then
         error(error_prefix .. "options.retry_delay takes in a non-negative number, but received '" .. tostring(options.retry_delay) .. "'", 0)
      end
   end
end

local function extract_fn_and_options(test_name, fn_or_options, fn, filename)
   local options = {}
   if type(fn_or_options) == "function" then
      fn = fn_or_options

   elseif type(fn_or_options) == "table" then
      options = fn_or_options
      if not fn then error("a function must be provided to run a unit test") end
      fn = fn
   end

   validate_options(test_name, options, filename)

   return fn, options
end


function tested:test(name, fn_or_options, fn)
   assert(type(self) == "table", tested_object_call_error)
   local func, options = extract_fn_and_options(name, fn_or_options, fn, self.filename)
   table.insert(self.tests, { name = name, fn = func, options = options, kind = "test" })
end

function tested:skip(name, fn_or_options, fn)
   assert(type(self) == "table", tested_object_call_error)
   local func, options = extract_fn_and_options(name, fn_or_options, fn, self.filename)
   table.insert(self.tests, { name = name, fn = func, options = options, kind = "skip" })
end

function tested:only(name, fn_or_options, fn)
   assert(type(self) == "table", tested_object_call_error)
   local func, options = extract_fn_and_options(name, fn_or_options, fn, self.filename)
   table.insert(self.tests, { name = name, fn = func, options = options, kind = "only" })
   self.run_only_tests = true
end

function tested:before(fn)
   assert(type(self) == "table", tested_object_call_error)
   self.before_fn = fn
end

function tested:after(fn)
   assert(type(self) == "table", tested_object_call_error)
   self.after_fn = fn
end

function tested:before_each(fn)
   assert(type(self) == "table", tested_object_call_error)
   self.before_each_fn = fn
end

function tested:after_each(fn)
   assert(type(self) == "table", tested_object_call_error)
   self.after_each_fn = fn
end

local function should_skip_test(test, run_only, options)
   if run_only and test.kind ~= "only" then
      return "SKIP", "Only running 'tested:only' tests"

   elseif test.kind == "skip" then
      return "SKIP", "Test marked with 'tested:skip'"

   elseif test.options.run_when ~= nil and test.options.run_when == false then
      return "SKIP", "Condition in `run_when` returned false. Skipping test."

   elseif options and options.filter ~= nil and not string.find(test.name, options.filter) then
      return "FILTERED", "Test name does not match filter pattern '" .. options.filter .. "'"

   elseif options and options.tags_filter ~= nil then

      local tag_set = {}
      if test.options.tags then
         for _, tag in ipairs(test.options.tags) do tag_set[tag] = true end
      end

      if not options.tags_filter(tag_set) then
         return "FILTERED", "Test tags do not match tag filter expression"
      end
   end
   return nil, nil
end

local function captured_os_exit(code)
   local prefix = "os.exit()"
   if code then prefix = "os.exit(" .. tostring(code) .. ")" end
   error(prefix .. " intercepted — something tried to exit out of the process", 0)
end






local function wrap_assert(self, test_output)
   local original_assert = tested_class.assert
   local original_assert_nil = tested_class.assert_nil
   local counters = { total = 0, failed = 0 }

   local function record_result(ok, err, assertion, line_number)
      counters.total = counters.total + 1
      local assertion_result = {
         filename = self.filename,
         line_number = line_number,
         given = assertion.given,
         should = assertion.should,
      }
      if ok == false then
         counters.failed = counters.failed + 1
         assertion_result.result = "FAIL"
         assertion_result.error_message = err
         if assertion.debug_var ~= nil then
            if type(assertion.debug_var) == "table" then
               assertion_result.error_message = "debug_var: " .. inspect.inspect(assertion.debug_var, {})
            else
               assertion_result.error_message = "debug_var: " .. tostring(assertion.debug_var)
            end
         end
      else
         assertion_result.result = "PASS"
      end
      table.insert(test_output.assertion_results, assertion_result)
   end

   tested_class.assert = function(assertion)
      local ok, err = original_assert(assertion)
      record_result(ok, err, assertion, debug.getinfo(2, "l").currentline)
      return ok, err
   end

   tested_class.assert_nil = function(assertion)
      local ok, err = original_assert_nil(assertion)
      record_result(ok, err, assertion, debug.getinfo(2, "l").currentline)
      return ok, err
   end

   local function restore()
      tested_class.assert = original_assert
      tested_class.assert_nil = original_assert_nil
   end

   return counters, restore
end


local function swap_os_exit(test_fn)
   local original_os_exit
   if _VERSION == "Lua 5.1" then

      original_os_exit = getfenv(test_fn).os.exit
      getfenv(test_fn).os.exit = captured_os_exit
   else
      original_os_exit = os.exit
      os.exit = captured_os_exit
   end
   return original_os_exit
end

local function xpcall_handler(e)
   local msg = type(e) == "string" and (e) or tostring(e)
   return msg .. debug.traceback("", 2)
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

local function restore_os_exit(test_fn, original)
   if _VERSION == "Lua 5.1" then
      getfenv(test_fn).os.exit = original
   else
      os.exit = original
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

   elseif test_output.result == "SKIP" then
      test_counts.skipped = test_counts.skipped + 1

   elseif test_output.result == "FILTERED" then
      test_counts.filtered = test_counts.filtered + 1

   end
end

local function run_test(self, test, test_output)
   if self.before_each_fn then self.before_each_fn() end

   local assertions, restore = wrap_assert(self, test_output)
   local original_os_exit = swap_os_exit(test.fn)

   local ok, err = xpcall(test.fn, xpcall_handler)
   set_result(ok, err, assertions.total, assertions.failed, test_output)

   restore_os_exit(test.fn, original_os_exit)
   restore()


   adjust_for_expected(test.options.expected, test_output)

   if self.after_each_fn then self.after_each_fn() end
end

local function convert_to_test_options(options)
   local test_options
   if options then
      test_options = {
         random = options.random,
         filter = options.filter,
         clock_s = options.clock_s or os.clock,
         sleep_s = options.sleep_s or shared.blocking_sleep,
      }
      if options.tags then test_options.tags_filter = shared.create_tags_function(options.tags) end
   else
      test_options = {
         clock_s = os.clock,
         sleep_s = shared.blocking_sleep,
      }
   end
   return test_options
end

function tested:_run(options, filename)
   if options and options.random then
      math.randomseed(os.time())
      shared.fisher_yates_shuffle(self.tests)
   end

   local test_results = {
      counts = { passed = 0, failed = 0, expected = 0, skipped = 0, filtered = 0, invalid = 0 },
      tests = {},


      filename = filename or self.filename,
      fully_tested = false,
      total_time = 0,
   }

   if self.before_fn then self.before_fn() end

   for i, test in ipairs(self.tests) do

      local retry_attempts = {}


      local test_result = { assertion_results = {}, name = test.name, options = test.options }

      local skip_result, skip_message = should_skip_test(test, self.run_only_tests, options)
      local start = options.clock_s()

      if skip_result then
         test_result.result = skip_result
         test_result.message = skip_message

      else
         run_test(self, test, test_result)

      end

      test_result.time = options.clock_s() - start

      local result = test_result.result
      local is_passing = result == "PASS" or result == "EXPECTED_FAIL" or result == "EXPECTED_EXCEPTION" or result == "EXPECTED_UNKNOWN"


      local retry_count = 0
      if test.options.retries and not skip_result and not is_passing and test.options.retries > 0 then
         while retry_count < test.options.retries do
            table.insert(retry_attempts, test_result)
            retry_count = retry_count + 1
            if test.options.retry_delay and options.sleep_s then
               options.sleep_s(test.options.retry_delay)
            end
            test_result = { assertion_results = {}, name = test.name, options = test.options }
            run_test(self, test, test_result)
         end
      end


      if retry_count > 0 then
         test_result.time = (options.clock_s() - start)
      end


      add_up_test_results(test_result, test_results.counts)


      test_result.retry_attempts = retry_attempts
      test_results.tests[i] = test_result
      test_results.total_time = test_results.total_time + test_result.time
   end

   if self.after_fn then self.after_fn() end

   if test_results.counts.failed == 0 and test_results.counts.invalid == 0 then
      test_results.fully_tested = true
   end

   return test_results
end

function tested:run(options, filename)
   assert(type(self) == "table", tested_object_call_error)
   local test_options = convert_to_test_options(options)
   return self:_run(test_options, filename)
end

function tested_class.run_tests(tests, options)
   local test_options = convert_to_test_options(options)

   local tests_output = {}
   if options and options.random then shared.fisher_yates_shuffle(tests) end
   for i, test in ipairs(tests) do
      tests_output[i] = test:_run(test_options)
   end

   return shared.combine_results(tests_output)
end

function tested_class.combine_results(tests_output)
   return shared.combine_results(tests_output)
end

function tested_class.format_results(tested_output, display_format, show)
   display_format = display_format or "plain"
   local formatter = require("tested.results." .. display_format)


   if not show then
      show = { "fail", "exception", "unknown", "unexpected" }
   end
   local show_all = false
   for _, display_option in ipairs(show) do if display_option == "all" then show_all = true; break end end
   if show_all then show = { "skip", "pass", "fail", "exception", "unknown", "expected", "unexpected" } end
   local to_display = shared.display_types(show)

   local output = {}

   output[1] = formatter.header(shared.version .. " (bundle)", {}, {})

   for i, test_result in ipairs(tested_output.module_results) do
      output[i + 1] = formatter.results(test_result, to_display)
   end

   table.insert(output, formatter.summary(tested_output))
   return table.concat(output)
end

return tested_class
