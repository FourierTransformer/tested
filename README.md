# tested

tested is a new (and somewhat experimental) unit testing framework that can be used for Lua and Teal unit tests. It is designed to generate an easy-to-read output that helps you quickly identify what the issue is.

## Installing

We're not currently on LuaRocks, so pulling down this repo and running a `luarocks make` is the best way to get it installed!


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

You can see more tests in this repo's [tests](https://github.com/FourierTransformer/tested/tree/main/tests) folder!

example of a working output:
```
tested v0.0.0  tests.date_testing tests.max_nesting_depth

- tests.date_testing (0.084ms)
- tests.max_nesting_depth (128.833ms)

Test Summary (128.917ms):
  Run: 5 passed, 0 failed
Other: 0 skipped, 0 invalid

Fully Tested!
```

and an example of a non-working output:
```
tested v0.0.0  tests.play tests.fully_working tests.tables

- tests.play (0.021ms)
 ✗ sum() (0.012ms)
   ✗ ./tests/play.tl:22 - Given: 3 + 4  Should: return 7
      Actual: 5
      Expected: 7.0

   ✗ ./tests/play.tl:31 - Given: 4 + 5  Should: return 120120901293
      Actual: 9
      Expected: 120120901293

- tests.fully_working (0.002ms)
- tests.tables (0.045ms)
 ✗ table compare will error (0.038ms)
   ✗ ./tests/tables.tl:27 - Given: a basic table  Should: not be the same as the other table
      - .config.debug: Mising Key
      ~ .name: Different Values (Expected: Alice  Actual: Bob)
      ~ .scores[2]: Different Values (Expected: 20  Actual: 25)
      + .email: Additional Key

      Actual:
      {
        age = 30,
        config = {
          debug = false,
          port = 8080
        },
        email = "bob@example.com",
        name = "Bob",
        scores = { 10, 25, 30 }
      }

      Expected:
      {
        age = 30,
        config = {
          debug = true,
          port = 8080
        },
        name = "Alice",
        scores = { 10, 20, 30 }
      }


Test Summary (0.068ms):
  Run: 5 passed, 2 failed
Other: 1 skipped, 0 invalid
```

Running the tests are as simple as placing the file in a `tests` folder and then running the CLI command `tested` (which should be installed from LuaRocks). It will go through the `tests` folder, load each file, and run it through the test framework. It also doesn't matter if the test is written in Lua or Teal, tested is able to load and run both!


## tested cli arguments
tested allows you to randomize the order of `tested.test`'s by passing the `-r` flag to `tested`:
```
tested -r
```

It also has different display modes, if you want to see passing/failing/invalid tests:
```
tested -d pass -d fail -d
```

You can refer to `tested -h` for all the cli options.

## A couple of notes and background
Maybe you saw the word "experimental" in the summary above, and are a little curious. I was reading up a little on unit-testing, and came across [this article](https://medium.com/javascript-scene/rethinking-unit-test-assertions-55f59358253f) by Eric Elliot. In it they argue that unit testing frameworks should be easily read. A lot of times they spit out an error and don't/can't easily indicate how it came to be. Just a name and a failure, so that's how we've ended up with the addition of `given` and `should` in the assert.

```lua
tested.assert({given="toml with dates", should="parse dates as strings", expected=expected, actual=parsed_dates})
```

They also argue that the only assert needed is the equality check, hence only having `tested.assert`. I'm sort've using `tested` as a way to play with these ideas. So far, while I like the reasoning behind the `given` and `should`, I might move to making them optional. I think it's really beneficial if you have multiple asserts in the same test to help differentiate what went wrong, but for use cases where there's only one assert, it's a little less useful.

As far as only one assert check (for equality). While I do think luassert has too many asserts, I think going down to just one is a little much. After playing around a bit I'm considering adding the following, for ease with Lua:

- `tested.assert_throws_error` - so you don't have to handle `pcall` wrapping yourself
- `tested.assert_truthy` - could be useful if looking for a string in an output, could just pass in `str:find("whatever")`
- `tested.assert_falsy` - similar reasonings as above

Maybe others, but I think with those couple we would be good.

## AI Disclosure
- AI was not used to write any of this code. It's all been hand written over the course of 2-3 weeks.
- AI was used to help research Lua internals (mostly around file loading and the debug module)
- AI helped generate a prettier terminal output.
  - I fed it my [original terminal output], and it re-formatted it to something that looks a lot closer to the final terminal output.

## Licenses
Parts of the following are included in the source code:
- Bundles a slightly modified [inspect.lua](https://github.com/kikito/inspect.lua) for table diffing and viewing - MIT
- Also bundles a slightly modified [ansicolors.lua](https://github.com/kikito/ansicolors.lua) - MIT