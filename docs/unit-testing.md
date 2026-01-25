# Unit Testing




## `tested` reference

### How it works (high level)
1. Recursively search through the `tests` folder (from where it's called) or the folders specfied [on the commandline](./cli.md#tested-base-command) looking for files with the suffx `_test.lua` (or `_test.tl`) and makes a list of them
2. Before running a test file, it notes which packages have been loaded.
3. It runs through the test file and creates a list of all the tests that need to be run. Shuffling the list if desired.
4. It runs each test, tracking the asserts and results
5. It clears any packages that were loaded during the test from the `package.loaded` table and then runs garabage collection.
6. It gathers up all the results

### Tests

- `tested.test(name: string, fn: function())`
- `tested.skip(name: string, fn: function())` - don't run this test. Useful if something is known-broken and you want to disable a test.
- `tested.only(name: string, fn: function())` - will only run these tests. Useful if you want to debug a few tests in a large file.
- `tested.conditional_test(name: string, condition: boolean, fn: function())` - Will only run the test if the condition passes.
    - Ex: the condition could be `type(jit) == 'table'` and the test will only run on LuaJIT

### Asserts
All the asserts in `tested` take in a table with a couple of values that should hopefully make debugging your unit tests. The `given` and `should` are [optional] text representations of what your unit test are doing. It can be useful to have text representations so you're not having to rely on the values alone. It's also nice if you're passing in a bunch of test files and could use the filename in `given`, so that it appears in the output if something goes wrong.

- `tested.assert({given?: string, should?: string, expected, actual})`
- `tested.assert_truthy({given?: string, actual})`
- `tested.assert_falsy({given?: string, actual})`
- `tested.assert_throws_exception({given?: string, actual})`

## On randomzing the order of tests
`tested` leaves it up to you on how you want to organize your unit tests. If you want a bunch of asserts in the same test, that's just fine!