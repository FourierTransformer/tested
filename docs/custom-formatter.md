# Custom Formatters
As of now (1/2026), `tested` currently supports a "terminal" output and a "plain" output (which is just the terminal output without colors), with plans for a few more [in the future](https://github.com/FourierTransformer/tested/issues/21)! But we've tried to make it easy to create your own formatter for `tested`.

## A basic formatter

```lua

local custom_formatter = {
	-- whether or not this formatter allows filtering by type
	allow_filtering: boolean = true,

	-- name of formatter
	format: string = "my custom formatter"
}

-- Runs after performing all the setups and tests are about to run!
-- version: "tested v0.0.0"
-- filepaths: list of filepaths passed into tested.
function custom_formatter.header(version: string, filepaths: {string}) end

-- Displays results after a test has been run
function custom_formatter.results(
	tested_result: types.TestedOutput,
	test_types_to_display: {types.TestResult: boolean}
) 
end

-- 
function custom_formatter.summary(output: types.TestRunnerOutput) end

return custom_formatter

```

Feel free to also look at the existing [terminal](https://github.com/FourierTransformer/tested/blob/main/src/tested/results/terminal.tl) formatter and the references below to help you get started!

### `TestRunnerOutput`
An example of what `types.TestRunnerOutput` looks like. `types.TestedOutput` is one of the values from `module_results`:
```lua
{
  all_fully_tested = false,
  module_results = { {
      counts = {
        failed = 0,
        invalid = 0,
        passed = 2,
        skipped = 0
      },
      filename = "./tests/fully_working_test.lua",
      fully_tested = true,
      tests = { {
          assertion_results = { {
              filename = "./tests/fully_working_test.lua",
              given = "nothing",
              line_number = 4,
              result = "PASS",
              should = "just work!"
            } },
          message = "All assertions have passed",
          name = "just works!",
          result = "PASS",
          time = 8.000000000008e-06
        }, {
          assertion_results = { {
              filename = "./tests/fully_working_test.lua",
              line_number = 13,
              result = "PASS"
            } },
          message = "All assertions have passed",
          name = "just works without given and should!",
          result = "PASS",
          time = 2.0000000000575e-06
        } },
      total_time = 1.0000000000066e-05
    }, {
      counts = {
        failed = 2,
        invalid = 0,
        passed = 1,
        skipped = 0
      },
      filename = "./tests/non_working_test.tl",
      fully_tested = false,
      tests = { {
          assertion_results = { {
              filename = "./tests/non_working_test.tl",
              given = "true",
              line_number = 4,
              result = "PASS",
              should = "1"
            } },
          message = "All assertions have passed",
          name = "doesn't work with given and should being not strings!",
          result = "PASS",
          time = 6.9999999999792e-06
        }, {
          assertion_results = { {
              error_message = "Actual: true\nExpected: false",
              filename = "./tests/non_working_test.tl",
              given = "true",
              line_number = 14,
              result = "FAIL"
            } },
          message = "1 assertions have failed",
          name = "output should clearly show just given",
          result = "FAIL",
          time = 2.9999999999752e-06
        }, {
          assertion_results = { {
              error_message = "Actual: false\nExpected: true",
              filename = "./tests/non_working_test.tl",
              line_number = 22,
              result = "FAIL",
              should = "true"
            } },
          message = "1 assertions have failed",
          name = "output should clearly show just should",
          result = "FAIL",
          time = 1.9999999999465e-06
        } },
      total_time = 1.1999999999901e-05
    } },
  total_counts = {
    failed = 2,
    invalid = 0,
    passed = 3,
    skipped = 0
  },
  total_tests = 5,
  total_time = 2.1999999999966e-05
}
```

### Type Definitions
```lua
enum TestResult
  "PASS"
  "FAIL"
  "SKIP"
  "CONDITIONAL_SKIP"
  "EXCEPTION"
  "TIMEOUT"
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
  total_counts: TestCounts
  total_time: number
  total_tests: integer
  all_fully_tested: boolean
end

-- The actual formatter itself
interface ResultFormatter
  format: string
  allow_filtering: boolean
  header: function(version: string, filepaths: {string})
  results: function(tested_result: types.TestedOutput, test_types_to_display: {types.TestResult: boolean})
  summary: function(runner_output: types.TestRunnerOutput)
end
```