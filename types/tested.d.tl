
local record tested

   enum ExpectedTestResult
      "FAIL"
      "EXCEPTION"
      "UNKNOWN"
   end

   interface TestedOptions
      -- retries: integer
      -- retry_timeout: number
      expected: ExpectedTestResult
      run_when: boolean
      tags: {string}
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

   test: function(name: string, fn: function())
   test: function(name: string, options: TestedOptions, fn: function())
   skip: function(name: string, fn: function())
   skip: function(name: string, options: TestedOptions, fn: function())
   only: function(name: string, fn: function())
   only: function(name: string, options: TestedOptions, fn: function())

   before: function(fn: function())
   after: function(fn: function())
   before_each: function(fn: function())
   after_each: function(fn: function())
   assert: function<T>(assertion: Assertion<T>): boolean, string
   assert_truthy: function(assertion: TruthyAssertion): boolean, string
   assert_falsy: function(assertion: FalsyAssertion): boolean, string
   assert_throws_exception: function(assertion: ExceptionAssertion): boolean, string
end

return tested
