
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
   assert_nil: function(assertion: BaseAssertion): boolean, string
   assert_truthy: function(assertion: BaseAssertion): boolean, string
   assert_falsy: function(assertion: BaseAssertion): boolean, string
   assert_throws_exception: function(assertion: ExceptionAssertion): boolean, string
end

return tested
