# CLI Reference

`tested` ships with a command-line interface (CLI) to aid in running tests. Below are some of the options explained in further detail as well as a reference to the full CLI's help page.

## `tested` - Base command 
By default `tested` will look for `_test.*` files recursively in the `./tests` directory relative to where it is run, looking for registered file extensions (by default `.lua` and `.tl`). You can specify your own directories or individual files to run by placing them at the end of the CLI invocation.

Example commands:

- `tested ./some-tests-here ./other-tests-here` - specifying multiple directories
- `tested ./tests/non_working_test.lua` - running a specific file

## `tested -c/--coverage`
The `-c` flag will enable [luacov](https://github.com/lunarmodules/luacov), and generate a `luacov.stats.out` file. It is disabled by default since it is generally used in CI/CD pipelines and unfortunately slows down testing. So feel free to enable it when you need code coverage!

## `tested -r/--random`
The `-r` will randomize the order of tests _within_ a test file.

## `tested -F/--filter`
Will only run tests that match the Lua pattern that applies to the **test name** using `string.find`. Useful for debugging specific tests by name. With `string.find`, so if you pass in `--filter "sum"` it will match _all tests_ with `"sum"` _anywhere_ in the test name. If you want to search for tests that _begin with_ `"sum"`, you should use `"^sum"` (or `"sum$"` to match the _end_ of a test name). It's just Lua [patterns](http://lua-users.org/wiki/PatternsTutorial) at the end of the day!

## `tested -t/--tags`
Tests can also be tagged and then selected to run by tag from the CLI. This can be useful if you have slow running tests, tests where you might want (or not want) code coverage, tests that might need external resources, or just the ability to create a group of selectable tests.

Test Example:
```lua
local tested = require("tested")
local t = tested.new()

t:test("tagged as integration", {tags={"integration"}}, function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

t:test("tagged as unit and slow", {tags={"unit", "slow"}}, function()
   tested.assert({given="1+1", should="equal 2", expected=2, actual=1+1})
end)

return t
```
The tag filtering supports boolean logic (and/or/not and parenthesis), so you can do the following:

- `-t "integration"` - would select just the first test
- `-t "integration or unit"` - would select both tests
- `-t "unit and slow"` and `-t "slow"` - would select only the last test
- `-t "not integration"` - will run _all_ tests without the integration tag (including un-tagged tests)

and because of that, tags cannot be named `and`, `or`, or `not`.


## `tested -s/--show`
By default the `tested` output shows the problematic test results, that likely need to be addressed: `fail`, `exception`, `unknown`, and `unexpected` but allows displaying other results.

Current Values: `pass fail skip exception unknown expected unexpected valid invalid all`

There are three groupings that can also be used:

- `tested -s valid` - will show `pass`, `fail`, `expected`, `filtered` (for tests that did not run when filtered) and `skip`
- `tested -s invalid` - will show `exception`, `unknown`, and `unexpected`
- `tested -s all` - shows all tests

To pass multiple values:

- `tested -s pass -s fail -s skip`

## `tested -f/--display-format`
Currently, `tested` has a couple display formats:

- `tested -f terminal` (default) - which displays all the output with ansicolors to the terminal
- `tested -f plain` - the same output as `terminal` but without any ansicoloring
- `tested -f tap` - output in the [TAP v14 format](https://testanything.org/). The TAP output does not change with the `-s` display options and always displays the entire output.


## `tested -n/--instances`
Prior versions of `tested` included support for running tests in a threaded manner using Lua Lanes, however we eventually ran into deadlock issues in tests where a test file forked and decided to remove threaded tests for now. The `-n` flag is now a noop and will just run tests sequentially. We hope to one day bring back safely running tests in parallel.

## `tested -z/--custom-formatter`
`tested` supports loading a [custom result formatter](./custom-formatter.md) from the commandline. It tries to load what's passed in initially as a Lua module, and then as filepath, doing some basic checks to ensure the object returned appears to be a formatter. Only one custom formatter can be loaded and will be used to display results.

## `tested -o/--output-file`
Output file to save results to a specified file. It loads a formatter based on the file extension of the file that's passed in. The currently supported extensions are:

- `.txt` - Outputs _exactly_ what is shown in the terminal (includes any of the `--show` display options)
- `.json` - Outputs the full [TestRunnerOutput](./custom-formatter.md#testrunneroutput). Everything - the `--show` option does not affect it. We're still pre v1, so the output here _could_ change.

Multiple files (and file types) can be specified and will all be written to at the end of the test run:

```bash
tested -o ./terminal_output.txt -o ./full_output.json
```

## `tested -x/--language-handler`
`tested` also supports loading [custom languages](./language-handlers.md) that can run using Lua. Similar to custom output formatters, the language handler will first try and load from a Lua module and then from a filepath. This allows flexibility in distribution in how folks may want to support their custom language. Multiple language handlers can be loaded, and afterward can be used for custom formatters or the tests themselves. The language handler for [Teal](https://teal-language.org/) is [built-in](./teal-support.md).

## `tested -h` - Reference

```
Usage: tested ([-f {terminal,plain,tap}] | [-z <custom_formatter>])
       [-h] [-c] [-r] [-F <filter>] [-t <tags>]
       [-s {all,valid,invalid,skip,pass,fail,exception,unknown,expected,unexpected}]
       [-o <output_file>] [-n <instances>] [-x <language_handler>]
       [-d {DEBUG,INFO,WARNING}] [--version] [<paths>] ...

A Lua/Teal Unit Testing Framework

Arguments:
   paths                 Path(s) to directories or files with tests to run (default: 'tests')

Options:
   -h, --help            Show this help message and exit.
   -c, --coverage        Enable code coverage - will generate luacov.stats.out (default: not-set)
   -r, --random          Randomize the order of the tests (default: not-set)
         -F <filter>,    Only run tests whose name matches this Lua pattern (default: not-set)
   --filter <filter>
       -t <tags>,        Only run tests matching a tag expression, e.g. 'integration' or '(unit or integration) and not slow' (default: not-set)
   --tags <tags>
       -s {all,valid,invalid,skip,pass,fail,exception,unknown,expected,unexpected},
   --show {all,valid,invalid,skip,pass,fail,exception,unknown,expected,unexpected}
                         What test results to display (default: '-s fail -s exception -s unknown')
                 -f {terminal,plain,tap},
   --display-format {terminal,plain,tap}
                         What format to output the results in (default: 'terminal') (default: terminal)
                   -z <custom_formatter>,
   --custom-formatter <custom_formatter>
                         File that loads a custom formatter to use for terminal output
              -o <output_file>,
   --output-file <output_file>
                         Output file to save test results in (currently supported extensions: '.txt' and '.json')
            -n <instances>,
   --instances <instances>
                         Set the number of concurrent tests to run (default: 4). Due to threading behaviour, this is now a noop. All tests run sequentially.
                   -x <language_handler>,
   --language-handler <language_handler>
                         File that loads custom language that is Lua-compatible
        -d {DEBUG,INFO,WARNING},
   --debug {DEBUG,INFO,WARNING}
                         Set the log level - mostly for debugging issues with tested (default: 'WARNING') (default: WARNING)
   --version             Show version information
```
