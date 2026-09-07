-- exporting all the shared types

local record types

   -- file loader
   interface FileLoader
      load_file: function(filepath: string): any
      loader: {string: function(filepath: string): function()}
      setups: {string: function}
   end

   enum DisplayType
      "none"
      "plain"
      "terminal"
      "tap"
   end

   -- test running types
   interface TestOptions
      display: DisplayType
      random: boolean
      filter: string
      tags_filter: function(tags: {string:boolean}): boolean
      clock_s: function(): number
      sleep_s: function(seconds: number)
   end

   interface TestRunnerOptions
      coverage: boolean
   end

   enum TestResult
      "PASS"
      "FAIL"
      "SKIP"
      "FILTERED"
      "EXCEPTION"
      "TIMEOUT"
      "UNKNOWN"
      "EXPECTED_FAIL"
      "EXPECTED_EXCEPTION"
      "EXPECTED_UNKNOWN"
      "UNEXPECTED"
   end

   enum ExpectedTestResult
      "FAIL"
      "EXCEPTION"
      "UNKNOWN"
   end

   interface AssertionResult
      filename: string
      line_number: integer
      result: types.TestResult
      given: string
      should: string
      error_message: string
   end

   interface TestOutput
      name: string
      result: types.TestResult
      message: string
      time: number
      assertion_results: {AssertionResult}
      options: TestedOptions
      retry_attempts: {TestOutput}
   end

   interface TestCounts
      passed: integer
      failed: integer
      expected: integer
      skipped: integer
      filtered: integer
      invalid: integer
   end

   interface TestedOutput
      tests: {TestOutput}
      filename: string
      counts: TestCounts
      fully_tested: boolean
      total_time: number
   end

   interface TestRunnerOutput
      module_results: {TestedOutput}
      -- removing until we can safely retain all stats.
      -- coverage_results: {table}
      total_counts: TestCounts
      total_time: number
      total_tests: integer
      all_fully_tested: boolean
      tested_version: string
   end

   -- needed for result handling
   interface ResultFormatter
      format: string
      supports_show: boolean
      header: function(version: string, filepaths: {string}, comments: {string}): string
      results: function(tested_result: types.TestedOutput, test_types_to_display: {types.TestResult: boolean}): string
      summary: function(runner_output: types.TestRunnerOutput): string
   end

   -- needed for registering new file types
   interface LanguageHandler
      extension: string
      loader: function(filepath: string): function(): any
      setup: function  -- optional: registers language support for require()
   end

   -- needed for tested
   enum TestType
      "test"
      "skip"
      "only"
      "filtered"
   end

   interface Test
      kind: TestType
      name: string
      fn: function()
      options: TestedOptions
   end

   interface BaseAssertion
      given: string
      should: string
      actual: any
      debug_var: any
   end

   interface Assertion<T> is BaseAssertion
      expected: T
      actual: T
   end

   interface ExceptionAssertion is BaseAssertion
      actual: function
      expected: any
   end

   interface TestedOptions
      expected: ExpectedTestResult
      run_when: boolean
      tags: {string}
      retries: integer
      retry_delay: number
   end

   interface TestedClass
      -- asserts
      assert: function<T>(assertion: Assertion<T>): boolean, string
      assert_nil: function(assertion: BaseAssertion): boolean, string
      assert_truthy: function(assertion: BaseAssertion): boolean, string
      assert_falsy: function(assertion: BaseAssertion): boolean, string
      assert_throws_exception: function(assertion: ExceptionAssertion): boolean, string

      -- initializer
      new: function(filename?: string): Tested
   end

   interface Tested
      -- properties needed to run tests
      tests: {Test}
      run_only_tests: boolean
      filename: string
      before_fn: function
      after_fn: function
      before_each_fn: function
      after_each_fn: function

      -- actual tests
      -- teal currently doesn't support polymorphism, so we gotta kinda handle it ourselves
      test: function(self: Tested, name: string, fn_or_options: function() | TestedOptions, fn?: function())
      skip: function(self: Tested, name: string, fn_or_options: function() | TestedOptions, fn?: function())
      only: function(self: Tested, name: string, fn_or_options: function() | TestedOptions, fn?: function())
      run: function(self: Tested, options?: types.TestOptions, filename?: string): types.TestedOutput

      before: function(self: Tested, fn: function())
      after: function(self: Tested, fn: function())
      before_each: function(self: Tested, fn: function())
      after_each: function(self: Tested, fn: function())
   end
end

return types