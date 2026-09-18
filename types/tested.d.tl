
local record tested

   enum ExpectedTestResult
      "FAIL"
      "EXCEPTION"
      "UNKNOWN"
   end

   interface TestedOptions
      expected: ExpectedTestResult
      run_when: boolean
      tags: {string}
      retries: integer
      retry_delay: number
   end

   interface TestedBaseOptions
      random: boolean
      filter: string
      tags: string
   end

   interface TestedAPIOptions is TestedBaseOptions
      clock_s: function(): number
      sleep_s: function(seconds: number)
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

   enum DisplayFormat
      "plain"
      "terminal"
      "tap"
   end

   enum DisplayOptions
      "all"
      "valid"
      "invalid"
      "skip"
      "pass"
      "fail"
      "exception"
      "unknown"
      "expected"
      "unexpected"
      -- "timeout" -- NYI
   end

   interface Tested
      test: function(name: string, fn: function())
      test: function(name: string, options: TestedOptions, fn: function())
      skip: function(name: string, fn: function())
      skip: function(name: string, options: TestedOptions, fn: function())
      only: function(name: string, fn: function())
      only: function(name: string, options: TestedOptions, fn: function())

      -- lifecycle
      before: function(self: Tested, fn: function())
      after: function(self: Tested, fn: function())
      before_each: function(self: Tested, fn: function())
      after_each: function(self: Tested, fn: function())

      -- test running
      run: function(self: Tested, options?: TestedAPIOptions): TestedOutput
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

   interface AssertionResult
      filename: string
      line_number: integer
      result: TestResult
      given: string
      should: string
      error_message: string
   end

   interface TestOutput
      name: string
      result: TestResult
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

   assert: function<T>(assertion: Assertion<T>): boolean, string
   assert_nil: function(assertion: BaseAssertion): boolean, string
   assert_truthy: function(assertion: BaseAssertion): boolean, string
   assert_falsy: function(assertion: BaseAssertion): boolean, string
   assert_throws_exception: function(assertion: ExceptionAssertion): boolean, string

   -- initializer
   new: function(filename?: string): Tested

   run_tests: function(tests: {Tested}, options?: TestedAPIOptions): TestRunnerOutput
   combine_results: function(tests_output: {TestedOutput}): TestRunnerOutput
   format_results: function(output: TestRunnerOutput, display_format?: DisplayFormat, show?: {DisplayOptions}): string
end

return tested
