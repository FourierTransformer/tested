# API Quick Reference

Throughout this document `t` is the tested _object_ (per `t = tested.new()`) and `tested` is the tested _class_ (per `tested = require("tested")`)

## Tests
- `t = tested.new(filename?: string)` - creates a new tested object that tests can be associated with.
- `t:test(name: string, options?: table, fn: function())`
- `t:skip(name: string, options?: table, fn: function())` - don't run this test. Useful if something is known-broken and you want to temporarily disable a test.
- `t:only(name: string, fn: function())` - will only run these tests. Useful if you want to debug a few tests in a large file.

### Options
Options can be specified in a table passed in via the optional second argument:

- `expected: "FAIL", "EXCEPTION", or "UNKNOWN"` - Useful if a unit test is going to be broken for an extended period of time and you want to mark it as a specific expected result. It will not be shown by default in the output (but can be enabled by `--show expected`, `--show all`, or `--show valid`). If the result stops being the expected value, the test will display and count as `invalid`.
    - ex: `t:test("fails all the time", {expected="FAIL"}, function())`
- `run_when: boolean` - a value that can be determined at runtime - useful if the test should only run on LuaJIT, a certain operating system, or even configuration.
    - ex: `t:test("luajit only", {run_when=type(jit) == 'table'}, function())` - will only run when executing via LuaJIT
- `tags: {string}` - a list of tags that can be used for test run filtering 
- `retries: integer` - number of times to retry the test if the test result is not a `PASS` or one of the `EXPECTED_*`'s.
- `retry_delay: number` - number of seconds to wait before attempting a retry

## Asserts
All the asserts in `tested` take in a table with a couple of values that should hopefully make debugging your unit tests. The `given` and `should` are _optional_ text representations of what your unit test are doing. It can be useful to have text representations so you're not having to rely on the values alone. It's also nice if you're passing in a bunch of test files and use the filename in `given`, so that it appears in the output if something goes wrong.

- `tested.assert({given?: string, should?: string, expected, actual})`
- `tested.assert_nil({given?: string, should?: string, actual})`
- `tested.assert_truthy({given?: string, should?: string, actual})`
- `tested.assert_falsy({given?: string, should?: string, actual})`
- `tested.assert_throws_exception({given?: string, should?: string, expected?: any, actual: function()})`
    - `expected` is also optional here, but if passed in, `tested` will check if it matches the error that comes back from the function. If `expected` is a `string`, it should match the exact string that is thrown in your error command.

All the asserts can also take in any value as `debug_var`, which gets displayed when a test fails. It can be used to display any values to help make debugging a test easier (ex: a whole string if you're checking a substring, or an entire table).

## Test Lifecycle
All the lifecycle methods take in a function that will be executed at the corresponding time. For any skipped test, the `before_each` and `after_each` will not run.

- `t:before(fn: function())` - executes before any test in a file run
- `t:after(fn: function())` - executes after all the tests in a file have run
- `t:before_each(fn: function())` - executes before each test
- `t:after_each(fn: function())` - executes after each test

## Test Running
These are only needed for running your own tests, as you would have to do with [`tested_core`](../tested-core.md). While the methods are available, the CLI handles these things for you.

- `t:run(options?: TestedAPIOptions): TestedOutput)` - runs an individual test
- `tested.run_tests(tests: {Tested}, options?: TestedAPIOptions): TestRunnerOutput` - runs a series of tests
- `tested.combine_results(tests_output: {TestedOutput}): TestRunnerOutput` - combine individual test results
- `tested.format_results(output: TestRunnerOutput, display_format?: DisplayFormat, show?: {DisplayOptions}): string` - format the results from either `combine_results` or `format_results`.

### Tested API Options
- `random: boolean` - randomizes the order of tests and test instances before running
- `filter: string` - filter a set of tests down by name
- `tags: string` - use test tags combined with `and`, `or`, and `not` to run specifically tagged tests
- `clock_s: function(): number` - function that is called at the beginning and end of tests to determine running time. Defaults to `os.clock()`
- `sleep_s: function(seconds: number)` - sleep function used with `retry_delay`. By default it is a blocking sleep method using `os.clock()`

### Display Format
The optional argument `display_format` is one of `plain`, `tap`, or `terminal`.

### Display Options
The optional `show` argument is one of `pass fail skip exception unknown expected unexpected valid invalid all` and defaults to showing tests that need to be looked at. More specifics can be found on the [CLI page](./cli/#tested-s-show)


## High Level Architecture
1. Recursively search through the `tests` folder (from where it's called) or the folders specified [on the commandline](./cli.md#tested-base-command) looking for files with the suffix `_test.lua` (or `_test.tl`) and makes a list of them
2. Before running a test file, it notes which packages have been loaded.
3. It runs through the test file and creates a list of all the tests that need to be run. Shuffling the list if desired.
4. It runs each test, tracking the asserts and results
5. It clears any packages that were loaded during the test from the `package.loaded` table and then runs garbage collection.
6. It gathers up all the results
