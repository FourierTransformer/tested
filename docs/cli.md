# CLI

`tested` ships with a command-line interface (CLI) to aid in running tests. Below are some of the options explained in further detail as well as a reference to the full CLI's help page.

## `tested` - Base command 
By default `tested` will look for `_test.*` files recursively in the `./tests` directory relative to where it is run, looking for registered file extensions (by default `.lua` and `.tl`). You can specify your own directories or individual files to run by placing them at the end of the CLI invocation.

Example commands:

- `tested ./some-tests-here ./other-tests-here` - specifying multiple directories
- `tested ./tests/non_working_test.lua` - running a specific file

## `tested -c/--coverage`
The `-c` flag will enable [luacov](https://github.com/lunarmodules/luacov), and generate a `luacov.stats.out` file. It is disabled by default since it is generally used in CI/CD pipelines and unfortunately slows down testing. So feel free to enable it when you need code coverage!

## `tested -s/--show`
By default the `tested` output shows the problematic test results, that likely need to be addressed: `fail`, `exception`, and `unknown`, but allows filtering to display other results.

Current Values: `pass fail skip exception unknown valid invalid all`

There are three groupings that can also be used:

- `tested -s valid` - will show `pass`, `fail`, and `skip`
- `tested -s invalid` - will show `exception` and `unknown`
- `tested -s all` - shows all tests

To pass multiple values:

- `tested -s pass -s fail -s skip`

## `tested -f/--display-format`
Currently, `tested` has two display formats. The default is `terminal` which displays all the output with ansicolors to the terminal and `plain`, which is the same output as `terminal` but without any ansicoloring. There are some plans to add more in the future!


## `tested -n/--threads`
Specify the number of threads `tested` should use. If set to `0`, will not use any threads (nor invoke the threading library - [LuaLanes](https://lualanes.github.io/lanes/) - at all) and will just run the tests sequentially. There is a small thread spin-up cost, but if you have a lot of tests it is generally negligible. Also, if you have a lot of resources available on your computer, increasing the number of threads could help run tests faster.

## `tested -z/--custom-formatter`
`tested` supports loading a [custom result formatter](./custom-formatter.md) from the commandline. It tries to load what's passed in initially as a Lua module, and then as filepath, doing some basic checks to ensure the object returned appears to be a formatter. Only one custom formatter can be loaded and will be used to display results.

## `tested -x/--format-handler`
`tested` also supports loading [custom format handlers](./additional-formats.md). These are used to extend the functionality of tested and tap into other languages that can embed into Lua. Similar to custom output formatters, the format handler will first try and load from a Lua module and then from a filepath. This allows flexibility in distribution in how folks may want to support a custom format. Multiple format handlers can be loaded, and afterward can be used for custom formatters or the tests themselves.

## `tested -h` - Reference

```
$ tested -h
Usage: tested ([-f {terminal,plain}] | [-z <custom_formatter>]) [-h]
       [-c] [-r]
       [-s {all,valid,invalid,skip,pass,fail,exception,unknown}]
       [-n <threads>] [-x <format_handler>] [-d {DEBUG,INFO,WARNING}]
       [--version] [<paths>] ...

A Lua/Teal Unit Testing Framework

Arguments:
   paths                 Path(s) to directories or files with tests to run (default: 'tests')

Options:
   -h, --help            Show this help message and exit.
   -c, --coverage        Enable code coverage - will generate luacov.stats.out (default: not-set)
   -r, --random          Randomize the order of the tests (default: not-set)
       -s {all,valid,invalid,skip,pass,fail,exception,unknown},
   --show {all,valid,invalid,skip,pass,fail,exception,unknown}
                         What test results to display (default: '-s fail -s exception -s unknown')
                 -f {terminal,plain},
   --display-format {terminal,plain}
                         What format to output the results in (default: 'terminal') (default: terminal)
                   -z <custom_formatter>,
   --custom-formatter <custom_formatter>
                         File that loads a custom formatter to use for output
          -n <threads>,  Set the number of threads to run the tests with (default: 4). Set to 0 to disable.
   --threads <threads>
                 -x <format_handler>,
   --format-handler <format_handler>
                         File that loads custom formats that are Lua-compatible
        -d {DEBUG,INFO,WARNING},
   --debug {DEBUG,INFO,WARNING}
                         Set the log level - mostly for debugging purposes (default: 'WARNING') (default: WARNING)
   --version             Show version information
```