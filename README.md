# `tested`

`tested` is a new unit testing framework that can be used for Lua and Teal unit tests. It is designed to be modern and generate an easy-to-read output that helps you quickly identify and help to resolve a faililng test!

## Installing

```bash
luarocks install tested
```

After installing, the `tested` module will be available to your Lua code with `require("tested")` and a CLI tool, also called `tested` will be installed wherever your LuaRocks installs executables.

## A basic test

```lua
local tested = require("tested")
local tinytoml = require("tinytoml")

tested.test("encode date as string", function()

    local date_toml = [[offset_datetime = 1979-05-27T07:32:00Z
	local_datetime = 1979-05-27T07:32:00
	local_time = 07:32:00
	local_date = 1979-05-27]]

    local expected = {
      offset_datetime = "1979-05-27T07:32:00Z",
      local_datetime = "1979-05-27T07:32:00",
      local_time = "07:32:00",
      local_date = "1979-05-27"
    }

    local parsed_dates = tinytoml.parse(date_toml, {load_from_string=true, parse_datetime_as="string"})

    tested.assert({given="toml with dates", should="parse dates as strings", expected=expected, actual=parsed_dates})

end)

--- as many other tests as you want

return tested
```

Running the tests are as simple as placing the file in a `tests` folder and then running the CLI command `tested` (which should be installed from LuaRocks). It will go through the `tests` folder, find each file matching the `*_test.lua` (or `*_test.tl` file), and run it through the test framework. It also doesn't matter if the test is written in Lua or Teal, `tested` is able to load and run both!

You can see more tests in this repo's [tests](https://github.com/FourierTransformer/tested/tree/main/tests) folder!

## AI Disclosure
- AI was not used to write any of this code. It's all been hand written over the course of 2-3 weeks.
- AI was used to help research Lua internals (mostly around file loading and the debug module)
- AI helped generate a prettier terminal output.
  - I fed it my [original terminal output](./docs/original-output.txt), and it re-formatted it to something that looks a lot closer to the final terminal output.

## Licenses
Parts of the following are included in the source code present in this repo:
- Bundles a slightly modified [inspect.lua](https://github.com/kikito/inspect.lua) for table diffing and viewing - MIT
- Also bundles a slightly modified [ansicolors.lua](https://github.com/kikito/ansicolors.lua) - MIT
- A function from [Luacov](https://github.com/lunarmodules/luacov) code to help merge stats files in process - MIT

Major thanks to hishamhm, kikito, and benoit-germain for their work in the Lua space. Without them, tested wouldn't be possible.
