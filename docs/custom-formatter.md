# Custom Formatters
As of now (1/2026), `tested` currently supports printing out a "terminal", "plain" (which is just the terminal output without colors), and "tap" output. We've tried to make it easy to create your own formatter for `tested`. You can only create a custom formatter for _display_ purposes. If you want to create a custom formatter for _file saving_ purposes, please [create an issue](https://github.com/FourierTransformer/tested/issues)!

## A basic formatter

A formatter is composed of three functions which all return a string that will be printed in the terminal.

```lua

local custom_formatter = {
	-- whether or not this formatter supports the `--show` option
  -- set to `true` if actually handling `test_types_to_display` in the `results` function
	supports_show: boolean = true,

	-- name of formatter
	format: string = "my custom formatter"
}

-- Runs after performing all the setups and tests are about to run!
-- version: "tested v0.0.0"
-- filepaths: list of filepaths passed into tested.
-- comments: list of comments that can be displayed at the beginning of a test run for things like selected filter/tags
function custom_formatter.header(version: string, filepaths: {string}, comments: {string}): string end

-- Displays results after a test has been run
function custom_formatter.results(
	tested_result: types.TestedOutput,
	test_types_to_display: {types.TestResult: boolean}
): string
end

-- Outputs a summary at the end
function custom_formatter.summary(output: types.TestRunnerOutput): string end

return custom_formatter

```

Feel free to also look at the existing [terminal](https://github.com/FourierTransformer/tested/blob/main/src/tested/results/terminal.tl) formatter and the references below to help you get started!

### `TestRunnerOutput`
An example of what `types.TestRunnerOutput` looks like (in json). `types.TestedOutput` is one of the values from `module_results`:
```json
{
  "tested_version":"tested v0.2.0",
  "total_tests":2,
  "all_fully_tested":true,
  "total_time":4.000000000004e-06,
  "total_counts":{
    "skipped":0,
    "invalid":0,
    "filtered":0,
    "failed":0,
    "passed":2,
    "expected":0
  },
  "module_results":[{
      "counts":{
        "skipped":0,
        "invalid":0,
        "filtered":0,
        "failed":0,
        "passed":2,
        "expected":0
      },
      "fully_tested":true,
      "total_time":4.000000000004e-06,
      "filename":"./tests/assertions/fully_working_test.lua",
      "tests":[{
          "options":{
          },
          "time":3.000000000003e-06,
          "result":"PASS",
          "assertion_results":[{
              "filename":"./tests/assertions/fully_working_test.lua",
              "result":"PASS",
              "should":"just work!",
              "given":"nothing",
              "line_number":4
            }],
          "message":"All assertions have passed",
          "name":"just works!"
        },{
          "options":{
          },
          "time":1.000000000001e-06,
          "result":"PASS",
          "assertion_results":[{
              "result":"PASS",
              "filename":"./tests/assertions/fully_working_test.lua",
              "line_number":13
            }],
          "message":"All assertions have passed",
          "name":"just works without given and should!"
        }]
    }]
}
```

### Type Definitions
```lua
enum TestResult
  "PASS"
  "FAIL"
  "SKIP"
  "FILTERED"
  "EXCEPTION"
  -- "TIMEOUT" -- NYI
  "UNKNOWN"
  "EXPECTED_FAIL"
  "EXPECTED_EXCEPTION"
  "EXPECTED_UNKNOWN"
  "UNEXPECTED"
end

interface AssertionResult
  filename: string
  line_number: integer
  result: types.TestResult
  given: string
  should: string
  error_message: string
end

interface TestedOptions
  -- retries: integer -- NYI
  -- retry_timeout: number -- NYI
  expected: ExpectedTestResult
  run_when: boolean
  tags: {string}
end

interface TestOutput
  name: string
  result: types.TestResult
  message: string
  time: number
  assertion_results: {AssertionResult}
  options: TestedOptions
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
  total_counts: TestCounts
  total_time: number
  total_tests: integer
  all_fully_tested: boolean
  tested_version: string
end

-- The actual formatter itself
interface ResultFormatter
  format: string
  supports_show: boolean
  header: function(version: string, filepaths: {string}, comments: {string}): string
  results: function(tested_result: types.TestedOutput, test_types_to_display: {types.TestResult: boolean}): string
  summary: function(runner_output: types.TestRunnerOutput): string
end
```