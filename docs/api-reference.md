# API Quick Reference

## Tests

- `tested.test(name: string, options?: table, fn: function())`
- `tested.skip(name: string, options?: table, fn: function())` - don't run this test. Useful if something is known-broken and you want to temporarily disable a test.
- `tested.only(name: string, fn: function())` - will only run these tests. Useful if you want to debug a few tests in a large file.

### Options
- `expected: "FAIL", "EXCEPTION", or "UNKNOWN"` - Useful if a unit test is going to be broken for an extended period of time and you want to mark it as a specific expected result. It will not be shown by default in the output (but can be enabled by `--show expected`, `--show all`, or `--show valid`). If the result stops being the expected value, the test will display and count as `invalid`.
    - ex: `tested.test("fails all the time", {expected="FAIL"}, function())`
- `run_when: boolean` - a value that can be determined at runtime - useful if the test should only run on LuaJIT, a certain operating system, or even configuration.
    - ex: `tested.test("luajit only", {run_when=type(jit) == 'table'}, function())` - will only run when executing via LuaJIT

## Asserts
All the asserts in `tested` take in a table with a couple of values that should hopefully make debugging your unit tests. The `given` and `should` are _optional_ text representations of what your unit test are doing. It can be useful to have text representations so you're not having to rely on the values alone. It's also nice if you're passing in a bunch of test files and use the filename in `given`, so that it appears in the output if something goes wrong.

- `tested.assert({given?: string, should?: string, expected, actual})`
- `tested.assert_truthy({given?: string, should?: string, actual})`
- `tested.assert_falsy({given?: string, should?: string, actual})`
- `tested.assert_throws_exception({given?: string, should?: string, expected?: any, actual: function()})`
    - `expected` is also optional here, but if passed in, `tested` will check if it matches the error that comes back from the function. If `expected` is a `string`, it should match the exact string that is thrown in your error command.

## Test Lifecycle
All the lifecycle methods take in a function that will be executed at the corresponding time. For any skipped test, the `before_each` and `after_each` will not run.

- `tested.before(fn: function())` - executes before any test in a file run
- `tested.after(fn: function())` - executes after all the tests in a file have run
- `tested.before_each(fn: function())` - executes before each test
- `tested.after_each(fn: function())` - executes after each test

## How `tested` works (high level)
1. Recursively search through the `tests` folder (from where it's called) or the folders specfied [on the commandline](./cli.md#tested-base-command) looking for files with the suffix `_test.lua` (or `_test.tl`) and makes a list of them
2. Before running a test file, it notes which packages have been loaded.
3. It runs through the test file and creates a list of all the tests that need to be run. Shuffling the list if desired.
4. It runs each test, tracking the asserts and results
5. It clears any packages that were loaded during the test from the `package.loaded` table and then runs garbage collection.
6. It gathers up all the results