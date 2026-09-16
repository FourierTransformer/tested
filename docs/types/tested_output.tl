interface TestedOutput
   tests: {TestOutput}
   filename: string
   counts: TestCounts
   fully_tested: boolean
   total_time: number
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

interface TestedOptions
   expected: ExpectedTestResult
   run_when: boolean
   tags: {string}
   retries: integer
   retry_delay: number
end

enum ExpectedTestResult
   "FAIL"
   "EXCEPTION"
   "UNKNOWN"
end