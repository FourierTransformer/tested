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
Will only run tests that match the Lua pattern that applies to the **test name** using `string.find`. Useful for debugging specific tests.

## `tested -s/--show`
By default the `tested` output shows the problematic test results, that likely need to be addressed: `fail`, `exception`, `unknown`, and `unexpected` but allows filtering to display other results.

Current Values: `pass fail skip exception unknown expected unexpected valid invalid all`

There are three groupings that can also be used:

- `tested -s valid` - will show `pass`, `fail`, `expected`, and `skip`
- `tested -s invalid` - will show `exception`, `unknown`, and `unexpected`
- `tested -s all` - shows all tests

To pass multiple values:

- `tested -s pass -s fail -s skip`

## `tested -f/--display-format`
Currently, `tested` has a couple display formats:

- `tested -f terminal` (default) - which displays all the output with ansicolors to the terminal
- `tested -f plain` - the same output as `terminal` but without any ansicoloring
- `tested -f tap` - output in the [TAP v14 format](https://testanything.org/)


## `tested -n/--threads`
Specify the number of threads `tested` should use. If set to `0`, will not use any threads (nor invoke the threading library - [LuaLanes](https://lualanes.github.io/lanes/) - at all) and will just run the tests sequentially. There is a small thread spin-up cost, but if you have a lot of tests it is generally negligible. Also, if you have a lot of resources available on your computer, increasing the number of threads could help run tests faster.

## `tested -z/--custom-formatter`
`tested` supports loading a [custom result formatter](./custom-formatter.md) from the commandline. It tries to load what's passed in initially as a Lua module, and then as filepath, doing some basic checks to ensure the object returned appears to be a formatter. Only one custom formatter can be loaded and will be used to display results.

## `tested -o/--output-file`
Output file to save results to a specified file. It loads a formatter based on the file extension of the file that's passed in. The currently supported extensions are:

- `.txt` - Outputs _exactly_ what is shown in the terminal (includes any filtering)
- `.json` - Outputs the full [TestRunnerOutput](./custom-formatter.md#testrunneroutput). Everything - it does not filter anything. We're still pre v1, so the output here _could_ change.

Multiple files can be specified and all will be written to at the end of the test run:

```bash
tested -o ./terminal_output.txt -o ./full_output.json
```

## `tested -x/--format-handler`
`tested` also supports loading [custom format handlers](./additional-formats.md). These are used to extend the functionality of tested and tap into other languages that can embed into Lua. Similar to custom output formatters, the format handler will first try and load from a Lua module and then from a filepath. This allows flexibility in distribution in how folks may want to support a custom format. Multiple format handlers can be loaded, and afterward can be used for custom formatters or the tests themselves.

## `tested -h` - Reference

```
Usage: tested ([-f {terminal,plain,tap}] | [-z <custom_formatter>])
       [-h] [-c] [-r] [-F <filter>]
       [-s {all,valid,invalid,skip,pass,fail,exception,unknown,expected,unexpected}]
       [-o <output_file>] [-n <threads>] [-x <format_handler>]
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
          -n <threads>,  Set the number of threads to run the tests with (default: 4). Set to 0 to disable. Test files are split amongst the threads.
   --threads <threads>
                 -x <format_handler>,
   --format-handler <format_handler>
                         File that loads custom formats that are Lua-compatible
        -d {DEBUG,INFO,WARNING},
   --debug {DEBUG,INFO,WARNING}
                         Set the log level - mostly for debugging issues with tested (default: 'WARNING') (default: WARNING)
   --version             Show version information
```
