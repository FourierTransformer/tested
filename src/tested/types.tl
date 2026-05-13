-- exporting all the shared types

local record types

   -- file loader
   interface FileLoader
      load_file: function(filepath: string): any
   end

   -- test running types
   interface TestRunnerOptions
      random: boolean
      coverage: boolean
      filter: string
   end

   enum TestResult
      "PASS"
      "FAIL"
      "SKIP"
      "CONDITIONAL_SKIP"
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
   end

   interface TestCounts
      passed: integer
      failed: integer
      expected: integer
      skipped: integer
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
      allow_filtering: boolean
      header: function(version: string, filepaths: {string}, comments: {string}): string
      results: function(tested_result: types.TestedOutput, test_types_to_display: {types.TestResult: boolean}): string
      summary: function(runner_output: types.TestRunnerOutput): string
   end

   -- needed for registering new file types
   interface FileLoaderHandler
      extension: string
      loader: function(filepath: string): function(): any
   end

   -- needed for tested
   enum TestType
      "test"
      "skip"
      "only"
      "conditional_test"
      "conditional_skip"
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
   end

   interface Assertion<T> is BaseAssertion
      expected: T
      actual: T
   end

   interface TruthyAssertion is BaseAssertion end
   interface FalsyAssertion is BaseAssertion end
   interface ExceptionAssertion is BaseAssertion 
      actual: function
      expected: any
   end

   interface TestedOptions
      -- retries: integer
      -- retry_timeout: number
      expected: ExpectedTestResult
      run_when: boolean
   end

   interface Tested
      tests: {Test}
      run_only_tests: boolean

      before_fn: function()
      after_fn: function()
      before_each_fn: function()
      after_each_fn: function()

      assert: function<T>(assertion: Assertion<T>): boolean, string
      assert_truthy: function(assertion: TruthyAssertion): boolean, string
      assert_falsy: function(assertion: FalsyAssertion): boolean, string
      assert_throws_exception: function(assertion: ExceptionAssertion): boolean, string
      -- teal currently doesn't support polymorphism, so we gotta kinda handle it ourselves
      test: function(name: string, fn_or_options: function() | TestedOptions, fn?: function())
      skip: function(name: string, fn_or_options: function() | TestedOptions, fn?: function())
      only: function(name: string, fn_or_options: function() | TestedOptions, fn?: function())
      run: function(self: types.Tested, filename: string, options: types.TestRunnerOptions): types.TestedOutput
      before: function(fn: function())
      after: function(fn: function())
      before_each: function(fn: function())
      after_each: function(fn: function())
   end
end

return types