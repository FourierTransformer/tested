# `tested`

`tested` is a new Lua (and [Teal](https://teal-language.org)!) unit testing framework! It's designed to be simple to use, fast, provide enough information to make results actionable, and one day run everywhere Lua does. It's still early days, but I think it could see some use and am excited to share it!

## Installation
```bash
luarocks install tested
```

After installing, the `tested` module will be available to your Lua code with `require("tested")` and a CLI tool, also called `tested` will be installed wherever your LuaRocks installs executables (be sure LuaRocks `bin` folder is on your path!).

## Example Test

Test files should be placed in a folder called `tests`, and the `tested` command should be invoked from the same directory that has the `tests` folder in it.

=== "Test"

    ```lua
    local tested = require("tested")
    local utf8validator = require("utf8validator")

    tested.test("should support ascii", function()
       local start_seq = tonumber("00000000", 2)
       local end_seq = tonumber("01111111", 2)

       for i = start_seq, end_seq do
          tested.assert({
            -- given and should are optional!
            given="string.char " .. i,
            should="support ascii char",
            expected=true,
            actual=utf8validator(string.char(i))
        })
       end
       
    end)

    tested.test("should support two bytes", function()
       local start_seq = tonumber("11000010", 2)
       local end_seq = tonumber("11011111", 2)

       local start_seq_2nd = tonumber("10000000", 2)
       local end_seq_2nd = tonumber("10111111", 2)
       for i = start_seq, end_seq do
          for j = start_seq_2nd, end_seq_2nd do
             tested.assert_truthy({
                given = "string.char " .. i .. " " .. j,
                should = "support two bytes",
                actual=utf8validator(string.char(i, j))
            })
          end
       end
    end)

    -- ... the other test go here!

    return tested
    ```
=== "Output"
    ```
    tested v0.0.1  tests/binary_test.tl

    - tests/binary_test.tl (11.05ms)
    Test Summary for 4 tests (11.05ms):
      Run: 4 passed, 0 failed
    Other: 0 skipped, 0 invalid

    Fully Tested!
    ```

Check out the [Unit Testing](./unit-testing.md) page for more information on how `tested` works! and after, if you're using Teal, be sure to check out the [Teal Support](./teal-support.md) page!

## Quickstart

### Folder setup
In the root of your project, you should create a `tests` folder and place all your test files (with the suffix of `_test.lua` or `_test.tl`). From there you can run the `tested` command from a it will find all the tests and run them.

```
.
├─ tests/
│  ├─ my_library_test.lua
│  └─ a_different_test.lua
└─ my_library.lua
```

### The test file

Let's take a look at a basic test file:

```lua title="tests/my_library_test.lua"
local tested = require("tested")

tested.test("just a test!", function()
    tested.assert({
        given = "4 + 4",
        should = "return 8",
        expected = 8,
        actual = sum(4, 4)
    })
end)

print("This will be printed before _any_ tests run!")

tested.test("just works without given and should!", function()
    tested.assert({
        expected=true,
        actual=true
    })
end)

return tested
```

After the `tested` command loads up a test file, it goes through and finds all the various tests defined in the file (in this case there are two) and adds them to a list to be executed. In the example above, that `print` statement will execute before either tests.

It does this so tests can be [shuffled](#cli-quick-reference), [skipped](#skipping-tests), or to [only](#only-tests) run a specific test within a test file!

### Asserts
The basic assert is composed of four parts:
```lua
    tested.assert({
        given = "4 + 4",
        should = "return 8",
        expected = 8,
        actual = sum(4, 4)
    })
```

The `given` and `should` are optional strings that get displayed in the output to help you identify which specific assert has failed. The idea behind them is to be able to look at the testing output and know _exactly_ what and how something has failed. If your test references multiple files, placing a filename in given can be incredibly useful. Since some tests are more obvious than others (based on a test name), they are not required and can be omitted.

The `expected` and `actual` take in the expected and actual values. There are a couple of other asserts builtin to `tested`, including one for [exceptions](#testing-exceptions), [truthy, and falsy](#truthyfalsy-tests)!


### CLI Quick Reference
There are a couple CLI commands that are good to know when you get started:

- `tested -c` or `--coverage` will enable luacov code coverage and generate a `luacov.stats.out` file
- `tested -r` or `--random` will randomize the order of tests _within a test file_.
- `tested -s` or `--show` supports displaying different status of tests. By default `tested` shows tests which require followup (so `fail`, `exception`, and `invalid`)
    - Ex: `tested -s pass -s skip` see all passed and skipped tests
    - Ex: `tested -s valid`

To see the entire list of CLI options, check out the [CLI Reference](./cli.md)

### Teal Support
`tested` has builtin Teal support, be sure to check out the [Teal Support](./teal-support.md) page for some of the considerations around its usage with Teal.