# Pure Lua Mode - tested Core
For situations where Lua code can be directly executed, the standard `tested` framework and CLI from LuaRocks should work great, but in instances where `tested` needs to be embedded and/or LuaRocks (or equivalent) is not available, we offer `tested_core.lua` - a single file, zero external dependency, pure Lua module that can be used to run tests. _Only the CLI based test runner_ requires additional dependencies to function (mostly around OS calls) and most functionality is available in both.

In theory this allow `tested_core` to work with Neovim, LÖVE, OpenResty, or any other embedded environments! We haven't tried it with any other environment yet, but if you've had success, please [let us know!](https://github.com/FourierTransformer/tested/discussions/categories/show-and-tell). We want to one day add guides on how to set that up!

## Install
The latest released version of `tested_core.lua` can be found on the [GitHub Releases](https://github.com/FourierTransformer/tested/releases) page.

## Feature Comparison

| Feature | tested_core | tested (w/CLI) |
| ------- | -------- | ------------ |
| Tests + Asserts | ✅ | ✅ |
| Lifecycle Managment | ✅ | ✅ |
| Tags + Filters | ✅ | ✅ |
| Terminal/Plain/TAP Output | ✅ | ✅ |
| Custom Formatter | ❌ | ✅ |
| Custom timers | ✅ | ❌ |
| Code Coverage | ❌ | ✅ |
| Text/JSON Output to File | ❌ | ✅ |
| Additional Language Handlers | ❌ | ✅ |
| Automatic Test Finding | ❌ | ✅ |
| Full Test Isolation | ❌ | ⚠️ |

??? "On Test Isolation"
    Ideally when running tests, each test file should be in its own isolated testing environment. In Lua this can be particularly tricky, since there isn't really a safe way to unload C modules. So, at best, you can unload Lua modules, but have to let C modules persist, which is how the `tested` CLI operates today.

    For using `tested` from the Lua API directly, we currently _do not_ unload any modules between tests. Mostly because even doing that in an unknown environment could cause issues. Unfortunately this is an exercise left to the reader for those who truly need it.

## Using the `tested` API
Below are examples of using `tested_core`, and at the [bottom of the page](#type-definition-reference), we also have the full Teal type definitions for all of the values that get returned.

Fair warning, we are still pre-v1 and while a lot of the returned values haven't changed much, it is always possible. After v1, we will follow [semver](https://semver.org/) and any major change (removal or restructuring) will result in a MAJOR version change to `tested` and additions will be considered MINOR.

### Run a single test

After writing a test tile, you can directly call `run` on the tested object

```lua
local tested = require("tested_core")

local t = tested.new()

t:test("hello this is my test name", function()
    tested.assert({
        given = "the most basic of tests (4 == 4)",
        should = "be true",
        expected = 4,
        actual = 4,
    })
end)

--- ... other tests

-- results will include all test results, and assertion results and such
local results = t:run()
```

`t:run` can take two optional parameters: `options` and  `filename`:
```lua
local test_options = {random=true} -- will randomize order of tests
local results = t:run(test_options, "custom-filename.lua")
```
By default the filename is `#!lua debug.getinfo(2, "S").short_src` when `#!lua tested.new()` is called, but depending on your setup, you may want to override that value.

#### Tested Options
The options are the same as the ones from the CLI, and include an additional `clock_s` and `sleep_s` for setting timing functions:

- `random: boolean`: randomizes the order of tests before running
- `filter: string`: filter a set of tests down by name
- `tags: string`: use test tags with basic primitives to only run specifically tagged tests
- `clock_s: function(): number`: a function that returns a number of seconds (by default uses `os.clock()`). This is used to determine the amount of time a test has been run. Overridable in situations where you don't want CPU time but rather wall time and/or more precision.
- `sleep_s: function(seconds: number)`: For [test retries](./unit-testing/#test-retries) with a `retry_delay`, the `sleep_s` method is used. By default it is a blocking sleep method using `os.clock()`.


### Run multiple tests
We also provide a convenient way to run a bunch of tests:
```lua
local tested = require("tested_core")

-- simple example, but you should be able do test discovery however!
-- these files simply return the tested object `t`
local first_test = require("tests.first")
local second_test = require("tests.second")
local all_tests = {first_test, second_test}

local options = {random=true}
-- This will call `run` on all the individual tests
-- and return the total counts/times of all tests run as well as all the individual test results
local test_runner_output = tested.run_tests(all_tests, options)
```

It follows all the same options as [above](#tested-options).

### Formatting results
Unlike standard tested, the results of the tests _do not_ get printed out to stdout, but we do offer a few helper methods for formatting the Lua table output as a string to match the regular output.

```lua
local tested = require("tested_core")

local test_runner_output = tested.run_tests(all_tests, options)
local results_string = tested.format_results(test_runner_output, "terminal", "all")
print(results_string)
```

The optional second and third arguments line up with the [CLI's](./cli/#tested-s-show) `--display-format` and `--show` options respectively:

- The second argument "display_format" can either be `plain`, `terminal`, or `tap` (and defaults to `plain`)
- The third argument "show" is a list of strings that can either be: `pass fail skip exception unknown expected unexpected valid invalid all`
    - It defaults to tests that need to be addressed: `{"fail", "exception", "unknown", "unexpected"}`

There are also helper methods for combining individual `t:run()`s:
```lua
local tested = require("tested_core")
local first_test = require("tests.first")
local second_test = require("tests.second")

local first_test_result = first_test:run()
local second_test_result = second_test:run()

-- combine and display all results
local combined_results = tested.combine_results({first_test_result, second_test_result})
print(tested.format_results(combined_results))
```

### Type Definition Reference

The `tested_core` API methods for test running:

```lua
interface TestedClass
  run_tests: function(tests: {Tested}, options?: TestedAPIOptions): TestRunnerOutput
  combine_results: function(tests_output: {TestedOutput}): TestRunnerOutput
  format_results: function(output: TestRunnerOutput, display_type?: DisplayFormat, show?: {DisplayOptions}): string
end

interface TestedObject
  run: function(self: Tested, options?: TestedAPIOptions, filename?: string): TestedOutput
end
```

??? "Type Definitions"

    === "Teal"

        ```lua
        --8<-- "./docs/types/tested_output.tl"
        ```


